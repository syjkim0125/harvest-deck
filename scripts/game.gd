extends Node2D

const SawAudio = preload("res://scripts/saw_audio.gd")
const Production = preload("res://scripts/production.gd")
const Impact = preload("res://scripts/impact.gd")
const SPEED: float = 270.0
const ATTACK_INTERVAL: float = 0.105
const CAPACITY: int = 40
const HUD_HEIGHT: int = 114
const BOUNDS = Rect2(40, 100, 1480, 1040)
var impact = Impact.new()
var player: Vector2 = Vector2(700, 720)
var facing: Vector2 = Vector2.UP
var velocity: Vector2 = Vector2.ZERO
var fruits: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var cargo: Array[int] = []
var camera: Camera2D
var upgrade_button: Button
var hire_button: Button
var notice: String = ""
var hud: Label
var status: Label
var audio: AudioStreamPlayer
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
var cooldown: float = 0.0
var unload_clock: float = 0.0
var time: float = 0.0
var paused: bool = false
var feedback: bool = true
var sound_on: bool = true
var local_stop: bool = false
var drag_id: int = -1
var drag_origin: Vector2
var drag_vector: Vector2 = Vector2.ZERO
var depot: Vector2 = Vector2(680, 310)
var rng = RandomNumberGenerator.new()
var audio_rng = RandomNumberGenerator.new()
var terrain_style: StyleBoxFlat

