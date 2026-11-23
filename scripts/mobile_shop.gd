extends RefCounted

const JUICE := 10
const MIX := 11
const HELP := 12
const GIFT := 13
const EXTRA := 14
const STARTER: Array[int] = [JUICE, MIX, HELP, GIFT]
const SHIFT := 12.0
const TOTAL := 24.0

var raw: Array[int] = [0, 0]
var jobs: Array[int] = []
var shelf: Array[int] = []
var customers: Array[int] = []
var cash := 0
var sold := 0
var premiums := 0
var mixed := 0
var produced := 0
var next_customer := 0
var arrival := 0.0
var blend := 0.0
var quick_blends := 0
var service := 0.0
var time := 0.0
var closing_time := 0.0
var shift := 0
var energy := 2
var hands: Array[int] = []
var helper := false
var tips := 0
var opened := false
var done := false

func setup(ingredients: Array[int]) -> void:
	for fruit in ingredients:
		if fruit in [0, 1]:
			raw[fruit] += 1
	for i in range(3):
		arrive()

func arrive() -> void:
	if customers.size() < 5:
		customers.append(next_customer)
		next_customer += 1

static func cost(card: int) -> int:
	return 2 if card in [HELP, EXTRA] else 1

static func station(card: int) -> int:
	if card == HELP:
		return 2
	return 1 if card == GIFT else 0

func can_play(card: int) -> bool:
	if done or time >= TOTAL or card not in hands or energy < cost(card):
		return false
	match card:
		JUICE: return raw[0] + raw[1] > 0
		MIX, EXTRA: return raw[0] > 0 and raw[1] > 0
		HELP: return not helper
		GIFT: return true
	return false

func play_at(card: int, target: int) -> bool:
	if station(card) != target or not can_play(card):
		return false
	hands.erase(card)
	energy -= cost(card)
	opened = true
	match card:
		JUICE:
			for i in range(2):
				var fruit := 0 if raw[0] > 0 else 1
				if raw[fruit] > 0:
					raw[fruit] -= 1
					jobs.append(fruit)
					quick_blends += 1
		MIX, EXTRA:
			raw[0] -= 1
			raw[1] -= 1
			jobs.append(3 if card == EXTRA else 2)
		HELP: helper = true
		GIFT: tips += 3
	return true

func tick(delta: float) -> void:
	if not opened or done:
		return
	time = minf(TOTAL, time + delta)
	arrival += delta
	if arrival >= (1.05 if helper else 1.8):
		arrival = 0.0
		arrive()
	if jobs.is_empty() and time < TOTAL - 1.35 and shelf.size() < 5:
		var fruit := 0 if raw[0] >= raw[1] else 1
		if raw[fruit] > 0:
			raw[fruit] -= 1
			jobs.append(fruit)
	if not jobs.is_empty() and shelf.size() < 5:
		blend += delta
		if blend >= mix_duration():
			blend = 0.0
			produced = jobs.pop_front()
			if produced < 2:
				quick_blends = maxi(0, quick_blends - 1)
			shelf.append(produced)
			mixed += 1
	if not shelf.is_empty() and not customers.is_empty():
		service += delta
		if service >= service_duration():
			service = 0.0
			customers.pop_front()
			var drink: int = shelf.pop_front()
			cash += [3, 3, 8, 12][drink] + (2 if tips > 0 else 0)
			tips = maxi(0, tips - 1)
			premiums += int(drink >= 2)
			sold += 1
	if time >= TOTAL:
		closing_time += delta
		done = (jobs.is_empty() and shelf.is_empty()) or closing_time >= 9.0

func mix_duration() -> float:
	if not jobs.is_empty() and jobs[0] >= 2:
		return 0.70
	return 0.45 if quick_blends > 0 else 1.25

func service_duration() -> float:
	return 0.46 if helper else 1.5
