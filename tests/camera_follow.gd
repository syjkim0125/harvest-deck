extends SceneTree
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
	var snapshots = []
	var outcomes = []
	var rows = []
	for rate in [5, 30, 60, 120]:
		var g = Game.new()
		root.add_child(g)
		g.set_physics_process(false)
		g.sound_on = false
		g.fruits.clear()
		var sample = []
		for frame in range(rate * 2):
			g.drag_vector = Vector2.RIGHT if frame < rate * 4 / 5 else (Vector2.UP if frame < rate * 8 / 5 else Vector2.ZERO)
			g._physics_process(1.0 / rate)
			if frame + 1 in [rate * 4 / 5, rate * 8 / 5, rate * 2]:
				sample.append(g.camera.position)
				rows.append({"rate": rate, "time": float(frame + 1) / rate, "camera": [g.camera.position.x, g.camera.position.y], "target": [g.camera_follow_target().x, g.camera_follow_target().y]})
		snapshots.append(sample)
		outcomes.append([g.player, g.time, g.hits, g.cargo.duplicate(), g.stock, g.cash])
		var held: Vector2 = g.camera.position
		g.set_paused(true)
		g._physics_process(0.5)
		check(g.camera.position == held and g.camera.offset == Vector2.ZERO, "pause freezes tracking and clears shake at %dHz" % rate)
		g.reset_run()
		check(g.camera.position == g.camera_follow_target(), "reset aligns camera without a recovery pan at %dHz" % rate)
		g.queue_free()
		await process_frame
	var max_difference = 0.0
	for i in range(4):
		var error = 0.0
		for j in range(3):
			error = maxf(error, snapshots[i][j].distance_to(snapshots[3][j]))
		max_difference = maxf(max_difference, error)
		check(error < 0.01, "same-time follow checkpoints agree with 120Hz for %dHz (error %.4f)" % [[5,30,60,120][i], error])
	var conserved = true
	for i in range(1, 4):
		conserved = conserved and outcomes[i][0].is_equal_approx(outcomes[0][0]) and absf(outcomes[i][1] - outcomes[0][1]) < 0.00001 and outcomes[i].slice(2) == outcomes[0].slice(2)
	check(conserved, "tracking changes neither movement nor resources across rates")
	var file = FileAccess.open("res://docs/camera-follow-v079.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"prototype simulation coordinates, not original-video measurements", "max_checkpoint_difference_world_units":max_difference, "samples":rows}, "  "))
	print("CAMERA FOLLOW: %d checks, %d failures; max difference %.4f world units" % [checks, failures, max_difference])
	quit(1 if failures else 0)
