extends Node2D
## Static orchard scenery. Coordinates serve the existing playfield and routes.

const TREE = preload("res://assets/orchard-tree-v1.png")
const TREE_FRAME := Rect2(117, 86, 940, 1080)

var floor_bounds: Rect2

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
	draw_rect(Rect2(-2000, -2000, 5500, 5500), Color("243e3b"))
	var rim := StyleBoxFlat.new()
	rim.bg_color = Color("5a8261")
	rim.border_color = Color("375b49")
	rim.set_border_width_all(12)
	rim.set_corner_radius_all(42)
	draw_style_box(rim, floor_bounds)
	draw_lane()
	var scenery_rng := RandomNumberGenerator.new()
	scenery_rng.seed = 2607
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
	draw_polyline(center, Color("78916a"), 193.0, true)
	draw_polyline(center, Color("9e9472"), 174.0, true)
	draw_polyline(center, Color("ada17c"), 151.0, true)
	# A paved market terrace leads into the orchard path.
	var terrace := StyleBoxFlat.new()
	terrace.bg_color = Color("b4a586")
	terrace.border_color = Color("81785d")
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

func draw_planter(point: Vector2) -> void:
	draw_set_transform(point, 0.0, Vector2(1.0, 0.46))
	draw_circle(Vector2(0, 9), 34, Color(0.10, 0.23, 0.17, 0.30), true, -1.0, true)
	draw_circle(Vector2.ZERO, 31, Color("334f3e"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 26, Color("b3946c"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 21, Color("685a48"), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(TREE, Rect2(point + Vector2(-59, -117), Vector2(105, 120)), TREE_FRAME)
