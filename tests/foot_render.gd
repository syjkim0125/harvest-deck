extends SceneTree
## Scripted renderer capture, not a human play or performance benchmark.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var output = ProjectSettings.globalize_path("res://../foot-v078-frames")
	DirAccess.make_dir_recursive_absolute(output)
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.fruits.clear()
	g.cargo.clear()
	var directions = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.ZERO, Vector2.DOWN]
	var names = ["RIGHT", "UP", "LEFT", "STOP", "DOWN"]
	for frame in range(60):
		var phase = frame / 12
		g.simulate(1.0 / 30.0, directions[phase])
		g.camera.position = g.camera_follow_target()
		g._physics_process(0.0)
		g.status.text = "SCRIPTED FOOT ROUTE / %s\nFixed 30Hz simulation; renderer capture\nNo human feel or reference-parity claim" % names[phase]
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var error = root.get_texture().get_image().save_png(output.path_join("frame-%03d.png" % frame))
		if error != OK:
			push_error("Frame save failed: %d" % error)
			quit(1)
			return
	print("FOOT_RENDER: 60 frames, 2 simulated seconds, player=", g.player)
	quit()
