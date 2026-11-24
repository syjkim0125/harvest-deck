extends Node2D

const Combat = preload("res://scripts/mobile_combat.gd")
const Shop = preload("res://scripts/mobile_shop.gd")
const Art = preload("res://scripts/mobile_shop_art.gd")
const MarketArt = preload("res://scripts/market_art.gd")
const FontKO = preload("res://assets/market-sans.otf")
const PAPER := Color("fff1d0")
const OAK := Color("25273f")
const MINT := Color("9bf0c5")
const GOLD := Color("ffd279")
const PLAY_AREA := Vector2(360, 640)
const SHEET_TOP := 210.0
const OPTION_W := 102.0
const OPTION_H := 120.0
const MOTION_RECT := Rect2(295, 16, 56, 56)
const INTRO_STICK := Vector2(180, 566)
const INTRO_STICK_RADIUS := 38.0
const INTRO_DRAG_THRESHOLD := 10.0
const INTRO_STEP_SECONDS := 0.22

enum Phase { INTRO, HUNT, UPGRADE, SHOP, REWARD, SCORE }
var phase := Phase.INTRO
var combat: Combat
var canvas: Node2D
var scale_factor := 1.0
var origin := Vector2.ZERO
var animation := 0.0
var day_number := 1
var total_cash := 0
var total_sold := 0
var reward := -1
var day_card_level := 0
var day_deck: Array[int] = []
var day_draw: Array[int] = []
var day_discard: Array[int] = []
var equipped: Array[int] = []
var night_deck: Array[int] = []
var night_draw: Array[int] = []
var night_discard: Array[int] = []
var options: Array[int] = []
var shop: Shop
var art := Art.new()
var pointer := -2
var press_at := Vector2.ZERO
var point := Vector2.ZERO
var hand_at_press := -1
var intro_step_left := 0.0
var selected := -1
var rejected := 0.0
var settings := false
var motion := 0
var stash_counts: Array[int] = [0, 0]
var stall := MarketArt.stall()
var spin_icon := MarketArt.card(4)
var guard_icon := MarketArt.card(3)
var random := RandomNumberGenerator.new()

func _ready() -> void:
	if OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).get('lab') === '1'"):
		get_tree().call_deferred("change_scene_to_file", "res://main.tscn")
		return
	combat = Combat.new()
	add_child(combat)
	var overlay := CanvasLayer.new()
	overlay.layer = 4
	add_child(overlay)
	canvas = Node2D.new()
	overlay.add_child(canvas)
	canvas.draw.connect(paint)
	get_viewport().size_changed.connect(layout)
	layout()
	reset_run()

func layout() -> void:
	var view := get_viewport_rect().size
	scale_factor = minf(view.x / PLAY_AREA.x, view.y / PLAY_AREA.y)
	origin = (view - PLAY_AREA * scale_factor) * 0.5
	canvas.position = origin
	canvas.scale = Vector2.ONE * scale_factor

func reset_run() -> void:
	day_number = 1
	total_cash = 0
	total_sold = 0
	reward = -1
	random.seed = Time.get_ticks_usec()
	day_deck.assign(Combat.DAY_STARTER)
	night_deck.assign(Shop.STARTER)
	start_hunt()
	phase = Phase.INTRO
	combat.active = false

func start_hunt() -> void:
	clear_pointer()
	combat.show()
	combat.camera.enabled = true
	combat.start_hunt(day_number, day_number == 2 and reward == Shop.EXTRA)
	apply_motion()
	day_card_level = 0
	equipped.clear()
	day_draw = shuffled(day_deck)
	if reward in day_deck:
		day_draw.erase(reward)
		day_draw.push_front(reward)
	day_discard.clear()
	stash_counts.fill(0)
	phase = Phase.HUNT

