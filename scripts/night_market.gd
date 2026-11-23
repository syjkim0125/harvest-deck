extends RefCounted

const Production = preload("res://scripts/production.gd")
const SpineMelon = preload("res://scripts/spine_melon.gd")

const RollingOrange = preload("res://scripts/rolling_orange.gd")

enum Phase { OFF, MENU, SERVICE, CLOSED }
enum Recipe { WATERMELON, MELON, ORANGE }

const FEES := [10, 12, 20]
const DAYS := 3
const COCKTAIL_BONUS := 3
const COCKTAIL_EXTRA_TIME := 0.25
const NAMES := ["Watermelon juice", "Spine melon special", "Orange fizz"]
const INGREDIENTS := ["1 watermelon", "1 watermelon + 1 spine melon", "1 watermelon + 1 orange"]
const EXTRA_FRUIT := [-1, SpineMelon.KIND, RollingOrange.KIND]
const PRICES := [Production.PRICE, 12, 9]
const ORDERS := [[5, 3, 0], [7, 1, 3], [4, 6, 0]]
const MIX_TIMES := [Production.MIX_SECONDS, Production.MIX_SECONDS + 0.35, Production.MIX_SECONDS + 0.20]

var phase := Phase.OFF
var fee := FEES[0]
var demand: Array = ORDERS[0]
var cocktail := false
var stock: Array[int] = []
var selected: Array[bool] = [false, false, false]
var sold: Array[int] = [0, 0, 0]
var gross := 0
var active_recipe := -1
var remaining := 0.0

func reset(day_number := 1) -> void:
	phase = Phase.OFF
	fee = FEES[day_number - 1]
	demand = ORDERS[day_number - 1]
	cocktail = false
	stock = []
	selected.fill(false)
	sold.fill(0)
	gross = 0
	active_recipe = -1
	remaining = 0.0

func enter(safe_stock: Array[int]) -> bool:
	if phase != Phase.OFF:
		return false
	# Day and night see the same depot inventory. No second grant at transition.
	stock = safe_stock
	phase = Phase.MENU
	return true

func offers(recipe: int) -> bool:
	return recipe >= 0 and recipe < demand.size() and demand[recipe] > 0

func portions(recipe: int) -> int:
	if not offers(recipe):
		return 0
	var watermelon := stock.count(0)
	var extra: int = EXTRA_FRUIT[recipe]
	return watermelon if extra == -1 else mini(watermelon, stock.count(extra))

func has_available_menu() -> bool:
	# All recipes require one watermelon.
	return portions(Recipe.WATERMELON) > 0

func toggle_recipe(recipe: int) -> bool:
	if phase != Phase.MENU or portions(recipe) == 0:
		return false
	selected[recipe] = not selected[recipe]
	return true

func open() -> bool:
	if phase != Phase.MENU or not selected.has(true):
		return false
	phase = Phase.SERVICE
	return true

func can_serve(recipe: int) -> bool:
	return phase == Phase.SERVICE and active_recipe == -1 and portions(recipe) > 0 and selected[recipe] and sold[recipe] < demand[recipe]

func serve(recipe: int) -> bool:
	if not can_serve(recipe):
		return false
	stock.erase(0)
	var extra: int = EXTRA_FRUIT[recipe]
	if extra != -1:
		stock.erase(extra)
	active_recipe = recipe
	remaining = duration(recipe)
	return true

func price(recipe: int) -> int:
	return PRICES[recipe] + (COCKTAIL_BONUS if cocktail and recipe == Recipe.MELON else 0)

func duration(recipe: int) -> float:
	var extra := COCKTAIL_EXTRA_TIME if cocktail and recipe == Recipe.MELON else 0.0
	return MIX_TIMES[recipe] + Production.SALE_SECONDS + extra

func step(delta: float) -> void:
	if active_recipe == -1 or delta <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.000001:
		sold[active_recipe] += 1
		gross += price(active_recipe)
		active_recipe = -1
		remaining = 0.0

func close() -> bool:
	if active_recipe != -1:
		return false
	if phase != Phase.SERVICE and (phase != Phase.MENU or has_available_menu()):
		return false
	phase = Phase.CLOSED
	return true

func net() -> int:
	return gross - fee
