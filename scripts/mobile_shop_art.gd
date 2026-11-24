extends RefCounted

const INK := Color("30294b")
const GOLD := Color("ffd279")
const CREAM := Color("fff0cf")
const PINK := Color("ef897d")
const MINT := Color("8ddbc0")
const STATIONS: Array[Rect2] = [Rect2(19, 197, 109, 134), Rect2(132, 197, 105, 134), Rect2(241, 197, 100, 134)]
var walking: Dictionary = {}
var coin_time := 0.0
var last_sale := 0
var last_mix := 0
var cup_time := 0.0
static var style_cache: Dictionary = {}

func refresh(delta: float, shop) -> void:
	if last_mix != shop.mixed:
		last_mix = shop.mixed
		cup_time = 0.27
	cup_time = maxf(0.0, cup_time - delta)
	if last_sale != shop.sold:
		last_sale = shop.sold
		coin_time = 0.60
	coin_time = maxf(0.0, coin_time - delta)
	for i in range(shop.customers.size()):
		var person: int = shop.customers[i]
		var target := customer_spot(i)
		walking[person] = Vector2(walking.get(person, Vector2(355, 412))).lerp(target, 1.0 - exp(-6.0 * delta))
	for person in walking.keys():
		if person not in shop.customers:
			walking.erase(person)

static func customer_spot(index: int) -> Vector2:
	const SPOTS := [Vector2(287, 329), Vector2(264, 372), Vector2(205, 393), Vector2(144, 391), Vector2(87, 385)]
	return SPOTS[index]

static func shape(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)

static func box(canvas: CanvasItem, rect: Rect2, color: Color, corner: int = 10, outline := Color.TRANSPARENT) -> void:
	var key := "%s:%s:%d" % [color, outline, corner]
	var style: StyleBoxFlat = style_cache.get(key)
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(corner)
		style.set_border_width_all(2 if outline.a > 0.0 else 0)
		style.border_color = outline
		style_cache[key] = style
	canvas.draw_style_box(style, rect)

