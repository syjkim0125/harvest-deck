extends Button
## The illustration, title and description share the native button's hit area.

var artwork: TextureRect
var heading: Label
var caption: Label
var surface: StyleBoxFlat

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size.y = 51
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	surface = make_surface(Color("283e3b"), Color("496358"))
	add_theme_stylebox_override("normal", surface)
	add_theme_stylebox_override("hover", make_surface(Color("364e43"), Color("f9d088")))
	add_theme_stylebox_override("pressed", make_surface(Color("455a47"), Color("ffe19f")))
	add_theme_stylebox_override("disabled", make_surface(Color("243432"), Color("415049")))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_top = 4
	row.offset_right = -6
	row.offset_bottom = -4
	row.add_theme_constant_override("separation", 8)

	var art_frame := PanelContainer.new()
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.custom_minimum_size.x = 46
	art_frame.add_theme_stylebox_override("panel", make_surface(Color("c2d4a7"), Color("253f3d")))
	row.add_child(art_frame)
	artwork = TextureRect.new()
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_frame.add_child(artwork)

	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 1)
	row.add_child(words)
	heading = make_label(words, 14, Color("fff0cd"))
	caption = make_label(words, 12, Color("cfdfce"))

func make_label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label

func make_surface(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style

func present(icon: Texture2D, title: String, description: String, selected: bool = false, unavailable: bool = false) -> void:
	if artwork.texture != icon:
		artwork.texture = icon
	heading.text = title
	caption.text = description
	tooltip_text = title + "\n" + description
	disabled = unavailable
	artwork.modulate = Color(0.72, 0.76, 0.71) if unavailable else Color.WHITE
	surface.bg_color = Color("425c44") if selected else Color("283e3b")
	surface.border_color = Color("e6b567") if selected else Color("496358")
