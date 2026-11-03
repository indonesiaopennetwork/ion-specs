require "date"
require "minitest/autorun"
require "time"
require "yaml"

class SupportAttributesTest < Minitest::Test
  def setup
    repository_root = File.expand_path("../../..", __dir__)
    core_path = File.join(repository_root, "releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml")
    core = YAML.safe_load(File.read(core_path), permitted_classes: [Date, Time], aliases: true)
    @support = core.dig("components", "schemas", "Support")
  end

  def test_support_attributes_is_an_optional_attributes_slot
    assert_equal(
      "#/components/schemas/Attributes",
      @support.dig("properties", "supportAttributes", "$ref")
    )
    refute_includes Array(@support["required"]), "supportAttributes"
  end

  def test_support_keeps_its_closed_shape_and_channels
    assert_equal false, @support["additionalProperties"]
    assert_equal(
      %w[orderId descriptor channels supportAttributes],
      @support["properties"].keys
    )
    assert_equal(
      "#/components/schemas/Attributes",
      @support.dig("properties", "channels", "items", "$ref")
    )
  end
end
