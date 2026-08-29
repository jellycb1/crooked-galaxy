extends SceneTree

const ContentDB = preload("res://scripts/content_db.gd")
const CoreRules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const YearOne = preload("res://scripts/year_one_content_rules.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")

var failures := 0


func _init() -> void:
	var levels := YearOne.required_unlock_levels()
	check(levels.slice(0, 5) == [1, 4, 8, 13, 19], "the launch contract preserves all five implemented discovery levels")
	check(levels[-1] == YearOne.FINAL_YEAR_ONE_PLANET_LEVEL and levels.size() == 35, "ten-level expansion cadence covers the fuel-limited worst-case year")
	check(YearOne.TOTAL_HUNTS == 1825 and YearOne.required_target_count() == 140, "the year-one catalog has an explicit 365-day, 140-target ceiling")
	check(YearOne.PACING_AUDIT_DAILY_HUNTS == [5, 10, 20, 40], "the launch contract audits reference through high-intensity hunt profiles")
	check(YearOne.days_for_hunts(1825, 5) == 365 and YearOne.days_for_hunts(1825, 20) == 92, "pacing conversion exposes faster content consumption instead of treating five hunts as a cap")
	check(MonetizationRules.DAILY_HUNT_FUEL == 100 and MonetizationRules.HUNT_FUEL_REFILL_AMOUNT == 20 and MonetizationRules.HUNT_FUEL_REFILL_COSTS == [1, 5, 20], "the year-one model uses the approved transparent fuel reserve and refill ladder")
	check(YearOne.days_for_hunts(0, 0) == 0, "pacing conversion handles an empty horizon safely")
	check(ContentDB.PLANETS.size() == 26 and ContentDB.TARGETS.size() == 104, "the audit distinguishes implemented planet packs from the launch catalog")
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
	check(int(player.level) == YearOne.REFERENCE_YEAR_END_LEVEL, "five standard hunts per day project to the documented quadratic-curve year-end level")
	var year_end_worlds := MissionRules.available_planets(int(player.level)).size()
	check(year_end_worlds == 17 and seen_planets.size() == year_end_worlds, "the five-hunt reference sees every world unlocked by its documented year-end level")
	var level_150_planet_seen := ContentDB.TARGETS.any(func(target): return str(target.planet_id) == str(ContentDB.PLANETS[-1].id) and seen_targets.has(str(target.id)))
	check(not level_150_planet_seen, "content beyond the reference year-end level does not leak into its board")
	for _hunt in 2500:
		var offers := MissionRules.board_offers(player)
		for offer in offers:
			seen_targets[str(offer.id)] = true
		var standard: Dictionary = offers[1]
		player.wins = int(player.wins) + 1
		CoreRules.apply_xp(player, int(standard.xp))
		if seen_targets.size() == ContentDB.TARGETS.size():
			break
	check(int(player.level) >= 230 and seen_targets.size() == ContentDB.TARGETS.size(), "one bounded post-year continuation reaches level 230 and exposes every implemented target identity")
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
