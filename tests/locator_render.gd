extends SceneTree
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
	g.facing = Vector2.UP
	g.fruits.clear()
	# Dense same-height foreground can conceal head and body.
	for x in [690,710]:
		var at = Vector2(x,710)
		g.fruits.append({"pos":at,"home":at,"hp":3,"kind":0,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
	g.player = Vector2(700,700)
	g.camera.position = g.camera_follow_target()
	var rows = []
	for config in [["hidden",700,false,0],["reduced",700,true,24],["front",755,false,0]]:
		g.player = Vector2(700,config[1])
		g.impact.reduced = config[2]
		g.cargo.clear()
		for i in range(config[3]): g.cargo.append(i % 2)
		g._physics_process(0.0)
		g.status.text = "SCRIPTED LOCATOR / %s / %s\nFixed camera; shake OFF\nStatic cue, no human rating" % [phase,config[0]]
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var error = root.get_texture().get_image().save_png("res://docs/locator-v0714-%s-%s.png" % [phase,config[0]])
		var occluded = g.player_is_occluded() if g.has_method("player_is_occluded") else false
		rows.append({"case":config[0],"save":error,"occluded":occluded,"cargo":g.cargo.size(),"hits":g.hits})
		print("LOCATOR_RENDER ",phase," ",config[0]," result=",error," cue=",occluded)
	var f = FileAccess.open("res://docs/locator-v0714-%s.json" % phase,FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  "))
	quit()
