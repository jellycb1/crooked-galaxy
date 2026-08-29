class_name CoreRules
extends RefCounted

const ClassRulesScript = preload("res://scripts/class_rules.gd")
const EnemyProfileRulesScript = preload("res://scripts/enemy_profile_rules.gd")
const AttributePackageRulesScript = preload("res://scripts/attribute_package_rules.gd")

const INTEGRITY_HEALTH_PER_LEVEL := 8
const MAX_INTEGRITY_UPGRADES := 5
const PLANETARY_KIT_POWER_BONUS := 1
const PLANETARY_KIT_HEALTH_BONUS := 6
const BOUNTY_ODDS_CACHE_LIMIT := 512
const BASE_ATTRIBUTE_VALUE := 10
const ATTRIBUTE_POINTS_PER_LEVEL := 2
const XP_QUADRATIC_NUMERATOR := 4
const XP_QUADRATIC_DENOMINATOR := 5
const ATTRIBUTE_KEYS := ["strength", "vitality", "dexterity", "intelligence", "cunning"]
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]
const EQUIPMENT_SLOT_NAMES := {
	"weapon": "Arma",
	"helmet": "Capacete",
	"armor": "Traje",
	"gloves": "Luvas",
	"boots": "Botas",
	"rig": "Cinto técnico",
	"implant": "Implante",
	"gadget": "Gadget",
	"relic": "Relíquia",
}

static var bounty_odds_cache: Dictionary = {}


static func player_power(player: Dictionary) -> int:
	var equipment_power := 0
	for slot in EQUIPMENT_SLOTS:
		equipment_power += item_combat_power(player.get(slot, {}))
	return int(player.get("base_power", 10)) + equipment_power + equipment_set_bonus_power(player) + floori(float(attribute_investment(player, "strength")) / 2.0) + ClassRulesScript.specialization_power(player, BASE_ATTRIBUTE_VALUE)


static func max_health(player: Dictionary) -> int:
	var armor: Dictionary = player.get("armor", {})
	var equipment_health := 0
	for slot in EQUIPMENT_SLOTS:
		equipment_health += item_health_bonus(player.get(slot, {}))
	return 72 + int(player.get("level", 1)) * 8 + int(armor.get("power", 0)) * 3 + equipment_health + equipment_set_bonus_health(player) + attribute_investment(player, "vitality") * 4


static func default_attributes() -> Dictionary:
	return {
		"strength": BASE_ATTRIBUTE_VALUE,
		"vitality": BASE_ATTRIBUTE_VALUE,
		"dexterity": BASE_ATTRIBUTE_VALUE,
		"intelligence": BASE_ATTRIBUTE_VALUE,
		"cunning": BASE_ATTRIBUTE_VALUE,
	}


static func attribute_value(player: Dictionary, attribute_id: String) -> int:
	return int(player.get("attributes", {}).get(attribute_id, BASE_ATTRIBUTE_VALUE)) + AttributePackageRulesScript.attribute_bonus(player, attribute_id)


static func attribute_investment(player: Dictionary, attribute_id: String) -> int:
	return maxi(0, attribute_value(player, attribute_id) - BASE_ATTRIBUTE_VALUE)


static func cunning_roll_bonus(player: Dictionary) -> float:
	return minf(0.15, float(attribute_investment(player, "cunning")) * 0.005)


static func player_attack_roll(player: Dictionary, roll: float, bonus_multiplier := 1.0) -> float:
	var class_bonus := ClassRulesScript.specialization_attack_roll_bonus(player, BASE_ATTRIBUTE_VALUE)
	return clampf(roll + cunning_roll_bonus(player) + class_bonus * maxf(0.0, float(bonus_multiplier)), 0.0, 1.0)


static func item_combat_power(item: Dictionary) -> int:
	return int(item.get("power", 0)) + int(item.get("trait", {}).get("power_bonus", 0))


static func item_health_bonus(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("health_bonus", 0)) + int(item.get("integrity_upgrades", 0)) * INTEGRITY_HEALTH_PER_LEVEL


static func item_opening_damage(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("opening_damage_bonus", 0))


static func item_damage_reduction(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("damage_reduction", 0))


