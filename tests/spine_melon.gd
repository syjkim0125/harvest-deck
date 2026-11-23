extends SceneTree

const Game = preload("res://scripts/game.gd")
const MELON_KIND := 2
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func melon_in(game) -> Dictionary:
	for fruit in game.fruits:
		if fruit.kind == MELON_KIND:
			return fruit
	return {}

func run() -> void:
	var game = Game.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_sound_enabled(false)
	var melon := melon_in(game)
	check(not melon.is_empty(), "the default orchard contains a spined melon")
	if melon.is_empty():
		print("%d checks / %d failures" % [checks, failures])
		quit(1)
		return
	check(game.fruits.size() == 33, "special encounter adds one target alongside both existing fruit groups")
	var center: Vector2 = melon.pos
	var encounter = melon.encounter
	game.player = center + Vector2(0, 180)
	game.simulate(0.3, Vector2.ZERO)
	check(encounter.phase == encounter.Phase.IDLE, "distant players do not start the warning")
	game.simulate(0.23, Vector2.UP)
	check(encounter.phase == encounter.Phase.WARNING and melon.hp == 3, "walking in triggers a warning and closed shell blocks auto-cut")
	check(game.impact.trauma == 0.0 and game.hits == 0, "a blocked cut is not a confirmed hit")
	game.set_paused(true)
	var warning_time: float = encounter.time_left
	game.set_physics_process(true)
	await physics_frame
	await physics_frame
	game.set_physics_process(false)
	check(encounter.time_left == warning_time, "paused game holds the encounter clock")
	game.set_paused(false)
	game.simulate(0.23, Vector2.DOWN)
	game.simulate(0.46, Vector2.ZERO)
	check(encounter.phase == encounter.Phase.VULNERABLE and game.seed_hits == 0, "walking out before the burst opens the shell without a seed hit")
	check(game.impact.trauma == 0.0, "the enemy burst does not shake the camera")
	game.toggle_reduced_motion()
	game.simulate(0.25, Vector2.UP)
	game.simulate(0.5, Vector2.ZERO)
	check(melon.hp == 0 and game.cargo == [MELON_KIND, MELON_KIND, MELON_KIND], "returning with auto-cut harvests three distinct melon pieces in M mode")
	check(game.impact.trauma == 0.0 and is_equal_approx(Engine.time_scale, 1.0), "M suppresses hit shake and movement time is unchanged")
	game.simulate(5.2, Vector2.ZERO)
	check(melon.hp == 0 and game.cargo.size() == 3 and game.seed_hits == 0, "one encounter per run; the harvested melon cannot attack, respawn or reward again")
	# Walk north along the western edge before crossing to the depot. Cutting
	# through the middle rows would pick up watermelons on the comparison path.
	var corner := Vector2(center.x, game.depot.y)
	game.simulate(game.player.distance_to(corner) / game.SPEED, (corner - game.player).normalized())
	game.simulate(game.player.distance_to(game.depot) / game.SPEED, (game.depot - game.player).normalized())
	game.simulate(0.24, Vector2.ZERO)
	check(game.cargo.is_empty() and game.stock == 3, "the existing depot safely transfers all three melon pieces")
	check(game.production.raw.count(MELON_KIND) + game.production.ready.count(MELON_KIND) + int(game.production.active_kind == MELON_KIND) == 3,
		"melon retains its identity in the existing production queue")

	game.simulate(game.depot.distance_to(game.service_pad) / game.SPEED, Vector2.DOWN)
	game.simulate(3.0, Vector2.ZERO)
	check(game.production.sold_by_kind == [0, 0, 3, 0] and game.production.pending_cash == 15,
		"comparison sales count the third ingredient without changing prices")

	game.reset_run()
	melon = melon_in(game)
	encounter = melon.encounter
	check(game.seed_hits == 0 and melon.hp == 3 and encounter.phase == encounter.Phase.IDLE,
		"reset restores a fresh encounter")
	game.player = melon.pos + Vector2(0, 78)
	game.facing = Vector2.UP
	game.simulate(0.69, Vector2.ZERO)
	check(game.seed_hits == 0 and melon.hp == 3, "the warning gives the player time to move")
	game.simulate(0.05, Vector2.ZERO)
	check(game.seed_hits == 1 and encounter.phase == encounter.Phase.VULNERABLE, "standing in the ring counts one seed hit on burst")
	game.facing = Vector2.DOWN
	game.simulate(1.5, Vector2.ZERO)
	check(game.seed_hits == 1 and encounter.phase == encounter.Phase.RECOVERING, "the strike does not hit again each frame and the shell closes")
	game.facing = Vector2.UP
	check(game.attack() == 0, "closed shell blocks cuts again after the opening ends")

	print("%d checks / %d failures" % [checks, failures])
	quit(failures)
