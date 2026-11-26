#!/usr/bin/env ruby

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../generate_registry"
require_relative "registry_test_support"

class GenerateRegistryTest < Minitest::Test
  include RegoRegistryTestSupport

  def test_generation_is_byte_stable
    Dir.mktmpdir do |root|
      release = build_repository(root)
      _path, first, first_errors = IonRegoRegistry.build(release)
      _path, second, second_errors = IonRegoRegistry.build(release)

      assert_empty first_errors
      assert_empty second_errors
      assert_equal IonRegoRegistry.render(first), IonRegoRegistry.render(second)
    end
  end

  def test_missing_and_stale_registry_fail_until_write_refreshes_it
    Dir.mktmpdir do |root|
      release = build_repository(root)
      path, _registry, missing = IonRegoRegistry.sync(release, out: StringIO.new)
      assert missing.any? { |error| error.include?("registry is missing") }

      _path, _registry, write_errors = IonRegoRegistry.sync(release, write: true, out: StringIO.new)
      assert_empty write_errors
      expected = path.read

      path.write("{}\n")
      _path, _registry, stale = IonRegoRegistry.sync(release, out: StringIO.new)
      assert stale.any? { |error| error.include?("registry is stale") }

      IonRegoRegistry.sync(release, write: true, out: StringIO.new)
      assert_equal expected, path.read
    end
  end
end