static func equipment_trait_total(player: Dictionary, key: String) -> float:
	var total := 0.0
	for slot in EQUIPMENT_SLOTS:
		total += float(player.get(slot, {}).get("trait", {}).get(key, 0.0))
	return total


static func player_evasion_chance(player: Dictionary) -> float:
	return minf(0.20, ClassRulesScript.specialization_evasion_chance(player, BASE_ATTRIBUTE_VALUE) + equipment_trait_total(player, "evasion_chance_bonus"))


static func player_defense_bypass(player: Dictionary) -> int:
	return ClassRulesScript.specialization_defense_bypass(player, BASE_ATTRIBUTE_VALUE) + roundi(equipment_trait_total(player, "defense_bypass_bonus"))


static func player_counter_damage(player: Dictionary, round_number: int) -> int:
	var damage := ClassRulesScript.specialization_counter_damage(player, BASE_ATTRIBUTE_VALUE, round_number)
	var equipment_damage := roundi(equipment_trait_total(player, "counter_damage_bonus"))
	var equipment_cadence := roundi(equipment_trait_total(player, "counter_every_rounds"))
	if equipment_damage > 0 and equipment_cadence > 0 and round_number > 0 and round_number % equipment_cadence == 0:
		damage += equipment_damage
	return damage


static func player_follow_up_damage(player: Dictionary, adjusted_roll: float, base_damage: int) -> int:
	var damage := ClassRulesScript.specialization_follow_up_damage(player, adjusted_roll, base_damage)
	var equipment_ratio := equipment_trait_total(player, "follow_up_damage_ratio")
	var equipment_threshold := equipment_trait_total(player, "follow_up_roll_threshold")
	if equipment_ratio > 0.0 and equipment_threshold > 0.0 and adjusted_roll >= equipment_threshold:
		damage += maxi(1, roundi(float(base_damage) * equipment_ratio))
	return damage


static func player_opening_damage(player: Dictionary) -> int:
	var equipment_bonus := 0
	for slot in EQUIPMENT_SLOTS:
		equipment_bonus += item_opening_damage(player.get(slot, {}))
	return equipment_bonus + floori(float(attribute_investment(player, "intelligence")) / 2.0) + ClassRulesScript.specialization_opening_damage(player, BASE_ATTRIBUTE_VALUE)


static func player_damage_reduction(player: Dictionary) -> int:
	var equipment_bonus := 0
	for slot in EQUIPMENT_SLOTS:
		equipment_bonus += item_damage_reduction(player.get(slot, {}))
	return equipment_bonus + floori(float(attribute_investment(player, "dexterity")) / 3.0) + ClassRulesScript.specialization_damage_reduction(player, BASE_ATTRIBUTE_VALUE)


static func is_equipment_slot(slot: String) -> bool:
	return EQUIPMENT_SLOTS.has(slot)


static func equipment_slot_name(slot: String) -> String:
	return str(EQUIPMENT_SLOT_NAMES.get(slot, "Equipamento"))


static func equipped_item_count(player: Dictionary) -> int:
	var count := 0
	for slot in EQUIPMENT_SLOTS:
		if not player.get(slot, {}).is_empty():
			count += 1
	return count


static func equipment_set_origin(player: Dictionary) -> String:
	var weapon_origin := str(player.get("weapon", {}).get("origin_planet_id", ""))
	var armor_origin := str(player.get("armor", {}).get("origin_planet_id", ""))
	return weapon_origin if not weapon_origin.is_empty() and weapon_origin == armor_origin else ""


static func equipment_set_bonus_power(player: Dictionary) -> int:
	return PLANETARY_KIT_POWER_BONUS if not equipment_set_origin(player).is_empty() else 0


static func equipment_set_bonus_health(player: Dictionary) -> int:
	return PLANETARY_KIT_HEALTH_BONUS if not equipment_set_origin(player).is_empty() else 0


static func equipment_score(item: Dictionary) -> int:
	var trait_data: Dictionary = item.get("trait", {})
	var tactical := int(trait_data.get("counter_damage_bonus", 0)) * 8 + roundi(float(trait_data.get("evasion_chance_bonus", 0.0)) * 500.0) + int(trait_data.get("defense_bypass_bonus", 0)) * 6 + roundi(float(trait_data.get("follow_up_damage_ratio", 0.0)) * 40.0)
	return item_combat_power(item) * 6 + item_health_bonus(item) + item_opening_damage(item) * 2 + item_damage_reduction(item) * 10 + tactical + AttributePackageRulesScript.item_score(item)


