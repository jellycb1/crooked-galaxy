class_name DailyObjectiveRules
extends RefCounted

const LocaleRules = preload("res://scripts/locale_rules.gd")

const OBJECTIVE_IDS := ["first_capture", "active_shift", "full_shift"]


static func objectives(player: Dictionary) -> Array[Dictionary]:
	var completed := clampi(int(player.get("daily_hunts_completed", 0)), 0, 1000)
	var claimed: Array = player.get("claimed_daily_objectives", [])
	var definitions: Array[Dictionary] = [
		{"id": "first_capture", "goal": 1, "credits": 25, "scrap": 0},
		{"id": "active_shift", "goal": 3, "credits": 0, "scrap": 3},
		{"id": "full_shift", "goal": 5, "credits": 60, "scrap": 5},
	]
	for definition in definitions:
		var objective_id := str(definition.id)
		var prefix := "DAILY_OBJECTIVE_%s" % objective_id.to_upper()
		definition.progress = mini(completed, int(definition.goal))
		definition.complete = completed >= int(definition.goal)
		definition.claimed = claimed.has(objective_id)
		definition.name = LocaleRules.text("%s_NAME" % prefix, objective_id.to_upper())
		definition.description = LocaleRules.text("%s_DESCRIPTION" % prefix, "Conclua %d contratos hoje." % int(definition.goal))
	return definitions


static func rewards_ready(player: Dictionary) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for objective in objectives(player):
		if bool(objective.complete) and not bool(objective.claimed):
			ready.append(objective)
	return ready


static func valid_claim_ids() -> Array[String]:
	return OBJECTIVE_IDS.duplicate()
