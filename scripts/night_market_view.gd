extends Panel

const Market = preload("res://scripts/night_market.gd")
const Day = preload("res://scripts/day_harvest.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
const RollingOrange = preload("res://scripts/rolling_orange.gd")
const IllustratedAction = preload("res://scripts/illustrated_action.gd")
const Art = preload("res://scripts/market_art.gd")
const INK := Color("101e29")
const PAPER := Color("f2f5ee")
const MUTED := Color("afc6cb")
const MINT := Color("b4efd2")
const GOLD := Color("f7ce88")
const LOSS := Color("ffb4a1")
const SHORT_RECIPE_NAMES := ["Juice", "Melon", "Fizz"]
const STOCK_NAMES := ["watermelon", "melon", "orange"]
const INGREDIENT_NAMES := {0: STOCK_NAMES[0], SpineMelon.KIND: STOCK_NAMES[1], RollingOrange.KIND: STOCK_NAMES[2]}

signal recipe_pressed(recipe: int)
signal action_pressed
signal cancel_pressed
signal pause_pressed
signal reward_pressed(card: Day.Card)
signal loadout_pressed(card: Day.Card)
signal target_pressed(recipe: int)
signal start_pressed

var market_content: VBoxContainer
var prep_content: VBoxContainer
var loadout_buttons: Array[IllustratedAction] = []
var dash_kit_button: IllustratedAction
var prep_title: Label
var forecast_title: Label
var forecast_buttons: Array[Button] = []
var target_hint: Label
var route_hint: Label
var deck_buttons: Array[IllustratedAction] = []
var available_cards: Array[Day.Card] = []
var reward_title: Label
var reward_options: Array = []
var reward_content: VBoxContainer
var reward_buttons: Array[IllustratedAction] = []
var start_button: Button
var prep_pause_button: Button
var title: Label
var detail: Label
var inventory: Label
var ledger: Label
var run_breakdown: VBoxContainer
var night_headings: Array[Label] = []
var night_breakdowns: Array[Label] = []
var progress: ProgressBar
var recipes: VBoxContainer
var stall_art: TextureRect
var recipe_cards: Array[PanelContainer] = []
var recipe_buttons: Array[IllustratedAction] = []
var drink_art: Array[AtlasTexture] = []
var card_art: Array[AtlasTexture] = []
var action_button: Button
var cancel_button: Button
var pause_button: Button

func _ready() -> void:
	for i in range(Day.Card.COOLER_CRATE + 1):
		card_art.append(Art.card(i))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", surface(INK))
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := MarginContainer.new()
	center.add_child(frame)
	for side in ["top", "bottom", "left", "right"]:
		frame.add_theme_constant_override("margin_" + side, 14)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 280
	content.add_theme_constant_override("separation", 7)
	var pages := VBoxContainer.new()
	frame.add_child(pages)
	pages.add_child(content)
	market_content = content
	build_prep(pages)
	title = label(content, "Night Market", 32, PAPER)
	stall_art = TextureRect.new()
	stall_art.texture = Art.stall()
	stall_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stall_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stall_art.custom_minimum_size.y = 72
	stall_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stall_art)
	detail = label(content, "", 16, GOLD)
	inventory = label(content, "", 14, MUTED)
	recipes = VBoxContainer.new()
	recipes.add_theme_constant_override("separation", 4)
	content.add_child(recipes)
	for i in range(Market.NAMES.size()):
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		recipes.add_child(card)
		recipe_cards.append(card)
		var button := illustrated_action(card, 62.0)
		button.pressed.connect(func(): recipe_pressed.emit(i))
		recipe_buttons.append(button)
		drink_art.append(Art.drink(i))
	ledger = label(content, "", 15, PAPER)
	build_run_breakdown(content)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 7
	progress.add_theme_stylebox_override("background", surface(Color("253b46")))
	progress.add_theme_stylebox_override("fill", surface(MINT))
	content.add_child(progress)
	reward_content = VBoxContainer.new()
	content.add_child(reward_content)
	reward_title = label(reward_content, "", 16, GOLD)
	for i in range(Day.REWARD_OFFERS[0].size()):
		var button := illustrated_action(reward_content)
		button.pressed.connect(func():
			if i < reward_options.size():
				reward_pressed.emit(reward_options[i])
		)
		reward_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	content.add_child(actions)
	action_button = action(actions)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.add_theme_stylebox_override("normal", surface(Color("235246"), 6))
	action_button.add_theme_stylebox_override("hover", surface(Color("316a5b"), 6))
	action_button.pressed.connect(func(): action_pressed.emit())
	cancel_button = action(actions)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.text = "X / CANCEL QUEUE"
	cancel_button.hide()
	cancel_button.pressed.connect(func(): cancel_pressed.emit())
	pause_button = action(content)
	pause_button.pressed.connect(func(): pause_pressed.emit())

