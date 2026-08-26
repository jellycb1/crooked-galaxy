extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Missions = preload("res://scripts/mission_rules.gd")
const Contracts = preload("res://scripts/contract_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const Builds = preload("res://tools/simulation_builds.gd")
const Transport = preload("res://scripts/transport_rules.gd")

const CHECKPOINT_LEVELS := [1, 4, 8, 13, 19, 30, 50]


func _init() -> void:
	print("Crooked Galaxy interplanetary mission-network audit")
	for level in CHECKPOINT_LEVELS:
		print("\nLEVEL %d · XP threshold %d" % [level, Rules.xp_needed(level)])
		for policy in Builds.POLICIES:
			var player := representative_player(level, policy)
			var offers := Missions.board_offers(player)
			var rows: Array[String] = []
			for offer in offers:
				var evaluations := Contracts.evaluate_approaches(player, offer, Content.contract_approaches())
				var recommended_id := Contracts.recommended_approach_id(evaluations, str(player.class_id))
				var recommended_odds := 0.0
				for evaluation in evaluations:
					if str(evaluation.id) == recommended_id:
						recommended_odds = float(evaluation.odds)
						break
				rows.append("%s/%s raw=%d%% rec=%s:%d%% xp=%d time=%ds" % [str(offer.mission_role), str(offer.planet_id), roundi(Rules.bounty_odds(player, offer) * 100.0), recommended_id, roundi(recommended_odds * 100.0), int(offer.xp), roundi(Transport.effective_mission_duration(player, offer))])
			print("  %-28s P%d H%d · %s" % [str(policy.name), Rules.player_power(player), Rules.max_health(player), " | ".join(rows)])
			var role_ranges := {"safe": [], "standard": [], "dangerous": []}
			for cycle in 20:
				player.wins = cycle
				for offer in Missions.board_offers(player):
					var evaluations := Contracts.evaluate_approaches(player, offer, Content.contract_approaches())
					var recommended_id := Contracts.recommended_approach_id(evaluations, str(player.class_id))
					for evaluation in evaluations:
						if str(evaluation.id) == recommended_id:
							role_ranges[str(offer.mission_role)].append(float(evaluation.odds))
							break
			print("    20-cycle recommended ranges · safe %s · standard %s · dangerous %s" % [range_text(role_ranges.safe), range_text(role_ranges.standard), range_text(role_ranges.dangerous)])
	quit(0)


static func representative_player(level: int, policy: Dictionary) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	player.level = level
	player.base_power = 10 + (level - 1) * 2
	player.stat_points = (level - 1) * Rules.ATTRIBUTE_POINTS_PER_LEVEL
	if level > 1:
		var prior_mission_power := 11 + maxi(0, level - 2) * 5
		var gear_power := maxi(1, roundi(float(prior_mission_power) * 0.55))
		player.weapon = {"id": "audit_weapon", "slot": "weapon", "power": gear_power}
		player.armor = {"id": "audit_armor", "slot": "armor", "power": gear_power}
	Builds.configure_player(player, policy)
	return player


static func range_text(values: Array) -> String:
	var lowest := 1.0
	var highest := 0.0
	for value in values:
		lowest = minf(lowest, float(value))
		highest = maxf(highest, float(value))
	return "%d-%d%%" % [roundi(lowest * 100.0), roundi(highest * 100.0)]
