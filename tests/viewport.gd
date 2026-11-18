extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func run() -> void:
	var outcomes = []
	for size in [Vector2i(512, 1108), Vector2i(960, 720), Vector2i(1280, 720)]:
		var view = SubViewport.new()
		view.size = size
		root.add_child(view)
		var g = Game.new()
		view.add_child(g)
		g.set_physics_process(false)
		g.sound_on = false
		g._physics_process(0.0)
		await process_frame
		var buttons = [g.pause_button, g.shake_button, g.orchard_button, g.upgrade_button, g.hire_button]
		var contained = true
		var separated = true
		for i in range(buttons.size()):
			var rect = buttons[i].get_rect()
			contained = contained and Rect2(Vector2.ZERO, Vector2(size.x, g.hud_height)).encloses(rect)
			separated = separated and not rect.intersects(g.status.get_rect()) and not rect.intersects(g.hud.get_rect())
			for j in range(i):
				separated = separated and not rect.intersects(buttons[j].get_rect())
		check(contained and separated, "HUD controls fit without overlaps at %s" % size)
		g.player = g.service_pad + Vector2(0, 64)
		var head_y = (115.0 - g.camera_follow_target().y) * g.camera.zoom.y + size.y / 2.0
		check(head_y > g.hud_height + 8, "queue heads stay below HUD at service edge %s" % size)
		g.impact.hit(true)
		g.camera.offset = g.feedback_offset()
		check((g.camera.offset * g.camera.zoom).length() <= Game.MAX_DISPLAY_SHAKE + 0.001, "zoom cannot amplify viewport-pixel shake %s" % size)
		var hud_before = g.hud.get_global_transform()
		g.camera.position += Vector2(150, 200)
		g.camera.offset = Vector2(2, 1)
		check(g.hud.get_global_transform() == hud_before, "HUD remains independent of camera movement %s" % size)
		g.shake_button.pressed.emit()
		check(g.impact.reduced and g.impact.trauma == 0.0 and g.camera.offset == Vector2.ZERO, "touch-accessible shake OFF clears pulse immediately %s" % size)
		g.set_paused(true)
		g.shake_button.pressed.emit()
		check(not g.impact.reduced and g.camera.offset == Vector2.ZERO, "shake preference remains usable while paused %s" % size)
		g.reset_run()
		g.drag_id = 5
		g.drag_vector = Vector2.RIGHT
		g.layout_hud()
		check(g.drag_id == -1 and g.drag_vector == Vector2.ZERO, "resize clears a held touch drag %s" % size)
		for i in range(120):
			g.simulate(1.0 / 60.0, Vector2.LEFT if i < 30 else Vector2.ZERO)
		outcomes.append([g.hits, g.cargo.duplicate(), g.production.inventory_count(), g.cash, g.player])
		view.queue_free()
		await process_frame
	check(outcomes[0] == outcomes[1] and outcomes[1] == outcomes[2], "viewport and zoom preserve seeded harvest, inventory and movement")
	print("VIEWPORT RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
