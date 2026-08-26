extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_persistence_matrix_%s.json" % OS.get_process_id()


func _init() -> void:
	audit_hunt_choice_roundtrips()
	audit_contract_approach_roundtrips()
	audit_equipment_roundtrips()
	cleanup_save_family()
	if failures == 0:
		print("PASS: exhaustive persistence matrices round-trip without recovery")
		quit(0)
	else:
		printerr("FAIL: %d persistence matrix issue(s)" % failures)
		quit(1)


func clean_state() -> StateScript:
	var state = StateScript.new()
	state.save_path = test_save
	state.player = state.default_player()
	return state


func audit_hunt_choice_roundtrips() -> void:
	for event in ContentDB.HUNT_EVENTS:
		var matching_targets := ContentDB.TARGETS.filter(func(target): return str(target.planet_id) == str(event.planet_id))
		check(not matching_targets.is_empty(), "event %s has a canonical planet target" % str(event.id))
		if matching_targets.is_empty():
			continue
		for choice in event.choices:
			var source := clean_state()
			source.player.credits = 1000
			var completed_planets: Array = []
			for planet in ContentDB.PLANETS:
				if str(planet.id) == str(event.planet_id):
					break
				completed_planets.append(str(planet.id))
			source.player.completed_planets = completed_planets
			source.player.level = int(ContentDB.get_planet(str(event.planet_id)).get("unlock_level", 1))
			source.player.current_planet_id = str(event.planet_id)
			source.select_bounty(matching_targets[0])
			source.choose_approach("quiet_net")
			source.hunt_event = event.duplicate(true)
			source.hunt_event_triggered = true
			source.hunt_elapsed_before_event = 3.0
			source.hunt_remaining_after_event = 4.0
			source.phase = source.Phase.HUNT_EVENT
			var credits_before := int(source.player.credits)
			check(source.resolve_hunt_event(str(choice.id)), "choice %s resolves before round-trip" % str(choice.id))
			var expected_credits := credits_before - int(choice.get("credit_cost", 0))
			var restored = StateScript.new()
			restored.save_path = test_save
			restored.load_game()
			check(restored.last_notice_context != "system_recovery", "choice %s does not emit false recovery" % str(choice.id))
			check(restored.phase == restored.Phase.HUNT and str(restored.current_bounty.get("hunt_event_choice_id", "")) == str(choice.id), "choice %s restores its applied hunt outcome" % str(choice.id))
			check(int(restored.player.credits) == expected_credits, "choice %s preserves its exact charged wallet" % str(choice.id))
			restored.free()
			source.free()


func audit_contract_approach_roundtrips() -> void:
	for target_index in [0, 8, 19]:
		var target: Dictionary = ContentDB.TARGETS[target_index]
		for approach in ContentDB.CONTRACT_APPROACHES:
			var source := clean_state()
			var completed_planets: Array = []
			for planet in ContentDB.PLANETS:
				if str(planet.id) == str(target.planet_id):
					break
				completed_planets.append(str(planet.id))
			source.player.completed_planets = completed_planets
			source.player.level = int(ContentDB.get_planet(str(target.planet_id)).get("unlock_level", 1))
			source.player.current_planet_id = str(target.planet_id)
			var captures: Dictionary = {}
			for prerequisite in ContentDB.TARGETS:
				if str(prerequisite.planet_id) == str(target.planet_id) and int(prerequisite.get("chapter_tier", prerequisite.rank)) < int(target.get("chapter_tier", target.rank)):
					captures[str(prerequisite.id)] = 3
			source.player.captures_by_target = captures
			source.select_bounty(target)
			source.choose_approach(str(approach.id))
			var expected_scrap := int(source.current_bounty.get("scrap_reward", 0))
			var expected_loot_power := int(source.current_bounty.loot_power)
			var restored = StateScript.new()
			restored.save_path = test_save
			restored.load_game()
			var context := "%s/%s" % [str(target.id), str(approach.id)]
			check(restored.last_notice_context != "system_recovery", "contract %s does not emit false recovery" % context)
			check(restored.phase == restored.Phase.HUNT and str(restored.current_bounty.approach.id) == str(approach.id), "contract %s restores its applied approach" % context)
			check(int(restored.current_bounty.get("scrap_reward", 0)) == expected_scrap, "contract %s preserves corporate scrap metadata" % context)
			check(int(restored.current_bounty.loot_power) == expected_loot_power and expected_loot_power == int(target.get("loot_power", target.power)), "contract %s preserves canonical loot tier" % context)
			restored.free()
			source.free()


func audit_equipment_roundtrips() -> void:
	var rarity_colors := {"Comum": "#b9c2d9", "Raro": "#58d9ff", "Épico": "#d789ff"}
	var calibration_histories := [0, 1, 5]
	for slot in ContentDB.ITEM_TRAITS:
		for trait_definition in ContentDB.ITEM_TRAITS[slot]:
			for rarity in rarity_colors:
				for planet in ContentDB.PLANETS:
					for power_upgrades in calibration_histories:
						for integrity_upgrades in range(CoreRules.MAX_INTEGRITY_UPGRADES + 1):
							var context := "%s/%s/%s/cal%d/ref%d" % [str(trait_definition.id), str(rarity), str(planet.id), power_upgrades, integrity_upgrades]
							var item := {
								"id": "equipped_%s" % context,
								"name": "Equipamento auditado",
								"slot": str(slot),
								"origin_planet_id": str(planet.id),
								"power": 12 + power_upgrades,
								"rarity": str(rarity),
								"color": str(rarity_colors[rarity]),
								"trait": trait_definition.duplicate(true),
								"power_upgrades": power_upgrades,
								"integrity_upgrades": integrity_upgrades,
							}
							var reserve := item.duplicate(true)
							reserve.id = "reserve_%s" % context
							var source := clean_state()
							source.player[slot] = item.duplicate(true)
							source.player.inventory = [reserve.duplicate(true)]
							source.player.locked_item_ids = [str(item.id), str(reserve.id)]
							var id_key := "%s_id" % str(slot)
							source.player.equipment_loadouts[0][id_key] = str(item.id)
							source.player.equipment_loadouts[1][id_key] = str(reserve.id)
							source.save_game()
							var restored = StateScript.new()
							restored.save_path = test_save
							restored.load_game()
							var restored_item: Dictionary = restored.player[slot]
							var restored_reserve: Dictionary = restored.player.inventory[0] if not restored.player.inventory.is_empty() else {}
							check(restored.last_notice_context != "system_recovery", "equipment %s does not emit false recovery" % context)
							check(restored.payloads_equivalent(restored_item, item), "equipment %s preserves its equipped payload" % context)
							check(restored.payloads_equivalent(restored_reserve, reserve), "equipment %s preserves its reserve payload" % context)
							check(restored.player.locked_item_ids.has(str(item.id)) and restored.player.locked_item_ids.has(str(reserve.id)), "equipment %s preserves protection" % context)
							check(str(restored.player.equipment_loadouts[0][id_key]) == str(item.id) and str(restored.player.equipment_loadouts[1][id_key]) == str(reserve.id), "equipment %s preserves loadouts" % context)
							restored.free()
							source.free()


func cleanup_save_family() -> void:
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