func build_run_breakdown(parent: Control) -> void:
	run_breakdown = VBoxContainer.new()
	run_breakdown.add_theme_constant_override("separation", 4)
	parent.add_child(run_breakdown)
	for i in range(Market.DAYS):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", surface(Color("1b303d"), 3))
		run_breakdown.add_child(card)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", 1)
		card.add_child(lines)
		night_headings.append(label(lines, "", 14, MINT))
		var breakdown := label(lines, "", 12, PAPER)
		breakdown.add_theme_constant_override("line_spacing", 0)
		night_breakdowns.append(breakdown)

func build_prep(parent: Control) -> void:
	prep_content = VBoxContainer.new()
	prep_content.custom_minimum_size.x = 280
	parent.add_child(prep_content)
	prep_title = label(prep_content, "", 27, PAPER)
	forecast_title = label(prep_content, "", 16, GOLD)
	for i in range(Market.NAMES.size()):
		var button := action(prep_content, 29.0, 3)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.tooltip_text = Market.INGREDIENTS[i]
		button.add_theme_stylebox_override("pressed", surface(Color("235246"), 3))
		button.pressed.connect(func(): target_pressed.emit(i))
		forecast_buttons.append(button)
	target_hint = label(prep_content, "", 13, MUTED)
	route_hint = label(prep_content, "", 13, MUTED)
	var standard := illustrated_action(prep_content)
	standard.pressed.connect(func(): loadout_pressed.emit(Day.Card.STANDARD))
	loadout_buttons.append(standard)
	var wedge := illustrated_action(prep_content)
	wedge.pressed.connect(func(): loadout_pressed.emit(Day.Card.WEDGE))
	loadout_buttons.append(wedge)
	dash_kit_button = illustrated_action(prep_content)
	dash_kit_button.pressed.connect(func(): loadout_pressed.emit(Day.Card.DASH_KIT))
	for i in range(2):
		var button := illustrated_action(prep_content)
		button.pressed.connect(func(): loadout_pressed.emit(available_cards[i]))
		deck_buttons.append(button)
	start_button = action(prep_content)
	start_button.text = "ENTER / START HARVEST"
	start_button.add_theme_stylebox_override("normal", surface(Color("235246"), 6))
	start_button.add_theme_stylebox_override("hover", surface(Color("316a5b"), 6))
	start_button.pressed.connect(func(): start_pressed.emit())
	prep_pause_button = action(prep_content)
	prep_pause_button.pressed.connect(func(): pause_pressed.emit())

func reward_name(card: Day.Card) -> String:
	match card:
		Day.Card.RESERVE_CELL: return "RESERVE CELL"
		Day.Card.SEED_GUARD: return "SEED GUARD"
		Day.Card.TUNED_BLADE: return "TUNED BLADE"
		Day.Card.LIMITED_COCKTAIL: return "LIMITED COCKTAIL"
		Day.Card.WHEEL_CHOCK: return "WHEEL CHOCK"
		Day.Card.COOLER_CRATE: return "COOLER CRATE"
	return ""

func reward_description(card: Day.Card, chilled_watermelon: int) -> String:
	match card:
		Day.Card.RESERVE_CELL: return "First unload: restore up to %d charge" % Day.RESERVE_CHARGE
		Day.Card.SEED_GUARD: return "First seed hit: costs %d instead of %d" % [Day.GUARDED_SEED_COST, Day.SEED_COST]
		Day.Card.TUNED_BLADE: return "Each cut uses %.2f charge" % Day.TUNED_CUT_COST
		Day.Card.LIMITED_COCKTAIL: return "Special: +$%d each, +%.2fs prep" % [Market.COCKTAIL_BONUS, Market.COCKTAIL_EXTRA_TIME]
		Day.Card.WHEEL_CHOCK: return "Day %d: orange stops +%.2fs" % [RollingOrange.DAY, Day.CHOCK_BRAKE_BONUS]
		Day.Card.COOLER_CRATE:
			if chilled_watermelon == 0:
				return "No watermelon left to carry"
			return "Day 3 depot: %d/%d watermelon saved" % [chilled_watermelon, Day.COOLER_CAPACITY]
	return ""

