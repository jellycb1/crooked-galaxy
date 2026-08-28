class_name ContentPackRegistry
extends RefCounted

const PlanetContentPack = preload("res://scripts/content/planet_content_pack.gd")
const DustballPrime = preload("res://scripts/content/packs/dustball_prime.gd")
const Congelaria = preload("res://scripts/content/packs/congelaria_sa.gd")
const Micelia404 = preload("res://scripts/content/packs/micelia_404.gd")
const FerroVelhoOmega = preload("res://scripts/content/packs/ferro_velho_omega.gd")
const CassinoQuasar = preload("res://scripts/content/packs/cassino_quasar.gd")
const AeropolisPenhora = preload("res://scripts/content/packs/aeropolis_penhora.gd")
const ArquivoAbissalN9 = preload("res://scripts/content/packs/arquivo_abissal_n9.gd")
const VerdantiaPatenteada = preload("res://scripts/content/packs/verdantia_patenteada.gd")
const CaldeiraGarantia = preload("res://scripts/content/packs/caldeira_garantia.gd")
const CondominioLunar7 = preload("res://scripts/content/packs/condominio_lunar_7.gd")
const NecropoleSolarUmbral = preload("res://scripts/content/packs/necropole_solar_umbral.gd")
const CentralTempestades24h = preload("res://scripts/content/packs/central_tempestades_24h.gd")
const MuseuAmanhaObsoleto = preload("res://scripts/content/packs/museu_amanha_obsoleto.gd")
const BibliotecaSilencioTaxado = preload("res://scripts/content/packs/biblioteca_silencio_taxado.gd")

const PACK_SCRIPTS := [DustballPrime, Congelaria, Micelia404, FerroVelhoOmega, CassinoQuasar, AeropolisPenhora, ArquivoAbissalN9, VerdantiaPatenteada, CaldeiraGarantia, CondominioLunar7, NecropoleSolarUmbral, CentralTempestades24h, MuseuAmanhaObsoleto, BibliotecaSilencioTaxado]

