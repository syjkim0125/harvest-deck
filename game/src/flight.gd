extends Node2D
const MODEL = preload("res://src/world.gd")
const SKY = preload("res://art/nebula.svg")
const SHIP = preload("res://art/courier.svg")
const MOON = preload("res://art/verdant-moon.svg")
const PORT = preload("res://art/port.svg")
const NPC = preload("res://art/freighter.svg")
const RELAY = preload("res://art/relay.svg")
const INK := Color("#101a2a")
const WHITE := Color("#e9ecdf")
const MINT := Color("#a7ebd7")
const GOLD := Color("#e6bc89")
const SAVE := "user://first_light_v1.json"
var world := MODEL.new()
var font := ThemeDB.fallback_font
var finger := -1
var start := Vector2.ZERO
var pointer := Vector2.ZERO
var steer := Vector2.ZERO
var cam := Vector2.ZERO
var zoom := 1.0
var stars: Array[Vector3] = []
var message := "Free drift • Kestrel Reach"
var message_time := 5.0
var save_time := 0.0
var audio: AudioStreamPlayer
var chime: AudioStreamWAV
var ambient: AudioStreamPlayer
var muted := false
var paused := false
var test_mode := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var rng := RandomNumberGenerator.new()
	rng.seed = 319
	for i in range(190):
		stars.append(Vector3(rng.randf_range(0,1200),rng.randf_range(0,1800),rng.randf_range(0.45,1.8)))
	audio = AudioStreamPlayer.new()
	add_child(audio)
	chime = make_sound(false)
	audio.stream = chime
	ambient = AudioStreamPlayer.new()
	add_child(ambient)
	ambient.stream = make_sound(true)
	ambient.volume_db = -24.0
	if not test_mode and FileAccess.file_exists(SAVE):
		var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if data is Dictionary:
			world.restore(data)
	cam = world.position
	queue_redraw()

func make_sound(loop: bool) -> AudioStreamWAV:
	var rate := 22050
	var length := 4.0 if loop else 0.46
	var count := int(rate * length)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	for i in range(count):
		var t := float(i)/rate
		var v := 0.0
		if loop:
			v = (sin(TAU*55*t)*0.6+sin(TAU*82.5*t)*0.22+sin(TAU*110*t)*0.12)*(0.55+0.3*sin(TAU*t/4))
		else:
			v = (sin(TAU*440*t)*0.45+sin(TAU*660*t)*0.25)*minf(t*35,1.0)*exp(-t*8)
		bytes.encode_s16(i*2,int(v*8000))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = count
	return wav

func _exit_tree() -> void:
	store()
	for player in [audio,ambient]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	chime = null

func store() -> void:
	if test_mode: return
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(world.snapshot(),"",true,true))

func say(s: String) -> void:
	message = s
	message_time = 4.2
	if not test_mode and not muted and is_instance_valid(audio): audio.play()

func action_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(size.x*0.12,size.y-142,size.x*0.76,58)

func pause_rect() -> Rect2:
	return Rect2(get_viewport_rect().size.x-61,19,43,43)

func sound_rect() -> Rect2:
	return Rect2(get_viewport_rect().size.x-112,19,43,43)

func resume_audio() -> void:
	if not test_mode and not muted and not paused and not ambient.playing: ambient.play()

func begin(id: int,p: Vector2) -> void:
	if finger != -1: return
	if pause_rect().has_point(p):
		paused = not paused
		if paused:
			ambient.stop()
			store()
		else: resume_audio()
		return
	if sound_rect().has_point(p):
		muted = not muted
		if muted: ambient.stop()
		else: resume_audio()
		return
	if paused: return
	resume_audio()
	if action_rect().has_point(p):
		if not world.landed.is_empty():
			world.launch()
			say("Undocked • continue your voyage")
			store()
			return
		var near: String = world.nearby()
		if world.interact(near):
			match near:
				"echo": say("Recovered • 2 alloy fragments")
				"trader": say("Merchant: a strange signal east of here.")
				"courier": say("Courier: safe travels, captain.")
				_: say("Arrival • return whenever you choose")
			store()
			return
	if not world.landed.is_empty(): return
	finger = id
	start = p
	pointer = p

