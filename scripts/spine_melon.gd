extends RefCounted

enum Phase { IDLE, WARNING, VULNERABLE, RECOVERING }

const KIND := 2
const HOME := Vector2(210, 866)
const EAST_HOME := Vector2(1200, 740)
const TRIGGER_RADIUS := 146.0
const STRIKE_RADIUS := 128.0
const WARNING_SECONDS := 0.70
const OPEN_SECONDS := 1.30
const RECOVERY_SECONDS := 0.80
const BURST_SECONDS := 0.18

var phase := Phase.IDLE
var first_open_bonus := 0.0
var time_left := 0.0
var burst_left := 0.0
var last_strike_hit := false

func step(delta: float, distance: float) -> void:
	burst_left = maxf(0.0, burst_left - delta)
	if phase == Phase.IDLE:
		if distance <= TRIGGER_RADIUS:
			phase = Phase.WARNING
			time_left = WARNING_SECONDS
		return
	time_left = maxf(0.0, time_left - delta)
	if time_left > 0.000001:
		return
	match phase:
		Phase.WARNING:
			phase = Phase.VULNERABLE
			time_left = OPEN_SECONDS + first_open_bonus
			first_open_bonus = 0.0
			burst_left = BURST_SECONDS
			last_strike_hit = distance <= STRIKE_RADIUS
		Phase.VULNERABLE:
			phase = Phase.RECOVERING
			time_left = RECOVERY_SECONDS
		Phase.RECOVERING:
			phase = Phase.IDLE

static func make_cue() -> AudioStreamWAV:
	var cue := AudioStreamWAV.new()
	cue.format = AudioStreamWAV.FORMAT_16_BITS
	cue.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(2646 * 2)
	for i in range(2646):
		var t := float(i) / cue.mix_rate
		var envelope := minf(1.0, t / 0.008) * pow(1.0 - t / 0.12, 2)
		var sample := sin(TAU * (370.0 * t + 1300.0 * t * t)) * envelope
		samples.encode_s16(i * 2, roundi(sample * 11000.0))
	cue.data = samples
	return cue
