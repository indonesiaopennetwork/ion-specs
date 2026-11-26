package ion.release2.trade.provider

import rego.v1

trade_catalog(attributes) := {
	"context": {"action": "catalog/publish"},
	"message": {"catalogs": [{"provider": {"providerAttributes": object.union(
		{"@type": "ion:IONTradeProvider"},
		attributes,
	)}}]},
}

test_ION_R2_TRD_0001_rejects_temporary_closure_without_until if {
	input_value := trade_catalog({"operationalStatus": {"status": "TEMPORARILY_CLOSED"}})
	result := violations with input as input_value
	some violation in result
	violation == {
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": "[ION-R2-TRD-0001] message.catalogs[0].provider.providerAttributes.operationalStatus.until: required when status is TEMPORARILY_CLOSED",
	}
}

test_ION_R2_TRD_0001_accepts_temporary_closure_with_until if {
	input_value := trade_catalog({"operationalStatus": {"status": "TEMPORARILY_CLOSED", "until": "2026-09-20T09:00:00Z"}})
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_TRD_0001_ignores_open_provider if {
	input_value := trade_catalog({"operationalStatus": {"status": "OPEN"}})
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_TRD_0001_ignores_unrelated_action if {
	input_value := object.union(trade_catalog({"operationalStatus": {"status": "TEMPORARILY_CLOSED"}}), {"context": {"action": "confirm"}})
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_TRD_0001_ignores_missing_optional_parent if {
	result := violations with input as {"context": {"action": "catalog/publish"}, "message": {}}
	count(result) == 0
}

test_ION_R2_TRD_0002_rejects_central_invoicing_without_entity if {
	input_value := trade_catalog({"invoicing": {"model": "CENTRAL"}})
	result := violations with input as input_value
	some violation in result
	violation == {
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": "[ION-R2-TRD-0002] message.catalogs[0].provider.providerAttributes.invoicing.entityId: required when invoicing model is CENTRAL",
	}
}

test_ION_R2_TRD_0002_accepts_central_invoicing_with_entity if {
	input_value := trade_catalog({"invoicing": {"model": "CENTRAL", "entityId": "PROVIDER-001"}})
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_TRD_0002_ignores_per_centre_invoicing if {
	input_value := trade_catalog({"invoicing": {"model": "PER_FULFILMENT_CENTRE"}})
	result := violations with input as input_value
	count(result) == 0
}

test_provider_rules_iterate_over_multiple_catalogs if {
	invalid_attributes := {"@type": "ion:IONTradeProvider", "operationalStatus": {"status": "TEMPORARILY_CLOSED"}}
	input_value := {"context": {"action": "on_discover"}, "message": {"catalogs": [
		{"provider": {"providerAttributes": invalid_attributes}},
		{"provider": {"providerAttributes": invalid_attributes}},
	]}}
	result := violations with input as input_value
	count(result) == 2
}

test_provider_rules_ignore_non_trade_attributes if {
	input_value := {"context": {"action": "catalog/publish"}, "message": {"catalogs": [{"provider": {"providerAttributes": {
		"@type": "example:OtherProvider",
		"operationalStatus": {"status": "TEMPORARILY_CLOSED"},
		"invoicing": {"model": "CENTRAL"},
	}}}]}}
	result := violations with input as input_value
	count(result) == 0
}
