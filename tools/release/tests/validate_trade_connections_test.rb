#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class ValidateTradeConnectionsTest < Minitest::Test
  SCRIPT = File.expand_path("../validate_trade_connections.rb", __dir__)

  def test_schema_pack_groups_map_to_release_directories
    Dir.mktmpdir do |root|
      build_release(root)
      %w[schema/common/Payment/v1 schema/core/reconcile/v1 schema/extension/trade/TradeContract/v1].each do |path|
        FileUtils.mkdir_p(File.join(root, path))
      end
      write_pattern(root, "common" => ["Payment/v1"], "core" => ["reconcile/v1"], "trade" => ["TradeContract/v1"])

      output, status = Open3.capture2e("ruby", SCRIPT, root)
      assert status.success?, output
    end
  end

  def test_missing_core_schema_pack_is_reported_under_schema_core
    Dir.mktmpdir do |root|
      build_release(root)
      write_pattern(root, "core" => ["reconcile/v2"])

      output, status = Open3.capture2e("ruby", SCRIPT, root)
      refute status.success?
      assert_includes output, "schema pack does not exist: schema/core/reconcile/v2"
    end
  end

  private

  def build_release(root)
    FileUtils.mkdir_p(File.join(root, "errors"))
    FileUtils.mkdir_p(File.join(root, "policies"))
    File.write(File.join(root, "release.yaml"), "publicBaseUrl: https://schema.ion.id/release1/\n")
    File.write(File.join(root, "errors/trade.yaml"), "[]\n")
    File.write(File.join(root, "errors/registry.json"), %({"errors": []}\n))
    File.write(File.join(root, "policies/registry.json"), %({"policies": []}\n))
  end

  def write_pattern(root, schema_packs)
    directory = File.join(root, "flows/trade/patterns/sample/v1")
    FileUtils.mkdir_p(directory)
    pattern = { "phases" => { "phase1" => { "steps" => [{ "step" => "reconcile", "schemaPacks" => schema_packs }] } } }
    File.write(File.join(directory, "pattern.yaml"), pattern.to_yaml)
  end
end
