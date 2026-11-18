extends SceneTree

const View = preload("res://scripts/cargo_view.gd")
const Game = preload("res://scripts/game.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func run() -> void:
	var fx = View.new()
	fx.send(1, Vector2(10, 80), Vector2(200, 120))
	check(View.position_at(fx.transfers[0]) == Vector2(10, 80) and fx.transfers[0].kind == 1, "handoff starts at its slice position with the same kind")
	fx.step(View.DURATION / 2)
	check(View.position_at(fx.transfers[0]).is_equal_approx(Vector2(105, 76)), "midpoint follows the designed arc")
	var end = fx.transfers[0].duplicate()
	end.age = View.DURATION
	check(View.position_at(end).is_equal_approx(end.destination), "arc ends at the depot without overshoot")
	var positions = []
	for rate in [30, 60, 120]:
		fx.clear()
		fx.send(0, Vector2.ZERO, Vector2(100, 0))
		for i in range(rate / 10):
			fx.step(1.0 / rate)
		positions.append(View.position_at(fx.transfers[0]))
		fx.step(0.2)
		check(fx.transfers.is_empty(), "handoff expires at %dHz without leaving a ghost" % rate)
	check(positions[0].is_equal_approx(positions[1]) and positions[1].is_equal_approx(positions[2]), "same elapsed time has the same arc at 30 / 60 / 120Hz")
	for i in range(100):
		fx.send(i % 2, Vector2.ZERO, Vector2.ONE)
	check(fx.transfers.size() == View.MAX_TRANSFERS, "dense cosmetic sends are bounded")
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.fruits.clear()
	g.cargo.assign([0, 1, 0])
	g.player = g.depot
	g.simulate(0.05, Vector2.ZERO)
	check(g.cargo.size() == 2 and g.stock == 1 and g.cargo_view.transfers.size() == 1, "handoff credits production once at existing 40ms timing, not animation end")
	var state = g.cargo_view.transfers.duplicate(true)
	g.set_paused(true)
	g._physics_process(0.5)
	check(g.cargo_view.transfers == state and g.cargo.size() + g.stock == 3, "pause freezes handoff without consuming or duplicating items")
	g.toggle_reduced_motion()
	check(g.cargo_view.transfers.is_empty() and g.cargo.size() + g.stock == 3, "reduced motion removes cosmetic movement without touching ownership")
	g.set_paused(false)
	g.simulate(0.3, Vector2.ZERO)
	check(g.cargo_view.transfers.is_empty() and g.cargo.is_empty() and g.stock == 3, "reduced motion preserves normal delivery and processing")
	g.reset_run()
	g.impact.reduced = false
	g.fruits.clear()
	g.cargo.assign([1])
	g.player = g.depot
	g.simulate(0.05, Vector2.ZERO)
	g.player = Vector2(700, 900)
	g.simulate(1.0, Vector2.ZERO)
	check(g.cargo_view.transfers.is_empty() and g.stock == 1 and g.production.ready == [1], "walking away during handoff cannot cancel or duplicate the deposit")
	g.cargo_view.send(1, Vector2.ZERO, g.depot)
	g.reset_run()
	check(g.cargo_view.transfers.is_empty() and g.stock == 0, "explicit reset clears traces with the rest of the run")
	var outcomes = []
	for effects in [false, true]:
		g.reset_run()
		g.feedback = effects
		g.fruits.clear()
		g.cargo.assign([0, 1, 0, 1, 0, 1])
		g.player = g.depot
		for frame in range(60):
			g.simulate(1.0 / 60, Vector2.ZERO)
		outcomes.append([g.production.ready.duplicate(), g.production.raw.duplicate(), g.production.active_kind, g.rng.state])
	check(outcomes[0] == outcomes[1], "cosmetic delivery ON/OFF preserves kinds, timing and gameplay RNG")
	g.feedback = true
	g.cargo_view.send(0, Vector2.ZERO, g.depot)
	var event = InputEventKey.new()
	event.physical_keycode = KEY_3
	event.pressed = true
	g._input(event)
	check(not g.feedback and g.cargo_view.transfers.is_empty(), "effect OFF clears already running handoff traces")
	g.reset_run()
	var settled = g.camera.position
	g._physics_process(0.1)
	check(g.camera.position.is_equal_approx(settled), "reset starts at the settled camera target instead of introducing a follow pan")
	g.queue_free()
	await process_frame
	print("CARGO VIEW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
