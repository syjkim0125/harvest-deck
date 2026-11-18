extends SceneTree
## Fixed-pose render evidence only. These stills are not a finished animation test.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("avatar_render requires a rendering display")
		quit(2)
		return
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_on = false
	game.fruits.clear()
	game.cargo.clear()
	var poses = [["up", Vector2.UP, 9.0], ["down", Vector2.DOWN, 9.0], ["left", Vector2.LEFT, 9.0], ["right", Vector2.RIGHT, 9.0], ["right-next", Vector2.RIGHT, 27.0]]
	for pose in poses:
		game.facing = pose[1]
		game.avatar.reset()
		game.avatar.step(1.0 / 60, pose[1] * pose[2])
		game.camera.position = game.camera_follow_target()
		game._physics_process(0.0)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var path = "res://docs/avatar-v077-%s.png" % pose[0]
		var error = root.get_texture().get_image().save_png(path)
		print("AVATAR_RENDER ", path, " result=", error)
	quit()
