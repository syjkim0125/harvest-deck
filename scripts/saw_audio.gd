extends Node
## Original periodic PCM synthesis; no samples taken from the reference game.
const RATE: int = 24000
const SAMPLES: int = 6000
const CONTACT_HOLD: float = 0.12
const ATTACK_TAU: float = 0.012
const RELEASE_TAU: float = 0.055
var output_enabled: bool = false
var contact_left: float = 0.0
var motor_gain: float = 0.0
var cut_gain: float = 0.0
var pitch: float = 0.9
var master_gain: float = 0.65
var motor: AudioStreamPlayer
var cutter: AudioStreamPlayer
var loop_starts: int = 0

static func make_loop(cutting: bool) -> AudioStreamWAV:
	var pcm = PackedByteArray()
	pcm.resize(SAMPLES * 2)
	var synth_rng = RandomNumberGenerator.new()
	synth_rng.seed = 9404
	var phases: Array[float] = []
	for k in range(12):
		phases.append(synth_rng.randf_range(0, TAU))
	for i in range(SAMPLES):
		var t = float(i) / RATE
		var sample: float
		if cutting:
			sample = sin(TAU * 360 * t) * 0.4 + sin(TAU * 720 * t) * 0.18
			for k in range(12):
				sample += sin(TAU * (980 + k * 172) * t + phases[k]) * 0.025
			sample *= (0.85 + 0.15 * sin(TAU * 12 * t)) * 0.7
		else:
			sample = (sin(TAU * 100 * t) * 0.55 + sin(TAU * 200 * t) * 0.25 + sin(TAU * 500 * t) * 0.12) * (0.88 + 0.12 * sin(TAU * 40 * t))
		pcm.encode_s16(i * 2, int(clampf(sample, -0.95, 0.95) * 32767))
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = pcm
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = SAMPLES
	return wave

func _ready() -> void:
	output_enabled = DisplayServer.get_name() != "headless"
	motor = AudioStreamPlayer.new()
	cutter = AudioStreamPlayer.new()
	motor.stream = make_loop(false)
	cutter.stream = make_loop(true)
	motor.volume_db = -80
	cutter.volume_db = -80
	add_child(motor)
	add_child(cutter)

func confirmed_hit() -> void:
	contact_left = CONTACT_HOLD

func silence() -> void:
	contact_left = 0.0
	motor_gain = 0.0
	cut_gain = 0.0
	pitch = 0.9
	if is_instance_valid(motor):
		motor.stop()
		cutter.stop()

func step(delta: float, enabled: bool, moving: bool, full: bool) -> void:
	if not enabled or master_gain <= 0.0:
		silence()
		return
	# Exact integration across the contact timeout makes 30/60/120Hz agree.
	var dt = maxf(0.0, delta)
	var active_dt = minf(dt, contact_left) if not full else 0.0
	contact_left = maxf(0.0, contact_left - dt) if not full else 0.0
	var motor_target: float = 0.07 if active_dt > 0.0 else (0.17 if moving and not full else 0.10)
	motor_gain = lerpf(motor_gain, motor_target * master_gain, 1.0 - exp(-dt / ATTACK_TAU))
	if active_dt > 0:
		cut_gain = lerpf(cut_gain, 0.22 * master_gain, 1.0 - exp(-active_dt / ATTACK_TAU))
	if dt > active_dt:
		cut_gain *= exp(-(dt - active_dt) / RELEASE_TAU)
	var pitch_target: float = 0.82 if active_dt > 0 else (1.12 if moving else 0.9)
	pitch = lerpf(pitch, pitch_target, 1.0 - exp(-dt * 18))
	if not output_enabled:
		return
	motor.volume_linear = motor_gain
	cutter.volume_linear = cut_gain
	motor.pitch_scale = pitch
	cutter.pitch_scale = 0.94
	if not motor.playing:
		motor.play()
		loop_starts += 1
	if cut_gain > 0.0001:
		if not cutter.playing:
			cutter.play()
			loop_starts += 1
	else:
		cutter.stop()

func mode() -> String:
	if motor_gain <= 0.0001:
		return "OFF"
	return "CUT" if cut_gain > 0.015 else "IDLE"

func _exit_tree() -> void:
	silence()
