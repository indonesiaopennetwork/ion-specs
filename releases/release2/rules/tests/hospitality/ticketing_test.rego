package ion.release2.hospitality.ticketing

import rego.v1

# ION-R2-HSP-0001
test_valid_resource if {
	valid_catalog_resource({"id": "E1"}, {"crc": "HSC-events", "event": {"eventId": "E1"}})
}

test_invalid_resource if {
	not valid_catalog_resource({"id": "E1"}, {"crc": "HSC-events", "event": {"eventId": "E2"}})
}

# ION-R2-HSP-0002
test_invalid_offer if {
	not valid_catalog_offer({"resources": [{"id": "E1"}]}, {"resourceIds": ["E2"]}, {"eventRef": "E2"})
}

# ION-R2-HSP-0003
test_invalid_commitment if {
	not valid_commitment_reference({"offer": {"id": "O1"}}, {"offerRef": "O2"})
}

# ION-R2-HSP-0004
test_duplicate_seats if {
	not valid_seat_count({"seatIds": ["A1", "A1"], "admissions": 2})
}

test_correct_seats if {
	valid_seat_count({"seatIds": ["A1", "A2"], "admissions": 2})
}
