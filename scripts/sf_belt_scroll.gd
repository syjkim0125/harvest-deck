extends Node2D
## SF pivot: playable, portrait-first belt-scroll combat experiment A.
## The old fruit game remains in legacy/harvest-deck-v0.8.11.
const FONT = preload("res://assets/market-sans.otf")
const SIZE := Vector2(360, 640)
const FIELD := Rect2(22, 282, 316, 208)
const INK := Color("#0b1029")
const CLOUD := Color("#171b3e")
const LILAC := Color("#aca5ff")
const ICE := Color("#83f7ec")
const GOLD := Color("#ffd886")
const CORAL := Color("#ff647e")
const WHITE := Color("#f0f2ff")
const STRIKE_POS := Vector2(291, 559)
const DODGE_POS := Vector2(68, 559)

enum Mode { INTRO, COMBAT, CLEAR, DEFEAT }
var mode := Mode.INTRO
var hero := Vector2(90, 396)
var facing := 1
var health := 5
var scraps := 0
var combo := 0
var wave := 1
var elapsed := 0.0
var attack_cd := 0.0
var attack_fx := 0.0
# Only a confirmed contact briefly freezes combat; a missed swing never does.
var impact_pause := 0.0
var impact_fx := 0.0
var impact_pos := Vector2.ZERO
var invulnerable := 0.0
var dodge_fx := 0.0
var hit_fx := 0.0
var shake := 0.0
var next_wave := -1.0
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var touch_id := -1
var touch_start := Vector2.ZERO
var touch_age := 0.0
var move_axis := Vector2.ZERO
var layout_scale := 1.0
var layout_origin := Vector2.ZERO
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 20261125
	get_viewport().size_changed.connect(resize)
	resize()

func resize() -> void:
	var screen := get_viewport_rect().size
	layout_scale = minf(screen.x / SIZE.x, screen.y / SIZE.y)
	layout_origin = (screen - SIZE * layout_scale) / 2.0
	queue_redraw()

func screen_to_game(point: Vector2) -> Vector2:
	return (point - layout_origin) / maxf(layout_scale, 0.001)

func start_run() -> void:
	mode = Mode.COMBAT
	hero = Vector2(90, 396)
	facing = 1
	health = 5
	scraps = 0
	combo = 0
	wave = 1
	elapsed = 0.0
	attack_cd = 0.0
	invulnerable = 0.0
	attack_fx = 0.0
	impact_pause = 0.0
	impact_fx = 0.0
	impact_pos = Vector2.ZERO
	hit_fx = 0.0
	dodge_fx = 0.0
	next_wave = -1.0
	touch_id = -1
	move_axis = Vector2.ZERO
	particles.clear()
	spawn_wave()

func spawn_wave() -> void:
	enemies.clear()
	next_wave = -1.0
	if wave == 1:
		enemies.append(make_enemy(0, Vector2(264, 395), 3))
		enemies.append(make_enemy(1, Vector2(304, 342), 3))
	else:
		enemies.append(make_enemy(2, Vector2(279, 386), 8))

func make_enemy(kind: int, position: Vector2, hp: int) -> Dictionary:
	return {
		"kind": kind,
		"pos": position,
		"hp": hp,
		"max_hp": hp,
		"cooldown": 0.65 + float(kind) * 0.25,
		"telegraph": 0.0,
		"target": position,
		"flash": 0.0,
		"stagger": 0.0
	}

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	# A very short contact pause keeps the impact readable without delaying the input itself.
	# It freezes enemies, the player, attack cooldowns and impact particles together.
	if mode == Mode.COMBAT and impact_pause > 0.0:
		impact_pause = maxf(impact_pause - dt, 0.0)
		queue_redraw()
		return
	elapsed += dt
	attack_cd = maxf(attack_cd - dt, 0.0)
	attack_fx = maxf(attack_fx - dt, 0.0)
	impact_fx = maxf(impact_fx - dt, 0.0)
	hit_fx = maxf(hit_fx - dt, 0.0)
	dodge_fx = maxf(dodge_fx - dt, 0.0)
	invulnerable = maxf(invulnerable - dt, 0.0)
	shake = maxf(shake - dt * 25.0, 0.0)
	if touch_id >= 0 or touch_id == -2:
		touch_age += dt
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p["life"] = float(p["life"]) - dt
		var pos: Vector2 = p["pos"]
		var velocity: Vector2 = p["vel"]
		p["pos"] = pos + velocity * dt
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
	if mode == Mode.COMBAT:
		var motion := move_axis
		if touch_id == -1:
			motion = Vector2(
				float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
				float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
			)
		if motion.length_squared() > 0.001:
			move_hero(motion.normalized() * 146.0 * dt)
		advance_enemies(dt)
		if next_wave >= 0.0:
			next_wave -= dt
			if next_wave < 0.0:
				if wave == 1:
					wave = 2
					spawn_wave()
				else:
					mode = Mode.CLEAR
	queue_redraw()