func drag(id: int,p: Vector2) -> void:
	if finger == id:
		pointer = p
		steer = ((p-start)/78.0).limit_length()

func end(id: int) -> void:
	if finger == id:
		finger = -1
		steer = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: begin(event.index,event.position)
		else: end(event.index)
	elif event is InputEventScreenDrag:
		drag(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: begin(-2,event.position)
		else: end(-2)
	elif event is InputEventMouseMotion:
		drag(-2,event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E: begin(-3,action_rect().get_center()); end(-3)
		if event.keycode == KEY_ESCAPE: begin(-3,pause_rect().get_center())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ambient):
		finger = -1
		steer = Vector2.ZERO
		paused = true
		ambient.stop()
		store()

func _process(dt: float) -> void:
	if not paused:
		var axis := steer
		if finger == -1:
			axis = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length()
		var before: int = world.discovered.size()
		world.step(dt,axis)
		if before != world.discovered.size():
			say("New discovery • "+("silent relay" if world.discovered.back()=="echo" else "ancient wreck"))
			store()
		cam = cam.lerp(world.position,1.0-exp(-dt*5.0))
		var target_zoom := 0.91 if world.velocity.length()>155 else 1.02
		zoom = lerpf(zoom,target_zoom,1.0-exp(-dt*2.3))
		message_time = maxf(0.0,message_time-dt)
		save_time += dt
		if save_time > 8.0:
			save_time = 0.0
			store()
	queue_redraw()

func txt(s: String,p: Vector2,sz: int=16,color: Color=WHITE) -> void:
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)

func center_txt(s: String,r: Rect2,sz: int=16,color: Color=WHITE) -> void:
	var width := font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz).x
	txt(s,Vector2(r.get_center().x-width/2,r.get_center().y+sz*0.34),sz,color)

func panel(r: Rect2, color: Color=Color("#17273b"), radius: int=12) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = Color("#5a7880")
	style.set_border_width_all(1)
	draw_style_box(style,r)

func ship(texture: Texture2D,p: Vector2,angle: float,size: Vector2,thrust: float=0.0) -> void:
	draw_set_transform(p,angle,Vector2.ONE)
	if thrust>0.04:
		var length := 14+thrust*27+sin(world.time*34)*3
		for y in [-13.0,13.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(-26,y-4),Vector2(-26-length,y),Vector2(-26,y+4)]),Color("#65e6d2",0.65))
			draw_line(Vector2(-26,y),Vector2(-36-thrust*8,y),Color("#edffdd"),2,true)
	draw_texture_rect(texture,Rect2(-size/2,size),false)
	draw_set_transform(Vector2.ZERO)

func wp(p: Vector2) -> Vector2:
	return get_viewport_rect().size/2+(p-cam)*zoom

func ring(p: Vector2,r: float,c: Color) -> void:
	draw_arc(p,r,0,TAU,64,c,1.3,true)

func marker(id: String,label: String,sub: String,texture: Texture2D,diameter: float,color: Color) -> void:
	var p := wp(world.site(id))
	var d := diameter*zoom
	draw_texture_rect(texture,Rect2(p-Vector2.ONE*d/2,Vector2.ONE*d),false)
	if world.position.distance_to(world.site(id)) < 260.0 or id in ["port","moon"]:
		var r := Rect2(p+Vector2(-74,d*0.38+5),Vector2(148,38))
		panel(r,Color("#102034",0.92),8)
		center_txt(label,Rect2(r.position,r.size-Vector2(0,16)),13,color)
		center_txt(sub,Rect2(r.position+Vector2(0,20),Vector2(148,15)),10,WHITE)

