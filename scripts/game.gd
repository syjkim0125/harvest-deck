extends Node2D

const WATERMELON = preload("res://assets/watermelon-v1.png")
const WATERMELON_FRAME = Rect2(105, 57, 1016, 1190)
const GOLDEN_FRUIT = preload("res://assets/golden-fruit-v1.png")
const GOLDEN_FRAME = Rect2(103, 54, 1019, 1194)
const FRUIT_SOURCE_SIZE = Vector2(1254, 1254)
const HARVESTER_ATLAS = preload("res://assets/harvester-v1.png")
const HARVESTER_FRONT := Rect2(4, 4, 112, 152)
const HARVESTER_SIDE := Rect2(120, 4, 112, 152)
const HARVESTER_BACK := Rect2(236, 4, 112, 152)
const SAW_FRAME := Rect2(354, 4, 156, 76)
const SLICE_ATLAS = preload("res://assets/fruit-slices-v1.png")
const AvatarMotion = preload("res://scripts/avatar_motion.gd")
const CargoView = preload("res://scripts/cargo_view.gd")
const SawAudio = preload("res://scripts/saw_audio.gd")
const Production = preload("res://scripts/production.gd")
const Impact = preload("res://scripts/impact.gd")
const OrchardGround = preload("res://scripts/orchard_ground.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")
const RollingOrange = preload("res://scripts/rolling_orange.gd")
const DayHarvest = preload("res://scripts/day_harvest.gd")
const NightMarket = preload("res://scripts/night_market.gd")
const NightMarketView = preload("res://scripts/night_market_view.gd")
const CUT_TRAIL_DURATION := 0.075
const BREAK_TRAIL_DURATION := 0.108
const HIT_FLASH_DURATION := 0.055
const HIT_HOLD := 0.032
const BREAK_HOLD := 0.040
const PICKUP_DURATION := 0.18
const MAX_CUT_PARTICLES := 160
const SPEED: float = 360.0
const DASH_SPEED := 900.0
const ATTACK_INTERVAL: float = 0.084
const CAPACITY: int = 40
const DEPOT_RADIUS := 85.0
const CARGO_SPACING: float = 3.0
const HUD_HEIGHT: int = 150
const BOUNDS = Rect2(40, 100, 1480, 1040)
@export var day_mode := false
var preparing_day := false
var run_day := 1
var earned_card := DayHarvest.Card.NONE
var deck: Array[DayHarvest.Card] = []
var run_results: Array[Dictionary] = []
var run_sales: int:
	get:
		var total := 0
		for result in run_results:
			total += result.sales
		return total
var run_fees: int:
	get:
		var total := 0
		for result in run_results:
			total += result.fee
		return total
var day := DayHarvest.new()
var night := NightMarket.new()
var night_view: NightMarketView
var impact := Impact.new()
var cargo_view = CargoView.new()
var avatar = AvatarMotion.new()
var player: Vector2 = Vector2(700, 720)
var facing: Vector2 = Vector2.UP
var velocity: Vector2 = Vector2.ZERO
var fruits: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var cargo: Array[int] = []
var hud_panel: ColorRect
var pause_button: Button
var shake_button: Button
var mode_button: Button
var return_button: Button
var dash_button: Button
var dash_left := 0.0
var dash_direction := Vector2.ZERO
var portrait_view: bool = false
var hud_height: float = HUD_HEIGHT
var camera: Camera2D
var orchard_button: Button
var orchard_pad = Vector2(1020, 440)
var upgrade_button: Button
var hire_button: Button
var notice: String = ""
var hud: Label
var status: Label
var audio: AudioStreamPlayer
var encounter_audio: AudioStreamPlayer
var cut_sound: AudioStreamWAV
var break_sound: AudioStreamWAV
var saw_audio: Node
var loop_sound: bool = true
var sound_volume: float = 0.65
var production = Production.new()
var stock: int:
	get: return production.inventory_count()
var cash: int:
	get: return production.collected_cash
var ground_drops: Array[Dictionary] = []
var cash_pad = Vector2(900, 310)
var service_pad = Vector2(680, 410)
var hire_pad = Vector2(1080, 310)
var upgrade_pad = Vector2(460, 310)
var customer_visuals: Dictionary = {}
var hits: int = 0
var seed_hits: int = 0
var cooldown: float = 0.0
var unload_clock: float = 0.0
var time: float = 0.0
var paused: bool = false
var sprite_art: bool = true
var feedback: bool = true
var sound_on: bool = true
var local_stop: bool = true
var drag_id: int = -1
var drag_origin: Vector2
var drag_vector: Vector2 = Vector2.ZERO
var depot: Vector2 = Vector2(680, 310)
var rng = RandomNumberGenerator.new()
var audio_rng = RandomNumberGenerator.new()
var particle_rng := RandomNumberGenerator.new()
var avatar_style: StyleBoxFlat
var cut_trail_left: float = 0.0
var cut_trail_position := Vector2.ZERO
var cut_trail_facing := Vector2.UP
var cut_trail_break := false
var cut_contacts: Array[Dictionary] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rng.seed = 1742
	var ground := OrchardGround.new()
	ground.floor_bounds = BOUNDS
	ground.z_index = -1
	add_child(ground)
	setup_inputs()
	camera = Camera2D.new()
	camera.position = player
	add_child(camera)
	var layer = CanvasLayer.new()
	add_child(layer)
	hud_panel = ColorRect.new()
	hud_panel.color = Color(0.025, 0.055, 0.075, 0.92)
	hud_panel.size = Vector2(960, HUD_HEIGHT)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_panel)
	hud = Label.new()
	hud.position = Vector2(22, 12)
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	status = Label.new()
	status.position = Vector2(22, 46)
	status.add_theme_font_size_override("font_size", 14)
	layer.add_child(status)
	hire_button = Button.new()
	hire_button.position = Vector2(720, 116)
	hire_button.size = Vector2(220, 29)
	hire_button.focus_mode = Control.FOCUS_NONE
	hire_button.pressed.connect(try_hire_cashier)
	layer.add_child(hire_button)
	upgrade_button = Button.new()
	upgrade_button.position = Vector2(480, 116)
	upgrade_button.size = Vector2(220, 29)
	upgrade_button.focus_mode = Control.FOCUS_NONE
	upgrade_button.pressed.connect(try_upgrade_mixer)
	layer.add_child(upgrade_button)
	orchard_button = Button.new()
	orchard_button.position = Vector2(240, 116)
	orchard_button.size = Vector2(220, 29)
	orchard_button.focus_mode = Control.FOCUS_NONE
	orchard_button.pressed.connect(try_unlock_orchard)
	layer.add_child(orchard_button)
	shake_button = Button.new()
	shake_button.focus_mode = Control.FOCUS_NONE
	shake_button.pressed.connect(toggle_reduced_motion)
	layer.add_child(shake_button)
	pause_button = Button.new()
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(func(): set_paused(not paused))
	layer.add_child(pause_button)
	mode_button = Button.new()
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(switch_mode)
	layer.add_child(mode_button)
	return_button = Button.new()
	return_button.text = "ENTER / END HARVEST"
	return_button.focus_mode = Control.FOCUS_NONE
	return_button.pressed.connect(advance_day)
	layer.add_child(return_button)
	dash_button = Button.new()
	dash_button.focus_mode = Control.FOCUS_NONE
	dash_button.add_theme_font_size_override("font_size", 11)
	dash_button.tooltip_text = "Dash once for %d battery." % DayHarvest.DASH_COST
	dash_button.pressed.connect(try_dash)
	layer.add_child(dash_button)
	var night_layer := CanvasLayer.new()
	night_layer.layer = 2
	add_child(night_layer)
	night_view = NightMarketView.new()
	night_layer.add_child(night_view)
	night_view.recipe_pressed.connect(pick_night_recipe)
	night_view.action_pressed.connect(advance_night)
	night_view.loadout_pressed.connect(pick_day_card)
	night_view.reward_pressed.connect(pick_reward_card)
	night_view.start_pressed.connect(begin_harvest)
	night_view.pause_pressed.connect(func(): set_paused(not paused))
	get_viewport().size_changed.connect(layout_hud)
	layout_hud()
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.max_polyphony = 2
	encounter_audio = AudioStreamPlayer.new()
	encounter_audio.stream = SpineMelon.make_cue()
	add_child(encounter_audio)
	saw_audio = SawAudio.new()
	add_child(saw_audio)
	audio_rng.seed = 618
	cut_sound = make_hit_sound(false)
	break_sound = make_hit_sound(true)
	audio.stream = cut_sound
	reset_run()

func toggle_reduced_motion() -> void:
	impact.reduced = not impact.reduced
	clear_cut_feedback()
	particles.clear()
	cargo_view.clear()
	impact.clear()
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
	update_shake_button()

func clear_cut_feedback() -> void:
	avatar.clear_hit()
	cut_trail_left = 0.0
	cut_contacts.clear()
	for fruit in fruits:
		fruit.freeze = 0.0
		fruit.flash = 0.0
		fruit.recoil = Vector2.ZERO

func update_shake_button() -> void:
	shake_button.text = "M / OFF" if impact.reduced else ("M / SOFT" if impact.soft else "M / ON")
	shake_button.tooltip_text = "M: reduce motion   8: soft camera"