func refresh_prep(market: Market, card: Day.Card, paused: bool, run_day: int, deck: Array[Day.Card], balance: int, chilled_watermelon: int, target: int) -> void:
	prep_content.add_theme_constant_override("separation", 3 if run_day == Market.DAYS else 5)
	show()
	market_content.hide()
	prep_content.show()
	prep_title.text = "Day %d Preparation" % run_day
	forecast_title.text = "Tonight’s fee $%d  ·  Run net $%d" % [market.fee, balance]
	for i in range(forecast_buttons.size()):
		var button := forecast_buttons[i]
		button.visible = market.offers(i)
		button.disabled = paused
		button.set_pressed_no_signal(i == target)
		button.text = "%s  ·  %d × $%d" % [Market.NAMES[i], market.demand[i], market.price(i)]
		if i == target:
			button.text += "  ✓"
	var target_name: String = "all orders" if target == Market.ALL_RECIPES else SHORT_RECIPE_NAMES[target]
	target_hint.text = "Target: %s  ·  Tap an order or press N" % target_name
	match target:
		Market.Recipe.WATERMELON:
			route_hint.text = "Watermelon patch: west"
		Market.Recipe.MELON:
			route_hint.text = "1 watermelon + 1 spine melon (SW)"
			if run_day == Market.DAYS:
				route_hint.text = "Melon SW: ring  ·  E: dodge sideways"
		Market.Recipe.ORANGE:
			route_hint.text = "1 watermelon + 1 orange (SE)"
		_:
			match run_day:
				RollingOrange.DAY: route_hint.text = "Melon SW  ·  Orange SE (with watermelon)"
				Market.DAYS: route_hint.text = "Melon SW: ring  ·  E: dodge sideways"
				_: route_hint.text = "Spine melon: southwest"
	available_cards = deck
	for i in range(deck_buttons.size()):
		var button := deck_buttons[i]
		button.visible = i < deck.size()
		if button.visible:
			var reward := deck[i]
			present_card(button, reward, "%s / %s" % ["C" if i == 0 else "V", reward_name(reward)],
				reward_description(reward, chilled_watermelon), card == reward, paused or not Day.card_available(reward, run_day))
	present_card(loadout_buttons[Day.Card.STANDARD], Day.Card.STANDARD, "Q / STANDARD KIT",
		"1 charge per cut", card == Day.Card.STANDARD, paused)
	present_card(loadout_buttons[Day.Card.WEDGE], Day.Card.WEDGE, "W / CUTTING WEDGE",
		"Melon opening +%.1fs once  ·  %.2f/cut" % [Day.WEDGE_OPEN_BONUS, Day.WEDGE_CUT_COST],
		card == Day.Card.WEDGE, paused)
	dash_kit_button.visible = Day.card_available(Day.Card.DASH_KIT, run_day)
	present_card(dash_kit_button, Day.Card.DASH_KIT, "B / DASH KIT",
		"Space: one %.2fs dash for %d charge" % [Day.DASH_SECONDS, Day.DASH_COST], card == Day.Card.DASH_KIT, paused)
	start_button.disabled = paused
	prep_pause_button.text = "RESUME" if paused else "PAUSE"

