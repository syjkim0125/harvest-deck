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
	g.player = Vector2(700,700)
	g.facing = Vector2.RIGHT
	g.fruits.append({"pos":Vector2(755,700),"home":Vector2(755,700),"hp":3,"kind":1,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
func run() -> void:
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	for kind in [0,1]:
		var image = g.fruit_texture(kind).get_image()
		check(image.get_width() <= 512 and image.get_height() <= 512 and image.has_mipmaps() and image.get_data().size() <= 1500000, "bounded imported texture data with mipmaps for kind%d" % kind)
		var region = g.fruit_sprite_region(kind)
		check(Rect2(Vector2.ZERO,image.get_size()).encloses(region) and region.size.x > 0 and image.get_pixel(0,0).a == 0.0, "resolution-aware frame and transparent corner for kind%d" % kind)
		var rect = g.fruit_sprite_rect(Vector2(700,700),kind,24)
		check(rect.size.x == 48 and rect.end.y == 724 and rect.get_center().x == 700, "body anchor and width survive import resizing for kind%d" % kind)
	fixture(g)
	check(g.attack() == 0 and g.hits == 0 and g.cargo.is_empty(), "new golden art cannot bypass the locked orchard")
	g.production.collected_cash = 50
	g.player = g.orchard_pad
	check(g.try_unlock_orchard() and g.cash == 0, "existing paid unlock activates the second fruit")
	g.player = Vector2(700,700)
	for i in range(3):
		g.attack()
	check(g.cargo == [1,1,1], "golden fruit retains kind1 rewards")
	var outcomes = []
	for enabled in [false,true]:
		fixture(g)
		g.production.orchard_unlocked = true
		g.sprite_art = enabled
		for i in range(3):
			g.attack()
		outcomes.append([g.hits,g.cargo.duplicate(),g.particles.duplicate(true),g.rng.state])
	check(outcomes[0] == outcomes[1], "golden sprite and legacy style preserve hit/reward/particle RNG state")
	g.queue_free()
	await process_frame
	print("GOLDEN ART: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
