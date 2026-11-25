extends SceneTree
const WORLD = preload("res://scripts/sf_galaxy_sim.gd")
const GAME = preload("res://scripts/sf_belt_scroll.gd")
var checks := 0
var errors := 0

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var galaxy = WORLD.new(20261125)
	test(galaxy.current_system == 0 and galaxy.credits == 18 and galaxy.fuel == 6, "independent civilian begins at Freeport with provisions")
	test(galaxy.systems.size() == 5 and galaxy.visited[0], "five star destinations exist and starting port is known")
	test(not galaxy.can_travel(4) and galaxy.can_travel(1) and galaxy.can_travel(2), "star routes respect visible adjacency")
	test(not galaxy.travel_to(4)["ok"] and galaxy.turns == 0, "illegal jumps cannot skip routes or advance war")
	test(not galaxy.is_named_recruitable("Marshal Voss") and not galaxy.is_named_recruitable("Oracle Sevrin"), "named faction leaders cannot join the player")
	test(galaxy.is_named_recruitable("Wandering Medic"), "ordinary recruits remain eligible")
	var first: Dictionary = galaxy.travel_to(1)
	test(first["ok"] and first["system"] == 1, "player can jump to connected enemy territory")
	test(galaxy.current_system == 1 and galaxy.visited[1] and galaxy.fuel == 5, "jump consumes fuel and reveals the sector")
	test(galaxy.turns == 1 and not galaxy.last_news.is_empty(), "NPC factions act during every travel turn")
	var replay = WORLD.new(20261125)
	var same: Dictionary = replay.travel_to(1)
	test(same["event"] == first["event"] and replay.last_news == galaxy.last_news, "same seed and route replay the same incident and faction news")
	var before_credits: int = galaxy.credits
	galaxy.finish_expedition(4, true)
	test(galaxy.cargo == 4 and galaxy.credits == before_credits + 12 and galaxy.fame == 1, "successful salvage funds and raises captain reputation")
	test(galaxy.fuel == 6, "returning from a mission restores one fuel")
	test(galaxy.nearest_reachable(Vector2(287, 390)) == 3, "tapping a connected star selects that destination")
	test(galaxy.nearest_reachable(Vector2(274, 491)) == -1, "inaccessible star cannot be jumped to")

	var game = GAME.new()
	root.add_child(game)
	game.set_process(false)
	test(game.mode == 0, "screen begins with original playable landing intro")
	game.start_campaign()
	test(game.mode == 4 and game.campaign_started, "campaign begins with captain creation")
	game.choose_captain(0)
	test(game.mode == 5, "captain origin leads to starship choice")
	game.choose_starship(0)
	test(game.mode == 6 and game.galaxy.current_system == 0, "chosen civilian ship arrives at the starmap")
	test(game.jump_to_system(1) and game.mode == GAME.Mode.EXPLORE, "travel enters spatial exploration instead of automatic combat")
	test(game.active_sector == 1 and game.health == 6 and game.wave == 1 and game.enemies.is_empty(), "guardian starts exploration without spawning enemies")
	var initial_hero: Vector2 = game.hero
	game.begin_touch(0, Vector2(180, 100))
	game.end_touch(0, Vector2(180, 100))
	test(game.touch_id == -1 and game.hero == initial_hero and game.expedition_route.is_empty(), "HUD taps cannot select an exploration route")
	game.begin_touch(0, game.hero)
	game.drag_touch(game.hero + (GAME.REFUGE - game.hero).normalized() * 60.0)
	for i in range(60):
		if game.rescue_pending:
			break
		game._process(0.016)
	test(game.mode == GAME.Mode.EXPLORE and game.rescue_pending and game.expedition_route == "Nooli refuge" and game.scraps == 2, "actual movement discovers Nooli and starts escort instead of ending the expedition")
	game.end_touch(0, GAME.REFUGE)
	test(game.mode == GAME.Mode.EXPLORE and game.touch_id == -1 and not game.nooli_recruited, "discovery is not recruitment before extraction")
	game.begin_touch(0, game.hero)
	game.drag_touch(game.hero + (GAME.LANDING - game.hero).normalized() * 60.0)
	for i in range(90):
		if game.mode == GAME.Mode.CLEAR:
			break
		game._process(0.016)
	test(game.mode == GAME.Mode.CLEAR and game.scraps == 2, "escort requires returning physically to landing without duplicating salvage")
	game.finish_expedition(true)
	test(game.mode == GAME.Mode.GALAXY and game.galaxy.cargo == 2 and game.last_expedition_route == "Nooli refuge" and game.nooli_recruited, "refuge reward and recruited crew persist on return")
	game.start_campaign()
	game.choose_captain(1)
	game.choose_starship(1)
	test(game.galaxy.fuel == 5, "escort ship trades fuel range for extra hull")
	test(game.last_expedition_route.is_empty() and not game.nooli_recruited, "new campaign clears previous expedition history")
	test(game.jump_to_system(1) and game.health == 6 and game.mode == GAME.Mode.EXPLORE, "escort hull adds one HP for a scavenger captain")
	game.begin_touch(0, game.hero)
	game.drag_touch(game.hero + (GAME.QUARRY - game.hero).normalized() * 60.0)
	for i in range(60):
		if game.mode != GAME.Mode.EXPLORE:
			break
		game._process(0.016)
	test(game.mode == GAME.Mode.COMBAT and game.expedition_route == "Amber quarry" and game.enemies.size() == 2, "rightward exploration reaches quarry and spawns combat")
	game.end_touch(0, Vector2(305, 340))
	test(game.touch_id == -1 and game.move_axis == Vector2.ZERO and game.attack_cd == 0.0 and game.dodge_fx == 0.0, "crossing into combat consumes the exploration gesture without accidental attack or dodge")
	if game.enemies.is_empty():
		quit(1)
		return
	game.hero = game.enemies[0]["pos"] - Vector2(58, 0)
	game.facing = 1
	game.enemies[0]["hp"] = 1
	game.strike()
	test(game.scraps == 2, "scavenger captain earns additional salvage from a defeated alien")
	game.finish_expedition(true)
	test(game.mode == GAME.Mode.GALAXY and game.last_expedition_route == "Amber quarry" and game.galaxy.cargo == 2, "quarry route and combat salvage persist on return")
	game.queue_free()
	await process_frame
	print("SF GALAXY: %d checks / %d failures" % [checks, errors])
	quit(1 if errors else 0)

func test(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(message)
	print("PASS " if ok else "FAIL ", message)
