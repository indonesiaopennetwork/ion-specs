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

  private

  def with_published_release
    Dir.mktmpdir do |root|
      source = File.join(root, "release1")
      target = File.join(root, "release2")
      FileUtils.mkdir_p(File.join(source, "schema"))
      File.write(
        File.join(source, "release.yaml"),
        {
          "release" => 1,
          "name" => "release1",
          "status" => "published",
          "publishedAt" => "2026-11-21T00:00:00Z",
          "publicBaseUrl" => "https://schema.ion.id/release1/",
          "toolingCommit" => "a" * 40,
          "artifactChecksums" => { "schema/thing.yaml" => "b" * 64 },
          "implementationGuidance" => {
            "areas" => {
              "logistics" => {
                "notes" => ["Implementers should expect refinements in Release 2."]
              }
            }
          },
          "notes" => [
            "Release 1 uses https://schema.ion.id/release1/schema/thing.yaml.",
            "Release URLs became permanent when Release 1 was published."
          ]
        }.to_yaml
      )
      File.write(File.join(source, "schema", "thing.yaml"), "$ref: https://schema.ion.id/release1/schema/thing.yaml\n")
      File.write(
        File.join(source, "README.md"),
        "> **Status: PUBLISHED — `current` channel.**\n\nRelease 1 was published on 21 November 2026 as the inaugural `current` release.\nEvery file in this directory is now immutable.\n\nRun the publication gate to verify the immutable release and its channel\nassignment:\n"
      )
      File.write(
        File.join(source, "NOTICES.md"),
        "**Status:** Published Release 1\n\nThis notice records the dependency provenance of the published Release 1 bundle.\n"
      )
      yield root, source, target
    end
  end
end
