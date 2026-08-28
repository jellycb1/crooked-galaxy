extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Missions = preload("res://scripts/mission_rules.gd")
const Contracts = preload("res://scripts/contract_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const Builds = preload("res://tools/simulation_builds.gd")
const Transport = preload("res://scripts/transport_rules.gd")

const CHECKPOINT_LEVELS := [1, 4, 8, 13, 19, 30, 40, 50, 60, 70]


func _init() -> void:
	print("Crooked Galaxy interplanetary mission-network audit")
	for level in CHECKPOINT_LEVELS:
		print("\nLEVEL %d · XP threshold %d" % [level, Rules.xp_needed(level)])
		for policy in Builds.POLICIES:
			var player := Builds.representative_player(level, policy)
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
				rows.append("%s/%s raw=%d%% routes=%s rec=%s:%d%% xp=%d time=%ds" % [str(offer.mission_role), str(offer.planet_id), roundi(Rules.bounty_odds(player, offer) * 100.0), approach_odds_text(evaluations), recommended_id, roundi(recommended_odds * 100.0), int(offer.xp), roundi(Transport.effective_mission_duration(player, offer))])
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
	print_progression_timeline()
	quit(0)


static func print_progression_timeline() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var elapsed := 0.0
	var known_worlds := Missions.available_planets(int(player.level)).size()
	print("\nSTANDARD-OFFER WORLD DISCOVERY · no transport")
	for _capture in 700:
		var offers := Missions.board_offers(player)
		if offers.size() < 2:
			break
		var offer: Dictionary = offers[1]
		elapsed += Transport.effective_mission_duration(player, offer)
		player.xp = int(player.xp) + int(offer.xp)
		player.wins = int(player.wins) + 1
		while int(player.xp) >= Rules.xp_needed(int(player.level)):
			player.xp = int(player.xp) - Rules.xp_needed(int(player.level))
			player.level = int(player.level) + 1
		var next_worlds := Missions.available_planets(int(player.level)).size()
		if next_worlds > known_worlds:
			var planet := Missions.available_planets(int(player.level))[next_worlds - 1]
			print("  %s · level %d · win %d · cumulative base wait %ds" % [str(planet.id), int(player.level), int(player.wins), roundi(elapsed)])
			known_worlds = next_worlds


static func range_text(values: Array) -> String:
	var lowest := 1.0
	var highest := 0.0
	for value in values:
		lowest = minf(lowest, float(value))
		highest = maxf(highest, float(value))
	return "%d-%d%%" % [roundi(lowest * 100.0), roundi(highest * 100.0)]


static func approach_odds_text(evaluations: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for evaluation in evaluations:
		parts.append("%s:%d%%" % [str(evaluation.id), roundi(float(evaluation.odds) * 100.0)])
	return "/".join(parts)
