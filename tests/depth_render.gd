extends SceneTree
## Fixed overlap fixture, not human play. Run with -- before or -- after.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var phase = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "after"
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.impact.enabled = false
	g.production.orchard_unlocked = true
	g.facing = Vector2.LEFT
	g.fruits.clear()
	# Intentionally reverse ground depth: near golden first, far green last.
	for target in [[Vector2(700,727),1],[Vector2(706,695),0],[Vector2(754,713),0]]:
		g.fruits.append({"pos":target[0],"home":target[0],"hp":2,"kind":target[1],"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
	for i in range(24): g.cargo.append(i % 2)
	g.camera.position = g.camera_follow_target()
	for y in [700,720,755]:
		g.player = Vector2(700,y)
		g._physics_process(0.0)
		g.status.text = "SCRIPTED DEPTH / %s / Y%d\nFixed camera, 24 items, no shake\nOverlap comparison; not human play" % [phase,y]
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result = root.get_texture().get_image().save_png("res://docs/depth-v0713-%s-%d.png" % [phase,y])
		print("DEPTH_RENDER ",phase," y=",y," save=",result," cargo=",g.cargo.size()," hits=",g.hits)
	quit()
