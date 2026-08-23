class_name CareerRules
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")


static func milestones(player: Dictionary) -> Array[Dictionary]:
	var captures: Dictionary = player.get("captures_by_target", {})
	var has_repeat_target := false
	for count in captures.values():
		if int(count) >= 3:
			has_repeat_target = true
	var completed_count: int = player.get("completed_planets", []).size()
	var claimed: Array = player.get("claimed_milestones", [])
	return [
		{"id": "first_warrant", "name": "PRIMEIRO MANDADO", "description": "Execute sua primeira captura.", "complete": int(player.get("wins", 0)) >= 1, "claimed": claimed.has("first_warrant"), "credits": 40, "scrap": 0},
		{"id": "repeat_customer", "name": "CLIENTE FREQUENTE", "description": "Capture o mesmo alvo três vezes.", "complete": has_repeat_target, "claimed": claimed.has("repeat_customer"), "credits": 70, "scrap": 2},
		{"id": "sector_owner", "name": "DONO DO SETOR", "description": "Conclua seu primeiro planeta.", "complete": completed_count >= 1, "claimed": claimed.has("sector_owner"), "credits": 120, "scrap": 4},
		{"id": "triple_frontier", "name": "TRÍPLICE FRONTEIRA", "description": "Conclua três planetas.", "complete": completed_count >= 3, "claimed": claimed.has("triple_frontier"), "credits": 300, "scrap": 10},
		{"id": "omega_mechanic", "name": "MECÂNICO DO APOCALIPSE", "description": "Conclua quatro planetas.", "complete": completed_count >= 4, "claimed": claimed.has("omega_mechanic"), "credits": 450, "scrap": 14},
		{"id": "house_breaker", "name": "A CASA PERDEU", "description": "Conclua cinco planetas.", "complete": completed_count >= 5, "claimed": claimed.has("house_breaker"), "credits": 650, "scrap": 18},
		{"id": "nothing_wasted", "name": "NADA SE PERDE", "description": "Recicle pelo menos 25 pontos de sucata.", "complete": int(player.get("scrap_recycled_total", 0)) >= 25, "claimed": claimed.has("nothing_wasted"), "credits": 90, "scrap": 5},
		{"id": "hot_pursuit", "name": "PERSEGUIÇÃO AQUECIDA", "description": "Mantenha um embalo de cinco capturas.", "complete": int(player.get("best_capture_streak", 0)) >= 5, "claimed": claimed.has("hot_pursuit"), "credits": 110, "scrap": 4},
	]


static func rewards_ready(player: Dictionary) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for milestone in milestones(player):
		if bool(milestone.complete) and not bool(milestone.claimed):
			ready.append(milestone)
	return ready


static func next_mastery_objective(player: Dictionary, targets: Array) -> Dictionary:
	var captures_by_target: Dictionary = player.get("captures_by_target", {})
	var best: Dictionary = {}
	for target in targets:
		var captures := int(captures_by_target.get(str(target.id), 0))
		if captures <= 0:
			continue
		var level := CoreRules.target_mastery_level(captures)
		var requirement := CoreRules.target_mastery_next_requirement(level)
		if requirement < 0:
			continue
		var candidate := {
			"target": target,
			"captures": captures,
			"level": level,
			"next_level": level + 1,
			"next_requirement": requirement,
			"remaining": requirement - captures,
			"rare_bonus": (level + 1) * 5,
			"epic_bonus": (level + 1) * 2,
			"scrap_bonus": CoreRules.target_mastery_scrap_reward(level + 1),
		}
		if best.is_empty() or int(candidate.remaining) < int(best.remaining):
			best = candidate
	return best
