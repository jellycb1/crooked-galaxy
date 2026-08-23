extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const TEST_SAVE := "user://crooked_galaxy_test_save.json"

var failures := 0


func _init() -> void:
	var source = StateScript.new()
	source.save_path = TEST_SAVE
	source.player = source.default_player()
	source.player.credits = 123
	source.phase = source.Phase.VICTORY
	source.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	source.pending_loot = {
		"id": "test_loot",
		"name": "Zapper de Teste",
		"description": "Existe apenas durante o teste.",
		"slot": "weapon",
		"power": 7,
		"rarity": "Raro",
		"color": "#58d9ff",
	}
	source.combat_events.assign([
		{"actor": "player", "action": "Teste de Impacto", "damage": 17, "quality": "CRÍTICO"},
	])
	source.save_game()

	var restored = StateScript.new()
	restored.save_path = TEST_SAVE
	restored.load_game()
	check(int(restored.player.credits) == 123, "player data survives save and load")
	check(restored.phase == restored.Phase.VICTORY, "capture phase survives save and load")
	check(str(restored.pending_loot.id) == "test_loot", "pending reward survives save and load")
	check(restored.combat_events.size() == 1, "finishing action survives save and load")
	check(str(restored.combat_events[0].action) == "Teste de Impacto", "action data is restored")

	source.phase = source.Phase.BOARD
	source.current_bounty = {}
	source.pending_loot = {}
	source.select_bounty(ContentDB.TARGETS[0])
	var restored_briefing = StateScript.new()
	restored_briefing.save_path = TEST_SAVE
	restored_briefing.load_game()
	check(restored_briefing.phase == restored_briefing.Phase.BRIEFING, "briefing phase survives save and load")
	check(restored_briefing.offered_approaches.size() == 3, "approach choices survive save and load")

	source.free()
	restored.free()
	restored_briefing.free()
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if failures == 0:
		print("PASS: save and load preserve an interrupted reward flow")
		quit(0)
	else:
		printerr("FAIL: %d persistence test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