func layout_hud() -> void:
	var width = get_viewport_rect().size.x
	portrait_view = width < 800.0
	hud_height = 210.0 if portrait_view else float(HUD_HEIGHT)
	hud_panel.size = Vector2(width, hud_height)
	hud.position = Vector2(16, 10) if portrait_view else Vector2(22, 12)
	status.position = Vector2(16, 60) if portrait_view else Vector2(22, 46)
	hud.add_theme_font_size_override("font_size", 16 if portrait_view else 18)
	status.add_theme_font_size_override("font_size", 12 if portrait_view else 14)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.size = Vector2(width - 32, 44 if portrait_view else 26)
	status.size = Vector2(width - 32, 52 if portrait_view else 66)
	var buttons = [orchard_button, upgrade_button, hire_button]
	var button_width = (width - 48.0) / 3.0 if portrait_view else 220.0
	for i in range(buttons.size()):
		buttons[i].position = Vector2(16 + i * (button_width + 8), 118) if portrait_view else Vector2(240 + i * 240, 116)
		buttons[i].add_theme_font_size_override("font_size", 11 if portrait_view else 16)
		buttons[i].size = Vector2(button_width, 38 if portrait_view else 29)
	var utility_width: float = (width - 48.0) / 3.0 if portrait_view else 68.0
	var utility_gap := 8.0 if portrait_view else 6.0
	var utility_y := 166.0 if portrait_view else 116.0
	var utility_buttons := [shake_button, pause_button, mode_button]
	for i in range(utility_buttons.size()):
		var button: Button = utility_buttons[i]
		button.position = Vector2(16.0 + i * (utility_width + utility_gap), utility_y)
		button.size = Vector2(utility_width, 36 if portrait_view else 29)
		button.add_theme_font_size_override("font_size", 11)
	update_shake_button()
	pause_button.text = "RESUME" if paused else "PAUSE"
	mode_button.text = "NEW LAB" if day_mode else "NEW DAY"
	shake_button.tooltip_text = "Toggle screen shake."
	mode_button.tooltip_text = "Switch modes and start a new run."
	layout_day_actions()
	for button in buttons:
		button.visible = not day_mode
	camera.zoom = Vector2.ONE * (1.4 if portrait_view else 1.0)
	# Orientation changes must not leave a held drag or scale a previous pulse.
	drag_id = -1
	drag_vector = Vector2.ZERO
	camera.offset = Vector2.ZERO

func layout_day_actions() -> void:
	var width := get_viewport_rect().size.x
	var active_kit := day_mode and not preparing_day and not day_finished() and day.card == DayHarvest.Card.DASH_KIT
	return_button.visible = day_mode
	return_button.position = Vector2(16, 118) if portrait_view else Vector2(240, 116)
	return_button.size = Vector2(width - (140 if active_kit else 32), 38) if portrait_view else Vector2(220, 29)
	return_button.add_theme_font_size_override("font_size", 11 if active_kit and portrait_view else 13)
	dash_button.visible = active_kit
	dash_button.position = Vector2(width - 116, 118) if portrait_view else Vector2(480, 116)
	dash_button.size = Vector2(100, 38) if portrait_view else Vector2(220, 29)
	update_dash_button()

func update_dash_button() -> void:
	dash_button.disabled = not can_dash()
	dash_button.text = "DASH USED" if day.dash_used else "SPACE / DASH"

func setup_inputs() -> void:
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func reset_run() -> void:
	run_day = 1
	deck.clear()
	run_results.clear()
	earned_card = DayHarvest.Card.NONE
	reset_day()

func reset_day() -> void:
	rng.seed = 1742
	particle_rng.seed = 2841
	time = 0.0
	player = Vector2(700, 720)
	velocity = Vector2.ZERO
	facing = Vector2.UP
	cargo.clear()
	particles.clear()
	cargo_view.clear()
	fruits.clear()
	production.reset()
	dash_left = 0.0
	day.reset()
	preparing_day = day_mode
	night.reset(run_day)
	if not deck.is_empty():
		day.card = deck.back()
		night.cocktail = day.card == DayHarvest.Card.LIMITED_COCKTAIL
	notice = ""
	ground_drops.clear()
	customer_visuals.clear()
	audio_rng.seed = 618
	hits = 0
	seed_hits = 0
	cooldown = 0.0
	unload_clock = 0.0
	paused = false
	if is_instance_valid(night_view):
		refresh_market_view()
	if is_instance_valid(pause_button):
		pause_button.text = "PAUSE"
		layout_day_actions()
	drag_id = -1
	drag_vector = Vector2.ZERO
	impact.reset()
	avatar.reset()
	clear_cut_feedback()
	if is_instance_valid(saw_audio):
		saw_audio.silence()
	if is_instance_valid(camera):
		camera.position = camera_follow_target()
		camera.offset = Vector2.ZERO
	if is_instance_valid(audio):
		audio.stop()
	for i in range(32):
		var kind = i % 2
		var center = Vector2(510, 690) if kind == 0 else Vector2(1020, 660)
		var home = center + Vector2(rng.randf_range(-160, 160), rng.randf_range(-170, 170))
		fruits.append({"pos": home, "home": home, "hp": 3, "kind": kind, "flash": 0.0, "respawn": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO})
	if is_instance_valid(encounter_audio):
		encounter_audio.stop()
	var melon_sites := [SpineMelon.HOME]
	if day_mode and run_day == NightMarket.DAYS:
		melon_sites.append(SpineMelon.EAST_HOME)
	for site in melon_sites:
		fruits.append({
			"pos": site, "kind": SpineMelon.KIND, "hp": 3,
			"flash": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO,
			"encounter": SpineMelon.new(),
		})

	if day_mode and run_day == RollingOrange.DAY:
		fruits.append({
			"pos": RollingOrange.HOME, "kind": RollingOrange.KIND, "hp": 3,
			"flash": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO,
			"encounter": RollingOrange.new(),
		})

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_paused(true)

func set_paused(value: bool) -> void:
	paused = value
	if paused:
		dash_left = 0.0
	if is_instance_valid(dash_button):
		update_dash_button()
	if is_instance_valid(pause_button):
		pause_button.text = "RESUME" if paused else "PAUSE"
	if is_instance_valid(night_view):
		refresh_market_view()
	clear_cut_feedback()
	if value and is_instance_valid(saw_audio):
		saw_audio.silence()
	if value and is_instance_valid(audio):
		audio.stop()
	if value and is_instance_valid(encounter_audio):
		encounter_audio.stop()
	drag_vector = Vector2.ZERO
	drag_id = -1
	impact.clear()
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P: set_paused(not paused)
			KEY_R: reset_run()
			KEY_7: switch_mode()
			KEY_ENTER, KEY_KP_ENTER:
				if night.phase == NightMarket.Phase.OFF:
					advance_day()
				else:
					advance_night()
			KEY_Q:
				if preparing_day:
					pick_day_card(DayHarvest.Card.STANDARD)
				elif choosing_reward():
					pick_reward_card(DayHarvest.REWARD_OFFERS[run_day - 1][0])
				else:
					pick_night_recipe(NightMarket.Recipe.WATERMELON)
			KEY_W:
				if preparing_day:
					pick_day_card(DayHarvest.Card.WEDGE)
				elif choosing_reward():
					pick_reward_card(DayHarvest.REWARD_OFFERS[run_day - 1][1])
				else:
					pick_night_recipe(NightMarket.Recipe.MELON)
			KEY_C:
				if not deck.is_empty():
					pick_day_card(deck[0])
			KEY_V:
				if deck.size() > 1:
					pick_day_card(deck[1])
			KEY_T:
				if run_day == 1 and choosing_reward():
					pick_reward_card(DayHarvest.Card.WHEEL_CHOCK)
				else:
					pick_night_recipe(NightMarket.Recipe.ORANGE)
			KEY_B: pick_day_card(DayHarvest.Card.DASH_KIT)
			KEY_SPACE: try_dash()
			KEY_E: try_hire_cashier()
			KEY_F: try_upgrade_mixer()
			KEY_G: try_unlock_orchard()
			KEY_1:
				impact.enabled = not impact.enabled
				impact.clear()
			KEY_2: set_sound_enabled(not sound_on)
			KEY_8:
				impact.soft = not impact.soft
				impact.clear()
				camera.offset = Vector2.ZERO
				update_shake_button()
			KEY_6: sprite_art = not sprite_art
			KEY_5:
				loop_sound = not loop_sound
				saw_audio.silence()
			KEY_MINUS: sound_volume = maxf(0.0, sound_volume - 0.1)
			KEY_EQUAL: sound_volume = minf(1.0, sound_volume + 0.1)
			KEY_3:
				feedback = not feedback
				clear_cut_feedback()
				particles.clear()
				cargo_view.clear()
			KEY_4: local_stop = not local_stop
			KEY_M: toggle_reduced_motion()

	# A release must reach the active drag even if GUI consumes it later.
	if event is InputEventScreenTouch and not event.pressed and event.index == drag_id:
		drag_id = -1
		drag_vector = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# Let CanvasLayer controls consume touch before starting the movement drag.
	if event is InputEventScreenTouch:
		if event.pressed and drag_id == -1 and not paused and not preparing_day and not day_finished():
			drag_id = event.index
			drag_origin = event.position
		elif not event.pressed and event.index == drag_id:
			drag_id = -1
			drag_vector = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == drag_id:
		drag_vector = ((event.position - drag_origin) / 65.0).limit_length()

