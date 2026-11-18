extends RefCounted
## Non-additive comfort-budget impulse; design values, not reference measurements.
## Fixed phase on confirmed hits; decay in seconds, no continuous idle vibration.
var trauma: float = 0.0
var clock: float = 0.0
var enabled: bool = true
var reduced: bool = false
const DURATION: float = 2.0 / 30.0
const DECAY: float = 1.0 / DURATION
const MAX_PIXELS: float = 1.5

func hit(kill: bool = false) -> void:
	if enabled and not reduced:
		# A crowd cannot amplify or prolong the same attack pulse.
		trauma = maxf(trauma, 1.0 if kill else 0.85)
		clock = 0.0

func step(delta: float) -> Vector2:
	clock += delta
	trauma = maxf(0.0, trauma - DECAY * delta)
	if not enabled or reduced or trauma <= 0.0:
		return Vector2.ZERO
	var direction = Vector2(cos(clock * TAU * 15.0), sin(clock * TAU * 21.0 + 0.4))
	return direction.limit_length() * MAX_PIXELS * trauma

func clear() -> void:
	trauma = 0.0
	clock = 0.0

func reset() -> void:
	clear()