static func coin(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_circle(at + Vector2(0, 2), radius, Color("9a573d"), true, -1.0, true)
	canvas.draw_circle(at, radius, GOLD, true, -1.0, true)
	canvas.draw_arc(at, radius * 0.66, 0, TAU, 24, Color("e9a24e"), maxf(1.0, radius * 0.13), true)
	canvas.draw_line(at - Vector2(0, radius * 0.4), at + Vector2(0, radius * 0.4), CREAM, 2, true)

static func fruit(canvas: CanvasItem, at: Vector2, kind: int, scale_factor: float = 1.0) -> void:
	var r := 12.0 * scale_factor
	canvas.draw_circle(at, r, Color("356c61") if kind == 0 else Color("8c583b"), true, -1.0, true)
	canvas.draw_circle(at - Vector2.ONE * r * 0.15, r * 0.85, MINT if kind == 0 else GOLD, true, -1.0, true)
	if kind == 0:
		canvas.draw_arc(at, r * 0.67, -1.1, 1.8, 14, Color("438873"), r * 0.2, true)
	else:
		canvas.draw_circle(at + Vector2(-3, -3) * scale_factor, r * 0.21, CREAM)
	canvas.draw_line(at + Vector2(0, -r * 0.75), at + Vector2(r * 0.34, -r * 1.14), Color("477457"), maxf(1.0, r * 0.22), true)

static func cup(canvas: CanvasItem, at: Vector2, kind: int, factor: float = 1.0) -> void:
	var drink: Color = [MINT, PINK, Color("c7a9f0"), GOLD][kind]
	shape(canvas, PackedVector2Array([at + Vector2(-10, -8) * factor, at + Vector2(10, -8) * factor,
		at + Vector2(7, 10) * factor, at + Vector2(-7, 10) * factor]), drink)
	canvas.draw_line(at + Vector2(-11, -7) * factor, at + Vector2(11, -7) * factor, CREAM, 2.2 * factor, true)
	canvas.draw_line(at + Vector2(2, -8) * factor, at + Vector2(6, -16) * factor, Color("ffe5bc"), 2.2 * factor, true)

static func person(canvas: CanvasItem, at: Vector2, index: int, bob: float = 0.0) -> void:
	var shirt: Color = [Color("e49c68"), Color("90b9ed"), Color("bb9adc"), MINT, Color("e58e9c")][index % 5]
	canvas.draw_circle(at + Vector2(0, 10), 15, Color(0.16, 0.12, 0.24, 0.26))
	at.y += bob
	box(canvas, Rect2(at + Vector2(-12, -3), Vector2(24, 19)), shirt, 7, INK)
	canvas.draw_circle(at + Vector2(0, -11), 13, INK, true, -1.0, true)
	canvas.draw_circle(at + Vector2(0, -10), 11, Color("efbc91"), true, -1.0, true)
	canvas.draw_arc(at + Vector2(0, -8), 11, PI + 0.2, TAU - 0.2, 12, Color("594160"), 5, true)
	canvas.draw_circle(at + Vector2(-3.2, -9), 1.3, INK, true, -1.0, true)
	canvas.draw_circle(at + Vector2(3.2, -9), 1.3, INK, true, -1.0, true)

func paint(canvas: CanvasItem, shop, animation: float, highlighted: int) -> void:
	canvas.draw_rect(Rect2(0, 0, 360, 640), Color("282548"))
	canvas.draw_circle(Vector2(311, 51), 25, Color("ffe5a4"), true, -1.0, true)
	canvas.draw_circle(Vector2(321, 45), 24, Color("282548"), true, -1.0, true)
	for i in range(30):
		var star := Vector2(11 + (i * 109) % 346, 20 + (i * 43) % 123)
		canvas.draw_circle(star, 1.0 + float(i % 3) * 0.45, Color(1, 0.87, 0.65, 0.4 + 0.22 * sin(animation * 1.9 + i)))
	# The room is a cutaway with the equipment in the player's view.
	box(canvas, Rect2(12, 153, 336, 278), Color("443557"), 18, Color("79516b"))
	box(canvas, Rect2(20, 185, 320, 234), Color("80566b"), 14)
	for i in range(8):
		for j in range(5):
			canvas.draw_rect(Rect2(25 + 39 * i, 211 + 39 * j, 38, 38), Color("875b73") if (i + j) % 2 == 0 else Color("a16d7d"))
	shape(canvas, PackedVector2Array([Vector2(16, 177), Vector2(35, 133), Vector2(325, 133), Vector2(344, 177)]), Color("88485f"))
	for i in range(8):
		var x := 16.0 + i * 41
		var awning := PINK if i % 2 == 0 else Color("f6c881")
		shape(canvas, PackedVector2Array([Vector2(x, 177), Vector2(35 + i * 36.25, 135),
			Vector2(35 + (i + 1) * 36.25, 135), Vector2(x + 41, 177)]), awning)
		box(canvas, Rect2(x, 174, 41, 16), awning.darkened(0.18), 6)
	if highlighted >= 0:
		box(canvas, STATIONS[highlighted], Color(0.98, 0.8, 0.36, 0.22), 12, GOLD)
	# Always show the ingredient crates, appliances and counter.
	for kind in range(2):
		var at := Vector2(41 + kind * 41, 296)
		box(canvas, Rect2(at - Vector2(17, 8), Vector2(34, 24)), Color("a86552"), 4, INK)
		for piece in range(mini(shop.raw[kind], 3)):
			fruit(canvas, at + Vector2(-8 + piece * 8, -5 - 4 * (piece % 2)), kind, 0.65)
	# The active batch stays in the jar. The tray shows the actual line behind it.
	if shop.jobs.size() > 1:
		box(canvas, Rect2(30, 322, 88, 25), Color("a86552"), 6, INK)
		for i in range(1, mini(5, shop.jobs.size())):
			var at := Vector2(23 + 20 * i, 333)
			var job: int = shop.jobs[i]
			if job < 2:
				fruit(canvas, at, job, 0.62)
			else:
				cup(canvas, at, job, 0.62)
	var running: bool = shop.can_blend()
	var base := Vector2(74, 237) + Vector2(sin(animation * 65) * 1.7 * float(running), 0)
	box(canvas, Rect2(base + Vector2(-22, 22), Vector2(44, 19)), Color("b56971"), 5, INK)
	shape(canvas, PackedVector2Array([base + Vector2(-22, -24), base + Vector2(22, -24),
		base + Vector2(15, 22), base + Vector2(-15, 22)]), Color("b7dad4"))
	if not shop.jobs.is_empty():
		var drink: int = shop.jobs[0]
		var fill: Color = [MINT, PINK, Color("d4a7f6"), GOLD][drink]
		box(canvas, Rect2(base + Vector2(-14, 1), Vector2(28, 20)), fill, 4)
		if running:
			canvas.draw_circle(base + Vector2(sin(animation * 11) * 8, 2 - sin(animation * 17) * 8), 3, CREAM)
		progress(canvas, Rect2(base + Vector2(-21, 42), Vector2(42, 4)), shop.blend / shop.mix_duration())
	box(canvas, Rect2(base + Vector2(-25, -28), Vector2(50, 7)), INK, 3)
	box(canvas, Rect2(135, 228, 94, 66), Color("8c535f"), 8, INK)
	box(canvas, Rect2(134, 223, 96, 13), Color("e0a16c"), 5, INK)
	for i in range(shop.shelf.size()):
		if cup_time <= 0.0 or i < shop.shelf.size() - 1:
			cup(canvas, Vector2(147 + 17 * i, 258), shop.shelf[i], 0.73)
	if cup_time > 0.0:
		var t := 1.0 - cup_time / 0.27
		var destination := Vector2(147 + 17 * maxi(0, shop.shelf.size() - 1), 258)
		cup(canvas, Vector2(74, 232).lerp(destination, t) + Vector2(0, -18 * sin(PI * t)), shop.produced, 0.73)
	box(canvas, Rect2(244, 232, 91, 67), Color("894f5d"), 8, INK)
	if shop.helper:
		person(canvas, Vector2(311, 225), 3, sin(animation * 5) * 1.4)
	box(canvas, Rect2(242, 229, 95, 14), Color("e0a16c"), 5, INK)
	box(canvas, Rect2(257, 211, 29, 22), Color("8bd8c3"), 5, INK)
	box(canvas, Rect2(264, 216, 14, 6), Color("34546a"), 1)
	# Queue actors approach and advance on the actual service event.
	for i in range(shop.customers.size() - 1, -1, -1):
		var id: int = shop.customers[i]
		person(canvas, walking.get(id, customer_spot(i)), id, sin(animation * 5 + id) * 1.1)
	if not shop.customers.is_empty():
		var first: Vector2 = walking.get(shop.customers[0], customer_spot(0))
		box(canvas, Rect2(first + Vector2(-13, -56), Vector2(26, 27)), CREAM, 9)
		cup(canvas, first + Vector2(0, -42), shop.shelf[0] if not shop.shelf.is_empty() else 0, 0.64)
		if shop.service > 0.0:
			progress(canvas, Rect2(first + Vector2(-23, 18), Vector2(46, 4)), shop.service / shop.service_duration())
	if coin_time > 0.0:
		var t := 1.0 - coin_time / 0.60
		for i in range(3):
			coin(canvas, Vector2(293 + (i - 1) * (9 + 13 * t), 282 - 64 * t - i * 9), 7.0 - 3 * t)

static func progress(canvas: CanvasItem, rect: Rect2, value: float) -> void:
	box(canvas, rect, INK, 3)
	if value > 0.0:
		box(canvas, Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0.0, 1.0), rect.size.y)), GOLD, 3)
