extends Node2D
## Static orchard scenery. Coordinates serve the existing playfield and routes.

var floor_bounds: Rect2

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
	draw_rect(Rect2(-2000, -2000, 5500, 5500), Color("3b7470"))
	var rim := StyleBoxFlat.new()
	rim.bg_color = Color("82af91")
	rim.border_color = Color("544d48")
	rim.set_border_width_all(12)
	rim.set_corner_radius_all(42)
	draw_style_box(rim, floor_bounds)
	draw_lane()
	var scenery_rng := RandomNumberGenerator.new()
	scenery_rng.seed = 2607
	for y in range(520, 1090, 115):
		for x in range(160, 1460, 175):
			var clearing := Vector2(x, y) + Vector2(scenery_rng.randf_range(-48, 48), scenery_rng.randf_range(-20, 20))
			if absf(clearing.x - lane_x(clearing.y)) > 102:
				draw_ground_patch(clearing, scenery_rng.randf_range(0.65, 1.4))
	for x in range(95, 1480, 45):
		for y in range(155, 1110, 43):
			var point := Vector2(x, y) + Vector2(scenery_rng.randf_range(-15, 15), scenery_rng.randf_range(-13, 13))
			if point.y < 480 or absf(point.x - lane_x(point.y)) < 101:
				continue
			draw_tuft(point, scenery_rng.randf_range(0.65, 1.3))
	for point in [Vector2(385, 480), Vector2(835, 554), Vector2(280, 520), Vector2(294, 970), Vector2(1170, 516), Vector2(1270, 795), Vector2(1110, 954), Vector2(730, 1000)]:
		draw_planter(point)

func lane_x(y: float) -> float:
	return 685.0 + sin((y - 430.0) / 155.0) * 43.0

func draw_lane() -> void:
	var center := PackedVector2Array()
	for y in range(436, 1100, 12):
		center.append(Vector2(lane_x(y), y))
	draw_polyline(center, Color("99b494"), 193.0, true)
	draw_polyline(center, Color("c4b395"), 165.0, true)
	# A paved market terrace leads into the orchard path.
	var terrace := StyleBoxFlat.new()
	terrace.bg_color = Color("b6b994")
	terrace.border_color = Color("6f8068")
	terrace.set_border_width_all(4)
	terrace.set_corner_radius_all(20)
	draw_style_box(terrace, Rect2(360, 112, 794, 370))
	for y in range(130, 470, 32):
		var shift := 16 if (y - 130) % 64 == 0 else 0
		for x in range(382 + shift, 1128, 41):
			draw_line(Vector2(x, y), Vector2(x + 24, y), Color(0.38, 0.34, 0.26, 0.19), 1.0, true)

func draw_tuft(point: Vector2, size: float) -> void:
	var blade := Color(0.19, 0.36, 0.25, 0.36)
	draw_line(point, point + Vector2(-4, -4) * size, blade, 1.6, true)
	draw_line(point, point + Vector2(2, -7) * size, blade, 1.6, true)
	draw_line(point, point + Vector2(5, -2) * size, blade, 1.6, true)

func draw_ground_patch(at: Vector2, scale: float) -> void:
	draw_set_transform(at, 0.0, Vector2(scale * 1.45, scale))
	draw_circle(Vector2.ZERO, 38, Color("92ba98"), true, -1.0, true)
	draw_circle(Vector2(20, -17), 24, Color("92ba98"), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)

func draw_planter(point: Vector2) -> void:
	draw_set_transform(point + Vector2(0, 5), 0.0, Vector2(1.0, 0.46))
	draw_circle(Vector2.ZERO, 32, Color(0.10, 0.23, 0.17, 0.30), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	draw_line(point, point + Vector2(0, -39), Color("433b44"), 22, true)
	draw_line(point - Vector2(0, 2), point + Vector2(0, -39), Color("b07b60"), 15, true)
	var crown := point + Vector2(0, -47)
	var lobes := [Vector2(-20, 1), Vector2(17, 1), Vector2(0, -19), Vector2(3, 13)]
	for offset in lobes:
		draw_circle(crown + offset, 22, Color("344448"), true, -1.0, true)
	for offset in lobes:
		draw_circle(crown + offset, 18.6, Color("4e9d84"), true, -1.0, true)
	draw_circle(crown + Vector2(-8, -18), 14, Color("68b79a"), true, -1.0, true)
