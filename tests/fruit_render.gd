extends SceneTree
## Fixed A/B art fixture; these stills do not demonstrate a finished animation.
func _initialize() -> void:
	call_deferred("run")
func capture(g, name: String, label: String) -> void:
	g._physics_process(0.0)
	g.status.text = "SCRIPTED ART CHECK / %s\nSame fixture; camera shake disabled\nStatic sprite plus procedural response" % label
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path = "res://docs/fruit-v0710-%s.png" % name
	var error = root.get_texture().get_image().save_png(path)
	print("FRUIT_RENDER ", name, " result=", error, " hits=", g.hits, " cargo=", g.cargo.size())
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.impact.enabled = false
	g.fruits.clear()
	for point in [Vector2(700,655),Vector2(625,610),Vector2(775,625)]:
		g.fruits.append({"pos":point,"home":point,"hp":3,"kind":0,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
	g.camera.position = g.camera_follow_target()
	g.sprite_art = false
	await capture(g,"legacy","LEGACY IDLE")
	g.sprite_art = true
	await capture(g,"sprite","NEW SPRITE IDLE")
	g.attack()
	await capture(g,"hit","CONFIRMED HIT")
	g.attack()
	g.attack()
	g.cooldown = 100.0
	g.simulate(0.06,Vector2.ZERO)
	await capture(g,"cut","CUT / THREE REWARD ITEMS")
	quit()