func move_hero(offset: Vector2) -> void:
	hero += offset
	hero.x = clampf(hero.x, FIELD.position.x + 12.0, FIELD.end.x - 12.0)
	hero.y = clampf(hero.y, FIELD.position.y + 30.0, FIELD.end.y - 22.0)
	if absf(offset.x) > 0.05:
		facing = 1 if offset.x > 0.0 else -1

func advance_enemies(dt: float) -> void:
	for e in enemies:
		e["flash"] = maxf(float(e["flash"]) - dt, 0.0)
		e["stagger"] = maxf(float(e["stagger"]) - dt, 0.0)
		if float(e["stagger"]) > 0.0:
			continue
		if float(e["telegraph"]) > 0.0:
			e["telegraph"] = float(e["telegraph"]) - dt
			if float(e["telegraph"]) <= 0.0:
				enemy_attack(e)
			continue
		e["cooldown"] = maxf(float(e["cooldown"]) - dt, 0.0)
		var pos: Vector2 = e["pos"]
		var toward := hero - pos
		var reach := 62.0 if int(e["kind"]) != 1 else 139.0
		if toward.length() > reach:
			var speed := 48.0 if int(e["kind"]) == 0 else 34.0
			if int(e["kind"]) == 2:
				speed = 39.0
			pos += toward.normalized() * speed * dt
			pos.x = clampf(pos.x, FIELD.position.x + 12.0, FIELD.end.x - 12.0)
			pos.y = clampf(pos.y, FIELD.position.y + 30.0, FIELD.end.y - 22.0)
			e["pos"] = pos
		elif float(e["cooldown"]) <= 0.0:
			# The warning locks a location. Moving/dodging out avoids damage.
			e["target"] = hero
			e["telegraph"] = 0.90 if int(e["kind"]) == 2 else 0.72
			e["cooldown"] = 1.35 if int(e["kind"]) == 0 else 1.65

func enemy_attack(e: Dictionary) -> void:
	var target: Vector2 = e["target"]
	burst(target, CORAL, 7)
	if hero.distance_to(target) < (52.0 if int(e["kind"]) == 2 else 42.0):
		if invulnerable <= 0.0:
			health -= 2 if int(e["kind"]) == 2 else 1
			invulnerable = 0.65
			hit_fx = 0.28
			shake = 4.0
			combo = 0
			if health <= 0:
				health = 0
				mode = Mode.DEFEAT

func strike() -> void:
	if mode != Mode.COMBAT or attack_cd > 0.0 or next_wave >= 0.0:
		return
	attack_cd = 0.34
	attack_fx = 0.16
	var landed := 0
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		var pos: Vector2 = e["pos"]
		var direction := pos - hero
		if absf(direction.x) <= 89.0 and absf(direction.y) <= 47.0 and direction.x * float(facing) >= -9.0:
			landed += 1
			e["hp"] = int(e["hp"]) - 1
			e["flash"] = 0.16
			e["stagger"] = 0.22
			# Knockback is directional but stays inside the playable belt.
			e["pos"] = Vector2(
				clampf(pos.x + float(facing) * 22.0, FIELD.position.x + 12.0, FIELD.end.x - 12.0),
				clampf(pos.y - 5.0, FIELD.position.y + 30.0, FIELD.end.y - 22.0)
			)
			burst(pos, ICE, 9)
			impact_pos = pos
			impact_fx = 0.16
			shake = 3.0
			if int(e["hp"]) <= 0:
				scraps += 3 if int(e["kind"]) == 2 else 1
				burst(pos, GOLD, 14)
				enemies.remove_at(i)
	combo = mini(combo + 1, 9) if landed > 0 else 0
	if landed > 0:
		impact_pause = 0.055
	if enemies.is_empty() and next_wave < 0.0:
		next_wave = 0.86

