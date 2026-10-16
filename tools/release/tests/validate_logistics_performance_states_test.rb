#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../validate_logistics_performance_states"

class ValidateLogisticsPerformanceStatesTest < Minitest::Test
  RELEASE_ROOT = File.expand_path("../../../releases/release1", __dir__)
  REGISTRY = File.join(RELEASE_ROOT, "schema/extension/logistics/LogisticsPerformanceStates/v1/states.yaml")

  def test_release_registry_is_valid
    assert_empty IonLogisticsPerformanceStates.validate(REGISTRY, release_root: RELEASE_ROOT)
  end

  def test_reports_graph_and_terminal_defects
    with_release do |root, registry|
      registry["machines"]["sample"]["states"]["START"]["transitions"] = [{"to" => "MISSING"}]
      registry["machines"]["sample"]["states"]["ORPHAN"] = {"terminalOutcome" => "SUCCESS", "contractStatusContribution" => "COMPLETE"}
      errors = validate_fixture(root, registry)
      assert errors.any? { |error| error.include?("transition target does not exist: MISSING") }
      assert errors.any? { |error| error.include?("unreachable state DONE") }
      assert errors.any? { |error| error.include?("unreachable state ORPHAN") }
    end
  end

  def test_reports_bad_requirement_and_flow_references
    with_release do |root, registry|
      transition = registry["machines"]["sample"]["states"]["START"]["transitions"].first
      transition["flowRefs"] = ["missing-flow"]
      registry["machines"]["sample"]["states"]["START"]["requirements"] = [{
        "requirementId" => "missing", "targetSchema" => "LogisticsPerformance", "targetPointer" => "/components/schemas/LogisticsPerformance/properties/missing"
      }]
      errors = validate_fixture(root, registry)
      assert errors.any? { |error| error.include?("unresolved flowRef missing-flow") }
      assert errors.any? { |error| error.include?("unresolved targetPointer") }
    end
  end

  def test_reports_unknown_machine_in_logistics_flow
    with_release do |root, registry|
      flow_dir = File.join(root, "flows/logistics/sample/v1")
      FileUtils.mkdir_p(flow_dir)
      File.write(File.join(flow_dir, "profile.yaml"), {"stateMachine" => "states.yaml#unknown"}.to_yaml)
      errors = validate_fixture(root, registry)
      assert errors.any? { |error| error.include?("unknown state machine unknown") }, errors.inspect
    end
  end

  private

  def with_release
    Dir.mktmpdir do |root|
      %w[LogisticsPerformance LogisticsContract].each do |name|
        path = File.join(root, "schema/extension/logistics/#{name}/v1")
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "attributes.yaml"), {
          "components" => {"schemas" => {name => {"properties" => {"events" => {"type" => "array"}}}}}
        }.to_yaml)
      end
      yield root, valid_registry
    end
  end

  def validate_fixture(root, registry)
    path = File.join(root, "states.yaml")
    File.write(path, registry.to_yaml)
    IonLogisticsPerformanceStates.validate(path, release_root: root)
  end

  def valid_registry
    {
      "registryVersion" => "1.0.0",
      "contractStatusAggregation" => [{"ruleId" => "complete", "when" => "ALL_REQUIRED_TERMINAL_SUCCESS", "contractStatus" => "COMPLETE"}],
      "flowCatalog" => {"known-flow" => {"status" => "planned"}},
      "machines" => {
        "sample" => {
          "machineId" => "sample", "version" => "1.0.0", "initialState" => "START",
          "states" => {
            "START" => {"category" => "BOOKING", "transitions" => [{"to" => "DONE", "flowRefs" => ["known-flow"]}]},
            "DONE" => {"category" => "DELIVERY", "terminalOutcome" => "SUCCESS", "contractStatusContribution" => "COMPLETE"}
          }
        }
      }
    }
  end
end
