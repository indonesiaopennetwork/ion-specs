#!/usr/bin/env ruby

require "digest"
require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../validate_artifact_checksums"

class ValidateArtifactChecksumsTest < Minitest::Test
  def test_complete_release_inventory_passes
    with_release do |root, manifest|
      assert_empty IonArtifactChecksums.validate(root, manifest)
    end
  end

  def test_modified_artifact_is_rejected
    with_release do |root, manifest|
      File.write(File.join(root, "schema/vendored/dependency.yaml"), "changed")
      errors = IonArtifactChecksums.validate(root, manifest)
      assert errors.any? { |error| error.include?("checksum mismatch") }
    end
  end

  def test_unrecorded_release_file_is_rejected
    with_release do |root, manifest|
      File.write(File.join(root, "schema/vendored/unrecorded.yaml"), "extra")
      errors = IonArtifactChecksums.validate(root, manifest)
      assert_includes errors, "release artifact is not checksummed: schema/vendored/unrecorded.yaml"
    end
  end

  def test_unrecorded_ion_owned_file_is_allowed_in_draft
    with_release do |root, manifest|
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      File.write(File.join(root, "flows/trade/pattern.yaml"), "id: storefront\n")
      assert_empty IonArtifactChecksums.validate(root, manifest)
    end
  end

  def test_draft_rejects_checksum_for_ion_owned_file
    with_release do |root, manifest|
      relative = "flows/trade/pattern.yaml"
      FileUtils.mkdir_p(File.dirname(File.join(root, relative)))
      File.write(File.join(root, relative), "id: storefront\n")
      manifest["artifactChecksums"][relative] = Digest::SHA256.hexdigest("id: storefront\n")

      errors = IonArtifactChecksums.validate(root, manifest)
      assert_includes errors, "draft checksum records ION-authored artifact: flows/trade/pattern.yaml"
    end
  end

  def test_unrecorded_ion_owned_file_is_rejected_after_publication
    with_release(status: "published") do |root, manifest|
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      File.write(File.join(root, "flows/trade/pattern.yaml"), "id: storefront\n")
      errors = IonArtifactChecksums.validate(root, manifest)
      assert_includes errors, "release artifact is not checksummed: flows/trade/pattern.yaml"
    end
  end

  def test_recorded_ion_owned_file_passes_after_publication
    with_release(status: "published") do |root, manifest|
      relative = "flows/trade/pattern.yaml"
      FileUtils.mkdir_p(File.dirname(File.join(root, relative)))
      File.write(File.join(root, relative), "id: storefront\n")
      manifest["artifactChecksums"][relative] = Digest::SHA256.hexdigest("id: storefront\n")

      assert_empty IonArtifactChecksums.validate(root, manifest)
    end
  end

  def test_os_metadata_is_not_a_release_artifact
    with_release do |root, manifest|
      File.write(File.join(root, "schema/.DS_Store"), "finder metadata")
      assert_empty IonArtifactChecksums.validate(root, manifest)
    end
  end

  private

  def with_release(status: "draft")
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/vendored"))
      relative = "schema/vendored/dependency.yaml"
      File.write(File.join(root, relative), "content")
      checksum = Digest::SHA256.hexdigest("content")
      manifest = {
        "status" => status,
        "artifactChecksums" => { relative => checksum },
        "dependencies" => [{
          "name" => "dependency",
          "vendoredPath" => relative,
          "releasedSha256" => checksum
        }]
      }
      yield root, manifest
    end
  end
end
