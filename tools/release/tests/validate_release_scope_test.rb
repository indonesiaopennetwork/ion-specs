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

  def test_logistics_flow_is_rejected_while_logistics_is_excluded
    Dir.mktmpdir do |root|
      create_validated_baseline(root)
      FileUtils.mkdir_p(File.join(root, "flows/logistics"))

      errors = IonReleaseScope.validate(root, "contentStatus" => statuses)

      assert_includes errors, "excluded content is present for logistics: flows/logistics"
    end
  end

  def test_review_required_logistics_allows_logistics_flow
    Dir.mktmpdir do |root|
      create_validated_baseline(root)
      FileUtils.mkdir_p(File.join(root, "flows/logistics"))
      manifest = {
        "contentStatus" => statuses.merge("logistics" => "review-required")
      }

      errors = IonReleaseScope.validate(root, manifest)

      refute errors.any? { |error| error.include?("excluded content is present for logistics") }
    end
  end

  def test_validated_flow_scope_accepts_logistics_flow
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common"))
      FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
      FileUtils.mkdir_p(File.join(root, "flows/logistics"))
      FileUtils.mkdir_p(File.join(root, "errors"))
      manifest = {
        "contentStatus" => statuses.merge("logistics" => "review-required")
      }

      errors = IonReleaseScope.validate(root, manifest)

      refute_includes errors, "validated content is absent for flows"
    end
  end

  def test_versioned_ion_additional_api_satisfies_validated_ion_api_scope
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/core/api/v2.0.0"))
      File.write(File.join(root, "schema/core/api/v2.0.0/ion-additional.yaml"), "openapi: 3.1.0\n")
      manifest = { "contentStatus" => statuses.merge("ionApi" => "validated") }

      errors = IonReleaseScope.validate(root, manifest)

      refute_includes errors, "validated content is absent for ionApi"
    end
  end

  def test_vendored_beckn_protocol_does_not_satisfy_validated_ion_api_scope
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/vendored/beckn/api/v2.0.0"))
      File.write(File.join(root, "schema/vendored/beckn/api/v2.0.0/beckn.yaml"), "openapi: 3.1.0\n")
      manifest = { "contentStatus" => statuses.merge("ionApi" => "validated") }

      errors = IonReleaseScope.validate(root, manifest)

      assert_includes errors, "validated content is absent for ionApi"
    end
  end

  def test_flat_schema_directory_is_rejected
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common"))
      FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      FileUtils.mkdir_p(File.join(root, "errors"))
      FileUtils.mkdir_p(File.join(root, "common"))

      errors = IonReleaseScope.validate(root, "contentStatus" => statuses)

      assert_includes errors, "schema content must be nested under schema/: common"
    end
  end

  def test_release_local_policy_copy_is_rejected
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common"))
      FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      FileUtils.mkdir_p(File.join(root, "errors"))
      FileUtils.mkdir_p(File.join(root, "policies"))

      errors = IonReleaseScope.validate(root, "contentStatus" => statuses)

      assert_includes errors, "shared policies must not be copied into a release: policies"
    end
  end

  private

  def create_validated_baseline(root)
    FileUtils.mkdir_p(File.join(root, "schema/common"))
    FileUtils.mkdir_p(File.join(root, "schema/extension/trade"))
    FileUtils.mkdir_p(File.join(root, "flows/trade"))
    FileUtils.mkdir_p(File.join(root, "errors"))
  end

  def statuses
    {
      "ionApi" => "excluded",
      "common" => "validated",
      "trade" => "validated",
      "logistics" => "excluded",
      "hospitality" => "excluded",
      "finance" => "excluded",
      "flows" => "validated",
      "errors" => "validated"
    }
  end
end
