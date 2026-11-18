extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks = 0
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)
func fixture(g) -> void:
	g.reset_run()
	g.sound_on = false
	g.fruits.clear()
	g.player = Vector2(700, 700)
	g.facing = Vector2.RIGHT
	g.fruits.append({"pos":Vector2(755,700),"home":Vector2(755,700),"hp":3,"kind":0,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
func run() -> void:
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	var image = Game.WATERMELON.get_image()
	check(image.has_mipmaps(), "large sprite imports mipmaps for small on-screen rendering")
	check(image.get_pixel(0,0).a == 0.0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a == 0.0 and image.get_pixel(int(image.get_width()*0.48),int(image.get_height()*0.72)).a > 0.95, "sprite has transparent corners and a solid body")
	check(Rect2(Vector2.ZERO, image.get_size()).encloses(g.fruit_sprite_region(0)), "authored visible frame stays within the unmodified generated source")
	var rect = g.watermelon_rect(Vector2(700,700),24)
	check(rect.size.x == 48.0 and rect.end.y == 724.0 and rect.get_center().x == 700.0, "sprite body width and bottom remain aligned with existing fruit center")
	fixture(g)
	g.facing = Vector2.LEFT
	check(g.attack() == 0 and g.fruit_display_scale(g.fruits[0]) == Vector2.ONE, "whiff cannot create a squash pulse")
	g.facing = Vector2.RIGHT
	var center: Vector2 = g.fruits[0].pos
	check(g.attack() == 1 and g.fruit_display_scale(g.fruits[0]).x > 1.0 and g.fruits[0].pos == center, "confirmed-hit squash leaves collision position unchanged")
	g.fruits[0].flash = 10.0
	check(g.fruit_display_scale(g.fruits[0]).is_equal_approx(Vector2(1.1,0.9)), "squash amplitude is bounded rather than accumulated")
	g.impact.reduced = true
	check(g.fruit_display_scale(g.fruits[0]) == Vector2.ONE, "reduced motion removes the new deformation")
	g.impact.reduced = false
	g.feedback = false
	check(g.fruit_display_scale(g.fruits[0]) == Vector2.ONE, "reaction OFF removes deformation immediately")
	g.feedback = true
	fixture(g)
	for i in range(3):
		g.attack()
	var pieces = 0
	for p in g.particles:
		pieces += int(p.get("piece", false))
	check(g.cargo == [0,0,0] and pieces == 4, "four cosmetic kill pieces do not multiply the three-item reward")
	var outcomes = []
	for enabled in [false,true]:
		fixture(g)
		g.sprite_art = enabled
		for i in range(3):
			g.attack()
		outcomes.append([g.hits,g.cargo.duplicate(),g.particles.duplicate(true),g.rng.state,g.impact.trauma])
	check(outcomes[0] == outcomes[1], "new sprite and legacy art preserve hits, rewards, particle state and RNG")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_6
	event.pressed = true
	var prior = g.sprite_art
	var cargo = g.cargo.duplicate()
	g._input(event)
	check(g.sprite_art != prior and g.cargo == cargo, "6 toggles the comparison art without resetting the run")
	g.queue_free()
	await process_frame
	print("FRUIT ART: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
