class_name CoreRules
extends RefCounted


static func player_power(player: Dictionary) -> int:
	var weapon_power := item_combat_power(player.get("weapon", {}))
	var armor_power := item_combat_power(player.get("armor", {}))
	return int(player.get("base_power", 10)) + weapon_power + armor_power


static func max_health(player: Dictionary) -> int:
	var weapon: Dictionary = player.get("weapon", {})
	var armor: Dictionary = player.get("armor", {})
	return 72 + int(player.get("level", 1)) * 8 + int(armor.get("power", 0)) * 3 + item_health_bonus(weapon) + item_health_bonus(armor)


static func item_combat_power(item: Dictionary) -> int:
	return int(item.get("power", 0)) + int(item.get("trait", {}).get("power_bonus", 0))


static func item_health_bonus(item: Dictionary) -> int:
	return int(item.get("trait", {}).get("health_bonus", 0))


static func equipment_score(item: Dictionary) -> int:
	return item_combat_power(item) * 6 + item_health_bonus(item)


static func damage_roll(power: int, defense: int, roll: float) -> int:
	var variance := lerpf(0.82, 1.18, clampf(roll, 0.0, 1.0))
	return maxi(1, roundi(float(power) * variance - float(defense) * 0.45))


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
	var hunter_power := player_power(player)
	var hunter_health := max_health(player)
	var hunter_defense := int(player.get("armor", {}).get("power", 0)) + 3
	var target_power := int(target.get("power", 1))
	var target_defense := int(target.get("defense", 0))
	var target_health := int(target.get("health", 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = hunter_power * 92821 + hunter_health * 68917 + hunter_defense * 31337 + target_power * 7919 + target_defense * 1543 + target_health * 421
	var wins := 0
	for _trial in TRIALS:
		var player_hp := hunter_health
		var enemy_hp := target_health
		var rounds := 0
		while player_hp > 0 and enemy_hp > 0 and rounds < 100:
			rounds += 1
			enemy_hp -= damage_roll(hunter_power, target_defense, rng.randf())
			if enemy_hp <= 0:
				wins += 1
				break
			player_hp -= damage_roll(target_power, hunter_defense, rng.randf())
	return clampf(float(wins) / float(TRIALS), 0.01, 0.99)


static func is_upgrade(item: Dictionary, equipped: Dictionary) -> bool:
	return equipment_score(item) > equipment_score(equipped)


static func salvage_value(item: Dictionary) -> int:
	var multiplier := 1
	match str(item.get("rarity", "Comum")):
		"Raro":
			multiplier = 2
		"Épico":
			multiplier = 4
	var trait_bonus := 2 if item.has("trait") else 0
	return maxi(1, ceili(float(int(item.get("power", 1)) * multiplier) / 3.0) + trait_bonus)


static func equipment_upgrade_cost(item: Dictionary) -> int:
	return maxi(4, 3 + ceili(float(int(item.get("power", 1))) * 0.8))


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