func edge_hint(id: String,label: String,col: Color) -> void:
	var size := get_viewport_rect().size
	var p := wp(world.site(id))
	var safe := Rect2(45,155,size.x-90,size.y-340)
	if safe.has_point(p): return
	var offset := p-size/2
	if offset.length()<1: return
	var ratio := minf((safe.size.x/2)/maxf(absf(offset.x),0.01),(safe.size.y/2)/maxf(absf(offset.y),0.01))
	var q := size/2+offset*ratio
	var u := offset.normalized()
	draw_colored_polygon(PackedVector2Array([q+u*7,q-u*4+u.orthogonal()*4,q-u*4-u.orthogonal()*4]),col)
	center_txt(label,Rect2(q+Vector2(-43,10),Vector2(86,16)),11,col)

func _draw() -> void:
	var sz := get_viewport_rect().size
	draw_texture_rect(SKY,Rect2(Vector2.ZERO,sz),false)
	for s in stars:
		var p := Vector2(fposmod(s.x-cam.x*0.23,sz.x),fposmod(s.y-cam.y*0.23,sz.y))
		draw_circle(p,s.z,Color("#dbebeb",0.48),true,-1.0,true)
	# Visible bodies and subtle environmental cues; unknown sites have no map labels.
	var moon_p := wp(world.site("moon"))
	ring(moon_p,114*zoom,Color("#92c7c9",0.15))
	marker("moon","VEYRA","quiet moon",MOON,210,MINT)
	marker("port","HALCYON","free station",PORT,105,GOLD)
	var ep := wp(world.site("echo"))
	if not world.collected:
		var pulse := fposmod(world.time*0.7,1.0)
		ring(ep,12+pulse*34,Color("#a7ebd7",(1-pulse)*0.48))
		if world.discovered.has("echo"):
			marker("echo","SILENT RELAY","salvage signal",RELAY,63,MINT)
		else: draw_circle(ep,3.5,MINT)
	var rp := wp(world.site("ruin"))
	if world.discovered.has("ruin"):
		marker("ruin","OLD WRECK","charted",RELAY,85,GOLD)
	else:
		draw_circle(rp,2.8,Color("#c6a3bd"))
	for id in ["trader","courier"]:
		var p := wp(world.site(id))
		var a := world.time*(0.12 if id=="trader" else 0.17)
		var heading := Vector2(-sin(a)*350,cos(a)*175).angle() if id=="trader" else Vector2(cos(a)*230,-sin(a)*140).angle()
		ship(NPC,p,heading,Vector2(76,46)*zoom,0.32)
		if p.distance_to(wp(world.position)) < 160:
			center_txt("VELA MERCHANT" if id=="trader" else "CIVILIAN",Rect2(p+Vector2(-72,31),Vector2(144,15)),10,GOLD)
	# Near debris, decorative not collidable in M1.
	for i in range(24):
		var a := i*2.39996
		var d := 155+float(i%7)*25
		var p := wp(Vector2(-610,50)+Vector2(cos(a),sin(a)*0.65)*d)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-2),p+Vector2(1,-6),p+Vector2(7,0),p+Vector2(0,5)]),Color("#607181",0.62))
	ship(SHIP,wp(world.position),world.heading,Vector2(94,94)*zoom,world.velocity.length()/235.0)
	for id in ["port","moon"]:
		edge_hint(id,"STATION" if id=="port" else "MOON",GOLD if id=="port" else MINT)
	if finger != -1:
		ring(start,38,Color("#8bbdbd",0.26))
		draw_line(start,start+steer*36,Color("#9ed9ca",0.6),2,true)
		draw_circle(start+steer*36,6,Color("#c0ede0",0.75))
	paint_hud(sz)
	if not world.landed.is_empty(): paint_arrival(sz)
	if paused:
		panel(Rect2(36,sz.y/2-76,sz.x-72,152),Color("#152438",0.98))
		center_txt("FLIGHT PAUSED",Rect2(36,sz.y/2-58,sz.x-72,50),25,MINT)
		center_txt("Tap II to resume",Rect2(36,sz.y/2,sz.x-72,35),15,WHITE)

