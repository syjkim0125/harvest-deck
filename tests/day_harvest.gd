extends SceneTree

const Game = preload("res://scripts/game.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_sound_enabled(false)
	check(game.get("day_mode") == true, "the shipped scene opens the day expedition")
	if failures:
		print("DAY HARVEST: %d checks, %d failures" % [checks, failures])
		quit(failures)
		return

	var day = game.day
	var initial_charge: float = day.charge
	game.player = Vector2(950, 930)
	game.simulate(2.0, Vector2.ZERO)
	check(day.charge == initial_charge, "waiting outside the hazard costs no battery")
	game.player = Vector2(510, 690)
	game.simulate(0.3, Vector2.LEFT)
	check(game.hits > 0 and day.charge == initial_charge - game.hits * day.CUT_COST, "watermelon cuts spend exactly one charge per target")

	game.reset_run()
	var center := SpineMelon.HOME
	game.player = center + Vector2(0, SpineMelon.STRIKE_RADIUS + 8)
	game.simulate(0.74, Vector2.ZERO)
	check(game.seed_hits == 0 and day.charge == initial_charge, "standing outside a warning avoids both seed and hazard cost")
	game.reset_run()
	game.player = center + Vector2(0, 75)
	game.facing = Vector2.DOWN
	game.simulate(0.69, Vector2.ZERO)
	check(is_equal_approx(day.charge, initial_charge - 0.69 * day.HAZARD_COST_PER_SECOND), "danger radius drains charge proportionally to time")
	var before_seed: float = day.charge
	game.simulate(0.06, Vector2.ZERO)
	check(game.seed_hits == 1 and is_equal_approx(day.charge, before_seed - day.SEED_COST - 0.06 * day.HAZARD_COST_PER_SECOND), "one seed attack applies a single discrete cost")
	check(game.impact.trauma == 0.0, "incoming seed damage never adds shake")

	game.reset_run()
	game.cargo.assign([0, 2])
	game.player = game.depot
	game.simulate(1.0, Vector2.ZERO)
	check(game.cargo.is_empty() and game.production.raw == [2, 0], "depot lands safe stock by fruit type without running daytime production")
	check(game.production.ready.is_empty() and game.production.active_kind == -1 and game.production.pending_cash == 0, "day stock is available for future menu choices")
	game.cargo.assign([0, 2, 0, 2, 0])
	game.player = center + Vector2(0, 75)
	game.facing = Vector2.DOWN
	day.charge = day.SEED_COST
	game.drag_id = 7
	game.drag_vector = Vector2.RIGHT
	game.simulate(1.0, Vector2.ZERO)
	check(day.outcome == day.Outcome.EXHAUSTED and day.charge == 0.0 and game.seed_hits == 1, "the seed strike can exhaust the saw")
	check(game.player == game.depot and game.camera.offset == Vector2.ZERO and game.drag_id == -1, "exhaustion returns directly to the depot and clears input and shake")
	check(game.production.raw == [2, 0, 2, 0] and day.lost_cargo == 3 and game.cargo.is_empty(), "only carried cargo pays the rounded-up half loss; both previous deposits survive")
	var stock_after_return: int = game.stock
	game.simulate(15.0, Vector2.DOWN)
	check(game.player == game.depot and game.stock == stock_after_return and game.attack() == 0, "a long frame or further movement cannot reopen or duplicate the day")

	game.reset_run()
	game.fruits.clear()
	game.fruits.assign([
		{"pos": game.player, "kind": 0, "hp": 1},
		{"pos": game.player, "kind": 0, "hp": 1},
	])
	day.charge = day.CUT_COST
	check(game.attack() == 1 and game.fruits[1].hp == 1 and day.outcome == day.Outcome.EXHAUSTED,
		"the last funded cut cannot cut a second target on the same pulse")
	check(game.stock == 1 and day.lost_cargo == 2, "a last cut's payout goes through the same cargo loss rule")

	game.reset_run()
	game.player = center + Vector2(0, 75)
	game.facing = Vector2.DOWN
	day.charge = 0.10
	game.simulate(0.20, Vector2.ZERO)
	check(day.charge == 0.0 and day.outcome == day.Outcome.EXHAUSTED and game.seed_hits == 0,
		"hazard exposure alone can exhaust the saw before any seed hits")

	game.reset_run()
	game.cargo.assign([0, 0])
	check(not game.finish_day_at_depot(), "safe return is unavailable away from the drop zone")
	game.player = game.depot
	check(not game.finish_day_at_depot(), "safe return waits for all cargo to unload")
	game.simulate(0.10, Vector2.ZERO)
	game.set_paused(true)
	check(not game.finish_day_at_depot(), "paused day cannot accept a return input")
	game.set_paused(false)
	game.return_button.pressed.emit()
	check(day.outcome == day.Outcome.RETURNED and game.stock == 2 and day.lost_cargo == 0,
		"voluntary return keeps all unloaded cargo")
	check(not game.finish_day_at_depot(), "voluntary return is single-use")

	game.mode_button.pressed.emit()
	check(not game.day_mode and game.stock == 0 and game.production.customers.size() == 3, "the visible mode button opens a fresh comparison shop")
	game.cargo.assign([0, 0])
	game.player = game.depot
	game.simulate(3.0, Vector2.ZERO)
	game.player = game.service_pad
	game.simulate(2.0, Vector2.ZERO)
	check(game.production.pending_cash == 10 and day.charge == initial_charge, "comparison input still unloads, mixes and sells without battery costs")
	game.mode_button.pressed.emit()
	check(game.day_mode and day.charge == initial_charge and day.outcome == day.Outcome.ACTIVE, "the mode button starts a fresh day again")
	for size in [Vector2i(320, 720), Vector2i(512, 1108), Vector2i(960, 720)]:
		var view := SubViewport.new()
		view.size = size
		root.add_child(view)
		var layout_game := Game.new()
		layout_game.day_mode = true
		view.add_child(layout_game)
		layout_game.set_physics_process(false)
		layout_game._physics_process(0.0)
		await process_frame
		var buttons := [layout_game.return_button, layout_game.shake_button, layout_game.pause_button, layout_game.mode_button]
		var valid := true
		for i in range(buttons.size()):
			var rect: Rect2 = buttons[i].get_rect()
			valid = valid and Rect2(0, 0, size.x, layout_game.hud_height).encloses(rect)
			valid = valid and not rect.intersects(layout_game.hud.get_rect()) and not rect.intersects(layout_game.status.get_rect())
			for j in range(i):
				valid = valid and not rect.intersects(buttons[j].get_rect())
		check(valid, "day HUD controls fit without overlap at %s" % size)
		view.queue_free()
		await process_frame

	print("DAY HARVEST: %d checks, %d failures" % [checks, failures])
	quit(failures)
