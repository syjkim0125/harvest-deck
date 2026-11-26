extends Node2D
## SF pivot: playable, portrait-first belt-scroll combat experiment A.
## The old fruit game remains in legacy/harvest-deck-v0.8.11.
const NOOLI = preload("res://assets/gameplay/nooli.svg")
const MANTIS = preload("res://assets/gameplay/amber_mantis.svg")
const VEILWOOD = preload("res://assets/gameplay/veilwood_stage.svg")
const VEILWOOD_FORE = preload("res://assets/gameplay/veilwood_foreground.svg")
const EXPLORER = preload("res://assets/gameplay/explorer_motion.svg")
const ROCK_ART = preload("res://assets/gameplay/veilwood_rock.svg")
const COMBAT_CUES = preload("res://assets/gameplay/combat_cues.svg")
const FONT = preload("res://assets/market-sans.otf")
const GALAXY_SIM = preload("res://scripts/sf_galaxy_sim.gd")
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
const REFUGE := Vector2(99, 392)
const QUARRY := Vector2(289, 383)
const LANDING := Vector2(180, 440)
const ROCK := Vector2(184, 391)
const ROCK_RADIUS := 23.0
const CACHE := Vector2(180, 325)
const LANDING_RADIUS := 24.0

enum Mode { INTRO, COMBAT, CLEAR, DEFEAT, CAPTAIN, STARSHIP, GALAXY, EXPLORE }
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
# The civilian captain's journey persists across individual combat expeditions.
var galaxy = GALAXY_SIM.new()
var campaign_started := false
var captain_choice := 0
var ship_choice := 0
var active_sector := 0
var mission_notice := ""
var expedition_route := ""
var last_expedition_route := ""
var rescue_pending := false
var nooli_recruited := false
var buddy_pos := REFUGE
var attack_landed := false
var refuge_seen := false
var quarry_seen := false
var cache_found := false
var learned_move := false
var learned_attack := false
var learned_evade := false
var escort_trail: Array[Vector2] = []
var fallen: Array[Dictionary] = []
var contact_count := 0
var impact_audio: AudioStreamPlayer
var contact_sound: AudioStreamWAV
var heavy_sound: AudioStreamWAV

func _ready() -> void:
	random.seed = 20261125
	get_viewport().size_changed.connect(resize)
	resize()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	impact_audio = AudioStreamPlayer.new()
	add_child(impact_audio)
	contact_sound = make_impact_sound(false)
	heavy_sound = make_impact_sound(true)

func _exit_tree() -> void:
	if impact_audio != null:
		impact_audio.stop()
		impact_audio.stream = null
	contact_sound = null
	heavy_sound = null

