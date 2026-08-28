extends SceneTree

const ContentDB = preload("res://scripts/content_db.gd")
const CoreRules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const YearOne = preload("res://scripts/year_one_content_rules.gd")

var failures := 0


func _init() -> void:
	var levels := YearOne.required_unlock_levels()
	check(levels.slice(0, 5) == [1, 4, 8, 13, 19], "the launch contract preserves all five implemented discovery levels")
	check(levels[-1] == 300 and levels.size() == 33, "ten-level expansion cadence covers the projected level-302 daily player")
	check(YearOne.TOTAL_HUNTS == 1825 and YearOne.required_target_count() == 132, "the year-one catalog has an explicit 365-day, 132-target ceiling")
	check(ContentDB.PLANETS.size() == 5 and ContentDB.TARGETS.size() == 20, "the audit distinguishes the implemented vertical slice from the launch catalog")
	for index in ContentDB.PLANETS.size():
		check(int(ContentDB.PLANETS[index].unlock_level) == levels[index], "implemented planet %d follows the year-one unlock contract" % (index + 1))

	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	var seen_targets := {}
	var seen_planets := {}
	for _hunt in YearOne.TOTAL_HUNTS:
		var offers := MissionRules.board_offers(player)
		for offer in offers:
			seen_targets[str(offer.id)] = true
			seen_planets[str(offer.planet_id)] = true
		var standard: Dictionary = offers[1]
		player.wins = int(player.wins) + 1
		CoreRules.apply_xp(player, int(standard.xp))
	check(int(player.level) == YearOne.PROJECTED_YEAR_END_LEVEL, "five standard hunts per day project to the documented year-end level")
	check(seen_planets.size() == ContentDB.PLANETS.size() and seen_targets.size() == ContentDB.TARGETS.size(), "the current rotation keeps every implemented world and target discoverable during the year simulation")
	state.free()
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: year-one content contract and 365-day projection are coherent")
		quit(0)
	else:
		printerr("FAIL: %d year-one content contract issue(s)" % failures)
		quit(1)
