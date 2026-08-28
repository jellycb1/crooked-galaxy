class_name MissionRules
extends RefCounted

const Content = preload("res://scripts/content_db.gd")

const ROLES := [
	{"id": "safe", "pressure_mult": 0.94, "reward_mult": 0.90},
	{"id": "standard", "pressure_mult": 1.00, "reward_mult": 1.00},
	{"id": "dangerous", "pressure_mult": 1.12, "reward_mult": 1.15},
]

# New hunters learn the loop with shorter journeys. The reduction depends only
# on the snapshotted mission level, so accepted contracts remain deterministic.
const EARLY_TRAVEL_BANDS := [
	{"minimum_level": 13, "multiplier": 1.00},
	{"minimum_level": 8, "multiplier": 0.80},
	{"minimum_level": 4, "multiplier": 0.60},
	{"minimum_level": 1, "multiplier": 0.40},
]


static func available_planets(level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for planet in Content.PLANETS:
		if level >= int(planet.get("unlock_level", 1)):
			result.append(planet.duplicate(true))
	return result


static func is_planet_available(planet_id: String, level: int) -> bool:
	return available_planets(level).any(func(planet): return str(planet.id) == planet_id)


static func newly_available_planets(before_level: int, after_level: int) -> Array[Dictionary]:
	var known_ids := {}
	for planet in available_planets(before_level):
		known_ids[str(planet.id)] = true
	var result: Array[Dictionary] = []
	for planet in available_planets(after_level):
		if not known_ids.has(str(planet.id)):
			result.append(planet.duplicate(true))
	return result


static func board_offers(player: Dictionary, limit := 3) -> Array[Dictionary]:
	var planets := available_planets(int(player.get("level", 1)))
	if planets.is_empty() or limit <= 0:
		return []
	var cycle := maxi(0, int(player.get("wins", 0)))
	var planet_order := _planet_rotation(planets, cycle)
	var used_target_ids := {}
	var result: Array[Dictionary] = []
	for offer_index in mini(limit, ROLES.size()):
		var planet: Dictionary = planet_order[offer_index % planet_order.size()]
		var templates := targets_for_planet(str(planet.id))
		if templates.is_empty():
			continue
		var template := _target_for_slot(templates, str(planet.id), cycle, offer_index, used_target_ids, planets.size())
		used_target_ids[str(template.id)] = true
		result.append(scale_offer(template, planet, int(player.get("level", 1)), ROLES[offer_index], offer_index))
	return result


static func _planet_rotation(planets: Array[Dictionary], cycle: int) -> Array[Dictionary]:
	# One epoch spans one pass through the complete unlocked pool. Within it,
	# every destination appears in exactly the same number of board slots. A
	# deterministic shuffle prevents the network from looking like a fixed list
	# while keeping identical saves and server snapshots reproducible.
	var epoch := cycle / planets.size()
	var offset := cycle % planets.size()
	var shuffled := _deterministic_shuffle(planets, _stable_seed("planets:%d:%d" % [planets.size(), epoch]))
	var result: Array[Dictionary] = []
	for index in planets.size():
		result.append(shuffled[(offset + index) % shuffled.size()])
	return result


static func _target_for_slot(templates: Array[Dictionary], planet_id: String, cycle: int, offer_index: int, used_ids: Dictionary, unlocked_planet_count: int) -> Dictionary:
	# Preserve the familiar opening sequence while varying the target whenever a
	# planet changes board position later in the network. Content order remains a
	# deliberate authoring tool; duplicate identities on two-world boards are
	# resolved by advancing within that planet's family.
	var stride := 1 if unlocked_planet_count == 1 else 2
	var cursor := (cycle * stride + offer_index + Content.planet_index_for(planet_id)) % templates.size()
	for step in templates.size():
		var candidate: Dictionary = templates[(cursor + step) % templates.size()]
		if not used_ids.has(str(candidate.id)):
			return candidate
	return templates[cursor]


static func _deterministic_shuffle(source: Array[Dictionary], seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = source.duplicate(true)
	var state := maxi(1, seed)
	for index in range(result.size() - 1, 0, -1):
		state = int((state * 1103515245 + 12345) & 0x7fffffff)
		var swap_index := state % (index + 1)
		var held := result[index]
		result[index] = result[swap_index]
		result[swap_index] = held
	return result


static func _stable_seed(value: String) -> int:
	# A small process-independent hash; unlike Object.hash(), this is safe to use
	# as part of a future authoritative server contract.
	var seed := 2166136261
	for byte in value.to_utf8_buffer():
		seed = int(((seed ^ int(byte)) * 16777619) & 0x7fffffff)
	return maxi(1, seed)


static func offer_for_target(player: Dictionary, target: Dictionary, role_id := "standard") -> Dictionary:
	var planet := Content.get_planet(str(target.get("planet_id", "")))
	if target.is_empty() or not is_planet_available(str(planet.get("id", "")), int(player.get("level", 1))):
		return {}
	for index in ROLES.size():
		if str(ROLES[index].id) == role_id:
			return scale_offer(target, planet, int(player.get("level", 1)), ROLES[index], index)
	return {}


static func weekly_special_offer(player: Dictionary, target: Dictionary, week_id: int) -> Dictionary:
	var offer := offer_for_target(player, target, "dangerous")
	if offer.is_empty():
		return {}
	return _apply_weekly_special(offer, week_id)


static func _apply_weekly_special(offer: Dictionary, week_id: int) -> Dictionary:
	offer["weekly_special"] = true
	offer["weekly_cycle_id"] = week_id
	offer["power"] = maxi(1, roundi(float(offer.power) * 1.08))
	offer["defense"] = maxi(0, roundi(float(offer.defense) * 1.08))
	offer["health"] = maxi(1, roundi(float(offer.health) * 1.15))
	offer["credits"] = maxi(1, roundi(float(offer.credits) * 1.35))
	offer["xp"] = maxi(1, roundi(float(offer.xp) * 1.20))
	offer["loot_power"] = int(offer.power)
	offer["scrap_reward"] = 8
	return offer


static func targets_for_planet(planet_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in Content.TARGETS:
		if str(target.get("planet_id", Content.PLANET.id)) == planet_id:
			result.append(target.duplicate(true))
	return result


static func travel_multiplier(mission_level: int) -> float:
	for band in EARLY_TRAVEL_BANDS:
		if mission_level >= int(band.minimum_level):
			return float(band.multiplier)
	return 0.40


static func mission_travel_duration(planet: Dictionary, mission_level: int) -> float:
	return float(planet.get("travel_duration", 300.0)) * travel_multiplier(mission_level)


static func starter_travel_discount(mission_level: int) -> float:
	return 1.0 - travel_multiplier(mission_level)


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
	offer["base_travel_duration"] = float(planet.get("travel_duration", 300.0))
	offer["travel_duration"] = mission_travel_duration(planet, mission_level)
	offer["starter_travel_discount"] = starter_travel_discount(mission_level)
	offer["pursuit_duration"] = 20.0 + minf(100.0, float(mission_level) * 4.0)
	offer["duration"] = ceili(float(offer.travel_duration) + float(offer.pursuit_duration))
	offer["fuel_cost"] = maxi(1, ceili(float(offer.base_travel_duration) / 60.0))
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
	var canonical := scale_offer_level(template, planet, int(mission_level), role, int(offer_index))
	if bool(loaded.get("weekly_special", false)):
		var cycle = loaded.get("weekly_cycle_id", -1)
		if not (cycle is int or cycle is float) or int(cycle) < 0:
			return {}
		canonical = _apply_weekly_special(canonical, int(cycle))
	return canonical
