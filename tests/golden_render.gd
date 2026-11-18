extends SceneTree
## Fixed renderer fixture for unlock gating and both fruit styles; not human play.
func _initialize() -> void:
	call_deferred("run")
func capture(g, name: String, label: String) -> void:
	g._physics_process(0.0)
	g.status.text = "SCRIPTED GOLDEN FRUIT / %s\nSame fixture; camera shake disabled\nStatic sprite plus procedural response" % label
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png("res://docs/golden-v0711-%s.png" % name)
	print("GOLDEN_RENDER ",name," result=",error," unlocked=",g.production.orchard_unlocked," hits=",g.hits," cargo=",g.cargo)
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
	var targets = [[Vector2(700,655),1],[Vector2(625,610),0],[Vector2(775,625),1]]
	for target in targets:
		g.fruits.append({"pos":target[0],"home":target[0],"hp":3,"kind":target[1],"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
	g.camera.position = g.camera_follow_target()
	await capture(g,"locked","LOCKED / KIND1 HIDDEN")
	g.production.collected_cash = 50
	g.player = g.orchard_pad
	g.try_unlock_orchard()
	g.player = Vector2(700,720)
	g.sprite_art = false
	await capture(g,"legacy","UNLOCKED LEGACY")
	g.sprite_art = true
	await capture(g,"sprite","UNLOCKED NEW ART")
	g.attack()
	await capture(g,"hit","CONFIRMED KIND1 HIT")
	g.attack()
	g.attack()
	g.cooldown = 100
	g.simulate(0.06,Vector2.ZERO)
	await capture(g,"cut","THREE KIND1 REWARD ITEMS")
	quit()
