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
          sector: trade
          title: { en: Invalid resource }
      YAML
      File.write(File.join(root, "errors", "logistics.yaml"), <<~YAML)
        - code: ION-B5001
          sector: logistics
          title: { en: Delivery attempt limit reached }
      YAML

      error, = IonReleaseErrorRegistry.build(root)
      assert_empty error[2]
      assert_equal 2, error[1]["count"]
      assert_equal({"trade" => 1, "logistics" => 1}, error[1]["bySector"])
      assert_equal ["ION-A2001", "ION-B5001"], error[1]["errors"].map { |entry| entry["code"] }
    end
  end

  def test_rejects_sector_code_mismatch
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "errors"))
      File.write(File.join(root, "errors", "trade.yaml"), "- {code: ION-B2001, sector: trade}\n")
      File.write(File.join(root, "errors", "logistics.yaml"), "- {code: ION-B5001, sector: logistics}\n")

      error, = IonReleaseErrorRegistry.build(root)
      assert_includes error[2], "invalid Trade error code: ION-B2001"
    end
  end
end