func shuffled(deck: Array[int]) -> Array[int]:
	var batch: Array[int] = deck.duplicate()
	for i in range(batch.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var card := batch[i]
		batch[i] = batch[j]
		batch[j] = card
	return batch

func offer_day_cards() -> void:
	options.clear()
	for i in range(3):
		if day_draw.is_empty():
			day_draw = shuffled(day_discard)
			day_discard.clear()
		options.append(day_draw.pop_front())
	phase = Phase.UPGRADE
	combat.saw_audio.silence()
	clear_pointer()

func pick_day_card(card: int) -> void:
	if phase != Phase.UPGRADE or card not in options:
		return
	combat.equip(card)
	if day_card_level == 0:
		combat.preview_upgrade(card)
	equipped.append(card)
	day_discard.append_array(options)
	day_card_level += 1
	phase = Phase.HUNT

func open_market() -> void:
	combat.stop_hunt()
	combat.hide()
	combat.camera.enabled = false
	clear_pointer()
	art = Art.new()
	shop = Shop.new()
	shop.setup(combat.cargo, combat.star_fruit)
	night_draw = shuffled(night_deck)
	night_discard.clear()
	# Both starter routes are available on opening night.
	if day_number == 1:
		night_draw.assign([Shop.JUICE, Shop.MIX, Shop.HELP, Shop.GIFT])
	elif reward in night_deck:
		night_draw.erase(reward)
		night_draw.push_front(reward)
	refill_night_hand()
	phase = Phase.SHOP
	selected = -1

func refill_night_hand() -> void:
	night_discard.append_array(shop.hands)
	shop.hands.clear()
	# Offer both ways to respond to the first night's bottleneck after the shift.
	if day_number == 1 and shop.shift == 1 and not shop.helper and shop.raw[0] + shop.raw[1] > 0:
		for card in [Shop.JUICE, Shop.HELP, Shop.GIFT]:
			if night_draw.has(card):
				night_draw.erase(card)
				shop.hands.append(card)
			elif night_discard.has(card):
				night_discard.erase(card)
				shop.hands.append(card)
	for i in range(3 - shop.hands.size()):
		if night_draw.is_empty():
			night_draw = shuffled(night_discard)
			night_discard.clear()
		shop.hands.append(night_draw.pop_front())
	shop.energy = 2
	selected = -1

func opening_card() -> int:
	if shop.opened:
		return -1
	for card in shop.hands:
		if shop.can_play(card):
			return card
	return -1

func select_shop_card(card: int) -> void:
	selected = card if shop.can_play(card) else -1
	rejected = 0.55 if selected < 0 else 0.0

func play_card(card: int, station: int) -> void:
	if shop.play_at(card, station):
		night_discard.append(card)
		selected = -1
		rejected = 0.0
	else:
		select_shop_card(card)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(combat):
		return
	animation += delta
	rejected = maxf(0.0, rejected - delta)
	if not settings:
		if phase == Phase.HUNT:
			combat.tick_hunt(delta, day_number)
			if intro_step_left > 0.0:
				intro_step_left = maxf(0.0, intro_step_left - delta)
				if intro_step_left == 0.0:
					combat.direction = Vector2.ZERO
			stash_counts[0] = combat.cargo.count(0)
			stash_counts[1] = combat.cargo.count(1)
			if combat.hearts <= 0 or combat.time >= Combat.DAY_SECONDS:
				open_market()
			elif day_card_level < Combat.LEVELS.size() and combat.defeated >= Combat.LEVELS[day_card_level]:
				offer_day_cards()
		elif phase == Phase.SHOP:
			shop.tick(delta)
			art.refresh(delta, shop)
			if shop.shift == 0 and shop.time >= Shop.SHIFT:
				shop.shift = 1
				refill_night_hand()
			if shop.done:
				total_cash += shop.cash
				total_sold += shop.sold
				options.assign([Combat.GUARD, Shop.EXTRA])
				phase = Phase.REWARD if day_number == 1 else Phase.SCORE
				clear_pointer()
	canvas.queue_redraw()

func apply_motion() -> void:
	combat.impact.soft = motion == 1
	combat.impact.reduced = motion == 2
	combat.impact.clear()
	combat.camera.offset = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(combat):
		clear_pointer()
		if phase in [Phase.HUNT, Phase.SHOP]:
			settings = true
			combat.saw_audio.silence()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(combat):
		return
	if event is InputEventScreenTouch:
		if event.canceled:
			if pointer == event.index:
				clear_pointer()
			return
		contact(event.index, (event.position - origin) / scale_factor, event.pressed)
	elif event is InputEventScreenDrag:
		drag(event.index, (event.position - origin) / scale_factor)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		contact(-1, (event.position - origin) / scale_factor, event.pressed)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		drag(-1, (event.position - origin) / scale_factor)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				settings = not settings
				clear_pointer()
				combat.saw_audio.silence()
			KEY_8:
				motion = 0 if motion == 1 else 1
				apply_motion()
			KEY_M:
				motion = 0 if motion == 2 else 2
				apply_motion()

func contact(id: int, at: Vector2, pressed: bool) -> void:
	if pressed:
		if pointer != -2:
			return
		if intro_step_left > 0.0:
			intro_step_left = 0.0
			combat.direction = Vector2.ZERO
		pointer = id
		press_at = at
		point = at
		hand_at_press = card_at(at, shop.hands, 491) if phase == Phase.SHOP and not settings else -1
		return
	if pointer != id:
		return
	var from := press_at
	var down_card := hand_at_press
	clear_pointer()
	if settings:
		if Rect2(84, 347, 192, 66).has_point(at):
			motion = (motion + 1) % 3
			apply_motion()
		else:
			settings = false
		return
	if MOTION_RECT.has_point(from) and MOTION_RECT.has_point(at):
		settings = true
		combat.saw_audio.silence()
		return
	match phase:
		Phase.INTRO:
			if from.distance_to(INTRO_STICK) <= INTRO_STICK_RADIUS and at.distance_to(INTRO_STICK) <= INTRO_STICK_RADIUS:
				begin_hunt(Vector2.UP)
				intro_step_left = INTRO_STEP_SECONDS
		Phase.UPGRADE:
			pick_day_card(card_at(at, options, 288))
		Phase.SHOP:
			var target := station_at(at)
			if down_card >= 0:
				if target >= 0:
					play_card(down_card, target)
				else:
					select_shop_card(down_card)
			elif (not shop.opened and selected < 0 and not shop.customers.is_empty()
					and from.distance_to(at) < 14.0 and art.first_customer_hit_area(shop).has_point(from)
					and art.first_customer_hit_area(shop).has_point(at)):
				shop.opened = true
				rejected = 0.0
			elif target >= 0:
				if selected >= 0:
					play_card(selected, target)
				elif not shop.opened:
					var suggested := opening_card()
					if suggested < 0:
						shop.opened = true
					elif Shop.station(suggested) == target:
						select_shop_card(suggested)
		Phase.REWARD:
			var card := card_at(at, options, 288)
			if card < 0:
				return
			reward = card
			if card < 10:
				day_deck.append(card)
			else:
				night_deck.append(card)
			day_number = 2
			start_hunt()
		Phase.SCORE:
			if Rect2(110, 414, 140, 104).has_point(at):
				reset_run()

func begin_hunt(direction: Vector2) -> void:
	phase = Phase.HUNT
	combat.active = true
	combat.direction = direction

func drag(id: int, at: Vector2) -> void:
	if settings or pointer != id:
		return
	point = at
	if MOTION_RECT.has_point(press_at):
		return
	var displacement := at - press_at
	var direction := (displacement / 45.0).limit_length()
	if phase == Phase.INTRO and displacement.length() > INTRO_DRAG_THRESHOLD:
		begin_hunt(direction)
	elif phase == Phase.HUNT:
		combat.direction = direction

func clear_pointer() -> void:
	pointer = -2
	hand_at_press = -1
	intro_step_left = 0.0
	if is_instance_valid(combat):
		combat.direction = Vector2.ZERO

func station_at(at: Vector2) -> int:
	for i in range(Art.STATIONS.size()):
		if Art.STATIONS[i].has_point(at):
			return i
	return -1

func card_rect(index: int, count: int, y: float) -> Rect2:
	var row_width := OPTION_W * count + 9 * (count - 1)
	return Rect2((360 - row_width) / 2.0 + index * (OPTION_W + 9), y, OPTION_W, OPTION_H)

func card_at(at: Vector2, cards: Array[int], y: float) -> int:
	for i in range(cards.size()):
		if card_rect(i, cards.size(), y).has_point(at):
			return cards[i]
	return -1

func label(line: String, x: float, y: float, size: int, color := PAPER) -> void:
	canvas.draw_string(FontKO, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func center(line: String, y: float, size: int, color := PAPER, x: float = 180.0) -> void:
	label(line, x - FontKO.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, y, size, color)

func paint() -> void:
	if phase in [Phase.SHOP, Phase.REWARD, Phase.SCORE]:
		canvas.draw_rect(Rect2(-origin / scale_factor, get_viewport_rect().size / scale_factor), Color("282548"))
	match phase:
		Phase.INTRO:
			paint_hunt_hud()
			paint_intro()
		Phase.HUNT:
			paint_hunt_hud()
			paint_joystick()
		Phase.UPGRADE:
			paint_hunt_hud()
			paint_offer("전투 카드", "카드 한 장을 골라요", false)
		Phase.SHOP:
			paint_shop()
		Phase.REWARD:
			paint_shop(false)
			paint_offer("오늘 번 돈  %d" % shop.cash, "내일 덱에 넣을 선물", true)
		Phase.SCORE:
			paint_score()
	if not settings:
		paint_settings_icon()
	else:
		paint_settings()

func paint_hunt_hud() -> void:
	Art.box(canvas, Rect2(12, 16, 266, 92), Color("24453d"), 20)
	var preview := combat.preview_card if phase == Phase.HUNT and combat.preview_left > 0.0 else -1
	for i in range(combat.heart_limit):
		var at := Vector2(33 + 23 * i, 39)
		if preview == Combat.HEART and i == combat.heart_limit - 1:
			canvas.draw_arc(at, 11, 0, TAU, 24, MINT, 2.0, true)
		heart(at, i < combat.hearts)
	label("낮 %d" % day_number, 214, 46, 18)
	if preview == Combat.BOUNTY:
		Art.box(canvas, Rect2(21, 60, 137, 30), Color("315c4d"), 5, MINT)
	Art.fruit(canvas, Vector2(36, 75), 0, 0.78)
	Art.fruit(canvas, Vector2(108, 75), 1, 0.78)
	label(str(stash_counts[0]), 49, 81, 19)
	label(str(stash_counts[1] - int(combat.star_fruit)), 122, 81, 19)
	Art.progress(canvas, Rect2(168, 71, 88, 8), 1.0 - combat.time / Combat.DAY_SECONDS)
	if combat.star_fruit:
		paint_star_fruit(Vector2(244, 93), 0.58)
	for i in equipped.size():
		var at := Vector2(29 + i * 39, 131)
		if i == 0 and preview >= 0:
			canvas.draw_circle(at, 18, Color("24453d"), true, -1.0, true)
			canvas.draw_arc(at, 18, 0, TAU, 24, MINT, 2.0, true)
		icon(equipped[i], at, 13)
	if combat.immunity > 1.15 and motion < 2:
		canvas.draw_rect(Rect2(2, 2, 356, 636), Color(0.99, 0.35, 0.35, 0.46), false, 5)

func heart(at: Vector2, full: bool) -> void:
	var tint := Color("f29491") if full else Color("685365")
	canvas.draw_circle(at + Vector2(-4, -3), 5, tint, true, -1.0, true)
	canvas.draw_circle(at + Vector2(4, -3), 5, tint, true, -1.0, true)
	Art.shape(canvas, PackedVector2Array([at + Vector2(-8, -1), at + Vector2(8, -1), at + Vector2(0, 9)]), tint)

func paint_intro() -> void:
	Art.box(canvas, Rect2(59, 454, 242, 68), Color("203f3a"), 18, MINT)
	center("수확 상점", 485, 27, PAPER)
	center("손가락으로 밀어요", 508, 15, MINT)
	if pointer != -2 and not MOTION_RECT.has_point(press_at):
		paint_stick(press_at, point - press_at)
		return
	var rise := 0.7 if motion == 2 else smoothstep(0.35, 1.2, fmod(animation, 2.0))
	var thumb := Vector2(0, -27 * rise)
	paint_stick(INTRO_STICK, thumb, true)
	finger(INTRO_STICK + thumb + Vector2(12, 8))

func paint_joystick() -> void:
	if pointer != -2 and not MOTION_RECT.has_point(press_at):
		paint_stick(press_at, point - press_at)

func paint_stick(at: Vector2, displacement: Vector2, guide := false) -> void:
	var radius := INTRO_STICK_RADIUS if guide else 33.0
	canvas.draw_circle(at, radius, Color(0.13, 0.25, 0.22, 0.65), true, -1.0, true)
	canvas.draw_arc(at, radius, 0, TAU, 36, MINT if guide else Color(1, 1, 0.9, 0.64), 2, true)
	if guide:
		canvas.draw_polyline(PackedVector2Array([at + Vector2(-9, -17), at + Vector2(0, -27),
			at + Vector2(9, -17)]), MINT, 3, true)
	canvas.draw_circle(at + displacement.limit_length(radius - 6), 11, PAPER, true, -1.0, true)

func finger(at: Vector2) -> void:
	canvas.draw_circle(at, 13, Color(1, 0.94, 0.76, 0.34), true, -1.0, true)
	Art.box(canvas, Rect2(at + Vector2(-2, -8), Vector2(11, 24)), PAPER, 6, OAK)
	Art.box(canvas, Rect2(at + Vector2(2, 6), Vector2(18, 14)), PAPER, 6, OAK)

func paint_offer(title: String, help: String, is_reward: bool) -> void:
	canvas.draw_rect(Rect2(-origin / scale_factor, get_viewport_rect().size / scale_factor), Color(0.10, 0.10, 0.16, 0.73))
	Art.box(canvas, Rect2(11, SHEET_TOP, 338, 223), Color("3a3458"), 20, GOLD if is_reward else MINT)
	center(title, 248, 27, GOLD if is_reward else PAPER)
	center(help, 272, 15, PAPER)
	for i in options.size():
		paint_card(options[i], card_rect(i, options.size(), 288), true)
	if is_reward:
		center("낮 방패   ·   밤 주스", 455, 18, PAPER)

func paint_card(card: int, rect: Rect2, available: bool, lifted := false) -> void:
	var accent := MINT if card < 10 else GOLD
	var x := rect.get_center().x
	Art.box(canvas, Rect2(rect.position + Vector2(0, 4), rect.size), Color("252239"), 13)
	Art.box(canvas, rect, Color("fff1d0") if available else Color("b4a7a7"), 13, accent if lifted else OAK)
	var picture := Vector2(x, rect.position.y + 44)
	if phase == Phase.UPGRADE and day_card_level == 0 and card in [Combat.WIDE, Combat.SPIN]:
		# Match the field's outline while leaving the saw readable at card size.
		picture.y -= 8.0
		var radius := 29.0 if card == Combat.WIDE else 23.0
		if card == Combat.WIDE:
			picture.x -= 8.0
		Combat.draw_cut_outline(canvas, picture, radius, 0.0, combat.cut_dot_after(card), Color("21634e"))
		icon(card, picture, 15)
	else:
		icon(card, picture, 25)
	center(card_name(card), rect.position.y + 82, 14, OAK, x)
	if phase == Phase.REWARD and card == Shop.EXTRA:
		center("별 과일 찾기", rect.position.y + 103, 12, Color("435856"), x)
	elif card >= 10:
		for i in Shop.cost(card):
			spark(Vector2(x + (i - (Shop.cost(card) - 1) * 0.5) * 15, rect.position.y + 100), 6, Color("bc6a37"))
	else:
		center(card_effect(card), rect.position.y + 103, 12, Color("435856"), x)

func icon(card: int, at: Vector2, radius: float) -> void:
	match card:
		Combat.WIDE:
			canvas.draw_texture_rect_region(Combat.HARVESTER_ATLAS,
				Rect2(at - Vector2(radius, radius * 0.55), Vector2(radius * 2, radius * 1.1)), Combat.SAW_FRAME)
		Combat.SPIN, Combat.GUARD:
			canvas.draw_texture_rect(spin_icon if card == Combat.SPIN else guard_icon, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2), false)
		Combat.HEART:
			heart(at + Vector2(-6, -2), true)
			spark(at + Vector2(12, -9), 8, Color("bc6a37"))
		Combat.BOUNTY:
			Art.fruit(canvas, at + Vector2(-9, 3), 0, radius / 23.0)
			Art.fruit(canvas, at + Vector2(10, -4), 1, radius / 23.0)
		Shop.JUICE:
			Art.cup(canvas, at, 0, radius / 15.0)
			spark(at + Vector2(15, -8), 7, Color("bc6a37"))
		Shop.MIX, Shop.EXTRA:
			Art.fruit(canvas, at + Vector2(-13, 7), 0, radius / 25.0)
			if card == Shop.EXTRA:
				paint_star_fruit(at + Vector2(13, 7), radius / 25.0)
			else:
				Art.fruit(canvas, at + Vector2(13, 7), 1, radius / 25.0)
			Art.cup(canvas, at - Vector2(0, 6), 2 if card == Shop.MIX else 3, radius / 21.0)
		Shop.HELP:
			Art.person(canvas, at + Vector2(0, 4), 3)
		Shop.GIFT:
			Art.coin(canvas, at, radius * 0.67)

func card_name(card: int) -> String:
	match card:
		Combat.WIDE: return "큰 톱날"
		Combat.SPIN: return "빙글 톱"
		Combat.HEART: return "튼튼 앞치마"
		Combat.BOUNTY: return "과일 한 줌"
		Combat.GUARD: return "폭신 방패"
		Shop.JUICE: return "빠른 착즙"
		Shop.MIX: return "섞어 주스"
		Shop.HELP: return "도우미"
		Shop.GIFT: return "팁 병"
		_: return "별빛 주스"

func card_effect(card: int) -> String:
	match card:
		Combat.WIDE: return "멀리 베기"
		Combat.SPIN: return "회전 범위 +" if combat.spins > 0 else "뒤도 베기"
		Combat.HEART: return "하트 +1"
		Combat.BOUNTY: return "과일 +1"
		_: return "한 번 막기"

func spark(at: Vector2, r: float, color: Color) -> void:
	Art.shape(canvas, PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.7, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.7, 0)]), color)