func refresh(market: Market, paused: bool, run_day: int, reward: Day.Card, run_sales: int, run_fees: int,
	results: Array[Dictionary], chilled_watermelon: int) -> void:
	prep_content.hide()
	market_content.show()
	visible = market.phase != Market.Phase.OFF
	if not visible:
		return
	var picking := market.phase == Market.Phase.MENU
	var serving := market.phase == Market.Phase.SERVICE
	var closed := market.phase == Market.Phase.CLOSED
	var final_night := run_day == Market.DAYS
	stall_art.visible = picking or serving
	run_breakdown.visible = closed and final_night
	inventory.visible = not run_breakdown.visible
	title.text = "Day %d Closed" % run_day if closed else "Night %d Market" % run_day
	reward_content.visible = closed and not final_night
	if reward_content.visible:
		reward_title.text = "Choose one card for Day %d" % (run_day + 1)
		reward_options = Day.REWARD_OFFERS[run_day - 1]
		for i in range(reward_buttons.size()):
			var button := reward_buttons[i]
			button.visible = i < reward_options.size()
			if button.visible:
				var card: Day.Card = reward_options[i]
				present_card(button, card, "%s / %s" % [key_for(i), reward_name(card)],
					reward_description(card, chilled_watermelon), card == reward,
					paused or (card == Day.Card.COOLER_CRATE and chilled_watermelon == 0))
	inventory.text = "Watermelon %d   Spine melon %d" % [market.stock.count(0), market.stock.count(SpineMelon.KIND)]
	var citrus_night := market.offers(Market.Recipe.ORANGE)
	if citrus_night:
		inventory.text += "   Orange %d" % market.stock.count(RollingOrange.KIND)
	recipes.visible = picking or serving
	cancel_button.visible = serving and market.queued_recipe != -1
	cancel_button.disabled = paused
	for i in range(recipe_buttons.size()):
		var button := recipe_buttons[i]
		var name_and_price := "%s  ·  $%d" % [Market.NAMES[i], market.price(i)]
		var description: String
		recipe_cards[i].visible = market.offers(i) and (picking or (serving and market.selected[i]))
		if not recipe_cards[i].visible:
			continue
		if picking:
			description = "%s  ·  Up to %d" % [Market.INGREDIENTS[i], market.demand[i]]
			button.text = "%s / %s" % [key_for(i), "REMOVE FROM MENU" if market.selected[i] else "ADD TO MENU"]
			if market.portions(i) == 0:
				button.text = "NEEDS INGREDIENTS"
			button.disabled = paused or market.portions(i) == 0
		elif serving:
			description = "Served %d/%d  ·  Stock for %d" % [market.sold[i], market.demand[i], market.portions(i)]
			var order := market.order_state(i)
			button.disabled = paused or order not in [Market.OrderState.READY, Market.OrderState.QUEUE_NEXT]
			match order:
				Market.OrderState.READY: button.text = "%s / SERVE ORDER" % key_for(i)
				Market.OrderState.QUEUE_NEXT: button.text = "%s / QUEUE NEXT" % key_for(i)
				Market.OrderState.PREPARING: button.text = "PREPARING…"
				Market.OrderState.QUEUED: button.text = "PREPARING · NEXT QUEUED" if market.active_recipe == i else "QUEUED"
				Market.OrderState.QUEUE_FULL: button.text = "QUEUE FULL"
				Market.OrderState.FILLED: button.text = "ORDERS FILLED"
				Market.OrderState.MISSING_INGREDIENTS: button.text = "NEEDS INGREDIENTS"
				Market.OrderState.CLOSING: button.text = "CLOSING"
		button.present(drink_art[i], name_and_price, description + "\n" + button.text, market.selected[i], button.disabled)
	ledger.text = "Sales  $%d     Operating fee  $%d" % [market.gross, market.fee]
	var preparing := serving and market.active_recipe != -1
	progress.visible = serving
	progress.value = 100.0 * (1.0 - market.remaining / market.duration(market.active_recipe)) if preparing else 0.0
	action_button.disabled = paused
	pause_button.text = "RESUME" if paused else "PAUSE"
	var detail_size := 14 if picking else 16
	if detail.get_theme_font_size("font_size") != detail_size:
		detail.add_theme_font_size_override("font_size", detail_size)
	if picking:
		var has_menu := market.has_available_menu()
		var has_selection := market.selected.has(true)
		detail.text = "Set tonight’s menu" if has_menu else "No recipes available"
		if has_selection:
			var shortage := ingredient_list(market.missing_ingredients(market.stock, Market.SELECTED_RECIPES))
			detail.text = "Selected orders covered" if shortage.is_empty() else "Menu short: " + shortage
		action_button.text = "ENTER / OPEN MARKET" if has_menu else "ENTER / CLOSE WITHOUT SALES"
		action_button.disabled = paused or (has_menu and not has_selection)
	elif serving:
		detail.text = "Take an order" if market.can_serve(0) or market.can_serve(1) or market.can_serve(2) else "No orders available"
		if market.closing_requested:
			detail.text = "Closing after accepted orders"
			action_button.text = "ENTER / KEEP OPEN"
		elif preparing:
			detail.text = "Preparing " + Market.NAMES[market.active_recipe]
			action_button.text = "ENTER / CLOSE AFTER"
		else:
			action_button.text = "ENTER / CLOSE MARKET"
	else:
		var result: Dictionary = results[run_day - 1]
		inventory.text = leftover_text(result.leftover)
		if market.net() >= 0:
			detail.text = "Operating fee covered  ·  Net $%d" % market.net()
		else:
			detail.text = "Operating shortfall  ·  $%d" % -market.net()
		ledger.text += "\nServed  %d juice  ·  %d special" % [market.sold[0], market.sold[1]]
		if citrus_night:
			ledger.text += "  ·  %d fizz" % market.sold[2]
		ledger.text += "\n" + unfilled_text(result.demand, result.sold)
		ledger.text += "\nRun sales $%d  ·  Run fees $%d" % [run_sales, run_fees]
		if final_night:
			title.text = "Run Complete"
			detail.text = "Three-day net  %s" % net_text(run_sales - run_fees)
			ledger.text = "Run sales $%d  ·  Run fees $%d" % [run_sales, run_fees]
			update_run_breakdown(results)
			action_button.text = "ENTER / NEW RUN"
		else:
			action_button.text = "ENTER / PREPARE DAY %d" % (run_day + 1)
			action_button.disabled = paused or reward == Day.Card.NONE
	if paused:
		detail.text = "Paused"

