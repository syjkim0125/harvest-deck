extends Panel

const Market = preload("res://scripts/night_market.gd")
const Day = preload("res://scripts/day_harvest.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
const INK := Color("101e29")
const PAPER := Color("f2f5ee")
const MUTED := Color("afc6cb")
const MINT := Color("b4efd2")
const GOLD := Color("f7ce88")

signal recipe_pressed(recipe: int)
signal action_pressed
signal pause_pressed
signal reward_pressed(card: Day.Card)
signal loadout_pressed(card: Day.Card)
signal start_pressed

var market_content: VBoxContainer
var prep_content: VBoxContainer
var loadout_buttons: Array[Button] = []
var prep_title: Label
var available_reward := Day.Card.NONE
var earned_button: Button
var earned_description: Label
var reward_content: VBoxContainer
var reward_buttons: Array[Button] = []
var start_button: Button
var prep_pause_button: Button
var title: Label
var detail: Label
var inventory: Label
var ledger: Label
var progress: ProgressBar
var recipes: VBoxContainer
var recipe_cards: Array[PanelContainer] = []
var recipe_labels: Array[Label] = []
var recipe_buttons: Array[Button] = []
var action_button: Button
var pause_button: Button

func _ready() -> void:
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
	content.add_theme_constant_override("separation", 10)
	var pages := VBoxContainer.new()
	frame.add_child(pages)
	pages.add_child(content)
	market_content = content
	build_prep(pages)
	title = label(content, "Night Market", 32, PAPER)
	detail = label(content, "", 16, GOLD)
	inventory = label(content, "", 14, MUTED)
	recipes = VBoxContainer.new()
	recipes.add_theme_constant_override("separation", 9)
	content.add_child(recipes)
	for i in range(Market.NAMES.size()):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", surface(Color("1b303d"), 8))
		recipes.add_child(card)
		recipe_cards.append(card)
		var recipe := VBoxContainer.new()
		recipe.add_theme_constant_override("separation", 5)
		card.add_child(recipe)
		label(recipe, "%s  ·  $%d" % [Market.NAMES[i], Market.PRICES[i]], 17, MINT if i == 0 else GOLD)
		label(recipe, "1 watermelon" if i == 0 else "1 watermelon + 1 spine melon", 13, MUTED)
		recipe_labels.append(label(recipe, "", 13, MUTED))
		var button := action(recipe)
		button.pressed.connect(func(): recipe_pressed.emit(i))
		recipe_buttons.append(button)
	ledger = label(content, "", 15, PAPER)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 7
	progress.add_theme_stylebox_override("background", surface(Color("253b46")))
	progress.add_theme_stylebox_override("fill", surface(MINT))
	content.add_child(progress)
	reward_content = VBoxContainer.new()
	content.add_child(reward_content)
	label(reward_content, "Choose one card for Day 2", 16, GOLD)
	for card in Day.REWARDS:
		var button := action(reward_content)
		button.pressed.connect(func(): reward_pressed.emit(card))
		reward_buttons.append(button)
		label(reward_content, reward_description(card), 13, MUTED)
	action_button = action(content)
	action_button.add_theme_stylebox_override("normal", surface(Color("235246"), 6))
	action_button.add_theme_stylebox_override("hover", surface(Color("316a5b"), 6))
	action_button.pressed.connect(func(): action_pressed.emit())
	pause_button = action(content)
	pause_button.pressed.connect(func(): pause_pressed.emit())

func build_prep(parent: Control) -> void:
	prep_content = VBoxContainer.new()
	prep_content.custom_minimum_size.x = 280
	prep_content.add_theme_constant_override("separation", 8)
	parent.add_child(prep_content)
	prep_title = label(prep_content, "", 27, PAPER)
	label(prep_content, "Tonight’s orders  ·  Fee $%d" % Market.FEE, 16, GOLD)
	for i in range(Market.NAMES.size()):
		label(prep_content, "%s  ·  %d × $%d" % [Market.NAMES[i], Market.DEMAND[i], Market.PRICES[i]], 14, MINT)
	label(prep_content, "Special: 1 watermelon + 1 spine melon", 13, MUTED)
	label(prep_content, "Choose today’s loadout", 16, GOLD)
	var standard := action(prep_content)
	standard.pressed.connect(func(): loadout_pressed.emit(Day.Card.STANDARD))
	loadout_buttons.append(standard)
	label(prep_content, "1 charge per cut  ·  Normal openings", 13, MUTED)
	var wedge := action(prep_content)
	wedge.pressed.connect(func(): loadout_pressed.emit(Day.Card.WEDGE))
	loadout_buttons.append(wedge)
	label(prep_content, "First melon opening +%.1fs  ·  %.2f charge/cut" % [Day.WEDGE_OPEN_BONUS, Day.WEDGE_CUT_COST], 13, MUTED)
	earned_button = action(prep_content)
	earned_button.pressed.connect(func(): loadout_pressed.emit(available_reward))
	earned_description = label(prep_content, "", 13, MUTED)
	start_button = action(prep_content)
	start_button.text = "ENTER / START HARVEST"
	start_button.add_theme_stylebox_override("normal", surface(Color("235246"), 6))
	start_button.add_theme_stylebox_override("hover", surface(Color("316a5b"), 6))
	start_button.pressed.connect(func(): start_pressed.emit())
	prep_pause_button = action(prep_content)
	prep_pause_button.pressed.connect(func(): pause_pressed.emit())

func reward_name(card: Day.Card) -> String:
	return "RESERVE CELL" if card == Day.Card.RESERVE_CELL else "SEED GUARD"

func reward_description(card: Day.Card) -> String:
	if card == Day.Card.RESERVE_CELL:
		return "First unload: restore up to %d charge" % Day.RESERVE_CHARGE
	return "First seed hit: costs %d instead of %d" % [Day.GUARDED_SEED_COST, Day.SEED_COST]

func refresh_prep(card: Day.Card, paused: bool, run_day: int, reward: Day.Card) -> void:
	show()
	market_content.hide()
	prep_content.show()
	prep_title.text = "Day %d Preparation" % run_day
	available_reward = reward if run_day > 1 else Day.Card.NONE
	earned_button.visible = available_reward != Day.Card.NONE
	earned_description.visible = earned_button.visible
	if earned_button.visible:
		earned_button.text = "C / " + reward_name(available_reward) + ("   ✓" if card == available_reward else "")
		earned_description.text = reward_description(available_reward)
		earned_button.disabled = paused
	loadout_buttons[Day.Card.STANDARD].text = "Q / STANDARD KIT" + ("   ✓" if card == Day.Card.STANDARD else "")
	loadout_buttons[Day.Card.WEDGE].text = "W / CUTTING WEDGE" + ("   ✓" if card == Day.Card.WEDGE else "")
	for button in loadout_buttons:
		button.disabled = paused
	start_button.disabled = paused
	prep_pause_button.text = "RESUME" if paused else "PAUSE"

func refresh(market: Market, paused: bool, run_day: int, reward: Day.Card) -> void:
	prep_content.hide()
	market_content.show()
	visible = market.phase != Market.Phase.OFF
	if not visible:
		return
	var picking := market.phase == Market.Phase.MENU
	var serving := market.phase == Market.Phase.SERVICE
	var closed := market.phase == Market.Phase.CLOSED
	title.text = "Day %d Closed" % run_day if closed else "Night Market"
	reward_content.visible = closed and run_day == 1
	if reward_content.visible:
		for i in range(reward_buttons.size()):
			var card: Day.Card = Day.REWARDS[i]
			var button := reward_buttons[i]
			button.text = "%s / %s%s" % [key_for(i), reward_name(card), "   ✓" if card == reward else ""]
			button.disabled = paused
	inventory.text = "Watermelon  %d     Spine melon  %d" % [market.stock.count(0), market.stock.count(SpineMelon.KIND)]
	recipes.visible = picking or serving
	for i in range(recipe_buttons.size()):
		var button := recipe_buttons[i]
		recipe_cards[i].visible = picking or (serving and market.selected[i])
		if picking:
			recipe_labels[i].text = "Up to %d orders" % Market.DEMAND[i]
			button.text = "%s / %s" % [key_for(i), "REMOVE FROM MENU" if market.selected[i] else "ADD TO MENU"]
			if market.portions(i) == 0:
				button.text = "NEEDS INGREDIENTS"
			button.disabled = paused or market.portions(i) == 0
		elif serving:
			recipe_labels[i].text = "Served %d / %d   ·   Stock for %d" % [market.sold[i], Market.DEMAND[i], market.portions(i)]
			button.text = "%s / SERVE ORDER" % key_for(i)
			button.disabled = paused or not market.can_serve(i)
	ledger.text = "Sales  $%d     Operating fee  $%d" % [market.gross, Market.FEE]
	var preparing := serving and market.active_recipe != -1
	progress.visible = serving
	progress.value = 100.0 * (1.0 - market.remaining / market.duration(market.active_recipe)) if preparing else 0.0
	action_button.disabled = paused
	pause_button.text = "RESUME" if paused else "PAUSE"
	if picking:
		detail.text = "Set tonight’s menu" if market.has_available_menu() else "No recipes available"
		action_button.text = "ENTER / OPEN MARKET" if market.has_available_menu() else "ENTER / CLOSE WITHOUT SALES"
		action_button.disabled = paused or (market.has_available_menu() and not market.selected.has(true))
	elif serving:
		detail.text = "Take an order" if market.can_serve(0) or market.can_serve(1) else "No orders available · close the market"
		if preparing:
			detail.text = "Preparing " + Market.NAMES[market.active_recipe]
		action_button.text = "ENTER / CLOSE MARKET"
		action_button.disabled = paused or market.active_recipe != -1
	else:
		if market.net() >= 0:
			detail.text = "Operating fee covered  ·  Net $%d" % market.net()
		else:
			detail.text = "Operating shortfall  ·  $%d" % -market.net()
		ledger.text += "\nServed  %d juice  ·  %d special" % [market.sold[0], market.sold[1]]
		action_button.text = "ENTER / REPLAY DAY 1"
		if reward_content.visible:
			action_button.text = "ENTER / PREPARE DAY 2"
			action_button.disabled = paused or reward == Day.Card.NONE
	if paused:
		detail.text = "Paused"

func key_for(recipe: int) -> String:
	return "Q" if recipe == 0 else "W"

func label(parent: Control, value: String, font_size: int, color: Color) -> Label:
	var text := Label.new()
	text.text = value
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", color)
	parent.add_child(text)
	return text

func action(parent: Control) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", surface(Color("2c4656"), 6))
	button.add_theme_stylebox_override("hover", surface(Color("3e5968"), 6))
	button.add_theme_stylebox_override("pressed", surface(Color("35594f"), 6))
	button.add_theme_stylebox_override("disabled", surface(Color("233641"), 6))
	parent.add_child(button)
	return button

func surface(color: Color, padding := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, padding)
	return box
