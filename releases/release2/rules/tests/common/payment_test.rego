package ion.release2.common.payment

import rego.v1

paid_settlement := {
	"context": {"action": "confirm"},
	"message": {"contract": {"settlements": [{"settlementAttributes": {"status": "PAID"}}]}},
}

test_ION_R2_COM_0001_rejects_paid_settlement_without_paid_at if {
	result := violations with input as paid_settlement
	result == {{
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": "[ION-R2-COM-0001] message.contract.settlements[0].settlementAttributes.paidAt: required when payment status is PAID",
	}}
}

test_ION_R2_COM_0001_accepts_paid_settlement_with_paid_at if {
	input_value := object.union_n([
		paid_settlement,
		{"message": {"contract": {"settlements": [{"settlementAttributes": {
			"status": "PAID",
			"paidAt": "2026-09-19T10:32:15Z",
		}}]}}},
	])
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_COM_0001_ignores_pending_payment if {
	input_value := {"context": {"action": "confirm"}, "message": {"contract": {"settlements": [{"settlementAttributes": {"status": "PENDING"}}]}}}
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_COM_0001_ignores_unrelated_action if {
	input_value := object.union(paid_settlement, {"context": {"action": "select"}})
	result := violations with input as input_value
	count(result) == 0
}

test_ION_R2_COM_0001_ignores_missing_optional_parent if {
	result := violations with input as {"context": {"action": "confirm"}, "message": {}}
	count(result) == 0
}

test_ION_R2_COM_0001_reports_each_invalid_settlement if {
	input_value := {"context": {"action": "on_status"}, "message": {"contract": {"settlements": [
		{"settlementAttributes": {"status": "PAID"}},
		{"settlementAttributes": {"status": "PAID"}},
	]}}}
	result := violations with input as input_value
	count(result) == 2
}
