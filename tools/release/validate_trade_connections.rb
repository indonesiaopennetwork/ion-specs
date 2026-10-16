#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "pathname"
require "yaml"

options = {}
OptionParser.new do |parser|
  parser.on("--repository-root PATH", "Repository root containing the shared policies directory") do |path|
    options[:repository_root] = path
  end
end.parse!(ARGV)

release_root = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/release1")))
repository_root = Pathname.new(File.expand_path(options.fetch(:repository_root, File.expand_path("../..", __dir__))))
errors = []

unless release_root.directory?
  warn "release directory does not exist: #{release_root}"
  exit 2
end

load_document = lambda do |path|
  text = File.read(path).delete_prefix("\uFEFF")
  File.extname(path) == ".json" ? JSON.parse(text) : YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
rescue JSON::ParserError, Psych::SyntaxError => e
  errors << "#{path}: parse error: #{e.message.lines.first.strip}"
  nil
end

relative = ->(path) { Pathname.new(path).relative_path_from(release_root).to_s }
repository_relative = ->(path) { Pathname.new(path).relative_path_from(repository_root).to_s }
manifest = load_document.call(release_root.join("release.yaml").to_s) || {}
public_base_url = manifest["publicBaseUrl"].to_s
policy_public_base_url = "https://schema.ion.id/policies/"

flow_files = Dir[release_root.join("flows/trade/**/*.{yaml,yml,json}").to_s].sort
flow_documents = flow_files.to_h { |path| [path, load_document.call(path)] }

flow_documents.each do |path, document|
  next unless File.basename(path) == "profile.json" && document.is_a?(Hash)

  document.each do |key, value|
    next unless key.end_with?("File") && value.is_a?(String)
    target = Pathname.new(File.expand_path(value.split("#", 2).first, File.dirname(path)))
    errors << "#{relative.call(path)}: #{key} target does not exist: #{value}" unless target.file?
  end
  if document["performanceStateMachine"].is_a?(String)
    target = release_root.join(document["performanceStateMachine"].split("#", 2).first)
    errors << "#{relative.call(path)}: performanceStateMachine target does not exist" unless target.file?
  end
  if document.dig("policyRequirements", "policyIris")
    errors << "#{relative.call(path)}: policyRequirements.policyIris must contain concrete registry IRIs, not category placeholders"
  end
end

policy_files = Dir[repository_root.join("policies/**/v1/**/*.yaml").to_s].reject { |path| File.basename(path) == "_schema.yaml" }.sort
source_iris = []
policy_files.each do |path|
  YAML.load_stream(File.read(path).delete_prefix("\uFEFF")).compact.each do |document|
    unless document.is_a?(Hash) && document["iri"]
      errors << "#{repository_relative.call(path)}: policy document has no iri"
      next
    end
    source_iris << document["iri"]
    errors << "#{repository_relative.call(path)}: missing displayText.id" unless document.dig("displayText", "id")
  end
rescue Psych::SyntaxError => e
  errors << "#{repository_relative.call(path)}: parse error: #{e.message.lines.first.strip}"
end
source_iris.group_by { |iri| iri }.select { |_, values| values.length > 1 }.each_key do |iri|
  errors << "duplicate policy IRI: #{iri}"
end

policy_registry = load_document.call(repository_root.join("policies/registry.json").to_s) || {}
registry_policies = policy_registry.fetch("policies", [])
registry_iris = registry_policies.map { |entry| entry["iri"] }
(source_iris.uniq - registry_iris).each { |iri| errors << "policy missing from registry: #{iri}" }
(registry_iris - source_iris.uniq).each { |iri| errors << "registry policy has no source: #{iri}" }
registry_policies.each do |entry|
  path = repository_root.join(entry["docPath"].to_s)
  errors << "policy registry docPath does not exist: #{entry['docPath']}" unless path.file?
end

active_policy_refs = []
walk = nil
walk = lambda do |value, source|
  case value
  when Hash
    value.each do |key, child|
      if %w[policyIRI policyRef].include?(key) && child.is_a?(String) && child.start_with?("ion://policy/")
        active_policy_refs << [source, child]
      end
      if %w[schemaPacks schemaPacksRequired].include?(key) && child.is_a?(Hash)
        child.each do |group, packs|
          Array(packs).each do |pack|
            prefix = case group
                     when "common" then "schema/common"
                     when "core" then "schema/core"
                     else "schema/extension/#{group}"
                     end
            target = release_root.join(prefix, pack.to_s)
            errors << "#{relative.call(source)}: schema pack does not exist: #{prefix}/#{pack}" unless target.directory?
          end
        end
      end
      walk.call(child, source)
    end
  when Array
    value.each { |child| walk.call(child, source) }
  when String
    if value.start_with?("https://schema.ion.id/")
      if value.start_with?(policy_public_base_url)
        target = repository_root.join(value.delete_prefix("https://schema.ion.id/").split("#", 2).first)
        errors << "#{relative.call(source)}: policy URL target does not exist: #{value}" unless target.exist?
      elsif value.start_with?(public_base_url)
        target = release_root.join(value.delete_prefix(public_base_url).split("#", 2).first)
        errors << "#{relative.call(source)}: release URL target does not exist: #{value}" unless target.exist?
      else
        errors << "#{relative.call(source)}: non-release schema.ion.id URL: #{value}"
      end
    end
  end
end
flow_documents.each { |path, document| walk.call(document, path) if document }
active_policy_refs.each do |path, iri|
  errors << "#{relative.call(path)}: policy reference is not registered: #{iri}" unless registry_iris.include?(iri)
end

trade_errors_path = release_root.join("errors/trade.yaml")
trade_errors = load_document.call(trade_errors_path.to_s)
trade_errors = [] unless trade_errors.is_a?(Array)
trade_errors.each do |entry|
  %w[schema_ref flow_ref].each do |key|
    reference = entry[key]
    next unless reference.is_a?(String)
    target = if reference.start_with?(policy_public_base_url)
               repository_root.join(reference.delete_prefix("https://schema.ion.id/").split("#", 2).first)
             elsif reference.match?(%r{\Ahttps?://})
               nil
             else
               release_root.join(reference.split("#", 2).first)
             end
    if target.nil?
      errors << "#{entry['code']}: #{key} uses an unsupported external target: #{reference}"
      next
    end
    errors << "#{entry['code']}: #{key} target does not exist: #{reference}" unless target.exist?
  end
end
error_registry = load_document.call(release_root.join("errors/registry.json").to_s) || {}
registered_trade_errors = Array(error_registry["errors"]).select { |entry| entry["sector"] == "trade" }
errors << "errors/registry.json does not match errors/trade.yaml" unless registered_trade_errors == trade_errors

if errors.empty?
  puts "Trade connection validation passed: #{flow_files.length} structured flow files, " \
       "#{active_policy_refs.length} concrete policy references, #{source_iris.uniq.length} policies, " \
       "#{trade_errors.length} Trade errors"
else
  warn "Trade connection validation failed with #{errors.length} error(s):"
  errors.each { |error| warn "- #{error}" }
  exit 1
end
