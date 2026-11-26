#!/usr/bin/env ruby

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../validate_sources"

class ValidateSourcesTest < Minitest::Test
  def test_manifest_v1_skips_rego_without_requiring_opa_or_rules_directory
    Dir.mktmpdir do |root|
      File.write(File.join(root, "release.yaml"), "schemaVersion: 1\nrelease: 1\n")
      out = StringIO.new
      err = StringIO.new

      assert IonRegoSourceValidation.validate(root, opa: "definitely-missing-opa", out: out, err: err)
      assert_includes out.string, "not applicable to manifest schema v1"
      assert_empty err.string
    end
  end
end
