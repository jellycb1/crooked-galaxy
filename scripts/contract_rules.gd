class_name ContractRules
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const Classes = preload("res://scripts/class_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")

const MIN_RECOMMENDED_ODDS := 0.55
const SCRAP_VALUE := 16.0


static func evaluate_approaches(player: Dictionary, target: Dictionary, approaches: Array[Dictionary]) -> Array[Dictionary]:
	var evaluations: Array[Dictionary] = []
	for approach in approaches:
		var preview := Content.apply_approach(target, approach)
		var payout := Rules.bounty_streak_reward(int(preview.credits), int(player.get("capture_streak", 0)) + 1)
		evaluations.append({
			"id": str(approach.id),
			"preview": preview,
			"odds": Rules.bounty_odds(player, preview),
			"credits": int(payout.credits),
			"streak": int(payout.streak),
			"streak_bonus": int(payout.bonus_credits),
			"streak_bonus_percent": int(payout.bonus_percent),
			"xp": int(preview.xp),
			"scrap": int(preview.get("scrap_reward", 0)),
			"duration": ceili(TransportRules.effective_mission_duration(player, preview)),
		})
	return evaluations


static func recommended_approach_id(evaluations: Array[Dictionary], class_id := "") -> String:
	var recommended_id := ""
	var best_score := -1.0
	for evaluation in evaluations:
		var odds := float(evaluation.get("odds", 0.0))
		if odds < MIN_RECOMMENDED_ODDS:
			continue
		var score := expected_return_score(evaluation, class_id)
		if score > best_score:
			best_score = score
			recommended_id = str(evaluation.get("id", ""))
	if not recommended_id.is_empty():
		return recommended_id
	var safest_odds := -1.0
	for evaluation in evaluations:
		var odds := float(evaluation.get("odds", 0.0))
		if odds > safest_odds:
			safest_odds = odds
			recommended_id = str(evaluation.get("id", ""))
	return recommended_id


static func expected_return_score(evaluation: Dictionary, class_id := "") -> float:
	var duration := maxf(1.0, float(evaluation.get("duration", 1.0)))
	var value := float(evaluation.get("credits", 0)) + float(evaluation.get("xp", 0)) * 0.35 + float(evaluation.get("scrap", 0)) * SCRAP_VALUE
	var affinity := Classes.approach_affinity(class_id, str(evaluation.get("id", "")))
	return float(evaluation.get("odds", 0.0)) * value * affinity / duration


static func recommendation_label(player: Dictionary, approach_id: String) -> String:
	var profile := Classes.route_profile_text(str(player.get("class_id", "")), approach_id)
	return "MELHOR EQUILÍBRIO" if profile.is_empty() else "SINERGIA · %s" % profile


static func field_test_defeat_text(context: Dictionary) -> String:
	if context.is_empty():
		return ""
	var tested := "%s %d%%" % [str(context.get("tested_approach_name", "CONTRATO BASE")).to_upper(), roundi(float(context.get("tested_odds", 0.0)) * 100.0)]
	if bool(context.get("overridden", false)):
		return "OVERRIDE DERROTADO · TESTADA %s → ESCOLHIDA %s · REAVALIE A ROTA" % [tested, str(context.get("chosen_approach_name", "CONTRATO BASE")).to_upper()]
	return "ROTA TESTADA TAMBÉM FALHOU · %s · REFORCE A BUILD OU REVEJA O INCIDENTE" % tested
