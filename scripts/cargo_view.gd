extends RefCounted
## Cosmetic handoff traces only. Ownership transfers to production immediately.
## Never use these entries as inventory or award resources on animation completion.
const DURATION: float = 0.24
const MAX_TRANSFERS: int = 8
const ARC_HEIGHT: float = 24.0
var transfers: Array[Dictionary] = []

func send(kind: int, start: Vector2, destination: Vector2) -> void:
	if transfers.size() >= MAX_TRANSFERS:
		transfers.pop_front()
	transfers.append({"kind": kind, "start": start, "destination": destination, "age": 0.0})

func step(delta: float) -> void:
	for i in range(transfers.size() - 1, -1, -1):
		transfers[i].age += maxf(delta, 0.0)
		if transfers[i].age >= DURATION - 0.000001:
			transfers.remove_at(i)

static func position_at(item: Dictionary) -> Vector2:
	var progress = clampf(item.age / DURATION, 0.0, 1.0)
	return item.start.lerp(item.destination, progress) + Vector2(0, -sin(progress * PI) * ARC_HEIGHT)

func clear() -> void:
	transfers.clear()
