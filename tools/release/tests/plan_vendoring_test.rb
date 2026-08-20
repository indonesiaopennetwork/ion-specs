#!/usr/bin/env ruby

require "minitest/autorun"
require_relative "../plan_vendoring"

class PlanVendoringTest < Minitest::Test
  def test_parses_registry_reference_with_v_prefix_and_fragment
    parsed = IonVendoringPlan.registry_reference(
      "https://schema.beckn.io/RetailResource/v2.1/attributes.yaml#/components/schemas/RetailResource"
    )

    assert_equal "RetailResource", parsed["family"]
    assert_equal "2.1", parsed["version"]
    assert_equal "v2.1", parsed["requestedVersionSegment"]
    assert_equal "RetailResource@2.1", parsed["key"]
  end

  def test_parses_document_url_without_attributes_filename
    parsed = IonVendoringPlan.registry_reference(
      "https://schema.beckn.io/Contact/2.0#/components/schemas/Contact"
    )

    assert_equal "Contact", parsed["family"]
    assert_equal "2.0", parsed["version"]
    assert_equal "https://schema.beckn.io/Contact/2.0", parsed["documentUrl"]
  end

  def test_rejects_non_registry_and_non_schema_document_urls
    assert_nil IonVendoringPlan.registry_reference("https://example.com/Contact/2.0")
    assert_nil IonVendoringPlan.registry_reference("https://schema.beckn.io/Contact/2.0/context.jsonld")
  end

  def test_collects_nested_refs
    document = {
      "allOf" => [
        { "$ref" => "https://schema.beckn.io/Attributes/2.0/attributes.yaml#/components/schemas/Attributes" },
        { "properties" => { "quantity" => { "$ref" => "https://schema.beckn.io/Quantity/2.0" } } }
      ]
    }

    assert_equal 2, IonVendoringPlan.collect_refs(document).length
  end

  def test_source_and_target_rules_are_explicit
    retail = IonVendoringPlan.source_rule("RetailOffer")
    generic = IonVendoringPlan.source_rule("Quantity")

    assert_equal "beckn/local-retail", retail["apiRepository"]
    assert_equal "beckn/schemas", generic["apiRepository"]
    assert_equal "schema/Quantity/v2.0/attributes.yaml", IonVendoringPlan.upstream_path("Quantity", "2.0")
    assert_equal(
      "releases/release1/vendored/beckn/schemas/Quantity/2.0/attributes.yaml",
      IonVendoringPlan.target_path("Quantity", "2.0")
    )
  end

  def test_strips_only_the_vendoring_header
    content = "# VENDORED DEPENDENCY\n# metadata\nopenapi: 3.1.1\ninfo:\n  version: 2.0.0\n"

    assert_equal(
      "openapi: 3.1.1\ninfo:\n  version: 2.0.0\n",
      IonVendoringPlan.strip_vendoring_header(content)
    )
  end

  def test_summarizes_payload_line_differences
    summary = IonVendoringPlan.line_difference_summary(
      "openapi: 3.1.1\ndescription: upstream\n",
      "openapi: 3.1.1\n# description: upstream\n"
    )

    assert_equal 1, summary["differenceCount"]
    assert_equal 2, summary["differences"][0]["line"]
    assert_equal "description: upstream", summary["differences"][0]["upstream"]
    assert_equal "# description: upstream", summary["differences"][0]["candidate"]
    refute summary["truncated"]
  end
end