func make_impact_sound(heavy: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := int(float(rate) * (0.13 if heavy else 0.085))
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var envelope := exp(-t * (34.0 if heavy else 52.0))
		var signal_value := sin(TAU * (115.0 if heavy else 185.0) * t) * 0.65 + sin(TAU * 870.0 * t) * 0.20 * exp(-t * 75.0)
		pcm.encode_s16(i * 2, int(clampf(signal_value * envelope, -1.0, 1.0) * 13000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	return stream

func play_contact(heavy: bool) -> void:
	contact_count += 1
	if impact_audio != null:
		impact_audio.stream = heavy_sound if heavy else contact_sound
		impact_audio.play()

func resize() -> void:
	var screen := get_viewport_rect().size
	layout_scale = minf(screen.x / SIZE.x, screen.y / SIZE.y)
	layout_origin = (screen - SIZE * layout_scale) / 2.0
	queue_redraw()

func screen_to_game(point: Vector2) -> Vector2:
	return (point - layout_origin) / maxf(layout_scale, 0.001)

func start_campaign() -> void:
	galaxy = GALAXY_SIM.new()
	expedition_route = ""
	last_expedition_route = ""
	nooli_recruited = false
	rescue_pending = false
	learned_move = false
	learned_attack = false
	learned_evade = false
	campaign_started = true
	mode = Mode.CAPTAIN
	queue_redraw()

func choose_captain(choice: int) -> void:
	captain_choice = clampi(choice, 0, 1)
	mode = Mode.STARSHIP
	queue_redraw()

func choose_starship(choice: int) -> void:
	ship_choice = clampi(choice, 0, 1)
	galaxy.fuel = 6 if ship_choice == 0 else 5
	mode = Mode.GALAXY
	queue_redraw()

func jump_to_system(index: int) -> bool:
	var result: Dictionary = galaxy.travel_to(index)
	if not result["ok"]:
		return false
	active_sector = index
	mission_notice = String(result["event"])
	start_run()
	mode = Mode.EXPLORE
	hero = LANDING
	enemies.clear()
	return true

func finish_expedition(won: bool) -> void:
	if mode == Mode.GALAXY or (rescue_pending and mode != Mode.CLEAR and won):
		return
	last_expedition_route = expedition_route
	galaxy.finish_expedition(scraps, won)
	if won and rescue_pending:
		nooli_recruited = true
	rescue_pending = false
	escort_trail.clear()
	fallen.clear()
	mode = Mode.GALAXY
	enemies.clear()
	particles.clear()
	impact_pause = 0.0
	queue_redraw()

func start_run() -> void:
	mode = Mode.COMBAT
	expedition_route = ""
	rescue_pending = false
	buddy_pos = REFUGE
	refuge_seen = false
	quarry_seen = false
	cache_found = false
	escort_trail.clear()
	fallen.clear()
	contact_count = 0
	attack_landed = false
	hero = Vector2(90, 396)
	facing = 1
	health = 5 + (1 if campaign_started and captain_choice == 0 else 0) + (1 if campaign_started and ship_choice == 1 else 0)
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
	if impact_audio != null:
		impact_audio.stop()
		impact_audio.stream = null
	spawn_wave()

func spawn_wave() -> void:
	enemies.clear()
	next_wave = -1.0
	var danger: int = int(galaxy.systems[active_sector]["risk"]) if campaign_started else 0
	if wave == 1:
		enemies.append(make_enemy(0, Vector2(264, 395), 3 + danger))
		enemies.append(make_enemy(1, Vector2(304, 342), 3 + danger))
	else:
		enemies.append(make_enemy(2, Vector2(279, 386), 8 + danger * 2))

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
		"stagger": 0.0,
		"recovery": 0.0
	}

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	# Gesture duration must advance even during a contact pause.
	if touch_id != -1:
		touch_age += delta
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
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p["life"] = float(p["life"]) - dt
		var pos: Vector2 = p["pos"]
		var velocity: Vector2 = p["vel"]
		p["pos"] = pos + velocity * dt
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
	if mode == Mode.COMBAT or mode == Mode.EXPLORE:
		var motion := move_axis
		if touch_id == -1:
			motion = Vector2(
				float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
				float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
			)
		if motion.length_squared() > 0.001:
			move_hero(motion.normalized() * 146.0 * dt)
		if mode == Mode.EXPLORE and rescue_pending:
			advance_escort(dt)
		if mode != Mode.COMBAT:
			queue_redraw()
			return
		advance_enemies(dt)
		for i in range(fallen.size() - 1, -1, -1):
			fallen[i]["life"] = float(fallen[i]["life"]) - dt
			if float(fallen[i]["life"]) <= 0.0:
				fallen.remove_at(i)
		if next_wave >= 0.0:
			next_wave -= dt
			if next_wave < 0.0:
				if wave == 1:
					wave = 2
					spawn_wave()
				else:
					mode = Mode.CLEAR
	queue_redraw()

func clamp_field(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, FIELD.position.x + 12.0, FIELD.end.x - 12.0), clampf(p.y, FIELD.position.y + 30.0, FIELD.end.y - 22.0))

func terrain_move(from: Vector2, offset: Vector2) -> Vector2:
	# Substep long input so a flick cannot tunnel through the standing stone.
	var steps := maxi(1, int(ceil(offset.length() / 5.0)))
	var p := from
	for i in range(steps):
		var next := clamp_field(p + offset / float(steps))
		var away := next - ROCK
		if away.length() < ROCK_RADIUS:
			if away.length_squared() < 0.001:
				away = p - ROCK
			if away.length_squared() < 0.001:
				away = Vector2.DOWN
			next = clamp_field(ROCK + away.normalized() * ROCK_RADIUS)
		p = next
	return p

func discover_nearby() -> void:
	if not refuge_seen and hero.distance_to(REFUGE) < 57.0:
		refuge_seen = true
		burst(REFUGE, ICE, 6)
	if not quarry_seen and hero.distance_to(QUARRY) < 62.0:
		quarry_seen = true
	if not cache_found and hero.distance_to(CACHE) < 16.0:
		cache_found = true
		scraps += 2
		burst(CACHE, GOLD, 12)

func advance_escort(dt: float) -> void:
	# Follow the traveled path rather than cutting across the stone.
	var target := hero
	if not escort_trail.is_empty():
		target = escort_trail[0]
	buddy_pos = terrain_move(buddy_pos, target - buddy_pos if buddy_pos.distance_to(target) <= 125.0 * dt else (target - buddy_pos).normalized() * 125.0 * dt)
	if not escort_trail.is_empty() and buddy_pos.distance_to(target) < 6.0:
		escort_trail.pop_front()
	if hero.distance_to(LANDING) < LANDING_RADIUS and buddy_pos.distance_to(LANDING) < LANDING_RADIUS:
		touch_id = -1
		move_axis = Vector2.ZERO
		mode = Mode.CLEAR

func move_hero(offset: Vector2) -> void:
	var old := hero
	hero = terrain_move(hero, offset) if mode == Mode.EXPLORE else clamp_field(hero + offset)
	if hero.distance_to(old) > 0.5:
		learned_move = true
	if absf(offset.x) > 0.05:
		facing = 1 if offset.x > 0.0 else -1
	if mode != Mode.EXPLORE:
		return
	discover_nearby()
	if rescue_pending:
		if escort_trail.is_empty() or escort_trail.back().distance_to(hero) > 9.0:
			escort_trail.append(hero)
		# Arrival is decided in advance_escort, including while player is stationary.
		return
	if refuge_seen and hero.distance_to(REFUGE) < 25.0:
		expedition_route = "Nooli refuge"
		scraps += 2
		rescue_pending = true
		buddy_pos = REFUGE
		escort_trail.clear()
		escort_trail.append(hero)
		touch_id = -1
		move_axis = Vector2.ZERO
		burst(REFUGE, ICE, 14)
	elif quarry_seen and hero.distance_to(QUARRY) < 25.0:
		expedition_route = "Amber quarry"
		touch_id = -1
		move_axis = Vector2.ZERO
		mode = Mode.COMBAT
		spawn_wave()

func advance_enemies(dt: float) -> void:
	for e in enemies:
		e["flash"] = maxf(float(e["flash"]) - dt, 0.0)
		e["stagger"] = maxf(float(e["stagger"]) - dt, 0.0)
		e["recovery"] = maxf(float(e["recovery"]) - dt, 0.0)
		if float(e["stagger"]) > 0.0 or float(e["recovery"]) > 0.0:
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
	e["recovery"] = 0.30
	if hero.distance_to(target) < (52.0 if int(e["kind"]) == 2 else 42.0):
		if invulnerable <= 0.0:
			burst(hero, CORAL, 7)
			play_contact(true)
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
	learned_attack = true
	attack_cd = 0.34
	attack_fx = 0.16
	var landed := 0
	var heavy := false
	attack_landed = false
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		var pos: Vector2 = e["pos"]
		var direction := pos - hero
		if absf(direction.x) <= 89.0 and absf(direction.y) <= 47.0 and direction.x * float(facing) >= -9.0:
			landed += 1
			e["hp"] = int(e["hp"]) - 1
			e["flash"] = 0.16
			e["stagger"] = 0.22
			e["telegraph"] = 0.0
			e["recovery"] = 0.30
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
				heavy = true
				scraps += (3 if int(e["kind"]) == 2 else 1) + (1 if campaign_started and captain_choice == 1 else 0)
				burst(pos, GOLD, 14)
				fallen.append({"pos": e["pos"], "kind": e["kind"], "life": 0.40, "direction": facing})
				enemies.remove_at(i)
	combo = mini(combo + 1, 9) if landed > 0 else 0
	if landed > 0:
		attack_landed = true
		impact_pause = 0.095 if heavy else 0.055
		shake = 5.0 if heavy else 3.0
		play_contact(heavy)
	if enemies.is_empty() and next_wave < 0.0:
		next_wave = 0.86

func dodge(direction: Vector2) -> void:
	if mode != Mode.COMBAT or dodge_fx > 0.0:
		return
	var axis := direction.normalized()
	if axis.length_squared() < 0.1:
		axis = Vector2(float(facing), 0.0)
	learned_evade = true
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
			match mode:
				Mode.INTRO:
					start_campaign()
				Mode.CAPTAIN:
					choose_captain(0)
				Mode.STARSHIP:
					choose_starship(0)
				Mode.GALAXY:
					for destination in galaxy.systems[galaxy.current_system]["routes"]:
						if jump_to_system(int(destination)):
							break
				Mode.CLEAR:
					if campaign_started:
						finish_expedition(true)
					else:
						start_run()
				Mode.DEFEAT:
					if campaign_started:
						finish_expedition(false)
					else:
						start_run()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_J:
			strike()
		elif event.keycode == KEY_SHIFT or event.keycode == KEY_K:
			dodge(Vector2(float(facing), 0.0))

func begin_touch(id: int, point: Vector2) -> void:
	match mode:
		Mode.INTRO:
			start_campaign()
			return
		Mode.CAPTAIN:
			choose_captain(0 if point.x < SIZE.x / 2.0 else 1)
			return
		Mode.STARSHIP:
			choose_starship(0 if point.x < SIZE.x / 2.0 else 1)
			return
		Mode.GALAXY:
			if point.y >= 556.0 and point.y < 615.0:
				galaxy.refuel_at_freeport()
				queue_redraw()
				return
			var target_index: int = galaxy.nearest_reachable(point, 38.0)
			if target_index >= 0:
				jump_to_system(target_index)
			return
		Mode.CLEAR:
			if campaign_started:
				finish_expedition(true)
			else:
				start_run()
			return
		Mode.DEFEAT:
			if campaign_started:
				finish_expedition(false)
			else:
				start_run()
			return
	if mode == Mode.EXPLORE and not FIELD.has_point(point):
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
	if mode == Mode.EXPLORE or mode == Mode.COMBAT or mode == Mode.CLEAR or mode == Mode.DEFEAT:
		draw_texture_rect(VEILWOOD, Rect2(Vector2.ZERO, SIZE), false)
	else:
		paint_world()
	match mode:
		Mode.EXPLORE:
			paint_exploration()
		Mode.INTRO:
			paint_title()
		Mode.CAPTAIN, Mode.STARSHIP:
			paint_setup()
		Mode.GALAXY:
			paint_galaxy()
		_:
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
	draw_text("TAP TO BEGIN", Vector2(80, 571), 26, INK)

func paint_setup() -> void:
	var is_captain := mode == Mode.CAPTAIN
	draw_rect(Rect2(18, 98, 324, 92), Color("#111a37", 0.96))
	draw_text("YOUR JOURNEY BEGINS", Vector2(31, 133), 22, ICE)
	draw_text("NO FLAG. NO MASTER. YOUR CHOICE.", Vector2(31, 164), 12, WHITE)
	draw_text("1 / 2   CAPTAIN" if is_captain else "2 / 2   STARSHIP", Vector2(26, 252), 17, LILAC)
	var left: Rect2 = Rect2(18, 288, 154, 196)
	var right: Rect2 = Rect2(188, 288, 154, 196)
	draw_rect(left, Color("#233656"))
	draw_rect(right, Color("#352b53"))
	for panel in [left, right]:
		draw_rect(Rect2(panel.position.x, panel.position.y, panel.size.x, 4), ICE if panel == left else GOLD)
	if is_captain:
		draw_circle(Vector2(95, 350), 27, ICE)
		draw_circle(Vector2(265, 350), 27, GOLD)
		draw_text("GUARDIAN", Vector2(35, 408), 18, WHITE)
		draw_text("+1 HP", Vector2(49, 440), 17, ICE)
		draw_text("SCAVENGER", Vector2(198, 408), 16, WHITE)
		draw_text("+1 SALVAGE", Vector2(200, 440), 12, GOLD)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(95, 325), Vector2(135, 367), Vector2(95, 351), Vector2(55, 367)]), ICE)
		draw_colored_polygon(PackedVector2Array([Vector2(265, 325), Vector2(313, 369), Vector2(265, 356), Vector2(217, 369)]), GOLD)
		draw_text("SCOUT", Vector2(55, 408), 21, WHITE)
		draw_text("6 FUEL", Vector2(52, 440), 17, ICE)
		draw_text("ESCORT", Vector2(224, 408), 20, WHITE)
		draw_text("5 FUEL / +1 HP", Vector2(198, 440), 12, GOLD)
	draw_text("TAP A PORTRAIT TO CHOOSE", Vector2(66, 546), 15, WHITE)

