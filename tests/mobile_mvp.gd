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

func play_shop_touch(view: Viewport, game: MVP, card: int) -> void:
	tap(view, game, game.card_rect(game.shop.hands.find(card), game.shop.hands.size(), 491).get_center())
	tap(view, game, Art.STATIONS[Shop.station(card)].get_center())

func observe_open_shop(view: Viewport, game: MVP, harvest: Array[int], use_cards: bool) -> Dictionary:
	game.reset_run()
	game.random.seed = 9344
	game.combat.cargo.assign(harvest)
	game.open_market()
	var first_customer := game.art.first_customer_hit_area(game.shop).get_center()
	tap(view, game, Vector2(165, 390))
	touch(view, game, Vector2(165, 390), true)
	drag(view, game, first_customer)
	touch(view, game, first_customer, false)
	check(not game.shop.opened and game.shop.time == 0.0, "a tap on the floor or drag ending on a customer does not open the shop")
	var hands := game.shop.hands.duplicate()
	var stock := game.shop.raw.duplicate()
	tap(view, game, first_customer)
	check(game.shop.opened and game.shop.energy == 2 and game.shop.hands == hands
		and game.shop.raw == stock and game.night_discard.is_empty(),
		"tapping the first customer opens the shop without paying for a card")
	var mixer: Dictionary = {}
	var full_shelf: Dictionary = {}
	var cards_used: Array[int] = []
	for i in range(34 * 60):
		if game.phase != MVP.Phase.SHOP:
			break
		tick(game, 1.0 / 60.0)
		if mixer.is_empty() and game.shop.shelf.is_empty() and game.shop.can_blend() and not game.shop.customers.is_empty():
			mixer = {"second": snappedf(game.shop.time, 0.01), "hand": game.shop.hands.duplicate(),
				"juice": game.shop.can_play(Shop.JUICE), "helper": game.shop.can_play(Shop.HELP)}
			if use_cards:
				play_shop_touch(view, game, Shop.JUICE)
				cards_used.append(Shop.JUICE)
		if full_shelf.is_empty() and game.shop.shelf.size() == 5 and not game.shop.customers.is_empty():
			full_shelf = {"second": snappedf(game.shop.time, 0.01), "hand": game.shop.hands.duplicate(),
				"juice": game.shop.can_play(Shop.JUICE), "helper": game.shop.can_play(Shop.HELP)}
			if use_cards and full_shelf.helper:
				play_shop_touch(view, game, Shop.HELP)
				cards_used.append(Shop.HELP)
	var outcome := {"cards": cards_used, "empty_shelf": mixer, "full_shelf": full_shelf,
		"closed": game.phase == MVP.Phase.REWARD, "sold": game.shop.sold, "cash": game.total_cash}
	print("NATURAL SHOP ", JSON.stringify(outcome))
	return outcome

func compare_shop_bottleneck(full_shelf: bool, hire_helper: bool) -> Dictionary:
	var shop := Shop.new()
	var ingredients: Array[int] = []
	ingredients.resize(19 if full_shelf else 24)
	ingredients.fill(0)
	shop.setup(ingredients)
	if full_shelf:
		shop.shelf.assign([0, 0, 0, 0, 0])
	shop.hands.assign([Shop.JUICE, Shop.GIFT, Shop.HELP])
	if hire_helper:
		shop.play_at(Shop.HELP, 2)
	else:
		shop.play_at(Shop.JUICE, 0)
		shop.play_at(Shop.GIFT, 1)
	check(shop.opened and shop.energy == 0, "each shop comparison spends the same two stars")
	for i in range(180):
		shop.tick(1.0 / 60.0)
	var result := {"full_shelf": full_shelf, "helper": hire_helper, "mixed": shop.mixed,
		"shelf": shop.shelf.size(), "line": shop.customers.size(), "mix_queue": shop.jobs.size(),
		"sold": shop.sold, "cash": shop.cash}
	for i in range(31 * 60):
		if shop.done:
			break
		shop.tick(1.0 / 60.0)
	result.merge({"closed": shop.done, "final_sold": shop.sold, "final_cash": shop.cash})
	print("SHOP BOTTLENECK ", JSON.stringify(result))
	return result

