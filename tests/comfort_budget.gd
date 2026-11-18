extends SceneTree
## Literal user comfort budget: do not derive expected limits from implementation constants.
const Game = preload("res://scripts/game.gd")
const Impact = preload("res://scripts/impact.gd")
var checks = 0
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func run() -> void:
	check(Impact.MAX_PIXELS <= 1.5 and Game.MAX_DISPLAY_SHAKE <= 1.5, "configured displacement respects literal 1.5px budget")
	check(Impact.DURATION <= 2.0 / 30.0 + 0.0000001, "configured pulse lasts at most 66.667ms")
	for rate in [30,60,120,1000]:
		var fx = Impact.new()
		fx.hit(true)
		var peak = fx.step(0.0).length()
		var elapsed = 0.0
		while elapsed < 0.067:
			var dt = minf(1.0 / rate,0.067 - elapsed)
			peak = maxf(peak,fx.step(dt).length())
			elapsed += dt
		check(peak <= 1.500001 and peak > 0.0, "nonzero bounded pulse at %dHz" % rate)
		check(fx.step(0.0) == Vector2.ZERO, "center restored by 67ms at %dHz" % rate)
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	for zoom in [Vector2(0.7,0.7),Vector2.ONE,Vector2(1.4,1.4),Vector2(2,1.5)]:
		g.camera.zoom = zoom
		g.impact.clear()
		for i in range(100): g.impact.hit(true)
		var peak = 0.0
		for i in range(68):
			peak = maxf(peak,(g.feedback_offset() * zoom).length())
			g.impact.step(0.001)
		check(peak <= 1.500001 and g.feedback_offset() == Vector2.ZERO, "100 simultaneous hits retain pixel budget and expiry with zoom %s" % zoom)
	var fx = Impact.new()
	var gap_zero = true
	for i in range(20):
		fx.hit(true)
		fx.step(0.067)
		gap_zero = gap_zero and fx.step(0.0) == Vector2.ZERO
		fx.step(0.038)
	check(gap_zero, "105ms repeated cuts leave a centered gap after every pulse")
	g.impact.hit(true)
	g.toggle_reduced_motion()
	g.impact.hit(true)
	check(g.feedback_offset() == Vector2.ZERO and g.impact.trauma == 0, "M clears current pulse and prevents hidden feedback")
	g.queue_free()
	await process_frame
	print("COMFORT BUDGET: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
