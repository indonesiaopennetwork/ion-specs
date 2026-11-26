package ion.release2

import rego.v1

# Phase 2 establishes the public result contract without asserting business
# rules. Later phases aggregate common, Trade, and Logistics violations here.
violations := set()

result := {
	"valid": count(violations) == 0,
	"violations": [violation | some violation in violations],
}
