extends SceneTree
## Scripted render samples, not human feel or hardware latency measurement.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	var g = load("res://scripts/game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	g.cooldown = 100.0
	g.fruits.clear()
	g.impact.hit(true)
	var samples = []
	for i in range(10):
		if i > 0: g.impact.step(1.0 / 120.0)
		g.camera.offset = g.feedback_offset()
		g.status.text = "SCRIPTED COMFORT / %.1f ms\n1.5 logical px / 66.667 ms budget\nFixed scene; no human comfort rating" % (i * 1000.0 / 120.0)
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result = root.get_texture().get_image().save_png("res://docs/comfort-v0712-%02d.png" % i)
		samples.append({"ms":i*1000.0/120.0,"viewport_offset":g.camera.offset*g.camera.zoom,"hud_origin":g.hud.get_global_transform().origin,"save_result":result})
	var f = FileAccess.open("res://docs/comfort-v0712-render.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(samples,"\t"))
	print("COMFORT_RENDER 10 samples / 0..75ms; last_offset=",g.camera.offset*g.camera.zoom)
	quit()