# This registry owns the deterministic public composition order. ContentDB
# remains the stable facade consumed by gameplay, saves and tests.
const STARTER_PLANET := DustballPrime.PLANET
const PLANETS := [
	DustballPrime.PLANET,
	Congelaria.PLANET,
	Micelia404.PLANET,
	FerroVelhoOmega.PLANET,
	CassinoQuasar.PLANET,
	AeropolisPenhora.PLANET,
	ArquivoAbissalN9.PLANET,
	VerdantiaPatenteada.PLANET,
	CaldeiraGarantia.PLANET,
	CondominioLunar7.PLANET,
	NecropoleSolarUmbral.PLANET,
	CentralTempestades24h.PLANET,
	MuseuAmanhaObsoleto.PLANET,
	BibliotecaSilencioTaxado.PLANET,
]
const TARGETS := DustballPrime.TARGETS + Congelaria.TARGETS + Micelia404.TARGETS + FerroVelhoOmega.TARGETS + CassinoQuasar.TARGETS + AeropolisPenhora.TARGETS + ArquivoAbissalN9.TARGETS + VerdantiaPatenteada.TARGETS + CaldeiraGarantia.TARGETS + CondominioLunar7.TARGETS + NecropoleSolarUmbral.TARGETS + CentralTempestades24h.TARGETS + MuseuAmanhaObsoleto.TARGETS + BibliotecaSilencioTaxado.TARGETS
const HUNT_EVENTS := DustballPrime.EVENTS + Congelaria.EVENTS + Micelia404.EVENTS + FerroVelhoOmega.EVENTS + CassinoQuasar.EVENTS + AeropolisPenhora.EVENTS + ArquivoAbissalN9.EVENTS + VerdantiaPatenteada.EVENTS + CaldeiraGarantia.EVENTS + CondominioLunar7.EVENTS + NecropoleSolarUmbral.EVENTS + CentralTempestades24h.EVENTS + MuseuAmanhaObsoleto.EVENTS + BibliotecaSilencioTaxado.EVENTS
const STARTER_ITEM_CATALOG := DustballPrime.ITEMS
const PLANET_ITEM_CATALOGS := {
	"congelaria_sa": Congelaria.ITEMS,
	"micelia_404": Micelia404.ITEMS,
	"ferro_velho_omega": FerroVelhoOmega.ITEMS,
	"cassino_quasar": CassinoQuasar.ITEMS,
	"aeropolis_penhora": AeropolisPenhora.ITEMS,
	"arquivo_abissal_n9": ArquivoAbissalN9.ITEMS,
	"verdantia_patenteada": VerdantiaPatenteada.ITEMS,
	"caldeira_garantia": CaldeiraGarantia.ITEMS,
	"condominio_lunar_7": CondominioLunar7.ITEMS,
	"necropole_solar_umbral": NecropoleSolarUmbral.ITEMS,
	"central_tempestades_24h": CentralTempestades24h.ITEMS,
	"museu_amanha_obsoleto": MuseuAmanhaObsoleto.ITEMS,
	"biblioteca_silencio_taxado": BibliotecaSilencioTaxado.ITEMS,
}
const SECONDARY_ITEM_CATALOGS := {
	"congelaria_sa": Congelaria.SECONDARY_ITEMS,
	"micelia_404": Micelia404.SECONDARY_ITEMS,
	"ferro_velho_omega": FerroVelhoOmega.SECONDARY_ITEMS,
	"cassino_quasar": CassinoQuasar.SECONDARY_ITEMS,
	"aeropolis_penhora": AeropolisPenhora.SECONDARY_ITEMS,
	"arquivo_abissal_n9": ArquivoAbissalN9.SECONDARY_ITEMS,
	"verdantia_patenteada": VerdantiaPatenteada.SECONDARY_ITEMS,
	"caldeira_garantia": CaldeiraGarantia.SECONDARY_ITEMS,
	"condominio_lunar_7": CondominioLunar7.SECONDARY_ITEMS,
	"necropole_solar_umbral": NecropoleSolarUmbral.SECONDARY_ITEMS,
	"central_tempestades_24h": CentralTempestades24h.SECONDARY_ITEMS,
	"museu_amanha_obsoleto": MuseuAmanhaObsoleto.SECONDARY_ITEMS,
	"biblioteca_silencio_taxado": BibliotecaSilencioTaxado.SECONDARY_ITEMS,
}


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
	if PLANETS.size() != PACK_SCRIPTS.size():
		errors.append("composed planet count does not match registered packs")
	var expected_targets: Array = []
	var expected_events: Array = []
	for pack_index in PACK_SCRIPTS.size():
		var pack_script = PACK_SCRIPTS[pack_index]
		if pack_index >= PLANETS.size() or PLANETS[pack_index] != pack_script.PLANET:
			errors.append("composed planet order differs at pack index %d" % pack_index)
		expected_targets.append_array(pack_script.TARGETS)
		expected_events.append_array(pack_script.EVENTS)
	if TARGETS != expected_targets:
		errors.append("composed target order differs from registered packs")
	if HUNT_EVENTS != expected_events:
		errors.append("composed event order differs from registered packs")
	if STARTER_ITEM_CATALOG != DustballPrime.ITEMS:
		errors.append("starter item catalog differs from the first registered pack")
	for pack_index in range(1, PACK_SCRIPTS.size()):
		var pack_script = PACK_SCRIPTS[pack_index]
		var pack_id := str(pack_script.PACK.id)
		if PLANET_ITEM_CATALOGS.get(pack_id, {}) != pack_script.ITEMS:
			errors.append("primary item catalog differs for %s" % pack_id)
		if SECONDARY_ITEM_CATALOGS.get(pack_id, {}) != pack_script.SECONDARY_ITEMS:
			errors.append("secondary item catalog differs for %s" % pack_id)
	return errors