static func has_intrinsic_modifier(item: Dictionary) -> bool:
	return item.has("trait") or item.has("attribute_package_id")


static func player_build_score(player: Dictionary) -> int:
	var attack_accuracy := cunning_roll_bonus(player) + ClassRulesScript.specialization_attack_roll_bonus(player, BASE_ATTRIBUTE_VALUE)
	return player_power(player) * 6 + max_health(player) + player_opening_damage(player) * 2 + player_damage_reduction(player) * 10 + player_counter_damage(player, 12) * 8 + roundi(player_evasion_chance(player) * 500.0) + player_defense_bypass(player) * 6 + roundi(equipment_trait_total(player, "follow_up_damage_ratio") * 40.0) + roundi(attack_accuracy * 500.0)


static func damage_roll(power: int, defense: int, roll: float) -> int:
	var variance := lerpf(0.82, 1.18, clampf(roll, 0.0, 1.0))
	return maxi(1, roundi(float(power) * variance - float(defense) * 0.45))


static func player_attack_damage(player: Dictionary, target_defense: int, roll: float, round_number: int, opening_damage_multiplier := 1.0, attack_roll_bonus_multiplier := 1.0, defense_bypass_multiplier := 1.0) -> int:
	var bypass := roundi(float(ClassRulesScript.specialization_defense_bypass(player, BASE_ATTRIBUTE_VALUE)) * maxf(0.0, defense_bypass_multiplier))
	var effective_defense := maxi(0, target_defense - bypass)
	var damage := damage_roll(player_power(player), effective_defense, player_attack_roll(player, roll, attack_roll_bonus_multiplier))
	if round_number == 1:
		damage += roundi(float(player_opening_damage(player)) * maxf(0.0, float(opening_damage_multiplier)))
	return damage


static func enemy_attack_damage(player: Dictionary, target_power: int, roll: float, damage_reduction_piercing := 0.0) -> int:
	return int(enemy_attack_breakdown(player, target_power, roll, damage_reduction_piercing).damage)


static func enemy_attack_breakdown(player: Dictionary, target_power: int, roll: float, damage_reduction_piercing := 0.0) -> Dictionary:
	var defense := int(player.get("armor", {}).get("power", 0)) + 3
	var raw_damage := damage_roll(target_power, defense, roll)
	if roll < player_evasion_chance(player):
		return {"raw_damage": raw_damage, "damage": 0, "prevented": raw_damage, "base_reduction": player_damage_reduction(player), "effective_reduction": 0, "dodged": true}
	var base_reduction := player_damage_reduction(player)
	var effective_reduction := roundi(float(base_reduction) * (1.0 - clampf(float(damage_reduction_piercing), 0.0, 1.0)))
	var damage := maxi(1, raw_damage - effective_reduction)
	return {
		"raw_damage": raw_damage,
		"damage": damage,
		"prevented": raw_damage - damage,
		"base_reduction": base_reduction,
		"effective_reduction": effective_reduction,
		"dodged": false,
	}


static func xp_needed(level: int) -> int:
	var offset := maxi(0, level - 1)
	var quadratic_numerator := XP_QUADRATIC_NUMERATOR * offset * offset
	var quadratic_xp := floori(float(quadratic_numerator) / float(XP_QUADRATIC_DENOMINATOR) + 0.5)
	return 80 + offset * 45 + quadratic_xp


static func apply_xp(player: Dictionary, amount: int) -> int:
	player["xp"] = int(player.get("xp", 0)) + maxi(0, amount)
	var levels_gained := 0
	while int(player["xp"]) >= xp_needed(int(player["level"])):
		player["xp"] = int(player["xp"]) - xp_needed(int(player["level"]))
		player["level"] = int(player["level"]) + 1
		player["base_power"] = int(player["base_power"]) + 2
		player["stat_points"] = int(player.get("stat_points", 0)) + ATTRIBUTE_POINTS_PER_LEVEL
		levels_gained += 1
	return levels_gained