func paint_galaxy() -> void:
	draw_rect(Rect2(10, 9, 340, 175), Color("#11172f", 0.96))
	draw_text("VOID CARAVAN  /  NAVIGATION", Vector2(20, 34), 17, ICE)
	draw_text("FREE CAPTAIN  |  NO ALLEGIANCE", Vector2(20, 59), 12, LILAC)
	draw_text("CREDITS %d    FUEL %d    CARGO %d" % [galaxy.credits, galaxy.fuel, galaxy.cargo], Vector2(20, 84), 15, GOLD)
	draw_text("JUMPS %d    RENOWN %d" % [galaxy.turns, galaxy.fame], Vector2(20, 107), 14, WHITE)
	if nooli_recruited:
		draw_texture_rect_region(NOOLI, Rect2(299, 91, 44, 44), Rect2(256, 0, 128, 128))
		draw_text("CREW +1", Vector2(272, 146), 10, ICE)
	draw_text(galaxy.last_news.substr(0, 43), Vector2(20, 140), 11, LILAC)
	draw_text(galaxy.last_encounter.substr(0, 43), Vector2(20, 164), 11, ICE)
	draw_rect(Rect2(9, 202, 342, 350), Color("#0a132c", 0.9))
	for i in range(galaxy.systems.size()):
		var source: Dictionary = galaxy.systems[i]
		var start: Vector2 = source["pos"]
		for dest in source["routes"]:
			var j: int = dest
			if i < j:
				var endpoint: Vector2 = galaxy.systems[j]["pos"]
				draw_line(start, endpoint, Color("#587494", 0.78), 2.0)
	for i in range(galaxy.systems.size()):
		var sector: Dictionary = galaxy.systems[i]
		var p: Vector2 = sector["pos"]
		var owner: String = sector["owner"]
		var tint: Color = GALAXY_SIM.FACTIONS[owner]["color"]
		var reachable: bool = galaxy.can_travel(i)
		var here: bool = i == galaxy.current_system
		var r := 16.0 if here else 13.0
		if reachable:
			draw_arc(p, 30.0, 0.0, TAU, 36, ICE, 2.5, true)
		if here:
			draw_arc(p, 28.0, 0.0, TAU, 36, GOLD, 3.5, true)
		draw_circle(p, r + 4.0, INK)
		draw_circle(p, r, tint)
		draw_circle(p + Vector2(-4, -4), 4.0, WHITE)
		draw_text(String(sector["name"]), p + Vector2(-33, -33), 10, WHITE if galaxy.visited[i] else LILAC)
	draw_rect(Rect2(11, 562, 338, 55), Color("#273351"))
	draw_text("TAP CONNECTED STAR TO JUMP", Vector2(30, 585), 15, WHITE)
	draw_text("AT FREEPORT: TAP HERE TO REFUEL 4C", Vector2(30, 604), 11, ICE)
	draw_text("LAST: " + last_expedition_route if not last_expedition_route.is_empty() else "GALAXY CHANGES AFTER EACH JUMP", Vector2(44, 630), 10, LILAC)