func paint_hud(sz: Vector2) -> void:
	panel(Rect2(16,18,sz.x-140,99),Color("#0c1b2b",0.94))
	txt("V O I D   C A R A V A N",Vector2(29,43),15,MINT)
	txt("KESTREL REACH",Vector2(29,67),22,WHITE)
	txt("01  •  FREE DRIFT",Vector2(29,94),12,GOLD)
	panel(sound_rect())
	center_txt("×" if muted else "♫",sound_rect(),19,WHITE)
	panel(pause_rect())
	center_txt("II" if not paused else "▶",pause_rect(),19,MINT)
	panel(Rect2(16,128,sz.x-32,48),Color("#101d30",0.86))
	txt("CARGO  %02d"%world.cargo,Vector2(29,157),14,GOLD)
	txt("LOG  %02d"%world.discovered.size(),Vector2(sz.x*0.42,157),14,MINT)
	var speed := world.velocity.length()
	txt("%03d m/s"%int(speed),Vector2(sz.x-115,157),14,WHITE)
	if message_time>0.0:
		panel(Rect2(25,188,sz.x-50,44),Color("#193044",0.9))
		center_txt(message,Rect2(25,188,sz.x-50,44),14,WHITE)
	var near: String = world.nearby()
	if not near.is_empty() and world.landed.is_empty():
		var label: String = {"port":"DOCK  /  HALCYON","moon":"LAND  /  VEYRA","echo":"RECOVER RELAY","trader":"HAIL MERCHANT","courier":"HAIL COURIER"}[near]
		panel(action_rect(),Color("#254f55"))
		center_txt(label,action_rect(),17,MINT)
	elif world.landed.is_empty() and world.time<25.0:
		center_txt("Drag anywhere to steer",Rect2(0,sz.y-112,sz.x,36),16,WHITE)
		center_txt("Release to coast • approach to interact",Rect2(0,sz.y-81,sz.x,26),12,MINT)
	# Thin lower safe-area footer.
	draw_line(Vector2(25,sz.y-41),Vector2(sz.x-25,sz.y-41),Color("#94b5b6",0.27),1)
	txt("FIRST LIGHT   /   M1 PLAYABLE STUDY",Vector2(25,sz.y-19),11,Color("#b1c8c8"))
	txt("v0.1",Vector2(sz.x-53,sz.y-19),11,GOLD)

func paint_arrival(sz: Vector2) -> void:
	var r := Rect2(22,sz.y*0.29,sz.x-44,sz.y*0.53)
	panel(r,Color("#101f31",0.98),18)
	var is_moon: bool = world.landed=="moon"
	var title := "VEYRA" if is_moon else "HALCYON"
	center_txt("ARRIVAL CONFIRMED",Rect2(r.position+Vector2(0,13),Vector2(r.size.x,34)),12,GOLD)
	center_txt(title,Rect2(r.position+Vector2(0,47),Vector2(r.size.x,40)),29,WHITE)
	var tex := MOON if is_moon else PORT
	var d := minf(r.size.x*0.46,r.size.y*0.37)
	draw_texture_rect(tex,Rect2(r.get_center()-Vector2(d/2,d/2+10),Vector2(d,d)),false)
	center_txt("Surface exploration is the next milestone." if is_moon else "Station services are the next milestone.",Rect2(r.position+Vector2(0,r.size.y-134),Vector2(r.size.x,35)),13,MINT)
	center_txt("Your voyage and discoveries are saved.",Rect2(r.position+Vector2(0,r.size.y-105),Vector2(r.size.x,28)),12,WHITE)
	panel(action_rect(),Color("#254f55"))
	center_txt("LAUNCH  /  RETURN TO SPACE",action_rect(),16,MINT)