func _physics_process(delta: float) -> void:
	if preparing_day:
		return
	if night.phase != NightMarket.Phase.OFF:
		if not paused:
			night.step(delta)
		refresh_market_view()
		return
	if not paused and not day_finished():
		simulate(delta, movement_direction())
	camera.offset = feedback_offset() if not paused else Vector2.ZERO
	if day_mode:
		update_day_hud()
		queue_redraw()
		return
	hud.text = "HARVEST  $%d  BAG %d/%d  RAW %d  MIX %d  READY %d  TILL $%d  LINE %d" % [cash, cargo.size(), CAPACITY, production.raw.size(), int(production.active_kind >= 0), production.ready.size(), production.pending_cash, production.customers.size()]
	status.text = "WASD / arrows / touch drag • auto-cut • mint: unload / blue: serve / gold: cash / purple: hire / coral: mixer\n1 Hit shake %s   2 Sound %s   3 Reaction %s   4 Local-stop %s   M No-shake %s   P Pause   R Reset %s" % [impact.enabled, sound_on, feedback, local_stop, impact.reduced, "[PAUSED]" if paused else ""]
	status.text += "\n5 Motor %s  -/+ Volume %d%%  Saw %s   6 Sprite art %s" % [loop_sound, roundi(sound_volume * 100), saw_audio.mode(), sprite_art]
	if portrait_view:
		hud.text = "HARVEST  $%d   BAG %d/%d\nRAW %d  MIX %d  READY %d  TILL $%d  LINE %d" % [cash, cargo.size(), CAPACITY, production.raw.size(), int(production.active_kind >= 0), production.ready.size(), production.pending_cash, production.customers.size()]
		status.text = "Drag / WASD: move + auto-cut  |  P: pause  R: reset\n1: shake  2: sound  3: reaction  4: local-stop\n5: motor  -/+: volume %d%%  %s  6: art %s" % [roundi(sound_volume * 100), "PAUSED" if paused else saw_audio.mode(), sprite_art]
	hire_button.text = "CASHIER WORKING" if production.cashier_hired else "E / HIRE CASHIER $%d" % Production.CASHIER_COST
	hire_button.disabled = paused or production.cashier_hired or cash < Production.CASHIER_COST or player.distance_to(hire_pad) >= 80
	upgrade_button.text = "MIXER 0.25s ACTIVE" if production.mixer_upgraded else "F / UPGRADE MIXER $40"
	upgrade_button.disabled = paused or production.mixer_upgraded or cash < Production.MIXER_UPGRADE_COST or player.distance_to(upgrade_pad) >= 80
	orchard_button.text = "ORCHARD OPEN" if production.orchard_unlocked else "G / OPEN ORCHARD $50"
	orchard_button.disabled = paused or production.orchard_unlocked or cash < Production.ORCHARD_COST or player.distance_to(orchard_pad) >= 80
	if portrait_view:
		hire_button.text = "CASHIER WORKING" if production.cashier_hired else "E / CASHIER $30"
		upgrade_button.text = "MIXER UPGRADED" if production.mixer_upgraded else "F / MIXER $40"
		orchard_button.text = "ORCHARD OPEN" if production.orchard_unlocked else "G / ORCHARD $50"
	if not notice.is_empty():
		hire_button.tooltip_text = notice
	queue_redraw()

func update_day_hud() -> void:
	var charge_percent := ceili(day.charge)
	hud.text = "DAY %d   BAT %d%%   BAG %d/%d" % [run_day, charge_percent, cargo.size(), CAPACITY]
	var stock_text := "SAFE %d   MELON %d" % [stock, production.raw.count(SpineMelon.KIND)]
	hud.text += ("\n" if portrait_view else "     ") + stock_text
	match day.card:
		DayHarvest.Card.WEDGE: hud.text += "   WEDGE"
		DayHarvest.Card.RESERVE_CELL: hud.text += "   CELL USED" if day.reward_used else "   CELL READY"
		DayHarvest.Card.SEED_GUARD: hud.text += "   GUARD USED" if day.reward_used else "   GUARD READY"
		DayHarvest.Card.TUNED_BLADE: hud.text += "   TUNED"
		DayHarvest.Card.LIMITED_COCKTAIL: hud.text += "   COCKTAIL"
		DayHarvest.Card.WHEEL_CHOCK: hud.text += "   CHOCK"
	hud.modulate = Color("ffbc82") if charge_percent <= DayHarvest.SEED_COST else Color.WHITE
	if day_finished():
		var hint := "HARVEST ENDED • Safe stock secured"
		if day.outcome == DayHarvest.Outcome.EXHAUSTED:
			hint = "BATTERY EMPTY • Returned • Lost %d" % day.lost_cargo
		status.text = hint + "\nContinue to the night market"
	else:
		var shortage := NightMarketView.ingredient_list(night.missing_ingredients(production.raw))
		var forecast := "Tonight: all orders covered" if shortage.is_empty() else "Need: " + shortage
		status.text = forecast + "\nMint pad: unload • Ring drains battery\nWASD / arrows / drag • auto-cut"
	return_button.text = "ENTER / NIGHT MENU" if day_finished() else "ENTER / END HARVEST"
	if dash_button.visible:
		update_dash_button()
	return_button.disabled = paused or (not day_finished() and (not cargo.is_empty() or player.distance_to(depot) >= DEPOT_RADIUS))

func switch_mode() -> void:
	day_mode = not day_mode
	hud.modulate = Color.WHITE
	layout_hud()
	reset_run()

func day_finished() -> bool:
	return day_mode and day.outcome != DayHarvest.Outcome.ACTIVE

func refresh_market_view() -> void:
	if preparing_day:
		night_view.refresh_prep(night, day.card, paused, run_day, deck, run_sales - run_fees)
	else:
		night_view.refresh(night, paused, run_day, earned_card, run_sales, run_fees, run_results)

func choosing_reward() -> bool:
	return run_day < NightMarket.DAYS and night.phase == NightMarket.Phase.CLOSED

func pick_reward_card(card: DayHarvest.Card) -> void:
	if choosing_reward() and not paused and card in DayHarvest.REWARD_OFFERS[run_day - 1]:
		earned_card = card
		refresh_market_view()

func pick_day_card(card: DayHarvest.Card) -> void:
	if preparing_day and not paused and DayHarvest.card_available(card, run_day) and (
		card in [DayHarvest.Card.STANDARD, DayHarvest.Card.WEDGE, DayHarvest.Card.DASH_KIT] or card in deck):
		day.card = card
		night.cocktail = card == DayHarvest.Card.LIMITED_COCKTAIL
		refresh_market_view()

func begin_harvest() -> bool:
	if not preparing_day or paused:
		return false
	preparing_day = false
	for fruit in fruits:
		if fruit.kind == SpineMelon.KIND and day.card == DayHarvest.Card.WEDGE:
			fruit.encounter.first_open_bonus = DayHarvest.WEDGE_OPEN_BONUS
		elif fruit.kind == RollingOrange.KIND and day.card == DayHarvest.Card.WHEEL_CHOCK:
			fruit.encounter.brake_bonus = DayHarvest.CHOCK_BRAKE_BONUS
	layout_day_actions()
	refresh_market_view()
	return true

func advance_day() -> bool:
	if preparing_day:
		return begin_harvest()
	return enter_night() if day_finished() else finish_day_at_depot()

func enter_night() -> bool:
	if paused or not day_finished() or not night.enter(production.raw):
		return false
	refresh_market_view()
	return true

func pick_night_recipe(recipe: int) -> bool:
	if paused or night.phase == NightMarket.Phase.OFF:
		return false
	var changed := night.toggle_recipe(recipe) if night.phase == NightMarket.Phase.MENU else night.serve(recipe)
	if changed:
		refresh_market_view()
	return changed

func advance_night() -> bool:
	if paused:
		return false
	match night.phase:
		NightMarket.Phase.MENU:
			if not (night.open() if night.has_available_menu() else night.close()):
				return false
		NightMarket.Phase.SERVICE:
			if not night.close():
				return false
		NightMarket.Phase.CLOSED:
			if choosing_reward():
				if earned_card == DayHarvest.Card.NONE:
					return false
				deck.append(earned_card)
				earned_card = DayHarvest.Card.NONE
				run_day += 1
				reset_day()
			else:
				reset_run()
			return true
		_:
			return false
	if night.phase == NightMarket.Phase.CLOSED:
		run_results.append(night.settlement())
	refresh_market_view()
	return true

func finish_day_at_depot() -> bool:
	if not day_mode or preparing_day or day_finished() or paused or not cargo.is_empty() or player.distance_to(depot) >= DEPOT_RADIUS:
		return false
	conclude_day(false)
	return true

