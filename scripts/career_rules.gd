class_name CareerRules
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")


static func milestones(player: Dictionary) -> Array[Dictionary]:
	var captures: Dictionary = player.get("captures_by_target", {})
	var wins := maxi(0, int(player.get("wins", 0)))
	var has_repeat_target := false
	for count in captures.values():
		if int(count) >= 3:
			has_repeat_target = true
	var discovered_count := MissionRules.available_planet_count(int(player.get("level", 1)))
	var claimed: Array = player.get("claimed_milestones", [])
	var recycled := maxi(0, int(player.get("scrap_recycled_total", 0)))
	var best_streak := maxi(0, int(player.get("best_capture_streak", 0)))
	var definitions: Array[Dictionary] = [
		milestone("first_warrant", "PRIMEIRO MANDADO", "Execute sua primeira captura.", wins, 1, claimed, 40, 0),
		milestone("repeat_customer", "CLIENTE FREQUENTE", "Capture o mesmo alvo três vezes.", 1 if has_repeat_target else 0, 1, claimed, 70, 2),
		milestone("sector_owner", "PRIMEIRA FRONTEIRA", "Descubra seu segundo mundo de contratos.", discovered_count, 2, claimed, 120, 4),
		milestone("triple_frontier", "TRÍPLICE FRONTEIRA", "Descubra três mundos da rede.", discovered_count, 3, claimed, 300, 10),
		milestone("omega_mechanic", "MECÂNICO DO APOCALIPSE", "Descubra quatro mundos da rede.", discovered_count, 4, claimed, 450, 14),
		milestone("house_breaker", "A CASA PERDEU", "Descubra cinco mundos da rede.", discovered_count, 5, claimed, 650, 18),
		milestone("nothing_wasted", "NADA SE PERDE", "Recicle pelo menos 25 pontos de sucata.", recycled, 25, claimed, 90, 5),
		milestone("hot_pursuit", "PERSEGUIÇÃO AQUECIDA", "Mantenha um embalo de cinco capturas.", best_streak, 5, claimed, 110, 4),
		milestone("hundred_warrants", "CENTENA PROCURADA", "Conclua 100 caçadas normais.", wins, 100, claimed, 600, 10),
		milestone("ten_frontiers", "CARTÓGRAFO DE DEZ MUNDOS", "Descubra dez mundos da rede.", discovered_count, 10, claimed, 900, 10),
		milestone("five_hundred_warrants", "ARQUIVO DE QUINHENTOS", "Conclua 500 caçadas normais.", wins, 500, claimed, 2000, 25),
		milestone("fifteen_frontiers", "ATLAS DA FRONTEIRA", "Descubra quinze mundos da rede.", discovered_count, 15, claimed, 1500, 20),
		milestone("thousand_warrants", "MIL MANDADOS", "Conclua 1 000 caçadas normais.", wins, 1000, claimed, 4000, 40),
		milestone("twenty_frontiers", "CARTÓGRAFO DO ABISMO", "Descubra vinte mundos da rede.", discovered_count, 20, claimed, 2400, 30),
		milestone("two_thousand_warrants", "DOIS MIL REGISTOS", "Conclua 2 000 caçadas normais.", wins, 2000, claimed, 7000, 60),
		milestone("twenty_five_frontiers", "REGISTO GALÁCTICO", "Descubra vinte e cinco mundos da rede.", discovered_count, 25, claimed, 3500, 40),
		milestone("three_thousand_warrants", "TRÊS MIL CAPTURAS", "Conclua 3 000 caçadas normais.", wins, 3000, claimed, 10000, 80),
		milestone("thirty_frontiers", "MAPA DO LIMITE", "Descubra trinta mundos da rede.", discovered_count, 30, claimed, 5000, 50),
		milestone("complete_launch_atlas", "ATLAS DA GALÁXIA TORTA", "Descubra os trinta e cinco mundos do catálogo de lançamento.", discovered_count, 35, claimed, 7500, 60),
	]
	for milestone in definitions:
		var prefix := "CAREER_MILESTONE_%s" % str(milestone.id).to_upper()
		milestone.name = LocaleRules.text("%s_NAME" % prefix, str(milestone.name))
		milestone.description = LocaleRules.text("%s_DESCRIPTION" % prefix, str(milestone.description))
	return definitions


static func milestone(id: String, name: String, description: String, current: int, target: int, claimed: Array, credits: int, scrap: int) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"current": clampi(current, 0, target),
		"target": target,
		"complete": current >= target,
		"claimed": claimed.has(id),
		"credits": credits,
		"scrap": scrap,
	}


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
