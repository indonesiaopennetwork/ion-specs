#!/usr/bin/env ruby

require "find"
require "json"
require "optparse"
require "pathname"
require "yaml"

module IonPolicyRegistry
  TRADE_POLICY_CATEGORIES = %w[return warranty].freeze
  REQUIRED_POLICY_FIELDS = %w[iri version status displayText].freeze

  module_function

  def build(repository_root)
    root = Pathname.new(File.expand_path(repository_root))
    policies = []
    errors = []
    seen = {}

    policy_source_paths(root).each do |path|
      YAML.load_stream(File.read(path).delete_prefix("\uFEFF")).compact.each do |document|
        unless document.is_a?(Hash)
          errors << "#{relative(root, path)}: policy document must be an object"
          next
        end

        missing = REQUIRED_POLICY_FIELDS.reject { |field| document.key?(field) }
        unless missing.empty?
          errors << "#{relative(root, path)}: missing #{missing.join(', ')}"
          next
        end

        iri = document["iri"]
        errors << "duplicate policy IRI: #{iri}" if seen[iri]
        seen[iri] = path
        display = document["displayText"]
        errors << "#{iri}: missing displayText.id" unless display.is_a?(Hash) && display["id"]
        category_dir = Pathname.new(path).relative_path_from(root.join("policies")).each_filename.first
        relative_path = relative(root, path)
        sector = document["sector"] || (relative_path.include?("/trade/") || TRADE_POLICY_CATEGORIES.include?(category_dir) ? "trade" : "cross-sector")
        policies << {
          "iri" => iri,
          "category" => document["category"] || category_dir.upcase.tr("-", "_"),
          "subCategory" => document["subCategory"],
          "version" => document["version"],
          "status" => document["status"],
          "versionEffectiveFrom" => document["versionEffectiveFrom"],
          "displayText" => { "id" => display["id"], "en" => display["en"] || "" },
          "applicableCategories" => document["applicableCategories"] || [],
          "applicableResourceTypes" => document["applicableResourceTypes"] || [],
          "regulatoryBasis" => document["regulatoryBasis"] || [],
          "supersededBy" => document["supersededBy"],
          "deprecatedAt" => document["deprecatedAt"],
          "sector" => sector,
          "docPath" => relative_path
        }
      end
    rescue Psych::SyntaxError => e
      errors << "#{relative(root, path)}: #{e.message.lines.first.strip}"
    end

    policies.sort_by! { |policy| policy["iri"] }
    by_category = policies.group_by { |policy| policy["category"] }.transform_values(&:length)
    by_sector = policies.group_by { |policy| policy["sector"] }.transform_values(&:length)
    registry = {
      "_generated" => "Do not edit directly. Run tools/policies/generate_registry.rb --write.",
      "_scheme" => "ion://policy/{category}.{sector-or-scope}.{variant-name}",
      "version" => "2.0.0",
      "totalPolicies" => policies.length,
      "byCategory" => by_category,
      "bySector" => by_sector,
      "policies" => policies
    }
    [root.join("policies/registry.json"), registry, errors]
  end

  def relative(root, path)
    Pathname.new(path).relative_path_from(root).to_s
  end

  def policy_source_paths(root)
    policies_root = root.join("policies")
    return [] unless policies_root.directory?

    paths = []
    Find.find(policies_root.to_s) do |path|
      next unless File.file?(path) && File.extname(path) == ".yaml"

      parts = Pathname.new(path).relative_path_from(root).each_filename.to_a
      paths << path if parts.first == "policies" && parts.include?("v1")
    end
    paths.sort
  end
end

if $PROGRAM_NAME == __FILE__
  options = { write: false }
  OptionParser.new do |parser|
    parser.on("--write", "Write the deterministic policy registry") { options[:write] = true }
  end.parse!(ARGV)
  repository_root = ARGV.fetch(0, ".")
  path, registry, errors = IonPolicyRegistry.build(repository_root)
  rendered = JSON.pretty_generate(registry) + "\n"
  if options[:write]
    path.dirname.mkpath
    path.write(rendered)
    puts "generated #{path}: #{registry['totalPolicies']} entries"
  elsif !path.file?
    errors << "generated registry is missing: #{path}"
  elsif path.read != rendered
    errors << "generated registry is stale: #{path}"
  else
    puts "generated registry is current: #{path}"
  end
  unless errors.empty?
    errors.each { |failure| warn "ERROR: #{failure}" }
    exit 1
  end
end