func conclude_day(exhausted: bool) -> void:
	dash_left = 0.0
	day.outcome = DayHarvest.Outcome.EXHAUSTED if exhausted else DayHarvest.Outcome.RETURNED
	if exhausted:
		# Keep the oldest half of the carried stack. Already deposited stock is untouched.
		day.lost_cargo = ceili(cargo.size() / 2.0)
		cargo.resize(cargo.size() - day.lost_cargo)
		while not cargo.is_empty():
			deposit_cargo(false)
		ground_drops.clear()
		player = depot
		camera.position = camera_follow_target()
		camera.reset_smoothing()
	velocity = Vector2.ZERO
	drag_id = -1
	drag_vector = Vector2.ZERO
	impact.clear()
	avatar.reset()
	clear_cut_feedback()
	cargo_view.clear()
	particles.clear()
	camera.offset = Vector2.ZERO
	if exhausted:
		camera.force_update_scroll()
	saw_audio.silence()
	audio.stop()
	layout_day_actions()

func try_hire_cashier() -> bool:
	if day_mode or paused or player.distance_to(hire_pad) >= 80:
		notice = "Stand on the purple hire pad to hire."
		return false
	var hired: bool = production.hire_cashier()
	notice = "Cashier hired. You can return to harvesting." if hired else "Collect $30 first, or cashier is already hired."
	return hired

func try_upgrade_mixer() -> bool:
	if day_mode or paused or player.distance_to(upgrade_pad) >= 80:
		notice = "Stand on the coral pad to upgrade the mixer."
		return false
	var upgraded: bool = production.upgrade_mixer()
	notice = "Mixer upgraded: 0.25 seconds per item." if upgraded else "Collect $40 first, or mixer is already upgraded."
	return upgraded

func try_unlock_orchard() -> bool:
	if day_mode or paused or player.distance_to(orchard_pad) >= 80:
		notice = "Stand on the amber orchard pad to unlock."
		return false
	var opened: bool = production.unlock_orchard()
	notice = "Orchard open. Yellow fruit can now be harvested." if opened else "Collect $50 first, or orchard is already open."
	return opened

func set_sound_enabled(value: bool) -> void:
	sound_on = value
	if not value:
		if is_instance_valid(audio):
			audio.stop()
		if is_instance_valid(encounter_audio):
			encounter_audio.stop()
		if is_instance_valid(saw_audio):
			saw_audio.silence()

func feedback_offset() -> Vector2:
	# Convert logical viewport pixels to camera world units.
	return impact.offset() / camera.zoom

func camera_follow_target() -> Vector2:
	# Keep the queue below the fixed HUD while working the shop counter.
	var shop_weight = clampf((600.0 - player.y) / 125.0, 0.0, 1.0)
	var hud_bias = hud_height / (2.0 * camera.zoom.y) if portrait_view else 0.0
	var shop_bias = 50.0 if portrait_view else 180.0
	return player + Vector2(0, -shop_bias * shop_weight - hud_bias)

func movement_direction() -> Vector2:
	if drag_vector.length() > 0.05:
		return drag_vector
	return Input.get_vector("left", "right", "up", "down")

func can_dash() -> bool:
	return day_mode and not preparing_day and not day_finished() and not paused and (
		day.card == DayHarvest.Card.DASH_KIT and not day.dash_used and day.charge > DayHarvest.DASH_COST)

func try_dash() -> bool:
	if not can_dash():
		return false
	var direction := movement_direction()
	dash_direction = direction.normalized() if direction.length() > 0.05 else facing
	dash_left = DayHarvest.DASH_SECONDS
	day.dash_used = true
	day.spend(DayHarvest.DASH_COST)
	update_dash_button()
	return true

func simulate(delta: float, direction: Vector2) -> void:
	if preparing_day:
		return
	# Advance movement, harvesting and production together. A slow frame must not
	# skip cuts then leave negative cooldown debt to repay on subsequent frames.
	# 120 Hz substeps also keep collisions along the path, not at the final point.
	var remaining = maxf(delta, 0.0)
	while remaining > 0.000000001 and not day_finished():
		var step_delta = minf(remaining, 1.0 / 120.0)
		simulate_slice(step_delta, direction)
		remaining -= step_delta

func simulate_slice(delta: float, direction: Vector2) -> void:
	# Age prior feedback before resolving this slice's hits. A late hit must not
	# lose an entire render frame of lifetime, especially after a hitch.
	impact.step(delta)
	cargo_view.step(delta)
	cut_trail_left = maxf(0.0, cut_trail_left - delta)
	for fruit in fruits:
		fruit.flash = maxf(0.0, fruit.flash - delta)
		var held := minf(fruit.freeze, delta)
		fruit.freeze -= held
		if fruit.hp > 0 and fruit.freeze <= 0.0:
			fruit.recoil = fruit.get("recoil", Vector2.ZERO).lerp(Vector2.ZERO, 1.0 - exp(-25.0 * (delta - held)))
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= exp(-4.0 * delta)
		if p.life <= 0.0:
			particles.remove_at(i)
	time += delta
	velocity = direction.limit_length() * SPEED
	var previous_player = player
	if dash_left > 0.0:
		var dash_time := minf(dash_left, delta)
		dash_left = maxf(0.0, dash_left - delta)
		var displacement := dash_direction * DASH_SPEED * dash_time + velocity * (delta - dash_time)
		velocity = displacement / delta
		facing = dash_direction
	elif direction.length() > 0.05:
		facing = direction.normalized()
	player += velocity * delta
	player = player.clamp(BOUNDS.position + Vector2.ONE * 20, BOUNDS.end - Vector2.ONE * 20)
	avatar.step(delta, player - previous_player, facing)
	# Follow the travelled path at the same cadence as movement, not only the
	# final target of a long physics frame. Hit offset stays a separate channel.
	if is_instance_valid(camera):
		camera.position = camera.position.lerp(camera_follow_target(), 1.0 - exp(-10.0 * delta))
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown += ATTACK_INTERVAL
		attack()
		if day_finished():
			return
	for f in fruits:
		if not production.can_harvest(f.kind):
			continue
		if f.kind == SpineMelon.KIND:
			if f.hp > 0:
				step_spine_melon(f, delta)
				if day_finished():
					return
			continue
		if f.kind == RollingOrange.KIND:
			if f.hp > 0:
				f.encounter.step(delta, player)
				f.pos = f.encounter.position
			continue
		if f.hp <= 0:
			f.respawn -= delta
			if f.respawn <= 0.0:
				f.hp = 3
				f.pos = f.home
				f.recoil = Vector2.ZERO
		else:
			f.pos = f.pos.lerp(f.home + Vector2(sin(time * 2.0 + f.home.x) * 7, cos(time * 2.5 + f.home.y) * 5), 1.0 - exp(-7.0 * delta))
	if player.distance_to(depot) < DEPOT_RADIUS and not cargo.is_empty():
		unload_clock += delta
		while unload_clock >= 0.04 and not cargo.is_empty():
			unload_clock -= 0.04
			deposit_cargo(feedback and not impact.reduced)
			if day_mode:
				day.on_deposit()
	else:
		unload_clock = 0.0
	if not day_mode:
		step_shop(delta)
	for i in range(ground_drops.size() - 1, -1, -1):
		if cargo.size() < CAPACITY and player.distance_to(ground_drops[i].pos) < 65:
			cargo.append(ground_drops[i].kind)
			ground_drops.remove_at(i)

	saw_audio.master_gain = sound_volume
	saw_audio.step(delta, sound_on and loop_sound and not paused, velocity.length() > 1, cargo.size() >= CAPACITY)

func deposit_cargo(animate: bool) -> void:
	var index := cargo.size() - 1
	var start := cargo_position(index)
	for i in range(particles.size() - 1, -1, -1):
		if particles[i].get("cargo_index", -1) == index:
			start = pickup_position(particles[i])
			particles.remove_at(i)
			break
	var kind: int = cargo.pop_back()
	production.deposit(kind)
	if animate:
		cargo_view.send(kind, start, depot + Vector2(0, -30))

func step_shop(delta: float) -> void:
	production.step(delta, player.distance_to(service_pad) < 65)
	var live_ids: Array[int] = []
	for i in range(production.customers.size()):
		var id: int = production.customers[i].id
		live_ids.append(id)
		var destination := Vector2(570 + i * 52, 135)
		customer_visuals[id] = customer_visuals.get(id, Vector2(960, 135)).lerp(destination, 1.0 - exp(-5.0 * delta))
	for id in customer_visuals.keys():
		if id not in live_ids:
			customer_visuals.erase(id)
	if player.distance_to(cash_pad) < 65:
		production.collect()

func step_spine_melon(fruit: Dictionary, delta: float) -> void:
	var encounter: SpineMelon = fruit.encounter
	var previous_phase := encounter.phase
	var distance := player.distance_to(fruit.pos)
	encounter.step(delta, distance)
	var battery_cost := DayHarvest.HAZARD_COST_PER_SECOND * delta if distance <= SpineMelon.STRIKE_RADIUS else 0.0
	if encounter.phase != previous_phase:
		if encounter.phase == SpineMelon.Phase.WARNING:
			play_encounter_cue(1.0)
		elif encounter.phase == SpineMelon.Phase.VULNERABLE:
			if encounter.last_strike_hit:
				seed_hits += 1
				battery_cost += day.take_seed_hit() if day_mode else DayHarvest.SEED_COST
			play_encounter_cue(0.57)
	if day_mode and battery_cost > 0.0 and day.spend(battery_cost):
		conclude_day(true)

