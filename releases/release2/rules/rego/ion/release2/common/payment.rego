package ion.release2.common.payment

import rego.v1

applicable_actions := {"confirm", "on_confirm", "status", "on_status"}

# METADATA
# title: Paid settlement declares its payment timestamp
# description: Requires paidAt on every settlement whose payment status is PAID in confirmation and status messages.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-COM-0001
#   sector: common
#   actions:
#     - confirm
#     - on_confirm
#     - status
#     - on_status
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#     - schema/common/Payment/v1/attributes.yaml
#   flow_paths:
#     - flows/trade/patterns/storefront/v1/pattern.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in applicable_actions
	some index
	settlement := input.message.contract.settlements[index]
	attributes := object.get(settlement, "settlementAttributes", {})
	attributes.status == "PAID"
	object.get(attributes, "paidAt", "") == ""
	violation := {
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": sprintf("[ION-R2-COM-0001] message.contract.settlements[%d].settlementAttributes.paidAt: required when payment status is PAID", [index]),
	}
}
