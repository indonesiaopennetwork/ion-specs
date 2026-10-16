#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "pathname"
require "yaml"

module IonLogisticsConnections
  PATTERNS = %w[parcel hyperlocal freight roro warehouse cross-border].freeze
  VARIANTS = %w[during-transaction cancellation delivery-attempts reverse exception weight-dispute incident rts-handoff cross-cutting].freeze
  ACTIONS = %w[discover on_discover select on_select init on_init confirm on_confirm status on_status track on_track update on_update cancel on_cancel rate on_rate support on_support reconcile on_reconcile].freeze
  STATE_REGISTRY = "flows/logistics/state-machines/v1/states.yaml"

  module_function

  def validate(release_root, repository_root: nil)
    release_root = Pathname.new(File.expand_path(release_root))
    repository_root = Pathname.new(File.expand_path(repository_root || release_root.join("../..")))
    errors = []
    documents = load_documents(release_root, errors)
    registry = load_document(release_root.join(STATE_REGISTRY), errors) || {}
    machines = registry.fetch("machines", {})
    flow_catalog = registry.fetch("flowCatalog", {})
    policy_registry = load_document(repository_root.join("policies/registry.json"), errors) || {}
    policy_iris = policy_registry.fetch("policies", []).map { |entry| entry["iri"] }

    validate_inventory(release_root, errors)
    owned_flow_ids = []
    documents.each do |path, document|
      next unless document.is_a?(Hash)
      relative = path.relative_path_from(release_root)
      validate_actions(document, relative, errors)
      validate_schema_packs(document, release_root, relative, errors)
      validate_state_references(document, release_root, machines, relative, errors)
      validate_policy_references(document, policy_iris, relative, errors)
      if path.basename.to_s == "profile.json"
        validate_profile_file_targets(document, path, relative, errors)
        owned_flow_ids.concat(Array(document["flowIds"]))
      end
    end
    validate_flow_ownership(flow_catalog, owned_flow_ids, errors)
    errors
  end

  def load_documents(release_root, errors)
    release_root.glob("flows/logistics/**/*.{yaml,yml,json}").sort.to_h do |path|
      [path, load_document(path, errors)]
    end
  end

  def load_document(path, errors)
    text = File.read(path).delete_prefix("\uFEFF")
    path.extname == ".json" ? JSON.parse(text) : YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
  rescue Errno::ENOENT
    errors << "document does not exist: #{path}"
    nil
  rescue JSON::ParserError, Psych::SyntaxError => e
    errors << "#{path}: parse error: #{e.message.lines.first.strip}"
    nil
  end

  def validate_inventory(root, errors)
    PATTERNS.each do |name|
      path = root.join("flows/logistics/patterns/#{name}/v1/profile.json")
      errors << "missing Logistics pattern profile: #{name}" unless path.file?
    end
    VARIANTS.each do |name|
      path = root.join("flows/logistics/variants/#{name}/v1/profile.json")
      errors << "missing Logistics variant profile: #{name}" unless path.file?
    end
  end

  def validate_actions(document, source, errors)
    walk(document) do |key, value|
      if key == "step"
        errors << "#{source}: unsupported protocol action #{value}" unless ACTIONS.include?(value)
      elsif %w[steps baseSequence optionalActions].include?(key) && value.is_a?(Array)
        value.each do |action|
          errors << "#{source}: unsupported protocol action #{action}" if action.is_a?(String) && !ACTIONS.include?(action)
        end
      end
    end
  end

  def validate_schema_packs(document, root, source, errors)
    walk(document) do |key, value|
      next unless %w[schemaPacks schemaPacksRequired].include?(key) && value.is_a?(Hash)
      value.each do |group, packs|
        prefix = group == "common" ? "schema/common" : "schema/extension/#{group}"
        Array(packs).each do |pack|
          errors << "#{source}: schema pack does not exist: #{prefix}/#{pack}" unless root.join(prefix, pack.to_s).directory?
        end
      end
    end
  end

  def validate_state_references(document, root, machines, source, errors)
    references = []
    walk(document) do |key, value|
      references << value if %w[stateMachine performanceStateMachine].include?(key) && value.is_a?(String)
      references.concat(value.values) if key == "mappings" && value.is_a?(Hash) && value.values.all? { |entry| entry.is_a?(String) && entry.include?("states.yaml#") }
    end
    references.each do |reference|
      path, fragment = reference.split("#", 2)
      errors << "#{source}: state-machine reference must target #{STATE_REGISTRY}: #{reference}" unless path == STATE_REGISTRY
      errors << "#{source}: state-machine target does not exist: #{path}" unless root.join(path).file?
      errors << "#{source}: unknown state machine #{fragment}" unless machines.key?(fragment)
    end
  end

  def validate_policy_references(document, registry_iris, source, errors)
    collect_strings(document).select { |value| value.start_with?("ion://policy/") }.uniq.each do |iri|
      errors << "#{source}: policy reference is not registered: #{iri}" unless registry_iris.include?(iri)
    end
  end

  def validate_profile_file_targets(document, path, source, errors)
    document.each do |key, value|
      next unless key.end_with?("File") && value.is_a?(String)
      target = Pathname.new(File.expand_path(value.split("#", 2).first, path.dirname))
      errors << "#{source}: #{key} target does not exist: #{value}" unless target.file?
    end
  end

  def validate_flow_ownership(flow_catalog, owned_ids, errors)
    duplicate_values(owned_ids).each { |id| errors << "flow ID has multiple profile owners: #{id}" }
    owned_ids.uniq.each do |id|
      declaration = flow_catalog[id]
      errors << "profile owns undeclared flow ID: #{id}" unless declaration
      errors << "profile-owned flow ID is not published: #{id}" if declaration && declaration["status"] != "published"
    end
    flow_catalog.each do |id, declaration|
      errors << "published flow ID has no profile owner: #{id}" if declaration["status"] == "published" && !owned_ids.include?(id)
    end
  end

  def walk(value, &block)
    case value
    when Hash
      value.each { |key, child| yield(key, child); walk(child, &block) }
    when Array
      value.each { |child| walk(child, &block) }
    end
  end

  def collect_strings(value)
    case value
    when Hash then value.flat_map { |key, child| [key.to_s] + collect_strings(child) }
    when Array then value.flat_map { |child| collect_strings(child) }
    when String then [value]
    else []
    end
  end

  def duplicate_values(values)
    values.group_by(&:itself).select { |_, entries| entries.length > 1 }.keys
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  OptionParser.new do |parser|
    parser.on("--repository-root PATH") { |path| options[:repository_root] = path }
  end.parse!(ARGV)
  release_root = ARGV.fetch(0, "releases/release1")
  errors = IonLogisticsConnections.validate(release_root, repository_root: options[:repository_root])
  if errors.empty?
    puts "Logistics connection validation passed: #{IonLogisticsConnections::PATTERNS.length} patterns, #{IonLogisticsConnections::VARIANTS.length} variants"
  else
    warn "Logistics connection validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
