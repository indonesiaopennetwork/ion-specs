require "date"
require "minitest/autorun"
require "time"
require "yaml"

class ProtocolCallbackEnvelopesTest < Minitest::Test
  CORE_CALLBACKS = %w[
    /on_discover
    /on_select
    /on_init
    /on_confirm
    /on_status
    /on_track
    /on_update
    /on_cancel
    /on_rate
    /on_support
    /catalog/on_publish
    /catalog/on_pull
  ].freeze

  def setup
    repository_root = File.expand_path("../../..", __dir__)
    api_root = File.join(repository_root, "releases/release1/schema/core/api/v2.0.0")
    @core = load_yaml(File.join(api_root, "ion-beckn.yaml"))
    @additional = load_yaml(File.join(api_root, "ion-additional.yaml"))
  end

  def test_core_callbacks_keep_both_outcomes_without_enforcing_exclusivity
    CORE_CALLBACKS.each do |path|
      schema = callback_schema(@core, path)
      assert_callback_properties(schema, path, "#/components/schemas/AsyncError")
      refute schema.key?("oneOf"), "#{path} must not make message and error mutually exclusive"
    end
  end

  def test_async_error_preserves_the_closed_base_error_shape
    assert_equal(
      [{ "$ref" => "#/components/schemas/Error" }],
      @core.dig("components", "schemas", "AsyncError", "allOf")
    )
  end

  def test_on_reconcile_retains_exactly_one_outcome
    error_ref = "https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-beckn.yaml#/components/schemas/AsyncError"
    schema = callback_schema(@additional, "/on_reconcile")
    assert_callback_properties(schema, "/on_reconcile", error_ref)
    assert_equal(
      [["message"], ["error"]],
      schema.fetch("oneOf").map { |alternative| alternative["required"] },
      "/on_reconcile must allow exactly one callback outcome"
    )
  end

  private

  def load_yaml(path)
    YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
  end

  def callback_schema(document, path)
    document.dig("paths", path, "post", "requestBody", "content", "application/json", "schema")
  end

  def assert_callback_properties(schema, path, error_ref)
    refute_nil schema, "#{path} request schema is missing"
    assert_equal ["context"], schema["required"], "#{path} must require context"
    assert schema.dig("properties", "message"), "#{path} message outcome is missing"
    assert_equal error_ref, schema.dig("properties", "error", "$ref"), "#{path} AsyncError reference differs"
  end
end