func play_encounter_cue(pitch: float) -> void:
	if sound_on and is_instance_valid(encounter_audio) and DisplayServer.get_name() != "headless":
		encounter_audio.pitch_scale = pitch
		encounter_audio.volume_linear = sound_volume * 0.65
		encounter_audio.play()

func attack() -> int:
	if preparing_day or cargo.size() >= CAPACITY or day_finished():
		return 0
	var count := 0
	var killed := false
	var exhausted := false
	var nearest_contact := INF
	var animated := feedback and not impact.reduced
	for f in fruits:
		if not production.can_harvest(f.kind) or f.hp <= 0 or cargo.size() >= CAPACITY:
			continue
		var diff: Vector2 = f.pos - player
		var distance := diff.length()
		if distance > 100.0 or (distance > 28.0 and facing.dot(diff / distance) < 0.1):
			continue
		if f.kind == SpineMelon.KIND and f.encounter.phase != SpineMelon.Phase.VULNERABLE:
			continue
		if f.kind == RollingOrange.KIND and f.encounter.phase != RollingOrange.Phase.BRAKING:
			continue
		f.hp -= 1
		count += 1
		hits += 1
		var dead: bool = f.hp <= 0
		var cut_axis := diff / distance if distance > 0.001 else facing
		var contact: Vector2 = f.pos - cut_axis * minf(17.0, distance * 0.5) + Vector2(0, -7)
		if feedback:
			f.flash = HIT_FLASH_DURATION
		if animated:
			if count == 1:
				cut_contacts.clear()
			cut_contacts.append({"at": contact, "axis": cut_axis, "kind": f.kind, "break": dead})
			f.recoil = cut_axis * 9.0
			f.freeze = HIT_HOLD if local_stop else 0.0
		# Favor the nearest break, or the nearest normal cut if nothing broke.
		if (dead and not killed) or (dead == killed and distance < nearest_contact):
			nearest_contact = distance
			cut_trail_position = contact
			cut_trail_facing = cut_axis
		var cargo_start := cargo.size()
		if dead:
			killed = true
			if f.kind in [0, 1]:
				f.respawn = 5.0
			for j in range(3):
				if cargo.size() < CAPACITY:
					cargo.append(f.kind)
				else:
					ground_drops.append({"pos": f.pos + Vector2(j * 9 - 9, 15), "kind": f.kind})
		burst(contact, cut_axis, f.kind, dead, cargo_start, cargo.size() - cargo_start)
		if day_mode and day.spend(day.cut_cost()):
			exhausted = true
			break
	if exhausted:
		conclude_day(true)
		return count
	if count == 0:
		return 0
	impact.hit(killed, cut_trail_facing)
	if animated:
		var hold := (BREAK_HOLD if killed else HIT_HOLD) if local_stop else 0.0
		avatar.confirmed_hit(hold, 1.4 if killed else 1.0)
		cut_trail_break = killed
		cut_trail_left = BREAK_TRAIL_DURATION if killed else CUT_TRAIL_DURATION
	if sound_on:
		if loop_sound and is_instance_valid(saw_audio):
			saw_audio.confirmed_hit()
		# Headless runs validate the synthesized samples without opening audio.
		if is_instance_valid(audio) and DisplayServer.get_name() != "headless":
			var cue := break_sound if killed else cut_sound
			if audio.stream != cue:
				audio.stream = cue
			audio.pitch_scale = audio_rng.randf_range(0.97, 1.04)
			audio.volume_linear = sound_volume * 0.75
			audio.play()
	return count

func burst(at: Vector2, axis: Vector2, kind: int, dead: bool, cargo_start: int, collected: int) -> void:
	var amount := 17 if dead else 7
	var animated := feedback and not impact.reduced
	for i in range(amount if animated else (6 if dead else 3)):
		var piece := animated and dead and i < 4
		var pickup := piece and i < collected
		var spread := 1.45 if piece else 1.15
		var speed := particle_rng.randf_range(100.0, 230.0) if piece else particle_rng.randf_range(145.0, 390.0)
		var velocity := axis.rotated(particle_rng.randf_range(-spread, spread)) * speed
		var lifetime := particle_rng.randf_range(0.16, 0.28)
		if pickup:
			lifetime = PICKUP_DURATION
		particles.append({
			"pos": at, "vel": velocity, "life": lifetime, "duration": lifetime, "kind": kind, "piece": piece,
			"cargo_index": cargo_start + i if pickup else -1,
		})
	if particles.size() > MAX_CUT_PARTICLES:
		particles = particles.slice(particles.size() - MAX_CUT_PARTICLES)

func make_hit_sound(broken: bool) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 24000
	var sample_count := 2640 if broken else 1920
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var noise_rng := RandomNumberGenerator.new()
	noise_rng.seed = 9017 if broken else 4703
	var previous_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / wave.mix_rate
		var noise := noise_rng.randf_range(-1.0, 1.0)
		var grit := (noise - previous_noise * 0.58) * exp(-t * (55.0 if broken else 112.0))
		previous_noise = noise
		var body := sin(TAU * (168.0 * t - 660.0 * t * t)) * exp(-t * 30.0) if broken else sin(TAU * (345.0 * t - 2100.0 * t * t)) * exp(-t * 72.0)
		var edge := sin(TAU * 1900.0 * t) * exp(-t * 220.0)
		var ramp := minf(t / 0.0013, 1.0) * minf(float(sample_count - 1 - i) / 100.0, 1.0)
		var sample := (body * (0.52 if broken else 0.29) + grit * 0.28 + edge * 0.17) * ramp
		bytes.encode_s16(i * 2, roundi(clampf(sample, -0.48, 0.48) * 32767.0))
	wave.data = bytes
	return wave

func _draw() -> void:
	draw_rect(Rect2(520, 190, 320, 72), Color("193a3e"))
	draw_rect(Rect2(530, 180, 300, 64), Color("ecbd68"))
	draw_circle(depot, 82, Color(0.42, 0.9, 0.72, 0.25))
	draw_arc(depot, 82, 0, TAU, 48, Color("85e8b3"), 3)
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(590, 220), "SAFE STOCK / DROP" if day_mode else "JUICE / DROP ZONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("183b38"))
	if not day_mode:
		draw_shop(font)
	for marker in orchard_waypoints():
		draw_orchard_waypoint(font, marker)
	for f in fruits:
		if f.kind == SpineMelon.KIND and f.hp > 0 and not day_finished():
			draw_melon_hazard(f.pos, f.encounter)
		if f.kind == RollingOrange.KIND and f.hp > 0 and not day_finished():
			draw_orange_route()
	for d in ground_drops:
		draw_slice(d.pos, d.kind, 12, 0.15)
	# Sort a separate presentation list; never reorder the harvesting array.
	for actor in world_draw_order():
		if actor == -1:
			draw_player_actor()
		else:
			draw_fruit_actor(fruits[actor])
	draw_cut_trail()
	for p in particles:
		var progress := 1.0 - clampf(p.life / p.duration, 0.0, 1.0)
		var opacity := 1.0 - smoothstep(0.34, 1.0, progress)
		if p.piece and feedback and not impact.reduced:
			var at := pickup_position(p) if p.cargo_index >= 0 else Vector2(p.pos)
			var settled := smoothstep(0.45, 1.0, progress) if p.cargo_index >= 0 else 0.0
			var size := lerpf(7.0, 13.0, settled) if p.cargo_index >= 0 else 7.0 * opacity
			draw_slice(at, p.kind, size, lerp_angle(p.vel.angle() + time * 8.0, 0.13, settled))
		else:
			var juice := cut_juice_color(p.kind)
			juice.a = opacity
			if feedback and not impact.reduced and p.vel.length_squared() > 9000.0:
				var tail: Vector2 = p.pos - p.vel * (0.02 + 0.065 * opacity) * smoothstep(0.0, 0.18, progress)
				draw_line(tail, p.pos, juice, 1.0 + 2.2 * opacity, true)
				draw_circle(p.pos, 1.1 + 1.5 * opacity, juice, true, -1.0, true)
			else:
				draw_circle(p.pos, 3.0, juice, true)
	# Damaged-target bars remain readable above bodies and the carried stack.
	if player_is_occluded():
		draw_player_locator()
	for f in fruits:
		if f.kind == SpineMelon.KIND and f.hp > 0 and not day_finished():
			draw_melon_status(font, f.pos, f.encounter)
		if f.kind == RollingOrange.KIND and f.hp > 0 and not day_finished():
			draw_orange_status(font, f.pos, f.encounter)
		if f.hp > 0 and f.hp < 3 and production.can_harvest(f.kind):
			var display_pos: Vector2 = f.pos + (f.get("recoil", Vector2.ZERO) if feedback and not impact.reduced else Vector2.ZERO)
			draw_rect(Rect2(display_pos + Vector2(-20, -36), Vector2(40, 4)), Color("233635"))
			draw_rect(Rect2(display_pos + Vector2(-20, -36), Vector2(f.hp * 13.3, 4)), Color("ffe3a0"))
	for item in cargo_view.transfers:
		draw_slice(CargoView.position_at(item), item.kind, 13, 0.0)
	if cargo.size() >= CAPACITY:
		draw_string(font, player + Vector2(-35, 45), "FULL! UNLOAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe9a0"))

