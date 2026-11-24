extends SceneTree

const MVP = preload("res://scripts/mobile_mvp.gd")
const Shop = preload("res://scripts/mobile_shop.gd")
const Combat = preload("res://scripts/mobile_combat.gd")
const Art = preload("res://scripts/mobile_shop_art.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS " if ok else "FAIL ", message)

func touch(view: Viewport, game: MVP, at: Vector2, down: bool) -> void:
	var input := InputEventScreenTouch.new()
	input.index = 2
	input.position = game.origin + at * game.scale_factor
	input.pressed = down
	view.push_input(input, true)

func drag(view: Viewport, game: MVP, at: Vector2) -> void:
	var input := InputEventScreenDrag.new()
	input.index = 2
	input.position = game.origin + at * game.scale_factor
	view.push_input(input, true)

func tap(view: Viewport, game: MVP, at: Vector2) -> void:
	touch(view, game, at, true)
	touch(view, game, at, false)

func tick(game: MVP, seconds: float) -> void:
	for i in range(roundi(seconds * 60.0)):
		game._physics_process(1.0 / 60.0)

func wait_for_phase(game: MVP, expected: MVP.Phase) -> void:
	for i in range(60):
		if game.phase == expected:
			return
		if game.phase == MVP.Phase.UPGRADE:
			game.pick_day_card(game.options[0])
		tick(game, 1.0)