func compare_reward_route(view: Viewport, game: MVP, reward_card: int, direction: Vector2) -> Vector2i:
	game.reset_run()
	game.random.seed = 9344
	game.options.assign([Combat.GUARD, Shop.EXTRA])
	game.phase = MVP.Phase.REWARD
	tap(view, game, game.card_rect(game.options.find(reward_card), game.options.size(), 288).get_center())
	var recipe := reward_card == Shop.EXTRA
	var start := game.combat.player
	var golden: Dictionary = game.combat.fruits[2]
	var golden_start: Vector2 = golden.pos
	check(game.day_number == 2 and golden.get("recipe_target", false) == recipe
		and (not recipe or golden_start == start + Combat.RECIPE_FRUIT_OFFSET),
		"only the recipe reward marks the golden fruit at the side of the day-two field")
	tick(game, 0.2)
	check((golden.home == golden_start) == recipe, "the marked fruit waits for a detour")
	# Both branches start with one ordinary ingredient and use the real saw for the next harvest.
	game.combat.cargo.append(0)
	var thumb := Vector2(180, 520)
	touch(view, game, thumb, true)
	drag(view, game, thumb + direction)
	tick(game, 0.75)
	touch(view, game, thumb + direction, false)
	var counts := Vector2i(game.combat.cargo.count(0), game.combat.cargo.count(1))
	check(game.combat.defeated > 0 and ((game.combat.player.x > start.x) == recipe)
		and (counts.y >= 3 if recipe else counts.x >= 4 and counts.y == 0),
		"the two touch routes harvest different fruits from the same starting stock")
	if not recipe:
		tap(view, game, game.card_rect(game.options.find(Combat.GUARD), game.options.size(), 288).get_center())
		var protected_hearts := game.combat.hearts
		var before_armor := game.combat.armor
		game.combat.fruits.clear()
		game.combat.immunity = 0.0
		game.combat.spawn_enemy(game.combat.player, 0)
		tick(game, 1.0 / 60.0)
		check(before_armor == 1 and game.combat.armor == 0 and game.combat.hearts == protected_hearts
			and game.combat.immunity > 0.0,
			"the alternative reward blocks an incoming contact")
	game.open_market()
	if not recipe:
		check(Shop.EXTRA not in game.shop.hands and game.shop.raw[1] == 0,
			"the guard route sends only ordinary stock to the night fixture")
		var first_card := game.opening_card()
		var target := Art.STATIONS[Shop.station(first_card)].get_center()
		tap(view, game, game.card_rect(game.shop.hands.find(first_card), game.shop.hands.size(), 491).get_center())
		tap(view, game, target)
		tick(game, 4.0)
		check(game.shop.sold > 0 and game.shop.premiums == 0, "the alternative route can sell ordinary juice")
	else:
		var card := game.card_rect(0, game.shop.hands.size(), 491).get_center()
		var mixer := Art.STATIONS[0].get_center()
		check(game.shop.hands[0] == Shop.EXTRA and game.shop.raw == [counts.x, counts.y - 1]
			and game.shop.star_fruit and game.shop.can_play(Shop.EXTRA), "one marked piece is reserved from the golden harvest")
		touch(view, game, card, true)
		drag(view, game, mixer)
		touch(view, game, mixer, false)
		check(game.shop.jobs == [3] and game.shop.raw == [counts.x - 1, counts.y - 1] and not game.shop.star_fruit
			and game.shop.energy == 0 and Shop.EXTRA in game.night_discard,
			"dragging the recipe to the mixer spends exactly the pair and two stars")
		tick(game, 3.0)
		check(game.shop.premiums == 1 and game.shop.cash >= 12, "a customer buys the actual star juice")
	return counts

