extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	# Reproducible 6-second scripted harvest then delivery. No human feel claims.
	for i in range(360):
		var target = Vector2(510, 650) if i < 180 else g.depot
		var direction = (target - g.player).normalized() if target.distance_to(g.player) > 10 else Vector2.ZERO
		g.simulate(1.0 / 60.0, direction)
		g.camera.position = g.camera_follow_target()
		g.camera.offset = g.feedback_offset()
		g._physics_process(0.0) # Refresh the real responsive HUD, no simulation advance.
		g.queue_redraw()
		await process_frame
		if i in [120, 359]:
			await RenderingServer.frame_post_draw
			var path = "user://godot-harvest-%d.png" % i
			var error = root.get_texture().get_image().save_png(path)
			print("SCREENSHOT ", ProjectSettings.globalize_path(path), " result=", error)
	print("VISUAL_SMOKE hits=", g.hits, " cash=", g.cash, " stock=", g.stock, " cargo=", g.cargo.size())
	quit()
