extends RefCounted
## Presentation only. Contact anchors remain fixed across turns and stops.
const STRIDE: float = 72.0
const KICK_SECONDS: float = 0.075
const KICK_UNITS: float = 2.5
const STEP_REACH: float = 10.0
const MAX_STANCE_REACH: float = 18.0
const SWING_TRAVEL: float = 12.0
const SETTLE_SECONDS: float = 0.12
var distance: float = 0.0
var walk_weight: float = 0.0
var hit_age: float = KICK_SECONDS
var body: Vector2 = Vector2.ZERO
var heading: Vector2 = Vector2.UP
var feet: Array[Dictionary] = []

func nominal(index: int, at: Vector2, direction: Vector2) -> Vector2:
	return at + Vector2(0, 15) + direction.orthogonal() * (-9.0 if index == 0 else 9.0)

func ensure_feet(direction: Vector2) -> void:
	if not feet.is_empty():
		return
	heading = direction.normalized() if direction.length() > 0.0 else Vector2.UP
	for i in range(2):
		var point = nominal(i, body, heading)
		feet.append({"point": point, "start": point, "target": point, "progress": 1.0, "lift": 0.0, "start_lift": 0.0, "mode": "plant"})

func step(delta: float, displacement: Vector2, facing: Vector2 = Vector2.ZERO) -> void:
	var dt = maxf(delta, 0.0)
	var direction = facing.normalized() if facing.length() > 0.0 else (displacement.normalized() if displacement.length() > 0.0 else heading)
	ensure_feet(direction)
	var slices = maxi(1, ceili(dt * 120.0 - 0.000001))
	for i in range(slices):
		step_slice(dt / slices, displacement / slices, direction)

func begin_swing(foot: Dictionary, destination: Vector2, settling: bool) -> void:
	foot.start = foot.point
	foot.target = destination
	foot.start_lift = foot.lift
	foot.progress = 0.0
	foot.mode = "settle" if settling else "swing"

func step_slice(delta: float, displacement: Vector2, direction: Vector2) -> void:
	var travel = displacement.length()
	var moving = travel > 0.000001
	var turned = heading.dot(direction) < 0.5
	heading = direction
	body += displacement
	distance = fposmod(distance + travel, STRIDE)
	walk_weight = 1.0 if moving else walk_weight * exp(-18.0 * delta)
	hit_age = minf(KICK_SECONDS, hit_age + delta)
	for i in range(2):
		var foot = feet[i]
		var rest = nominal(i, body, heading)
		if foot.mode == "plant":
			var reach: float = foot.point.distance_to(rest)
			if moving and reach > STEP_REACH and (feet[1 - i].mode == "plant" or reach > MAX_STANCE_REACH):
				begin_swing(foot, rest + heading * SWING_TRAVEL, false)
			continue
		if not moving and foot.mode != "settle":
			begin_swing(foot, rest, true)
			continue
		if moving and (foot.mode == "settle" or turned):
			begin_swing(foot, rest + heading * SWING_TRAVEL, false)
			continue
		foot.progress = minf(1.0, foot.progress + (delta / SETTLE_SECONDS if foot.mode == "settle" else travel / SWING_TRAVEL))
		var t: float = foot.progress
		foot.point = foot.start.lerp(foot.target, t * t * (3.0 - 2.0 * t))
		foot.lift = lerpf(foot.start_lift, 0.0, t)
		if foot.mode == "swing":
			foot.lift = minf(7.0, foot.lift + sin(PI * t) * 7.0)
		if t >= 1.0:
			foot.point = foot.target
			foot.lift = 0.0
			foot.mode = "plant"

func confirmed_hit() -> void:
	hit_age = 0.0

func clear_hit() -> void:
	hit_age = KICK_SECONDS

func reset() -> void:
	distance = 0.0
	walk_weight = 0.0
	body = Vector2.ZERO
	heading = Vector2.UP
	feet.clear()
	clear_hit()

func kick() -> float:
	return KICK_UNITS * (1.0 - hit_age / KICK_SECONDS)

func bob(reduced: bool) -> float:
	return 0.0 if reduced else -absf(sin(distance / STRIDE * TAU)) * 1.5 * walk_weight

func foot(index: int, facing: Vector2, reduced: bool) -> Dictionary:
	ensure_feet(facing)
	var state = feet[index]
	var lift: float = 0.0 if reduced else state.lift
	return {"position": state.point - body - Vector2(0, lift), "planted": state.mode == "plant"}
