extends SceneTree

const MELON := 2
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
	game.player = game.depot
	game.cargo.assign(pieces)
	game.simulate(0.05 * pieces.size() + 0.04, Vector2.ZERO)
	key(game, KEY_ENTER)
	key(game, KEY_ENTER)

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
	var night = game.night
	var ui = game.night_view
	check(not game.enter_night(), "an active expedition cannot open the market")
	deliver(game, [0, 0, 0, 0])
	check(ui.visible and night.phase == night.Phase.MENU and night.stock.count(0) == 4, "the mint depot hands the exact safe stock to the night menu")
	check(ui.recipe_buttons[1].disabled and not game.pick_night_recipe(1), "watermelon stock alone cannot enable the special")
	check(not game.advance_night(), "the market needs a chosen menu")
	ui.recipe_buttons[0].pressed.emit()
	check(night.selected == [true, false] and game.stock == 4, "menu choice leaves stock intact")
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
	check(night.gross == 5 and night.sold == [1, 0] and game.player == home, "a finished drink earns one sale while the player stays put")
	check(game.hits == 0 and game.impact.trauma == 0.0 and Engine.time_scale == 1.0, "night work does not cut targets or stop the engine")
	key(game, KEY_Q)
	game._physics_process(2.0)
	key(game, KEY_Q)
	game._physics_process(2.0)
	ui.action_button.pressed.emit()
	check(night.phase == night.Phase.CLOSED and night.gross == 15 and night.net() == 5 and game.stock == 1,
		"watermelon-only service covers the closing fee, leaves surplus, and reaches the results screen")
	check(not night.close() and not game.pick_night_recipe(0) and night.net() == 5, "a closed night cannot charge or sell again")
	ui.action_button.pressed.emit()
	check(night.phase == night.Phase.OFF and not ui.visible and game.stock == 0 and game.day.charge == 100.0,
		"the completed prototype can start a new independent day")

	deliver(game, [0, 0, MELON])
	key(game, KEY_Q)
	key(game, KEY_W)
	key(game, KEY_ENTER)
	key(game, KEY_W)
	check(night.active_recipe == 1 and night.stock.count(0) == 1 and night.stock.count(MELON) == 0, "the special spends one watermelon and one melon")
	game._physics_process(2.0)
	check(night.gross == 12 and night.sold == [0, 1] and not night.can_serve(1), "the melon premium pays once and needs fresh ingredients for another order")
	ui.recipe_buttons[0].pressed.emit()
	game._physics_process(2.0)
	game.advance_night()
	check(night.phase == night.Phase.CLOSED and night.net() == 7 and night.sold == [1, 1] and game.stock == 0,
		"the mixed menu completes the melon route and charges the fee once")

	game.reset_run()
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
		deliver(layout_game, [0, MELON])
		await process_frame
		await process_frame
		var pane = layout_game.night_view
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		check(bounds.encloses(pane.action_button.get_global_rect()) and bounds.encloses(pane.pause_button.get_global_rect())
			and not pane.action_button.get_global_rect().intersects(pane.pause_button.get_global_rect()),
			"night actions remain in-bounds at %s" % size)
		view.queue_free()
		await process_frame

	print("NIGHT MARKET: %d checks, %d failures" % [checks, failures])
	quit(failures)
