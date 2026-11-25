extends SceneTree
const SF = preload("res://scripts/sf_belt_scroll.gd")
var checks := 0
var errors := 0

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = SF.new()
	root.add_child(game)
	game.set_process(false)
	test(game.mode == 0, "starts with a landing screen")
	game.start_run()
	test(game.mode == 1 and game.wave == 1 and game.enemies.size() == 2, "first wave has two alien types")
	test(game.health == 5 and game.scraps == 0, "health and salvage start clean")
	game.hero = game.enemies[0]["pos"] - Vector2(58, 0)
	game.facing = 1
	game.attack_cd = 0.0
	game.strike()
	test(int(game.enemies[0]["hp"]) == 2, "close-range facing attack damages the crawler")
	test(game.combo == 1 and game.attack_cd > 0.0, "confirmed strike has combo and cooldown")
	game.attack_cd = 0.0
	game.enemies[0]["hp"] = 1
	game.strike()
	test(game.enemies.size() == 1 and game.scraps == 1, "defeated alien awards salvage once")
	game.enemies[0]["target"] = game.hero
	game.enemies[0]["telegraph"] = 0.02
	var old_health: int = game.health
	var old_pos: Vector2 = game.hero
	game.dodge(Vector2.LEFT)
	test(game.hero.x < old_pos.x and game.invulnerable > 0.0, "evade moves the player and grants brief invulnerability")
	game.advance_enemies(0.03)
	test(game.health == old_health, "evading a locked warning prevents the hit")
	game.invulnerable = 0.0
	game.enemies[0]["target"] = game.hero
	game.enemy_attack(game.enemies[0])
	test(game.health == old_health - 1, "failed escape receives predictable telegraphed damage")
	game.start_run()
	test(game.scraps == 0 and game.enemies.size() == 2 and game.mode == 1, "restarting clears combat state")
	game.queue_free()
	await process_frame
	print("SF COMBAT: %d checks / %d failures" % [checks, errors])
	quit(1 if errors else 0)

func test(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(message)
	print("PASS " if ok else "FAIL ", message)
