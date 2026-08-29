extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Contracts = preload("res://scripts/contract_rules.gd")
const Missions = preload("res://scripts/mission_rules.gd")
const Builds = preload("res://tools/simulation_builds.gd")

const CHECKPOINT_LEVELS := [30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180]

var failures := 0


func _init() -> void:
	for level in CHECKPOINT_LEVELS:
		for policy in Builds.POLICIES:
			var player := Builds.representative_player(level, policy)
			var checkpoint_has_separated_choice := false
			for cycle in 20:
				player.wins = cycle
				for offer in Missions.board_offers(player):
					var evaluations := Contracts.evaluate_approaches(player, offer, Content.contract_approaches())
					var viable_count := evaluations.filter(func(evaluation): return float(evaluation.odds) >= Contracts.MIN_RECOMMENDED_ODDS).size()
					var quiet_odds := float(evaluations[0].odds)
					var hot_odds := float(evaluations[1].odds)
					var premium_odds := float(evaluations[2].odds)
					check(viable_count >= 2, "%s level %d cycle %d %s offer keeps at least two viable approaches (%s)" % [str(policy.id), level, cycle, str(offer.mission_role), odds_text(evaluations)])
					check(quiet_odds >= hot_odds and hot_odds >= premium_odds, "%s level %d preserves ordered route pressure (%s)" % [str(policy.id), level, odds_text(evaluations)])
					checkpoint_has_separated_choice = checkpoint_has_separated_choice or quiet_odds - premium_odds >= 0.15
			check(checkpoint_has_separated_choice, "%s level %d includes a visibly separated risk/reward decision" % [str(policy.id), level])

	# Every currently authored late world receives the same class-neutral contract:
	# its unlock level and a standard offer. This catches a new pack that silently
	# reintroduces planet-index pressure into the route layer.
	for planet in Content.PLANETS:
		var unlock_level := int(planet.get("unlock_level", 1))
		if unlock_level < CHECKPOINT_LEVELS[0]:
			continue
		var targets := Missions.targets_for_planet(str(planet.id))
		for policy in Builds.POLICIES:
			var player := Builds.representative_player(unlock_level, policy)
			var offer := Missions.offer_for_target(player, targets[0], "standard")
			var evaluations := Contracts.evaluate_approaches(player, offer, Content.contract_approaches())
			var viable_count := evaluations.filter(func(evaluation): return float(evaluation.odds) >= Contracts.MIN_RECOMMENDED_ODDS).size()
			check(viable_count >= 2, "%s unlock contract is viable through two routes for %s (%s)" % [str(planet.id), str(policy.id), odds_text(evaluations)])

	if failures == 0:
		print("PASS: every late-game class cohort retains ordered, viable, and visibly distinct approach choices")
		quit(0)
	else:
		printerr("FAIL: %d late approach cohort guard(s) failed" % failures)
		quit(1)


func odds_text(evaluations: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for evaluation in evaluations:
		parts.append("%s=%d%%" % [str(evaluation.id), roundi(float(evaluation.odds) * 100.0)])
	return "/".join(parts)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
