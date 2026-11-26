extends SceneTree
# Rendered native CI capture, not a real iOS/Android or subjective playtest.
const GAME = preload("res://scripts/sf_belt_scroll.gd")
var failures := 0
var game

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
	print("PASS " if ok else "FAIL ", label)

func render_frames() -> void:
	for i in range(3):
		await process_frame
		await RenderingServer.frame_post_draw

func touch(id: int, p: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = game.layout_origin + p * game.layout_scale
	event.pressed = down
	game._input(event)

func drag(id: int, p: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = game.layout_origin + p * game.layout_scale
	game._input(event)

func move_toward_target(target: Vector2, limit: int = 120) -> void:
	var origin: Vector2 = game.hero
	touch(0, origin, true)
	drag(0, origin + (target - origin).normalized() * 60.0)
	for i in range(limit):
		if game.touch_id == -1 or game.hero.distance_to(target) < 7.0:
			break
		game._process(0.016)
	touch(0, target, false)

func shot(prefix: String, label: String) -> void:
	game.queue_redraw()
	await render_frames()
	var img := root.get_texture().get_image()
	check(img != null and not img.is_empty(), prefix + " " + label + " actual render")
	if img != null and not img.is_empty():
		var path := "res://build/captures/" + prefix + "-" + label + ".png"
		check(img.save_png(path) == OK, "saved " + path)
		print("CAPTURE ", img.get_size(), " ", path)

func verify() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/captures"))
	for size in [Vector2i(360, 640), Vector2i(393, 852)]:
		root.size = size
		await render_frames()
		game = GAME.new()
		root.add_child(game)
		game.set_process(false)
		await render_frames()
		game.resize()
		var prefix := "%dx%d" % [size.x, size.y]
		check(root.size == size, prefix + " window size")
		game.start_campaign()
		game.choose_captain(0)
		game.choose_starship(0)
		await shot(prefix, "navigation")
		check(game.jump_to_system(1), prefix + " connected jump")
		await shot(prefix, "unmapped")
		move_toward_target(GAME.REFUGE)
		check(game.rescue_pending and game.refuge_seen, prefix + " touch discovery")
		await shot(prefix, "rescue")
		move_toward_target(GAME.LANDING)
		for i in range(120):
			if game.mode == GAME.Mode.CLEAR:
				break
			game._process(0.016)
		check(game.mode == GAME.Mode.CLEAR, prefix + " dual extraction")
		await shot(prefix, "extraction")
		game.finish_expedition(true)
		check(game.nooli_recruited, prefix + " crew persists")
		game.start_run()
		game.hero = game.enemies[0]["pos"] - Vector2(58, 0)
		game.enemies[0]["cooldown"] = 0.0
		game.advance_enemies(0.016)
		await shot(prefix, "telegraph")
		game.strike()
		check(game.attack_landed, prefix + " confirmed contact")
		await shot(prefix, "hit")
		game.free()
		game = null
		await render_frames()
	print("SF RENDER CAPTURE: %d failures" % failures)
	quit(1 if failures else 0)