func paint_star_fruit(at: Vector2, size: float) -> void:
	Art.fruit(canvas, at, 1, size)
	Combat.draw_recipe_mark(canvas, at + Vector2(10, -21) * size, 7.0 * size)

func paint_shop(include_hand := true) -> void:
	var moving := hand_at_press >= 0 and pointer != -2 and point.distance_to(press_at) > 12.0
	var guide := opening_card() if include_hand and selected < 0 and not moving else -1
	var preview := hand_at_press if moving else selected
	if preview < 0:
		preview = guide
	var target := Shop.station(preview) if preview >= 0 and shop.can_play(preview) else -1
	art.paint(canvas, shop, animation, target)
	label("밤 %d" % day_number, 23, 51, 29, GOLD)
	Art.coin(canvas, Vector2(121, 42), 10)
	label(str(shop.cash), 138, 48, 20)
	Art.progress(canvas, Rect2(23, 61, 116, 7), 1.0 - shop.time / Shop.TOTAL)
	Art.fruit(canvas, Vector2(41, 105), 0, 0.73)
	label(str(shop.raw[0]), 54, 111, 16)
	Art.fruit(canvas, Vector2(105, 105), 1, 0.73)
	label(str(shop.raw[1]), 117, 111, 16)
	if shop.star_fruit:
		paint_star_fruit(Vector2(171, 105), 0.82)
	if not include_hand:
		return
	if target >= 0:
		var to := Art.STATIONS[target].get_center()
		var baton := Vector2(to.x, to.y - 88 + sin(animation * 6.0) * 6)
		Art.shape(canvas, PackedVector2Array([baton + Vector2(-11, -3), baton + Vector2(11, -3), baton + Vector2(0, 11)]), GOLD)
		if guide < 0:
			center("빛나는 곳에 놓아요", 455, 18, PAPER)
		else:
			center("손님을 눌러도 열려요", 455, 19, PAPER)
	elif rejected > 0.0:
		center("과일과 별을 확인해요", 455, 18, Color("f7a3a2"))
	elif not shop.opened:
		center("손님을 눌러 가게를 열어요", 455, 19, PAPER)
	elif shop.time >= Shop.TOTAL:
		center("마지막 주스를 팔아요", 455, 18, PAPER)
	else:
		center("손님에게 주스가 가요", 455, 18, PAPER)
	for i in range(2):
		spark(Vector2(173 + i * 15, 472), 7, GOLD if i < shop.energy else Color("67607f"))
	for i in shop.hands.size():
		var card := shop.hands[i]
		if moving and card == hand_at_press:
			continue
		paint_card(card, card_rect(i, shop.hands.size(), 491), shop.can_play(card), card in [selected, guide])
	if guide >= 0:
		var card := card_rect(shop.hands.find(guide), shop.hands.size(), 491)
		var station := Art.STATIONS[target]
		var cycle := fmod(animation, 2.4)
		var slide := smoothstep(0.55, 1.60, cycle) if motion < 2 else 0.0
		finger((card.get_center() + Vector2(27, 21)).lerp(station.get_center() + Vector2(27, 12), slide))
	elif selected >= 0 and target >= 0 and not shop.opened and not moving:
		finger(Art.STATIONS[target].get_center() + Vector2(27, 12))
	if moving:
		paint_card(hand_at_press, Rect2(point - Vector2(OPTION_W / 2, OPTION_H - 17), Vector2(OPTION_W, OPTION_H)), shop.can_play(hand_at_press), true)

