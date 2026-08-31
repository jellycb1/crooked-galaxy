class_name ReleaseReadinessRules
extends RefCounted

const ContentDB = preload("res://scripts/content_db.gd")
const ClassRules = preload("res://scripts/class_rules.gd")
const SpeciesRules = preload("res://scripts/species_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const ChallengeRules = preload("res://scripts/challenge_rules.gd")

const PRODUCTION_SLICE_MAX_LEVEL := 30
const PRODUCTION_SLICE_PLANET_IDS := [
	"dustball_prime",
	"congelaria_sa",
	"micelia_404",
	"ferro_velho_omega",
	"cassino_quasar",
	"aeropolis_penhora",
]
const PRODUCTION_SLICE_RIFT_REALITY_ID := "dead_customs"
const PRODUCTION_SLICE_RIFT_FLOORS := 6


static func production_slice_planets() -> Array[Dictionary]:
	var planets: Array[Dictionary] = []
	for planet in ContentDB.PLANETS:
		if str(planet.get("id", "")) in PRODUCTION_SLICE_PLANET_IDS:
			planets.append(planet)
	return planets


static func production_slice_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for target in ContentDB.TARGETS:
		if str(target.get("planet_id", "")) in PRODUCTION_SLICE_PLANET_IDS:
			targets.append(target)
	return targets


static func production_slice_incidents() -> Array[Dictionary]:
	var incidents: Array[Dictionary] = []
	for incident in ContentDB.HUNT_EVENTS:
		if str(incident.get("planet_id", "")) in PRODUCTION_SLICE_PLANET_IDS:
			incidents.append(incident)
	return incidents


static func production_slice_transports() -> Array[Dictionary]:
	var transports: Array[Dictionary] = []
	for transport in TransportRules.DEFINITIONS:
		if int(transport.get("required_level", 1)) <= PRODUCTION_SLICE_MAX_LEVEL:
			transports.append(transport)
	return transports


static func production_slice_rift_stages() -> Array[Dictionary]:
	var reality := ChallengeRules.reality_definition(PRODUCTION_SLICE_RIFT_REALITY_ID)
	var stages: Array = reality.get("stages", [])
	var result: Array[Dictionary] = []
	for stage_index in mini(PRODUCTION_SLICE_RIFT_FLOORS, stages.size()):
		result.append(ChallengeRules.stage_at(stage_index, PRODUCTION_SLICE_RIFT_REALITY_ID))
	return result


static func production_slice_summary() -> Dictionary:
	return {
		"max_level": PRODUCTION_SLICE_MAX_LEVEL,
		"classes": ClassRules.DEFINITIONS.size(),
		"species": SpeciesRules.DEFINITIONS.size(),
		"planets": production_slice_planets().size(),
		"targets": production_slice_targets().size(),
		"incidents": production_slice_incidents().size(),
		"transports": production_slice_transports().size(),
		"rift_stages": production_slice_rift_stages().size(),
	}


static func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var planets := production_slice_planets()
	var observed_planet_ids: Array[String] = []
	for planet in planets:
		observed_planet_ids.append(str(planet.get("id", "")))
		if int(planet.get("unlock_level", 0)) > PRODUCTION_SLICE_MAX_LEVEL:
			errors.append("Slice planet unlocks after level %d: %s" % [PRODUCTION_SLICE_MAX_LEVEL, str(planet.get("id", ""))])
	if observed_planet_ids != PRODUCTION_SLICE_PLANET_IDS:
		errors.append("Production-slice planet order or identity drifted")

	var targets := production_slice_targets()
	var incidents := production_slice_incidents()
	for planet_id in PRODUCTION_SLICE_PLANET_IDS:
		if targets.filter(func(entry): return str(entry.get("planet_id", "")) == planet_id).size() != 4:
			errors.append("Production-slice planet must own four targets: %s" % planet_id)
		if incidents.filter(func(entry): return str(entry.get("planet_id", "")) == planet_id).size() != 2:
			errors.append("Production-slice planet must own two incidents: %s" % planet_id)

	if ClassRules.DEFINITIONS.size() != 3:
		errors.append("Production slice requires exactly three launch classes")
	if SpeciesRules.DEFINITIONS.size() != 8:
		errors.append("Production slice requires exactly eight launch species")
	if production_slice_transports().size() != 4:
		errors.append("Production slice requires all four launch transports")

	var stages := production_slice_rift_stages()
	if stages.size() != PRODUCTION_SLICE_RIFT_FLOORS:
		errors.append("Production slice requires the first six Rift encounters")
	for stage in stages:
		if int(stage.get("recommended_level", 0)) > PRODUCTION_SLICE_MAX_LEVEL:
			errors.append("Production-slice Rift encounter exceeds level 30: %s" % str(stage.get("id", "")))
	if ChallengeRules.FIRST_REALITY_RECOMMENDED_LEVELS.size() > PRODUCTION_SLICE_RIFT_FLOORS:
		if int(ChallengeRules.FIRST_REALITY_RECOMMENDED_LEVELS[PRODUCTION_SLICE_RIFT_FLOORS]) <= PRODUCTION_SLICE_MAX_LEVEL:
			errors.append("A seventh Rift encounter now belongs to the level 1-30 slice")
	return errors
