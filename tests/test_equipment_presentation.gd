extends SceneTree

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")

var failures := 0


func _init() -> void:
	var inventory := [
		{"id": "common_armor", "slot": "armor", "power": 8, "rarity": "Comum"},
		{"id": "epic_weapon", "slot": "weapon", "power": 4, "rarity": "Épico"},
		{"id": "rare_weapon", "slot": "weapon", "power": 6, "rarity": "Raro"},
		{"id": "trait_weapon", "slot": "weapon", "power": 5, "rarity": "Raro", "trait": {"power_bonus": 2}},
		{"id": "spare_implant", "slot": "implant", "power": 3, "rarity": "Comum"},
	]
	var weapons := EquipmentPresentation.filtered_inventory(inventory, "weapon", "power")
	check(weapons.size() == 3, "slot filters exclude unrelated equipment")
	check(str(weapons[0].id) == "trait_weapon", "power sorting includes modification effects")
	var other_gear := EquipmentPresentation.filtered_inventory(inventory, "other", "power")
	check(other_gear.size() == 1 and str(other_gear[0].id) == "spare_implant", "grouped mobile filter exposes every non-core universal slot")
	var by_rarity := EquipmentPresentation.filtered_inventory(inventory, "all", "rarity")
	check(str(by_rarity[0].id) == "epic_weapon", "rarity sorting places epic equipment first")
	by_rarity[0].power = 99
	check(int(inventory[1].power) == 4, "presentation sorting does not mutate inventory")

	var player := {
		"level": 1,
		"base_power": 10,
		"weapon": {"slot": "weapon", "power": 5},
		"armor": {"slot": "armor", "power": 3},
	}
	var stronger := {"slot": "weapon", "power": 4, "trait": {"power_bonus": 2, "health_bonus": 10}}
	var deltas := EquipmentPresentation.equipment_deltas(player, stronger)
	check(int(deltas.power) == 1 and int(deltas.health) == 10, "comparison reports effective combat changes")
	check(bool(deltas.upgrade), "comparison recognizes a modified upgrade")
	check(EquipmentPresentation.equipment_delta_text(player, stronger) == "▲ +1 PODER · +10 VIDA", "comparison text summarizes both effects")
	check(EquipmentPresentation.equipment_delta_text(player, player.weapon) == "= MESMO EFEITO", "equal equipment has a stable summary")
	var ambush_weapon := {"slot": "weapon", "power": 5, "trait": {"opening_damage_bonus": 5}}
	check(EquipmentPresentation.equipment_delta_text(player, ambush_weapon) == "▲ +5 EMBOSCADA", "comparison text exposes opening-shot effects")
	var dampener_armor := {"slot": "armor", "power": 3, "trait": {"damage_reduction": 2}}
	check(EquipmentPresentation.equipment_delta_text(player, dampener_armor) == "▲ +2 REDUÇÃO", "comparison text exposes incoming damage reduction")
	var kit_player := {
		"level": 1,
		"base_power": 10,
		"weapon": {"slot": "weapon", "power": 5, "origin_planet_id": "dustball_prime"},
		"armor": {"slot": "armor", "power": 3, "origin_planet_id": "congelaria_sa"},
	}
	var matching_armor := {"slot": "armor", "power": 2, "origin_planet_id": "dustball_prime"}
	check(EquipmentPresentation.equipment_delta_text(kit_player, matching_armor) == "▲ +3 VIDA · ATIVA KIT +1 PODER / +6 VIDA", "comparison exposes the full tradeoff when a lower-base item completes a planetary kit")

	if failures == 0:
		print("PASS: equipment presentation is deterministic")
		quit(0)
	else:
		printerr("FAIL: %d equipment presentation test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
