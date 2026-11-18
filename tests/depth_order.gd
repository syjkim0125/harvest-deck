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
func fruit(at: Vector2,kind: int = 0) -> Dictionary:
	return {"pos":at,"home":at,"hp":3,"kind":kind,"flash":0.0,"respawn":0.0,"freeze":0.0,"recoil":Vector2.ZERO}
func run() -> void:
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.fruits.clear()
	g.player = Vector2(700,720)
	g.fruits.append(fruit(Vector2(700,727),1))
	g.fruits.append(fruit(Vector2(706,695)))
	g.production.orchard_unlocked = true
	check(g.world_draw_order() == [1,-1,0],"far fruit, player, near fruit draw in ground-depth order")
	var before = g.fruits.duplicate(true)
	var rng_state = g.rng.state
	for i in range(100): g.world_draw_order()
	check(g.fruits == before and g.rng.state == rng_state,"presentation sorting never reorders targets or consumes gameplay RNG")
	g.player.y = 700
	check(g.world_draw_order() == [-1,1,0],"walking behind both fruit changes actor depth")
	g.player.y = 755
	check(g.world_draw_order() == [1,0,-1],"walking in front of both fruit changes actor depth")
	g.player.y = 720
	g.fruits[0].recoil = Vector2(0,-100)
	g.fruits[0].flash = 0.055
	for i in range(40): g.cargo.append(i % 2)
	check(g.world_draw_order() == [1,-1,0],"recoil, squash and full stack do not reorder ground anchors")
	g.impact.reduced = true
	g.feedback = false
	g.sprite_art = false
	check(g.world_draw_order() == [1,-1,0],"reduced motion and legacy art share the same depth")
	g.production.orchard_unlocked = false
	check(g.world_draw_order() == [1,-1],"locked fruit never enters presentation list")
	g.fruits[1].hp = 0
	check(g.world_draw_order() == [-1],"dead fruit never enters presentation list")
	g.production.orchard_unlocked = true
	g.fruits[1].hp = 3
	g.fruits[0].pos.y = 712 # Both fruit feet exactly level with player's y+16.
	g.fruits[1].pos.y = 712
	check(g.world_draw_order() == [-1,0,1] and g.world_draw_order() == [-1,0,1],"equal-depth ties use stable player/target IDs")
	g.reset_run()
	var order = g.world_draw_order()
	var count = 0
	for f in g.fruits:
		if f.hp > 0 and g.production.can_harvest(f.kind): count += 1
	check(order.size() == count + 1 and order.count(-1) == 1,"reset contains each visible target and player exactly once")
	g.queue_free()
	await process_frame
	print("DEPTH ORDER: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
