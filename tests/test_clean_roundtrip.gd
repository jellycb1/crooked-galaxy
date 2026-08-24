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

	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
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


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
