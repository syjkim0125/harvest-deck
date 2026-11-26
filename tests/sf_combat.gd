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
	test(game.attack_landed and float(game.enemies[0]["telegraph"]) == 0.0 and float(game.enemies[0]["recovery"]) > 0.0, "confirmed hit interrupts enemy windup and enters recovery")
	test(game.hero_pose() == 2 and game.contact_count == 1, "contact pose and sound request share a confirmed event")
	if DisplayServer.get_name() == "headless":
		test(not game.impact_audio.playing, "headless tests verify sound request without creating a playback")
	test(game.combo == 1 and game.attack_cd > 0.0, "confirmed strike has combo and cooldown")
	test(game.impact_pause > 0.0 and game.impact_fx > 0.0, "confirmed contact starts a visible impact stop")
	var stop_before: float = game.impact_pause
	var stopped_enemy_position: Vector2 = game.enemies[0]["pos"]
	game._process(0.016)
	test(game.enemies[0]["pos"] == stopped_enemy_position and game.impact_pause < stop_before, "impact stop freezes enemies for one frame")
	game.attack_cd = 0.0
	game.enemies[0]["hp"] = 1
	game.strike()
	test(game.impact_pause > 0.055, "defeat contact uses a stronger impact pause")
	test(game.fallen.size() == 1 and float(game.fallen[0]["life"]) > 0.0, "defeat visual persists separately from active enemies")
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
	test(game.impact_pause == 0.0 and game.impact_fx == 0.0, "restart clears impact state")
	game.enemies[0]["pos"] = game.hero + Vector2(-65, 0)
	game.enemies[1]["pos"] = game.hero + Vector2(-80, 0)
	game.facing = 1
	game.strike()
	test(game.impact_pause == 0.0 and game.impact_fx == 0.0, "a whiff never freezes combat or plays contact effects")
	test(game.hero_pose() == 3 and game.contact_count == 0, "whiff pose never triggers contact sound")
	test(not game.attack_landed, "miss uses a distinct swing state, never confirmed contact")
	test(game.combo == 0 and int(game.enemies[0]["hp"]) == 3, "a missed swing never rewards combo or damage")
	# V-001: warn, lock, lunge, recover. Changing hero position never retargets the lunge.
	game.start_run()
	game.enemies.resize(1)
	var crawler: Dictionary = game.enemies[0]
	game.hero = Vector2(205, 395)
	crawler["pos"] = Vector2(264, 395)
	crawler["cooldown"] = 0.0
	game.advance_enemies(0.016)
	var locked: Vector2 = crawler["target"]
	test(float(crawler["telegraph"]) > 0.0 and locked == game.hero, "crawler warns and locks a destination")
	game.hero = Vector2(205, 462)
	for i in range(48):
		game.advance_enemies(0.016)
		if float(crawler["charge_left"]) > 0.0:
			break
	test(float(crawler["charge_left"]) > 0.0 and crawler["target"] == locked, "enemy begins locked lunge without tracking escape")
	var precharge: Vector2 = crawler["pos"]
	var prior_hp: int = game.health
	game.advance_enemies(0.05)
	test(crawler["pos"] != precharge, "charge visibly moves the enemy")
	for i in range(16):
		game.advance_enemies(0.016)
	test(game.health == prior_hp and game.contact_count == 0, "escaping locked charge avoids damage and contact audio")
	game.start_run()
	game.enemies.resize(1)
	crawler = game.enemies[0]
	game.hero = Vector2(205, 395)
	crawler["target"] = game.hero
	crawler["charge_left"] = 0.03
	prior_hp = game.health
	game.advance_enemies(0.05)
	game.invulnerable = 0.0
	game.advance_enemies(0.05)
	test(game.health == prior_hp - 1 and game.contact_count == 1, "locked lunge applies damage and sound only once before recovery")
	game.start_run()
	game.hero = game.enemies[0]["pos"] - Vector2(58, 0)
	game.enemies[0]["charge_left"] = 0.18
	game.strike()
	test(float(game.enemies[0]["charge_left"]) == 0.0, "confirmed counterattack cancels an active charge")
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
