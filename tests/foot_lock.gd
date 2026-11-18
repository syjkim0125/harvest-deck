extends SceneTree
const Motion = preload("res://scripts/avatar_motion.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func finish() -> void:
	print("FOOT LOCK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func run() -> void:
	var m = Motion.new()
	var body = Vector2(3, 0)
	m.step(1.0 / 120, body)
	var before: Vector2 = body + m.foot(0, Vector2.RIGHT, false).position
	m.step(1.0 / 120, Vector2(0, -3))
	body += Vector2(0, -3)
	check(before.is_equal_approx(body + m.foot(0, Vector2.UP, false).position), "90-degree turn cannot teleport a contact foot")
	m = Motion.new()
	body = Vector2(3, 0)
	m.step(1.0 / 120, body)
	before = body + m.foot(0, Vector2.RIGHT, false).position
	m.step(0.3, Vector2.ZERO)
	check(before.is_equal_approx(body + m.foot(0, Vector2.RIGHT, false).position), "stopping does not slide a planted foot")
	m.step(1.0 / 120, Vector2(3, 0))
	body += Vector2(3, 0)
	check(before.is_equal_approx(body + m.foot(0, Vector2.RIGHT, false).position), "restarting does not pop a planted foot")
	if "--contact-only" in OS.get_cmdline_user_args():
		finish()
		return
	m = Motion.new()
	body = Vector2.ZERO
	var stable = true
	var prior = {"world": Vector2.ZERO, "planted": false}
	for frame in range(20):
		var direction = Vector2.RIGHT if frame < 10 else Vector2.LEFT
		m.step(1.0 / 120, direction * 3)
		body += direction * 3
		var pose = m.foot(0, direction, false)
		var point: Vector2 = body + pose.position
		if prior.planted and pose.planted:
			stable = stable and point.is_equal_approx(prior.world)
		prior = {"world": point, "planted": pose.planted}
	check(stable, "180-degree reversal does not drag a planted foot")
	var endings = []
	var trace = []
	for rate in [30, 60, 120]:
		m = Motion.new()
		body = Vector2.ZERO
		var previous = []
		for i in range(2):
			var initial = m.foot(i, Vector2.RIGHT, false)
			previous.append({"planted": initial.planted, "world": initial.position})
		stable = true
		var max_reach = 0.0
		for frame in range(rate * 2):
			var phase = int(float(frame) / rate * 2.5 + 0.00001) % 5
			var direction: Vector2 = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.ZERO, Vector2.DOWN][phase]
			m.step(1.0 / rate, direction * 360.0 / rate)
			body += direction * 360.0 / rate
			var current = []
			for i in range(2):
				var pose = m.foot(i, m.heading, false)
				var point: Vector2 = body + pose.position
				if previous[i].planted and pose.planted:
					stable = stable and point.is_equal_approx(previous[i].world)
				current.append({"planted": pose.planted, "world": point})
				max_reach = maxf(max_reach, m.feet[i].point.distance_to(m.nominal(i, m.body, m.heading)))
			previous = current
			if rate == 30:
				trace.append({"time": float(frame + 1) / rate, "body": [body.x, body.y], "feet": [{"x": current[0].world.x, "y": current[0].world.y, "planted": current[0].planted}, {"x": current[1].world.x, "y": current[1].world.y, "planted": current[1].planted}]})
		check(stable, "turn/stop route preserves planted anchors at %dHz" % rate)
		check(max_reach < 30.0, "leg reach remains bounded on the route at %dHz" % rate)
		endings.append([m.foot(0, m.heading, false).position, m.foot(1, m.heading, false).position])
	check(endings[0][0].is_equal_approx(endings[1][0]) and endings[1][0].is_equal_approx(endings[2][0]) and endings[0][1].is_equal_approx(endings[1][1]) and endings[1][1].is_equal_approx(endings[2][1]), "same route ends at matching poses across frame rates")
	m = Motion.new()
	for frame in range(10):
		m.step(1.0 / 120, Vector2(3, 0))
	var old_pose = [m.foot(0, Vector2.RIGHT, false).position, m.foot(1, Vector2.RIGHT, false).position]
	m.step(0.0, Vector2.ZERO)
	check(old_pose == [m.foot(0, Vector2.RIGHT, false).position, m.foot(1, Vector2.RIGHT, false).position], "zero-time stop cannot snap an airborne foot")
	m.step(0.3, Vector2.ZERO)
	check(m.feet[0].mode == "plant" and m.feet[1].mode == "plant" and m.feet[0].lift == 0.0 and m.feet[1].lift == 0.0, "stopping settles airborne feet")
	var held = m.feet.duplicate(true)
	m.step(1.0, Vector2.ZERO)
	check(m.feet == held, "settled idle anchors do not drift")
	m.reset()
	check(m.body == Vector2.ZERO and m.feet.is_empty(), "reset removes stale world anchors")
	var file = FileAccess.open("res://docs/foot-lock-v078.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind": "scripted model coordinates, not reference-video measurements", "seconds": 2, "samples_hz": 30, "samples": trace}, "  "))
	finish()
