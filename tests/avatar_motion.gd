extends SceneTree

const Motion = preload("res://scripts/avatar_motion.gd")
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

func target(game) -> void:
	game.reset_run()
	game.sound_on = false
	game.fruits.clear()
	game.player = Vector2(700, 700)
	game.facing = Vector2.RIGHT
	game.fruits.append({"pos": Vector2(755, 700), "home": Vector2(755, 700), "hp": 1000, "kind": 0, "flash": 0.0, "respawn": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO})

func run() -> void:
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var motion = Motion.new()
		motion.step(1.0 / 120, direction * 3)
		var first: Vector2 = direction * 3 + motion.foot(0, direction, false).position
		motion.step(1.0 / 120, direction * 3)
		var second: Vector2 = direction * 6 + motion.foot(0, direction, false).position
		check(first.is_equal_approx(second), "straight stance foot stays planted toward %s" % direction)
	var samples = []
	for rate in [30, 60, 120]:
		var motion = Motion.new()
		for i in range(rate / 10):
			motion.step(1.0 / rate, Vector2.RIGHT * Game.SPEED / rate)
		samples.append(motion.foot(1, Vector2.RIGHT, false).position)
	check(samples[0].is_equal_approx(samples[1]) and samples[1].is_equal_approx(samples[2]), "gait matches actual distance at 30 / 60 / 120Hz")
	var motion = Motion.new()
	motion.step(0.01, Vector2(3, 0))
	var distance = motion.distance
	motion.step(0.4, Vector2.ZERO)
	check(motion.distance == distance and motion.walk_weight < 0.001, "stopping settles the pose without advancing steps")
	check(motion.bob(true) == 0.0, "reduced motion removes decorative body bob")
	motion.confirmed_hit()
	for i in range(100):
		motion.confirmed_hit()
	check(motion.kick() == Motion.KICK_UNITS, "crowd hits cannot add weapon recoil")
	motion.step(Motion.KICK_SECONDS, Vector2.ZERO)
	check(motion.kick() == 0.0, "weapon recoil returns to zero without an idle oscillation")
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	target(g)
	g.fruits.clear()
	var idle_bar = g.saw_endpoints()
	g.simulate(0.5, Vector2.ZERO)
	check(g.saw_endpoints() == idle_bar and g.avatar.kick() == 0.0, "idle and repeated whiffs leave saw endpoints still")
	g.player = Game.BOUNDS.end - Vector2.ONE * 20
	g.avatar.reset()
	g.simulate(0.2, Vector2.RIGHT)
	check(g.avatar.distance == 0.0 and g.avatar.walk_weight == 0.0, "pressing into a world boundary cannot run the feet in place")
	target(g)
	var normal_bar = g.saw_endpoints()
	g.attack()
	check(g.avatar.kick() > 0.0 and g.saw_endpoints()[0].x < normal_bar[0].x and g.hits == 1, "confirmed hit moves only the cosmetic weapon recoil")
	g.set_paused(true)
	check(g.avatar.kick() == 0.0, "pause clears a stale weapon kick")
	target(g)
	g.attack()
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.avatar.kick() == 0.0 and g.paused, "focus-out clears weapon feedback through pause")
	target(g)
	g.attack()
	g.toggle_reduced_motion()
	check(g.avatar.kick() == 0.0 and g.impact.reduced, "M clears weapon recoil with other reduced-motion effects")
	g.attack()
	check(g.avatar.kick() == 0.0 and g.hits == 2, "reduced motion preserves hits without weapon kicks")
	g.reset_run()
	check(g.avatar.distance == 0.0 and g.avatar.walk_weight == 0.0 and g.avatar.kick() == 0.0, "reset clears gait and weapon phase")
	var outcomes = []
	for feedback in [false, true]:
		target(g)
		g.feedback = feedback
		g.impact.reduced = false
		g.simulate(0.5, Vector2.RIGHT)
		outcomes.append([g.player, g.hits, g.cargo.duplicate(), g.stock, g.rng.state])
	check(outcomes[0] == outcomes[1], "avatar feedback preserves gameplay positions, harvest and RNG")
	g.queue_free()
	await process_frame
	print("AVATAR MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
