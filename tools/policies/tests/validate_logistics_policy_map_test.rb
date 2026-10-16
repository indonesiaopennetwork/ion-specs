#!/usr/bin/env ruby

require "json"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../validate_logistics_policy_map"

class ValidateLogisticsPolicyMapTest < Minitest::Test
  def test_accepts_registered_target_and_explained_deferral
    with_files(
      {
        "entries" => {
          "ion://policy/legacy.one" => {
            "disposition" => "reused",
            "targetIri" => "ion://policy/current.one"
          },
          "ion://policy/legacy.two" => {
            "disposition" => "deferred",
            "reason" => "No authoritative source."
          }
        }
      },
      ["ion://policy/current.one"]
    ) do |map_path, registry_path|
      assert_empty IonLogisticsPolicyMap.validate(map_path, registry_path)
    end
  end

  def test_rejects_missing_target_and_unexplained_deferral
    with_files(
      {
        "entries" => {
          "ion://policy/legacy.one" => {
            "disposition" => "migrated",
            "targetIri" => "ion://policy/missing"
          },
          "ion://policy/legacy.two" => { "disposition" => "deferred" }
        }
      },
      []
    ) do |map_path, registry_path|
      errors = IonLogisticsPolicyMap.validate(map_path, registry_path)
      assert errors.any? { |error| error.include?("target policy is not registered") }
      assert errors.any? { |error| error.include?("must explain its reason") }
    end
  end

  private

  def with_files(map, iris)
    Dir.mktmpdir do |directory|
      map_path = File.join(directory, "map.yaml")
      registry_path = File.join(directory, "registry.json")
      File.write(map_path, YAML.dump(map))
      registry = { "policies" => iris.map { |iri| { "iri" => iri } } }
      File.write(registry_path, JSON.generate(registry))
      yield map_path, registry_path
    end
  end
end
