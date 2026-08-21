#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../validate_release_scope"

class ValidateReleaseScopeTest < Minitest::Test
  def test_validated_and_excluded_areas_are_enforced
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common"))
      FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      FileUtils.mkdir_p(File.join(root, "policies"))
      FileUtils.mkdir_p(File.join(root, "errors"))
      manifest = { "contentStatus" => statuses }
      assert_empty IonReleaseScope.validate(root, manifest)

      FileUtils.mkdir_p(File.join(root, "schema/extension/logistics"))
      errors = IonReleaseScope.validate(root, manifest)
      assert errors.any? { |error| error.include?("excluded content is present for logistics") }
    end
  end

  def test_missing_validated_area_is_rejected
    Dir.mktmpdir do |root|
      errors = IonReleaseScope.validate(root, "contentStatus" => statuses)
      assert_includes errors, "validated content is absent for common"
      assert_includes errors, "validated content is absent for trade"
    end
  end

  def test_flat_schema_directory_is_rejected
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common"))
      FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      FileUtils.mkdir_p(File.join(root, "policies"))
      FileUtils.mkdir_p(File.join(root, "errors"))
      FileUtils.mkdir_p(File.join(root, "common"))

      errors = IonReleaseScope.validate(root, "contentStatus" => statuses)

      assert_includes errors, "schema content must be nested under schema/: common"
    end
  end

  private

  def statuses
    {
      "ionApi" => "excluded",
      "common" => "validated",
      "trade" => "validated",
      "logistics" => "excluded",
      "hospitality" => "excluded",
      "finance" => "excluded",
      "flows" => "validated",
      "policies" => "validated",
      "errors" => "validated"
    }
  end
end
