package ion.release2

import rego.v1

expected_empty_result := {
	"valid": true,
	"violations": [],
}

test_result_is_defined_for_trade_input if {
	actual := result with input as {
		"context": {"action": "confirm", "networkId": "ion.id"},
		"message": {"contract": {"id": "ORDER-001"}},
	}
	actual == expected_empty_result
}

test_result_is_defined_for_logistics_input if {
	actual := result with input as {
		"context": {"action": "confirm", "networkId": "ion.id"},
		"message": {"contract": {"id": "SHIPMENT-001"}},
	}
	actual == expected_empty_result
}