func paint_stone() -> void:
	draw_texture_rect(ROCK_ART, Rect2(ROCK + Vector2(-26, -34), Vector2(52, 60)), false)

func paint_exploration() -> void:
	var pulse := 0.5 + 0.5 * sin(elapsed * 3.5)
	if hero.y >= ROCK.y:
		paint_stone()
	if not rescue_pending:
		for i in range(3):
			var p := LANDING.lerp(REFUGE, 0.30 + float(i) * 0.18)
			draw_circle(p, 2.0 + pulse * 1.5, Color(ICE, 0.70))
		if refuge_seen:
			draw_arc(REFUGE, 23.0 + pulse * 3.0, 0.0, TAU, 32, Color(ICE, 0.6), 2.0, true)
			draw_texture_rect_region(NOOLI, Rect2(REFUGE - Vector2(28, 35), Vector2(56, 56)), Rect2(128, 0, 128, 128))
		if quarry_seen:
			draw_texture_rect_region(MANTIS, Rect2(QUARRY - Vector2(40, 47), Vector2(80, 80)), Rect2(192, 0, 192, 192))
	else:
		draw_arc(LANDING, LANDING_RADIUS, 0.0, TAU, 32, ICE, 3.0, true)
		draw_texture_rect_region(NOOLI, Rect2(buddy_pos - Vector2(24, 34 + sin(elapsed * 9.0) * 1.5), Vector2(48, 48)), Rect2(256, 0, 128, 128))
		if hero.distance_to(LANDING) < LANDING_RADIUS and buddy_pos.distance_to(LANDING) >= LANDING_RADIUS:
			draw_arc(buddy_pos, 19.0 + pulse * 4.0, 0.0, TAU, 24, ICE, 2.0, true)
	if not cache_found:
		draw_colored_polygon(PackedVector2Array([CACHE + Vector2(0,-9), CACHE + Vector2(7,0), CACHE + Vector2(0,9), CACHE + Vector2(-7,0)]), Color(GOLD, 0.45 + pulse * 0.45))
	paint_hero()
	if hero.y < ROCK.y:
		paint_stone()
	draw_texture_rect(VEILWOOD_FORE, Rect2(Vector2.ZERO, SIZE), false)
	for p in particles:
		draw_circle(p["pos"], 2.2 + float(p["life"]) * 4.0, p["color"])
	draw_rect(Rect2(10, 10, 340, 48), Color("#11243b", 0.82))
	draw_text("VEILWOOD", Vector2(21, 40), 17, WHITE)
	draw_text("SCRAP %02d" % scraps, Vector2(240, 40), 13, GOLD)
	if rescue_pending:
		draw_text("WAIT FOR NOOLI" if hero.distance_to(LANDING) < LANDING_RADIUS else "RETURN TO LANDING", Vector2(78, 600), 14, ICE)
	elif not learned_move:
		draw_text("DRAG TO MOVE", Vector2(122, 600), 14, WHITE)