func dodge(direction: Vector2) -> void:
	if mode != Mode.COMBAT or dodge_fx > 0.0:
		return
	var axis := direction.normalized()
	if axis.length_squared() < 0.1:
		axis = Vector2(float(facing), 0.0)
	move_hero(axis * 75.0)
	invulnerable = maxf(invulnerable, 0.32)
	dodge_fx = 0.50
	burst(hero, LILAC, 10)

func burst(where: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle := random.randf_range(-PI, PI)
		var speed := random.randf_range(48.0, 146.0)
		particles.append({
			"pos": where,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": random.randf_range(0.15, 0.38),
			"color": color
		})

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var point := screen_to_game(event.position)
		if event.pressed:
			begin_touch(event.index, point)
		else:
			end_touch(event.index, point)
	elif event is InputEventScreenDrag and event.index == touch_id:
		drag_touch(screen_to_game(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point := screen_to_game(event.position)
		if event.pressed:
			begin_touch(-2, point)
		else:
			end_touch(-2, point)
	elif event is InputEventMouseMotion and touch_id == -2:
		drag_touch(screen_to_game(event.position))
	elif event is InputEventKey and event.pressed and not event.echo:
		if mode != Mode.COMBAT and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			start_run()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_J:
			strike()
		elif event.keycode == KEY_SHIFT or event.keycode == KEY_K:
			dodge(Vector2(float(facing), 0.0))

func begin_touch(id: int, point: Vector2) -> void:
	if mode != Mode.COMBAT:
		start_run()
		return
	if point.distance_to(STRIKE_POS) < 45.0:
		strike()
		return
	if point.distance_to(DODGE_POS) < 45.0:
		dodge(Vector2(float(facing), 0.0))
		return
	touch_id = id
	touch_start = point
	touch_age = 0.0
	move_axis = Vector2.ZERO

func drag_touch(point: Vector2) -> void:
	if touch_id == -1:
		return
	move_axis = ((point - touch_start) / 46.0).limit_length(1.0)

func end_touch(id: int, point: Vector2) -> void:
	if id != touch_id:
		return
	var direction := point - touch_start
	if mode == Mode.COMBAT:
		if direction.length() > 54.0 and touch_age < 0.26:
			dodge(direction)
		elif direction.length() < 13.0:
			if point.x < hero.x - 24.0:
				facing = -1
			elif point.x > hero.x + 24.0:
				facing = 1
			strike()
	touch_id = -1
	move_axis = Vector2.ZERO

func draw_text(label: String, at: Vector2, font_size: int, tint: Color) -> void:
	draw_string(FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

func _draw() -> void:
	var jitter := Vector2.ZERO
	if shake > 0.0:
		jitter = Vector2(random.randf_range(-shake, shake), random.randf_range(-shake, shake))
	draw_set_transform(layout_origin + jitter * layout_scale, 0.0, Vector2.ONE * layout_scale)
	paint_world()
	if mode == Mode.INTRO:
		paint_title()
	else:
		paint_game()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func paint_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), INK)
	draw_rect(Rect2(0, 75, 360, 215), CLOUD)
	draw_circle(Vector2(279, 123), 69, Color("#33365c"))
	draw_circle(Vector2(279, 123), 52, Color("#776eac"))
	draw_circle(Vector2(273, 112), 43, Color("#9f94d1"))
	for i in range(40):
		var x := float((i * 73 + 31) % 346) + 7.0
		var y := float((i * 61 + 13) % 238) + 22.0
		draw_circle(Vector2(x, y), 1.2 if i % 5 else 2.2, Color("#d4d6fd", 0.5))
	for i in range(7):
		var x := float(i * 61 - 30)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 22, 288), Vector2(x + 16, 202 + (i % 3) * 21),
			Vector2(x + 61, 289)]), Color("#25294b"))
	draw_rect(Rect2(0, 285, 360, 206), Color("#333b65"))
	draw_rect(Rect2(0, 302, 360, 187), Color("#353e66"))
	for i in range(4):
		var y := 320.0 + float(i) * 53.0
		draw_line(Vector2(8, y), Vector2(352, y), Color("#67658b", 0.34), 1.5)
	for i in range(6):
		var x := float(i) * 78.0 - 25.0
		draw_line(Vector2(x, 491), Vector2(x + 75, 314), Color("#777099", 0.19), 1.0)
	for i in range(5):
		var p := Vector2(24 + float(i * 75), 316 + float((i * 29) % 161))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-8, 7), p + Vector2(-2, -21), p + Vector2(9, 5)
		]), Color("#6cf2df", 0.3))
	draw_rect(Rect2(0, 495, 360, 145), Color("#11162c"))
	draw_line(Vector2(0, 495), Vector2(360, 495), Color("#58688d"), 2.0)

