#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "pathname"
require "yaml"

module IonReleaseRegistries
  TRADE_POLICY_CATEGORIES = %w[return warranty].freeze
  REQUIRED_POLICY_FIELDS = %w[iri version status displayText].freeze

  module_function

  def build(release_root)
    root = Pathname.new(File.expand_path(release_root))
    [build_policy_registry(root), build_error_registry(root)]
  end

  def build_policy_registry(root)
    policies = []
    errors = []
    seen = {}
    Dir[root.join("policies/**/v1/**/*.yaml").to_s].sort.each do |path|
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
      "_generated" => "Do not edit directly. Run tools/release/generate_release_registries.rb --write releases/#{root.basename}.",
      "_scheme" => "ion://policy/{category}.{sector-or-scope}.{variant-name}",
      "version" => "2.0.0",
      "totalPolicies" => policies.length,
      "byCategory" => by_category,
      "bySector" => by_sector,
      "policies" => policies
    }
    [root.join("policies/registry.json"), registry, errors]
  end

  def build_error_registry(root)
    path = root.join("errors/trade.yaml")
    errors = []
    entries = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
    unless entries.is_a?(Array)
      errors << "errors/trade.yaml: top level must be an array"
      entries = []
    end
    codes = entries.map { |entry| entry["code"] }
    codes.group_by { |code| code }.select { |_, values| values.length > 1 }.each_key do |code|
      errors << "duplicate error code: #{code}"
    end
    entries.each do |entry|
      errors << "invalid Trade error code: #{entry['code']}" unless entry["code"].to_s.match?(/\AION-A\d{4,}\z/)
    end
    registry = {
      "_generated" => "Do not edit directly. Run tools/release/generate_release_registries.rb --write releases/#{root.basename}.",
      "_source" => "errors/trade.yaml",
      "version" => "2.0.0",
      "sector" => "trade",
      "count" => entries.length,
      "errors" => entries
    }
    [root.join("errors/registry.json"), registry, errors]
  rescue Errno::ENOENT, Psych::SyntaxError => e
    [root.join("errors/registry.json"), {}, ["errors/trade.yaml: #{e.message.lines.first.strip}"]]
  end

  def relative(root, path)
    Pathname.new(path).relative_path_from(root).to_s
  end
end

if $PROGRAM_NAME == __FILE__
  options = { write: false }
  OptionParser.new do |parser|
    parser.on("--write", "Write deterministic registry files") { options[:write] = true }
  end.parse!(ARGV)
  release_root = ARGV.fetch(0, "releases/release1")
  failures = []
  IonReleaseRegistries.build(release_root).each do |path, registry, errors|
    failures.concat(errors)
    rendered = JSON.pretty_generate(registry) + "\n"
    if options[:write]
      path.dirname.mkpath
      path.write(rendered)
      puts "generated #{path}: #{registry['totalPolicies'] || registry['count']} entries"
    elsif !path.file?
      failures << "generated registry is missing: #{path}"
    elsif path.read != rendered
      failures << "generated registry is stale: #{path}"
    else
      puts "generated registry is current: #{path}"
    end
  end
  unless failures.empty?
    failures.each { |failure| warn "ERROR: #{failure}" }
    exit 1
  end
end
