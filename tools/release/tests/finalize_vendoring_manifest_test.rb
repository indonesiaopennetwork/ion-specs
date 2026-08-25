#!/usr/bin/env ruby

require "digest"
require "fileutils"
require "minitest/autorun"
require "tmpdir"

require_relative "../finalize_vendoring_manifest"

class FinalizeVendoringManifestTest < Minitest::Test
  def test_protocol_dependency_records_no_transformation_when_bytes_match
    with_protocol_file("content") do |root, path, checksum|
      record = IonVendoringManifest.dependency_record(
        name: "BecknProtocol",
        type: "protocol",
        version: "2.0.0",
        upstream: upstream_record(checksum),
        target: path,
        release_root: root
      )

      assert_equal checksum, record["releasedSha256"]
      assert_empty record["transformations"]
    end
  end

  def test_protocol_dependency_rejects_cosmetic_release_differences
    with_protocol_file("content with trailing whitespace  \n") do |root, path, _checksum|
      upstream_checksum = Digest::SHA256.hexdigest("content\n")

      error = assert_raises(ArgumentError) do
        IonVendoringManifest.dependency_record(
          name: "BecknProtocol",
          type: "protocol",
          version: "2.0.0",
          upstream: upstream_record(upstream_checksum),
          target: path,
          release_root: root
        )
      end

      assert_includes error.message, "vendored protocol differs from upstream"
    end
  end

  private

  def with_protocol_file(content)
    Dir.mktmpdir do |root|
      path = File.join(root, "schema/vendored/beckn/protocol/v2.0.0/beckn.yaml")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      yield root, path, Digest::SHA256.hexdigest(content)
    end
  end

  def upstream_record(checksum)
    {
      "repository" => "https://github.com/beckn/protocol-specifications-v2",
      "commit" => "a" * 40,
      "rawUrl" => "https://raw.githubusercontent.com/example/beckn.yaml",
      "sha256" => checksum
    }
  end
end
