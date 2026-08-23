class_name CoreRules
extends RefCounted


static func player_power(player: Dictionary) -> int:
	var weapon_power := int(player.get("weapon", {}).get("power", 0))
	var armor_power := int(player.get("armor", {}).get("power", 0))
	return int(player.get("base_power", 10)) + weapon_power + armor_power


static func max_health(player: Dictionary) -> int:
	return 72 + int(player.get("level", 1)) * 8 + int(player.get("armor", {}).get("power", 0)) * 3


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
	var player_damage := maxf(1.0, float(player_power(player)) - float(target.get("defense", 0)) * 0.45)
	var enemy_defense := int(player.get("armor", {}).get("power", 0)) + 3
	var enemy_damage := maxf(1.0, float(target.get("power", 1)) - float(enemy_defense) * 0.45)
	var turns_to_win := ceilf(float(target.get("health", 1)) / player_damage)
	var turns_to_lose := ceilf(float(max_health(player)) / enemy_damage)
	# The player attacks first, so an even race slightly favors the hunter.
	var race_advantage := (turns_to_lose - turns_to_win) * 1.35 + 0.35
	var estimate := 1.0 / (1.0 + exp(-race_advantage))
	return clampf(estimate, 0.01, 0.99)


static func is_upgrade(item: Dictionary, equipped: Dictionary) -> bool:
	return int(item.get("power", 0)) > int(equipped.get("power", 0))


static func salvage_value(item: Dictionary) -> int:
	var multiplier := 1
	match str(item.get("rarity", "Comum")):
		"Raro":
			multiplier = 2
		"Épico":
			multiplier = 4
	return maxi(1, ceili(float(int(item.get("power", 1)) * multiplier) / 3.0))


static func equipment_upgrade_cost(item: Dictionary) -> int:
	return maxi(4, 3 + ceili(float(int(item.get("power", 1))) * 0.8))


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
