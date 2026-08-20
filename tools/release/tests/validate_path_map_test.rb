#!/usr/bin/env ruby

require "minitest/autorun"
require_relative "../validate_path_map"

class ValidatePathMapTest < Minitest::Test
  PATH_MAP = File.expand_path("../release1-path-map.json", __dir__)
  REPOSITORY_ROOT = File.expand_path("../../..", __dir__)

  def setup
    @path_map = IonReleasePathMap.load(PATH_MAP)
  end

  def test_release1_path_map
    assert_empty IonReleasePathMap.validate(@path_map, repository_root: REPOSITORY_ROOT)
    assert_equal 15, @path_map.fetch("mappings").size
  end

  def test_duplicate_targets_are_rejected
    @path_map["mappings"][1]["target"] = @path_map["mappings"][0]["target"]

    assert_includes IonReleasePathMap.validate(@path_map), "duplicate target mappings"
  end

  def test_target_must_stay_inside_release
    @path_map["mappings"][0]["target"] = "releases/release2/core/api/v2.0.0/ion.yaml"

    errors = IonReleasePathMap.validate(@path_map)

    assert errors.any? { |error| error.include?("target must stay under releases/release1/") }
    assert errors.any? { |error| error.include?("publicUrl does not mirror target") }
  end

  def test_source_must_exist_when_repository_root_is_given
    @path_map["mappings"][0]["source"] = "schema/missing.yaml"

    errors = IonReleasePathMap.validate(@path_map, repository_root: REPOSITORY_ROOT)

    assert_includes errors, "mapping 0 source does not exist: schema/missing.yaml"
  end
end
