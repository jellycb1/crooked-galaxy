class_name ContentPackRegistry
extends RefCounted

const PlanetContentPack = preload("res://scripts/content/planet_content_pack.gd")
const DustballPrime = preload("res://scripts/content/packs/dustball_prime.gd")
const Congelaria = preload("res://scripts/content/packs/congelaria_sa.gd")
const Micelia404 = preload("res://scripts/content/packs/micelia_404.gd")

const PACK_SCRIPTS := [DustballPrime, Congelaria, Micelia404]


static func all_packs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pack_script in PACK_SCRIPTS:
		result.append(pack_script.PACK.duplicate(true))
	return result


static func pack_for_planet(planet_id: String) -> Dictionary:
	for pack_script in PACK_SCRIPTS:
		if str(pack_script.PACK.id) == planet_id:
			return pack_script.PACK.duplicate(true)
	return {}


static func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var ids := {}
	var target_ids := {}
	var event_ids := {}
	var previous_planet_id := ""
	var previous_unlock_level := 0
	for pack_index in PACK_SCRIPTS.size():
		var pack_script = PACK_SCRIPTS[pack_index]
		var pack: Dictionary = pack_script.PACK
		var pack_id := str(pack.get("id", ""))
		if ids.has(pack_id):
			errors.append("duplicate planet pack id: %s" % pack_id)
		ids[pack_id] = true
		for error in PlanetContentPack.validation_errors(pack):
			errors.append("%s: %s" % [pack_id, error])
		var planet: Dictionary = pack.get("planet", {})
		var unlock_level := int(planet.get("unlock_level", 0))
		if pack_index == 0:
			if planet.has("unlock_after") and not str(planet.get("unlock_after", "")).is_empty():
				errors.append("first planet pack cannot depend on another planet")
		elif str(planet.get("unlock_after", "")) != previous_planet_id:
			errors.append("%s must unlock after %s" % [pack_id, previous_planet_id])
		if pack_index > 0 and unlock_level <= previous_unlock_level:
			errors.append("planet pack unlock levels must increase: %s" % pack_id)
		previous_planet_id = pack_id
		previous_unlock_level = unlock_level
		for target in pack.get("targets", []):
			var target_id := str(target.get("id", ""))
			if target_ids.has(target_id):
				errors.append("duplicate target id across packs: %s" % target_id)
			target_ids[target_id] = true
		for event in pack.get("events", []):
			var event_id := str(event.get("id", ""))
			if event_ids.has(event_id):
				errors.append("duplicate event id across packs: %s" % event_id)
			event_ids[event_id] = true
	return errors
