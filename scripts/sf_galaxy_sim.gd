extends RefCounted
## Deterministic, UI-free living galaxy simulation. No saved-game schema yet.
## Every hyperspace jump advances competing NPC factions independently of the player.

const FREE := "free"
const HELION := "helion"
const VELA := "vela"
const ASH := "ash"
const CHOIR := "choir"
const DUSK := "dusk"

const FACTIONS := {
	"free": {"name": "Free Drifters", "leader": "", "power": 0, "color": Color("#a8c5d7")},
	"helion": {"name": "Helion Directorate", "leader": "Marshal Voss", "power": 7, "color": Color("#f3b26d")},
	"vela": {"name": "Vela Compact", "leader": "Broker Minae", "power": 5, "color": Color("#80e2c8")},
	"ash": {"name": "Ashline Freefront", "leader": "Captain Rook", "power": 6, "color": Color("#f37491")},
	"choir": {"name": "Choir of the Veil", "leader": "Oracle Sevrin", "power": 5, "color": Color("#bc9ffc")},
	"dusk": {"name": "Dusk Corsairs", "leader": "Admiral Kest", "power": 6, "color": Color("#ff707f")}
}
# Routes are bidirectional. Zone 0 is independent trade space.
const START_SYSTEMS := [
	{"name": "FREEPORT", "owner": FREE, "pos": Vector2(85, 343), "routes": [1, 2], "risk": 0},
	{"name": "HELION REACH", "owner": HELION, "pos": Vector2(207, 291), "routes": [0, 3], "risk": 1},
	{"name": "VEIL MOON", "owner": CHOIR, "pos": Vector2(144, 448), "routes": [0, 3, 4], "risk": 2},
	{"name": "ASH FRONT", "owner": ASH, "pos": Vector2(287, 390), "routes": [1, 2, 4], "risk": 2},
	{"name": "DUSK GATE", "owner": DUSK, "pos": Vector2(274, 491), "routes": [2, 3], "risk": 3}
]

var rng := RandomNumberGenerator.new()
var systems: Array[Dictionary] = []
var visited: Array[bool] = []
var current_system := 0
var turns := 0
var fuel := 6
var credits := 18
var cargo := 0
var fame := 0
var war_events := 0
var last_news := "Neutral captain. Choose a route."
var last_encounter := ""

func _init(world_seed: int = 20261125) -> void:
	rng.seed = world_seed
	for entry in START_SYSTEMS:
		systems.append(entry.duplicate(true))
		visited.append(false)
	visited[0] = true

func is_named_recruitable(person_name: String) -> bool:
	# Faction leaders may negotiate, fight or issue missions, but never join crew.
	for faction in FACTIONS.values():
		if not String(faction["leader"]).is_empty() and person_name == String(faction["leader"]):
			return false
	return true

func can_travel(index: int) -> bool:
	if index < 0 or index >= systems.size() or fuel <= 0:
		return false
	if index == current_system:
		return false
	var routes: Array = systems[current_system]["routes"]
	return routes.has(index)

func travel_to(index: int) -> Dictionary:
	if not can_travel(index):
		return {"ok": false, "event": "Route locked or out of fuel."}
	fuel -= 1
	current_system = index
	visited[index] = true
	turns += 1
	var encounter := _roll_encounter(index)
	# NPC factions move and fight *without* being gated on player reputation.
	advance_factions()
	last_encounter = encounter
	return {"ok": true, "event": encounter, "system": index, "turn": turns}

func _roll_encounter(index: int) -> String:
	var owner: String = systems[index]["owner"]
	var options: Array[String] = [
		"Salvage beacon in the debris field.",
		"Unknown life signs near the ruins.",
		"Distress signal from a lost crew."
	]
	match owner:
		HELION:
			options.append("Directorate patrol requests ID.")
		ASH:
			options.append("Freefront scouts demand supplies.")
		CHOIR:
			options.append("Veil pilgrims protect a relic.")
		DUSK:
			options.append("Corsair ship preparing an ambush.")
		VELA:
			options.append("Trade convoy offers a contract.")
	return options[rng.randi_range(0, options.size() - 1)]

func advance_factions() -> void:
	# Contested borders are the only candidates: a war needs a geographic cause.
	var frontiers: Array[Vector2i] = []
	for i in range(systems.size()):
		for neighbor in systems[i]["routes"]:
			var j: int = neighbor
			if i >= j:
				continue
			var a: String = systems[i]["owner"]
			var b: String = systems[j]["owner"]
			if a != FREE and b != FREE and a != b:
				frontiers.append(Vector2i(i, j))
	if frontiers.is_empty():
		last_news = "Quiet cycle. No hostile borders."
		return
	var border: Vector2i = frontiers[rng.randi_range(0, frontiers.size() - 1)]
	var attacker_index: int = border.x if rng.randf() < 0.5 else border.y
	var defender_index: int = border.y if attacker_index == border.x else border.x
	var attacker: String = systems[attacker_index]["owner"]
	var defender: String = systems[defender_index]["owner"]
	# Most turns change the situation without flipping the entire map.
	var attack_roll: int = rng.randi_range(1, 6) + int(FACTIONS[attacker]["power"])
	var defence_roll: int = rng.randi_range(1, 6) + int(FACTIONS[defender]["power"]) + 2
	if attack_roll > defence_roll + 2:
		systems[defender_index]["owner"] = attacker
		war_events += 1
		last_news = "%s took %s." % [FACTIONS[attacker]["name"], systems[defender_index]["name"]]
	else:
		last_news = "%s skirmished with %s." % [FACTIONS[attacker]["name"], FACTIONS[defender]["name"]]

func finish_expedition(scrap: int, won: bool) -> void:
	var secured: int = maxi(scrap, 0)
	if not won:
		secured = floori(float(secured) / 2.0)
	cargo += secured
	credits += secured * 3
	if won:
		fame += 1
	fuel = mini(fuel + 1, 6)

func refuel_at_freeport() -> bool:
	if current_system != 0 or credits < 4 or fuel >= 6:
		return false
	credits -= 4
	fuel = mini(fuel + 3, 6)
	return true

func nearest_reachable(point: Vector2, radius: float = 34.0) -> int:
	var closest := -1
	var best := radius
	for i in range(systems.size()):
		var dist: float = point.distance_to(systems[i]["pos"])
		if can_travel(i) and dist < best:
			best = dist
			closest = i
	return closest
