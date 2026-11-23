extends SceneTree

const Day = preload("res://scripts/day_harvest.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
const Orange = preload("res://scripts/rolling_orange.gd")
const Market = preload("res://scripts/night_market.gd")
const MELON := SpineMelon.KIND
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", message)

func key(game, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._input(event)

func deliver(game, pieces: Array[int]) -> void:
	key(game, KEY_ENTER)
	game.player = game.depot
	game.cargo.assign(pieces)
	game.simulate(0.05 * pieces.size() + 0.04, Vector2.ZERO)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)

func walk_to(game, target: Vector2) -> void:
	var offset: Vector2 = target - game.player
	game.simulate(offset.length() / game.SPEED, offset.normalized())

func late_melon_approach(game) -> void:
	walk_to(game, Vector2(510, 690))
	walk_to(game, Vector2(390, 1004))
	walk_to(game, SpineMelon.HOME + Vector2(0, 138))
	game.simulate(2.02, Vector2.ZERO)
	walk_to(game, SpineMelon.HOME + Vector2(0, 65))
	game.simulate(0.30, Vector2.ZERO)

func check_preparation(game) -> void:
	var ui = game.night_view
	check(game.preparing_day and ui.prep_content.is_visible_in_tree()
		and not ui.market_content.is_visible_in_tree() and game.day.card == Day.Card.STANDARD,
		"the shipped scene starts at tonight's forecast with the standard kit selected")
	game.simulate(1.0, Vector2.LEFT)
	check(game.player == Vector2(700, 720) and game.hits == 0 and not game.finish_day_at_depot(),
		"preparation blocks movement, cuts and return")
	ui.prep_pause_button.pressed.emit()
	key(game, KEY_W)
	key(game, KEY_ENTER)
	check(game.preparing_day and game.day.card == Day.Card.STANDARD and ui.start_button.disabled,
		"pause blocks loadout and harvest entry")
	ui.prep_pause_button.pressed.emit()
	ui.loadout_buttons[Day.Card.WEDGE].pressed.emit()
	check(game.day.card == Day.Card.WEDGE, "the screen button selects Cutting Wedge")
	key(game, KEY_Q)
	check(game.day.card == Day.Card.STANDARD, "Q restores the standard kit before departure")
	key(game, KEY_ENTER)
	key(game, KEY_W)
	check(not ui.visible and game.day.card == Day.Card.STANDARD,
		"starting the orchard locks the selected kit")
	late_melon_approach(game)
	check(game.seed_hits == 0 and not game.cargo.has(MELON),
		"the normal opening closes before the delayed approach can harvest")
	game.reset_run()
	key(game, KEY_W)
	ui.start_button.pressed.emit()
	walk_to(game, Vector2(510, 690))
	check(game.hits > 0 and game.day.charge == Day.MAX_CHARGE - game.hits * Day.WEDGE_CUT_COST,
		"the selected wedge spends an extra quarter charge per real cut")
	game.reset_run()
	key(game, KEY_W)
	key(game, KEY_ENTER)
	late_melon_approach(game)
	var encounter: SpineMelon = game.fruits[-1].encounter
	check(encounter.first_open_bonus == 0.0 and game.seed_hits == 0 and game.cargo.count(MELON) == 3,
		"the same late route harvests all three melon slices with the wedge")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	game._physics_process(2.0)
	check(game.night.sold[1] == 1 and game.night.gross == 12,
		"the wedge route sells tonight's special with harvested ingredients")
	game.reset_run()

func check_reward_continuation(game) -> void:
	var ui = game.night_view
	var night = game.night
	check(ui.reward_content.is_visible_in_tree() and ui.action_button.disabled and not game.advance_night(),
		"Day 1 close requires one reward selection before advancing")
	game.set_paused(true)
	ui.reward_buttons[0].pressed.emit()
	check(game.earned_card == Day.Card.NONE and ui.reward_buttons[0].disabled, "pause blocks the closing choice")
	game.set_paused(false)
	key(game, KEY_W)
	check(game.earned_card == Day.Card.SEED_GUARD, "W selects Seed Guard at close")
	ui.reward_buttons[0].pressed.emit()
	check(game.earned_card == Day.Card.RESERVE_CELL and night.net() == 5,
		"changing the closing choice replaces the card and keeps the settled ledger")
	ui.action_button.pressed.emit()
	check(game.run_day == 2 and night.phase == night.Phase.OFF and game.stock == 0 and game.day.charge == Day.MAX_CHARGE
		and ui.prep_title.text == "Day 2 Preparation" and ui.deck_buttons[0].visible and game.day.card == Day.Card.RESERVE_CELL,
		"the same run opens Day 2 with the chosen reward and fresh daily state")
	key(game, KEY_Q)
	check(game.day.card == Day.Card.STANDARD, "Day 2 can still choose the standard kit")
	key(game, KEY_C)
	check(game.day.card == Day.Card.RESERVE_CELL, "C equips the carried reward")
	key(game, KEY_ENTER)
	walk_to(game, game.depot)
	check(not game.day.reward_used, "visiting the depot with an empty bag does not spend Reserve Cell")
	walk_to(game, Vector2(510, 690))
	game.simulate(0.45, Vector2.ZERO)
	walk_to(game, game.depot + Vector2(0, 90))
	var charge_before: float = game.day.charge
	check(game.cargo.has(0) and charge_before < Day.MAX_CHARGE, "Day 2 harvest fills the bag and spends charge")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	check(game.stock > 0 and game.day.reward_used and is_equal_approx(game.day.charge, minf(charge_before + Day.RESERVE_CHARGE, Day.MAX_CHARGE)),
		"the first real unload uses Reserve Cell once without exceeding 100 charge")
	game.day.charge = 60.0
	game.cargo.append(0)
	game.simulate(0.1, Vector2.ZERO)
	check(game.day.charge == 60.0, "later deposits do not recharge again")
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	key(game, KEY_Q)
	key(game, KEY_ENTER)
	key(game, KEY_Q)
	game._physics_process(2.0)
	key(game, KEY_ENTER)
	check(night.phase == night.Phase.CLOSED and night.gross == 5 and ui.reward_content.visible,
		"Day 2 settles and opens the second reward offer")
	check(game.run_sales == 20 and game.run_fees == 22 and not game.advance_night() and game.run_fees == 22,
		"both nightly ledgers accrue once, even when the run goes into deficit")
	key(game, KEY_Q)
	check(game.earned_card == Day.Card.TUNED_BLADE, "Day 2 offers Tuned Blade")
	key(game, KEY_W)
	key(game, KEY_ENTER)
	check(game.run_day == 3 and game.deck == [Day.Card.RESERVE_CELL, Day.Card.LIMITED_COCKTAIL]
		and ui.deck_buttons[0].visible and ui.deck_buttons[1].visible and night.demand == [4, 6, 0] and night.fee == 20,
		"Day 3 keeps both rewards and opens with a new forecast")
	key(game, KEY_C)
	check(game.day.card == Day.Card.RESERVE_CELL and night.price(1) == 12, "the first reward is still selectable without the second reward bonus")
	key(game, KEY_V)
	check(game.day.card == Day.Card.LIMITED_COCKTAIL and night.price(1) == 15 and "6 × $15" in ui.forecast_labels[1].text,
		"the second reward updates the live forecast and actual sale price")
	key(game, KEY_ENTER)
	walk_to(game, Vector2(510, 690))
	game.simulate(0.70, Vector2.ZERO)
	walk_to(game, Vector2(390, 1004))
	harvest_melon_from_south(game, SpineMelon.HOME)
	walk_to(game, Vector2(SpineMelon.HOME.x, 1004))
	walk_to(game, Vector2(SpineMelon.EAST_HOME.x, 1004))
	harvest_melon_from_south(game, SpineMelon.EAST_HOME)
	check(game.cargo.count(MELON) == 6 and game.seed_hits == 0, "the two Day 3 orchard routes yield all six specials without taking a seed hit")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	for i in range(6):
		key(game, KEY_W)
		game._physics_process(3.0)
	check(night.sold == [0, 6, 0] and night.gross == 90 and not game.pick_night_recipe(1),
		"the final night sells six premium specials against the displayed order limit")
	key(game, KEY_ENTER)
	check(night.phase == night.Phase.CLOSED and not ui.reward_content.visible and ui.title.text == "Run Complete"
		and game.run_sales == 110 and game.run_fees == 42 and ui.detail.text == "Three-day net  $68",
		"the final screen settles three nights with the exact cumulative net")
	key(game, KEY_ENTER)
	check(game.run_day == 1 and game.earned_card == Day.Card.NONE and game.deck.is_empty()
		and game.run_sales == 0 and game.run_fees == 0 and not ui.deck_buttons[0].visible and not game.day.reward_used,
		"replaying clears the entire run ledger and deck")

func harvest_melon_from_south(game, center: Vector2) -> void:
	walk_to(game, center + Vector2(0, 138))
	game.simulate(0.74, Vector2.ZERO)
	walk_to(game, center + Vector2(0, 65))
	game.simulate(0.35, Vector2.ZERO)

func check_watermelon_run(game) -> void:
	for date in range(1, 4):
		var night = game.night
		var expected_orders: int = [5, 7, 4][date - 1]
		check(night.demand[0] == expected_orders, "Day %d has its own watermelon order count" % date)
		var pieces: Array[int] = []
		pieces.resize(8)
		pieces.fill(0)
		if date == 3:
			key(game, KEY_ENTER)
			walk_to(game, Vector2(510, 690))
			check(game.day.card == Day.Card.TUNED_BLADE and game.hits > 0
				and game.day.charge == Day.MAX_CHARGE - game.hits * Day.TUNED_CUT_COST,
				"Tuned Blade saves charge on each real Day 3 cut")
		deliver(game, pieces)
		key(game, KEY_Q)
		key(game, KEY_ENTER)
		for i in range(expected_orders):
			key(game, KEY_Q)
			game._physics_process(2.0)
		check(night.sold == [expected_orders, 0, 0] and not game.pick_night_recipe(0),
			"Day %d enforces its watermelon order limit" % date)
		key(game, KEY_ENTER)
		if date < 3:
			key(game, KEY_Q)
			key(game, KEY_ENTER)
	check(game.run_sales == 80 and game.run_fees == 42 and game.night_view.detail.text == "Three-day net  $38",
		"watermelon alone reaches the final screen with positive cumulative profit")
	game.reset_run()

func check_seed_guard(game) -> void:
	deliver(game, [])
	key(game, KEY_ENTER)
	game.pick_reward_card(Day.Card.WEDGE)
	check(game.earned_card == Day.Card.NONE, "the closing offer rejects starter equipment")
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_Q)
	game.night_view.deck_buttons[0].pressed.emit()
	key(game, KEY_ENTER)
	var melon: Dictionary = game.fruits.filter(func(f): return f.kind == MELON)[0]
	var encounter: SpineMelon = melon.encounter
	game.player = SpineMelon.HOME + Vector2(0, 110)
	game.simulate(0.75, Vector2.ZERO)
	check(game.seed_hits == 1 and game.day.reward_used and game.day.last_seed_cost == Day.GUARDED_SEED_COST
		and is_equal_approx(game.day.charge, Day.MAX_CHARGE - Day.GUARDED_SEED_COST - 0.75 * Day.HAZARD_COST_PER_SECOND),
		"Seed Guard reduces only the first real seed strike and keeps hazard drain")
	game.simulate(2.85, Vector2.ZERO)
	check(game.seed_hits == 2 and game.day.last_seed_cost == Day.SEED_COST
		and is_equal_approx(game.day.charge, Day.MAX_CHARGE - Day.GUARDED_SEED_COST - Day.SEED_COST - 3.60 * Day.HAZARD_COST_PER_SECOND),
		"the next seed strike charges the original cost")
	check(encounter.first_open_bonus == 0.0, "the chosen reward does not stack with the wedge")
	game.reset_run()

