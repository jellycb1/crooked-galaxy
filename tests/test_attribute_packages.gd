extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Packages = preload("res://scripts/attribute_package_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const StateScript = preload("res://scripts/game_state.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")

var failures := 0


func _init() -> void:
	check(Packages.DEFINITIONS.size() == 5 and Packages.ELIGIBLE_SLOTS.size() == 5, "the first slice covers five attributes on secondary equipment only")
	check(not Packages.is_eligible_slot("weapon") and not Packages.is_eligible_slot("armor") and Packages.is_eligible_slot("implant"), "packages cannot inflate the primary weapon curve")

	var base := player_for("warrant_breaker")
	var strength := with_package(base, "helmet", "breach_calibration")
	check(Rules.player_power(strength) == Rules.player_power(base) + 1, "strength package contributes through the universal attribute rule")
	var vitality := with_package(base, "helmet", "reinforced_biomesh")
	check(Rules.max_health(vitality) == Rules.max_health(base) + 12, "vitality package grants a readable health sidegrade")
	var dexterity := with_package(player_for("orbit_gunslinger"), "boots", "reflex_tuning")
	var gunslinger := player_for("orbit_gunslinger")
	check(Rules.player_damage_reduction(dexterity) == Rules.player_damage_reduction(gunslinger) + 1 and Rules.player_power(dexterity) == Rules.player_power(gunslinger) + 1, "primary dexterity crosses universal and Gunslinger breakpoints")
	var intelligence := with_package(player_for("contract_hacker"), "implant", "neural_overclock")
	var hacker := player_for("contract_hacker")
	check(Rules.player_power(intelligence) == Rules.player_power(hacker) + 1 and Rules.player_opening_damage(intelligence) == Rules.player_opening_damage(hacker) + 3, "primary intelligence feeds both universal and Hacker specialization rules")
	var cunning := with_package(base, "rig", "crooked_instinct")
	check(is_equal_approx(Rules.player_attack_roll(cunning, 0.5) - Rules.player_attack_roll(base, 0.5), 0.015), "cunning package exposes a direct accuracy gain")
	check(Rules.player_build_score(cunning) > Rules.player_build_score(base), "build comparison recognizes accuracy-only packages")

	var package_item := {"slot": "helmet", "power": 1, "rarity": "Raro", "attribute_package_id": "breach_calibration"}
	check(Rules.salvage_value(package_item) == Rules.salvage_value({"slot": "helmet", "power": 1, "rarity": "Raro", "trait": {}}), "packages recover the same scrap premium as ordinary modifications")
	check(EquipmentPresentation.modifier_text(package_item).contains("+2"), "equipment presentation explains a package without hidden arithmetic")

	var rng := RandomNumberGenerator.new()
	rng.seed = 884211
	var found_package := false
	for _roll in 1000:
		var item := Content.generate_loot(Content.TARGETS[12], rng, 4, "helmet")
		if item.has("attribute_package_id"):
			found_package = true
			check(not item.has("trait") and Packages.is_valid(str(item.attribute_package_id), str(item.slot)), "generated packages replace rather than stack with traits")
			break
	check(found_package, "rare and epic secondary loot can roll attribute packages")

	var state = StateScript.new()
	state.persistence_enabled = false
	var forged := {"id": "forged", "name": "Forjada", "slot": "helmet", "power": 1, "rarity": "Raro", "color": "#58d9ff", "attribute_package_id": "unknown"}
	check(state.sanitize_loaded_equipment(forged) and not forged.has("attribute_package_id"), "save repair removes unknown package ids")
	var stacked := {"id": "stacked", "name": "Empilhada", "slot": "helmet", "power": 1, "rarity": "Raro", "color": "#58d9ff", "attribute_package_id": "breach_calibration", "trait": Content.ITEM_TRAITS.helmet[0].duplicate(true)}
	check(state.sanitize_loaded_equipment(stacked) and stacked.has("trait") and not stacked.has("attribute_package_id"), "save repair rejects illegal trait-package stacking")
	state.free()

	if failures == 0:
		print("PASS: attribute packages create bounded class-aware equipment sidegrades")
		quit(0)
	else:
		printerr("FAIL: %d attribute-package test(s) failed" % failures)
		quit(1)


func player_for(class_id: String) -> Dictionary:
	var player := {
		"level": 10,
		"base_power": 20,
		"class_id": class_id,
		"attributes": Rules.default_attributes(),
	}
	for slot in Rules.EQUIPMENT_SLOTS:
		player[slot] = {}
	return player


func with_package(player: Dictionary, slot: String, package_id: String) -> Dictionary:
	var result := player.duplicate(true)
	result[slot] = {"slot": slot, "power": 0, "attribute_package_id": package_id}
	return result


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
