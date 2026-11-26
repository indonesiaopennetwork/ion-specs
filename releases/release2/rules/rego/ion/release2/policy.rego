package ion.release2

import data.ion.release2.common.payment
import data.ion.release2.trade.provider
import rego.v1

violations contains violation if {
	some violation in payment.violations
}

violations contains violation if {
	some violation in provider.violations
}

result := {
	"valid": count(violations) == 0,
	"violations": [violation | some violation in violations],
}
