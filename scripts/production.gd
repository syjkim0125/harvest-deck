extends RefCounted
## One mixer, FIFO inputs. Raw -> in-process -> ready -> sold -> collected.
## Customers arrive into a bounded FIFO queue; service requires an operator.
const SpineMelon = preload("res://scripts/spine_melon.gd")
const MIX_SECONDS: float = 0.45
const UPGRADED_MIX_SECONDS: float = 0.25
const MIXER_UPGRADE_COST: int = 40
var mixer_upgraded: bool = false
const SALE_SECONDS: float = 0.7
const PRICE: int = 5
const ARRIVAL_SECONDS: float = 1.6
const MAX_QUEUE: int = 5
const CASHIER_COST: int = 30
const ORCHARD_COST: int = 50
var orchard_unlocked: bool = false
const MAX_SERVED_HISTORY: int = 64
var cashier_hired: bool = false
var spent_cash: int = 0
var served_total: int = 0
var customers: Array[Dictionary] = []
var arrival_elapsed: float = 0.0
var next_customer_id: int = 1
var served_ids: Array[int] = []
var raw: Array[int] = []
var ready: Array[int] = []
var active_kind: int = -1
var mix_elapsed: float = 0.0
var sale_elapsed: float = 0.0
var sold_by_kind: Array[int] = [0, 0, 0]
var pending_cash: int = 0
var collected_cash: int = 0

func _init() -> void:
	reset()

func arrive() -> void:
	if customers.size() < MAX_QUEUE:
		customers.append({"id": next_customer_id})
		next_customer_id += 1

func reset() -> void:
	customers.clear()
	served_ids.clear()
	served_total = 0
	cashier_hired = false
	orchard_unlocked = false
	mixer_upgraded = false
	spent_cash = 0
	arrival_elapsed = 0.0
	next_customer_id = 1
	for i in range(3):
		arrive()
	raw.clear()
	ready.clear()
	active_kind = -1
	mix_elapsed = 0.0
	sale_elapsed = 0.0
	sold_by_kind.assign([0, 0, 0])
	pending_cash = 0
	collected_cash = 0

func deposit(kind: int) -> void:
	assert(kind in [0, 1, SpineMelon.KIND])
	raw.append(kind)

func inventory_count() -> int:
	return raw.size() + ready.size() + (1 if active_kind >= 0 else 0)

func start_mix() -> void:
	if active_kind < 0 and not raw.is_empty():
		active_kind = raw.pop_front()
		mix_elapsed = 0.0

func step(delta: float, operator_present: bool = true) -> void:
	# Consume event boundaries chronologically so large deltas and small steps agree.
	var remaining = maxf(delta, 0.0)
	while remaining > 0.000001:
		start_mix()
		var dt = minf(remaining, ARRIVAL_SECONDS - arrival_elapsed)
		if active_kind >= 0:
			dt = minf(dt, mix_duration() - mix_elapsed)
		var can_serve = (operator_present or cashier_hired) and not customers.is_empty() and not ready.is_empty()
		if can_serve:
			dt = minf(dt, SALE_SECONDS - sale_elapsed)
		if active_kind >= 0:
			mix_elapsed += dt
		if can_serve:
			sale_elapsed += dt
		arrival_elapsed += dt
		remaining -= dt
		if active_kind >= 0 and mix_elapsed >= mix_duration() - 0.000001:
			ready.append(active_kind)
			active_kind = -1
			mix_elapsed = 0.0
		if can_serve and sale_elapsed >= SALE_SECONDS - 0.000001:
			var kind: int = ready.pop_front()
			served_ids.append(customers.pop_front().id)
			served_total += 1
			if served_ids.size() > MAX_SERVED_HISTORY:
				served_ids.pop_front()
			sold_by_kind[kind] += 1
			pending_cash += PRICE
			sale_elapsed = 0.0
		if arrival_elapsed >= ARRIVAL_SECONDS - 0.000001:
			arrival_elapsed = 0.0
			arrive()
		if ready.is_empty():
			sale_elapsed = 0.0

func collect() -> int:
	var amount = pending_cash
	collected_cash += amount
	pending_cash = 0
	return amount

func hire_cashier() -> bool:
	# Only collected wallet cash can pay. Pending counter cash is not spendable.
	if cashier_hired or collected_cash < CASHIER_COST:
		return false
	collected_cash -= CASHIER_COST
	spent_cash += CASHIER_COST
	cashier_hired = true
	return true

func mix_duration() -> float:
	return UPGRADED_MIX_SECONDS if mixer_upgraded else MIX_SECONDS

func upgrade_mixer() -> bool:
	if mixer_upgraded or collected_cash < MIXER_UPGRADE_COST:
		return false
	var progress = mix_elapsed / mix_duration()
	collected_cash -= MIXER_UPGRADE_COST
	spent_cash += MIXER_UPGRADE_COST
	mixer_upgraded = true
	# Preserve completed fraction, not elapsed seconds, during an active job.
	mix_elapsed = progress * mix_duration() if active_kind >= 0 else 0.0
	return true


func unlock_orchard() -> bool:
	if orchard_unlocked or collected_cash < ORCHARD_COST:
		return false
	collected_cash -= ORCHARD_COST
	spent_cash += ORCHARD_COST
	orchard_unlocked = true
	return true

func can_harvest(kind: int) -> bool:
	return kind == 0 or kind == SpineMelon.KIND or (kind == 1 and orchard_unlocked)
