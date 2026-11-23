extends RefCounted

enum Phase { IDLE, ROLLING, BRAKING }

const KIND := 3
const DAY := 2
const HOME := Vector2(895, 900)
const TURN := Vector2(895, 1030)
const BRAKE_POINT := Vector2(1235, 1030)
const ROUTE := [TURN, BRAKE_POINT, Vector2(1235, 875), Vector2(895, 875), HOME]
const TRIGGER_RADIUS := 135.0
const SPEED := 480.0
const BRAKE_SECONDS := 0.92

var phase := Phase.IDLE
var position := HOME
var angle := 0.0
var waypoint := 0
var brake_left := 0.0
var brake_bonus := 0.0

func step(delta: float, player: Vector2) -> void:
	match phase:
		Phase.IDLE:
			if position.distance_squared_to(player) <= TRIGGER_RADIUS * TRIGGER_RADIUS:
				phase = Phase.ROLLING
		Phase.ROLLING:
			var destination: Vector2 = ROUTE[waypoint]
			var next := position.move_toward(destination, SPEED * delta)
			angle = fmod(angle + position.distance_to(next) / 23.0, TAU)
			position = next
			if position != destination:
				return
			waypoint += 1
			if position == BRAKE_POINT:
				phase = Phase.BRAKING
				brake_left = BRAKE_SECONDS + brake_bonus
			elif waypoint == ROUTE.size():
				phase = Phase.IDLE
				waypoint = 0
		Phase.BRAKING:
			brake_left = maxf(0.0, brake_left - delta)
			if brake_left <= 0.000001:
				phase = Phase.ROLLING