func _ready() -> void:
	rng.seed = 1742
	terrain_style = field_style()
	setup_inputs()
	camera = Camera2D.new()
	camera.position = player
	add_child(camera)
	var layer = CanvasLayer.new()
	add_child(layer)
	var panel = ColorRect.new()
	panel.color = Color(0.025, 0.055, 0.075, 0.92)
	panel.size = Vector2(960, HUD_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(22, 12)
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	status = Label.new()
	status.position = Vector2(22, 46)
	status.add_theme_font_size_override("font_size", 14)
	layer.add_child(status)
	hire_button = Button.new()
	hire_button.position = Vector2(720, 79)
	hire_button.size = Vector2(220, 29)
	hire_button.focus_mode = Control.FOCUS_NONE
	hire_button.pressed.connect(try_hire_cashier)
	layer.add_child(hire_button)
	upgrade_button = Button.new()
	upgrade_button.position = Vector2(480, 79)
	upgrade_button.size = Vector2(220, 29)
	upgrade_button.focus_mode = Control.FOCUS_NONE
	upgrade_button.pressed.connect(try_upgrade_mixer)
	layer.add_child(upgrade_button)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.max_polyphony = 2
	saw_audio = SawAudio.new()
	add_child(saw_audio)
	audio_rng.seed = 618
	make_hit_sound()
	reset_run()

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
	rng.seed = 1742
	time = 0.0
	player = Vector2(700, 720)
	velocity = Vector2.ZERO
	facing = Vector2.UP
	cargo.clear()
	particles.clear()
	fruits.clear()
	production.reset()
	notice = ""
	ground_drops.clear()
	customer_visuals.clear()
	audio_rng.seed = 618
	hits = 0
	cooldown = 0.0
	unload_clock = 0.0
	paused = false
	drag_id = -1
	drag_vector = Vector2.ZERO
	impact.reset()
	if is_instance_valid(saw_audio):
		saw_audio.silence()
	if is_instance_valid(camera):
		camera.position = player
		camera.offset = Vector2.ZERO
	if is_instance_valid(audio):
		audio.stop()
	for i in range(32):
		var kind = i % 2
		var center = Vector2(510, 690) if kind == 0 else Vector2(1020, 660)
		var home = center + Vector2(rng.randf_range(-160, 160), rng.randf_range(-170, 170))
		fruits.append({"pos": home, "home": home, "hp": 3, "kind": kind, "flash": 0.0, "respawn": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO})

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_paused(true)

func set_paused(value: bool) -> void:
	paused = value
	if value and is_instance_valid(saw_audio):
		saw_audio.silence()
	if value and is_instance_valid(audio):
		audio.stop()
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
			KEY_E: try_hire_cashier()
			KEY_F: try_upgrade_mixer()
			KEY_1:
				impact.enabled = not impact.enabled
				impact.clear()
			KEY_2: set_sound_enabled(not sound_on)
			KEY_5:
				loop_sound = not loop_sound
				saw_audio.silence()
			KEY_MINUS: sound_volume = maxf(0.0, sound_volume - 0.1)
			KEY_EQUAL: sound_volume = minf(1.0, sound_volume + 0.1)
			KEY_3: feedback = not feedback
			KEY_4: local_stop = not local_stop
			KEY_M:
				impact.reduced = not impact.reduced
				impact.clear()

	# A release must reach the active drag even if GUI consumes it later.
	if event is InputEventScreenTouch and not event.pressed and event.index == drag_id:
		drag_id = -1
		drag_vector = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# Let CanvasLayer controls consume touch before starting the movement drag.
	if event is InputEventScreenTouch:
		if event.pressed and drag_id == -1 and not paused:
			drag_id = event.index
			drag_origin = event.position
		elif not event.pressed and event.index == drag_id:
			drag_id = -1
			drag_vector = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == drag_id:
		drag_vector = ((event.position - drag_origin) / 65.0).limit_length()

func _physics_process(delta: float) -> void:
	if not paused:
		var direction = Input.get_vector("left", "right", "up", "down")
		if drag_vector.length() > 0.05:
			direction = drag_vector
		simulate(delta, direction)
	if not paused:
		camera.position = camera.position.lerp(camera_follow_target(), 1.0 - exp(-10.0 * delta))
	camera.offset = impact.step(delta) if not paused else Vector2.ZERO
	hud.text = "HARVEST  $%d  BAG %d/%d  RAW %d  MIX %d  READY %d  TILL $%d  LINE %d" % [cash, cargo.size(), CAPACITY, production.raw.size(), int(production.active_kind >= 0), production.ready.size(), production.pending_cash, production.customers.size()]
	status.text = "WASD / arrows / touch drag • auto-cut • mint: unload / blue: serve / gold: cash / purple: hire / coral: mixer\n1 Shake %s   2 Sound %s   3 Reaction %s   4 Local-stop %s   M Reduced %s   P Pause   R Reset %s" % [impact.enabled, sound_on, feedback, local_stop, impact.reduced, "[PAUSED]" if paused else ""]
	status.text += "\n5 Motor %s  -/+ Volume %d%%  Saw %s" % [loop_sound, roundi(sound_volume * 100), saw_audio.mode()]
	hire_button.text = "CASHIER WORKING" if production.cashier_hired else "E / HIRE CASHIER $%d" % Production.CASHIER_COST
	hire_button.disabled = paused or production.cashier_hired or cash < Production.CASHIER_COST or player.distance_to(hire_pad) >= 80
	upgrade_button.text = "MIXER 0.25s ACTIVE" if production.mixer_upgraded else "F / UPGRADE MIXER $40"
	upgrade_button.disabled = paused or production.mixer_upgraded or cash < Production.MIXER_UPGRADE_COST or player.distance_to(upgrade_pad) >= 80
	if not notice.is_empty():
		hire_button.tooltip_text = notice
	queue_redraw()

func try_hire_cashier() -> bool:
	if paused or player.distance_to(hire_pad) >= 80:
		notice = "Stand on the purple hire pad to hire."
		return false
	var hired: bool = production.hire_cashier()
	notice = "Cashier hired. You can return to harvesting." if hired else "Collect $30 first, or cashier is already hired."
	return hired

func try_upgrade_mixer() -> bool:
	if paused or player.distance_to(upgrade_pad) >= 80:
		notice = "Stand on the coral pad to upgrade the mixer."
		return false
	var upgraded: bool = production.upgrade_mixer()
	notice = "Mixer upgraded: 0.25 seconds per item." if upgraded else "Collect $40 first, or mixer is already upgraded."
	return upgraded

func set_sound_enabled(value: bool) -> void:
	sound_on = value
	if not value:
		if is_instance_valid(audio):
			audio.stop()
		if is_instance_valid(saw_audio):
			saw_audio.silence()

func camera_follow_target() -> Vector2:
	# Keep the queue below the fixed HUD while working the shop counter.
	var shop_weight = clampf((600.0 - player.y) / 125.0, 0.0, 1.0)
	return player + Vector2(0, -150.0 * shop_weight)

func simulate(delta: float, direction: Vector2) -> void:
	time += delta
	velocity = direction.limit_length() * SPEED
	player += velocity * delta
	player = player.clamp(BOUNDS.position + Vector2.ONE * 20, BOUNDS.end - Vector2.ONE * 20)
	if direction.length() > 0.05:
		facing = direction.normalized()
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown += ATTACK_INTERVAL
		attack()
	for f in fruits:
		f.flash = maxf(0.0, f.flash - delta)
		f.freeze = maxf(0.0, f.freeze - delta)
		if f.hp <= 0:
			f.respawn -= delta
			if f.respawn <= 0.0:
				f.hp = 3
				f.pos = f.home
				f.recoil = Vector2.ZERO
		else:
			if f.freeze <= 0.0:
				f.recoil = f.get("recoil", Vector2.ZERO).lerp(Vector2.ZERO, 1.0 - exp(-18.0 * delta))
			f.pos = f.pos.lerp(f.home + Vector2(sin(time * 2.0 + f.home.x) * 7, cos(time * 2.5 + f.home.y) * 5), 1.0 - exp(-7.0 * delta))
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= exp(-4.0 * delta)
		if p.life <= 0.0:
			particles.remove_at(i)
	if player.distance_to(depot) < 85 and not cargo.is_empty():
		unload_clock += delta
		while unload_clock >= 0.04 and not cargo.is_empty():
			unload_clock -= 0.04
			production.deposit(cargo.pop_back())
	else:
		unload_clock = 0.0
	production.step(delta, player.distance_to(service_pad) < 65)
	var live_ids: Array[int] = []
	for i in range(production.customers.size()):
		var id: int = production.customers[i].id
		live_ids.append(id)
		var destination = Vector2(570 + i * 52, 135)
		customer_visuals[id] = customer_visuals.get(id, Vector2(960, 135)).lerp(destination, 1.0 - exp(-5.0 * delta))
	for id in customer_visuals.keys():
		if id not in live_ids:
			customer_visuals.erase(id)
	if player.distance_to(cash_pad) < 65:
		production.collect()
	for i in range(ground_drops.size() - 1, -1, -1):
		if cargo.size() < CAPACITY and player.distance_to(ground_drops[i].pos) < 65:
			cargo.append(ground_drops[i].kind)
			ground_drops.remove_at(i)

	saw_audio.master_gain = sound_volume
	saw_audio.step(delta, sound_on and loop_sound and not paused, velocity.length() > 1, cargo.size() >= CAPACITY)

func attack() -> int:
	if cargo.size() >= CAPACITY:
		return 0
	var count = 0
	var killed = false
	for f in fruits:
		if f.hp <= 0 or cargo.size() >= CAPACITY:
			continue
		var diff: Vector2 = f.pos - player
		if diff.length() > 100 or (diff.length() > 28 and facing.dot(diff.normalized()) < 0.1):
			continue
		f.hp -= 1
		count += 1
		hits += 1
		var dead: bool = f.hp <= 0
		impact.hit(dead)
		if feedback:
			f.flash = 0.055
			f.recoil = diff.normalized() * 7
		if local_stop:
			f.freeze = 0.025
		burst(f.pos + f.get("recoil", Vector2.ZERO), f.kind, dead)
		if dead:
			killed = true
			f.respawn = 5.0
			for j in range(3):
				if cargo.size() < CAPACITY:
					cargo.append(f.kind)
				else:
					ground_drops.append({"pos": f.pos + Vector2(j * 9 - 9, 15), "kind": f.kind})
	if count > 0 and sound_on:
		var pitch: float = 0.78 if killed else audio_rng.randf_range(1.0, 1.12)
		if loop_sound and is_instance_valid(saw_audio):
			saw_audio.confirmed_hit()
		# Headless tests exercise state/PCM, not a hardware playback device.
		if is_instance_valid(audio) and DisplayServer.get_name() != "headless":
			audio.pitch_scale = pitch
			audio.volume_linear = sound_volume * 0.75
			audio.play()
	return count

func burst(at: Vector2, kind: int, dead: bool) -> void:
	for i in range(13 if dead else 5):
		var v = Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(40, 220)
		particles.append({"pos": at, "vel": v, "life": rng.randf_range(0.15, 0.4), "kind": kind})

func make_hit_sound() -> void:
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(2205 * 2)
	for i in range(2205):
		var t = float(i) / 22050.0
		var sample = (sin(TAU * (160 * t - 420 * t * t)) * 0.65 + audio_rng.randf_range(-0.35, 0.35)) * exp(-t * 48) * 0.35
		bytes.encode_s16(i * 2, int(sample * 32767))
	wave.data = bytes
	audio.stream = wave

func _draw() -> void:
	draw_rect(Rect2(-2000, -2000, 5500, 5500), Color("315953"))
	draw_style_box(terrain_style, BOUNDS)
	for x in range(80, 1500, 64):
		for y in range(140, 1120, 64):
			draw_line(Vector2(x, y), Vector2(x + 5, y - 7), Color(0.4, 0.65, 0.51, 0.27), 2)
	draw_circle(Vector2(510, 690), 225, Color(0.18, 0.37, 0.28, 0.3))
	draw_circle(Vector2(1020, 660), 225, Color(0.45, 0.39, 0.2, 0.25))
	draw_rect(Rect2(520, 190, 320, 72), Color("193a3e"))
	draw_rect(Rect2(530, 180, 300, 64), Color("ecbd68"))
	draw_circle(depot, 82, Color(0.42, 0.9, 0.72, 0.25))
	draw_arc(depot, 82, 0, TAU, 48, Color("85e8b3"), 3)
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(590, 220), "JUICE / DROP ZONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("183b38"))
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
	for d in ground_drops:
		draw_fruit(d.pos, d.kind, 10, false)
	for f in fruits:
		if f.hp > 0:
			var display_pos: Vector2 = f.pos + (f.get("recoil", Vector2.ZERO) if feedback else Vector2.ZERO)
			draw_fruit(display_pos, f.kind, 24, f.flash > 0 and feedback)
			if f.hp < 3:
				draw_rect(Rect2(display_pos + Vector2(-20, -36), Vector2(40, 4)), Color("233635"))
				draw_rect(Rect2(display_pos + Vector2(-20, -36), Vector2(f.hp * 13.3, 4)), Color("ffe3a0"))
	for p in particles:
		draw_circle(p.pos, 3.5, Color("f9796d") if p.kind == 0 else Color("ffd36a"))
	draw_set_transform(player + Vector2(0, 8), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 24, Color(0.02, 0.08, 0.07, 0.4))
	draw_set_transform(Vector2.ZERO)
	var bob = sin(time * 19) * 2 if velocity.length() > 1 else 0.0
	for i in range(cargo.size()):
		var sway = sin(time * 7 - i * 0.18) * minf(i * 0.3, 8.0) if velocity.length() > 1 else 0.0
		draw_fruit(player + Vector2(-13 + sway, -25 - i * 5.0), cargo[i], 11, false)
	draw_line(player + Vector2(-9, 5), player + Vector2(-10, 17 + bob), Color("202d36"), 10)
	draw_line(player + Vector2(9, 5), player + Vector2(10, 17 - bob), Color("202d36"), 10)
	draw_circle(player + Vector2(0, -9 + bob), 19, Color("253842"))
	draw_circle(player + Vector2(0, -25 + bob), 13, Color("f3d5ae"))
	draw_arc(player + Vector2(0, -28 + bob), 12, PI, TAU, 12, Color("764732"), 8)
	var saw_start = player + facing * 19 + Vector2(0, -6)
	var saw_end = saw_start + facing * 48
	var jiggle = facing.orthogonal() * sin(time * 90) * 1.6
	draw_line(saw_start, saw_end + jiggle, Color("162f35"), 20)
	draw_line(saw_start, saw_end + jiggle, Color("dce7d8"), 13)
	draw_circle(saw_start, 13, Color("eaa746"))
	if cargo.size() >= CAPACITY:
		draw_string(font, player + Vector2(-35, 45), "FULL! UNLOAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe9a0"))

func draw_fruit(at: Vector2, kind: int, radius: float, flash: bool) -> void:
	draw_circle(at + Vector2(0, radius * 0.22), radius, Color("203e35"))
	draw_circle(at, radius - 2, Color.WHITE if flash else (Color("74bc68") if kind == 0 else Color("edb950")))
	if kind == 0:
		draw_arc(at, radius * 0.65, -1.0, 1.0, 10, Color("3a8754"), 4)
	else:
		draw_line(at + Vector2(-7, -radius + 2), at + Vector2(0, -radius - 10), Color("86ba64"), 5)
	if radius > 15:
		draw_circle(at + Vector2(-7, 0), 3, Color("17382f"))
		draw_circle(at + Vector2(7, 0), 3, Color("17382f"))

func field_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("4d826b")
	style.border_color = Color("23493f")
	style.set_border_width_all(12)
	style.set_corner_radius_all(45)
	return style
