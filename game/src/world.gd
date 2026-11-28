extends RefCounted
# Fresh deterministic local star-system simulation; no retired runtime dependency.
const LIMIT := Rect2(-1450, -1600, 2900, 3200)
const PORT := Vector2(-150, 130)
const MOON := Vector2(153, -145)
const BEACON := Vector2(193, 267)
const RUIN := Vector2(-680, -830)
var position := Vector2.ZERO
var velocity := Vector2.ZERO
var heading := -PI / 2.0
var time := 0.0
var discovered: Array[String] = []
var cargo := 0
var credits := 18
var landed := ""
var collected := false
var contacted := false

func step(delta: float, steer: Vector2) -> void:
	var dt := clampf(delta, 0.0, 0.1)
	time += dt
	if landed.is_empty():
		var desired := steer.limit_length() * 235.0
		velocity = velocity.move_toward(desired, (470.0 if steer.length() > 0.02 else 240.0) * dt)
		position += velocity * dt
		position = position.clamp(LIMIT.position, LIMIT.end)
		if velocity.length() > 9.0:
			heading = lerp_angle(heading, velocity.angle(), 1.0 - exp(-dt * 8.0))
		for id in ["echo", "ruin"]:
			if position.distance_to(site(id)) < 180.0 and not discovered.has(id):
				discovered.append(id)

func site(id: String) -> Vector2:
	match id:
		"port": return PORT
		"moon": return MOON
		"echo": return BEACON
		"ruin": return RUIN
		"trader": return Vector2(105 + cos(time * 0.12 + 1.5) * 190, 5 + sin(time * 0.12 + 1.5) * 130)
		"courier": return Vector2(-540 + sin(time * 0.17) * 230, 290 + cos(time * 0.17) * 140)
	return Vector2.ZERO

func nearby() -> String:
	if not landed.is_empty():
		return ""
	var best := 100.0
	var result := ""
	for id in ["port", "moon", "echo", "ruin", "trader", "courier"]:
		if id in ["echo", "ruin"] and not discovered.has(id):
			continue
		if id == "echo" and collected:
			continue
		if id == "trader" and contacted:
			continue
		if id == "ruin":
			continue
		var d := position.distance_to(site(id))
		if d < best:
			best = d
			result = id
	return result

func interact(id: String) -> bool:
	if id.is_empty() or id != nearby():
		return false
	match id:
		"port", "moon":
			landed = id
			velocity = Vector2.ZERO
		"echo":
			collected = true
			cargo += 2
		"trader":
			contacted = true
		"courier":
			return true
		_:
			return false
	return true

func launch() -> bool:
	if landed.is_empty():
		return false
	landed = ""
	return true

func snapshot() -> Dictionary:
	return {"version":1,"x":position.x,"y":position.y,"vx":velocity.x,"vy":velocity.y,"heading":heading,"time":time,"discovered":discovered,"cargo":cargo,"credits":credits,"landed":landed,"collected":collected,"contacted":contacted}

func restore(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != 1:
		return false
	position = Vector2(float(data.get("x",0)),float(data.get("y",0))).clamp(LIMIT.position,LIMIT.end)
	velocity = Vector2(float(data.get("vx",0)),float(data.get("vy",0))).limit_length(235)
	heading = float(data.get("heading", -PI/2.0))
	time = maxf(0.0,float(data.get("time",0)))
	discovered.clear()
	for id in data.get("discovered", []):
		if id in ["echo","ruin"] and not discovered.has(id):
			discovered.append(id)
	cargo = maxi(0,int(data.get("cargo",0)))
	credits = maxi(0,int(data.get("credits",18)))
	landed = str(data.get("landed",""))
	if landed not in ["", "port", "moon"]:
		landed = ""
	collected = bool(data.get("collected",false))
	contacted = bool(data.get("contacted",false))
	return true
