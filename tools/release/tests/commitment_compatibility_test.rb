require "date"
require "minitest/autorun"
require "time"
require "yaml"

class CommitmentCompatibilityTest < Minitest::Test
  def setup
    repository_root = File.expand_path("../../..", __dir__)
    core_path = File.join(repository_root, "releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml")
    core = YAML.safe_load(File.read(core_path), permitted_classes: [Date, Time], aliases: true)
    @resource_entry = core.dig("components", "schemas", "Commitment", "properties", "resources", "items")
  end

  def test_resource_entry_requires_quantity_without_requiring_resource
    assert_equal ["quantity"], @resource_entry["required"]
    refute_equal false, @resource_entry["additionalProperties"]
  end

  def test_quantity_shape_is_recommended_but_not_enforced
    quantity = @resource_entry.dig("properties", "quantity")

    assert_equal(
      "#/components/schemas/Quantity",
      quantity.dig("x-ion-recommended-schema", "$ref")
    )
    refute quantity.key?("$ref")
    refute quantity.key?("type")
  end
end
