class_name MarketRules
extends RefCounted

const Content = preload("res://scripts/content_db.gd")
const Rules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const MonetizationRulesScript = preload("res://scripts/monetization_rules.gd")

const OFFER_COUNT := 3
const MAX_PURCHASE_RECORDS := 60


static func offers(player: Dictionary) -> Array[Dictionary]:
	var planet_id := str(player.get("current_planet_id", Content.PLANET.id))
	var cycle := maxi(0, int(player.get("market_cycle", 0)))
	var economy_day := maxi(0, int(player.get("economy_day", MonetizationRulesScript.utc_day_id())))
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
	rng.seed = 98173 + planet_index * 1301 + stock_tier * 101 + cycle * 7919 + economy_day * 104729
	var result: Array[Dictionary] = []
	for offer_index in OFFER_COUNT:
		var slot := offer_slot(player, offer_index)
		var mastery := 1 if offer_index < 2 else 3
		var item := Content.generate_loot(target, rng, mastery, slot)
		if MonetizationRulesScript.market_refresh_count(player) >= MonetizationRulesScript.MAX_MARKET_REFRESHES_PER_DAY and offer_index == OFFER_COUNT - 1:
			item = ensure_minimum_rare(item)
		var offer_id := "market_%s_%d_%d_%d_%d" % [planet_id, stock_tier, economy_day, cycle, offer_index]
		item.id = "%s_item" % offer_id
		result.append({
			"id": offer_id,
			"item": item,
			"price": item_price(item, planet_index, stock_tier),
			"purchased": player.get("market_purchased_offer_ids", []).has(offer_id),
		})
	return result


static func offer_slot(player: Dictionary, offer_index: int) -> String:
	if offer_index == 0:
		return "weapon"
	if offer_index == 1:
		return "armor"
	var planet_id := str(player.get("current_planet_id", Content.PLANET.id))
	var secondary_slots: Array[String] = []
	for slot in Content.loot_slots_for_planet(planet_id):
		if slot != "weapon" and slot != "armor" and not secondary_slots.has(slot):
			secondary_slots.append(slot)
	if secondary_slots.is_empty():
		return "weapon" if int(player.get("market_cycle", 0)) % 2 == 0 else "armor"
	var rotation := int(player.get("level", 1)) + int(player.get("market_cycle", 0)) + int(player.get("economy_day", 0))
	return secondary_slots[posmod(rotation, secondary_slots.size())]


static func item_price(item: Dictionary, planet_index: int, tier: int) -> int:
	var rarity_premium := 0
	match str(item.get("rarity", "Comum")):
		"Raro":
			rarity_premium = 120
		"Épico":
			rarity_premium = 300
	var trait_premium := 180 if Rules.has_intrinsic_modifier(item) else 0
	var secondary_slot := str(item.get("slot", "")) != "weapon" and str(item.get("slot", "")) != "armor"
	# Secondary power is intentionally flat, so its late-market price needs a
	# bounded career premium instead of inheriting primary item-power scaling.
	var late_lateral_step := maxi(0, tier - 50) if secondary_slot else 0
	var late_lateral_premium := late_lateral_step * late_lateral_step
	return maxi(60, 45 + int(item.get("power", 1)) * 18 + maxi(0, planet_index) * 90 + maxi(0, tier) * 40 + rarity_premium + trait_premium + late_lateral_premium)


static func refresh_cost(player: Dictionary) -> int:
	return MonetizationRulesScript.market_refresh_cost(player)


static func ensure_minimum_rare(item: Dictionary) -> Dictionary:
	var promoted := item.duplicate(true)
	if str(promoted.get("rarity", "Comum")) == "Comum":
		promoted.rarity = "Raro"
		promoted.color = "#58d9ff"
		if str(promoted.get("slot", "")) == "weapon" or str(promoted.get("slot", "")) == "armor":
			promoted.power = int(promoted.get("power", 1)) + 2
	if not Rules.has_intrinsic_modifier(promoted):
		var traits: Array = Content.ITEM_TRAITS.get(str(promoted.get("slot", "")), [])
		if not traits.is_empty():
			promoted.trait = (traits[abs(int(promoted.get("generation_seed", 0))) % traits.size()] as Dictionary).duplicate(true)
	return promoted


static func purchase_records_are_safe(records) -> bool:
	if not records is Array or records.size() > MAX_PURCHASE_RECORDS:
		return false
	for record in records:
		if not record is String or not str(record).begins_with("market_") or str(record).length() > 120:
			return false
	return true
