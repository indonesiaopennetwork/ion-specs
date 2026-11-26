package ion.release2.trade.provider

import rego.v1

applicable_actions := {"catalog/publish", "on_discover"}

trade_provider_attributes(catalog) := attributes if {
	attributes := catalog.provider.providerAttributes
	object.get(attributes, "@type", "") == "ion:IONTradeProvider"
}

# METADATA
# title: Temporary provider closure declares its end
# description: Requires until when a Trade provider advertises TEMPORARILY_CLOSED in a catalog message.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-TRD-0001
#   sector: trade
#   actions:
#     - catalog/publish
#     - on_discover
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#     - schema/extension/trade/TradeProvider/v1/attributes.yaml
#   flow_paths:
#     - flows/trade/patterns/storefront/v1/pattern.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in applicable_actions
	some index
	attributes := trade_provider_attributes(input.message.catalogs[index])
	status := object.get(attributes, "operationalStatus", {})
	status.status == "TEMPORARILY_CLOSED"
	object.get(status, "until", "") == ""
	violation := {
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": sprintf("[ION-R2-TRD-0001] message.catalogs[%d].provider.providerAttributes.operationalStatus.until: required when status is TEMPORARILY_CLOSED", [index]),
	}
}

# METADATA
# title: Central invoicing declares its issuing entity
# description: Requires entityId when a Trade provider selects the CENTRAL invoicing model in a catalog message.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-TRD-0002
#   sector: trade
#   actions:
#     - catalog/publish
#     - on_discover
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#     - schema/extension/trade/TradeProvider/v1/attributes.yaml
#   flow_paths:
#     - flows/trade/patterns/storefront/v1/pattern.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in applicable_actions
	some index
	attributes := trade_provider_attributes(input.message.catalogs[index])
	invoicing := object.get(attributes, "invoicing", {})
	invoicing.model == "CENTRAL"
	object.get(invoicing, "entityId", "") == ""
	violation := {
		"code": "POL_ELIGIBILITY_NOT_MET",
		"message": sprintf("[ION-R2-TRD-0002] message.catalogs[%d].provider.providerAttributes.invoicing.entityId: required when invoicing model is CENTRAL", [index]),
	}
}
