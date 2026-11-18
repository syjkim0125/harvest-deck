extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks = 0
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func fixture(g) -> void:
	g.reset_run()
	g.sound_on = false
	g.player = Vector2(700,700)
	g.fruits.clear()
	g.fruits.append({"pos":Vector2(700,710),"home":Vector2(700,710),"hp":3,"kind":0,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO})
func run() -> void:
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	fixture(g)
	check(g.player_is_occluded(),"foreground fruit covering the body requests a locator")
	var fruits = g.fruits.duplicate(true)
	var random_state = g.rng.state
	for i in range(100): g.player_is_occluded()
	check(g.fruits == fruits and g.rng.state == random_state,"locator query cannot change targets or gameplay RNG")
	g.player.y = 755
	check(not g.player_is_occluded(),"walking in front removes the locator immediately")
	g.player.y = 700
	g.fruits[0].pos.x = 760
	check(not g.player_is_occluded(),"a lateral fruit cannot produce a false full-width cue")
	g.fruits[0].pos = Vector2(700,680)
	check(not g.player_is_occluded(),"fruit drawn behind the player cannot occlude them")
	g.fruits[0].pos = Vector2(700,692)
	check(g.player_is_occluded(),"equal-depth fruit follows player in draw order and can occlude")
	fixture(g)
	g.fruits[0].hp = 0
	check(not g.player_is_occluded(),"dead fruit cannot leave a stale locator")
	g.fruits[0].hp = 3
	g.fruits[0].kind = 1
	check(not g.player_is_occluded(),"locked fruit cannot create a locator")
	g.production.orchard_unlocked = true
	check(g.player_is_occluded(),"unlocked golden fruit participates in the same cue")
	fixture(g)
	g.impact.reduced = true
	g.feedback = false
	g.sprite_art = false
	check(g.player_is_occluded(),"static cue remains available with M, reaction OFF and legacy art")
	for i in range(40): g.cargo.append(i % 2)
	check(g.player_is_occluded() and g.cargo.size() == 40,"full stack neither hides the cue nor changes resource ownership")
	g.set_paused(true)
	check(g.player_is_occluded(),"paused scene keeps its static position cue")
	g.fruits.clear()
	check(not g.player_is_occluded(),"removing all occluders clears the cue without a timer")
	g.queue_free()
	await process_frame
	print("PLAYER LOCATOR: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
