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

func click_at(view: Viewport, at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	view.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		view.push_input(event, true)

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
	game.update_day_hud()
	check(game.status.text.begins_with("Need: 8 watermelon · 3 melon"),
		"Day 1 counts one shared watermelon per regular and special order")
	late_melon_approach(game)
	game.update_day_hud()
	var encounter: SpineMelon = game.fruits[-1].encounter
	check(encounter.first_open_bonus == 0.0 and game.seed_hits == 0 and game.cargo.count(MELON) == 3,
		"the same late route harvests all three melon slices with the wedge")
	check(game.status.text.begins_with("Need: 8 watermelon · 3 melon"),
		"watermelon and melon in the bag do not reduce the safe-stock forecast")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	game.update_day_hud()
	var remaining_watermelon: int = maxi(0, 8 - game.production.raw.count(0))
	var forecast: String = game.status.text.get_slice("\n", 0)
	check(forecast == ("Tonight: all orders covered" if remaining_watermelon == 0 else "Need: %d watermelon" % remaining_watermelon),
		"safely delivering the melon harvest removes it from the forecast")
	check(not game.return_button.disabled, "the player can return after delivering stock even if there are shortages")
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	game._physics_process(2.0)
	check(game.night.sold[1] == 1 and game.night.gross == 12,
		"the wedge route sells tonight's special with harvested ingredients")
	game.reset_run()

func check_harvest_target(game) -> void:
	var ui = game.night_view
	for target in [Market.Recipe.WATERMELON, Market.Recipe.MELON]:
		game.reset_run()
		check(game.harvest_target == Market.ALL_RECIPES and not ui.forecast_buttons[Market.Recipe.ORANGE].visible,
			"a fresh Day 1 tracks all orders and hides the unavailable orange order")
		game.set_paused(true)
		key(game, KEY_N)
		ui.forecast_buttons[target].pressed.emit()
		check(game.harvest_target == Market.ALL_RECIPES and ui.forecast_buttons[target].disabled,
			"pause blocks both ways to change the target")
		game.set_paused(false)
		if target == Market.Recipe.WATERMELON:
			key(game, KEY_N)
		else:
			ui.forecast_buttons[target].pressed.emit()
			ui.forecast_buttons[target].pressed.emit()
			check(game.harvest_target == Market.ALL_RECIPES, "tapping the chosen order again tracks all orders")
			ui.forecast_buttons[target].pressed.emit()
		check(game.harvest_target == target and ui.forecast_buttons[target].button_pressed,
			"preparation highlights the chosen demand")
		key(game, KEY_ENTER)
		key(game, KEY_N)
		game.update_day_hud()
		var target_name: String = "Juice" if target == Market.Recipe.WATERMELON else "Melon"
		var start_need := "5 watermelon" if target == Market.Recipe.WATERMELON else "3 watermelon · 3 melon"
		check(game.harvest_target == target and game.status.text.begins_with("%s need: %s" % [target_name, start_need]),
			"the target is locked for today's harvest and counts only that recipe's demand")
		walk_to(game, Vector2(510, 690))
		game.simulate(0.70, Vector2.ZERO)
		game.update_day_hud()
		check(game.cargo.count(0) >= 5 and game.stock == 0
			and game.status.text.begins_with("Juice · unload to cover orders" if target == Market.Recipe.WATERMELON
				else "Melon need: 3 watermelon · 3 melon"),
			"the same watermelon harvest prompts unloading only for the juice goal")
		walk_to(game, game.depot)
		game.simulate(2.0, Vector2.ZERO)
		game.update_day_hud()
		check(game.status.text.begins_with("Juice covered · end harvest" if target == Market.Recipe.WATERMELON
			else "Melon need: 3 melon") and not game.return_button.disabled,
			"safe watermelon finishes the juice goal, while the melon goal still shows a shortage and permits return")
		if target == Market.Recipe.MELON:
			walk_to(game, Vector2(820, game.depot.y))
			walk_to(game, Vector2(820, 1004))
			walk_to(game, Vector2(SpineMelon.HOME.x, 1004))
			harvest_melon_from_south(game, SpineMelon.HOME)
			game.update_day_hud()
			check(game.cargo.count(MELON) == 3 and game.status.text.begins_with("Melon · unload to cover orders"),
				"harvesting the extra three melons changes the prompt to unload")
			walk_to(game, Vector2(SpineMelon.HOME.x, 1004))
			walk_to(game, Vector2(820, 1004))
			walk_to(game, Vector2(820, game.depot.y))
			walk_to(game, game.depot)
			game.simulate(2.0, Vector2.ZERO)
		game.cargo.append(0)
		game.update_day_hud()
		check(game.status.text.begins_with(target_name + " covered · finish unloading") and game.return_button.disabled,
			"surplus cargo still needs unloading when the goal is already covered at the depot")
		game.simulate(0.1, Vector2.ZERO)
		walk_to(game, game.depot + Vector2(0, 110))
		game.update_day_hud()
		check(game.status.text.begins_with(target_name + " covered · return to depot") and game.return_button.disabled,
			"departing with a covered target points back to the depot")
		walk_to(game, game.depot)
		key(game, KEY_ENTER)
		key(game, KEY_ENTER)
		check(game.night.phase == Market.Phase.MENU and not game.night.selected.has(true),
			"the daytime goal leaves the actual market menu open for selection")
		key(game, KEY_Q if target == Market.Recipe.WATERMELON else KEY_W)
		key(game, KEY_ENTER)
		var orders: int = game.night.demand[target]
		for i in range(orders):
			key(game, KEY_Q if target == Market.Recipe.WATERMELON else KEY_W)
			game._physics_process(2.0)
		key(game, KEY_ENTER)
		check(game.night.phase == Market.Phase.CLOSED and game.night.sold[target] == orders
			and game.night.gross == orders * game.night.price(target), "the planned route sells every target order")
		key(game, KEY_Q)
		key(game, KEY_ENTER)
		check(game.run_day == 2 and game.harvest_target == Market.ALL_RECIPES,
			"Day 2 starts with a fresh target before offering orange fizz")
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
	check(game.run_sales == 20 and game.run_fees == 22 and not game.advance_night() and game.run_fees == 22
		and game.run_results.size() == 2 and game.run_results[0].sold == [3, 0, 0] and game.run_results[1].sold == [1, 0, 0],
		"both nightly ledgers accrue once and preserve past menu sales when the run goes into deficit")
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
	check(game.day.card == Day.Card.LIMITED_COCKTAIL and night.price(1) == 15 and "6 × $15" in ui.forecast_buttons[1].text,
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
	check(ui.run_breakdown.is_visible_in_tree() and not ui.inventory.visible and ui.ledger.text == "Run sales $110  ·  Run fees $42",
		"the final summary shows whole-run totals and each closed night")
	check(ui.night_headings[0].text == "Night 1  ·  Net $5" and "Juice 3/5  ·  Melon 0/3" in ui.night_breakdowns[0].text,
		"Night 1 still shows its own juice sales and uncovered melon demand")
	check(ui.night_headings[1].text == "Night 2  ·  Net -$7" and "Juice 1/7  ·  Melon 0/1  ·  Fizz 0/3" in ui.night_breakdowns[1].text,
		"Night 2 shows its deficit and includes the orange fizz orders")
	check(ui.night_headings[2].text == "Night 3  ·  Net $70" and ui.night_breakdowns[2].text.begins_with("Sales $90  ·  Fee $20\nJuice 0/4  ·  Melon 6/6\nUnfilled: 4 juice\n"),
		"Night 3 uses actual cocktail receipts and omits unavailable fizz")
	key(game, KEY_ENTER)
	check(game.run_day == 1 and game.earned_card == Day.Card.NONE and game.deck.is_empty()
		and game.run_sales == 0 and game.run_fees == 0 and game.run_results.is_empty()
		and not ui.run_breakdown.is_visible_in_tree() and not ui.deck_buttons[0].visible and not game.day.reward_used,
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
	check(game.run_results[0].leftover == [3, 0, 0] and game.run_results[1].leftover == [1, 0, 0]
		and "Unfilled: 3 melon\nLeft: 3 watermelon" in game.night_view.night_breakdowns[0].text
		and "Unfilled: 1 melon · 3 fizz\nLeft: 1 watermelon" in game.night_view.night_breakdowns[1].text,
		"the final ledger keeps each night's own leftovers and excludes fully served juice from its shortfall")
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
		check(game.night_view.forecast_buttons[2].visible and "3 × $9" in game.night_view.forecast_buttons[2].text,
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
		check(game.orchard_waypoints().all(func(marker): return marker.target != Orange.HOME),
			"the fruit arrow leaves when the orange is harvested")
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
		check(game.night_view.recipe_buttons[2].text == "ORDERS FILLED" and game.night_view.recipe_buttons[2].disabled,
			"a fulfilled recipe reports the order limit even when its ingredients ran out at the same time")
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

func check_wheel_chock(game) -> void:
	for use_chock in [false, true]:
		game.reset_run()
		deliver(game, [])
		key(game, KEY_ENTER)
		var ui = game.night_view
		check(ui.reward_buttons[2].visible and "WHEEL CHOCK" in ui.reward_buttons[2].text, "the first close offers the orange route card")
		if use_chock:
			ui.reward_buttons[2].pressed.emit()
			check(game.earned_card == Day.Card.WHEEL_CHOCK, "the touch button picks Wheel Chock")
			key(game, KEY_Q)
			key(game, KEY_T)
			check(game.earned_card == Day.Card.WHEEL_CHOCK, "T changes the first-night reward back to Wheel Chock")
		else:
			key(game, KEY_Q)
		key(game, KEY_ENTER)
		if use_chock:
			check(game.deck == [Day.Card.WHEEL_CHOCK] and game.day.card == Day.Card.WHEEL_CHOCK and not ui.deck_buttons[0].disabled,
				"Wheel Chock enters the deck and prepares the Day 2 run")
			key(game, KEY_Q)
			key(game, KEY_C)
		key(game, KEY_ENTER)
		var orange: Orange = game.fruits[-1].encounter
		walk_to(game, Orange.HOME + Vector2(0, -70))
		walk_to(game, Orange.BRAKE_POINT + Vector2(-90, -90))
		game.simulate(0.60, Vector2.ZERO)
		check(orange.phase == Orange.Phase.BRAKING and orange.brake_bonus == (Day.CHOCK_BRAKE_BONUS if use_chock else 0.0),
			"the orange takes the same route and only the selected card changes its stop")
		game.simulate(0.51, Vector2.ZERO)
		walk_to(game, Orange.BRAKE_POINT + Vector2(-42, -42))
		game.simulate(0.34, Vector2.ZERO)
		check(game.cargo.count(Orange.KIND) == (3 if use_chock else 0),
			"the same late approach %s" % ("harvests the orange with Wheel Chock" if use_chock else "misses with Reserve Cell"))
		if not use_chock:
			continue
		walk_to(game, Vector2(510, 690))
		game.simulate(0.70, Vector2.ZERO)
		walk_to(game, game.depot)
		game.simulate(2.0, Vector2.ZERO)
		key(game, KEY_ENTER)
		key(game, KEY_ENTER)
		key(game, KEY_T)
		key(game, KEY_ENTER)
		key(game, KEY_T)
		game._physics_process(2.0)
		key(game, KEY_ENTER)
		check(game.night.gross == 9 and game.night.sold[2] == 1 and "COOLER CRATE" in ui.reward_buttons[2].text,
			"the rescued harvest can sell as orange fizz and Night 2 offers the cooler")
		key(game, KEY_Q)
		key(game, KEY_ENTER)
		key(game, KEY_C)
		check(game.run_day == 3 and game.deck.has(Day.Card.WHEEL_CHOCK) and ui.deck_buttons[0].disabled
			and game.day.card == Day.Card.TUNED_BLADE, "the orange-only card stays in the deck but cannot equip on Day 3")
		deliver(game, [])
		key(game, KEY_ENTER)
		check(ui.detail.text == "Three-day net  -$33" and ui.night_headings[0].text == "Night 1  ·  Net -$10"
			and ui.night_headings[2].text == "Night 3  ·  Net -$20", "no-stock closes still produce rows and a signed run loss")
		check(ui.night_headings[1].text == "Night 2  ·  Net -$3" and "Fizz 1/3" in ui.night_breakdowns[1].text,
			"the final screen retains the real citrus sale from the prior night")
		check(game.run_results[1].leftover[2] == 2 and "2 fizz" in ui.night_breakdowns[1].text
			and "2 orange" in ui.night_breakdowns[1].text,
			"the final ledger retains two leftover oranges and two unfilled fizz orders after the day resets")
	game.reset_run()

func check_dash_kit(game) -> void:
	key(game, KEY_B)
	check(game.day.card == Day.Card.STANDARD and not game.night_view.dash_kit_button.visible,
		"the dash kit is offered only on the orange day")
	for equip_dash in [false, true]:
		open_orange_day(game)
		if equip_dash:
			game.night_view.dash_kit_button.pressed.emit()
			check(game.day.card == Day.Card.DASH_KIT and not game.try_dash(), "selecting the kit does not use the ability during prep")
			key(game, KEY_Q)
			key(game, KEY_B)
		else:
			key(game, KEY_Q)
		key(game, KEY_ENTER)
		var orange: Orange = game.fruits[-1].encounter
		walk_to(game, Orange.HOME + Vector2(0, -70))
		walk_to(game, Orange.BRAKE_POINT + Vector2(-155, -155))
		game.simulate(0.40, Vector2.ZERO)
		check(orange.phase == Orange.Phase.BRAKING and orange.brake_bonus == 0.0 and orange.brake_left > 0.50,
			"both approaches reach the same unextended brake window")
		game.simulate(orange.brake_left - 0.50, Vector2.ZERO)
		var direction := Vector2.ONE.normalized()
		var start: Vector2 = game.player
		if equip_dash:
			game.set_paused(true)
			check(game.dash_button.disabled and not game.try_dash(), "pause blocks the dash")
			game.set_paused(false)
			game.day.charge = Day.DASH_COST
			check(not game.try_dash() and not game.day.dash_used, "dash requires enough charge to leave the saw on")
			game.day.charge = Day.MAX_CHARGE
			Input.action_press("right")
			Input.action_press("down")
			key(game, KEY_SPACE)
			Input.action_release("right")
			Input.action_release("down")
			check(game.day.charge == 92.0 and game.dash_button.disabled and not game.try_dash(), "Space spends eight charge once")
			game.simulate(Day.DASH_SECONDS, Vector2.ZERO)
			check(game.player.distance_to(start + direction * game.DASH_SPEED * Day.DASH_SECONDS) < 0.01,
				"the dash travels 180 units along the selected diagonal")
			game.simulate(0.31, Vector2.ZERO)
		else:
			check(not game.dash_button.visible and not game.try_dash(), "standard kit keeps its original movement inputs")
			game.simulate(0.50, direction)
			game.simulate(0.01, Vector2.ZERO)
		check(game.cargo.count(Orange.KIND) == (3 if equip_dash else 0),
			"the same late corner %s" % ("can be intercepted with a dash" if equip_dash else "is missed when approached on foot"))
		if equip_dash:
			var after_dash: Vector2 = game.player
			game.simulate(0.1, Vector2.RIGHT)
			check(game.player.distance_to(after_dash + Vector2.RIGHT * 36.0) < 0.01, "normal speed resumes as soon as the dash ends")
			walk_to(game, Vector2(510, 690))
			game.simulate(0.70, Vector2.ZERO)
			walk_to(game, game.depot)
			game.simulate(2.0, Vector2.ZERO)
			key(game, KEY_ENTER)
			key(game, KEY_ENTER)
			key(game, KEY_T)
			key(game, KEY_ENTER)
			key(game, KEY_T)
			game._physics_process(2.0)
			check(game.night.gross == 9 and game.night.sold[2] == 1, "the dash-caught orange reaches the second night's menu")

	open_orange_day(game)
	key(game, KEY_B)
	key(game, KEY_ENTER)
	game.drag_vector = Vector2.DOWN
	var touch_start: Vector2 = game.player
	game.dash_button.pressed.emit()
	game.simulate(0.05, Vector2.ZERO)
	var pause_at: Vector2 = game.player
	game.set_paused(true)
	game.set_paused(false)
	game.simulate(0.3, Vector2.ZERO)
	check(game.day.dash_used and pause_at.distance_to(touch_start + Vector2(0, 45)) < 0.01
		and game.player == pause_at and game.dash_left == 0.0,
		"the touch button uses the drag direction and pausing cancels the remaining dash")
	game.reset_run()
	check(not game.day.dash_used and game.dash_left == 0.0 and not game.dash_button.visible, "new run clears the dash state")

func check_orchard_waypoints(game) -> void:
	check(game.orchard_waypoints().is_empty(), "route markers wait until preparation ends")
	key(game, KEY_ENTER)
	var markers: Array[Dictionary] = game.orchard_waypoints()
	check(markers.map(func(marker): return marker.target) == [game.depot, SpineMelon.HOME],
		"Day 1 marks the drop-off and west melon")
	var west: Dictionary = markers[1]
	walk_to(game, west.at)
	var direction: Vector2 = (west.target - west.at).normalized()
	walk_to(game, west.target - direction * 139.0)
	check(game.fruits[-1].encounter.phase == SpineMelon.Phase.WARNING,
		"the west arrow leads to the melon warning without entering the strike radius")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	key(game, KEY_ENTER)
	check(game.orchard_waypoints().is_empty(), "the signs retire when the expedition is over")

	open_orange_day(game)
	key(game, KEY_ENTER)
	markers = game.orchard_waypoints()
	check(markers.map(func(marker): return marker.target) == [game.depot, SpineMelon.HOME, Orange.HOME],
		"Day 2 adds the orange start to the west melon and drop-off")
	var orange: Dictionary = markers[2]
	walk_to(game, orange.at)
	direction = (orange.target - orange.at).normalized()
	walk_to(game, orange.target - direction * 124.0)
	check(game.fruits[-1].encounter.phase == Orange.Phase.ROLLING and game.orchard_waypoints()[2].target == Orange.HOME,
		"the orange arrow reaches the chase and stays pointed at the launch point")
	walk_to(game, game.depot)
	game.simulate(2.0, Vector2.ZERO)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	if game.night.has_available_menu():
		key(game, KEY_Q)
		key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	key(game, KEY_Q)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)
	markers = game.orchard_waypoints()
	check(markers.map(func(marker): return marker.target) == [game.depot, SpineMelon.HOME, SpineMelon.EAST_HOME],
		"Day 3 points east towards the second melon instead of the orange lane")
	var east: Dictionary = markers[2]
	walk_to(game, east.at)
	direction = (east.target - east.at).normalized()
	walk_to(game, east.target - direction * 139.0)
	check(game.fruits[-1].encounter.phase == SpineMelon.Phase.WARNING,
		"following the east arrow reaches the second melon")
	game.switch_mode()
	check(game.orchard_waypoints().is_empty(), "the comparison lab has no expedition markers")
	game.switch_mode()

func check_cooler_crate(game) -> void:
	var ui = game.night_view
	for use_cooler in [false, true]:
		game.reset_run()
		deliver(game, [])
		key(game, KEY_ENTER)
		key(game, KEY_T)
		check(game.earned_card == Day.Card.WHEEL_CHOCK, "T still selects the first night's orange card")
		key(game, KEY_ENTER)
		game.begin_harvest()
		walk_to(game, Vector2(510, 690))
		game.simulate(0.7, Vector2.ZERO)
		walk_to(game, game.depot)
		game.simulate(2.0, Vector2.ZERO)
		game.finish_day_at_depot()
		game.enter_night()
		key(game, KEY_Q)
		key(game, KEY_ENTER)
		key(game, KEY_Q)
		game._physics_process(2.0)
		key(game, KEY_ENTER)
		var leftovers: int = game.run_results[1].leftover[0]
		check(leftovers > Day.COOLER_CAPACITY and game.run_results[1].sold[0] == 1
			and "4/4 watermelon saved" in ui.reward_buttons[2].tooltip_text,
			"the second night offers the cooler with a capped preview based on what went unsold")
		game.set_paused(true)
		key(game, KEY_T)
		check(game.earned_card == Day.Card.NONE and ui.reward_buttons[2].disabled, "paused close blocks the cooler choice")
		game.set_paused(false)
		key(game, KEY_T)
		key(game, KEY_ENTER)
		check(game.run_day == 3 and game.day.card == Day.Card.COOLER_CRATE and game.stock == 0
			and ui.deck_buttons[1].visible and "4/4 watermelon saved" in ui.deck_buttons[1].tooltip_text,
			"the cooler's preview carries to Day 3 preparation before it grants stock")
		key(game, KEY_Q)
		if use_cooler:
			key(game, KEY_V)
		key(game, KEY_ENTER)
		var carried := Day.COOLER_CAPACITY if use_cooler else 0
		check(not game.begin_harvest() and game.stock == carried and game.cargo.is_empty()
			and game.run_results[1].leftover[0] == leftovers,
			"starting harvest banks only the equipped cooler's stock once and preserves last night's ledger")
		walk_to(game, Vector2(700, 1004))
		walk_to(game, Vector2(SpineMelon.HOME.x, 1004))
		harvest_melon_from_south(game, SpineMelon.HOME)
		check(game.cargo.count(MELON) == 3 and not game.cargo.has(0),
			"the direct melon route yields three pieces without a watermelon detour")
		walk_to(game, Vector2(SpineMelon.HOME.x, 1004))
		walk_to(game, Vector2(820, 1004))
		walk_to(game, Vector2(820, game.depot.y))
		walk_to(game, game.depot)
		game.simulate(2.0, Vector2.ZERO)
		game.finish_day_at_depot()
		game.enter_night()
		check(game.night.stock.count(0) == carried and game.night.stock.count(MELON) == 3
			and game.pick_night_recipe(Market.Recipe.MELON) == use_cooler,
			"only the stocked cooler makes the same Day 3 harvest eligible for the special")
		key(game, KEY_ENTER)
		if use_cooler:
			for i in range(3):
				key(game, KEY_W)
				game._physics_process(2.0)
			key(game, KEY_ENTER)
		check(game.night.phase == Market.Phase.CLOSED and game.night.gross == (36 if use_cooler else 0)
			and game.run_results.size() == 3 and game.run_results[1].leftover[0] == leftovers,
			"the final ledger records actual sales from the cooler route without rewriting Night 2")
		key(game, KEY_ENTER)
		check(game.stock == 0 and game.deck.is_empty() and game.carryover_watermelons() == 0,
			"starting a new run clears the cooler and its stock")

func check_menu_shortage(game) -> void:
	deliver(game, [0, 0, 0, 0, 0, MELON])
	var ui = game.night_view
	check(ui.detail.text == "Set tonight’s menu" and ui.action_button.disabled,
		"menu planning starts with selection guidance")
	ui.recipe_buttons[Market.Recipe.WATERMELON].pressed.emit()
	check(ui.detail.text == "Selected orders covered",
		"five watermelons can cover all five selected juice orders")
	key(game, KEY_W)
	check(ui.detail.text == "Menu short: 3 watermelon · 2 melon" and not ui.action_button.disabled,
		"adding the special counts the same five watermelons against eight drinks and allows partial service")
	key(game, KEY_Q)
	check(ui.detail.text == "Menu short: 2 melon" and game.stock == 6,
		"removing the juice frees its planned watermelon demand without changing stock")
	key(game, KEY_W)
	check(ui.detail.text == "Set tonight’s menu" and ui.action_button.disabled,
		"removing the final menu restores the selection guidance")
	key(game, KEY_Q)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	game._physics_process(2.0)
	key(game, KEY_Q)
	game._physics_process(2.0)
	check(game.night.sold == [1, 1, 0] and game.night.gross == 17 and game.stock == 3,
		"a projected shortage leaves both selected recipes sellable while ingredients last")
	game.reset_run()

func check_service_buttons(game) -> void:
	deliver(game, [0, 0, MELON])
	var ui = game.night_view
	var juice: Button = ui.recipe_buttons[Market.Recipe.WATERMELON]
	var special: Button = ui.recipe_buttons[Market.Recipe.MELON]
	key(game, KEY_Q)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	check(juice.text == "Q / SERVE ORDER" and special.text == "W / SERVE ORDER"
		and not juice.disabled and not special.disabled, "both selected recipes advertise their live order shortcuts")
	check(game.night.order_state(-1) == Market.OrderState.UNAVAILABLE
		and game.night.order_state(Market.Recipe.ORANGE) == Market.OrderState.UNAVAILABLE,
		"out-of-range recipes and menus without demand cannot accept an order")
	special.pressed.emit()
	check(special.text == "PREPARING…" and special.disabled and juice.text == "MIXER BUSY" and juice.disabled,
		"the active special is preparing and a second recipe with ingredients waits for the mixer")
	game.set_paused(true)
	game._physics_process(2.0)
	check(ui.detail.text == "Paused" and special.text == "PREPARING…" and game.night.sold[1] == 0,
		"pausing preserves the preparation status and sale in progress")
	game.set_paused(false)
	game._physics_process(2.0)
	check(juice.text == "Q / SERVE ORDER" and not juice.disabled
		and special.text == "NEEDS INGREDIENTS" and special.disabled,
		"when the mixer clears, juice resumes and the special reports the missing melon")
	key(game, KEY_Q)
	check(juice.text == "PREPARING…" and game.night.stock.is_empty(),
		"reserving the last watermelon keeps its active order in preparation")
	game._physics_process(2.0)
	check(juice.text == "NEEDS INGREDIENTS" and juice.disabled and game.night.gross == 17,
		"remaining juice demand reports missing ingredients when the prep finishes")
	game.reset_run()

func check_ingredient_forecast() -> void:
	var market := Market.new()
	var stock: Array[int] = [0, 0, MELON, Orange.KIND, Orange.KIND, 1]
	market.reset(2)
	check(market.missing_ingredients(stock) == {0: 9, MELON: 0, Orange.KIND: 1},
		"Day 2 counts all three recipes without counting other inventory as watermelon")
	market.reset(3)
	check(market.missing_ingredients(stock) == {0: 8, MELON: 5},
		"Day 3 wants six melon specials and omits Day 2's orange demand")
	stock.assign([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, MELON, MELON, MELON, MELON, MELON, MELON, MELON])
	var before := stock.duplicate()
	check(market.missing_ingredients(stock) == {0: 0, MELON: 0} and stock == before,
		"surplus is clamped to zero without consuming stock")

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
	check_ingredient_forecast()
	check_menu_shortage(game)
	check_service_buttons(game)
	check_preparation(game)
	check_harvest_target(game)
	check_seed_guard(game)
	check_watermelon_run(game)
	check_rolling_orange(game)
	check_wheel_chock(game)
	check_dash_kit(game)
	check_orchard_waypoints(game)
	check_cooler_crate(game)
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
	check(ui.inventory.text == "Left: 1 watermelon" and "Unfilled: 2 juice · 3 melon" in ui.ledger.text,
		"Night 1 closing shows leftover watermelon beside both unfilled demand counts")
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
	check(ui.inventory.text == "Left: none" and "Unfilled: 4 juice · 2 melon" in ui.ledger.text,
		"selling one of each Day 1 recipe shows two updated shortfalls and no leftovers")

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
	check(ui.inventory.text == "Left: none" and "Unfilled: 5 juice · 3 melon" in ui.ledger.text,
		"closing without sales still records all unfilled demand")

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
	check(ui.recipe_buttons[0].text == "ORDERS FILLED" and ui.recipe_buttons[0].disabled
		and not ui.recipe_cards[1].visible, "filled watermelon orders show their cap while the unselected special stays hidden")

	game.reset_run()
	deliver(game, [0, 0, 0, 0, 0, 0, 0, 0, MELON, MELON, MELON, MELON])
	key(game, KEY_Q)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	for recipe in [KEY_Q, KEY_W]:
		for i in range(5 if recipe == KEY_Q else 3):
			key(game, recipe)
			game._physics_process(2.0)
	key(game, KEY_ENTER)
	check(night.sold == [5, 3, 0] and "All orders served" in ui.ledger.text and ui.inventory.text == "Left: 1 melon",
		"meeting all demand can leave surplus stock on the closing screen")

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
		for button in pane.forecast_buttons.slice(0, 2) + pane.loadout_buttons + [pane.start_button, pane.prep_pause_button]:
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
		var rewards_fit: bool = bounds.encloses(pane.reward_content.get_global_rect()) and bounds.encloses(pane.action_button.get_global_rect()) and bounds.encloses(pane.reward_buttons[2].get_global_rect())
		check(rewards_fit and bounds.encloses(pane.inventory.get_global_rect()) and bounds.encloses(pane.ledger.get_global_rect())
			and not pane.ledger.get_global_rect().intersects(pane.reward_content.get_global_rect()),
			"leftovers, unfilled orders and three closing rewards fit at %s" % size)
		key(layout_game, KEY_Q)
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		check(bounds.encloses(pane.prep_content.get_global_rect()) and bounds.encloses(pane.deck_buttons[0].get_global_rect())
			and bounds.encloses(pane.dash_kit_button.get_global_rect()) and bounds.encloses(pane.prep_pause_button.get_global_rect()),
			"Day 2 prep fits the target, dash kit, earned card and pause at %s" % size)
		for i in range(3):
			key(layout_game, KEY_N)
		check(layout_game.harvest_target == Market.Recipe.ORANGE and pane.forecast_buttons[2].button_pressed
			and bounds.encloses(pane.forecast_buttons[2].get_global_rect()), "N can target the Day 2 orange order at %s" % size)
		key(layout_game, KEY_N)
		check(layout_game.harvest_target == Market.ALL_RECIPES, "N wraps to all orders at %s" % size)
		key(layout_game, KEY_B)
		key(layout_game, KEY_ENTER)
		layout_game._physics_process(0.0)
		await process_frame
		await process_frame
		check(bounds.encloses(layout_game.dash_button.get_global_rect())
			and not layout_game.dash_button.get_global_rect().intersects(layout_game.return_button.get_global_rect()),
			"the touch dash and end-harvest buttons fit at %s" % size)
		var daytime_status: Label = layout_game.status
		check(daytime_status.text.begins_with("Need: 11 watermelon · 1 melon · 3 orange")
			and daytime_status.get_global_rect().end.y <= layout_game.return_button.position.y
			and daytime_status.get_minimum_size().y <= layout_game.return_button.position.y - daytime_status.position.y,
			"the three-ingredient forecast and its instructions fit above the harvest controls at %s" % size)
		layout_game.camera.force_update_scroll()
		var safe_playfield := Rect2(0.0, layout_game.hud_height, size.x, size.y - layout_game.hud_height)
		var transform: Transform2D = layout_game.get_global_transform_with_canvas()
		var signs_fit := true
		for marker in layout_game.orchard_waypoints():
			var panel: Rect2 = layout_game.waypoint_bounds(ThemeDB.fallback_font, marker)
			signs_fit = signs_fit and safe_playfield.encloses(transform * panel)
		check(signs_fit, "all route markers are visible below the HUD at expedition spawn at %s" % size)
		deliver(layout_game, [0, MELON, Orange.KIND])
		await process_frame
		await process_frame
		check(bounds.encloses(pane.recipe_cards[2].get_global_rect()) and bounds.encloses(pane.pause_button.get_global_rect()),
			"Day 2 market fits three recipes and pause at %s" % size)
		key(layout_game, KEY_Q)
		key(layout_game, KEY_W)
		key(layout_game, KEY_T)
		await process_frame
		await process_frame
		check(pane.detail.text == "Menu short: 10 watermelon · 2 orange"
			and bounds.encloses(pane.market_content.get_global_rect()) and not pane.action_button.disabled,
			"the combined shortage and all three selected menus fit before opening at %s" % size)
		key(layout_game, KEY_ENTER)
		key(layout_game, KEY_T)
		await process_frame
		await process_frame
		var service_fits: bool = bounds.encloses(pane.pause_button.get_global_rect())
		for button in pane.recipe_buttons:
			service_fits = (service_fits and button.is_visible_in_tree() and button.disabled
				and bounds.encloses(button.get_global_rect()))
		check(service_fits and pane.recipe_buttons[1].text == "NEEDS INGREDIENTS"
			and pane.recipe_buttons[2].text == "PREPARING…",
			"three live service states fit with the preparation meter at %s" % size)
		layout_game._physics_process(2.0)
		await process_frame
		await process_frame
		check(bounds.encloses(pane.market_content.get_global_rect()) and pane.detail.text == "No orders available"
			and pane.recipe_buttons[2].text == "NEEDS INGREDIENTS" and not pane.action_button.disabled,
			"all three menu states and the close action fit when ingredients run out at %s" % size)
		key(layout_game, KEY_ENTER)
		await process_frame
		await process_frame
		key(layout_game, KEY_T)
		check(pane.reward_buttons[2].visible and pane.reward_buttons[2].disabled
			and layout_game.earned_card == Day.Card.NONE
			and "No watermelon left" in pane.reward_buttons[2].tooltip_text
			and bounds.encloses(pane.reward_content.get_global_rect()) and bounds.encloses(pane.action_button.get_global_rect()),
			"the empty cooler explains why it is unavailable and the closing controls fit at %s" % size)
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
		check(bounds.encloses(pane.ledger.get_global_rect()) and bounds.encloses(pane.run_breakdown.get_global_rect())
			and bounds.encloses(pane.action_button.get_global_rect()) and bounds.encloses(pane.pause_button.get_global_rect())
			and not pane.run_breakdown.get_global_rect().intersects(pane.action_button.get_global_rect()),
			"all three final ledger rows and both actions fit at %s" % size)
		view.queue_free()
		await process_frame

	var art_view := SubViewport.new()
	art_view.size = Vector2i(512, 1108)
	root.add_child(art_view)
	var art_game = load("res://main.tscn").instantiate()
	art_view.add_child(art_game)
	art_game.set_physics_process(false)
	art_game.sound_on = false
	await process_frame
	await process_frame
	var art_ui = art_game.night_view
	var order: Control = art_ui.forecast_buttons[Market.Recipe.WATERMELON]
	click_at(art_view, order.get_global_rect().get_center())
	check(art_game.harvest_target == Market.Recipe.WATERMELON, "clicking the forecast order chooses the harvest target")
	var wedge: Control = art_ui.loadout_buttons[Day.Card.WEDGE].artwork
	click_at(art_view, wedge.get_global_rect().get_center())
	check(art_game.day.card == Day.Card.WEDGE, "clicking the cutting wedge illustration equips its card")
	key(art_game, KEY_ENTER)
	check(art_game.orchard_counter.mouse_filter == Control.MOUSE_FILTER_IGNORE, "a distant stall leaves the orchard gesture available")
	art_game.player = art_game.depot
	art_game.cargo.assign([0])
	art_game.simulate(0.08, Vector2.ZERO)
	art_game.camera.position = art_game.camera_follow_target()
	art_game.camera.force_update_scroll()
	art_game.update_day_hud()
	var stall: TextureButton = art_game.orchard_counter
	click_at(art_view, stall.get_global_transform_with_canvas() * (stall.size * 0.5))
	check(art_game.night.phase == Market.Phase.MENU and art_game.night.stock.count(0) == 1,
		"clicking the world stall after unloading opens the market with the deposited fruit")
	await process_frame
	await process_frame
	var juice_icon: Control = art_ui.recipe_buttons[0].artwork
	click_at(art_view, juice_icon.get_global_rect().get_center())
	check(art_game.night.selected[0], "clicking the juice illustration adds it to the market menu")
	key(art_game, KEY_ENTER)
	await process_frame
	await process_frame
	click_at(art_view, juice_icon.get_global_rect().get_center())
	check(art_game.night.active_recipe == Market.Recipe.WATERMELON and art_game.night.stock.is_empty(),
		"clicking the juice illustration during service reserves its ingredients")
	art_view.queue_free()
	await process_frame

	print("NIGHT MARKET: %d checks, %d failures" % [checks, failures])
	quit(failures)
