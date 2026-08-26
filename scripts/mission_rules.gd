class_name MissionRules
extends RefCounted

const Content = preload("res://scripts/content_db.gd")

const ROLES := [
	{"id": "safe", "pressure_mult": 0.94, "reward_mult": 0.90},
	{"id": "standard", "pressure_mult": 1.00, "reward_mult": 1.00},
	{"id": "dangerous", "pressure_mult": 1.12, "reward_mult": 1.15},
]


static func available_planets(level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for planet in Content.PLANETS:
		if level >= int(planet.get("unlock_level", 1)):
			result.append(planet.duplicate(true))
	return result


static func is_planet_available(planet_id: String, level: int) -> bool:
	return available_planets(level).any(func(planet): return str(planet.id) == planet_id)


static func board_offers(player: Dictionary, limit := 3) -> Array[Dictionary]:
	var planets := available_planets(int(player.get("level", 1)))
	if planets.is_empty() or limit <= 0:
		return []
	var cycle := maxi(0, int(player.get("wins", 0)))
	var result: Array[Dictionary] = []
	for offer_index in mini(limit, ROLES.size()):
		var planet: Dictionary = planets[(cycle + offer_index) % planets.size()]
		var templates := targets_for_planet(str(planet.id))
		if templates.is_empty():
			continue
		var template: Dictionary = templates[(cycle + offer_index + Content.planet_index_for(str(planet.id))) % templates.size()]
		result.append(scale_offer(template, planet, int(player.get("level", 1)), ROLES[offer_index], offer_index))
	return result


static func offer_for_target(player: Dictionary, target: Dictionary, role_id := "standard") -> Dictionary:
	var planet := Content.get_planet(str(target.get("planet_id", "")))
	if target.is_empty() or not is_planet_available(str(planet.get("id", "")), int(player.get("level", 1))):
		return {}
	for index in ROLES.size():
		if str(ROLES[index].id) == role_id:
			return scale_offer(target, planet, int(player.get("level", 1)), ROLES[index], index)
	return {}


static func targets_for_planet(planet_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in Content.TARGETS:
		if str(target.get("planet_id", Content.PLANET.id)) == planet_id:
			result.append(target.duplicate(true))
	return result


static func scale_offer(template: Dictionary, planet: Dictionary, player_level: int, role: Dictionary, offer_index: int) -> Dictionary:
	var mission_level := maxi(1, player_level)
	return scale_offer_level(template, planet, mission_level, role, offer_index)


static func scale_offer_level(template: Dictionary, planet: Dictionary, mission_level: int, role: Dictionary, offer_index: int) -> Dictionary:
	mission_level = clampi(mission_level, 1, 1000)
	var reward_mult := float(role.reward_mult)
	var pressure_mult := float(role.pressure_mult)
	var offer := template.duplicate(true)
	offer["mission_offer"] = true
	offer["mission_role"] = str(role.id)
	offer["mission_level"] = mission_level
	offer["offer_index"] = offer_index
	offer["elite_visual"] = bool(offer.get("boss", false))
	offer.erase("boss")
	# This curve is derived only from the snapshotted mission level. It never
	# reads equipment or current player power, so upgrades can improve real odds.
	offer["power"] = maxi(1, roundi((11.0 + (mission_level - 1) * 5.0) * pressure_mult))
	offer["defense"] = maxi(0, roundi((4.0 + (mission_level - 1) * 2.5) * pressure_mult))
	offer["health"] = maxi(1, roundi((70.0 + (mission_level - 1) * 35.0) * pressure_mult))
	offer["credits"] = maxi(1, roundi((32.0 + 1.35 * mission_level * mission_level) * reward_mult))
	offer["xp"] = maxi(1, roundi((36.0 + 7.0 * mission_level) * reward_mult))
	offer["loot_power"] = int(offer.power)
	offer["travel_duration"] = float(planet.get("travel_duration", 30.0))
	offer["pursuit_duration"] = 20.0 + minf(100.0, float(mission_level) * 4.0)
	offer["duration"] = ceili(float(offer.travel_duration) + float(offer.pursuit_duration))
	return offer


static func canonical_offer(loaded: Dictionary) -> Dictionary:
	if not bool(loaded.get("mission_offer", false)):
		return {}
	var template := Content.get_target(str(loaded.get("id", "")))
	var planet := Content.get_planet(str(loaded.get("planet_id", "")))
	var role: Dictionary = {}
	for candidate in ROLES:
		if str(candidate.id) == str(loaded.get("mission_role", "")):
			role = candidate
			break
	var mission_level = loaded.get("mission_level", 0)
	var offer_index = loaded.get("offer_index", -1)
	if template.is_empty() or str(template.get("planet_id", "")) != str(planet.get("id", "")) or role.is_empty():
		return {}
	if not (mission_level is int or mission_level is float) or int(mission_level) < 1 or int(mission_level) > 1000:
		return {}
	if not (offer_index is int or offer_index is float) or int(offer_index) < 0 or int(offer_index) >= ROLES.size():
		return {}
	if str(ROLES[int(offer_index)].id) != str(role.id):
		return {}
	return scale_offer_level(template, planet, int(mission_level), role, int(offer_index))