static func bounty_odds(player: Dictionary, target: Dictionary) -> float:
	# A short seeded simulation follows the actual alternating combat rules. It is
	# deterministic for identical stats, so UI percentages never flicker.
	# 768 deterministic trials keep sub-percent display resolution while cutting
	# cold mobile field-test work by 25%. Common random streams still make build
	# comparisons stable, and career simulations guard the 55% recommendation gate.
	const TRIALS := 768
	var hunter_health := max_health(player)
	var hunter_power := player_power(player)
	var armor_power := int(player.get("armor", {}).get("power", 0))
	var opening_damage := player_opening_damage(player)
	var damage_reduction := player_damage_reduction(player)
	var cunning_bonus := cunning_roll_bonus(player)
	var class_attack_bonus := ClassRulesScript.specialization_attack_roll_bonus(player, BASE_ATTRIBUTE_VALUE)
	var attack_roll_bonus := roundi((cunning_bonus + class_attack_bonus) * 1000.0)
	var counter_damage := player_counter_damage(player, 12)
	var evasion_probability := player_evasion_chance(player)
	var evasion_chance := roundi(evasion_probability * 1000.0)
	var defense_bypass := player_defense_bypass(player)
	var follow_up_ratio := roundi(equipment_trait_total(player, "follow_up_damage_ratio") * 1000.0)
	var follow_up_threshold := roundi(equipment_trait_total(player, "follow_up_roll_threshold") * 1000.0)
	var target_power := int(target.get("power", 1))
	var target_defense := int(target.get("defense", 0))
	var target_health := int(target.get("health", 1))
	var damage_reduction_piercing := roundi(clampf(EnemyProfileRulesScript.modifier(target, "damage_reduction_piercing", 0.0), 0.0, 1.0) * 1000.0)
	var opening_damage_multiplier := roundi(maxf(0.0, EnemyProfileRulesScript.modifier(target, "opening_damage_multiplier", 1.0)) * 1000.0)
	var attack_roll_bonus_multiplier := roundi(maxf(0.0, EnemyProfileRulesScript.modifier(target, "attack_roll_bonus_multiplier", 1.0)) * 1000.0)
	var defense_bypass_multiplier := roundi(maxf(0.0, EnemyProfileRulesScript.modifier(target, "defense_bypass_multiplier", 1.0)) * 1000.0)
	var counter_damage_multiplier := roundi(maxf(0.0, EnemyProfileRulesScript.modifier(target, "counter_damage_multiplier", 1.0)) * 1000.0)
	var cache_key := "%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [hunter_health, hunter_power, armor_power, opening_damage, damage_reduction, attack_roll_bonus, counter_damage, evasion_chance, defense_bypass, follow_up_ratio, follow_up_threshold, target_power, target_defense, target_health, damage_reduction_piercing, opening_damage_multiplier, attack_roll_bonus_multiplier, defense_bypass_multiplier, counter_damage_multiplier]
	if bounty_odds_cache.has(cache_key):
		return float(bounty_odds_cache[cache_key])
	# Everything below is invariant for all trials except the two random rolls and
	# the round cadence. Precomputing it avoids repeating class lookups, attribute
	# dictionaries, and nine-slot equipment scans tens of thousands of times on a
	# single UI request. The simulation keeps the same seed, trials, and arithmetic.
	var attack_multiplier := float(attack_roll_bonus_multiplier) / 1000.0
	var effective_target_defense := maxi(0, target_defense - roundi(float(ClassRulesScript.specialization_defense_bypass(player, BASE_ATTRIBUTE_VALUE)) * float(defense_bypass_multiplier) / 1000.0))
	var effective_opening_damage := roundi(float(opening_damage) * float(opening_damage_multiplier) / 1000.0)
	var effective_damage_reduction := roundi(float(damage_reduction) * (1.0 - float(damage_reduction_piercing) / 1000.0))
	var enemy_defense := armor_power + 3
	var class_effects: Dictionary = ClassRulesScript.get_definition(str(player.get("class_id", ""))).get("effects", {})
	var class_follow_up_threshold := float(class_effects.get("follow_up_roll_threshold", 2.0))
	var class_follow_up_ratio := maxf(0.0, float(class_effects.get("follow_up_damage_ratio", 0.0)))
	var equipment_follow_up_ratio := float(follow_up_ratio) / 1000.0
	var equipment_follow_up_threshold := float(follow_up_threshold) / 1000.0
	var counter_damage_by_round: Array[int] = []
	counter_damage_by_round.resize(101)
	for round_number in range(1, 101):
		counter_damage_by_round[round_number] = player_counter_damage(player, round_number)
	var rng := RandomNumberGenerator.new()
	# Builds facing the same target share the exact roll stream. This common-random
	# comparison prevents a real upgrade from displaying lower odds due to sample noise.
	rng.seed = 90210 + target_power * 7919 + target_defense * 1543 + target_health * 421
	var wins := 0
	for _trial in TRIALS:
		var player_hp := hunter_health
		var enemy_hp := target_health
		var rounds := 0
		while player_hp > 0 and enemy_hp > 0 and rounds < 100:
			rounds += 1
			var player_roll := rng.randf()
			var adjusted_roll := clampf(player_roll + cunning_bonus + class_attack_bonus * attack_multiplier, 0.0, 1.0)
			var primary_damage := damage_roll(hunter_power, effective_target_defense, adjusted_roll)
			if rounds == 1:
				primary_damage += effective_opening_damage
			enemy_hp -= primary_damage
			if enemy_hp <= 0:
				wins += 1
				break
			var follow_up_damage := 0
			if adjusted_roll >= class_follow_up_threshold:
				follow_up_damage += maxi(1, roundi(float(primary_damage) * class_follow_up_ratio))
			if equipment_follow_up_ratio > 0.0 and equipment_follow_up_threshold > 0.0 and adjusted_roll >= equipment_follow_up_threshold:
				follow_up_damage += maxi(1, roundi(float(primary_damage) * equipment_follow_up_ratio))
			enemy_hp -= follow_up_damage
			if enemy_hp <= 0:
				wins += 1
				break
			var enemy_roll := rng.randf()
			if enemy_roll >= evasion_probability:
				player_hp -= maxi(1, damage_roll(target_power, enemy_defense, enemy_roll) - effective_damage_reduction)
			if player_hp > 0:
				enemy_hp -= roundi(float(counter_damage_by_round[rounds]) * float(counter_damage_multiplier) / 1000.0)
				if enemy_hp <= 0:
					wins += 1
					break
	var result := clampf(float(wins) / float(TRIALS), 0.01, 0.99)
	if bounty_odds_cache.size() >= BOUNTY_ODDS_CACHE_LIMIT:
		bounty_odds_cache.clear()
	bounty_odds_cache[cache_key] = result
	return result


