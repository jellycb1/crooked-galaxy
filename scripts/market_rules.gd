class_name MarketRules
extends RefCounted

const Content = preload("res://scripts/content_db.gd")
const Rules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")

const OFFER_COUNT := 3
const MAX_PURCHASE_RECORDS := 60


static func offers(player: Dictionary) -> Array[Dictionary]:
	var planet_id := str(player.get("current_planet_id", Content.PLANET.id))
	var cycle := maxi(0, int(player.get("market_cycle", 0)))
	var planet_index := Content.planet_index_for(planet_id)
	var templates := MissionRules.targets_for_planet(planet_id)
	if templates.is_empty():
		return []
	var target := MissionRules.offer_for_target(player, templates[(int(player.get("level", 1)) + cycle) % templates.size()])
	if target.is_empty():
		return []
	# Stock follows the fixed level curve but trails the live contract by one
	# level-equivalent power step, preserving the market as optional catch-up.
	target.loot_power = maxi(10, int(target.loot_power) - 4)
	var stock_tier := maxi(1, int(player.get("level", 1)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 98173 + planet_index * 1301 + stock_tier * 101 + cycle * 7919
	var result: Array[Dictionary] = []
	for offer_index in OFFER_COUNT:
		var slot := "weapon" if offer_index == 0 else ("armor" if offer_index == 1 else ("weapon" if cycle % 2 == 0 else "armor"))
		var mastery := 1 if offer_index < 2 else 3
		var item := Content.generate_loot(target, rng, mastery, slot)
		var offer_id := "market_%s_%d_%d_%d" % [planet_id, stock_tier, cycle, offer_index]
		item.id = "%s_item" % offer_id
		result.append({
			"id": offer_id,
			"item": item,
			"price": item_price(item, planet_index, stock_tier),
			"purchased": player.get("market_purchased_offer_ids", []).has(offer_id),
		})
	return result


static func item_price(item: Dictionary, planet_index: int, tier: int) -> int:
	var rarity_premium := 0
	match str(item.get("rarity", "Comum")):
		"Raro":
			rarity_premium = 120
		"Épico":
			rarity_premium = 300
	var trait_premium := 180 if item.has("trait") else 0
	return maxi(60, 45 + int(item.get("power", 1)) * 18 + maxi(0, planet_index) * 90 + maxi(0, tier) * 40 + rarity_premium + trait_premium)


static func refresh_cost(player: Dictionary) -> int:
	var planet_id := str(player.get("current_planet_id", Content.PLANET.id))
	var level_band := maxi(0, int(player.get("level", 1)) - 1)
	return 75 + Content.planet_index_for(planet_id) * 180 + level_band * 30 + mini(10, maxi(0, int(player.get("market_cycle", 0)))) * 25


static func purchase_records_are_safe(records) -> bool:
	if not records is Array or records.size() > MAX_PURCHASE_RECORDS:
		return false
	for record in records:
		if not record is String or not str(record).begins_with("market_") or str(record).length() > 120:
			return false
	return true
