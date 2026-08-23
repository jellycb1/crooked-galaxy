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


static func bounty_odds(player_power_value: int, target_power: int) -> float:
	var ratio := float(player_power_value) / maxf(1.0, float(target_power))
	return clampf(0.5 + (ratio - 1.0) * 0.72, 0.12, 0.96)


static func is_upgrade(item: Dictionary, equipped: Dictionary) -> bool:
	return int(item.get("power", 0)) > int(equipped.get("power", 0))

