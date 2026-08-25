class_name EquipmentPresentation
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")


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
		"set_bonus": CoreRules.equipment_set_bonus_power(simulated) - CoreRules.equipment_set_bonus_power(player),
		"upgrade": CoreRules.is_upgrade_for_player(player, item),
	}


static func equipment_delta_text(player: Dictionary, item: Dictionary) -> String:
	var deltas := equipment_deltas(player, item)
	var parts: Array[String] = []
	if int(deltas.power) != 0:
		parts.append("%+d PODER" % int(deltas.power))
	if int(deltas.health) != 0:
		parts.append("%+d VIDA" % int(deltas.health))
	if int(deltas.opening_damage) != 0:
		parts.append("%+d EMBOSCADA" % int(deltas.opening_damage))
	if int(deltas.damage_reduction) != 0:
		parts.append("%+d REDUÇÃO" % int(deltas.damage_reduction))
	if int(deltas.set_bonus) > 0:
		parts.append("ATIVA KIT +%d PODER / +%d VIDA" % [CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS])
	elif int(deltas.set_bonus) < 0:
		parts.append("QUEBRA KIT -%d PODER / -%d VIDA" % [CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS])
	if parts.is_empty():
		return "= MESMO EFEITO"
	return ("▲ " if bool(deltas.upgrade) else "▼ ") + " · ".join(parts)
