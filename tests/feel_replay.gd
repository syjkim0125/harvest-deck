extends SceneTree
const Game = preload("res://scripts/game.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var variants = [
		["baseline", false, false, false, false],
		["shake", true, false, false, false],
		["shake_sound", true, true, false, false],
		["shake_sound_reaction", true, true, true, false],
		["shake_sound_reaction_local", true, true, true, true]]
	print("variant,seconds,hits,cargo,ground,inventory,sold,pending_cash,collected_cash,max_shake_px")
	for variant in variants:
		var g = Game.new()
		root.add_child(g)
		g.set_physics_process(false)
		g.impact.enabled = variant[1]
		g.sound_on = variant[2]
		g.feedback = variant[3]
		g.local_stop = variant[4]
		# No hardware sound output during deterministic headless simulation.
		var output = g.audio
		g.audio = null
		var max_shake = 0.0
		for i in range(1080):
			# Fixed timestamped world-space path, independent of effects.
			var direction = Vector2.ZERO
			if i < 45:
				direction = Vector2.LEFT
			elif i >= 480 and i < 565:
				direction = Vector2.UP
			elif (i >= 565 and i < 610) or (i >= 926 and i < 971):
				direction = Vector2.RIGHT
			elif i >= 730 and i < 746:
				direction = Vector2.DOWN
			elif i >= 971 and i < 987:
				direction = Vector2.UP
			g.simulate(1.0 / 60.0, direction)
			max_shake = maxf(max_shake, g.impact.step(1.0 / 60.0).length())
		print("%s,18,%d,%d,%d,%d,%d,%d,%d,%.3f" % [variant[0], g.hits, g.cargo.size(), g.ground_drops.size(), g.stock, g.production.sold_by_kind[0] + g.production.sold_by_kind[1], g.production.pending_cash, g.cash, max_shake])
		g.audio = output
		g.queue_free()
		await process_frame
	quit()
