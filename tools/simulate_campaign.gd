extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRulesScript = preload("res://scripts/contract_rules.gd")
const SimulationBuildsScript = preload("res://tools/simulation_builds.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")

const CAREERS := 20
const STRATEGIES := ["recommended", "corporate_when_viable"]
const MAX_ATTEMPTS_PER_CAPTURE := 25


func _init() -> void:
	var career_count := int(OS.get_environment("CG_CAMPAIGN_CAREERS")) if not OS.get_environment("CG_CAMPAIGN_CAREERS").is_empty() else CAREERS
	career_count = maxi(1, career_count)
	var strategies: Array = [OS.get_environment("CG_CAMPAIGN_STRATEGY")] if not OS.get_environment("CG_CAMPAIGN_STRATEGY").is_empty() else STRATEGIES
	var build_policies := SimulationBuildsScript.selected_policies(OS.get_environment("CG_CAMPAIGN_BUILD"))
	var market_policy := OS.get_environment("CG_CAMPAIGN_MARKET") if not OS.get_environment("CG_CAMPAIGN_MARKET").is_empty() else "active"
	var transport_policy := OS.get_environment("CG_CAMPAIGN_TRANSPORT") if not OS.get_environment("CG_CAMPAIGN_TRANSPORT").is_empty() else "active"
	if not market_policy in ["active", "off"]:
		printerr("Unknown CG_CAMPAIGN_MARKET. Use active or off.")
		quit(2)
		return
	if not transport_policy in ["active", "off"]:
		printerr("Unknown CG_CAMPAIGN_TRANSPORT. Use active or off.")
		quit(2)
		return
	if build_policies.is_empty():
		printerr("Unknown CG_CAMPAIGN_BUILD. Use breaker_balanced, gunslinger_balanced, hacker_balanced, or unassigned_control.")
		quit(2)
		return
	print("Crooked Galaxy sequential campaign (%d deterministic careers per strategy/build · market=%s · transport=%s)" % [career_count, market_policy, transport_policy])
	for strategy in strategies:
		for build_policy in build_policies:
			run_strategy_build(strategy, build_policy, career_count, market_policy, transport_policy)
	quit(0)