func full_reward_route(view: Viewport, game: MVP, reward_card: int, detour: bool) -> Dictionary:
	game.reset_run()
	game.random.seed = 9344
	game.options.assign([Combat.GUARD, Shop.EXTRA])
	game.phase = MVP.Phase.REWARD
	tap(view, game, game.card_rect(game.options.find(reward_card), game.options.size(), 288).get_center())
	var thumb := Vector2(180, 520)
	var to := thumb + Vector2(42, -46)
	var moving_for := 0.0
	var contacts := 0
	var marked: Dictionary = game.combat.fruits[2] if reward_card == Shop.EXTRA else {}
	if detour:
		touch(view, game, thumb, true)
		drag(view, game, to)
	while game.phase in [MVP.Phase.HUNT, MVP.Phase.UPGRADE]:
		if game.phase == MVP.Phase.UPGRADE:
			var card := game.options[0]
			for preferred in [Combat.GUARD, Combat.SPIN, Combat.WIDE]:
				if preferred in game.options:
					card = preferred
					break
			tap(view, game, game.card_rect(game.options.find(card), game.options.size(), 288).get_center())
			continue
		if detour and moving_for < 0.60:
			moving_for += 1.0 / 60.0
			if moving_for >= 0.60:
				touch(view, game, to, false)
		var prior_immunity := game.combat.immunity
		tick(game, 1.0 / 60.0)
		contacts += int(game.combat.immunity > prior_immunity)
	var result := {"reward": game.card_name(reward_card), "detour": detour, "route_s": snappedf(moving_for, 0.01),
		"day_s": snappedf(game.combat.time, 0.01), "contacts": contacts, "hearts": game.combat.hearts,
		"watermelon": game.combat.cargo.count(0), "golden": game.combat.cargo.count(1),
		"marked_pick": not marked.is_empty() and marked.hp <= 0, "star_playable": game.shop.can_play(Shop.EXTRA)}
	var star_orders := 0
	for shift in range(2):
		var card := game.opening_card() if shift == 0 else -1
		if shift == 1:
			for candidate in game.shop.hands:
				if game.shop.can_play(candidate):
					card = candidate
					break
		if card >= 0:
			tap(view, game, game.card_rect(game.shop.hands.find(card), game.shop.hands.size(), 491).get_center())
			tap(view, game, Art.STATIONS[Shop.station(card)].get_center())
			star_orders += int(card == Shop.EXTRA and card not in game.shop.hands)
		elif not game.shop.opened:
			tap(view, game, Art.STATIONS[0].get_center())
		if shift == 0:
			tick(game, Shop.SHIFT + 0.1)
	wait_for_phase(game, MVP.Phase.SCORE)
	result.merge({"star_orders": star_orders, "cups_sold": game.shop.sold, "cash": game.total_cash,
		"closed": game.phase == MVP.Phase.SCORE})
	print("REWARD ROUTE ", JSON.stringify(result))
	return result

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
	tap(view, game, Vector2(82, 432))
	tick(game, 0.5)
	check(game.phase == MVP.Phase.INTRO and game.combat.time == 0.0 and game.combat.player == player,
		"a stray tap leaves the opening and battle clock idle")
	touch(view, game, Vector2(179, 520), true)
	drag(view, game, Vector2(180, 515))
	tick(game, 0.12)
	touch(view, game, Vector2(180, 515), false)
	check(game.phase == MVP.Phase.INTRO and game.combat.time == 0.0,
		"brief finger jitter outside the illustrated stick does not start the hunt")
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
	check(game.combat.preview_card == first and game.combat.preview_left == Combat.CARD_PREVIEW_SECONDS
		and is_equal_approx(clock, game.combat.time), "the first card shows its cue on the live field without advancing on tap")
	var resume_from := game.combat.player
	touch(view, game, Vector2(179, 520), true)
	drag(view, game, Vector2(225, 520))
	tick(game, 0.10)
	touch(view, game, Vector2(225, 520), false)
	check(game.combat.player.x > resume_from.x and game.combat.time > clock and game.combat.preview_left > 0.0,
		"movement and the hunt clock resume while the first-card cue is visible")
	wait_for_phase(game, MVP.Phase.SHOP)
	check(game.phase == MVP.Phase.SHOP and game.shop.raw[0] > 0 and game.shop.raw[1] > 0
		and game.shop.customers.size() == 3, "two real day ingredients enter the graphical night shop")
	var first_harvest := game.combat.cargo.duplicate()
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
	game.reset_run()
	var tap_spawn := game.combat.player
	tap(view, game, MVP.INTRO_STICK)
	check(game.phase == MVP.Phase.HUNT and game.combat.direction == Vector2.UP,
		"tapping the illustrated stick starts a short step toward fruit at 393 by 852")
	tick(game, 0.4)
	check(game.combat.player.y < tap_spawn.y and game.combat.direction.is_zero_approx(),
		"the assisted first step stops without another touch")
	game.reset_run()
	tap(view, game, MVP.INTRO_STICK)
	touch(view, game, Vector2(120, 520), true)
	drag(view, game, Vector2(65, 520))
	tick(game, 0.30)
	check(game.combat.direction == Vector2.LEFT,
		"a new drag takes over the first step without being cut off by its timer")
	touch(view, game, Vector2(65, 520), false)
	game.reset_run()
	# Compare actual cutting at the same position with each available first card.
	for card in [Combat.WIDE, Combat.SPIN]:
		game.start_hunt()
		game.combat.fruits.clear()
		game.combat.spawn_enemy(game.combat.player + Vector2(0, -120), 0)
		game.combat.spawn_enemy(game.combat.player + Vector2(0, 75), 0)
		game.combat.facing = Vector2.UP
		game.motion = 2
		game.apply_motion()
		check(game.combat.attack() == 0, "baseline front reach and rear coverage miss both identical targets")
		game.options.assign([card])
		game.phase = MVP.Phase.UPGRADE
		var offered_dot := game.combat.cut_dot_after(card)
		tap(view, game, game.card_rect(0, 1, 288).get_center())
		check(is_equal_approx(offered_dot, game.combat.cut_dot_limit())
			and (offered_dot <= Combat.FULL_CIRCLE_CUT_DOT) == (card == Combat.SPIN),
			"the first card illustration predicts the field's actual coverage")
		check(game.combat.preview_card == card and game.combat.attack() == 1
			and game.combat.fruits[0].hp == (2 if card == Combat.WIDE else 3)
			and game.combat.fruits[1].hp == (2 if card == Combat.SPIN else 3),
			"at 393 by 852 with reduced motion, the preview accompanies the card's distinct real hit")
		game.combat.fruits.clear()
		game.combat.next_spawn = 5.0
		tick(game, 1.5)
		check(game.combat.preview_left == 0.0 and game.phase == MVP.Phase.HUNT,
			"the cue expires on its own during play")
	game.motion = 0
	var ordinary_route := compare_reward_route(view, game, Combat.GUARD, Vector2(-30, -55))
	var star_route := compare_reward_route(view, game, Shop.EXTRA, Vector2(42, -46))
	check(ordinary_route.x > star_route.x and ordinary_route.y < star_route.y,
		"the seeded day-two routes change the mix of fruits")
	for reward in [Combat.GUARD, Shop.EXTRA]:
		for detour in [false, true]:
			var outcome := full_reward_route(view, game, reward, detour)
			check(outcome.closed and outcome.cups_sold > 0, "the seeded route plays through the whole shop to settlement")
			var earns_star: bool = reward == Shop.EXTRA and detour
			check(outcome.marked_pick == earns_star and outcome.star_playable == earns_star
				and outcome.star_orders == int(earns_star) and outcome.golden > 0,
				"ordinary golden stock never substitutes for the marked harvest")
	game.reset_run()
	var reserved := Shop.new()
	reserved.setup([0, 0, 0, 0, 0, 0, 1], true)
	reserved.hands.assign([Shop.JUICE, Shop.MIX, Shop.EXTRA])
	check(not reserved.can_play(Shop.MIX) and reserved.play_at(Shop.JUICE, 0),
		"normal recipes cannot use the reserved star piece as ordinary gold")
	for i in range(240):
		reserved.tick(1.0 / 60.0)
	check(reserved.raw[0] > 0 and reserved.star_fruit, "automatic mixing leaves the reserved piece alone")
	reserved.energy = 2
	check(reserved.play_at(Shop.EXTRA, 0) and not reserved.star_fruit,
		"the marked piece remains usable by the star recipe after normal sales")
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
	var blocked := Shop.new()
	blocked.setup([0, 0])
	blocked.hands.assign([Shop.JUICE])
	blocked.shelf.assign([0, 0, 0, 0, 0])
	blocked.play_at(Shop.JUICE, 0)
	blocked.tick(0.4)
	check(blocked.jobs == [0, 0] and not blocked.can_blend() and blocked.blend == 0.0,
		"the mixer holds both batches while the display shelf is full")
	blocked.tick(1.1)
	check(blocked.sold == 1 and blocked.can_blend(), "a real sale frees shelf space and releases the mixer")
	var mixer_quick := compare_shop_bottleneck(false, false)
	var mixer_helper := compare_shop_bottleneck(false, true)
	var sales_quick := compare_shop_bottleneck(true, false)
	var sales_helper := compare_shop_bottleneck(true, true)
	check(mixer_quick.mixed > mixer_helper.mixed and mixer_quick.shelf > mixer_helper.shelf,
		"an empty shelf fills faster with quick blending")
	check(sales_helper.sold > sales_quick.sold and sales_helper.line < sales_quick.line,
		"with a full shelf, the helper serves more of the queue")
	check(mixer_quick.closed and mixer_helper.closed and sales_quick.closed and sales_helper.closed
		and mixer_quick.final_cash > mixer_helper.final_cash and sales_helper.final_cash > sales_quick.final_cash,
		"with equal opening spend, the higher closing revenue depends on the starting shelf")
	view.size = Vector2i(320, 560)
	var observe := observe_open_shop(view, game, first_harvest, false)
	view.size = Vector2i(393, 852)
	var intervene := observe_open_shop(view, game, first_harvest, true)
	check(observe.closed and observe.sold > 0 and observe.empty_shelf.get("juice", false)
		and observe.empty_shelf.get("helper", false), "watching a normal opening reveals the mixer queue with both cards still usable")
	check(intervene.closed and intervene.cards == [Shop.JUICE, Shop.HELP] and intervene.cash > observe.cash
		and intervene.full_shelf.get("helper", false),
		"natural mixer and sales bottlenecks expose usable cards in both shifts")
	game.reset_run()
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
