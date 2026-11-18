extends SceneTree
func _initialize() -> void:
	var rows = []
	for name in ["watermelon-v1.png", "golden-fruit-v1.png"]:
		var texture = load("res://assets/" + name)
		if texture == null:
			continue
		var image: Image = texture.get_image()
		rows.append({"asset":name,"size":[image.get_width(),image.get_height()],"mipmaps":image.has_mipmaps(),"image_bytes":image.get_data().size(),"format":image.get_format()})
	print(JSON.stringify(rows))
	quit()
