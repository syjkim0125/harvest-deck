extends SceneTree
const SCENE=preload("res://flight.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/captures"))
	var scene=SCENE.instantiate()
	scene.test_mode=true
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var err=root.get_texture().get_image().save_png("res://build/captures/first-light.png")
	scene.begin(0,Vector2(180,420))
	scene.drag(0,Vector2(265,420))
	for i in range(90): scene._process(1.0/60)
	scene.end(0)
	if scene.world.position.x<100: err=FAILED
	await process_frame
	await RenderingServer.frame_post_draw
	var err2=root.get_texture().get_image().save_png("res://build/captures/flight.png")
	print("M1 CAPTURE: ",err," ",err2)
	scene.free()
	quit(0 if err==OK and err2==OK else 1)