func paint_game() -> void:
	draw_rect(Rect2(8, 9, 344, 72), Color("#10162f", 0.9))
	var sector_title := String(galaxy.systems[active_sector]["name"]) if campaign_started else "TITAN MOON"
	draw_text("PLANET    /    " + sector_title, Vector2(20, 30), 14, ICE)
	for i in range(5 + (1 if campaign_started and captain_choice == 0 else 0) + (1 if campaign_started and ship_choice == 1 else 0)):
		draw_circle(Vector2(27 + i * 22, 54), 7, CORAL if i < health else Color("#35334b"))
	draw_text("SCRAP  %02d" % scraps, Vector2(228, 59), 18, GOLD)
	draw_text(expedition_route if not expedition_route.is_empty() else "WAVE  %d / 2" % wave, Vector2(20, 111), 15, WHITE)
	if combo > 1 and mode == Mode.COMBAT:
		draw_text("%d HIT COMBO" % combo, Vector2(219, 111), 16, ICE)
	for corpse in fallen:
		paint_fallen(corpse)
	for e in enemies:
		paint_enemy(e)
	paint_hero()
	draw_texture_rect(VEILWOOD_FORE, Rect2(Vector2.ZERO, SIZE), false)
	for p in particles:
		draw_circle(p["pos"], 2.2 + float(p["life"]) * 4.0, p["color"])
	if impact_fx > 0.0:
		var contact_size := 72.0 + (0.16 - impact_fx) * 115.0
		draw_texture_rect_region(COMBAT_CUES, Rect2(impact_pos - Vector2.ONE * contact_size * 0.5, Vector2.ONE * contact_size), Rect2(192, 0, 192, 192), Color(1.0, 1.0, 1.0, minf(1.0, impact_fx * 10.0)))
	if attack_fx > 0.0:
		var attack_point := hero + Vector2(float(facing) * 43.0, -9.0)
		var tint := ICE if attack_landed else Color("#a8bfd8", 0.6)
		draw_arc(attack_point, 47.0, -1.1 if facing == 1 else 2.0, 1.1 if facing == 1 else 4.2, 17, tint, 5.0 if attack_landed else 2.5, true)
	if mode == Mode.COMBAT:
		if not learned_attack or not learned_evade:
			draw_text("TAP TO STRIKE" if not learned_attack else "FLICK TO EVADE", Vector2(114, 514), 12, WHITE)
		paint_action(DODGE_POS, LILAC, "EVADE", false)
		paint_action(STRIKE_POS, ICE, "STRIKE", true)
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
		var hit_radius := 52.0 if kind == 2 else 42.0
		var cue_size := hit_radius * 192.0 / 74.0
		draw_texture_rect_region(COMBAT_CUES, Rect2(target - Vector2.ONE * cue_size * 0.5, Vector2.ONE * cue_size), Rect2(0, 0, 192, 192))
		draw_line(p, target, Color("#f87b89", 0.75), 2.0)
	if kind == 0:
		var pose := 2 if float(e["flash"]) > 0.0 else (1 if float(e["telegraph"]) > 0.0 else (3 if float(e["recovery"]) > 0.0 else 0))
		draw_texture_rect_region(MANTIS, Rect2(p - Vector2(48, 56), Vector2(96, 96)), Rect2(pose * 192, 0, 192, 192))
		draw_rect(Rect2(p.x - 22, p.y - 42, 44, 4), INK)
		draw_rect(Rect2(p.x - 22, p.y - 42, 44.0 * float(e["hp"]) / float(e["max_hp"]), 4), ICE)
		return
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

