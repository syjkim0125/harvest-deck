extends SceneTree
var failures = 0
var checks = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", label)
func run() -> void:
	for size in [Vector2i(512,1108),Vector2i(960,720),Vector2i(1280,720)]:
		var view = SubViewport.new()
		view.size = size
		root.add_child(view)
		var g = load("res://scripts/game.gd").new()
		view.add_child(g)
		g.set_physics_process(false)
		g.sound_on = false
		g.cargo.append(0)
		g.production.deposit(1)
		g.drag_id = 2
		g.drag_vector = Vector2.RIGHT
		g.impact.hit(true)
		g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(g.paused and g.drag_id == -1 and g.drag_vector == Vector2.ZERO and g.camera.offset == Vector2.ZERO, "focus loss clears input/pulse %s" % size)
		var before = [g.player,g.hits,g.cargo.duplicate(),g.stock,g.time]
		g._physics_process(0.5)
		check(before == [g.player,g.hits,g.cargo,g.stock,g.time], "paused world and inventory frozen %s" % size)
		var button = g.get("pause_button")
		check(is_instance_valid(button), "touch resume control exists %s" % size)
		if is_instance_valid(button):
			check(button.text.contains("RESUME") and not button.disabled and button.focus_mode == Control.FOCUS_NONE, "resume remains accessible while paused %s" % size)
			await process_frame
			var contained = Rect2(Vector2.ZERO,Vector2(size.x,g.hud_height)).encloses(button.get_rect())
			for control in [g.shake_button,g.hire_button,g.upgrade_button,g.orchard_button,g.hud,g.status]:
				contained = contained and not button.get_rect().intersects(control.get_rect())
			check(contained, "resume fits HUD without overlap %s" % size)
			button.pressed.emit()
			check(not g.paused and button.text.contains("PAUSE") and g.drag_id == -1, "button resumes without stale movement %s" % size)
			g._physics_process(0.0)
			check(before == [g.player,g.hits,g.cargo,g.stock,g.time], "resume does not duplicate inventory or time %s" % size)
			button.pressed.emit()
			g.shake_button.pressed.emit()
			check(g.paused and g.impact.reduced and g.camera.offset == Vector2.ZERO, "M control works while touch paused %s" % size)
			g.reset_run()
			check(not g.paused and button.text.contains("PAUSE"), "reset restores pause label %s" % size)
		view.queue_free()
		await process_frame
	print("PAUSE TOUCH RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
