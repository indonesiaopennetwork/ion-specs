package ion.release2.hospitality.ticketing

import rego.v1

contract_actions := {"select", "on_select", "init", "on_init", "confirm", "on_confirm", "status", "on_status", "update", "on_update", "cancel", "on_cancel"}

catalog_actions := {"catalog/publish", "on_discover"}

valid_catalog_resource(resource, attributes) if {
	attributes.crc == "HSC-events"
	resource.id == attributes.event.eventId
}

valid_catalog_offer(catalog, offer, attributes) if {
	attributes.eventRef in offer.resourceIds
	some resource in catalog.resources
	resource.id == attributes.eventRef
}

valid_commitment_reference(commitment, attributes) if {
	attributes.offerRef == commitment.offer.id
	event_ref := commitment.offer.offerAttributes.eventRef
	event_ref in commitment.offer.resourceIds
	some resource in commitment.resources
	resource.resource.id == event_ref
}

valid_seat_count(allocation) if {
	seats := object.get(allocation, "seatIds", [])
	count(seats) == allocation.admissions
	count({seat | some seat in seats}) == allocation.admissions
}

# METADATA
# title: Event catalogue resource classification and identity
# description: Requires the Event Ticketing resource CRC and core identity to agree.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-HSP-0001
#   sector: hospitality
#   actions:
#   - catalog/publish
#   - on_discover
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#   - schema/extension/hospitality/HospitalityResource/v1/attributes.yaml
#   flow_paths:
#   - flows/hospitality/event-ticketing/pattern.proposed.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in catalog_actions
	some ci, ri
	resource := input.message.catalogs[ci].resources[ri]
	attributes := object.get(resource, "resourceAttributes", {})
	object.get(attributes, "@type", "") == "ion:IONHospitalityResource"
	not valid_catalog_resource(resource, attributes)
	violation := {"code": "POL_ELIGIBILITY_NOT_MET", "message": sprintf("[ION-R2-HSP-0001] message.catalogs[%d].resources[%d]: invalid event identity or CRC", [ci, ri])}
}

# METADATA
# title: Event catalogue offer references
# description: Requires eventRef to resolve to a resource in the same catalogue and in the core offer resourceIds.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-HSP-0002
#   sector: hospitality
#   actions:
#   - catalog/publish
#   - on_discover
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#   - schema/extension/hospitality/HospitalityOffer/v1/attributes.yaml
#   flow_paths:
#   - flows/hospitality/event-ticketing/pattern.proposed.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in catalog_actions
	some ci, oi
	catalog := input.message.catalogs[ci]
	offer := catalog.offers[oi]
	attributes := object.get(offer, "offerAttributes", {})
	object.get(attributes, "@type", "") == "ion:IONHospitalityOffer"
	not valid_catalog_offer(catalog, offer, attributes)
	violation := {"code": "POL_ELIGIBILITY_NOT_MET", "message": sprintf("[ION-R2-HSP-0002] message.catalogs[%d].offers[%d]: unresolved event reference", [ci, oi])}
}

# METADATA
# title: Commitment offer and event reference integrity
# description: Requires a hospitality commitment to identify its offer and resolve the event resource in the commitment.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-HSP-0003
#   sector: hospitality
#   actions:
#   - select
#   - on_select
#   - init
#   - on_init
#   - confirm
#   - on_confirm
#   - status
#   - on_status
#   - update
#   - on_update
#   - cancel
#   - on_cancel
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#   - schema/extension/hospitality/HospitalityCommitment/v1/attributes.yaml
#   flow_paths:
#   - flows/hospitality/event-ticketing/pattern.proposed.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in contract_actions
	some ci
	commitment := input.message.contract.commitments[ci]
	attributes := object.get(commitment, "commitmentAttributes", {})
	object.get(attributes, "@type", "") == "ion:IONHospitalityCommitment"
	not valid_commitment_reference(commitment, attributes)
	violation := {"code": "POL_ELIGIBILITY_NOT_MET", "message": sprintf("[ION-R2-HSP-0003] message.contract.commitments[%d]: inconsistent offer or event reference", [ci])}
}

# METADATA
# title: Assigned seats match admission quantity
# description: Rejects allocated seats whose count or unique count differs from admission quantity for an assigned allocation.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-HSP-0004
#   sector: hospitality
#   actions:
#   - select
#   - on_select
#   - init
#   - on_init
#   - confirm
#   - on_confirm
#   - status
#   - on_status
#   - update
#   - on_update
#   - cancel
#   - on_cancel
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#   - schema/extension/hospitality/HospitalityCommitment/v1/attributes.yaml
#   flow_paths:
#   - flows/hospitality/event-ticketing/pattern.proposed.yaml
#   error_paths: []
#   policy_iris: []
#   config_keys: []
#   data_paths: []
violations contains violation if {
	input.context.action in contract_actions
	some ci, ai
	attributes := input.message.contract.commitments[ci].commitmentAttributes
	object.get(attributes, "@type", "") == "ion:IONHospitalityCommitment"
	allocation := attributes.allocations[ai]
	allocation.mode in {"EXACT_SEAT", "AUTO_ASSIGN", "WHOLE_TABLE", "TABLE_SEAT"}
	allocation.allocationState in {"PROPOSED", "HELD", "COMMITTED"}
	not valid_seat_count(allocation)
	violation := {"code": "POL_ELIGIBILITY_NOT_MET", "message": sprintf("[ION-R2-HSP-0004] message.contract.commitments[%d].commitmentAttributes.allocations[%d]: assigned seat count or uniqueness mismatch", [ci, ai])}
}
