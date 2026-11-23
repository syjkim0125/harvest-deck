extends "res://scripts/game.gd"
## Uses the comparison build's complete movement, saw and impact pipeline.

const DAY_SECONDS := 36.0
const WIDE := 0
const SPIN := 1
const HEART := 2
const BOUNTY := 3
const GUARD := 4
const DAY_STARTER: Array[int] = [WIDE, SPIN, HEART, BOUNTY]
const LEVELS: Array[int] = [1, 4, 8]

var active := false
var hearts := 5
var defeated := 0
var heart_limit := 5
var immunity := 0.0
var next_spawn := 0.0
var wide := 0
var spins := 0
var bounty := 0
var armor := 0
var direction := Vector2.ZERO
var wave_random := RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	hud_panel.get_parent().hide()
	night_view.get_parent().hide()
	orchard_counter.hide()
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)

func start_hunt(number: int) -> void:
	reset_day()
	fruits.clear()
	production.orchard_unlocked = true
	hearts = 5
	heart_limit = 5
	defeated = 0
	immunity = 0.0
	wide = 0
	spins = 0
	bounty = 0
	armor = 0
	next_spawn = 2.6 if number == 1 else 1.9
	wave_random.seed = 834 + number
	direction = Vector2.ZERO
	active = true
	camera.position = camera_follow_target()
	# One approachable group starts within sight of the player.
	for i in range(3):
		spawn_enemy(player + Vector2((i - 1) * 68, -175.0 - i * 28), int(i == 2))

func spawn_enemy(at: Vector2, kind: int) -> void:
	var home := at.clamp(BOUNDS.position + Vector2.ONE * 35, BOUNDS.end - Vector2.ONE * 35)
	fruits.append({"pos": home, "home": home, "kind": kind, "hp": 3, "flash": 0.0,
		"respawn": 0.0, "freeze": 0.0, "recoil": Vector2.ZERO})

func tick_hunt(delta: float, number: int) -> void:
	if not active:
		return
	immunity = maxf(0.0, immunity - delta)
	if direction.length_squared() < 0.01:
		var nearest := 145.0
		for enemy in fruits:
			var offset: Vector2 = enemy.pos - player
			if offset.length() < nearest and not offset.is_zero_approx():
				nearest = offset.length()
				facing = offset.normalized()
	for enemy in fruits:
		if enemy.freeze <= 0.0:
			enemy.pos = enemy.pos.move_toward(player, (56.0 + 4.0 * time + 9.0 * (number - 1) + 12.0 * enemy.kind) * delta)
		enemy.home = enemy.pos
	simulate(delta, direction if not direction.is_zero_approx() else movement_direction())
	for i in range(fruits.size() - 1, -1, -1):
		var enemy := fruits[i]
		if enemy.hp <= 0:
			defeated += 1
			for bonus in range(mini(bounty, harvest_limit() - cargo.size())):
				cargo.append(enemy.kind)
			fruits.remove_at(i)
		elif immunity <= 0.0 and player.distance_to(enemy.pos) < 32:
			immunity = 1.35
			if armor > 0:
				armor -= 1
			else:
				hearts -= 1
			enemy.pos += player.direction_to(enemy.pos) * 70
	next_spawn -= delta
	if next_spawn <= 0.0:
		next_spawn += maxf(1.1, 3.0 - time * 0.049 - 0.25 * (number - 1))
		for i in range(2 + int(time >= 16.0)):
			if fruits.size() >= 24:
				break
			var axis := Vector2.from_angle(wave_random.randf_range(0.0, TAU))
			spawn_enemy(player + axis * wave_random.randf_range(220.0, 340.0), int(wave_random.randf() < 0.45))
	camera.offset = feedback_offset()
	queue_redraw()

func equip(card: int) -> void:
	match card:
		WIDE: wide += 1
		SPIN: spins += 1
		HEART:
			heart_limit += 1
			hearts += 1
		BOUNTY: bounty += 1
		GUARD: armor += 1

func stop_hunt() -> void:
	active = false
	direction = Vector2.ZERO
	drag_vector = Vector2.ZERO
	saw_audio.silence()
	if is_instance_valid(audio):
		audio.stop()

func harvest_limit() -> int:
	return 999

func displayed_cargo_limit() -> int:
	return 18

func cut_reach() -> float:
	return 100.0 + 33.0 * wide + 14.0 * maxi(0, spins - 1)

func cut_dot_limit() -> float:
	return -1.0 if spins > 0 else 0.1

func update_orchard_counter() -> void:
	if is_instance_valid(orchard_counter):
		orchard_counter.hide()

func unload_destination() -> Vector2:
	return Vector2.INF

func step_shop(_delta: float) -> void:
	pass

func _draw() -> void:
	if spins > 0 and cut_trail_left > 0.0 and not impact.reduced:
		var opacity := cut_trail_left / BREAK_TRAIL_DURATION
		draw_arc(player, cut_reach() * (0.94 - opacity * 0.20), 0, TAU, 44, Color(1, 0.89, 0.59, opacity * 0.58), 2.5, true)
	draw_harvest_actors(ThemeDB.fallback_font)