func paint_score() -> void:
	Art.box(canvas, Rect2(23, 153, 314, 379), Color("423858"), 22, GOLD)
	center("오늘도 문 닫았어요!", 205, 25)
	canvas.draw_texture_rect(stall, Rect2(108, 218, 144, 119), false)
	Art.coin(canvas, Vector2(121, 359), 13)
	label(str(total_cash), 144, 367, 25)
	Art.cup(canvas, Vector2(213, 357), 0, 0.82)
	label(str(total_sold), 230, 367, 25)
	center("이틀 동안 번 돈과 판 주스", 394, 15)
	Art.box(canvas, Rect2(110, 414, 140, 104), Color("356055"), 17, MINT)
	canvas.draw_arc(Vector2(180, 451), 17, -0.4, TAU - 1.1, 26, MINT, 4, true)
	Art.shape(canvas, PackedVector2Array([Vector2(186, 429), Vector2(199, 439), Vector2(186, 443)]), MINT)
	center("다시 열기", 497, 18)

func paint_settings_icon() -> void:
	Art.box(canvas, MOTION_RECT, Color(0.12, 0.16, 0.24, 0.8), 16)
	for x in [321, 331]:
		canvas.draw_line(Vector2(x, 37), Vector2(x, 52), PAPER, 4, true)

func paint_settings() -> void:
	canvas.draw_rect(Rect2(-origin / scale_factor, get_viewport_rect().size / scale_factor), Color(0.10, 0.10, 0.16, 0.77))
	Art.box(canvas, Rect2(47, 206, 266, 225), Color("3a3458"), 25, MINT)
	center("잠깐 쉬어요", 254, 27)
	Art.shape(canvas, PackedVector2Array([Vector2(168, 271), Vector2(168, 312), Vector2(202, 291)]), MINT)
	center("누르면 계속", 334, 16)
	Art.box(canvas, Rect2(84, 347, 192, 66), Color("315a52"), 15)
	center(["흔들림 보통", "흔들림 약하게", "흔들림 끄기"][motion], 388, 18)
