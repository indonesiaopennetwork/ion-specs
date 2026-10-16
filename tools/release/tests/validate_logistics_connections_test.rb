#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../validate_logistics_connections"

class ValidateLogisticsConnectionsTest < Minitest::Test
  def test_release_flows_are_connected
    release_root = File.expand_path("../../../releases/release1", __dir__)
    repository_root = File.expand_path("../../..", __dir__)
    assert_empty IonLogisticsConnections.validate(release_root, repository_root: repository_root)
  end

  def test_reports_unknown_action_machine_policy_and_flow_owner
    Dir.mktmpdir do |repository_root|
      release_root = File.join(repository_root, "releases/release1")
      build_fixture(release_root, repository_root)
      profile = File.join(release_root, "flows/logistics/patterns/parcel/v1/profile.json")
      FileUtils.mkdir_p(File.dirname(profile))
      File.write(profile, <<~JSON)
        {"id":"sample","spineFile":"./pattern.yaml","performanceStateMachine":"flows/logistics/state-machines/v1/states.yaml#missing","flowIds":["missing-flow"],"requiredPolicyRefs":["ion://policy/missing"]}
      JSON
      File.write(File.join(File.dirname(profile), "pattern.yaml"), {"steps" => [{"step" => "invented"}]}.to_yaml)
      errors = IonLogisticsConnections.validate(release_root, repository_root: repository_root)
      assert errors.any? { |error| error.include?("unsupported protocol action invented") }
      assert errors.any? { |error| error.include?("unknown state machine missing") }
      assert errors.any? { |error| error.include?("policy reference is not registered") }
      assert errors.any? { |error| error.include?("profile owns undeclared flow ID") }
    end
  end

  private

  def build_fixture(root, repository_root)
    FileUtils.mkdir_p(File.join(repository_root, "policies"))
    File.write(File.join(repository_root, "policies/registry.json"), '{"policies":[]}')
    FileUtils.mkdir_p(File.join(root, "flows/logistics/state-machines/v1"))
    File.write(File.join(root, "flows/logistics/state-machines/v1/states.yaml"), {"machines" => {"known" => {}}, "flowCatalog" => {}}.to_yaml)
  end
end
