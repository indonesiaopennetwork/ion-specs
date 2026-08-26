require "minitest/autorun"

require_relative "../apply_vendoring_plan"

class ApplyVendoringPlanTest < Minitest::Test
  def dependency
    {
      "name" => "Quantity",
      "version" => "2.0",
      "publicUrl" => "https://schema.ion.id/release1/schema/vendored/beckn/schemas/Quantity/2.0/attributes.yaml",
      "registryDocuments" => [
        { "url" => "https://schema.beckn.io/Quantity/2.0/attributes.yaml" }
      ]
    }
  end

  def test_aliases_cover_registry_path_variants
    aliases = IonVendoringApply.ref_aliases([dependency])

    assert_equal dependency["publicUrl"], aliases["https://schema.beckn.io/Quantity/2.0"]
    assert_equal dependency["publicUrl"], aliases["https://schema.beckn.io/Quantity/v2.0"]
    assert_equal dependency["publicUrl"], aliases["https://schema.beckn.io/Quantity/v2.0/attributes.yaml"]
  end

  def test_rewrite_changes_only_ref_lines
    body = <<~YAML
      description: See https://schema.beckn.io/Quantity/2.0 for semantics.
      schema:
        $ref: https://schema.beckn.io/Quantity/2.0#/components/schemas/Quantity
    YAML

    rewritten, count = IonVendoringApply.rewrite_ref_lines(
      body,
      IonVendoringApply.ref_aliases([dependency])
    )

    assert_equal 1, count
    assert_includes rewritten, "description: See https://schema.beckn.io/Quantity/2.0 for semantics."
    assert_includes rewritten, "#{dependency["publicUrl"]}#/components/schemas/Quantity"
  end

  def test_internal_ref_rewrite_is_exact
    body = <<~YAML
      allOf:
        - "$ref": "#/components/schemas/Document"
      description: "#/components/schemas/Document"
    YAML

    rewritten, count = IonVendoringApply.rewrite_ref_lines(
      body,
      {},
      extra_refs: IonVendoringApply::ION_INTERNAL_REFS
    )

    assert_equal 1, count
    assert_includes rewritten, "#{IonVendoringApply::PROTOCOL_PUBLIC_URL}#/components/schemas/Document"
    assert_includes rewritten, 'description: "#/components/schemas/Document"'
  end

  def test_internal_ref_rewrite_is_idempotent
    qualified = "#{IonVendoringApply::PROTOCOL_PUBLIC_URL}#/components/schemas/Document"
    body = "allOf:\n  - $ref: #{qualified}\n"

    rewritten, count = IonVendoringApply.rewrite_ref_lines(
      body,
      {},
      extra_refs: IonVendoringApply::ION_INTERNAL_REFS
    )

    assert_equal 0, count
    assert_equal body, rewritten
  end
end
