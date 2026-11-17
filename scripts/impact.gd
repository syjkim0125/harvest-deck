extends RefCounted
## Seconds-based, bounded impact envelope. This never changes simulation time.
var trauma: float = 0.0
var clock: float = 0.0
var enabled: bool = true
var reduced: bool = false
const DECAY: float = 3.8
const MAX_PIXELS: float = 8.0

func hit(kill: bool = false) -> void:
	if enabled:
		trauma = minf(1.0, trauma + (0.44 if kill else 0.23))

func step(delta: float) -> Vector2:
	clock += delta
	trauma = maxf(0.0, trauma - DECAY * delta)
	if not enabled or reduced:
		return Vector2.ZERO
	return Vector2(sin(clock * 113.0), sin(clock * 147.0 + 1.7)) * MAX_PIXELS * trauma * trauma

func clear() -> void:
	trauma = 0.0

func reset() -> void:
	clear()
	clock = 0.0
