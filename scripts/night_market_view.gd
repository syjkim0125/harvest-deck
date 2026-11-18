extends Panel

const Market = preload("res://scripts/night_market.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
const INK := Color("101e29")
const PAPER := Color("f2f5ee")
const MUTED := Color("afc6cb")
const MINT := Color("b4efd2")
const GOLD := Color("f7ce88")

signal recipe_pressed(recipe: int)
signal action_pressed
signal pause_pressed

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
	frame.add_child(content)
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
	action_button = action(content)
	action_button.add_theme_stylebox_override("normal", surface(Color("235246"), 6))
	action_button.add_theme_stylebox_override("hover", surface(Color("316a5b"), 6))
	action_button.pressed.connect(func(): action_pressed.emit())
	pause_button = action(content)
	pause_button.pressed.connect(func(): pause_pressed.emit())

func refresh(market: Market, paused: bool) -> void:
	visible = market.phase != Market.Phase.OFF
	if not visible:
		return
	var picking := market.phase == Market.Phase.MENU
	var serving := market.phase == Market.Phase.SERVICE
	title.text = "Day 1 Closed" if market.phase == Market.Phase.CLOSED else "Night Market"
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