func update_run_breakdown(results: Array[Dictionary]) -> void:
	for i in range(night_headings.size()):
		var heading := night_headings[i]
		var breakdown := night_breakdowns[i]
		var result: Dictionary = results[i]
		var net: int = result.sales - result.fee
		heading.text = "Night %d  ·  Net %s" % [i + 1, net_text(net)]
		heading.add_theme_color_override("font_color", LOSS if net < 0 else MINT)
		var orders := PackedStringArray()
		for recipe in range(Market.NAMES.size()):
			if result.demand[recipe] > 0:
				orders.append("%s %d/%d" % [SHORT_RECIPE_NAMES[recipe], result.sold[recipe], result.demand[recipe]])
		breakdown.text = "Sales $%d  ·  Fee $%d\n%s\n%s\n%s" % [
			result.sales, result.fee, "  ·  ".join(orders),
			unfilled_text(result.demand, result.sold), leftover_text(result.leftover),
		]

func unfilled_text(demand: Array, sold: Array) -> String:
	var orders := PackedStringArray()
	for recipe in range(demand.size()):
		var missed: int = demand[recipe] - sold[recipe]
		if missed > 0:
			orders.append("%d %s" % [missed, SHORT_RECIPE_NAMES[recipe].to_lower()])
	return "All orders served" if orders.is_empty() else "Unfilled: " + " · ".join(orders)

static func ingredient_list(counts: Dictionary) -> String:
	var items := PackedStringArray()
	for kind in INGREDIENT_NAMES:
		var amount: int = counts.get(kind, 0)
		if amount > 0:
			items.append("%d %s" % [amount, INGREDIENT_NAMES[kind]])
	return " · ".join(items)

func leftover_text(counts: Array) -> String:
	var fruit := PackedStringArray()
	for i in range(STOCK_NAMES.size()):
		if counts[i] > 0:
			fruit.append("%d %s" % [counts[i], STOCK_NAMES[i]])
	return "Left: none" if fruit.is_empty() else "Left: " + " · ".join(fruit)

func net_text(amount: int) -> String:
	return "-$%d" % -amount if amount < 0 else "$%d" % amount

func key_for(recipe: int) -> String:
	return ["Q", "W", "T"][recipe]

func label(parent: Control, value: String, font_size: int, color: Color) -> Label:
	var text := Label.new()
	text.text = value
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", color)
	parent.add_child(text)
	return text

func illustrated_action(parent: Control, height := 51.0) -> IllustratedAction:
	var button := IllustratedAction.new()
	parent.add_child(button)
	button.custom_minimum_size.y = height
	return button

func present_card(button: IllustratedAction, card: Day.Card, title: String, description: String,
	selected: bool, unavailable: bool) -> void:
	button.text = title + ("   ✓" if selected else "")
	button.present(card_art[card], button.text, description, selected, unavailable)

func action(parent: Control, height := 42.0, padding := 6) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = height
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", surface(Color("2c4656"), padding))
	button.add_theme_stylebox_override("hover", surface(Color("3e5968"), padding))
	button.add_theme_stylebox_override("pressed", surface(Color("35594f"), padding))
	button.add_theme_stylebox_override("disabled", surface(Color("233641"), padding))
	parent.add_child(button)
	return button

func surface(color: Color, padding := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, padding)
	return box
