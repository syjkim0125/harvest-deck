extends RefCounted
## The day owns energy and its conclusion; the depot owns deposited ingredients.

enum Card { NONE = -1, STANDARD, WEDGE, RESERVE_CELL, SEED_GUARD }
enum Outcome { ACTIVE, RETURNED, EXHAUSTED }

const MAX_CHARGE := 100.0
const CUT_COST := 1.0
const WEDGE_CUT_COST := 1.25
const WEDGE_OPEN_BONUS := 0.80
const SEED_COST := 25.0
const HAZARD_COST_PER_SECOND := 2.0
const RESERVE_CHARGE := 25.0
const GUARDED_SEED_COST := 10.0
const REWARDS := [Card.RESERVE_CELL, Card.SEED_GUARD]

var card := Card.STANDARD
var charge := MAX_CHARGE
var outcome := Outcome.ACTIVE
var lost_cargo := 0
var reward_used := false
var last_seed_cost := SEED_COST

func reset() -> void:
	card = Card.STANDARD
	charge = MAX_CHARGE
	outcome = Outcome.ACTIVE
	lost_cargo = 0
	reward_used = false
	last_seed_cost = SEED_COST

func cut_cost() -> float:
	return WEDGE_CUT_COST if card == Card.WEDGE else CUT_COST

func on_deposit() -> void:
	if card == Card.RESERVE_CELL and not reward_used:
		charge = minf(MAX_CHARGE, charge + RESERVE_CHARGE)
		reward_used = true

func take_seed_hit() -> float:
	last_seed_cost = SEED_COST
	if card == Card.SEED_GUARD and not reward_used:
		last_seed_cost = GUARDED_SEED_COST
		reward_used = true
	return last_seed_cost

func spend(amount: float) -> bool:
	charge = maxf(0.0, charge - amount)
	# Remove fractional dust when a drain lands exactly on zero.
	if charge < 0.000001:
		charge = 0.0
	return charge == 0.0
