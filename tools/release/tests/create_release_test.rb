#!/usr/bin/env ruby

require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../create_release"

class CreateReleaseTest < Minitest::Test
  def test_dry_run_does_not_create_target
    with_published_release do |root, source, target|
      result = IonReleaseCreate.create(source, target)

      assert_equal "dry-run", result["mode"]
      refute File.exist?(target)
    end
  end

  def test_write_creates_next_draft_and_rewrites_namespace
    with_published_release do |_root, source, target|
      IonReleaseCreate.create(source, target, write: true)

      manifest = YAML.safe_load(File.read(File.join(target, "release.yaml")))
      assert_equal 2, manifest["release"]
      assert_equal "release2", manifest["name"]
      assert_equal "draft", manifest["status"]
      assert_nil manifest["publishedAt"]
      assert_nil manifest["toolingCommit"]
      assert_equal "https://schema.ion.id/release2/", manifest["publicBaseUrl"]
      assert_empty manifest["artifactChecksums"]
      assert_includes manifest.fetch("notes").first, "Release 2"
      refute_includes manifest.fetch("notes").first, "Release 1"
      assert_includes manifest.dig("implementationGuidance", "areas", "logistics", "notes").first, "Release 3"
      assert_includes File.read(File.join(target, "schema", "thing.yaml")), "schema.ion.id/release2/"
      assert_includes File.read(File.join(target, "README.md")), "Status: DRAFT"
      assert_includes File.read(File.join(target, "NOTICES.md")), "Draft Release 2 baseline"
    end
  end

  def test_rejects_nonsequential_target
    with_published_release do |root, source, _target|
      error = assert_raises(ArgumentError) do
        IonReleaseCreate.create(source, File.join(root, "release3"), write: true)
      end

      assert_equal "target must be the next integer release", error.message
    end
  end

  def test_version_2_rules_are_preserved_in_next_draft
    with_published_release(release_number: 2, schema_version: 2, with_rules: true) do |_root, source, target|
      IonReleaseCreate.create(source, target, write: true)

      manifest = YAML.safe_load(File.read(File.join(target, "release.yaml")))
      assert_equal 2, manifest["schemaVersion"]
      assert_equal 3, manifest["release"]
      assert_equal "release3", manifest["name"]
      assert_equal "validated", manifest.dig("contentStatus", "rules")
      assert_includes File.read(File.join(target, "rules", "policy.rego")), "package ion.release3"
    end
  end

  private

  def with_published_release(release_number: 1, schema_version: 1, with_rules: false)
    Dir.mktmpdir do |root|
      source = File.join(root, "release#{release_number}")
      target = File.join(root, "release#{release_number + 1}")
      FileUtils.mkdir_p(File.join(source, "schema"))
      if with_rules
        FileUtils.mkdir_p(File.join(source, "rules"))
        File.write(File.join(source, "rules", "policy.rego"), "package ion.release#{release_number}\n")
      end
      File.write(
        File.join(source, "release.yaml"),
        {
          "schemaVersion" => schema_version,
          "release" => release_number,
          "name" => "release#{release_number}",
          "status" => "published",
          "publishedAt" => "2026-11-21T00:00:00Z",
          "publicBaseUrl" => "https://schema.ion.id/release#{release_number}/",
          "toolingCommit" => "a" * 40,
          "artifactChecksums" => { "schema/thing.yaml" => "b" * 64 },
          "contentStatus" => schema_version == 2 ? { "rules" => "validated" } : {},
          "implementationGuidance" => {
            "areas" => {
              "logistics" => {
                "notes" => ["Implementers should expect refinements in Release #{release_number + 1}."]
              }
            }
          },
          "notes" => [
            "Release #{release_number} uses https://schema.ion.id/release#{release_number}/schema/thing.yaml.",
            "Release URLs became permanent when Release #{release_number} was published."
          ]
        }.to_yaml
      )
      File.write(File.join(source, "schema", "thing.yaml"), "$ref: https://schema.ion.id/release#{release_number}/schema/thing.yaml\n")
      File.write(
        File.join(source, "README.md"),
        "> **Status: PUBLISHED — `current` channel.**\n\nRelease #{release_number} was published on 21 November 2026 as the inaugural `current` release.\nEvery file in this directory is now immutable.\n\nRun the publication gate to verify the immutable release and its channel\nassignment:\n"
      )
      File.write(
        File.join(source, "NOTICES.md"),
        "**Status:** Published Release #{release_number}\n\nThis notice records the dependency provenance of the published Release #{release_number} bundle.\n"
      )
      yield root, source, target
    end
  end
end
