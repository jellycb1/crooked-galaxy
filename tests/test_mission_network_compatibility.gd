extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")

var test_save := "res://.godot/mission_network_compatibility_%s.json" % OS.get_process_id()
var failures := 0


func _init() -> void:
	var source := StateScript.new()
	source.save_path = test_save
	source.player = source.default_player()
	source.player.level = 19
	source.player.xp = 120
	source.player.wins = 82
	source.player.completed_planets = ContentDB.PLANETS.map(func(planet): return str(planet.id))
	source.player.current_planet_id = "cassino_quasar"
	source.player.owned_transport_ids = ["executive_escape_yacht"]
	source.player.active_transport_id = "executive_escape_yacht"
	source.phase = source.Phase.BOARD
	check(source.save_game(), "established pre-network progression can be written for compatibility audit")

	var restored := StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	var offers := MissionRulesScript.board_offers(restored.player)
	check(offers.size() == 3 and MissionRulesScript.available_planets(int(restored.player.level)).size() == ContentDB.PLANETS.size(), "established planet progress resumes into the complete three-offer network")
	check(str(restored.player.current_planet_id) == "cassino_quasar" and str(restored.player.active_transport_id) == "executive_escape_yacht", "active destination and owned transport survive the network transition")

	var accepted: Dictionary = offers[2]
	restored.select_bounty(accepted)
	var briefing := StateScript.new()
	briefing.save_path = test_save
	briefing.load_game()
	check(briefing.phase == briefing.Phase.BRIEFING and briefing.current_bounty == MissionRulesScript.canonical_offer(accepted), "an accepted level-banded offer restores its exact immutable snapshot")
	check(str(briefing.player.current_planet_id) == str(accepted.planet_id), "accepted mission destination remains authoritative after reload")

	var file := FileAccess.open(test_save, FileAccess.READ)
	var payload = JSON.parse_string(file.get_as_text())
	file = null
	payload.current_bounty.power = 999999
	payload.current_bounty.health = 1
	payload.current_bounty.credits = 999999
	file = FileAccess.open(test_save, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file = null
	var repaired := StateScript.new()
	repaired.save_path = test_save
	repaired.load_game()
	var canonical := MissionRulesScript.canonical_offer(accepted)
	check(int(repaired.current_bounty.power) == int(canonical.power) and int(repaired.current_bounty.health) == int(canonical.health) and int(repaired.current_bounty.credits) == int(canonical.credits), "tampered network combat and economy fields rebuild from canonical mission metadata")

	repaired.choose_approach("quiet_net")
	repaired.hunt_started_at = -10.0
	repaired.hunt_ends_at = -20.0
	repaired.save_game()
	var hunt := StateScript.new()
	hunt.save_path = test_save
	hunt.load_game()
	var expected_duration := TransportRulesScript.effective_mission_duration(hunt.player, hunt.current_bounty)
	check(hunt.phase == hunt.Phase.HUNT and is_equal_approx(hunt.hunt_ends_at - hunt.hunt_started_at, expected_duration), "interrupted network hunts restore travel, pursuit, approach, and transport timing coherently")
	hunt.abandon_bounty()
	var after_abandon := StateScript.new()
	after_abandon.save_path = test_save
	after_abandon.load_game()
	check(after_abandon.phase == after_abandon.Phase.BOARD and after_abandon.current_bounty.is_empty() and MissionRulesScript.board_offers(after_abandon.player).size() == 3, "consuming an interrupted legacy-compatible transaction returns cleanly to the three-offer board")

	for state in [source, restored, briefing, repaired, hunt, after_abandon]:
		state.free()
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: migrated progression and interrupted network missions remain transaction-safe")
		quit(0)
	else:
		printerr("FAIL: %d mission network compatibility issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
