#!/usr/bin/env ruby

require "date"
require "pathname"
require "yaml"

module IonLogisticsPerformanceStates
  TERMINAL_OUTCOMES = %w[SUCCESS CANCELLED FAILED RETURNED TRANSFERRED DISPUTED].freeze
  CONTRACT_CONTRIBUTIONS = %w[COMPLETE CANCELLED ACTIVE].freeze
  GUARD_OPERATORS = %w[EQ NOT_EQ IN NOT_IN EXISTS].freeze
  EFFECT_TYPES = %w[RELEASE_REFUND CREATE_CHILD_CONTRACT START_STORAGE_BILLING RECORD_DISPOSITION].freeze
  CATEGORIES = %w[BOOKING ASSIGNMENT PICKUP TRANSIT HUB DELIVERY RETURN CUSTOMS FREIGHT PORT WAREHOUSE EXCEPTION].freeze
  AGGREGATION_CONDITIONS = %w[ANY_REQUIRED_NON_TERMINAL ANY_REQUIRED_FAILED_OR_DISPUTED ALL_REQUIRED_CANCELLED ALL_REQUIRED_SUCCESS_RETURNED_OR_TRANSFERRED NO_REQUIRED_PERFORMANCES].freeze
  IDENTIFIER = /\A[a-z][a-z0-9-]*\z/
  STATE_CODE = /\A[A-Z][A-Z0-9_]*\z/

  SCHEMA_PATHS = {
    "LogisticsPerformance" => "schema/extension/logistics/LogisticsPerformance/v1/attributes.yaml",
    "LogisticsContract" => "schema/extension/logistics/LogisticsContract/v1/attributes.yaml"
  }.freeze

  module_function

  def validate(registry_path, release_root:)
    errors = []
    registry_path = Pathname.new(registry_path)
    release_root = Pathname.new(release_root)
    registry = load_yaml(registry_path, errors)
    return errors unless registry.is_a?(Hash)

    errors << "registryVersion must be a semantic version" unless registry["registryVersion"].to_s.match?(/\A\d+\.\d+\.\d+\z/)
    validate_aggregation(registry["contractStatusAggregation"], errors)
    flow_catalog = registry["flowCatalog"]
    unless flow_catalog.is_a?(Hash)
      errors << "flowCatalog must be an object"
      flow_catalog = {}
    end
    flow_catalog.each_key { |id| errors << "invalid flow catalog ID: #{id}" unless id.match?(IDENTIFIER) }
    flow_catalog.each do |id, declaration|
      unless declaration.is_a?(Hash) && %w[planned published].include?(declaration["status"]) && declaration["purpose"].to_s.match?(STATE_CODE)
        errors << "invalid flow catalog declaration: #{id}"
      end
    end

    machines = registry["machines"]
    unless machines.is_a?(Hash) && !machines.empty?
      errors << "machines must be a non-empty object"
      return errors
    end

    schemas = load_target_schemas(release_root, errors)
    machines.each do |machine_id, machine|
      validate_machine(machine_id, machine, flow_catalog, schemas, errors)
    end
    validate_flow_documents(release_root, machines, errors)
    errors
  end

  def load_yaml(path, errors)
    YAML.safe_load(File.read(path).delete_prefix("\uFEFF"), permitted_classes: [Date, Time], aliases: false)
  rescue Errno::ENOENT
    errors << "registry does not exist: #{path}"
    nil
  rescue Psych::SyntaxError => e
    errors << "#{path}: parse error: #{e.message.lines.first.strip}"
    nil
  end

  def load_target_schemas(release_root, errors)
    SCHEMA_PATHS.to_h do |name, relative|
      path = release_root.join(relative)
      document = load_yaml(path, errors)
      [name, document]
    end
  end

  def validate_aggregation(rules, errors)
    unless rules.is_a?(Array) && !rules.empty?
      errors << "contractStatusAggregation must be a non-empty array"
      return
    end
    ids = rules.filter_map { |rule| rule["ruleId"] if rule.is_a?(Hash) }
    duplicate_values(ids).each { |id| errors << "duplicate aggregation rule ID: #{id}" }
    rules.each do |rule|
      next unless rule.is_a?(Hash)
      errors << "aggregation rule #{rule['ruleId']} has invalid condition" unless AGGREGATION_CONDITIONS.include?(rule["when"])
      errors << "aggregation rule #{rule['ruleId']} has invalid Contract status" unless %w[ACTIVE CANCELLED COMPLETE].include?(rule["contractStatus"])
    end
  end

  def validate_machine(machine_id, machine, flow_catalog, schemas, errors)
    prefix = "machine #{machine_id}"
    errors << "invalid machine ID: #{machine_id}" unless machine_id.match?(IDENTIFIER)
    unless machine.is_a?(Hash)
      errors << "#{prefix} must be an object"
      return
    end
    errors << "#{prefix}: machineId must match its map key" unless machine["machineId"] == machine_id
    errors << "#{prefix}: version must be a semantic version" unless machine["version"].to_s.match?(/\A\d+\.\d+\.\d+\z/)
    states = machine["states"]
    unless states.is_a?(Hash) && !states.empty?
      errors << "#{prefix}: states must be a non-empty object"
      return
    end
    initial = machine["initialState"]
    errors << "#{prefix}: initialState does not name a state: #{initial}" unless states.key?(initial)

    states.each do |code, state|
      state_prefix = "#{prefix} state #{code}"
      errors << "#{state_prefix}: invalid state code" unless code.match?(STATE_CODE)
      unless state.is_a?(Hash)
        errors << "#{state_prefix}: must be an object"
        next
      end
      errors << "#{state_prefix}: invalid category #{state['category']}" unless CATEGORIES.include?(state["category"])
      terminal = state["terminalOutcome"]
      transitions = state.fetch("transitions", [])
      errors << "#{state_prefix}: transitions must be an array" unless transitions.is_a?(Array)
      transitions = [] unless transitions.is_a?(Array)
      if terminal
        errors << "#{state_prefix}: invalid terminalOutcome #{terminal}" unless TERMINAL_OUTCOMES.include?(terminal)
        errors << "#{state_prefix}: terminal states cannot have outgoing transitions" unless transitions.empty?
        errors << "#{state_prefix}: invalid contractStatusContribution" unless CONTRACT_CONTRIBUTIONS.include?(state["contractStatusContribution"])
      elsif transitions.empty?
        errors << "#{state_prefix}: non-terminal state has no outgoing transition"
      end
      validate_requirements(state_prefix, state.fetch("requirements", []), schemas, errors)
      transitions.each { |transition| validate_transition(state_prefix, transition, states, flow_catalog, errors) }
    end

    return unless states.key?(initial)
    reachable = reachable_states(initial, states)
    (states.keys - reachable).each { |code| errors << "#{prefix}: unreachable state #{code}" }
  end

  def validate_requirements(prefix, requirements, schemas, errors)
    unless requirements.is_a?(Array)
      errors << "#{prefix}: requirements must be an array"
      return
    end
    ids = requirements.filter_map { |entry| entry["requirementId"] if entry.is_a?(Hash) }
    duplicate_values(ids).each { |id| errors << "#{prefix}: duplicate requirement ID #{id}" }
    requirements.each do |requirement|
      unless requirement.is_a?(Hash)
        errors << "#{prefix}: requirement must be an object"
        next
      end
      schema_name = requirement["targetSchema"]
      pointer = requirement["targetPointer"]
      schema = schemas[schema_name]
      if schema.nil?
        errors << "#{prefix}: unknown requirement targetSchema #{schema_name}"
      elsif !resolve_pointer(schema, pointer)
        errors << "#{prefix}: requirement #{requirement['requirementId']} has unresolved targetPointer #{pointer} in #{schema_name}"
      end
    end
  end

  def validate_transition(prefix, transition, states, flow_catalog, errors)
    unless transition.is_a?(Hash)
      errors << "#{prefix}: transition must be an object"
      return
    end
    target = transition["to"]
    errors << "#{prefix}: transition target does not exist: #{target}" unless states.key?(target)
    Array(transition["flowRefs"]).each do |flow_ref|
      errors << "#{prefix}: unresolved flowRef #{flow_ref}" unless flow_catalog.key?(flow_ref)
    end
    Array(transition["guards"]).each do |guard|
      unless guard.is_a?(Hash) && guard["guardId"].to_s.match?(IDENTIFIER) && GUARD_OPERATORS.include?(guard["operator"])
        errors << "#{prefix}: invalid typed guard"
      end
      if guard.is_a?(Hash) && guard["operator"] != "EXISTS" && !guard.key?("value")
        errors << "#{prefix}: typed guard #{guard['guardId']} requires a value"
      end
    end
    Array(transition["effects"]).each do |effect|
      unless effect.is_a?(Hash) && EFFECT_TYPES.include?(effect["effectType"])
        errors << "#{prefix}: invalid typed effect"
      end
    end
  end

  def reachable_states(initial, states)
    visited = []
    queue = [initial]
    until queue.empty?
      code = queue.shift
      next if visited.include?(code) || !states.key?(code)
      visited << code
      Array(states.dig(code, "transitions")).each { |transition| queue << transition["to"] if transition.is_a?(Hash) }
    end
    visited
  end

  def resolve_pointer(document, pointer)
    return false unless pointer.is_a?(String) && pointer.start_with?("/")
    pointer.split("/").drop(1).reduce(document) do |node, segment|
      break nil unless node.is_a?(Hash)
      node[segment.gsub("~1", "/").gsub("~0", "~")]
    end
  end

  def validate_flow_documents(release_root, machines, errors)
    flow_files = %w[yaml yml json].flat_map do |extension|
      release_root.glob("flows/logistics/**/*.#{extension}")
    end
    flow_files.sort.each do |path|
      document = load_yaml(path, errors)
      walk(document) do |key, value|
        next unless %w[stateMachine performanceStateMachine].include?(key) && value.is_a?(String)
        fragment = value.split("#", 2)[1]
        errors << "#{path.relative_path_from(release_root)}: state-machine reference has no fragment" if fragment.to_s.empty?
        errors << "#{path.relative_path_from(release_root)}: unknown state machine #{fragment}" if !fragment.to_s.empty? && !machines.key?(fragment)
      end
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

  def duplicate_values(values)
    values.group_by(&:itself).select { |_, entries| entries.length > 1 }.keys
  end
end

if $PROGRAM_NAME == __FILE__
  release_root = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/release1")))
  registry_path = release_root.join("schema/extension/logistics/LogisticsPerformanceStates/v1/states.yaml")
  errors = IonLogisticsPerformanceStates.validate(registry_path, release_root: release_root)
  if errors.empty?
    registry = YAML.safe_load_file(registry_path, aliases: false)
    state_count = registry.fetch("machines").values.sum { |machine| machine.fetch("states").length }
    puts "Logistics performance-state validation passed: #{registry.fetch('machines').length} machines, #{state_count} states"
  else
    warn "Logistics performance-state validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
