class_name ContractRules
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")

const MIN_RECOMMENDED_ODDS := 0.55
const SCRAP_VALUE := 12.0


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
			"xp": int(preview.xp),
			"scrap": int(preview.get("scrap_reward", 0)),
			"duration": int(preview.duration),
		})
	return evaluations


static func recommended_approach_id(evaluations: Array[Dictionary]) -> String:
	var recommended_id := ""
	var best_score := -1.0
	for evaluation in evaluations:
		var odds := float(evaluation.get("odds", 0.0))
		if odds < MIN_RECOMMENDED_ODDS:
			continue
		var score := expected_return_score(evaluation)
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


static func expected_return_score(evaluation: Dictionary) -> float:
	var duration := maxf(1.0, float(evaluation.get("duration", 1.0)))
	var value := float(evaluation.get("credits", 0)) + float(evaluation.get("xp", 0)) * 0.35 + float(evaluation.get("scrap", 0)) * SCRAP_VALUE
	return float(evaluation.get("odds", 0.0)) * value / duration