func open_orange_day(game) -> void:
	game.reset_run()
	deliver(game, [])
	key(game, KEY_ENTER)
	key(game, KEY_Q)
	key(game, KEY_ENTER)

func check_rolling_orange(game) -> void:
	check(not game.night.offers(Market.Recipe.ORANGE) and game.fruits.all(func(f): return f.kind != Orange.KIND),
		"Day 1 forecast and orchard omit the optional orange encounter")
	var harvest_times: Array[float] = []
	for intercept in [false, true]:
		open_orange_day(game)
		check(game.night_view.forecast_labels[2].visible and "3 × $9" in game.night_view.forecast_labels[2].text,
			"Day 2 forecasts the orange fizz before departure")
		key(game, KEY_ENTER)
		var fruit: Dictionary = game.fruits.filter(func(f): return f.kind == Orange.KIND)[0]
		var orange: Orange = fruit.encounter
		walk_to(game, Orange.HOME + Vector2(0, -154))
		check(orange.phase == Orange.Phase.IDLE and orange.position == Orange.HOME, "outside the trigger the orange waits")
		walk_to(game, Orange.HOME + Vector2(0, -70))
		check(orange.phase == Orange.Phase.ROLLING and fruit.hp == 3 and game.hits == 0 and game.day.charge == 100.0,
			"approach starts the roll, and chase contact spends no charge before braking")
		var start: float = game.time
		if intercept:
			walk_to(game, Orange.BRAKE_POINT + Vector2(-55, -55))
		else:
			walk_to(game, Orange.TURN)
			walk_to(game, Orange.BRAKE_POINT + Vector2(-55, 0))
		game.simulate(0.34, Vector2.ZERO)
		harvest_times.append(game.time - start)
		check(fruit.hp == 0 and game.cargo.count(Orange.KIND) == 3 and game.hits == 3 and game.day.charge == 97.0,
			"%s at the bend yields exactly three slices through the regular saw" % ("Intercepting" if intercept else "Following the trail"))
		if not intercept:
			continue
		walk_to(game, Vector2(510, 690))
		game.simulate(0.70, Vector2.ZERO)
		walk_to(game, game.depot)
		game.simulate(6.0, Vector2.ZERO)
		check(fruit.hp == 0 and game.production.raw.count(Orange.KIND) == 3, "the orange does not respawn and all slices land at the depot")
		key(game, KEY_ENTER)
		key(game, KEY_ENTER)
		check(game.night_view.recipe_cards[2].visible and not game.night_view.recipe_buttons[2].disabled,
			"the Day 2 menu accepts the harvested orange and watermelon stock")
		key(game, KEY_T)
		key(game, KEY_ENTER)
		for i in range(3):
			key(game, KEY_T)
			game._physics_process(2.0)
		check(game.night.gross == 27 and game.night.sold[2] == 3 and game.night.stock.count(Orange.KIND) == 0
			and not game.pick_night_recipe(Market.Recipe.ORANGE), "three orange drinks consume exactly three slices and earn $27")
		key(game, KEY_ENTER)
		check(game.night.net() == 15 and "3 fizz" in game.night_view.ledger.text, "Day 2 closing counts orange drinks and their sales")
		key(game, KEY_W)
		key(game, KEY_ENTER)
		check(game.run_day == 3 and not game.night.offers(Market.Recipe.ORANGE) and game.fruits.all(func(f): return f.kind != Orange.KIND),
			"Day 3 restores the two-melon route with no carry-over orange order")
	check(harvest_times[0] > harvest_times[1] + 0.30, "intercepting cuts more than 0.3 seconds from the same chase")

	open_orange_day(game)
	key(game, KEY_ENTER)
	var retry: Orange = game.fruits[-1].encounter
	walk_to(game, Orange.HOME + Vector2(0, -70))
	var rolling_at := retry.position
	game.set_paused(true)
	game._physics_process(3.5)
	check(retry.position == rolling_at and retry.phase == Orange.Phase.ROLLING, "pause freezes the active route")
	game.set_paused(false)
	walk_to(game, Vector2(720, 780))
	game.simulate(3.2, Vector2.ZERO)
	check(retry.phase == Orange.Phase.IDLE and retry.position == Orange.HOME, "a missed brake loops back for another attempt")
	game.reset_run()

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_sound_enabled(false)
	check(is_instance_valid(game.get("night_view")), "the shipped scene contains the night market")
	if failures:
		print("NIGHT MARKET: %d checks, %d failures" % [checks, failures])
		quit(failures)
		return
	check_preparation(game)
	check_seed_guard(game)
	check_watermelon_run(game)
	check_rolling_orange(game)
	var night = game.night
	var ui = game.night_view
	check(not game.enter_night(), "an active expedition cannot open the market")
	deliver(game, [0, 0, 0, 0])
	check(ui.visible and night.phase == night.Phase.MENU and night.stock.count(0) == 4, "the mint depot hands the exact safe stock to the night menu")
	check(ui.recipe_buttons[1].disabled and not game.pick_night_recipe(1), "watermelon stock alone cannot enable the special")
	check(not game.advance_night(), "the market needs a chosen menu")
	ui.recipe_buttons[0].pressed.emit()
	check(night.selected == [true, false, false] and game.stock == 4, "menu choice leaves stock intact")
	key(game, KEY_ENTER)
	check(night.phase == night.Phase.SERVICE, "Enter opens the selected menu")
	var home: Vector2 = game.player
	key(game, KEY_Q)
	check(night.active_recipe == 0 and game.stock == 3 and night.gross == 0, "one service reserves one watermelon before earning sales")
	check(not game.pick_night_recipe(0) and not game.advance_night(), "in-flight work prevents duplicate reservations or close")
	game.set_paused(true)
	game._physics_process(20.0)
	check(night.active_recipe == 0 and night.gross == 0 and ui.pause_button.text == "RESUME", "night work waits through a pause")
	ui.pause_button.pressed.emit()
	game._physics_process(2.0)
	check(night.gross == 5 and night.sold == [1, 0, 0] and game.player == home, "a finished drink earns one sale while the player stays put")
	check(game.hits == 0 and game.impact.trauma == 0.0 and Engine.time_scale == 1.0, "night work does not cut targets or stop the engine")
	key(game, KEY_Q)
	game._physics_process(2.0)
	key(game, KEY_Q)
	game._physics_process(2.0)
	ui.action_button.pressed.emit()
	check(night.phase == night.Phase.CLOSED and night.gross == 15 and night.net() == 5 and game.stock == 1,
		"watermelon-only service covers the closing fee, leaves surplus, and reaches the results screen")
	check(not night.close() and not game.pick_night_recipe(0) and night.net() == 5, "a closed night cannot charge or sell again")
	check_reward_continuation(game)
	deliver(game, [0, 0, MELON])
	key(game, KEY_Q)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	check(night.active_recipe == 1 and night.stock.count(0) == 1 and night.stock.count(MELON) == 0, "the special spends one watermelon and one melon")
	game._physics_process(2.0)
	check(night.gross == 12 and night.sold == [0, 1, 0] and not night.can_serve(1), "the melon premium pays once and needs fresh ingredients for another order")
	ui.recipe_buttons[0].pressed.emit()
	game._physics_process(2.0)
	game.advance_night()
	check(night.phase == night.Phase.CLOSED and night.net() == 7 and night.sold == [1, 1, 0] and game.stock == 0,
		"the mixed menu completes the melon route and charges the fee once")

	game.reset_run()
	game.begin_harvest()
	game.production.deposit(0)
	game.production.deposit(MELON)
	game.day.charge = 0.02
	game.player = Vector2(210, 941)
	game.facing = Vector2.DOWN
	game.simulate(0.1, Vector2.ZERO)
	check(game.day.outcome == game.day.Outcome.EXHAUSTED and game.enter_night() and night.stock.size() == 2,
		"forced return can enter the same night with the previously secured stock")

	game.reset_run()
	deliver(game, [])
	check(not night.has_available_menu() and game.advance_night() and night.net() == -10,
		"an empty harvest can close immediately and records the shortfall")

	game.reset_run()
	deliver(game, [0, 0, 0, 0, 0, 0])
	key(game, KEY_Q)
	key(game, KEY_Q)
	check(not game.advance_night(), "deselecting the only menu disables opening again")
	key(game, KEY_Q)
	key(game, KEY_ENTER)
	for i in range(5):
		key(game, KEY_Q)
		game._physics_process(2.0)
	check(night.gross == 25 and game.stock == 1 and not game.pick_night_recipe(0), "demand limits sales even when another portion is in stock")

	for size in [Vector2i(320, 560), Vector2i(512, 1108), Vector2i(960, 720)]:
		var view := SubViewport.new()
		view.size = size
		root.add_child(view)
		var layout_game = load("res://main.tscn").instantiate()
		view.add_child(layout_game)
		layout_game.set_physics_process(false)
		await process_frame
		await process_frame
		var pane = layout_game.night_view
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var prep_fits: bool = bounds.encloses(pane.prep_content.get_global_rect())
		for button in pane.loadout_buttons + [pane.start_button, pane.prep_pause_button]:
			prep_fits = prep_fits and bounds.encloses(button.get_global_rect())
		check(prep_fits, "forecast and loadout actions fit at %s" % size)
		deliver(layout_game, [0, MELON])
		await process_frame
		await process_frame
		check(bounds.encloses(pane.action_button.get_global_rect()) and bounds.encloses(pane.pause_button.get_global_rect())
			and not pane.action_button.get_global_rect().intersects(pane.pause_button.get_global_rect()),
			"night actions remain in-bounds at %s" % size)
		key(layout_game, KEY_Q)
		key(layout_game, KEY_ENTER)
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		var rewards_fit: bool = bounds.encloses(pane.reward_content.get_global_rect()) and bounds.encloses(pane.action_button.get_global_rect())
		check(rewards_fit, "closing rewards and continue action fit at %s" % size)
		key(layout_game, KEY_Q)
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		check(bounds.encloses(pane.prep_content.get_global_rect()) and bounds.encloses(pane.deck_buttons[0].get_global_rect()),
			"Day 2 preparation and the earned card fit at %s" % size)
		deliver(layout_game, [0, MELON, Orange.KIND])
		await process_frame
		await process_frame
		check(bounds.encloses(pane.recipe_cards[2].get_global_rect()) and bounds.encloses(pane.pause_button.get_global_rect()),
			"Day 2 market fits three recipes and pause at %s" % size)
		key(layout_game, KEY_T)
		key(layout_game, KEY_ENTER)
		key(layout_game, KEY_ENTER)
		key(layout_game, KEY_W)
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		check(bounds.encloses(pane.prep_content.get_global_rect()) and bounds.encloses(pane.deck_buttons[1].get_global_rect())
			and bounds.encloses(pane.start_button.get_global_rect()), "Day 3 preparation and both earned cards fit at %s" % size)
		deliver(layout_game, [])
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		check(bounds.encloses(pane.ledger.get_global_rect()) and bounds.encloses(pane.action_button.get_global_rect()),
			"final ledger and new-run button fit at %s" % size)
		view.queue_free()
		await process_frame

	print("NIGHT MARKET: %d checks, %d failures" % [checks, failures])
	quit(failures)