static func clear_bounty_odds_cache() -> void:
	bounty_odds_cache.clear()


static func is_upgrade(item: Dictionary, equipped: Dictionary) -> bool:
	return equipment_score(item) > equipment_score(equipped)


static func is_upgrade_for_player(player: Dictionary, item: Dictionary) -> bool:
	var slot := str(item.get("slot", ""))
	if not is_equipment_slot(slot):
		return false
	var simulated := player.duplicate(true)
	simulated[slot] = item
	return player_build_score(simulated) > player_build_score(player)


static func salvage_value(item: Dictionary) -> int:
	var multiplier := 1
	match str(item.get("rarity", "Comum")):
		"Raro":
			multiplier = 2
		"Épico":
			multiplier = 4
	var trait_bonus := 2 if has_intrinsic_modifier(item) else 0
	var calibration_recovery := int(item.get("power_upgrades", 0)) * 2
	var integrity_level := int(item.get("integrity_upgrades", 0))
	var integrity_recovery := integrity_level * (integrity_level + 2)
	return maxi(1, ceili(float(int(item.get("power", 1)) * multiplier) / 3.0) + trait_bonus + calibration_recovery + integrity_recovery)


static func has_workshop_investment(item: Dictionary) -> bool:
	return int(item.get("power_upgrades", 0)) > 0 or int(item.get("integrity_upgrades", 0)) > 0