func paint_fallen(corpse: Dictionary) -> void:
	var p: Vector2 = corpse["pos"]
	var life := float(corpse["life"]) / 0.40
	var direction := float(corpse["direction"])
	var kind := int(corpse["kind"])
	var size := 96.0 if kind != 2 else 120.0
	p += Vector2(direction * (1.0 - life) * 18.0, (1.0 - life) * 9.0)
	draw_texture_rect_region(MANTIS, Rect2(p - Vector2(size * 0.5, size * 0.58), Vector2(size, size)), Rect2(384, 0, 192, 192), Color(1.0, 0.85, 0.72, life))

func hero_pose() -> int:
	if attack_fx > 0.08:
		return 2 if attack_landed else 3
	if attack_cd > 0.0:
		return 4
	if move_axis.length_squared() > 0.01:
		return 1 if int(elapsed * 12.0) % 2 == 0 else 0
	return 0

func paint_hero() -> void:
	var alpha := 0.45 if invulnerable > 0.0 and int(elapsed * 18.0) % 2 == 0 else 1.0
	var pose := hero_pose()
	var frame := pose + (5 if facing < 0 else 0)
	var bob := sin(elapsed * 12.0) * 1.5 if pose == 1 else 0.0
	draw_texture_rect_region(EXPLORER, Rect2(hero + Vector2(-38.0, -48.0 + bob), Vector2(76, 76)), Rect2(frame * 192, 0, 192, 192), Color(1.0, 1.0, 1.0, alpha))
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
	draw_text("NOOLI RESCUED" if won and rescue_pending else ("SALVAGE SECURED" if won else "SIGNAL LOST"), Vector2(31, 352), 26, ICE if won else CORAL)
	if won and rescue_pending:
		draw_texture_rect_region(NOOLI, Rect2(255, 367, 64, 64), Rect2(256, 0, 128, 128))
	draw_text("SCRAP RECOVERED   %d" % scraps, Vector2(41, 392), 17, GOLD)
	draw_text("TAP TO GALAXY" if campaign_started else "TAP TO REDEPLOY", Vector2(57, 453), 23, WHITE)
	draw_text("SHIP WORKSHOP: NEXT MILESTONE", Vector2(47, 563), 13, LILAC)
