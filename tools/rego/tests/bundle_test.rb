#!/usr/bin/env ruby

require "minitest/autorun"
require "pathname"
require "stringio"
require "tmpdir"
require_relative "../lib/bundle"

class BundleTest < Minitest::Test
  def setup
    @opa = ENV["ION_OPA"] || find_opa
    skip "set ION_OPA to run OPA bundle tests" unless @opa && File.executable?(@opa)
  end

  def test_clean_source_builds_and_verifies_test_signed_bundle
    with_bundle do |release, bundle, public_key|
      errors = IonRegoBundle.verify(release, bundle, opa: @opa, public_key: public_key)

      assert_empty errors
      entries, archive_errors = IonRegoBundle.read_archive(bundle)
      assert_empty archive_errors
      assert_equal [".manifest", ".signatures.json", "data.json", "ion/release2/policy.rego"], entries.keys.sort
      refute entries.keys.any? { |name| name.include?("test") || name.end_with?(".pem") }
    end
  end

  def test_source_change_makes_bundle_stale
    with_bundle do |release, bundle, public_key|
      source = File.join(release, "rules/rego/ion/release2/policy.rego")
      File.open(source, "a") { |file| file.write("\n# one-byte-equivalent source change\n") }

      errors = IonRegoBundle.verify(release, bundle, opa: @opa, public_key: public_key, verify_with_opa: false)
      assert_includes errors, "bundle content is stale for ion/release2/policy.rego"
    end
  end

  def test_tampered_module_fails_content_and_signature_hash_checks
    with_bundle do |release, bundle, public_key, temporary|
      entries, = IonRegoBundle.read_archive(bundle)
      entries["ion/release2/policy.rego"] = entries.fetch("ion/release2/policy.rego") + "\n# tampered\n"
      tampered = File.join(temporary, "tampered.tar.gz")
      write_archive(tampered, entries.to_a)

      errors = IonRegoBundle.verify(release, tampered, opa: @opa, public_key: public_key, verify_with_opa: false)
      assert_includes errors, "bundle content is stale for ion/release2/policy.rego"
      assert_includes errors, "bundle signature hash mismatch for ion/release2/policy.rego"
    end
  end

  def test_wrong_key_fails_opa_verification
    with_bundle do |release, bundle, _public_key, temporary|
      wrong = IonRegoBundle.prepare_keys(Pathname.new(temporary).join("wrong"), :test, nil, nil).fetch(:public)
      errors = IonRegoBundle.verify(release, bundle, opa: @opa, public_key: wrong)

      assert errors.any? { |error| error.include?("OPA bundle signature verification failed") }
    end
  end

  def test_missing_and_duplicate_modules_are_rejected
    with_bundle do |release, bundle, public_key, temporary|
      entries, = IonRegoBundle.read_archive(bundle)
      missing = File.join(temporary, "missing.tar.gz")
      write_archive(missing, entries.reject { |name, _| name.end_with?("policy.rego") })
      missing_errors = IonRegoBundle.verify(release, missing, opa: @opa, public_key: public_key, verify_with_opa: false)
      assert_includes missing_errors, "bundle is missing source module or data: ion/release2/policy.rego"

      duplicate = File.join(temporary, "duplicate.tar.gz")
      write_archive(duplicate, entries.to_a + [["ion/release2/policy.rego", entries.fetch("ion/release2/policy.rego")]])
      duplicate_errors = IonRegoBundle.verify(release, duplicate, opa: @opa, public_key: public_key, verify_with_opa: false)
      assert_includes duplicate_errors, "bundle contains duplicate archive path: ion/release2/policy.rego"
    end
  end

  def test_unsafe_and_unexpected_archive_paths_are_rejected
    with_bundle do |release, bundle, public_key, temporary|
      entries, = IonRegoBundle.read_archive(bundle)
      hostile = File.join(temporary, "hostile.tar.gz")
      write_archive(hostile, entries.to_a + [["../escape.rego", "package escape\n"], ["TEST-ONLY-private.pem", "secret"]])

      errors = IonRegoBundle.verify(release, hostile, opa: @opa, public_key: public_key, verify_with_opa: false)
      assert errors.any? { |error| error.include?("unsafe archive path") }
      assert_includes errors, "bundle contains unexpected file: TEST-ONLY-private.pem"
    end
  end

  def test_oversize_bundle_is_rejected
    with_bundle do |release, bundle, public_key|
      errors = IonRegoBundle.verify(release, bundle, opa: @opa, public_key: public_key, max_bytes: 1, verify_with_opa: false)
      assert errors.any? { |error| error.include?("exceeds ONIX 10 MiB limit") }
    end
  end

  def test_unexpected_runtime_data_file_prevents_build
    Dir.mktmpdir do |temporary|
      release = build_release(temporary)
      write(File.join(release, "rules/data/secret.key"), "not allowed\n")
      error = StringIO.new
      refute IonRegoBundle.build(release, opa: @opa, signing_mode: :test, err: error)
      assert_includes error.string, "unexpected runtime data file"
    end
  end

  def test_test_module_under_production_tree_prevents_build
    Dir.mktmpdir do |temporary|
      release = build_release(temporary)
      write(File.join(release, "rules/rego/ion/release2/leaked_test.rego"), "package ion.release2\nimport rego.v1\n")
      error = StringIO.new
      refute IonRegoBundle.build(release, opa: @opa, signing_mode: :test, err: error)
      assert_includes error.string, "test module is not allowed in production sources"
    end
  end

  private

  def with_bundle
    Dir.mktmpdir do |temporary|
      release = build_release(temporary)
      assert IonRegoBundle.build(release, opa: @opa, signing_mode: :test, write: true, out: StringIO.new, err: StringIO.new)
      paths = IonRegoBundle.canonical_paths(release)
      yield release, paths.fetch(:bundle), paths.fetch(:test_public_key), temporary
    end
  end

  def build_release(root)
    release = File.join(root, "releases/release2")
    write(File.join(release, "release.yaml"), "schemaVersion: 2\nrelease: 2\n")
    write(File.join(release, "rules/data/data.json"), "{}\n")
    write(File.join(release, "rules/rego/ion/release2/policy.rego"), <<~REGO)
      package ion.release2

      import rego.v1

      result := {"valid": true, "violations": []}
    REGO
    write(File.join(release, "rules/tests/policy_test.rego"), "package ion.release2\nimport rego.v1\n")
    release
  end

  def write_archive(path, entries)
    Zlib::GzipWriter.open(path) do |gzip|
      Gem::Package::TarWriter.new(gzip) do |tar|
        entries.each do |name, content|
          tar.add_file_simple(name, 0o600, content.bytesize) { |file| file.write(content) }
        end
      end
    end
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def find_opa
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
      candidate = File.join(directory, "opa")
      return candidate if File.file?(candidate) && File.executable?(candidate)
    end
    nil
  end
end
