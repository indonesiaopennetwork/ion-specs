require "date"
require "minitest/autorun"
require "time"
require "yaml"

class TrackActionCompatibilityTest < Minitest::Test
  def setup
    repository_root = File.expand_path("../../..", __dir__)
    core_path = File.join(repository_root, "releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml")
    core = YAML.safe_load(File.read(core_path), permitted_classes: [Date, Time], aliases: true)
    @track_action = core.dig("components", "schemas", "TrackAction")
  end

  def test_tracking_and_tracking_request_are_both_accepted
    assert_equal(
      [["trackingRequest"], ["tracking"]],
      @track_action.fetch("anyOf").map { |alternative| alternative["required"] }
    )
    assert_equal "#/components/schemas/Tracking", @track_action.dig("properties", "tracking", "$ref")
    assert_equal "#/components/schemas/TrackingRequest", @track_action.dig("properties", "trackingRequest", "$ref")
  end

  def test_tracking_request_is_recommended
    assert_equal "trackingRequest", @track_action["x-ion-recommended-property"]
    assert_equal true, @track_action.dig("properties", "tracking", "deprecated")
    refute @track_action.dig("properties", "trackingRequest", "deprecated")
  end
end
