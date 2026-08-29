extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const CoreRules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")

const CAREERS := 40
const CONTRACTS := 200


func _init() -> void:
	var final_wallets: Array[int] = []
	var counterfactual_wallets: Array[int] = []
	var service_spend: Array[int] = []
	var action_counts: Array[int] = []
	var final_levels: Array[int] = []
	var final_transport_counts: Array[int] = []
	for career_seed in CAREERS:
		var state = StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		state.rng.seed = 730000 + career_seed * 101
		var spent := 0
		var actions := 0
		for _contract_index in CONTRACTS:
			var contract: Dictionary = MissionRules.board_offers(state.player)[1]
			state.phase = state.Phase.REWARD
			state.current_bounty = contract.duplicate(true)
			var captures := int(state.player.get("captures_by_target", {}).get(str(contract.id), 0))
			state.pending_loot = ContentDB.generate_loot(contract, state.rng, CoreRules.target_mastery_level(captures))
			var equip := CoreRules.is_upgrade_for_player(state.player, state.pending_loot)
			var recycle := not equip and state.can_recycle_reward(state.pending_loot)
			state.claim_reward(equip, false, recycle)
			buy_available_transports(state)
			var before := int(state.player.credits)
			if spend_one_workshop_action(state):
				spent += before - int(state.player.credits)
				actions += 1
		final_wallets.append(int(state.player.credits))
		counterfactual_wallets.append(int(state.player.credits) + spent)
		service_spend.append(spent)
		action_counts.append(actions)
		final_levels.append(int(state.player.level))
		final_transport_counts.append(state.player.get("owned_transport_ids", []).size())
		state.free()
	print("Crooked Galaxy workshop Credit-sink audit (%d careers × %d contracts)" % [CAREERS, CONTRACTS])
	print("FINAL · level=%d · transports=%d · workshop actions=%d" % [median_int(final_levels), median_int(final_transport_counts), median_int(action_counts)])
	print("WALLET · with service=%d · without service=%d · median service spend=%d" % [median_int(final_wallets), median_int(counterfactual_wallets), median_int(service_spend)])
	var median_counterfactual := maxi(1, median_int(counterfactual_wallets))
	print("PRESSURE · service absorbs %.1f%% of otherwise retained Credits" % (100.0 * float(median_int(service_spend)) / float(median_counterfactual)))
	quit(0)


func buy_available_transports(state: StateScript) -> void:
	for definition in TransportRules.DEFINITIONS:
		var transport_id := str(definition.id)
		if TransportRules.is_owned(state.player, transport_id) or int(state.player.level) < int(definition.required_level):
			continue
		if int(state.player.credits) >= int(definition.price):
			state.acquire_or_equip_transport(transport_id)


func spend_one_workshop_action(state: StateScript) -> bool:
	var choices: Array[Dictionary] = []
	for slot in ["weapon", "armor"]:
		var item: Dictionary = state.player[slot]
		var power_scrap := CoreRules.equipment_upgrade_cost(item)
		var power_credits := CoreRules.equipment_upgrade_credit_cost(item)
		if int(state.player.scrap) >= power_scrap and int(state.player.credits) >= power_credits:
			choices.append({"slot": slot, "kind": "power", "scrap": power_scrap, "credits": power_credits, "value": 10.0 if slot == "armor" else 8.0})
		if CoreRules.can_upgrade_integrity(item):
			var integrity_scrap := CoreRules.equipment_integrity_upgrade_cost(item)
			var integrity_credits := CoreRules.equipment_integrity_credit_cost(item)
			if int(state.player.scrap) >= integrity_scrap and int(state.player.credits) >= integrity_credits:
				choices.append({"slot": slot, "kind": "integrity", "scrap": integrity_scrap, "credits": integrity_credits, "value": 8.0})
	if choices.is_empty():
		return false
	choices.sort_custom(func(a: Dictionary, b: Dictionary):
		var a_cost := float(a.scrap) + float(a.credits) / 100.0
		var b_cost := float(b.scrap) + float(b.credits) / 100.0
		return float(a.value) / a_cost > float(b.value) / b_cost
	)
	var best: Dictionary = choices[0]
	return state.upgrade_equipped(str(best.slot)) if str(best.kind) == "power" else state.reinforce_equipped(str(best.slot))


func median_int(values: Array[int]) -> int:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2] if not sorted.is_empty() else 0
