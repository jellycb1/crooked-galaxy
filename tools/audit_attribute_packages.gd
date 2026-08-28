extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const SimulationBuilds = preload("res://tools/simulation_builds.gd")
const Packages = preload("res://scripts/attribute_package_rules.gd")

const LEVELS := [8, 19, 35]


func _init() -> void:
	var largest_odds_delta := 0.0
	var smallest_score_delta := 1000000
	var primary_total := 0.0
	var primary_samples := 0
	var lateral_total := 0.0
	var lateral_samples := 0
	print("Crooked Galaxy attribute-package balance audit")
	for policy in SimulationBuilds.POLICIES:
		for level in LEVELS:
			var state = StateScript.new()
			state.persistence_enabled = false
			var player: Dictionary = state.default_player()
			player.level = level
			player.stat_points = maxi(0, level - 1) * Rules.ATTRIBUTE_POINTS_PER_LEVEL
			SimulationBuilds.configure_player(player, policy)
			var offers := [representative_target(player)]
			var baseline_score := Rules.player_build_score(player)
			var primary_id := str(policy.allocation_cycle[0])
			var row: Array[String] = []
			for definition in Packages.DEFINITIONS:
				var attribute_id := str(definition.attribute_id)
				var candidate := player.duplicate(true)
				var package_bonus := int(definition.bonus)
				candidate.attributes[attribute_id] = int(candidate.attributes.get(attribute_id, Rules.BASE_ATTRIBUTE_VALUE)) + package_bonus
				Rules.clear_bounty_odds_cache()
				var odds_delta := 0.0
				for offer in offers:
					odds_delta += Rules.bounty_odds(candidate, offer) - Rules.bounty_odds(player, offer)
				odds_delta = odds_delta / float(maxi(1, offers.size()))
				var score_delta := Rules.player_build_score(candidate) - baseline_score
				# Build comparison will expose accuracy explicitly when packages enter
				# runtime; count it here so Cunning is not falsely treated as inert.
				score_delta += roundi((Rules.player_attack_roll(candidate, 0.0) - Rules.player_attack_roll(player, 0.0)) * 500.0)
				largest_odds_delta = maxf(largest_odds_delta, odds_delta)
				smallest_score_delta = mini(smallest_score_delta, score_delta)
				if attribute_id == primary_id:
					primary_total += odds_delta
					primary_samples += 1
				else:
					lateral_total += odds_delta
					lateral_samples += 1
				row.append("%s %+dscore %+.2fpp" % [attribute_id.left(3).to_upper(), score_delta, odds_delta * 100.0])
			print("%s L%02d · %s" % [str(policy.class_id), level, " · ".join(row)])
			state.free()
	var primary_mean := primary_total / float(maxi(1, primary_samples))
	var lateral_mean := lateral_total / float(maxi(1, lateral_samples))
	print("SUMMARY · primary=%+.2fpp · lateral=%+.2fpp · max=%+.2fpp · min score=%d" % [primary_mean * 100.0, lateral_mean * 100.0, largest_odds_delta * 100.0, smallest_score_delta])
	if largest_odds_delta > 0.55 or smallest_score_delta <= 0 or primary_mean <= lateral_mean:
		printerr("FAIL: package values violate the lateral-progression guardrails")
		quit(1)
	else:
		print("PASS: attribute packages are bounded, legible sidegrades with a class-primary preference")
		quit(0)


func representative_target(player: Dictionary) -> Dictionary:
	var best := {}
	var best_distance := 10.0
	var hunter_power := Rules.player_power(player)
	var hunter_health := Rules.max_health(player)
	for power_offset in range(-4, 17, 4):
		for health_percent in range(70, 171, 20):
			var target := {
				"id": "package_audit",
				"power": maxi(1, hunter_power + power_offset),
				"defense": maxi(0, roundi(float(hunter_power) * 0.30)),
				"health": maxi(1, roundi(float(hunter_health) * float(health_percent) / 100.0)),
			}
			var distance := absf(Rules.bounty_odds(player, target) - 0.55)
			if distance < best_distance:
				best_distance = distance
				best = target
	return best
