#!/usr/bin/env ruby

require "minitest/autorun"
require_relative "../import_legacy_logistics"

class ImportLegacyLogisticsTest < Minitest::Test
  def test_normalizes_metadata_and_preserves_domain_terms
    legacy = {
      "id" => "cancel.logistics.prepickup-free",
      "type" => "CANCELLATION_POLICY",
      "sector" => "logistics",
      "cancellationFee" => 0
    }

    result = IonLegacyLogisticsPolicies.normalize(
      legacy,
      legacy.fetch("id"),
      "policies/cancellation/v1/source.yaml",
      "cancellation",
      "Pembatalan gratis",
      "Free cancellation"
    )

    assert_equal "ion://policy/cancel.logistics.prepickup-free", result["iri"]
    assert_equal "draft", result["status"]
    assert_nil result["versionEffectiveFrom"]
    assert_equal "logistics", result["sector"]
    assert_equal 0, result["cancellationFee"]
    refute result.key?("id")
    refute result.key?("type")
  end

  def test_rewrites_approved_existing_policy_iris
    value = {
      "path" => "ion://policy/dispute-resolution.commercial-odr",
      "other" => ["ion://policy/dispute-resolution.commercial-bani"]
    }

    assert_equal(
      {
        "path" => "ion://policy/dispute.commercial.odr",
        "other" => [
          "ion://policy/dispute.commercial.bani",
          "ion://policy/dispute.commercial.odr"
        ]
      },
      IonLegacyLogisticsPolicies.deep_rewrite(
        value.merge("other" => value["other"] + ["ion://policy/dispute-resolution.network-adjudication"])
      )
    )
  end
end
