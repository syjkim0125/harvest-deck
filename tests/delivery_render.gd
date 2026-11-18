extends SceneTree
## Render-only deterministic evidence. Requires a real display; not a human feel test.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("delivery_render requires a real rendering display")
		quit(2)
		return
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_on = false
	game.fruits.clear()
	game.cargo.resize(40)
	for i in range(40):
		game.cargo[i] = 0 if i < 30 else 1
	game.player = game.depot
	for frame in range(121):
		if frame > 0:
			game.simulate(1.0 / 60.0, Vector2.ZERO)
		game.camera.position = game.camera_follow_target()
		game._physics_process(0.0)
		await process_frame
		if frame in [0, 8, 120]:
			await RenderingServer.frame_post_draw
			var path = "res://docs/cargo-v076-%03d.png" % frame
			var result = root.get_texture().get_image().save_png(path)
			print("RENDER ", path, " result=", result, " bag=", game.cargo.size(), " stock=", game.stock, " cosmetic=", game.cargo_view.transfers.size())
	print("DELIVERY_RENDER: two simulated seconds, stock=", game.stock, " bag=", game.cargo.size())
	quit()
