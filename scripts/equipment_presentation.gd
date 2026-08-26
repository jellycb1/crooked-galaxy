class_name EquipmentPresentation
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const Content = preload("res://scripts/content_db.gd")


static func localized_item_field(item: Dictionary, field: String) -> String:
	var item_id := str(item.get("id", ""))
	if str(item.get("challenge_origin", "")) == "fenda_clandestina":
		return LocaleRules.text("RIFT_REWARD_%s_%s" % [item_id.trim_suffix("_reward").to_upper(), field.to_upper()], str(item.get(field, "")))
	if item_id == "starter_weapon" or item_id == "starter_armor":
		return LocaleRules.text("ITEM_%s_%s" % [item_id.to_upper(), field.to_upper()], str(item.get(field, "")))
	var planet_id := str(item.get("origin_planet_id", Content.PLANET.id))
	var slot := str(item.get("slot", "weapon"))
	var catalog := Content.item_catalog_for(planet_id, slot)
	for index in catalog.size():
		if str(catalog[index].get("name", "")) == str(item.get("name", "")):
			var key := "ITEM_%s_%s_%d_%s" % [planet_id.to_upper(), slot.to_upper(), index, field.to_upper()]
			return LocaleRules.text(key, str(item.get(field, "")))
	return str(item.get(field, ""))


static func localized_trait_field(trait_data: Dictionary, field: String) -> String:
	return LocaleRules.text("ITEM_TRAIT_%s_%s" % [str(trait_data.get("id", "")).to_upper(), field.to_upper()], str(trait_data.get(field, "")))


static func localized_rarity(rarity: String) -> String:
	match rarity:
		"Épico": return LocaleRules.text("RARITY_EPIC", "ÉPICO")
		"Raro": return LocaleRules.text("RARITY_RARE", "RARO")
		_: return LocaleRules.text("RARITY_COMMON", "COMUM")


static func localized_slot(slot: String) -> String:
	return LocaleRules.text("SLOT_%s" % slot.to_upper(), CoreRules.equipment_slot_name(slot))


static func filtered_inventory(inventory: Array, slot_filter: String, sort_mode: String) -> Array:
	var items := filtered_inventory_refs(inventory, slot_filter, sort_mode)
	return items.map(func(item): return item.duplicate(true))


static func filtered_inventory_refs(inventory: Array, slot_filter: String, sort_mode: String) -> Array:
	var items: Array = []
	for item in inventory:
		var item_slot := str(item.get("slot", ""))
		if slot_filter == "all" or item_slot == slot_filter or (slot_filter == "other" and item_slot != "weapon" and item_slot != "armor"):
			items.append(item)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return inventory_item_before(a, b, sort_mode)
	)
	return items


static func inventory_item_before(a: Dictionary, b: Dictionary, sort_mode: String) -> bool:
	if sort_mode == "rarity":
		var rarity_difference := rarity_weight(str(a.get("rarity", "Comum"))) - rarity_weight(str(b.get("rarity", "Comum")))
		if rarity_difference != 0:
			return rarity_difference > 0
	var power_difference := CoreRules.equipment_score(a) - CoreRules.equipment_score(b)
	if power_difference != 0:
		return power_difference > 0
	return str(a.get("id", "")) < str(b.get("id", ""))


static func rarity_weight(rarity: String) -> int:
	match rarity:
		"Épico":
			return 3
		"Raro":
			return 2
		_:
			return 1


static func equipment_deltas(player: Dictionary, item: Dictionary) -> Dictionary:
	var slot := str(item.get("slot", ""))
	if not CoreRules.is_equipment_slot(slot):
		return {"power": 0, "health": 0, "upgrade": false}
	var simulated := player.duplicate(true)
	simulated[slot] = item
	return {
		"power": CoreRules.player_power(simulated) - CoreRules.player_power(player),
		"health": CoreRules.max_health(simulated) - CoreRules.max_health(player),
		"opening_damage": CoreRules.player_opening_damage(simulated) - CoreRules.player_opening_damage(player),
		"damage_reduction": CoreRules.player_damage_reduction(simulated) - CoreRules.player_damage_reduction(player),
		"counter_damage": CoreRules.player_counter_damage(simulated, 12) - CoreRules.player_counter_damage(player, 12),
		"evasion_chance": CoreRules.player_evasion_chance(simulated) - CoreRules.player_evasion_chance(player),
		"defense_bypass": CoreRules.player_defense_bypass(simulated) - CoreRules.player_defense_bypass(player),
		"follow_up_ratio": CoreRules.equipment_trait_total(simulated, "follow_up_damage_ratio") - CoreRules.equipment_trait_total(player, "follow_up_damage_ratio"),
		"set_bonus": CoreRules.equipment_set_bonus_power(simulated) - CoreRules.equipment_set_bonus_power(player),
		"upgrade": CoreRules.is_upgrade_for_player(player, item),
	}


static func equipment_delta_text(player: Dictionary, item: Dictionary) -> String:
	var deltas := equipment_deltas(player, item)
	var parts: Array[String] = []
	if int(deltas.power) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_POWER", "%+d PODER", [int(deltas.power)]))
	if int(deltas.health) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_HEALTH", "%+d VIDA", [int(deltas.health)]))
	if int(deltas.opening_damage) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_AMBUSH", "%+d EMBOSCADA", [int(deltas.opening_damage)]))
	if int(deltas.damage_reduction) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_REDUCTION", "%+d REDUÇÃO", [int(deltas.damage_reduction)]))
	if int(deltas.counter_damage) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_COUNTER", "%+d CONTRA-ATAQUE", [int(deltas.counter_damage)]))
	if not is_zero_approx(float(deltas.evasion_chance)):
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_EVASION", "%+.1f%% ESQUIVA", [float(deltas.evasion_chance) * 100.0]))
	if int(deltas.defense_bypass) != 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_BYPASS", "%+d SOBRECARGA", [int(deltas.defense_bypass)]))
	if not is_zero_approx(float(deltas.follow_up_ratio)):
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_BURST", "%+.0f%% RAJADA", [float(deltas.follow_up_ratio) * 100.0]))
	if int(deltas.set_bonus) > 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_ACTIVATE_KIT", "ATIVA KIT +%d PODER / +%d VIDA", [CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]))
	elif int(deltas.set_bonus) < 0:
		parts.append(LocaleRules.text("EQUIPMENT_DELTA_BREAK_KIT", "QUEBRA KIT -%d PODER / -%d VIDA", [CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]))
	if parts.is_empty():
		return LocaleRules.text("EQUIPMENT_DELTA_SAME", "= MESMO EFEITO")
	return ("▲ " if bool(deltas.upgrade) else "▼ ") + " · ".join(parts)
