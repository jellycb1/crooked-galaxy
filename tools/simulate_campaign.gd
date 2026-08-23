extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRulesScript = preload("res://scripts/contract_rules.gd")

const CAREERS := 20


func _init() -> void:
	var results: Dictionary = {}
	for planet in Content.PLANETS:
		results[str(planet.id)] = {"odds": [[], [], [], []], "power": [[], [], [], []], "health": [[], [], [], []], "approach": [[], [], [], []], "option_odds": [[], [], [], []]}
	for career_seed in CAREERS:
		var state = StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		state.rng.seed = 150000 + career_seed * 211
		for planet in Content.PLANETS:
			var planet_id := str(planet.id)
			state.player.current_planet_id = planet_id
			for tier in 4:
				var target := Content.target_for_planet_tier(planet_id, tier)
				var contract := recommended_contract(state.player, target)
				results[planet_id].odds[tier].append(Rules.bounty_odds(state.player, contract))
				results[planet_id].power[tier].append(Rules.player_power(state.player))
				results[planet_id].health[tier].append(Rules.max_health(state.player))
				results[planet_id].approach[tier].append(str(contract.get("approach", {}).get("id", "none")))
				results[planet_id].option_odds[tier].append(contract_odds(state.player, target))
				var captures := 1 if tier == 3 else 3
				for _capture in captures:
					claim_win(state, contract)
					spend_workshop_scrap(state)
		state.free()
	print("Crooked Galaxy sequential campaign (%d deterministic careers)" % CAREERS)
	for planet in Content.PLANETS:
		var planet_id := str(planet.id)
		print("\n%s" % str(planet.name))
		for tier in 4:
			var target := Content.target_for_planet_tier(planet_id, tier)
			var odds: Array = results[planet_id].odds[tier]
			print("  %-24s arrival=%d%% · below 55%%=%d%% · power=%d · health=%d · approach=%s · options=%s" % [str(target.name), roundi(median(odds) * 100.0), roundi(fraction_below(odds, ContractRulesScript.MIN_RECOMMENDED_ODDS) * 100.0), roundi(median(results[planet_id].power[tier])), roundi(median(results[planet_id].health[tier])), approach_summary(results[planet_id].approach[tier]), option_odds_summary(results[planet_id].option_odds[tier])])
	quit(0)


func recommended_contract(player: Dictionary, target: Dictionary) -> Dictionary:
	var evaluations: Array[Dictionary] = []
	for approach in Content.contract_approaches():
		var contract := Content.apply_approach(target, approach)
		evaluations.append({"id": str(approach.id), "odds": Rules.bounty_odds(player, contract), "duration": float(contract.duration), "credits": int(contract.credits), "xp": int(contract.xp), "contract": contract})
	var recommended_id := ContractRulesScript.recommended_approach_id(evaluations)
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			return evaluation.contract
	return target.duplicate(true)


func contract_odds(player: Dictionary, target: Dictionary) -> Dictionary:
	var odds: Dictionary = {}
	for approach in Content.contract_approaches():
		odds[str(approach.id)] = Rules.bounty_odds(player, Content.apply_approach(target, approach))
	return odds


func claim_win(state: StateScript, contract: Dictionary) -> void:
	var target_id := str(contract.id)
	var captures := int(state.player.get("captures_by_target", {}).get(target_id, 0))
	state.phase = state.Phase.REWARD
	state.current_bounty = contract.duplicate(true)
	state.pending_loot = Content.generate_loot(contract, state.rng, Rules.target_mastery_level(captures))
	var equip_item := Rules.is_upgrade_for_player(state.player, state.pending_loot)
	var recycle_item := not equip_item and state.can_recycle_reward(state.pending_loot)
	state.claim_reward(equip_item, false, recycle_item)


func spend_workshop_scrap(state: StateScript) -> void:
	for _attempt in 20:
		var choices: Array[Dictionary] = []
		for slot in ["weapon", "armor"]:
			var item: Dictionary = state.player[slot]
			var power_cost := Rules.equipment_upgrade_cost(item)
			if power_cost <= int(state.player.scrap):
				choices.append({"kind": "power", "slot": slot, "cost": power_cost, "value": 10.0 if slot == "armor" else 8.0})
			if Rules.can_upgrade_integrity(item):
				var health_cost := Rules.equipment_integrity_upgrade_cost(item)
				if health_cost <= int(state.player.scrap):
					choices.append({"kind": "health", "slot": slot, "cost": health_cost, "value": 8.0})
		if choices.is_empty():
			return
		choices.sort_custom(func(a, b): return float(a.value) / float(a.cost) > float(b.value) / float(b.cost))
		var best: Dictionary = choices[0]
		if str(best.kind) == "power":
			state.upgrade_equipped(str(best.slot))
		else:
			state.reinforce_equipped(str(best.slot))


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


func approach_summary(values: Array) -> String:
	var counts: Dictionary = {}
	for value in values:
		var approach_id := str(value)
		counts[approach_id] = int(counts.get(approach_id, 0)) + 1
	var parts: Array[String] = []
	for approach in Content.contract_approaches():
		var approach_id := str(approach.id)
		var count := int(counts.get(approach_id, 0))
		if count > 0:
			parts.append("%s %d%%" % [approach_id, roundi(float(count) / float(values.size()) * 100.0)])
	return ", ".join(parts)


func option_odds_summary(samples: Array) -> String:
	var parts: Array[String] = []
	for approach in Content.contract_approaches():
		var values: Array = []
		for sample in samples:
			values.append(float(sample.get(str(approach.id), 0.0)))
		parts.append("%s %d%%" % [str(approach.id), roundi(median(values) * 100.0)])
	return "/".join(parts)
