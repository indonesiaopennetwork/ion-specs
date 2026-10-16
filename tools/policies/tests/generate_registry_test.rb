#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../generate_registry"

class GeneratePolicyRegistryTest < Minitest::Test
  def test_builds_root_policy_registry
    Dir.mktmpdir do |root|
      policy_dir = File.join(root, "policies", "return", "v1")
      FileUtils.mkdir_p(policy_dir)
      File.write(File.join(policy_dir, "standard.yaml"), <<~YAML)
        iri: ion://policy/return.standard.7d
        version: 1.0.0
        status: ratified
        displayText:
          id: Pengembalian tujuh hari
          en: Seven day return
      YAML
      _, registry, errors = IonPolicyRegistry.build(root)
      assert_empty errors
      assert_equal 1, registry["totalPolicies"]
      assert_equal "trade", registry["policies"][0]["sector"]
      assert_equal "policies/return/v1/standard.yaml", registry["policies"][0]["docPath"]
    end
  end

  def test_duplicate_policy_iris_are_rejected
    Dir.mktmpdir do |root|
      policy_dir = File.join(root, "policies", "return", "v1")
      FileUtils.mkdir_p(policy_dir)
      2.times do |index|
        File.write(File.join(policy_dir, "#{index}.yaml"), <<~YAML)
          iri: ion://policy/return.standard.7d
          version: 1.0.0
          status: ratified
          displayText: { id: Tujuh hari }
        YAML
      end
      _, _, errors = IonPolicyRegistry.build(root)
      assert errors.any? { |error| error.include?("duplicate policy IRI") }
    end
  end

  def test_logistics_policy_requires_explicit_lifecycle_applicability_and_provenance
    Dir.mktmpdir do |root|
      policy_dir = File.join(root, "policies", "sla", "v1")
      FileUtils.mkdir_p(policy_dir)
      File.write(File.join(policy_dir, "standard.yaml"), <<~YAML)
        iri: ion://policy/sla.standard
        version: 1.0.0
        status: draft
        sector: logistics
        displayText: { id: SLA standar }
      YAML

      _, _, errors = IonPolicyRegistry.build(root)
      assert errors.any? { |error| error.include?("missing Logistics metadata") }
      assert errors.any? { |error| error.include?("applicableCategories must include logistics") }
      assert errors.any? { |error| error.include?("sourceProvenance") }
    end
  end
end