func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(320, 560)
	root.add_child(view)
	var game: MVP = load("res://mobile.tscn").instantiate()
	view.add_child(game)
	game.set_physics_process(false)
	game.combat.set_sound_enabled(false)
	game.random.seed = 9344
	game.day_draw = game.shuffled(game.day_deck)
	check(game.phase == MVP.Phase.INTRO and game.scale_factor < 1.0, "the mobile scene opens at 320 by 560")
	var player := game.combat.player
	touch(view, game, Vector2(179, 520), true)
	drag(view, game, Vector2(179, 470))
	tick(game, 0.25)
	touch(view, game, Vector2(179, 470), false)
	check(game.phase == MVP.Phase.HUNT and game.combat.player.y < player.y
		and game.combat.direction.is_zero_approx(), "one drag starts the run and moves; release stops movement")
	wait_for_phase(game, MVP.Phase.UPGRADE)
	check(game.phase == MVP.Phase.UPGRADE and game.combat.hits >= 3 and game.combat.defeated >= 1
		and game.combat.cargo.size() >= 3, "the first real kill collects ingredients and opens a combat hand")
	var clock: float = game.combat.time
	tick(game, 1.0)
	check(is_equal_approx(clock, game.combat.time), "choosing a card holds combat and its timer")
	var index := game.options.find(Combat.WIDE)
	if index < 0:
		index = 0
	var first := game.options[index]
	tap(view, game, game.card_rect(index, game.options.size(), 288).get_center())
	check(game.phase == MVP.Phase.HUNT and first in game.equipped
		and (first != Combat.WIDE or game.combat.cut_reach() == 133.0), "touch equips a combat card that changes the same saw")
	wait_for_phase(game, MVP.Phase.SHOP)
	check(game.phase == MVP.Phase.SHOP and game.shop.raw[0] > 0 and game.shop.raw[1] > 0
		and game.shop.customers.size() == 3, "two real day ingredients enter the graphical night shop")
	var saved := game.shop.raw.duplicate()
	var mixer := Art.STATIONS[0].get_center()
	var cashier := Art.STATIONS[2].get_center()
	var mix_card := game.card_rect(1, game.shop.hands.size(), 491).get_center()
	check(game.opening_card() == Shop.JUICE, "the opening gesture starts at a playable mixer card")
	tap(view, game, mixer)
	check(game.selected == Shop.JUICE and not game.shop.opened and game.shop.energy == 2,
		"tapping the guided mixer first selects its card without starting the clock")
	touch(view, game, mix_card, true)
	drag(view, game, cashier)
	touch(view, game, cashier, false)
	check(game.selected == Shop.MIX and game.shop.raw == saved and game.shop.energy == 2 and not game.shop.opened,
		"dropping on the wrong station keeps the card selected and spends nothing")
	touch(view, game, mix_card, true)
	drag(view, game, Vector2(135, 450))
	touch(view, game, Vector2(135, 450), false)
	check(game.selected == Shop.MIX and game.shop.time == 0.0,
		"a short drop can be finished by tapping the mixer alone")
	tap(view, game, mixer)
	check(game.shop.opened and game.shop.energy == 1 and Shop.MIX not in game.shop.hands
		and game.shop.raw == [saved[0] - 1, saved[1] - 1] and game.opening_card() < 0,
		"the mixer completes one card and the opening guide ends")
	tick(game, 3.0)
	check(game.shop.premiums == 1 and game.shop.cash >= 8
		and game.shop.next_customer > 3, "mixer, shelf and physical customers complete a premium sale")
	tick(game, 10.0)
	check(game.shop.shift == 1 and game.shop.energy == 2 and game.shop.hands.size() == 3,
		"next hand restores energy and cycles the draw and discard piles")
	# If the helper was not redrawn, swap the hands just for the drag fixture.
	if Shop.HELP not in game.shop.hands:
		game.shop.hands[0] = Shop.HELP
	var helper := game.card_rect(game.shop.hands.find(Shop.HELP), game.shop.hands.size(), 491).get_center()
	touch(view, game, helper, true)
	drag(view, game, Art.STATIONS[2].get_center())
	touch(view, game, Art.STATIONS[2].get_center(), false)
	check(game.shop.helper and game.shop.energy == 0, "a drag reaches the cashier and hires the visible helper")
	wait_for_phase(game, MVP.Phase.REWARD)
	check(game.phase == MVP.Phase.REWARD and game.total_cash > 0, "closing pays the run once and offers a deck reward")
	tap(view, game, game.card_rect(1, game.options.size(), 288).get_center())
	check(game.phase == MVP.Phase.HUNT and game.day_number == 2 and Shop.EXTRA in game.night_deck
		and Shop.EXTRA not in game.day_deck, "night reward alters only the night deck")
	wait_for_phase(game, MVP.Phase.SHOP)
	check(game.shop.hands[0] == Shop.EXTRA, "the earned recipe is present in the second night hand")
	if game.shop.can_play(Shop.EXTRA):
		tap(view, game, game.card_rect(0, game.shop.hands.size(), 491).get_center())
		tap(view, game, Art.STATIONS[0].get_center())
	else:
		var suggested := game.opening_card()
		var station := Art.STATIONS[Shop.station(suggested)].get_center()
		tap(view, game, station)
		if suggested >= 0:
			tap(view, game, station)
	wait_for_phase(game, MVP.Phase.SCORE)
	check(game.phase == MVP.Phase.SCORE and game.total_sold > 0, "the second night closes to a combined ledger")
	tap(view, game, Vector2(179, 461))
	check(game.phase == MVP.Phase.INTRO and game.total_cash == 0 and Shop.EXTRA not in game.night_deck,
		"the restart icon resets both decks")
	view.size = Vector2i(393, 852)
	game.combat.cargo.assign([0, 1])
	game.open_market()
	var second_card := game.card_rect(1, game.shop.hands.size(), 491).get_center()
	tap(view, game, second_card)
	check(game.selected == Shop.MIX and not game.shop.opened, "a tall portrait viewport accepts the first tap on a card")
	tap(view, game, mixer)
	check(game.shop.opened and game.shop.energy == 1 and game.shop.jobs == [2],
		"the second tap applies the card at 393 by 852 without any drag")
	game.combat.cargo.clear()
	game.open_market()
	game.shop.hands.assign([Shop.JUICE, Shop.MIX])
	tap(view, game, mixer)
	check(game.shop.opened and game.selected < 0 and game.shop.energy == 2,
		"without a usable card, a station opens an empty shop without spending")
	var plain := Shop.new()
	plain.setup([0, 0])
	plain.hands.assign([Shop.MIX, Shop.JUICE])
	check(not plain.play_at(Shop.MIX, 0) and not plain.opened and plain.raw == [2, 0],
		"watermelon-only stock cannot play a mix card")
	check(plain.play_at(Shop.JUICE, 0) and plain.jobs == [0, 0] and plain.mix_duration() == 0.45, "watermelon-only quick blend actually speeds both queued cups")
	for i in 1500:
		plain.tick(1.0 / 60.0)
	check(plain.sold == 2 and plain.cash == 6 and plain.premiums == 0 and plain.done,
		"the watermelon-only route produces two actual sales and settles once")
	game.combat.fruits.clear()
	game.combat.cargo.resize(150)
	game.combat.cargo.fill(0)
	game.combat.spawn_enemy(game.combat.player + Vector2(0, -45), 0)
	game.combat.facing = Vector2.UP
	check(game.combat.attack() == 1, "a full legacy bag cannot shut down the survival saw")
	game.combat.equip(Combat.SPIN)
	game.combat.equip(Combat.SPIN)
	check(game.combat.cut_dot_limit() == -1.0 and game.combat.cut_reach() == 114.0,
		"redrawing the spin card extends its range instead of wasting the choice")
	print("MOBILE MVP: %d checks, %d failures" % [checks, failures])
	quit(failures)
