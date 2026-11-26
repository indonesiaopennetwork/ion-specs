#!/usr/bin/env ruby

require "minitest/autorun"
require "openssl"
require "stringio"
require "tmpdir"
require_relative "../generate_test_key"

class GenerateTestKeyTest < Minitest::Test
  def test_dry_run_does_not_write_keys
    Dir.mktmpdir do |root|
      output = File.join(root, "keys")
      result = IonRegoTestKey.generate(output, repository_root: root, out: StringIO.new)

      assert_equal "dry-run", result.fetch(:mode)
      refute File.exist?(output)
    end
  end

  def test_write_generates_parseable_test_only_keypair
    Dir.mktmpdir do |root|
      result = IonRegoTestKey.generate(
        File.join(root, "keys"),
        repository_root: root,
        write: true,
        out: StringIO.new
      )

      private_key = OpenSSL::PKey.read(result.fetch(:private).read)
      public_key = OpenSSL::PKey.read(result.fetch(:public).read)
      assert private_key.private?
      refute public_key.private?
      assert_equal "write", result.fetch(:mode)
    end
  end

  def test_release_directory_is_rejected
    Dir.mktmpdir do |root|
      error = assert_raises(ArgumentError) do
        IonRegoTestKey.generate(
          File.join(root, "releases", "release2", "rules", "keys"),
          repository_root: root,
          write: true,
          out: StringIO.new
        )
      end

      assert_equal "test keys must not be written inside releases/", error.message
    end
  end
end