static func equipment_upgrade_cost(item: Dictionary) -> int:
	return maxi(4, 3 + ceili(float(int(item.get("power", 1))) * 0.8))


static func equipment_upgrade_credit_cost(item: Dictionary) -> int:
	var level := equipment_service_level(item)
	var base := maxi(60, 20 + level * level)
	return base + int(item.get("power_upgrades", 0)) * maxi(25, ceili(float(base) * 0.25))


static func equipment_integrity_upgrade_cost(item: Dictionary) -> int:
	var level := int(item.get("integrity_upgrades", 0))
	return maxi(6, 5 + level * 4 + ceili(float(int(item.get("power", 1))) * 0.45))


static func equipment_integrity_credit_cost(item: Dictionary) -> int:
	var item_level := equipment_service_level(item)
	var base := maxi(75, 30 + roundi(float(item_level * item_level) * 0.80))
	return base + int(item.get("integrity_upgrades", 0)) * maxi(30, ceili(float(base) * 0.30))


static func equipment_service_level(item: Dictionary) -> int:
	if item.has("item_level"):
		return clampi(int(item.get("item_level", 1)), 1, 1000000)
	return maxi(1, roundi(float(int(item.get("power", 1))) / 10.0))


static func can_upgrade_integrity(item: Dictionary) -> bool:
	return int(item.get("integrity_upgrades", 0)) < MAX_INTEGRITY_UPGRADES


static func target_mastery_level(captures: int) -> int:
	if captures >= 10:
		return 3
	if captures >= 6:
		return 2
	if captures >= 3:
		return 1
	return 0


static func target_mastery_next_requirement(level: int) -> int:
	match level:
		0:
			return 3
		1:
			return 6
		2:
			return 10
		_:
			return -1


static func target_mastery_scrap_reward(level: int) -> int:
	return 0 if level <= 0 else level * 4 + 2


static func loot_rarity_thresholds(mastery_level: int) -> Dictionary:
	var level := clampi(mastery_level, 0, 3)
	return {
		"rare": 0.68 - float(level) * 0.05,
		"epic": 0.92 - float(level) * 0.02,
	}


static func bounty_streak_reward(base_credits: int, streak: int) -> Dictionary:
	var bonus_percent := mini(25, maxi(0, streak - 1) * 5)
	var bonus := roundi(float(maxi(0, base_credits)) * float(bonus_percent) / 100.0)
	return {
		"base_credits": maxi(0, base_credits),
		"bonus_credits": bonus,
		"credits": maxi(0, base_credits) + bonus,
		"bonus_percent": bonus_percent,
		"streak": maxi(0, streak),
	}


static func offline_patrol_rewards(elapsed_seconds: float, completed_planets: int, wins: int) -> Dictionary:
	if wins <= 0 or elapsed_seconds < 300.0:
		return {"minutes": 0, "credits": 0, "scrap": 0, "capped": false}
	var capped_seconds := minf(elapsed_seconds, 8.0 * 60.0 * 60.0)
	var minutes := floori(capped_seconds / 60.0)
	var credit_rate := 1 + maxi(0, completed_planets)
	var scrap_rate := 1 + floori(float(maxi(0, completed_planets)) / 2.0)
	return {
		"minutes": minutes,
		"credits": minutes * credit_rate,
		"scrap": floori(float(minutes) / 30.0) * scrap_rate,
		"capped": elapsed_seconds > capped_seconds,
	}


static func safe_content_margins(viewport_size: Vector2, screen_size: Vector2, safe_rect: Rect2, base := Vector4(42.0, 28.0, 42.0, 24.0)) -> Vector4:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return base
	var scale_x := viewport_size.x / screen_size.x
	var scale_y := viewport_size.y / screen_size.y
	var left_inset := maxf(0.0, safe_rect.position.x) * scale_x
	var top_inset := maxf(0.0, safe_rect.position.y) * scale_y
	var right_inset := maxf(0.0, screen_size.x - safe_rect.end.x) * scale_x
	var bottom_inset := maxf(0.0, screen_size.y - safe_rect.end.y) * scale_y
	return Vector4(maxf(base.x, left_inset), maxf(base.y, top_inset), maxf(base.z, right_inset), maxf(base.w, bottom_inset))
