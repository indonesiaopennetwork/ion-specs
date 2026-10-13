#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../generate_error_registry"

class GenerateErrorRegistryTest < Minitest::Test
  def test_builds_release_local_error_view
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "errors"))
      File.write(File.join(root, "errors", "trade.yaml"), <<~YAML)
        - code: ION-A2001
          title: { en: Invalid resource }
      YAML

      error, = IonReleaseErrorRegistry.build(root)
      assert_empty error[2]
      assert_equal 1, error[1]["count"]
    end
  end
end
