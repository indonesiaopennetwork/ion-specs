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

  def test_draft_is_rejected_by_publication_gate
    errors = IonReleaseManifest.validate_for_publication(@manifest)

    assert_includes errors, "release status must be published"
  end

  def test_release_name_and_url_must_match_number
    @manifest["name"] = "release2"
    @manifest["publicBaseUrl"] = "https://schema.ion.id/releases/release2/"

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "name must equal release1"
    assert_includes errors, "publicBaseUrl must equal https://schema.ion.id/releases/release1/"
  end

  def test_draft_may_not_have_publication_date
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"

    assert_includes IonReleaseManifest.validate(@manifest), "draft publishedAt must be null"
  end

  def test_published_release_rejects_pending_content_and_dependencies
    @manifest["status"] = "published"
    @manifest["publishedAt"] = "2026-08-21T00:00:00Z"

    errors = IonReleaseManifest.validate(@manifest)

    assert errors.any? { |error| error.include?("published ionApi") }
    assert errors.any? { |error| error.include?("must be validated or excluded") }
    assert_includes errors, "published dependencyStatus must be complete"
    assert_includes errors, "published dependencies must not be empty"
    assert_includes errors, "published artifactChecksums must not be empty"
    assert_includes errors, "published toolingCommit must be a 40-character commit"
  end

  def test_dependency_paths_must_stay_inside_release
    @manifest["dependencies"] = [valid_dependency.merge("vendoredPath" => "../outside.yaml")]

    errors = IonReleaseManifest.validate(@manifest)

    assert_includes errors, "dependency 0 vendoredPath must be release-relative"
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
      "vendoredPath" => "vendored/beckn/protocol/v2.0.0/beckn.yaml",
      "upstreamSha256" => "b" * 64,
      "releasedSha256" => "b" * 64,
      "license" => "CC-BY-NC-SA-4.0",
      "transformations" => []
    }
  end
end
