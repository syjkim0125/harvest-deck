extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = SubViewport.new()
	view.size = Vector2i(512, 1108)
	root.add_child(view)
	var game = load("res://scripts/game.gd").new()
	view.add_child(game)
	game.set_physics_process(false)
	game._physics_process(0.0)
	await process_frame
	var failures = 0
	for item in [game.hud, game.status, game.orchard_button, game.upgrade_button, game.hire_button]:
		var ok = Rect2(0, 0, 512, 1108).encloses(item.get_rect())
		if not ok:
			failures += 1
		print("PASS " if ok else "FAIL ", item.get_class(), " bounds ", item.get_rect())
	view.queue_free()
	await process_frame
	print("HUD BOUNDS: 5 checks, %d failures" % failures)
	quit(1 if failures else 0)
