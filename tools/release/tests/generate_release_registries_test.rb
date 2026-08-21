#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../generate_release_registries"

class GenerateReleaseRegistriesTest < Minitest::Test
  def test_builds_release_local_policy_and_error_views
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
      FileUtils.mkdir_p(File.join(root, "errors"))
      File.write(File.join(root, "errors", "trade.yaml"), <<~YAML)
        - code: ION-A2001
          title: { en: Invalid resource }
      YAML

      policy, error = IonReleaseRegistries.build(root)
      assert_empty policy[2]
      assert_equal 1, policy[1]["totalPolicies"]
      assert_equal "trade", policy[1]["policies"][0]["sector"]
      assert_empty error[2]
      assert_equal 1, error[1]["count"]
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
      FileUtils.mkdir_p(File.join(root, "errors"))
      File.write(File.join(root, "errors", "trade.yaml"), "[]\n")
      policy, = IonReleaseRegistries.build(root)
      assert policy[2].any? { |error| error.include?("duplicate policy IRI") }
    end
  end
end
