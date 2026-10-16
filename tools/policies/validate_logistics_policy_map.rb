#!/usr/bin/env ruby

require "json"
require "open3"
require "optparse"
require "pathname"
require "yaml"

module IonLogisticsPolicyMap
  DISPOSITIONS = %w[migrated reused replaced deferred].freeze
  POLICY_IRI = %r{ion://policy/[A-Za-z0-9._/-]+}.freeze

  module_function

  def validate(map_path, registry_path, source_root: nil)
    map = YAML.safe_load(File.read(map_path), aliases: false)
    registry = JSON.parse(File.read(registry_path))
    registered = registry.fetch("policies").to_h { |policy| [policy.fetch("iri"), policy] }
    entries = map.fetch("entries", {})
    errors = []

    entries.each do |source_iri, entry|
      disposition = entry["disposition"]
      errors << "#{source_iri}: invalid disposition #{disposition.inspect}" unless DISPOSITIONS.include?(disposition)
      if disposition == "deferred"
        errors << "#{source_iri}: deferred entry must explain its reason" if entry["reason"].to_s.strip.empty?
        errors << "#{source_iri}: deferred entry must not declare targetIri" if entry.key?("targetIri")
        next
      end

      target = entry["targetIri"]
      errors << "#{source_iri}: #{disposition} entry is missing targetIri" unless target
      errors << "#{source_iri}: target policy is not registered: #{target}" if target && !registered.key?(target)
    end

    validate_logistics_policy_references(registered, registry_path, errors)
    validate_source_inventory(map, entries, source_root, errors) if source_root
    errors
  rescue KeyError, JSON::ParserError, Psych::SyntaxError => e
    [e.message]
  end

  def validate_logistics_policy_references(registered, registry_path, errors)
    repository_root = Pathname.new(registry_path).dirname.dirname
    registered.each_value do |policy|
      next unless policy["sector"] == "logistics"

      path = repository_root.join(policy.fetch("docPath"))
      YAML.load_stream(File.read(path)).compact.each do |document|
        policy_references(document).each do |reference|
          next if reference == document["iri"] || registered.key?(reference)

          errors << "#{policy['iri']}: referenced policy is not registered: #{reference}"
        end
      end
    end
  end

  def policy_references(value)
    case value
    when Hash
      value.values.flat_map { |child| policy_references(child) }
    when Array
      value.flat_map { |child| policy_references(child) }
    when String
      value.start_with?("ion://policy/") ? [value] : []
    else
      []
    end
  end

  def validate_source_inventory(map, entries, source_root, errors)
    root = Pathname.new(File.expand_path(source_root))
    expected_commit = map.fetch("sourceCommit")
    output, status = Open3.capture2("git", "-C", root.to_s, "rev-parse", "HEAD")
    if !status.success?
      errors << "cannot read source revision: #{root}"
    elsif output.strip != expected_commit
      errors << "source revision is #{output.strip}; expected #{expected_commit}"
    end

    flow_root = root.join(map.fetch("sourcePath"))
    actual = Dir.glob(flow_root.join("**/*")).select { |path| File.file?(path) }.flat_map do |path|
      File.read(path).scan(POLICY_IRI)
    end.uniq.sort
    mapped = entries.keys.sort
    (actual - mapped).each { |iri| errors << "unmapped legacy Logistics policy IRI: #{iri}" }
    (mapped - actual).each { |iri| errors << "migration-map IRI is not used by legacy Logistics flows: #{iri}" }
  end
end

if $PROGRAM_NAME == __FILE__
  options = { source_root: nil }
  OptionParser.new do |parser|
    parser.on("--source-root PATH", "Also compare against the pinned legacy Logistics flow tree") do |path|
      options[:source_root] = path
    end
  end.parse!(ARGV)

  repository_root = Pathname.new(File.expand_path(ARGV.fetch(0, ".")))
  map_path = repository_root.join("tools/policies/logistics-policy-migration-map.yaml")
  registry_path = repository_root.join("policies/registry.json")
  errors = IonLogisticsPolicyMap.validate(map_path, registry_path, source_root: options[:source_root])
  if errors.empty?
    puts "Logistics policy migration map passed: #{map_path}"
  else
    errors.each { |error| warn "ERROR: #{error}" }
    exit 1
  end
end