func run_strategy_build(strategy: String, build_policy: Dictionary, career_count: int, market_policy: String, transport_policy: String) -> void:
	var results := empty_results()
	var corporate_scrap_totals: Array = []
	var workshop_action_totals: Array = []
	var final_levels: Array = []
	var final_credits: Array = []
	var final_scrap: Array = []
	var final_attributes: Array[String] = []
	var market_spend_totals: Array = []
	var market_purchase_totals: Array = []
	var market_refresh_totals: Array = []
	var transport_spend_totals: Array = []
	var transport_purchase_totals: Array = []
	var transport_saved_seconds_totals: Array = []
	var final_transports: Array[String] = []
	var stalled_careers := 0
	for career_seed in career_count:
		var state = StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		SimulationBuildsScript.configure_player(state.player, build_policy)
		state.rng.seed = 150000 + career_seed * 211
		var fight_rng := RandomNumberGenerator.new()
		fight_rng.seed = 250000 + career_seed * 307
		var corporate_scrap := 0
		var workshop_actions := 0
		var market_spend := 0
		var market_purchases := 0
		var market_refreshes := 0
		var transport_spend := 0
		var transport_purchases := 0
		var transport_saved_seconds := 0.0
		var career_stalled := false
		for planet in Content.PLANETS:
			var planet_id := str(planet.id)
			state.player.current_planet_id = planet_id
			for tier in 4:
				if transport_policy == "active":
					var hangar_result := visit_hangar(state)
					transport_spend += int(hangar_result.spent)
					transport_purchases += int(hangar_result.purchases)
				if market_policy == "active":
					var market_result := visit_market(state)
					market_spend += int(market_result.spent)
					market_purchases += int(market_result.purchases)
					market_refreshes += int(market_result.refreshes)
				var target := Content.target_for_planet_tier(planet_id, tier)
				var arrival_contract := strategy_contract(state.player, target, strategy)
				results[planet_id].odds[tier].append(Rules.bounty_odds(state.player, arrival_contract))
				results[planet_id].power[tier].append(Rules.player_power(state.player))
				results[planet_id].health[tier].append(Rules.max_health(state.player))
				results[planet_id].approach[tier].append(str(arrival_contract.get("approach", {}).get("id", "none")))
				results[planet_id].option_odds[tier].append(contract_odds(state.player, target))
				var captures := 1 if tier == 3 else 3
				var tier_attempts := 0
				var tier_defeats := 0
				for _capture in captures:
					var won := false
					var contract := strategy_contract(state.player, target, strategy)
					for _attempt in MAX_ATTEMPTS_PER_CAPTURE:
						transport_saved_seconds += TransportRulesScript.saved_seconds(state.player, float(contract.duration))
						var fight_odds := Rules.bounty_odds(state.player, contract)
						results[planet_id].attempt_odds[tier].append(fight_odds)
						results[planet_id].attempt_approach[tier].append(str(contract.get("approach", {}).get("id", "none")))
						tier_attempts += 1
						if fight_rng.randf() <= fight_odds:
							var summary := claim_win(state, contract)
							corporate_scrap += int(summary.get("contract_scrap", 0))
							SimulationBuildsScript.apply_available_points(state.player, build_policy)
							workshop_actions += spend_workshop_scrap(state)
							won = true
							break
						tier_defeats += 1
						var recommendation_changed := int(state.player.get("capture_streak", 0)) > 0
						state.player.capture_streak = 0
						if recommendation_changed:
							contract = strategy_contract(state.player, target, strategy)
					if not won:
						career_stalled = true
						break
				results[planet_id].attempts[tier].append(tier_attempts)
				results[planet_id].defeats[tier].append(tier_defeats)
				if career_stalled:
					break
			if career_stalled:
				break
		corporate_scrap_totals.append(corporate_scrap)
		workshop_action_totals.append(workshop_actions)
		final_levels.append(int(state.player.level))
		final_credits.append(int(state.player.credits))
		final_scrap.append(int(state.player.scrap))
		final_attributes.append(SimulationBuildsScript.attribute_summary(state.player))
		market_spend_totals.append(market_spend)
		market_purchase_totals.append(market_purchases)
		market_refresh_totals.append(market_refreshes)
		transport_spend_totals.append(transport_spend)
		transport_purchase_totals.append(transport_purchases)
		transport_saved_seconds_totals.append(transport_saved_seconds)
		final_transports.append(str(state.player.get("active_transport_id", "none")))
		if career_stalled:
			stalled_careers += 1
		state.free()
	print("\n=== %s · %s · stalled=%d%% ===" % [strategy, str(build_policy.name), roundi(float(stalled_careers) / float(career_count) * 100.0)])
	print("FINAL · level=%d · credits=%d · scrap=%d · corporate scrap=%d · workshop actions=%d · market spent=%d/buys=%d/refreshes=%d · hangar spent=%d/buys=%d/saved=%ds/active=%s · %s" % [roundi(median(final_levels)), roundi(median(final_credits)), roundi(median(final_scrap)), roundi(median(corporate_scrap_totals)), roundi(median(workshop_action_totals)), roundi(median(market_spend_totals)), roundi(median(market_purchase_totals)), roundi(median(market_refresh_totals)), roundi(median(transport_spend_totals)), roundi(median(transport_purchase_totals)), roundi(median(transport_saved_seconds_totals)), representative_string(final_transports), representative_string(final_attributes)])
	print_decision_summary(results)
	print_results(results)


func empty_results() -> Dictionary:
	var results: Dictionary = {}
	for planet in Content.PLANETS:
		results[str(planet.id)] = {"odds": [[], [], [], []], "power": [[], [], [], []], "health": [[], [], [], []], "approach": [[], [], [], []], "option_odds": [[], [], [], []], "attempts": [[], [], [], []], "defeats": [[], [], [], []], "attempt_odds": [[], [], [], []], "attempt_approach": [[], [], [], []]}
	return results


func print_results(results: Dictionary) -> void:
	for planet in Content.PLANETS:
		var planet_id := str(planet.id)
		print("\n%s" % str(planet.name))
		for tier in 4:
			var target := Content.target_for_planet_tier(planet_id, tier)
			var odds: Array = results[planet_id].odds[tier]
			if odds.is_empty():
				print("  %-24s unreached" % str(target.name))
				continue
			print("  %-24s arrival=%d%% · power=%d · health=%d · options=%s" % [str(target.name), roundi(median(odds) * 100.0), roundi(median(results[planet_id].power[tier])), roundi(median(results[planet_id].health[tier])), option_odds_summary(results[planet_id].option_odds[tier])])
			print("    attempts=%d · defeat careers=%d%% · fight odds=%d%% (min %d%%, below 55%%=%d%%) · routes=%s" % [roundi(median(results[planet_id].attempts[tier])), roundi(fraction_above(results[planet_id].defeats[tier], 0.0) * 100.0), roundi(median(results[planet_id].attempt_odds[tier]) * 100.0), roundi(minimum(results[planet_id].attempt_odds[tier]) * 100.0), roundi(fraction_below(results[planet_id].attempt_odds[tier], ContractRulesScript.MIN_RECOMMENDED_ODDS) * 100.0), approach_summary(results[planet_id].attempt_approach[tier])])


