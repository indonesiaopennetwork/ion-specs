#!/usr/bin/env ruby

require "date"
require "json"
require "pathname"
require "yaml"

repository_root = Pathname.new(File.expand_path("../..", __dir__))
errors = []
warnings = []

load_document = lambda do |path|
  text = File.read(path).delete_prefix("\uFEFF")
  File.extname(path) == ".json" ? JSON.parse(text) : YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
rescue JSON::ParserError, Psych::SyntaxError => e
  errors << "#{path}: parse error: #{e.message.lines.first.strip}"
  nil
end

flow_files = Dir[repository_root.join("flows/trade/**/*.{yaml,yml,json}").to_s].sort
flow_documents = flow_files.to_h { |path| [path, load_document.call(path)] }
flow_documents.each do |path, document|
  next unless File.basename(path) == "profile.json" && document.is_a?(Hash)

  document.each do |key, value|
    next unless key.end_with?("File") && value.is_a?(String)
    target = File.expand_path(value, File.dirname(path))
    errors << "#{path}: #{key} target does not exist: #{value}" unless File.file?(target)
  end
  if document["performanceStateMachine"].is_a?(String)
    target = repository_root.join(document["performanceStateMachine"].split("#", 2).first)
    errors << "#{path}: performanceStateMachine target does not exist" unless target.file?
  end
  if document.dig("policyRequirements", "policyIris")
    errors << "#{path}: policyRequirements.policyIris must contain concrete registry IRIs, not category placeholders"
  end
end

policy_files = Dir[repository_root.join("policies/**/v1/**/*.yaml").to_s].reject { |path| File.basename(path) == "_schema.yaml" }.sort
source_iris = []
policy_files.each do |path|
  text = File.read(path).delete_prefix("\uFEFF")
  YAML.load_stream(text).compact.each do |document|
    unless document.is_a?(Hash) && document["iri"]
      warnings << "#{path}: legacy policy document has no iri and is omitted from the registry"
      next
    end
    source_iris << document["iri"]
    errors << "#{path}: missing displayText.id" unless document.dig("displayText", "id")
  end
rescue Psych::SyntaxError => e
  errors << "#{path}: parse error: #{e.message.lines.first.strip}"
end
duplicates = source_iris.group_by { |iri| iri }.select { |_, occurrences| occurrences.length > 1 }.keys
duplicates.each { |iri| errors << "duplicate policy IRI: #{iri}" }

policy_registry = load_document.call(repository_root.join("policies/registry.json").to_s)
registry_iris = policy_registry.fetch("policies", []).map { |entry| entry["iri"] }
(source_iris.uniq - registry_iris).each { |iri| errors << "policy missing from registry: #{iri}" }
(registry_iris - source_iris.uniq).each { |iri| errors << "registry policy has no source: #{iri}" }

active_policy_refs = []
walk = lambda do |value, source|
  case value
  when Hash
    value.each do |key, child|
      if %w[policyIRI policyRef].include?(key) && child.is_a?(String) && child.start_with?("ion://policy/")
        active_policy_refs << [source, child]
      end
      walk.call(child, source)
    end
  when Array
    value.each { |child| walk.call(child, source) }
  end
end
flow_documents.each { |path, document| walk.call(document, path) if document }
active_policy_refs.each do |path, iri|
  errors << "#{path}: policy reference is not registered: #{iri}" unless registry_iris.include?(iri)
end

trade_errors_path = repository_root.join("errors/trade.yaml")
trade_errors = load_document.call(trade_errors_path.to_s) || []
trade_errors.each do |entry|
  %w[schema_ref flow_ref].each do |key|
    reference = entry[key]
    next unless reference.is_a?(String)
    target = repository_root.join(reference.split("#", 2).first)
    errors << "#{entry["code"]}: #{key} target does not exist: #{reference}" unless target.exist?
  end
end
trade_view = load_document.call(repository_root.join("errors/trade-registry.json").to_s)
unified = load_document.call(repository_root.join("errors/registry.json").to_s)
errors << "trade-registry.json does not match errors/trade.yaml" unless trade_view&.fetch("errors", nil) == trade_errors
unified_trade = unified&.fetch("errors", [])&.select { |entry| entry["code"].to_s.start_with?("ION-A") }
errors << "registry.json Trade view does not match errors/trade.yaml" unless unified_trade == trade_errors

if errors.empty?
  puts "Trade connection validation passed: #{flow_files.length} flow files, #{active_policy_refs.length} concrete policy references, #{source_iris.uniq.length} registered policies, #{trade_errors.length} Trade errors"
  puts "warnings: #{warnings.length} legacy policy document(s) omitted from the modern registry" unless warnings.empty?
else
  warn "Trade connection validation failed with #{errors.length} error(s):"
  errors.each { |error| warn "- #{error}" }
  exit 1
end
