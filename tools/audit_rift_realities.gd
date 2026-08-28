extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const Builds = preload("res://tools/simulation_builds.gd")
const Content = preload("res://scripts/content_db.gd")


func _init() -> void:
	print("Crooked Galaxy keyed Rift audit")
	for reality in Challenge.REALITIES:
		var reality_id := str(reality.id)
		print("\n%s · unlock L%d" % [str(reality.name), int(reality.unlock_level)])
		for stage_index in reality.stages.size():
			var projected_level: int = int(reality.unlock_level) + stage_index * (5 if reality_id != Challenge.FIRST_REALITY_ID else 0)
			var odds: Array[float] = []
			var players: Array[Dictionary] = []
			for policy in Builds.POLICIES:
				var player := representative_player(projected_level, policy)
				apply_prior_rewards(player, reality_id, stage_index)
				players.append(player)
				odds.append(Rules.bounty_odds(player, Challenge.stage_at(stage_index, reality_id)))
			odds.sort()
			var factor := suggested_factor(players, Challenge.stage_at(stage_index, reality_id)) if reality_id != Challenge.FIRST_REALITY_ID else 1.0
			print("  enemy %02d · L%d · %d-%d%% · factor %.2f · P%d D%d H%d" % [stage_index + 1, projected_level, roundi(odds[0] * 100.0), roundi(odds[-1] * 100.0), factor, int(Challenge.stage_at(stage_index, reality_id).power), int(Challenge.stage_at(stage_index, reality_id).defense), int(Challenge.stage_at(stage_index, reality_id).health)])
	quit(0)


func representative_player(level: int, policy: Dictionary) -> Dictionary:
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


func apply_prior_rewards(player: Dictionary, reality_id: String, stage_index: int) -> void:
	for reward_index in stage_index:
		var reward := Challenge.reward_for(Challenge.stage_at(reward_index, reality_id), Content.ITEM_TRAITS)
		if Rules.is_upgrade_for_player(player, reward):
			player[str(reward.slot)] = reward
	Rules.clear_bounty_odds_cache()


func suggested_factor(players: Array[Dictionary], stage: Dictionary) -> float:
	var low := 0.5
	var high := 3.0
	for _iteration in 12:
		var factor := (low + high) * 0.5
		var candidate := stage.duplicate(true)
		for stat_key in ["power", "defense", "health"]:
			candidate[stat_key] = maxi(1, roundi(float(stage[stat_key]) * factor))
		Rules.clear_bounty_odds_cache()
		var average := 0.0
		for player in players:
			average += Rules.bounty_odds(player, candidate) / float(players.size())
		if average > 0.65:
			low = factor
		else:
			high = factor
	return snappedf((low + high) * 0.5, 0.01)
