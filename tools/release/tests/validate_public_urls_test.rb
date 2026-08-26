#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../validate_public_urls"

class ValidatePublicUrlsTest < Minitest::Test
  def test_release_url_must_map_to_existing_file
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "schema/common/Address/v1"))
      File.write(File.join(root, "schema/common/Address/v1/attributes.yaml"), "type: object\n")
      manifest = { "publicBaseUrl" => "https://schema.ion.id/release9/" }
      File.write(
        File.join(root, "example.json"),
        '{"$ref":"https://schema.ion.id/release9/schema/common/Address/v1/attributes.yaml"}'
      )

      assert_empty IonReleasePublicUrls.validate(root, manifest)

      File.write(
        File.join(root, "example.json"),
        '{"$ref":"https://schema.ion.id/release9/common/Address/v1/attributes.yaml"}'
      )
      errors = IonReleasePublicUrls.validate(root, manifest)
      assert errors.any? { |error| error.include?("public URL target does not exist") }
    end
  end

  def test_rejects_legacy_and_cross_release_urls
    Dir.mktmpdir do |root|
      manifest = { "publicBaseUrl" => "https://schema.ion.id/release9/" }
      File.write(
        File.join(root, "example.json"),
        <<~JSON
          {
            "legacy": "https://schema.ion.id/releases/release9/schema/example.json",
            "crossRelease": "https://schema.ion.id/release8/schema/example.json"
          }
        JSON
      )

      errors = IonReleasePublicUrls.validate(root, manifest)

      assert errors.any? { |error| error.include?("legacy public URL namespace") }
      assert errors.any? { |error| error.include?("public URL falls outside https://schema.ion.id/release9/") }
    end
  end
end
