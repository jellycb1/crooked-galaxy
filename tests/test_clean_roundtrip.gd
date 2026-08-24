extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_clean_roundtrip_%s.json" % OS.get_process_id()


func _init() -> void:
	var board := clean_state()
	assert_clean_roundtrip(board, board.Phase.BOARD, "board")

	var briefing := clean_state()
	briefing.select_bounty(ContentDB.TARGETS[0])
	assert_clean_roundtrip(briefing, briefing.Phase.BRIEFING, "briefing")

	var hunt := clean_state()
	hunt.select_bounty(ContentDB.TARGETS[0])
	hunt.choose_approach("quiet_net")
	assert_clean_roundtrip(hunt, hunt.Phase.HUNT, "hunt")

	var incident := clean_state()
	incident.select_bounty(ContentDB.TARGETS[0])
	incident.choose_approach("quiet_net")
	incident.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	incident.hunt_event_triggered = true
	incident.hunt_elapsed_before_event = 3.0
	incident.hunt_remaining_after_event = 4.0
	incident.phase = incident.Phase.HUNT_EVENT
	assert_clean_roundtrip(incident, incident.Phase.HUNT_EVENT, "hunt event")

	var combat := clean_state()
	combat.select_bounty(ContentDB.TARGETS[0])
	combat.choose_approach("quiet_net")
	combat.begin_combat()
	assert_clean_roundtrip(combat, combat.Phase.COMBAT, "combat")

	var victory := clean_state()
	victory.select_bounty(ContentDB.TARGETS[0])
	victory.choose_approach("quiet_net")
	victory.begin_combat()
	victory.enemy_hp = 0
	victory.finish_combat(true)
	assert_clean_roundtrip(victory, victory.Phase.VICTORY, "victory")

	var reward := clean_state()
	reward.select_bounty(ContentDB.TARGETS[0])
	reward.choose_approach("quiet_net")
	reward.begin_combat()
	reward.enemy_hp = 0
	reward.finish_combat(true)
	reward.open_reward()
	assert_clean_roundtrip(reward, reward.Phase.REWARD, "reward")

	var evidenced_combat := clean_state()
	evidenced_combat.player.weapon.origin_planet_id = "dustball_prime"
	evidenced_combat.player.armor.origin_planet_id = "dustball_prime"
	evidenced_combat.select_bounty(ContentDB.TARGETS[0])
	evidenced_combat.choose_approach("quiet_net", {"target_id": "gloop", "approach_id": "quiet_net", "approach_name": "Rede Silenciosa", "odds": 0.74})
	evidenced_combat.begin_combat()
	evidenced_combat.save_game()
	var restored_evidence = StateScript.new()
	restored_evidence.save_path = test_save
	restored_evidence.load_game()
	check(restored_evidence.last_notice_context != "system_recovery", "combat with optional evidence does not emit false recovery")
	check(str(restored_evidence.combat_summary.get("kit_origin", "")) == "dustball_prime", "active planetary kit survives a clean combat round-trip")
	var restored_field_context: Dictionary = restored_evidence.combat_summary.get("field_test_context", {})
	check(not restored_field_context.is_empty() and not bool(restored_field_context.overridden) and str(restored_field_context.tested_approach_id) == "quiet_net", "confirmed tested-route context survives a clean combat round-trip")
	restored_evidence.free()
	evidenced_combat.free()

	var finale := clean_state()
	var boss := ContentDB.TARGETS[3].duplicate(true)
	finale.player.completed_planets = ["dustball_prime"]
	finale.player.wins = 10
	finale.player.captures_by_target = {"mayor_gold_dust": 1}
	finale.player.captures_by_planet = {"dustball_prime": 10}
	finale.chapter_completion = {"planet": ContentDB.PLANET.duplicate(true), "target": boss, "total_captures": 10, "credits": int(boss.credits), "xp": int(boss.xp)}
	finale.phase = finale.Phase.CHAPTER_COMPLETE
	assert_clean_roundtrip(finale, finale.Phase.CHAPTER_COMPLETE, "chapter complete")

	audit_hunt_choice_roundtrips()
	audit_contract_approach_roundtrips()
	audit_equipment_roundtrips()

	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	if failures == 0:
		print("PASS: every current-schema phase round-trips without false recovery")
		quit(0)
	else:
		printerr("FAIL: %d clean round-trip issue(s)" % failures)
		quit(1)


func clean_state() -> StateScript:
	var state = StateScript.new()
	state.save_path = test_save
	state.player = state.default_player()
	return state


func assert_clean_roundtrip(source: StateScript, expected_phase: int, context: String) -> void:
	source.save_game()
	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	check(restored.phase == expected_phase, "%s preserves its phase" % context)
	check(restored.last_notice_context != "system_recovery", "%s does not emit a false recovery notice" % context)
	restored.free()
	source.free()


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
			check(int(restored.current_bounty.loot_power) == expected_loot_power and expected_loot_power == int(target.power), "contract %s preserves canonical loot tier" % context)
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


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
