extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const CoreRulesScript = preload("res://scripts/core_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")

var failures := 0


func _init() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var elapsed := 0.0
	var discovery := {1: {"wins": 0, "seconds": 0.0}}
	var known_worlds := MissionRulesScript.available_planets(int(player.level)).size()
	for _capture in 150:
		var offers := MissionRulesScript.board_offers(player)
		check(offers.size() == 3, "standard progression always retains three generated offers")
		if offers.size() < 2:
			break
		var offer: Dictionary = offers[1]
		elapsed += TransportRulesScript.effective_mission_duration(player, offer)
		player.xp = int(player.xp) + int(offer.xp)
		player.wins = int(player.wins) + 1
		while int(player.xp) >= CoreRulesScript.xp_needed(int(player.level)):
			player.xp = int(player.xp) - CoreRulesScript.xp_needed(int(player.level))
			player.level = int(player.level) + 1
		var current_worlds := MissionRulesScript.available_planets(int(player.level)).size()
		if current_worlds > known_worlds:
			discovery[current_worlds] = {"wins": int(player.wins), "seconds": elapsed, "level": int(player.level)}
			known_worlds = current_worlds
		if known_worlds == ContentDB.PLANETS.size():
			break

	check(discovery.size() == ContentDB.PLANETS.size(), "a standard-contract career discovers all five current worlds")
	check(in_range(discovery, 2, 5, 15, 4), "the second world enters after the tutorial but before the opening loop becomes repetitive")
	check(in_range(discovery, 3, 15, 40, 8), "the third world arrives within the intended early-career window")
	check(in_range(discovery, 4, 35, 75, 13), "the fourth world anchors the middle-career window")
	check(in_range(discovery, 5, 60, 115, 19), "the fifth world remains a meaningful long-career discovery")
	check(float(discovery[2].seconds) < float(discovery[3].seconds) and float(discovery[3].seconds) < float(discovery[4].seconds) and float(discovery[4].seconds) < float(discovery[5].seconds), "cumulative mission time grows monotonically across world discoveries")
	check(seconds_in_range(discovery, 2, 1100.0, 1300.0), "Congelaria enters after roughly twenty minutes of standard base waits")
	check(seconds_in_range(discovery, 3, 5200.0, 5600.0), "Micelia enters after roughly ninety minutes of standard base waits")
	check(seconds_in_range(discovery, 4, 15000.0, 16500.0), "Ferro-Velho enters after roughly four and a half hours of standard base waits")
	check(seconds_in_range(discovery, 5, 36000.0, 39000.0), "Cassino enters after roughly ten hours of standard base waits")

	finish()


func in_range(discovery: Dictionary, world_count: int, minimum_wins: int, maximum_wins: int, expected_level: int) -> bool:
	if not discovery.has(world_count):
		return false
	var record: Dictionary = discovery[world_count]
	return int(record.wins) >= minimum_wins and int(record.wins) <= maximum_wins and int(record.level) == expected_level


func seconds_in_range(discovery: Dictionary, world_count: int, minimum_seconds: float, maximum_seconds: float) -> bool:
	if not discovery.has(world_count):
		return false
	var seconds := float(discovery[world_count].seconds)
	return seconds >= minimum_seconds and seconds <= maximum_seconds


func finish() -> void:
	if failures == 0:
		print("PASS: mission wait and world discovery pacing remain bounded")
		quit(0)
	else:
		printerr("FAIL: %d mission pacing issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
