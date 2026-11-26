#!/usr/bin/env ruby

require "minitest/autorun"
require_relative "../validate_manifest"

class ValidateManifestTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/valid-draft.yaml", __dir__)

  def setup
    @manifest = IonReleaseManifest.load(FIXTURE)
  end

  def test_valid_draft
    assert_empty IonReleaseManifest.validate(@manifest)
  end

  def test_valid_version_2_draft_requires_rules_status
    @manifest["schemaVersion"] = 2
    @manifest["contentStatus"]["rules"] = "review-required"

    assert_empty IonReleaseManifest.validate(@manifest)
  end

  def test_version_1_rejects_rules_status
    @manifest["contentStatus"]["rules"] = "review-required"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "contentStatus has unknown areas: rules"
  end

  def test_version_2_requires_rules_status
    @manifest["schemaVersion"] = 2

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "contentStatus missing: rules"
  end

  def test_rejects_unsupported_manifest_schema_version
    @manifest["schemaVersion"] = 3

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "schemaVersion must be 1 or 2"
  end

  def test_draft_is_rejected_by_publication_gate
    errors = IonReleaseManifest.validate_for_publication(@manifest)

    assert_includes errors, "release status must be published"
  end

  def test_release_name_and_url_must_match_number
    @manifest["name"] = "release2"
    @manifest["publicBaseUrl"] = "https://schema.ion.id/release2/"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "name must equal release1"
    assert_includes errors, "publicBaseUrl must equal https://schema.ion.id/release1/"
  end

  def test_draft_may_not_have_publication_date
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"

    assert_includes IonReleaseManifest.validate(@manifest), "draft publishedAt must be null"
  end

  def test_draft_rejects_ion_owned_artifact_checksum
    @manifest["artifactChecksums"] = {
      "flows/trade/pattern.yaml" => "b" * 64
    }

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "draft artifactChecksums path must be under schema/vendored/: flows/trade/pattern.yaml"
  end

  def test_policy_status_is_not_part_of_release_manifest
    @manifest["contentStatus"]["policies"] = "validated"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "contentStatus has unknown areas: policies"
  end

  def test_published_release_rejects_pending_content_and_dependencies
    @manifest["status"] = "published"
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"

    errors = IonReleaseManifest.validate(@manifest)

    assert errors.any? { |error| error.include?("must be validated or excluded") }
    assert_includes errors, "published dependencyStatus must be complete"
    assert_includes errors, "published dependencies must not be empty"
    assert_includes errors, "published artifactChecksums must not be empty"
    assert_includes errors, "published toolingCommit must be a 40-character commit"
  end

  def test_published_version_2_release_rejects_pending_rules
    @manifest["schemaVersion"] = 2
    @manifest["contentStatus"]["rules"] = "review-required"
    @manifest["status"] = "published"
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "published rules must be validated or excluded"
  end

  def test_versioned_implementation_guidance_areas
    @manifest["implementationGuidance"]["areas"]["rules"] = {
      "maturity" => "preview",
      "notes" => ["Rules are under implementation review."]
    }

    assert_includes IonReleaseManifest.validate(@manifest), "implementationGuidance.areas has unknown area: rules"

    @manifest["schemaVersion"] = 2
    @manifest["contentStatus"]["rules"] = "review-required"

    refute_includes IonReleaseManifest.validate(@manifest), "implementationGuidance.areas has unknown area: rules"
  end

  def test_published_release_may_explicitly_exclude_ion_api
    @manifest["status"] = "published"
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"
    @manifest["contentStatus"].transform_values! { "excluded" }
    @manifest["contentStatus"]["common"] = "validated"
    @manifest["contentStatus"]["trade"] = "validated"
    @manifest["dependencyStatus"] = "complete"
    @manifest["dependencies"] = [valid_dependency]
    @manifest["artifactChecksums"] = {
      "schema/vendored/beckn/api/v2.0.0/beckn.yaml" => "b" * 64
    }
    @manifest["toolingCommit"] = "a" * 40

    assert_empty IonReleaseManifest.validate(@manifest)
  end

  def test_dependency_paths_must_stay_inside_release
    @manifest["dependencies"] = [valid_dependency.merge("vendoredPath" => "../outside.yaml")]

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "dependency 0 vendoredPath must be release-relative"
  end

  def test_dependency_paths_must_use_nested_schema_layout
    @manifest["dependencies"] = [valid_dependency.merge("vendoredPath" => "vendored/beckn.yaml")]

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "dependency 0 vendoredPath must be under schema/vendored/"
  end

  def test_maintained_protocol_requires_a_core_path_and_transformations
    @manifest["maintainedArtifacts"] = [{
      "name" => "IONBecknProtocol",
      "type" => "protocol",
      "path" => "schema/vendored/beckn/api/v2.0.0/beckn.yaml",
      "upstreamVersion" => "2.0.0",
      "upstreamRepository" => "https://github.com/beckn/protocol-specifications-v2",
      "upstreamCommit" => "a" * 40,
      "upstreamUrl" => "https://raw.githubusercontent.com/example/beckn.yaml",
      "upstreamSha256" => "b" * 64,
      "releasedSha256" => "c" * 64,
      "license" => "CC-BY-NC-SA-4.0",
      "transformations" => []
    }]

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "maintained artifact 0 path must be under schema/core/"
    assert_includes errors, "maintained artifact 0 transformations must be a non-empty array"
  end

  def test_implementation_guidance_rejects_unknown_maturity
    @manifest["implementationGuidance"]["areas"]["trade"]["maturity"] = "battle-ready"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "implementationGuidance.areas.trade has invalid maturity: battle-ready"
  end

  def test_trade_primary_profile_must_match_release_primary_profile
    @manifest["implementationGuidance"]["areas"]["trade"]["primaryProfile"] = "another-profile"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "Trade primaryProfile must match implementationGuidance.primaryProfile.id"
  end

  private

  def valid_dependency
    {
      "name" => "beckn-protocol",
      "type" => "protocol",
      "upstreamVersion" => "v2.0.0",
      "upstreamRepository" => "https://github.com/beckn/protocol-specifications-v2",
      "upstreamCommit" => "a" * 40,
      "upstreamUrl" => "https://raw.githubusercontent.com/example/beckn.yaml",
      "vendoredPath" => "schema/vendored/beckn/api/v2.0.0/beckn.yaml",
      "upstreamSha256" => "b" * 64,
      "releasedSha256" => "b" * 64,
      "license" => "CC-BY-NC-SA-4.0",
      "transformations" => []
    }
  end
end
