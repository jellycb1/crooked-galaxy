class_name ContentPackRegistry
extends RefCounted

const PlanetContentPack = preload("res://scripts/content/planet_content_pack.gd")
const DustballPrime = preload("res://scripts/content/packs/dustball_prime.gd")

const PACK_SCRIPTS := [DustballPrime]


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
	for pack_script in PACK_SCRIPTS:
		var pack: Dictionary = pack_script.PACK
		var pack_id := str(pack.get("id", ""))
		if ids.has(pack_id):
			errors.append("duplicate planet pack id: %s" % pack_id)
		ids[pack_id] = true
		for error in PlanetContentPack.validation_errors(pack):
			errors.append("%s: %s" % [pack_id, error])
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