func print_decision_summary(results: Dictionary) -> void:
	var option_total := 0
	var saturated_options := 0
	var decision_snapshots := 0
	var multi_viable_snapshots := 0
	var meaningful_snapshots := 0
	var chosen_arrivals: Array = []
	var all_routes: Array = []
	for planet in Content.PLANETS:
		var planet_results: Dictionary = results[str(planet.id)]
		for tier in 4:
			chosen_arrivals.append_array(planet_results.odds[tier])
			all_routes.append_array(planet_results.attempt_approach[tier])
			for sample in planet_results.option_odds[tier]:
				decision_snapshots += 1
				var viable_count := 0
				var lowest := 1.0
				var highest := 0.0
				for odds in sample.values():
					option_total += 1
					var chance := float(odds)
					lowest = minf(lowest, chance)
					highest = maxf(highest, chance)
					if chance >= ContractRulesScript.MIN_RECOMMENDED_ODDS:
						viable_count += 1
					if chance >= 0.99:
						saturated_options += 1
				if viable_count >= 2:
					multi_viable_snapshots += 1
					if highest - lowest >= 0.15:
						meaningful_snapshots += 1
	var saturated_percent := roundi(float(saturated_options) / float(maxi(1, option_total)) * 100.0)
	var arrival_percent := roundi(fraction_at_least(chosen_arrivals, 0.99) * 100.0)
	var multi_viable_percent := roundi(float(multi_viable_snapshots) / float(maxi(1, decision_snapshots)) * 100.0)
	var meaningful_percent := roundi(float(meaningful_snapshots) / float(maxi(1, decision_snapshots)) * 100.0)
	print("DECISÕES · opções em 99%%=%d%% · chegadas em 99%%=%d%% · ≥2 viáveis=%d%% · escolha separada=%d%% · rotas escolhidas=%s" % [saturated_percent, arrival_percent, multi_viable_percent, meaningful_percent, approach_summary(all_routes)])
	for planet in Content.PLANETS:
		print_planet_decision_summary(results, str(planet.id), str(planet.name))


func print_planet_decision_summary(results: Dictionary, planet_id: String, planet_name: String) -> void:
	var option_total := 0
	var saturated_options := 0
	var decision_snapshots := 0
	var multi_viable_snapshots := 0
	var meaningful_snapshots := 0
	var planet_results: Dictionary = results[planet_id]
	for tier in 4:
		for sample in planet_results.option_odds[tier]:
			decision_snapshots += 1
			var viable_count := 0
			var lowest := 1.0
			var highest := 0.0
			for odds in sample.values():
				option_total += 1
				var chance := float(odds)
				lowest = minf(lowest, chance)
				highest = maxf(highest, chance)
				if chance >= ContractRulesScript.MIN_RECOMMENDED_ODDS:
					viable_count += 1
				if chance >= 0.99:
					saturated_options += 1
			if viable_count >= 2:
				multi_viable_snapshots += 1
				if highest - lowest >= 0.15:
					meaningful_snapshots += 1
	print("  %-20s opções 99%%=%d%% · ≥2 viáveis=%d%% · separadas=%d%%" % [planet_name, roundi(float(saturated_options) / float(maxi(1, option_total)) * 100.0), roundi(float(multi_viable_snapshots) / float(maxi(1, decision_snapshots)) * 100.0), roundi(float(meaningful_snapshots) / float(maxi(1, decision_snapshots)) * 100.0)])


func strategy_contract(player: Dictionary, target: Dictionary, strategy: String) -> Dictionary:
	if strategy == "corporate_when_viable":
		var corporate := Content.apply_approach(target, Content.CONTRACT_APPROACHES[2])
		if Rules.bounty_odds(player, corporate) >= ContractRulesScript.MIN_RECOMMENDED_ODDS:
			return corporate
	return recommended_contract(player, target)


func recommended_contract(player: Dictionary, target: Dictionary) -> Dictionary:
	var evaluations := ContractRulesScript.evaluate_approaches(player, target, Content.contract_approaches())
	var recommended_id := ContractRulesScript.recommended_approach_id(evaluations)
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			return evaluation.preview
	return target.duplicate(true)


