extends RefCounted

const COOLER_CRATE = preload("res://assets/cooler-crate-v1.png")
const Day = preload("res://scripts/day_harvest.gd")
const MARKET = preload("res://assets/market-v1.png")
const CARDS = preload("res://assets/loadout-cards-v1.png")
const STALL_FRAME := Rect2(4, 4, 184, 152)

static func stall() -> AtlasTexture:
	return region(MARKET, STALL_FRAME)

static func drink(recipe: int) -> AtlasTexture:
	return region(MARKET, Rect2(4 + (recipe + 1) * 192, 4, 184, 152))

static func card(card_id: int) -> AtlasTexture:
	if card_id == Day.Card.COOLER_CRATE:
		return region(COOLER_CRATE, Rect2(0, 0, 120, 120))
	return region(CARDS, Rect2(4 + card_id % 4 * 128, 4 + (card_id >> 2) * 128, 120, 120))

static func region(sheet: Texture2D, bounds: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = bounds
	texture.filter_clip = true
	return texture
