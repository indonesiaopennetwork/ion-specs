#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "pathname"
require "yaml"

module IonLogisticsErrors
  SUPPORTED_APIS = %w[
    discover on_discover select on_select init on_init confirm on_confirm
    status on_status track on_track update on_update cancel on_cancel
    rate on_rate support on_support reconcile on_reconcile
  ].freeze
  CATEGORIES = %w[cancellation compliance fulfillment governance incident payment transaction].freeze
  REQUIRED_FIELDS = %w[
    code http_status category title description affected_field affected_apis
    schema_ref schema_pointer flow_ref resolution legacy_code sector
  ].freeze

  module_function

  def load_yaml(path)
    YAML.safe_load(path.read, permitted_classes: [Date, Time], aliases: true)
  end

  def resolve_pointer(document, pointer)
    return nil unless pointer.is_a?(String) && pointer.start_with?("/")

    pointer.split("/").drop(1).reduce(document) do |value, token|
      break nil unless value.is_a?(Hash)
      value[token.gsub("~1", "/").gsub("~0", "~")]
    end
  end

  def validate(release_root, repository_root:, map_path:, source_root: nil)
    release_root = Pathname.new(release_root).expand_path
    repository_root = Pathname.new(repository_root).expand_path
    map_path = Pathname.new(map_path).expand_path
    failures = []

    source_path = release_root.join("errors/logistics.yaml")
    registry_path = release_root.join("errors/registry.json")
    entries = load_yaml(source_path)
    unless entries.is_a?(Array)
      return ["#{source_path}: top level must be an array"]
    end

    codes = entries.map { |entry| entry["code"] if entry.is_a?(Hash) }.compact
    codes.group_by { |code| code }.select { |_, values| values.length > 1 }.each_key do |code|
      failures << "duplicate Logistics error code: #{code}"
    end

    entries.each_with_index do |entry, index|
      unless entry.is_a?(Hash)
        failures << "errors/logistics.yaml entry #{index + 1} must be an object"
        next
      end
      label = entry["code"] || "entry #{index + 1}"
      REQUIRED_FIELDS.each { |field| failures << "#{label}: missing #{field}" unless entry.key?(field) }
      failures << "#{label}: invalid Logistics error code" unless label.to_s.match?(/\AION-B\d{4,}\z/)
      failures << "#{label}: invalid legacy code #{entry['legacy_code']}" unless entry["legacy_code"].to_s.match?(/\AION-LOG-\d{4}\z/)
      failures << "#{label}: sector must be logistics" unless entry["sector"] == "logistics"
      failures << "#{label}: HTTP status must be 400..599" unless (400..599).cover?(entry["http_status"])
      failures << "#{label}: unsupported category #{entry['category']}" unless CATEGORIES.include?(entry["category"])

      apis = entry["affected_apis"]
      unless apis.is_a?(Array) && !apis.empty?
        failures << "#{label}: affected_apis must be a non-empty array"
      else
        (apis - SUPPORTED_APIS).each { |api| failures << "#{label}: unsupported affected API #{api}" }
        failures << "#{label}: Logistics callback errors must identify a BPP-sent on_* API" unless apis.all? { |api| api.start_with?("on_") }
      end

      schema_ref = entry["schema_ref"]
      schema_dir = release_root.join(schema_ref.to_s)
      schema_path = schema_dir.join("attributes.yaml")
      unless schema_path.file?
        failures << "#{label}: schema target does not exist: #{schema_ref}"
      else
        schema = load_yaml(schema_path)
        failures << "#{label}: schema pointer does not resolve: #{entry['schema_pointer']}" if resolve_pointer(schema, entry["schema_pointer"]).nil?
      end

      flow_ref = entry["flow_ref"]
      target = if flow_ref.nil?
                 nil
               elsif flow_ref.start_with?("https://schema.ion.id/policies/")
                 repository_root.join(flow_ref.delete_prefix("https://schema.ion.id/").split("#", 2).first)
               elsif flow_ref.match?(%r{\Ahttps?://})
                 failures << "#{label}: unsupported external flow target: #{flow_ref}"
                 nil
               else
                 release_root.join(flow_ref.split("#", 2).first)
               end
      failures << "#{label}: flow or policy target does not exist: #{flow_ref}" if target && !target.exist?
    rescue Psych::SyntaxError => e
      failures << "#{label}: target parse error: #{e.message.lines.first.strip}"
    end

    registry = JSON.parse(registry_path.read)
    registered = Array(registry["errors"]).select { |entry| entry["sector"] == "logistics" }
    failures << "errors/registry.json does not match errors/logistics.yaml" unless registered == entries

    migration = load_yaml(map_path)
    included = migration.fetch("included", {})
    deferred = migration.fetch("deferred", {})
    reasons = migration.fetch("reasons", {})
    overlap = included.keys & deferred.keys
    failures << "migration map includes and defers the same codes: #{overlap.join(', ')}" unless overlap.empty?
    dispositions = included.length + deferred.length
    failures << "migration map covers #{dispositions}, expected #{migration['sourceCount']}" unless dispositions == migration["sourceCount"]
    deferred.each { |legacy_code, reason| failures << "#{legacy_code}: unknown deferral reason #{reason}" unless reasons.key?(reason) }
    mapped_entries = entries.to_h { |entry| [entry["legacy_code"], entry["code"]] }
    failures << "migration map included set does not match released Logistics errors" unless included == mapped_entries

    if source_root
      legacy_path = Pathname.new(source_root).expand_path.join(migration.fetch("sourcePath"))
      legacy = load_yaml(legacy_path)
      legacy_codes = legacy.fetch("errors").keys.sort
      mapped_codes = (included.keys + deferred.keys).sort
      failures << "migration map does not cover the pinned legacy error source" unless mapped_codes == legacy_codes
      failures << "legacy source contains #{legacy_codes.length}, expected #{migration['sourceCount']}" unless legacy_codes.length == migration["sourceCount"]
    end

    failures
  rescue Errno::ENOENT, KeyError, JSON::ParserError, Psych::SyntaxError => e
    failures << e.message.lines.first.strip
    failures
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  OptionParser.new do |parser|
    parser.on("--source-root PATH", "Verify coverage against the separately checked-out pinned legacy source") { |path| options[:source_root] = path }
  end.parse!(ARGV)
  release_root = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/release1")))
  repository_root = Pathname.new(File.expand_path("../..", __dir__))
  failures = IonLogisticsErrors.validate(
    release_root,
    repository_root: repository_root,
    map_path: repository_root.join("tools/release/release1-logistics-error-map.yaml"),
    source_root: options[:source_root]
  )
  if failures.empty?
    count = IonLogisticsErrors.load_yaml(release_root.join("errors/logistics.yaml")).length
    puts "Logistics error validation passed: #{count} included errors"
  else
    warn "Logistics error validation failed with #{failures.length} error(s):"
    failures.each { |failure| warn "- #{failure}" }
    exit 1
  end
end
