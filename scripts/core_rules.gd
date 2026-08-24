class_name CoreRules
extends RefCounted

const INTEGRITY_HEALTH_PER_LEVEL := 8
const MAX_INTEGRITY_UPGRADES := 5
const PLANETARY_KIT_POWER_BONUS := 1
const PLANETARY_KIT_HEALTH_BONUS := 6
const BOUNTY_ODDS_CACHE_LIMIT := 512

static var bounty_odds_cache: Dictionary = {}


static func player_power(player: Dictionary) -> int:
	var weapon_power := item_combat_power(player.get("weapon", {}))
	var armor_power := item_combat_power(player.get("armor", {}))
	return int(player.get("base_power", 10)) + weapon_power + armor_power + equipment_set_bonus_power(player)


static func max_health(player: Dictionary) -> int:
	var weapon: Dictionary = player.get("weapon", {})
	var armor: Dictionary = player.get("armor", {})
	return 72 + int(player.get("level", 1)) * 8 + int(armor.get("power", 0)) * 3 + item_health_bonus(weapon) + item_health_bonus(armor) + equipment_set_bonus_health(player)


static func item_combat_power(item: Dictionary) -> int:
	return int(item.get("power", 0)) + int(item.get("trait", {}).get("power_bonus", 0))


static func item_health_bonus(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("health_bonus", 0)) + int(item.get("integrity_upgrades", 0)) * INTEGRITY_HEALTH_PER_LEVEL


static func item_opening_damage(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("opening_damage_bonus", 0))


static func item_damage_reduction(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("damage_reduction", 0))


static func player_opening_damage(player: Dictionary) -> int:
	return item_opening_damage(player.get("weapon", {})) + item_opening_damage(player.get("armor", {}))


static func player_damage_reduction(player: Dictionary) -> int:
	return item_damage_reduction(player.get("weapon", {})) + item_damage_reduction(player.get("armor", {}))


static func equipment_set_origin(player: Dictionary) -> String:
	var weapon_origin := str(player.get("weapon", {}).get("origin_planet_id", ""))
	var armor_origin := str(player.get("armor", {}).get("origin_planet_id", ""))
	return weapon_origin if not weapon_origin.is_empty() and weapon_origin == armor_origin else ""


static func equipment_set_bonus_power(player: Dictionary) -> int:
	return PLANETARY_KIT_POWER_BONUS if not equipment_set_origin(player).is_empty() else 0


static func equipment_set_bonus_health(player: Dictionary) -> int:
	return PLANETARY_KIT_HEALTH_BONUS if not equipment_set_origin(player).is_empty() else 0


static func equipment_score(item: Dictionary) -> int:
	return item_combat_power(item) * 6 + item_health_bonus(item) + item_opening_damage(item) * 2 + item_damage_reduction(item) * 10


static func player_build_score(player: Dictionary) -> int:
	return player_power(player) * 6 + max_health(player) + player_opening_damage(player) * 2 + player_damage_reduction(player) * 10


static func damage_roll(power: int, defense: int, roll: float) -> int:
	var variance := lerpf(0.82, 1.18, clampf(roll, 0.0, 1.0))
	return maxi(1, roundi(float(power) * variance - float(defense) * 0.45))


static func player_attack_damage(player: Dictionary, target_defense: int, roll: float, round_number: int) -> int:
	var damage := damage_roll(player_power(player), target_defense, roll)
	if round_number == 1:
		damage += player_opening_damage(player)
	return damage


static func enemy_attack_damage(player: Dictionary, target_power: int, roll: float) -> int:
	return int(enemy_attack_breakdown(player, target_power, roll).damage)


static func enemy_attack_breakdown(player: Dictionary, target_power: int, roll: float) -> Dictionary:
	var defense := int(player.get("armor", {}).get("power", 0)) + 3
	var raw_damage := damage_roll(target_power, defense, roll)
	var damage := maxi(1, raw_damage - player_damage_reduction(player))
	return {
		"raw_damage": raw_damage,
		"damage": damage,
		"prevented": raw_damage - damage,
	}


static func xp_needed(level: int) -> int:
	return 80 + maxi(0, level - 1) * 45


static func apply_xp(player: Dictionary, amount: int) -> int:
	player["xp"] = int(player.get("xp", 0)) + maxi(0, amount)
	var levels_gained := 0
	while int(player["xp"]) >= xp_needed(int(player["level"])):
		player["xp"] = int(player["xp"]) - xp_needed(int(player["level"]))
		player["level"] = int(player["level"]) + 1
		player["base_power"] = int(player["base_power"]) + 2
		levels_gained += 1
	return levels_gained


static func bounty_odds(player: Dictionary, target: Dictionary) -> float:
	# A short seeded simulation follows the actual alternating combat rules. It is
	# deterministic for identical stats, so UI percentages never flicker.
	const TRIALS := 1024
	var hunter_health := max_health(player)
	var hunter_power := player_power(player)
	var armor_power := int(player.get("armor", {}).get("power", 0))
	var opening_damage := player_opening_damage(player)
	var damage_reduction := player_damage_reduction(player)
	var target_power := int(target.get("power", 1))
	var target_defense := int(target.get("defense", 0))
	var target_health := int(target.get("health", 1))
	var cache_key := "%d:%d:%d:%d:%d:%d:%d:%d" % [hunter_health, hunter_power, armor_power, opening_damage, damage_reduction, target_power, target_defense, target_health]
	if bounty_odds_cache.has(cache_key):
		return float(bounty_odds_cache[cache_key])
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
			enemy_hp -= player_attack_damage(player, target_defense, rng.randf(), rounds)
			if enemy_hp <= 0:
				wins += 1
				break
			player_hp -= enemy_attack_damage(player, target_power, rng.randf())
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
	if slot != "weapon" and slot != "armor":
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
	var trait_bonus := 2 if item.has("trait") else 0
	var calibration_recovery := int(item.get("power_upgrades", 0)) * 2
	var integrity_level := int(item.get("integrity_upgrades", 0))
	var integrity_recovery := integrity_level * (integrity_level + 2)
	return maxi(1, ceili(float(int(item.get("power", 1)) * multiplier) / 3.0) + trait_bonus + calibration_recovery + integrity_recovery)


static func has_workshop_investment(item: Dictionary) -> bool:
	return int(item.get("power_upgrades", 0)) > 0 or int(item.get("integrity_upgrades", 0)) > 0


static func equipment_upgrade_cost(item: Dictionary) -> int:
	return maxi(4, 3 + ceili(float(int(item.get("power", 1))) * 0.8))


static func equipment_integrity_upgrade_cost(item: Dictionary) -> int:
	var level := int(item.get("integrity_upgrades", 0))
	return maxi(6, 5 + level * 4 + ceili(float(int(item.get("power", 1))) * 0.45))


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


static func safe_content_margins(viewport_size: Vector2, screen_size: Vector2, safe_rect: Rect2, base := Vector4(30.0, 28.0, 30.0, 24.0)) -> Vector4:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return base
	var scale_x := viewport_size.x / screen_size.x
	var scale_y := viewport_size.y / screen_size.y
	var left_inset := maxf(0.0, safe_rect.position.x) * scale_x
	var top_inset := maxf(0.0, safe_rect.position.y) * scale_y
	var right_inset := maxf(0.0, screen_size.x - safe_rect.end.x) * scale_x
	var bottom_inset := maxf(0.0, screen_size.y - safe_rect.end.y) * scale_y
	return Vector4(maxf(base.x, left_inset), maxf(base.y, top_inset), maxf(base.z, right_inset), maxf(base.w, bottom_inset))