func contract_odds(player: Dictionary, target: Dictionary) -> Dictionary:
	var odds: Dictionary = {}
	for approach in Content.contract_approaches():
		odds[str(approach.id)] = Rules.bounty_odds(player, Content.apply_approach(target, approach))
	return odds


func claim_win(state: StateScript, contract: Dictionary) -> Dictionary:
	var target_id := str(contract.id)
	var captures := int(state.player.get("captures_by_target", {}).get(target_id, 0))
	state.phase = state.Phase.REWARD
	state.current_bounty = contract.duplicate(true)
	state.pending_loot = Content.generate_loot(contract, state.rng, Rules.target_mastery_level(captures))
	var equip_item := Rules.is_upgrade_for_player(state.player, state.pending_loot)
	var recycle_item := not equip_item and state.can_recycle_reward(state.pending_loot)
	return state.claim_reward(equip_item, false, recycle_item)


func spend_workshop_scrap(state: StateScript) -> int:
	var actions := 0
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
			return actions
		choices.sort_custom(func(a, b): return float(a.value) / float(a.cost) > float(b.value) / float(b.cost))
		var best: Dictionary = choices[0]
		if str(best.kind) == "power":
			state.upgrade_equipped(str(best.slot))
		else:
			state.reinforce_equipped(str(best.slot))
		actions += 1
	return actions


func visit_market(state: StateScript) -> Dictionary:
	var credits_before := int(state.player.credits)
	var purchases := buy_market_upgrades(state)
	var refreshes := 0
	# A rational player renews stale stock only with a healthy reserve. This
	# keeps the simulator from treating the sink as a compulsory progression tax.
	var refresh_cost := MarketRules.refresh_cost(state.player)
	if purchases == 0 and int(state.player.credits) >= refresh_cost * 3 and state.refresh_market():
		refreshes = 1
		purchases += buy_market_upgrades(state)
	return {"spent": credits_before - int(state.player.credits), "purchases": purchases, "refreshes": refreshes}


func visit_hangar(state: StateScript) -> Dictionary:
	var credits_before := int(state.player.credits)
	var purchases := 0
	# Permanent speed is valuable, but a rational hunter keeps a small reserve
	# for incidents and equipment. Prefer the fastest unlocked affordable model.
	for index in range(TransportRulesScript.DEFINITIONS.size() - 1, -1, -1):
		var transport: Dictionary = TransportRulesScript.DEFINITIONS[index]
		if not TransportRulesScript.is_unlocked(state.player, transport) or TransportRulesScript.is_owned(state.player, str(transport.id)):
			continue
		if int(state.player.credits) >= int(transport.price) + 250 and state.acquire_or_equip_transport(str(transport.id)):
			purchases = 1
			break
	return {"spent": credits_before - int(state.player.credits), "purchases": purchases}


func buy_market_upgrades(state: StateScript) -> int:
	var purchases := 0
	for _attempt in 3:
		var choices: Array[Dictionary] = []
		for offer in state.market_offers():
			if bool(offer.purchased) or int(offer.price) > int(state.player.credits) or not Rules.is_upgrade_for_player(state.player, offer.item):
				continue
			var equipped: Dictionary = state.player[str(offer.item.slot)]
			var gain := maxi(1, int(offer.item.power) - int(equipped.power))
			choices.append({"id": str(offer.id), "price": int(offer.price), "efficiency": float(gain) / float(offer.price)})
		if choices.is_empty():
			break
		choices.sort_custom(func(a, b): return float(a.efficiency) > float(b.efficiency))
		if not state.buy_market_offer(str(choices[0].id)):
			break
		purchases += 1
	return purchases


func median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])


func fraction_above(values: Array, threshold: float) -> float:
	var count := 0
	for value in values:
		if float(value) > threshold:
			count += 1
	return float(count) / float(values.size())


func fraction_below(values: Array, threshold: float) -> float:
	var count := 0
	for value in values:
		if float(value) < threshold:
			count += 1
	return float(count) / float(values.size())


func fraction_at_least(values: Array, threshold: float) -> float:
	if values.is_empty():
		return 0.0
	var count := 0
	for value in values:
		if float(value) >= threshold:
			count += 1
	return float(count) / float(values.size())


func minimum(values: Array) -> float:
	var result := INF
	for value in values:
		result = minf(result, float(value))
	return result


func representative_string(values: Array) -> String:
	if values.is_empty():
		return "sem dados"
	return str(values[values.size() / 2])


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
