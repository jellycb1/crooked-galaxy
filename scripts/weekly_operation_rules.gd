class_name WeeklyOperationRules
extends RefCounted

const Content = preload("res://scripts/content_db.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")

const SECONDS_PER_DAY := 86400
const OBJECTIVE_IDS := ["weekly_patrol", "weekly_regular", "weekly_veteran"]
const ROUTE_PLANET_QUOTA := 2
const ROUTE_REWARD_CREDITS := 250
const ROUTE_REWARD_SCRAP := 18


static func utc_week_id(unix_time := -1.0) -> int:
	var now := Time.get_unix_time_from_system() if unix_time < 0.0 else unix_time
	var day_id := floori(now / float(SECONDS_PER_DAY))
	# 1970-01-01 was a Thursday. The +3 makes every cycle begin on Monday
	# at 00:00 UTC and keeps the identifier suitable for future server authority.
	return floori(float(day_id + 3) / 7.0)


static func objectives(player: Dictionary) -> Array[Dictionary]:
	var completed := clampi(int(player.get("weekly_hunts_completed", 0)), 0, 10000)
	var claimed: Array = player.get("claimed_weekly_objectives", [])
	var definitions: Array[Dictionary] = [
		{"id": "weekly_patrol", "goal": 8, "credits": 150, "scrap": 0},
		{"id": "weekly_regular", "goal": 20, "credits": 0, "scrap": 15},
		{"id": "weekly_veteran", "goal": 35, "credits": 400, "scrap": 25},
	]
	for definition in definitions:
		var objective_id := str(definition.id)
		var prefix := "WEEKLY_OBJECTIVE_%s" % objective_id.to_upper()
		definition.progress = mini(completed, int(definition.goal))
		definition.complete = completed >= int(definition.goal)
		definition.claimed = claimed.has(objective_id)
		definition.name = LocaleRules.text("%s_NAME" % prefix, objective_id.to_upper())
		definition.description = LocaleRules.text("%s_DESCRIPTION" % prefix, "Conclua %d contratos esta semana." % int(definition.goal))
	return definitions


static func rewards_ready(player: Dictionary) -> Array[Dictionary]:
	return objectives(player).filter(func(objective): return bool(objective.complete) and not bool(objective.claimed))


static func valid_claim_ids() -> Array[String]:
	return OBJECTIVE_IDS.duplicate()


static func rotating_planet_ids(player: Dictionary, week_id: int) -> Array[String]:
	var planets := MissionRulesScript.available_planets(int(player.get("level", 1)))
	var result: Array[String] = []
	if planets.is_empty():
		return result
	# Advancing by the size of one circuit makes every complete launch catalog
	# pass cover all 35 worlds in twelve weeks. The snapshot remains stable when
	# the hunter levels up halfway through a weekly cycle.
	var offset := posmod(week_id * 3, planets.size())
	for index in mini(3, planets.size()):
		result.append(str(planets[(offset + index) % planets.size()].id))
	return result


static func route_status(player: Dictionary) -> Dictionary:
	var planet_ids: Array = player.get("weekly_route_planet_ids", [])
	var captures: Dictionary = player.get("weekly_route_captures", {})
	var entries: Array[Dictionary] = []
	var total_progress := 0
	for planet_id_value in planet_ids:
		var planet_id := str(planet_id_value)
		var planet := Content.get_planet(planet_id)
		if planet.is_empty():
			continue
		var progress := clampi(int(captures.get(planet_id, 0)), 0, ROUTE_PLANET_QUOTA)
		total_progress += progress
		entries.append({
			"planet": planet,
			"progress": progress,
			"goal": ROUTE_PLANET_QUOTA,
			"complete": progress >= ROUTE_PLANET_QUOTA,
		})
	var complete := not entries.is_empty() and entries.all(func(entry): return bool(entry.complete))
	return {
		"entries": entries,
		"progress": total_progress,
		"goal": entries.size() * ROUTE_PLANET_QUOTA,
		"complete": complete,
		"claimed": bool(player.get("weekly_route_claimed", false)),
		"credits": ROUTE_REWARD_CREDITS,
		"scrap": ROUTE_REWARD_SCRAP,
	}


static func record_route_capture(player: Dictionary, planet_id: String) -> bool:
	if not player.get("weekly_route_planet_ids", []).has(planet_id):
		return false
	var captures: Dictionary = player.get("weekly_route_captures", {}).duplicate(true)
	var previous := clampi(int(captures.get(planet_id, 0)), 0, ROUTE_PLANET_QUOTA)
	if previous >= ROUTE_PLANET_QUOTA:
		return false
	captures[planet_id] = previous + 1
	player.weekly_route_captures = captures
	return true


static func route_reward_ready(player: Dictionary) -> bool:
	var status := route_status(player)
	return bool(status.complete) and not bool(status.claimed)


static func eligible_special_targets(player: Dictionary) -> Array[Dictionary]:
	var unlocked_planets := {}
	for planet in MissionRulesScript.available_planets(int(player.get("level", 1))):
		unlocked_planets[str(planet.id)] = true
	var result: Array[Dictionary] = []
	for target in Content.TARGETS:
		if bool(target.get("boss", false)) and unlocked_planets.has(str(target.get("planet_id", ""))):
			result.append(target.duplicate(true))
	return result


static func rotating_target_id(player: Dictionary, week_id: int) -> String:
	var eligible := eligible_special_targets(player)
	if eligible.is_empty():
		return ""
	return str(eligible[posmod(week_id, eligible.size())].id)


static func special_contract(player: Dictionary, target_id: String, week_id: int) -> Dictionary:
	var target := Content.get_target(target_id)
	if target.is_empty() or not bool(target.get("boss", false)):
		return {}
	var eligible_ids := eligible_special_targets(player).map(func(entry): return str(entry.id))
	if not eligible_ids.has(target_id):
		return {}
	return MissionRulesScript.weekly_special_offer(player, target, week_id)