func orchard_waypoints() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	if not day_mode or preparing_day or day_finished():
		return markers
	markers.append({"at": Vector2(702, 620), "target": depot, "label": "DROP-OFF", "ink": Color("b4efd2")})
	for fruit in fruits:
		if fruit.hp <= 0:
			continue
		if fruit.kind == SpineMelon.KIND:
			var east: bool = fruit.pos == SpineMelon.EAST_HOME
			markers.append({
				"at": Vector2(728, 819) if east else Vector2(670, 772),
				"target": fruit.pos, "label": "SPINE MELON E" if east else "SPINE MELON W", "ink": Color("f1ceff"),
			})
		elif fruit.kind == RollingOrange.KIND:
			# Guide to where a chase starts, even while the fruit is on its loop.
			markers.append({
				"at": Vector2(728, 819), "target": RollingOrange.HOME, "label": "ROLLING ORANGE", "ink": Color("ffd393"),
			})
	return markers

func waypoint_bounds(font: Font, marker: Dictionary) -> Rect2:
	var width := font.get_string_size(marker.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 44.0
	return Rect2(marker.at - Vector2(width / 2.0, 14), Vector2(width, 28))

func draw_orchard_waypoint(font: Font, marker: Dictionary) -> void:
	var panel := waypoint_bounds(font, marker)
	var arrow := panel.position + Vector2(17, 14)
	var direction: Vector2 = (marker.target - marker.at).normalized()
	draw_rect(Rect2(panel.position + Vector2(0, 3), panel.size), Color(0.1, 0.19, 0.16, 0.45))
	draw_rect(panel, Color("213832"))
	draw_rect(panel, marker.ink, false, 1.0)
	var tip := arrow + direction * 8.0
	draw_line(arrow - direction * 7.0, tip, marker.ink, 2.0, true)
	draw_line(tip, tip - direction.rotated(0.62) * 7.0, marker.ink, 2.0, true)
	draw_line(tip, tip - direction.rotated(-0.62) * 7.0, marker.ink, 2.0, true)
	draw_string(font, panel.position + Vector2(32, 19), marker.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, marker.ink)

func draw_shop(font: Font) -> void:
	for i in range(production.customers.size()):
		var customer_id: int = production.customers[i].id
		var p: Vector2 = customer_visuals.get(customer_id, Vector2(570 + i * 52, 135))
		draw_circle(p, 13, Color("f1d8b4"))
		draw_rect(Rect2(p + Vector2(-13, 8), Vector2(26, 22)), Color("7799b3"))
		draw_string(font, p + Vector2(-9, -20), str(customer_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_circle(service_pad, 60, Color("649fbe"))
	draw_string(font, service_pad + Vector2(-48, 0), "AUTO SERVICE" if production.cashier_hired else "STAND TO SERVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("183b38"))
	draw_arc(service_pad, 55, -PI / 2, -PI / 2 + TAU * production.sale_elapsed / Production.SALE_SECONDS, 32, Color.WHITE, 5)
	draw_circle(upgrade_pad, 60, Color("d89580"))
	draw_string(font, upgrade_pad + Vector2(-54, 0), "MIXER 0.25s" if production.mixer_upgraded else "F / MIXER $40", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263b38"))
	var mixer_center = Vector2(563, 234)
	draw_rect(Rect2(mixer_center + Vector2(-18, -29), Vector2(36, 33)), Color("a6e3dc") if production.mixer_upgraded else Color("cfdbcc"))
	draw_rect(Rect2(mixer_center + Vector2(-21, 4), Vector2(42, 12)), Color("e08569") if production.mixer_upgraded else Color("6b837b"))
	if production.active_kind >= 0:
		var spin = time * (27 if production.mixer_upgraded else 15)
		draw_line(mixer_center - Vector2.RIGHT.rotated(spin) * 12, mixer_center + Vector2.RIGHT.rotated(spin) * 12, Color("366f62"), 4)
	draw_circle(hire_pad, 60, Color("ac8fbd"))
	draw_string(font, hire_pad + Vector2(-52, 0), "CASHIER HIRED" if production.cashier_hired else "E / HIRE $30", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263b38"))
	if production.cashier_hired:
		var staff = Vector2(795, 220)
		draw_circle(staff + Vector2(0, -20), 12, Color("f1d8b4"))
		draw_rect(Rect2(staff + Vector2(-13, -9), Vector2(26, 29)), Color("4c7c72"))
		draw_line(staff + Vector2(-8, 0), staff + Vector2(-18, 7 + sin(time * 10) * 3), Color("f1d8b4"), 5)
	draw_circle(cash_pad, 60, Color("c9a84e"))
	draw_string(font, cash_pad + Vector2(-47, 4), "COLLECT $%d" % production.pending_cash, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("263b38"))
	draw_rect(Rect2(540, 253, 280, 12), Color("193a3e"))
	draw_rect(Rect2(540, 253, 280 * production.mix_elapsed / production.mix_duration(), 12), Color("85e8b3"))
	draw_circle(orchard_pad, 60, Color("ddb968"))
	draw_string(font, orchard_pad + Vector2(-57, 3), "ORCHARD OPEN" if production.orchard_unlocked else "G / UNLOCK $50", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263b38"))
	if not production.orchard_unlocked:
		draw_arc(Vector2(1020, 660), 220, 0, TAU, 64, Color("ddb968"), 4)
		draw_string(font, Vector2(930, 690), "LOCKED / OPEN AT PAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a0"))

func draw_melon_hazard(at: Vector2, encounter: SpineMelon) -> void:
	var warning := encounter.phase == SpineMelon.Phase.WARNING
	var radius := SpineMelon.STRIKE_RADIUS
	if not warning and encounter.burst_left <= 0.0:
		if day_mode:
			for i in range(24):
				var angle := TAU * i / 24.0
				draw_arc(at, radius, angle, angle + 0.12, 5, Color("d1b184"), 2.0, true)
		return
	var color := Color("ffd078") if warning else Color("ff977a")
	draw_circle(at, radius, Color(color, 0.17 if warning else 0.29), true, -1.0, true)
	draw_arc(at, radius, 0, TAU, 96, Color("452a29"), 8.0, true)
	draw_arc(at, radius, 0, TAU, 96, color, 4.0, true)
	for i in range(12):
		var ray := Vector2.from_angle(TAU * i / 12.0)
		if warning:
			draw_line(at + ray * (radius - 12), at + ray * (radius - 3), color, 2.5, true)
		else:
			draw_circle(at + ray * (radius * 0.8), 4.0, color, true)

func draw_melon_status(font: Font, at: Vector2, encounter: SpineMelon) -> void:
	var label := "SPINE MELON"
	var color := Color("ecd8ff")
	match encounter.phase:
		SpineMelon.Phase.WARNING:
			label = "STEP OUT"
			color = Color("ffd078")
		SpineMelon.Phase.VULNERABLE:
			label = "OPEN • CUT NOW"
			color = Color("b7ffe0")
			if encounter.last_strike_hit and encounter.time_left > SpineMelon.OPEN_SECONDS - 0.55:
				label = "SEED HIT -%d • CUT NOW" % day.last_seed_cost if day_mode else "SEED HIT • CUT NOW"
				color = Color("ffb29a")
		SpineMelon.Phase.RECOVERING:
			label = "SHELL CLOSED"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var start := at + Vector2(-width / 2.0, -51)
	draw_rect(Rect2(start + Vector2(-7, -16), Vector2(width + 14, 21)), Color("1f2230"))
	draw_string(font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

func draw_cut_trail() -> void:
	if cut_trail_left <= 0.0 or not feedback or impact.reduced:
		return
	var duration := BREAK_TRAIL_DURATION if cut_trail_break else CUT_TRAIL_DURATION
	var age := duration - cut_trail_left
	for contact in cut_contacts:
		var life := BREAK_TRAIL_DURATION if contact.break else CUT_TRAIL_DURATION
		var strength := 1.0 - clampf(age / life, 0.0, 1.0)
		if strength <= 0.0:
			continue
		var center: Vector2 = contact.at
		var axis: Vector2 = contact.axis
		var tint := cut_juice_color(contact.kind)
		tint.a = strength
		var length := 45.0 if contact.break else 33.0
		for i in range(-1, 2):
			var ray := axis.rotated(i * 0.49)
			var tip := center + ray * length * (1.0 if i == 0 else 0.78)
			var width := ray.orthogonal() * (1.1 + 1.9 * strength)
			draw_colored_polygon(PackedVector2Array([center, center + ray * 10.0 + width, tip,
				center + ray * 10.0 - width]), tint)
		var core := Color(1.0, 0.97, 0.79, 1.0 - smoothstep(0.012, 0.055, age))
		if core.a > 0.0:
			var side := axis.orthogonal() * 4.0
			draw_colored_polygon(PackedVector2Array([center - axis * 13.0, center + side,
				center + axis * 19.0, center - side]), core)
			draw_circle(center, 4.5 if contact.break else 3.0, core, true, -1.0, true)

func player_is_occluded() -> bool:
	# Conservative body samples, not per-pixel alpha reads. Ignore transparent
	# sprite corners/stems and fruit drawn behind the player's ground contact.
	var samples = [Vector2(0, -28), Vector2(0, -9), Vector2(-8, -9), Vector2(8, -9)]
	var covered = [false, false, false, false]
	for f in fruits:
		if f.hp <= 0 or not production.can_harvest(f.kind) or f.pos.y + 24.0 < player.y + 16.0:
			continue
		var display_pos: Vector2 = f.pos + (f.get("recoil", Vector2.ZERO) if feedback and not impact.reduced else Vector2.ZERO)
		var scale = fruit_display_scale(f)
		for i in range(samples.size()):
			var local: Vector2 = (player + samples[i] - display_pos) / scale - Vector2(0, 2)
			if (local / Vector2(21, 23)).length_squared() <= 1.0:
				covered[i] = true
	return covered.count(true) >= 2

func draw_player_locator() -> void:
	# Static world-space navigation cue. No clock, pulse, alpha animation or RNG.
	var ring = PackedVector2Array()
	for i in range(33):
		var angle = TAU * i / 32.0
		ring.append(player + Vector2(cos(angle) * 23, 8 + sin(angle) * 9))
	draw_polyline(ring, Color("12323d"), 5, true)
	draw_polyline(ring, Color("b2fff0"), 2, true)
	var center = player + Vector2(0, -15)
	var diamond = PackedVector2Array([center + Vector2(0, -5), center + Vector2(5, 0), center + Vector2(0, 5), center + Vector2(-5, 0), center + Vector2(0, -5)])
	draw_polyline(diamond, Color("12323d"), 5, true)
	draw_polyline(diamond, Color("b2fff0"), 2, true)

func world_draw_order() -> Array[int]:
	# Fruit sprite feet are center+24; the player's ground contact is y+16.
	# Recoil, squash, body bob and stack height cannot change ground depth.
	var entries: Array[Dictionary] = []
	for i in range(fruits.size()):
		var f = fruits[i]
		if f.hp > 0 and production.can_harvest(f.kind):
			entries.append({"id": i, "depth": f.pos.y + 24.0})
	entries.append({"id": -1, "depth": player.y + 16.0})
	entries.sort_custom(func(a, b):
		if a.depth == b.depth:
			return a.id < b.id
		return a.depth < b.depth)
	var order: Array[int] = []
	for entry in entries:
		order.append(entry.id)
	return order

func draw_fruit_actor(f: Dictionary) -> void:
	var display_pos: Vector2 = f.pos + (f.get("recoil", Vector2.ZERO) if feedback and not impact.reduced else Vector2.ZERO)
	draw_set_transform(display_pos, 0, fruit_display_scale(f))
	if f.kind == SpineMelon.KIND:
		draw_spine_melon(f.encounter.phase == SpineMelon.Phase.VULNERABLE, f.flash > 0.0 and feedback)
	elif f.kind == RollingOrange.KIND:
		draw_rolling_orange(f.encounter, f.flash > 0 and feedback)
	else:
		draw_fruit(Vector2.ZERO, f.kind, 24, f.flash > 0 and feedback)
	draw_set_transform(Vector2.ZERO)

func draw_orange_route() -> void:
	var trail := Color("ffcc80")
	draw_dashed_line(RollingOrange.HOME, RollingOrange.TURN, trail, 3, 14, true, true)
	draw_dashed_line(RollingOrange.TURN, RollingOrange.BRAKE_POINT, trail, 3, 14, true, true)
	draw_arc(RollingOrange.BRAKE_POINT, 32, 0, TAU, 32, trail, 2, true)

func draw_orange_status(font: Font, at: Vector2, orange: RollingOrange) -> void:
	var prompt := "ROLLING ORANGE"
	if orange.phase == RollingOrange.Phase.ROLLING:
		prompt = "CUT AHEAD"
	elif orange.phase == RollingOrange.Phase.BRAKING:
		prompt = "CUT NOW"
	var width := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_rect(Rect2(at + Vector2(-width * 0.5 - 5, -65), Vector2(width + 10, 21)), Color("243b32"))
	draw_string(font, at + Vector2(-width * 0.5, -49), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1bd"))

func draw_rolling_orange(orange: RollingOrange, flash: bool) -> void:
	draw_circle(Vector2(0, 9), 24, Color("52362b"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 24, Color("af5028"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 21, Color("f49243") if not flash else Color("fff0b7"), true, -1.0, true)
	var roll := 0.0 if impact.reduced else orange.angle
	var leaf_root := Vector2(0, -20).rotated(roll)
	draw_colored_polygon(PackedVector2Array([leaf_root, Vector2(5, -29).rotated(roll),
		Vector2(15, -27).rotated(roll), Vector2(10, -20).rotated(roll)]), Color("81c66a"))
	for dot in [Vector2(-9, -9), Vector2(4, -12), Vector2(11, 5), Vector2(-10, 8)]:
		draw_circle(dot.rotated(roll), 1.5, Color("b84f2d"), true)
	if orange.phase == RollingOrange.Phase.BRAKING:
		draw_arc(Vector2.ZERO, 28, 0, TAU, 32, Color("fff1bd"), 2.5, true)

func draw_spine_melon(open: bool, flash: bool) -> void:
	draw_circle(Vector2(0, 12), 24, Color("272035"), true, -1.0, true)
	for i in range(8):
		var tip := Vector2.from_angle(TAU * i / 8.0)
		draw_colored_polygon(PackedVector2Array([
			tip.rotated(-0.16) * 23, tip * 34, tip.rotated(0.16) * 23,
		]), Color("643a77"))
	draw_circle(Vector2.ZERO, 26, Color("43274f"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 22, Color("ac76bc") if not flash else Color("f8d5ff"), true, -1.0, true)
	if open:
		draw_circle(Vector2.ZERO, 15, Color("642f64"), true, -1.0, true)
		draw_circle(Vector2.ZERO, 10, Color("fbcaff"), true, -1.0, true)
		for i in range(3):
			draw_circle(Vector2.from_angle(TAU * i / 3.0) * 5, 1.8, Color("762b71"), true)
	else:
		draw_arc(Vector2.ZERO, 15, -2.4, 0.8, 20, Color("683d82"), 4, true)
		draw_line(Vector2(-15, 7), Vector2(15, -8), Color("643a77"), 3, true)

func draw_player_actor() -> void:
	draw_set_transform(player + Vector2(0, 8), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 24, Color(0.02, 0.08, 0.07, 0.4))
	draw_set_transform(Vector2.ZERO)
	var flying := {}
	if feedback and not impact.reduced:
		for p in particles:
			if p.cargo_index >= 0:
				flying[p.cargo_index] = true
	for i in range(cargo.size() - 1, -1, -1):
		if i not in flying:
			draw_slice(cargo_position(i), cargo[i], 13, 0.13 if i % 2 == 0 else -0.13)
	draw_avatar()

func saw_endpoints() -> Array[Vector2]:
	var kick = avatar.kick() if feedback and not impact.reduced else 0.0
	var start = player + facing * (19.0 - kick) + Vector2(0, -6)
	if cut_trail_left <= 0.0 or not feedback or impact.reduced:
		return [start, start + facing * 48]
	# Turn the visual bar toward the confirmed contact without changing the hitbox.
	var weight := clampf(cut_trail_left / CUT_TRAIL_DURATION, 0.0, 1.0)
	var aim := start.direction_to(cut_trail_position)
	var axis := facing.lerp(aim, weight * 0.40).normalized()
	return [start, start + axis * (48.0 + weight * 8.0)]

func draw_avatar() -> void:
	var bob = avatar.bob(impact.reduced)
	var side = facing.orthogonal()
	if facing.y < -0.35:
		draw_equipped_saw(bob)
	for i in range(2):
		var pose = avatar.foot(i, facing, impact.reduced)
		var foot: Vector2 = player + pose.position
		var hip = player + Vector2(0, 4) + side * (-5.5 if i == 0 else 5.5)
		if pose.planted:
			draw_circle(foot + Vector2(0, 2), 5, Color(0.03, 0.08, 0.09, 0.3))
		draw_line(hip, foot, Color("26343d"), 8)
		draw_circle(foot, 5, Color("162c33"))
		draw_line(foot - side * 2, foot + side * 2, Color("79a9aa"), 2)
	if sprite_art:
		var frame := harvester_frame()
		var mirror := -1.0 if frame == HARVESTER_SIDE and facing.x < 0.0 else 1.0
		draw_set_transform(player + Vector2(0, bob), 0.0, Vector2(mirror, 1.0))
		draw_texture_rect_region(HARVESTER_ATLAS, Rect2(-19, -45, 38, 51), frame)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_legacy_avatar_body(bob)
	if facing.y >= -0.35:
		draw_equipped_saw(bob)

func harvester_frame() -> Rect2:
	if absf(facing.x) > absf(facing.y):
		return HARVESTER_SIDE
	return HARVESTER_BACK if facing.y < 0.0 else HARVESTER_FRONT

func draw_legacy_avatar_body(bob: float) -> void:
	draw_circle(player + Vector2(0, -9 + bob), 19, Color("173440"))
	draw_style_box(avatar_jacket_style(), Rect2(player + Vector2(-11, -20 + bob), Vector2(22, 21)))
	var torso = player + Vector2(0, -9 + bob)
	draw_line(torso + Vector2(-6, -7), torso + Vector2(-6, 5), Color("bde2b2"), 2, true)
	draw_line(torso + Vector2(6, -7), torso + Vector2(6, 5), Color("bde2b2"), 2, true)
	draw_rect(Rect2(torso + Vector2(-4, 2), Vector2(8, 5)), Color("e9be72"))
	var head = player + Vector2(0, -28 + bob)
	draw_circle(head, 14, Color("173440"), true, -1.0, true)
	draw_circle(head, 12, Color("e8bc93"), true, -1.0, true)
	var crown = head + Vector2(0, -6)
	draw_circle(crown, 11.0, Color("c58355"), true, -1.0, true)
	var brim_center = head + Vector2(facing.x * 7, -4 + minf(facing.y, 0.0) * 5)
	draw_line(brim_center - Vector2(10, 0), brim_center + Vector2(10, 0), Color("793f35"), 5, true)
	draw_line(crown + Vector2(-4, -6), crown + Vector2(4, -6), Color("edb878"), 2, true)
	if facing.y < -0.35:
		draw_circle(head + Vector2(0, 3), 8, Color("644d44"), true, -1.0, true)
		draw_line(head + Vector2(-7, -2), head + Vector2(7, -2), Color("edb878"), 3, true)
	elif absf(facing.x) > 0.6:
		draw_circle(head + Vector2(signf(facing.x) * 5, 1), 1.8, Color("17313b"))
		draw_circle(head + Vector2(signf(facing.x) * 11, 4), 2.5, Color("dfb98f"))
	else:
		for x in [-4, 4]:
			draw_circle(head + Vector2(x, 1), 1.8, Color("17313b"))
		draw_line(head + Vector2(-2, 7), head + Vector2(2, 7), Color("986c5b"), 1.5)

func draw_equipped_saw(bob: float) -> void:
	var ends = saw_endpoints()
	var axis := ends[0].direction_to(ends[1])
	var side := axis.orthogonal()
	for i in [-1, 1]:
		var shoulder = player + Vector2(i * 9, -13 + bob)
		var hand: Vector2 = ends[0] + side * (i * 7)
		draw_line(shoulder, hand, Color("173440"), 8)
		draw_line(shoulder, hand, Color("e0be98"), 5)
	if sprite_art:
		var length := ends[0].distance_to(ends[1]) + 9.0
		var height := length * SAW_FRAME.size.y / SAW_FRAME.size.x
		var flip := -1.0 if axis.x < 0.0 else 1.0
		draw_set_transform(ends[0], axis.angle(), Vector2(1.0, flip))
		var glow := clampf(cut_trail_left / 0.055, 0.0, 1.0) if feedback and not impact.reduced else 0.0
		draw_texture_rect_region(HARVESTER_ATLAS, Rect2(-9.0, -height * 0.58, length, height), SAW_FRAME,
			Color(1.0 + glow * 0.45, 1.0 + glow * 0.20, 1.0))
		draw_set_transform(Vector2.ZERO)
		return
	draw_line(ends[0], ends[1], Color("17313b"), 20)
	draw_line(ends[0], ends[1], Color("c1d8d0"), 12)
	draw_line(ends[0] + axis * 8, ends[1] - axis * 6, Color("718f91"), 3)
	for tooth in range(8):
		var center: Vector2 = ends[0] + axis * (9 + tooth * 5)
		for sign_side in [-1, 1]:
			draw_line(center + side * (sign_side * 5), center + side * (sign_side * 8) - axis * 2, Color("17313b"), 2)
	draw_circle(ends[0], 13, Color("17313b"))
	draw_circle(ends[0], 10, Color("4eafb6"))
	draw_line(ends[0] - side * 6, ends[0] + side * 6, Color("a3e6df"), 3)

func avatar_jacket_style() -> StyleBoxFlat:
	# Cached once; drawing must not allocate one style box per frame.
	if avatar_style == null:
		avatar_style = StyleBoxFlat.new()
		avatar_style.bg_color = Color("39776a")
		avatar_style.set_corner_radius_all(5)
	return avatar_style

func cargo_position(index: int) -> Vector2:
	var sway = sin(time * 7 - index * 0.18) * minf(index * 0.3, 8.0) if velocity.length() > 1 and not impact.reduced else 0.0
	return player + Vector2(-13 + sway, -25 - index * CARGO_SPACING)

func pickup_position(piece: Dictionary) -> Vector2:
	var progress := 1.0 - clampf(piece.life / PICKUP_DURATION, 0.0, 1.0)
	var destination := cargo_position(piece.cargo_index)
	var at: Vector2 = piece.pos.lerp(destination, smoothstep(0.20, 1.0, progress))
	return at + Vector2(0, -sin(progress * PI) * 12.0)

func draw_slice(at: Vector2, kind: int, radius: float, tilt: float) -> void:
	if sprite_art:
		var frame := Rect2(4 + kind * 128, 4, 120, 96)
		var width := radius * 2.0
		var height := width * frame.size.y / frame.size.x
		draw_set_transform(at, tilt)
		draw_texture_rect_region(SLICE_ATLAS, Rect2(-radius, -height * 0.34, width, height), frame)
		draw_set_transform(Vector2.ZERO)
		return
	# Original procedural wedge: dark silhouette, rind, cut face, three seeds.
	var outline = PackedVector2Array()
	var rind = PackedVector2Array()
	var flesh = PackedVector2Array()
	for i in range(17):
		var direction = Vector2.from_angle(PI * i / 16.0)
		outline.append(at + (direction * (radius + 1.5)).rotated(tilt))
		rind.append(at + (direction * radius).rotated(tilt))
		flesh.append(at + (direction * (radius - 3)).rotated(tilt))
	draw_colored_polygon(outline, Color("17382f"))
	var rind_color := Color("80bb66") if kind == 0 else Color("e6b74f")
	if kind == SpineMelon.KIND:
		rind_color = Color("9b5aad")
	elif kind == RollingOrange.KIND:
		rind_color = Color("cf612e")
	draw_colored_polygon(rind, rind_color)
	draw_colored_polygon(flesh, fruit_flesh_color(kind))
	for x in [-0.45, 0.0, 0.45]:
		draw_circle(at + Vector2(x * radius, radius * 0.36).rotated(tilt), 1.2, Color("3b3337"))

func fruit_flesh_color(kind: int) -> Color:
	match kind:
		0: return Color("ef746b")
		SpineMelon.KIND: return Color("fbcaff")
		RollingOrange.KIND: return Color("ffb35e")
		_: return Color("ffe397")

func cut_juice_color(kind: int) -> Color:
	return Color("f13b4e") if kind == 0 else fruit_flesh_color(kind)

func fruit_display_scale(fruit: Dictionary) -> Vector2:
	if not feedback or impact.reduced:
		return Vector2.ONE
	var strength = clampf(fruit.get("flash", 0.0) / HIT_FLASH_DURATION, 0.0, 1.0)
	return Vector2(1.0 + 0.16 * strength, 1.0 - 0.15 * strength)

func fruit_texture(kind: int) -> Texture2D:
	return WATERMELON if kind == 0 else GOLDEN_FRUIT

func fruit_sprite_region(kind: int) -> Rect2:
	var source_frame = WATERMELON_FRAME if kind == 0 else GOLDEN_FRAME
	var import_scale = fruit_texture(kind).get_size() / FRUIT_SOURCE_SIZE
	return Rect2(source_frame.position * import_scale, source_frame.size * import_scale)

func fruit_sprite_rect(at: Vector2, kind: int, radius: float) -> Rect2:
	var frame = fruit_sprite_region(kind)
	var height = radius * 2.0 * frame.size.y / frame.size.x
	return Rect2(at + Vector2(-radius, radius - height), Vector2(radius * 2.0, height))

func watermelon_rect(at: Vector2, radius: float) -> Rect2:
	return fruit_sprite_rect(at, 0, radius)

func draw_fruit(at: Vector2, kind: int, radius: float, flash: bool) -> void:
	if kind in [0, 1] and sprite_art:
		var shadow = PackedVector2Array()
		for i in range(24):
			var angle = TAU * i / 24.0
			shadow.append(at + Vector2(cos(angle) * radius * 0.95, radius * 0.68 + sin(angle) * radius * 0.28))
		draw_colored_polygon(shadow, Color(0.03, 0.10, 0.07, 0.35))
		var tint := Color.WHITE
		if flash:
			tint = Color(1.3, 1.25, 1.0) if impact.reduced else Color(2.35, 1.9, 0.95)
		draw_texture_rect_region(fruit_texture(kind), fruit_sprite_rect(at, kind, radius), fruit_sprite_region(kind), tint)
		return
	draw_circle(at + Vector2(0, radius * 0.22), radius, Color("203e35"))
	draw_circle(at, radius - 2, Color.WHITE if flash else (Color("74bc68") if kind == 0 else Color("edb950")))
	if kind == 0:
		draw_arc(at, radius * 0.65, -1.0, 1.0, 10, Color("3a8754"), 4)
	else:
		draw_line(at + Vector2(-7, -radius + 2), at + Vector2(0, -radius - 10), Color("86ba64"), 5)
	if radius > 15:
		draw_circle(at + Vector2(-7, 0), 3, Color("17382f"))
		draw_circle(at + Vector2(7, 0), 3, Color("17382f"))