func paint_title() -> void:
	draw_rect(Rect2(12, 31, 336, 42), Color("#11172e", 0.75))
	draw_text("PROTOTYPE 01  /  BELT-SCROLL", Vector2(27, 58), 13, ICE)
	draw_circle(Vector2(166, 355), 78, Color("#1d294a", 0.7))
	draw_colored_polygon(PackedVector2Array([
		Vector2(164, 263), Vector2(228, 348), Vector2(184, 375),
		Vector2(165, 369), Vector2(146, 375), Vector2(105, 348)
	]), Color("#d2d0fb"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(164, 285), Vector2(190, 346), Vector2(164, 342), Vector2(139, 346)
	]), ICE)
	draw_circle(Vector2(164, 348), 16, Color("#1c2342"))
	draw_circle(Vector2(164, 348), 7, GOLD)
	draw_text("VOID CARAVAN", Vector2(31, 160), 34, WHITE)
	draw_text("HUNT  /  SALVAGE  /  RETURN", Vector2(33, 188), 14, LILAC)
	draw_text("ALIEN FRONTIER", Vector2(97, 474), 17, ICE)
	draw_rect(Rect2(47, 528, 266, 67), Color("#4adaca"))
	draw_text("TAP TO LAND", Vector2(90, 571), 26, INK)

func paint_game() -> void:
	draw_rect(Rect2(8, 9, 344, 72), Color("#10162f", 0.9))
	draw_text("SECTOR 07    /    TITAN MOON", Vector2(20, 30), 14, ICE)
	for i in range(5):
		draw_circle(Vector2(27 + i * 22, 54), 7, CORAL if i < health else Color("#35334b"))
	draw_text("SCRAP  %02d" % scraps, Vector2(228, 59), 18, GOLD)
	draw_text("WAVE  %d / 2" % wave, Vector2(20, 111), 15, WHITE)
	if combo > 1 and mode == Mode.COMBAT:
		draw_text("%d HIT COMBO" % combo, Vector2(219, 111), 16, ICE)
	for e in enemies:
		paint_enemy(e)
	paint_hero()
	for p in particles:
		draw_circle(p["pos"], 2.2 + float(p["life"]) * 4.0, p["color"])
	if impact_fx > 0.0:
		# The radial contact spark only appears on a real hit, not an empty swing.
		var ring_radius := 8.0 + (0.16 - impact_fx) * 100.0
		draw_arc(impact_pos, ring_radius, 0.0, TAU, 24, GOLD, 3.0, true)
		for spark in range(6):
			var ray := Vector2.RIGHT.rotated(float(spark) * TAU / 6.0)
			draw_line(impact_pos + ray * (ring_radius + 3.0), impact_pos + ray * (ring_radius + 13.0), WHITE, 2.0)
	if attack_fx > 0.0:
		var attack_point := hero + Vector2(float(facing) * 45.0, -9.0)
		draw_arc(attack_point, 47.0, -1.1 if facing == 1 else 2.0, 1.1 if facing == 1 else 4.2, 17, WHITE, 7.0, true)
		draw_arc(attack_point, 38.0, -1.15 if facing == 1 else 2.0, 1.15 if facing == 1 else 4.3, 17, ICE, 4.0, true)
	if mode == Mode.COMBAT:
		draw_text("DRAG  MOVE    TAP  STRIKE    FLICK  EVADE", Vector2(25, 514), 10, Color("#c8d0e9"))
		paint_action(DODGE_POS, LILAC, "EVADE", false)
		paint_action(STRIKE_POS, ICE, "STRIKE", true)
		draw_text("WASD  /  SPACE  /  SHIFT", Vector2(93, 631), 10, Color("#777eaa"))
	elif mode == Mode.CLEAR:
		paint_result(true)
	elif mode == Mode.DEFEAT:
		paint_result(false)

