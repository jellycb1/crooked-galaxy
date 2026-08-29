class_name RiftCalendarEconomyModel
extends RefCounted

const StateScript = preload("res://scripts/game_state.gd")
const Challenge = preload("res://scripts/challenge_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const CoreRules = preload("res://scripts/core_rules.gd")
const DailyRules = preload("res://scripts/daily_objective_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const WeeklyRules = preload("res://scripts/weekly_operation_rules.gd")

const FIRST_REALITY_LEVELS := [8, 11, 15, 16, 22, 29, 32, 38, 45, 55, 70, 90]
const PROFILES := [
	{"id": "free_balanced", "daily_fuel": 100, "prefer_cheapest": false, "premium_refills": 0},
	{"id": "free_efficient", "daily_fuel": 100, "prefer_cheapest": true, "premium_refills": 0},
	{"id": "premium_efficient", "daily_fuel": 160, "prefer_cheapest": true, "premium_refills": 3},
]


static func simulate(profile: Dictionary) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	player.credits = 25
	player.scrap = 0
	player.capture_streak = 0
	player.wins = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 830147 + str(profile.id).hash()
	var result := {
		"id": str(profile.id),
		"days": 36,
		"hunts": 0,
		"rift_credits": 0,
		"mission_credits": 0,
		"daily_credits": 0,
		"weekly_credits": 0,
		"circuit_credits": 0,
		"workshop_credit_spend": 0,
		"transport_credit_spend": 0,
		"workshop_actions": 0,
		"circuit_completions": 0,
		"black_warrants": 0,
		"free_warp_chips": 0,
		"premium_warp_chip_spend": 0,
		"rift_first_service_total": 0,
		"minimum_service_ratio": INF,
		"maximum_service_ratio": 0.0,
	}
	var active_week := -1
	var black_warrant_completed := false
	for day in 36:
		var reality_index := day / 12
		var stage_index := day % 12
		advance_to_level(player, projected_level(reality_index, stage_index))
		player.seen_planet_ids = MissionRules.available_planets(int(player.level)).map(func(planet): return str(planet.id))
		var week := day / 7
		if week != active_week:
			active_week = week
			player.weekly_cycle_id = week
			player.weekly_hunts_completed = 0
			player.claimed_weekly_objectives = []
			player.weekly_route_planet_ids = WeeklyRules.rotating_planet_ids(player, week)
			player.weekly_route_captures = {}
			player.weekly_route_claimed = false
			black_warrant_completed = false
		var stage := Challenge.stage_at(stage_index, str(Challenge.REALITIES[reality_index].id))
		apply_rift_clear(player, stage, rng, result)
		buy_available_transports(player, result)
		spend_one_workshop_action(player, result)
		var fuel := int(profile.daily_fuel)
		result.premium_warp_chip_spend += premium_refill_cost(int(profile.premium_refills))
		var day_hunts := 0
		if not black_warrant_completed:
			var target_id := WeeklyRules.rotating_target_id(player, week)
			var special := WeeklyRules.special_contract(player, target_id, week)
			var special_cost := MonetizationRules.mission_fuel_cost(special)
			if not special.is_empty() and special_cost <= fuel:
				fuel -= special_cost
				apply_contract(player, special, rng, result)
				day_hunts += 1
				result.black_warrants += 1
				black_warrant_completed = true
		while fuel > 0:
			var offer := choose_offer(player, fuel, bool(profile.prefer_cheapest))
			if offer.is_empty():
				break
			fuel -= MonetizationRules.mission_fuel_cost(offer)
			apply_contract(player, offer, rng, result)
			day_hunts += 1
			if day_hunts >= 40:
				break
		if day_hunts > 0:
			result.free_warp_chips += 1
		apply_daily_payments(player, day_hunts, result)
		apply_weekly_payments(player, result)
		buy_available_transports(player, result)
	var gross_credits := int(result.rift_credits) + int(result.mission_credits) + int(result.daily_credits) + int(result.weekly_credits) + int(result.circuit_credits)
	result["gross_credits"] = gross_credits
	result["final_credits"] = int(player.credits)
	result["final_scrap"] = int(player.scrap)
	result["final_level"] = int(player.level)
	result["transports"] = player.get("owned_transport_ids", []).size()
	result["rift_credit_share"] = float(result.rift_credits) / float(maxi(1, gross_credits))
	result["purchased_chip_shortfall"] = maxi(0, int(result.premium_warp_chip_spend) - int(result.free_warp_chips))
	return result


static func projected_level(reality_index: int, stage_index: int) -> int:
	if reality_index == 0:
		return FIRST_REALITY_LEVELS[stage_index]
	return (100 if reality_index == 1 else 160) + stage_index * 5


static func advance_to_level(player: Dictionary, level: int) -> void:
	if int(player.get("level", 1)) >= level:
		return
	var gained := level - int(player.get("level", 1))
	player.level = level
	player.base_power = 10 + (level - 1) * 2
	player.stat_points = int(player.get("stat_points", 0)) + gained * CoreRules.ATTRIBUTE_POINTS_PER_LEVEL
	player.xp = 0


static func apply_rift_clear(player: Dictionary, stage: Dictionary, rng: RandomNumberGenerator, result: Dictionary) -> void:
	var credits := int(stage.credits)
	player.credits = int(player.credits) + credits
	result.rift_credits += credits
	CoreRules.apply_xp(player, int(stage.xp))
	var reward := Challenge.reward_for(stage, Content.ITEM_TRAITS)
	apply_loot(player, reward)
	if stage.has("reward_level"):
		var service := CoreRules.equipment_upgrade_credit_cost(reward)
		var ratio := float(credits) / float(maxi(1, service))
		result.rift_first_service_total += service
		result.minimum_service_ratio = minf(float(result.minimum_service_ratio), ratio)
		result.maximum_service_ratio = maxf(float(result.maximum_service_ratio), ratio)


static func apply_contract(player: Dictionary, contract: Dictionary, rng: RandomNumberGenerator, result: Dictionary) -> void:
	var payout := CoreRules.bounty_streak_reward(int(contract.credits), int(player.capture_streak) + 1)
	player.credits = int(player.credits) + int(payout.credits)
	result.mission_credits += int(payout.credits)
	player.capture_streak = int(player.capture_streak) + 1
	CoreRules.apply_xp(player, int(contract.xp))
	var target_id := str(contract.id)
	var captures: Dictionary = player.get("captures_by_target", {})
	var previous := int(captures.get(target_id, 0))
	var previous_mastery := CoreRules.target_mastery_level(previous)
	var loot := Content.generate_loot(contract, rng, previous_mastery)
	captures[target_id] = previous + 1
	player.captures_by_target = captures
	var mastery := CoreRules.target_mastery_level(previous + 1)
	if mastery > previous_mastery:
		player.scrap = int(player.scrap) + CoreRules.target_mastery_scrap_reward(mastery)
	player.scrap = int(player.scrap) + maxi(0, int(contract.get("scrap_reward", 0)))
	apply_loot(player, loot)
	player.wins = int(player.wins) + 1
	player.weekly_hunts_completed = int(player.get("weekly_hunts_completed", 0)) + 1
	WeeklyRules.record_route_capture(player, str(contract.planet_id))
	result.hunts += 1
	spend_one_workshop_action(player, result)


static func apply_loot(player: Dictionary, item: Dictionary) -> void:
	if item.is_empty():
		return
	if CoreRules.is_upgrade_for_player(player, item):
		player[str(item.slot)] = item.duplicate(true)
	else:
		player.scrap = int(player.scrap) + CoreRules.salvage_value(item)


static func choose_offer(player: Dictionary, fuel: int, prefer_cheapest: bool) -> Dictionary:
	var affordable := MissionRules.board_offers(player).filter(func(offer): return MonetizationRules.mission_fuel_cost(offer) <= fuel)
	if affordable.is_empty():
		return {}
	var captures: Dictionary = player.get("weekly_route_captures", {})
	var route_ids: Array = player.get("weekly_route_planet_ids", [])
	var route_offers := affordable.filter(func(offer): return route_ids.has(str(offer.planet_id)) and int(captures.get(str(offer.planet_id), 0)) < WeeklyRules.ROUTE_PLANET_QUOTA)
	if not route_offers.is_empty():
		route_offers.sort_custom(func(a: Dictionary, b: Dictionary): return MonetizationRules.mission_fuel_cost(a) < MonetizationRules.mission_fuel_cost(b))
		return route_offers[0]
	if prefer_cheapest:
		affordable.sort_custom(func(a: Dictionary, b: Dictionary): return MonetizationRules.mission_fuel_cost(a) < MonetizationRules.mission_fuel_cost(b))
		return affordable[0]
	for offer in affordable:
		if str(offer.mission_role) == "standard":
			return offer
	return affordable[0]


static func apply_daily_payments(player: Dictionary, hunts: int, result: Dictionary) -> void:
	for objective in DailyRules.objectives({"daily_hunts_completed": hunts, "claimed_daily_objectives": []}):
		if not bool(objective.complete):
			continue
		player.credits = int(player.credits) + int(objective.credits)
		player.scrap = int(player.scrap) + int(objective.scrap)
		result.daily_credits += int(objective.credits)


static func apply_weekly_payments(player: Dictionary, result: Dictionary) -> void:
	var claimed: Array = player.get("claimed_weekly_objectives", []).duplicate()
	for objective in WeeklyRules.rewards_ready(player):
		claimed.append(str(objective.id))
		player.credits = int(player.credits) + int(objective.credits)
		player.scrap = int(player.scrap) + int(objective.scrap)
		result.weekly_credits += int(objective.credits)
	player.claimed_weekly_objectives = claimed
	if WeeklyRules.route_reward_ready(player):
		player.weekly_route_claimed = true
		player.credits = int(player.credits) + WeeklyRules.ROUTE_REWARD_CREDITS
		player.scrap = int(player.scrap) + WeeklyRules.ROUTE_REWARD_SCRAP
		result.circuit_credits += WeeklyRules.ROUTE_REWARD_CREDITS
		result.circuit_completions += 1


static func spend_one_workshop_action(player: Dictionary, result: Dictionary) -> bool:
	var best: Dictionary = {}
	var best_value := -1.0
	for slot in CoreRules.EQUIPMENT_SLOTS:
		var item: Dictionary = player.get(slot, {})
		if item.is_empty():
			continue
		var actions := [{"kind": "power", "scrap": CoreRules.equipment_upgrade_cost(item), "credits": CoreRules.equipment_upgrade_credit_cost(item)}]
		if CoreRules.can_upgrade_integrity(item):
			actions.append({"kind": "integrity", "scrap": CoreRules.equipment_integrity_upgrade_cost(item), "credits": CoreRules.equipment_integrity_credit_cost(item)})
		for action in actions:
			if int(action.scrap) > int(player.scrap) or int(action.credits) > int(player.credits):
				continue
			var value := 1.0 / (float(action.scrap) + float(action.credits) / 100.0)
			if value > best_value:
				best_value = value
				best = {"slot": slot, "kind": str(action.kind), "scrap": int(action.scrap), "credits": int(action.credits)}
	if best.is_empty():
		return false
	player.scrap = int(player.scrap) - int(best.scrap)
	player.credits = int(player.credits) - int(best.credits)
	var item: Dictionary = player[str(best.slot)].duplicate(true)
	if str(best.kind) == "power":
		item.power = int(item.power) + 1
		item.power_upgrades = int(item.get("power_upgrades", 0)) + 1
	else:
		item.integrity_upgrades = int(item.get("integrity_upgrades", 0)) + 1
	player[str(best.slot)] = item
	result.workshop_credit_spend += int(best.credits)
	result.workshop_actions += 1
	return true


static func buy_available_transports(player: Dictionary, result: Dictionary) -> void:
	for definition in TransportRules.DEFINITIONS:
		var transport_id := str(definition.id)
		if TransportRules.is_owned(player, transport_id) or int(player.level) < int(definition.required_level) or int(player.credits) < int(definition.price):
			continue
		player.credits = int(player.credits) - int(definition.price)
		player.owned_transport_ids.append(transport_id)
		player.active_transport_id = transport_id
		result.transport_credit_spend += int(definition.price)


static func premium_refill_cost(count: int) -> int:
	var total := 0
	for index in clampi(count, 0, MonetizationRules.HUNT_FUEL_REFILL_COSTS.size()):
		total += int(MonetizationRules.HUNT_FUEL_REFILL_COSTS[index])
	return total
