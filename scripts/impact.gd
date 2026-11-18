extends RefCounted
## One directional impulse per cut, in logical viewport pixels.
const DURATION: float = 0.092
const MAX_PIXELS: float = 5.0
const SOFT_DURATION: float = 2.0 / 30.0
const SOFT_PIXELS: float = 1.5
const HIT_DURATION: float = 0.078
const HIT_PIXELS: float = 3.4

var trauma: float = 0.0
var clock: float = 0.0
var enabled: bool = true
var reduced: bool = false
var soft: bool = false
var axis := Vector2.RIGHT
var duration: float = DURATION
var amplitude: float = 0.0

func hit(kill: bool = false, direction: Vector2 = Vector2.RIGHT) -> void:
	if not enabled or reduced:
		return
	axis = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	amplitude = MAX_PIXELS if kill else HIT_PIXELS
	duration = DURATION if kill else HIT_DURATION
	if soft:
		amplitude *= SOFT_PIXELS / MAX_PIXELS
		duration *= SOFT_DURATION / DURATION
	trauma = 1.0
	clock = 0.0

func offset() -> Vector2:
	if not enabled or reduced or trauma <= 0.0:
		return Vector2.ZERO
	# Initial recoil, one smaller return pulse, then a centered camera.
	var phase := clampf(clock / duration, 0.0, 1.0)
	var wave := lerpf(1.0, -0.42, smoothstep(0.12, 0.48, phase)) if phase < 0.48 else lerpf(-0.42, 0.0, smoothstep(0.48, 1.0, phase))
	return -axis * amplitude * wave

func step(delta: float) -> Vector2:
	clock += delta
	trauma = maxf(0.0, 1.0 - clock / duration) if trauma > 0.0 else 0.0
	return offset()

func clear() -> void:
	trauma = 0.0
	clock = 0.0

func reset() -> void:
	clear()