func paint_enemy(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var kind: int = e["kind"]
	var radius := 22.0 if kind == 2 else 15.0
	var c := CORAL if kind != 1 else GOLD
	if float(e["telegraph"]) > 0.0:
		var target: Vector2 = e["target"]
		draw_circle(target, 46.0 if kind == 2 else 37.0, Color("#ff5970", 0.17))
		draw_arc(target, 46.0 if kind == 2 else 37.0, 0.0, TAU, 38, CORAL, 3.0, true)
		draw_line(p, target, Color("#f87b89", 0.75), 2.0)
	draw_circle(p + Vector2(0, 14), radius + 5.0, Color("#111327", 0.58))
	draw_circle(p, radius + 4.0, Color("#242241"))
	draw_circle(p, radius, WHITE if float(e["flash"]) > 0.0 else c)
	draw_circle(p + Vector2(-6, -4), 4.5, INK)
	draw_circle(p + Vector2(6, -4), 4.5, INK)
	draw_circle(p + Vector2(-5, -4), 1.7, WHITE)
	draw_circle(p + Vector2(7, -4), 1.7, WHITE)
	draw_line(p + Vector2(-3, 7), p + Vector2(4, 8), INK, 2.0)
	if kind == 2:
		for a in [-2, 0, 2]:
			draw_line(p + Vector2(float(a) * 8.0, -18), p + Vector2(float(a) * 13.0, -34), GOLD, 5.0)
	draw_rect(Rect2(p.x - 22, p.y - radius - 16, 44, 4), INK)
	draw_rect(Rect2(p.x - 22, p.y - radius - 16, 44.0 * float(e["hp"]) / float(e["max_hp"]), 4), ICE)

func paint_hero() -> void:
	var alpha := 0.45 if invulnerable > 0.0 and int(elapsed * 18.0) % 2 == 0 else 1.0
	draw_circle(hero + Vector2(0, 19), 20, Color("#0b122b", 0.65))
	draw_circle(hero + Vector2(0, 0), 19, Color("#121b37", alpha))
	draw_circle(hero + Vector2(0, -4), 15, Color("#c3befb", alpha))
	draw_rect(Rect2(hero.x - 11, hero.y + 9, 22, 13), Color("#555d91", alpha))
	draw_rect(Rect2(hero.x - 12, hero.y - 6, 24, 12), Color("#263452", alpha))
	draw_rect(Rect2(hero.x - 7, hero.y - 4, 14, 7), Color("#9ef9ec", alpha))
	draw_circle(hero + Vector2(float(facing) * 11, 11), 6, GOLD)
	draw_line(hero + Vector2(float(facing) * 9, 10), hero + Vector2(float(facing) * 30, 8), WHITE, 5.0)
	if hit_fx > 0.0:
		draw_arc(hero, 27, 0.0, TAU, 32, CORAL, 4.0)
	if dodge_fx > 0.0:
		draw_arc(hero, 26, 0.0, TAU, 32, LILAC, 2.0)

func paint_action(p: Vector2, color: Color, title: String, attack: bool) -> void:
	draw_circle(p, 39, Color("#283456"))
	draw_arc(p, 38, 0.0, TAU, 45, color, 2.5, true)
	if attack:
		draw_line(p + Vector2(-15, 10), p + Vector2(14, -18), color, 7.0, true)
		draw_line(p + Vector2(3, -17), p + Vector2(14, -18), WHITE, 4.0)
	else:
		draw_line(p + Vector2(-16, -2), p + Vector2(13, -2), color, 6.0)
		draw_line(p + Vector2(4, -12), p + Vector2(14, -2), color, 5.0)
		draw_line(p + Vector2(4, 8), p + Vector2(14, -2), color, 5.0)
	draw_text(title, p + Vector2(-23, 58), 12, color)

func paint_result(won: bool) -> void:
	draw_rect(Rect2(14, 304, 332, 176), Color("#11172f", 0.94))
	draw_text("SALVAGE SECURED" if won else "SIGNAL LOST", Vector2(31, 352), 26, ICE if won else CORAL)
	draw_text("SCRAP RECOVERED   %d" % scraps, Vector2(41, 392), 17, GOLD)
	draw_text("TAP TO REDEPLOY", Vector2(57, 453), 23, WHITE)
	draw_text("SHIP WORKSHOP: NEXT MILESTONE", Vector2(47, 563), 13, LILAC)
