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

  def test_unrecorded_ion_owned_file_is_rejected
    with_release do |root, manifest|
      FileUtils.mkdir_p(File.join(root, "flows/trade"))
      File.write(File.join(root, "flows/trade/pattern.yaml"), "id: storefront\n")
      errors = IonArtifactChecksums.validate(root, manifest)
      assert_includes errors, "release artifact is not checksummed: flows/trade/pattern.yaml"
    end
  end

  private

  def with_release
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/vendored"))
      relative = "schema/vendored/dependency.yaml"
      File.write(File.join(root, relative), "content")
      checksum = Digest::SHA256.hexdigest("content")
      manifest = {
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
