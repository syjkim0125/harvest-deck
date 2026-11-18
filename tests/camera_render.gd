extends SceneTree
## Captures the real follow code; never snaps camera to its target during the route.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var output = ProjectSettings.globalize_path("res://../camera-v079-frames")
	DirAccess.make_dir_recursive_absolute(output)
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.fruits.clear()
	for frame in range(60):
		g.drag_vector = Vector2.RIGHT if frame < 24 else (Vector2.UP if frame < 48 else Vector2.ZERO)
		g._physics_process(1.0 / 30.0)
		g.status.text = "SCRIPTED FOLLOW / %s\nActual camera follow; fixed 30Hz simulation\nNot human feel or source-video parity" % ("RIGHT" if frame < 24 else ("UP" if frame < 48 else "STOP"))
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var error = root.get_texture().get_image().save_png(output.path_join("frame-%03d.png" % frame))
		if error != OK:
			push_error("Frame save failed: %d" % error)
			quit(1)
			return
	print("CAMERA_RENDER: 60 frames,2 simulated seconds; player=",g.player," camera=",g.camera.position)
	quit()
