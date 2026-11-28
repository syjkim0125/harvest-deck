extends SceneTree
const MODEL = preload("res://src/world.gd")
var fails := 0
var checks := 0
func check(ok: bool,label: String) -> void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: fails+=1
func _initialize() -> void:
	var w = MODEL.new()
	var npc: Vector2=w.site("trader")
	for i in range(120): w.step(1.0/60,Vector2.RIGHT)
	check(w.position.x>200,"direct continuous travel")
	check(w.site("trader")!=npc,"NPC moves independent of player")
	var v: float=w.velocity.length()
	w.step(1.0/60,Vector2.ZERO)
	check(w.velocity.length()>0 and w.velocity.length()<v,"release coasts then decelerates")
	for i in range(120): w.step(1.0/60,Vector2.ZERO)
	check(w.velocity.length()<0.1,"ship stops")
	w.position=MODEL.MOON
	w.step(0.02,Vector2.ZERO)
	check(w.landed.is_empty(),"proximity does not force landing")
	check(w.interact("moon"),"deliberate landing")
	var t: float=w.time
	var p: Vector2=w.position
	w.step(0.1,Vector2.RIGHT)
	check(w.position==p and w.time>t,"same world advances during arrival")
	check(w.launch() and w.position==p,"return to identical world")
	w.position=MODEL.BEACON
	w.step(0.01,Vector2.ZERO)
	check(w.discovered.has("echo"),"proximity reveals hidden signal")
	check(w.interact("echo") and w.cargo==2,"intentional salvage")
	check(not w.interact("echo") and w.cargo==2,"no duplicate salvage")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(w.snapshot()))
	var next=MODEL.new()
	check(next.restore(saved) and next.position==w.position and next.time==w.time and next.collected and next.discovered==w.discovered,"save restores same world without elapsed wall time")
	print("M1 WORLD: %d checks / %d failures"%[checks,fails])
	quit(1 if fails else 0)
