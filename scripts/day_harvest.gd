extends RefCounted
## The day owns energy and its conclusion; the depot owns deposited ingredients.

const RollingOrange = preload("res://scripts/rolling_orange.gd")

enum Card { NONE = -1, STANDARD, WEDGE, RESERVE_CELL, SEED_GUARD, TUNED_BLADE, LIMITED_COCKTAIL, WHEEL_CHOCK, DASH_KIT, COOLER_CRATE }
enum Outcome { ACTIVE, RETURNED, EXHAUSTED }

const MAX_CHARGE := 100.0
const CUT_COST := 1.0
const WEDGE_CUT_COST := 1.25
const WEDGE_OPEN_BONUS := 0.80
const SEED_COST := 25.0
const HAZARD_COST_PER_SECOND := 2.0
const RESERVE_CHARGE := 25.0
const GUARDED_SEED_COST := 10.0
const TUNED_CUT_COST := 0.75
const CHOCK_BRAKE_BONUS := 0.60
const DASH_COST := 8.0
const DASH_SECONDS := 0.20
const COOLER_DAY := 3
const COOLER_CAPACITY := 4
const REWARD_OFFERS := [
	[Card.RESERVE_CELL, Card.SEED_GUARD, Card.WHEEL_CHOCK],
	[Card.TUNED_BLADE, Card.LIMITED_COCKTAIL, Card.COOLER_CRATE],
]

var card := Card.STANDARD
var charge := MAX_CHARGE
var outcome := Outcome.ACTIVE
var lost_cargo := 0
var reward_used := false
var dash_used := false
var last_seed_cost := SEED_COST

static func card_available(card_id: Card, day_number: int) -> bool:
	if card_id == Card.COOLER_CRATE:
		return day_number == COOLER_DAY
	return card_id not in [Card.WHEEL_CHOCK, Card.DASH_KIT] or day_number == RollingOrange.DAY

func reset() -> void:
	card = Card.STANDARD
	charge = MAX_CHARGE
	outcome = Outcome.ACTIVE
	lost_cargo = 0
	reward_used = false
	dash_used = false
	last_seed_cost = SEED_COST

func cut_cost() -> float:
	match card:
		Card.WEDGE: return WEDGE_CUT_COST
		Card.TUNED_BLADE: return TUNED_CUT_COST
	return CUT_COST

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
