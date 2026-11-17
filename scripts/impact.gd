extends RefCounted
## Short non-additive hit pulse. Values are comfort-tuning, not measured engine values.
## Two frames of the 30 fps reference = 66.7 ms maximum, independent of render fps.
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
		trauma = maxf(trauma, 1.0 if kill else 0.75)
		clock = 0.0

func step(delta: float) -> Vector2:
	clock += delta
	trauma = maxf(0.0, trauma - DECAY * delta)
	if not enabled or reduced or trauma <= 0.0:
		return Vector2.ZERO
	var direction = Vector2(sin(clock * 113.0), sin(clock * 147.0 + 1.7))
	return direction.limit_length() * MAX_PIXELS * trauma * trauma

func clear() -> void:
	trauma = 0.0
	clock = 0.0

func reset() -> void:
	clear()
