#!/usr/bin/env ruby

require "minitest/autorun"
require "pathname"
require_relative "../validate_logistics_errors"

class ValidateLogisticsErrorsTest < Minitest::Test
  REPOSITORY_ROOT = Pathname.new(File.expand_path("../../..", __dir__))
  RELEASE_ROOT = REPOSITORY_ROOT.join("releases/release1")
  MAP_PATH = REPOSITORY_ROOT.join("tools/release/release1-logistics-error-map.yaml")

  def test_release_logistics_errors_are_connected
    failures = IonLogisticsErrors.validate(
      RELEASE_ROOT,
      repository_root: REPOSITORY_ROOT,
      map_path: MAP_PATH
    )
    assert_empty failures, failures.join("\n")
  end

  def test_json_pointer_resolution
    document = {"components" => {"schemas" => {"A/B" => {"~field" => true}}}}
    assert_equal true, IonLogisticsErrors.resolve_pointer(document, "/components/schemas/A~1B/~0field")
    assert_nil IonLogisticsErrors.resolve_pointer(document, "/components/schemas/Missing")
  end
end
