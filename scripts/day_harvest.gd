extends RefCounted
## The day owns energy and its conclusion; the depot owns deposited ingredients.

enum Outcome { ACTIVE, RETURNED, EXHAUSTED }

const MAX_CHARGE := 100.0
const CUT_COST := 1.0
const SEED_COST := 25.0
const HAZARD_COST_PER_SECOND := 2.0

var charge := MAX_CHARGE
var outcome := Outcome.ACTIVE
var lost_cargo := 0

func reset() -> void:
	charge = MAX_CHARGE
	outcome = Outcome.ACTIVE
	lost_cargo = 0

func spend(amount: float) -> bool:
	charge = maxf(0.0, charge - amount)
	# Remove fractional dust when a drain lands exactly on zero.
	if charge < 0.000001:
		charge = 0.0
	return charge == 0.0
