extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRulesScript = preload("res://scripts/contract_rules.gd")

const CAREERS := 100


func _init() -> void:
	var odds_by_tier := [[], [], [], []]
	var power_by_tier := [[], [], [], []]
	var health_by_tier := [[], [], [], []]
	for career_seed in CAREERS:
		var state = StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		state.rng.seed = 41000 + career_seed * 97
		for tier in 4:
			var target := Content.target_for_planet_tier(Content.PLANET.id, tier)
			var contract := recommended_contract(state.player, target)
			odds_by_tier[tier].append(Rules.bounty_odds(state.player, contract))
			power_by_tier[tier].append(Rules.player_power(state.player))
			health_by_tier[tier].append(Rules.max_health(state.player))
			var captures_this_tier := 1 if tier == 3 else 3
			for _capture in captures_this_tier:
				claim_simulated_win(state, contract)
		state.free()
	print("Crooked Galaxy first-chapter repeat path (%d deterministic loot-only careers; wins assumed)" % CAREERS)
	for tier in 4:
		var target := Content.target_for_planet_tier(Content.PLANET.id, tier)
		print("  %s: median odds=%d%% · below 55%%=%d%% · median power=%d · median health=%d" % [
			str(target.name),
			roundi(median(odds_by_tier[tier]) * 100.0),
			roundi(fraction_below(odds_by_tier[tier], ContractRulesScript.MIN_RECOMMENDED_ODDS) * 100.0),
			roundi(median(power_by_tier[tier])),
			roundi(median(health_by_tier[tier])),
		])
	quit(0)


func recommended_contract(player: Dictionary, target: Dictionary) -> Dictionary:
	var evaluations: Array[Dictionary] = []
	for approach in Content.contract_approaches():
		var contract := Content.apply_approach(target, approach)
		evaluations.append({
			"id": str(approach.id),
			"odds": Rules.bounty_odds(player, contract),
			"duration": float(contract.duration),
			"credits": int(contract.credits),
			"xp": int(contract.xp),
			"contract": contract,
		})
	var recommended_id := ContractRulesScript.recommended_approach_id(evaluations)
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			return evaluation.contract
	return target.duplicate(true)


func claim_simulated_win(state: StateScript, contract: Dictionary) -> void:
	var target_id := str(contract.id)
	var captures := int(state.player.get("captures_by_target", {}).get(target_id, 0))
	state.phase = state.Phase.REWARD
	state.current_bounty = contract.duplicate(true)
	state.pending_loot = Content.generate_loot(contract, state.rng, Rules.target_mastery_level(captures))
	var equip_item := Rules.is_upgrade_for_player(state.player, state.pending_loot)
	var recycle_item := not equip_item and state.can_recycle_reward(state.pending_loot)
	state.claim_reward(equip_item, false, recycle_item)


func median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])


func fraction_below(values: Array, threshold: float) -> float:
	var count := 0
	for value in values:
		if float(value) < threshold:
			count += 1
	return float(count) / float(values.size())
