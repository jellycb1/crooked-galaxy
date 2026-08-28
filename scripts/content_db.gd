class_name ContentDB
extends RefCounted

const CoreRulesScript = preload("res://scripts/core_rules.gd")
const EquipmentGenerationRulesScript = preload("res://scripts/equipment_generation_rules.gd")
const AttributePackageRulesScript = preload("res://scripts/attribute_package_rules.gd")
const DustballPrimeContent = preload("res://scripts/content/packs/dustball_prime.gd")
const CongelariaContent = preload("res://scripts/content/packs/congelaria_sa.gd")
const Micelia404Content = preload("res://scripts/content/packs/micelia_404.gd")
const FerroVelhoOmegaContent = preload("res://scripts/content/packs/ferro_velho_omega.gd")
const CassinoQuasarContent = preload("res://scripts/content/packs/cassino_quasar.gd")
const AeropolisPenhoraContent = preload("res://scripts/content/packs/aeropolis_penhora.gd")
const ArquivoAbissalN9Content = preload("res://scripts/content/packs/arquivo_abissal_n9.gd")

static var procedural_collection_ids_cache: Array[String] = []
static var procedural_collection_entries_cache: Array[Dictionary] = []


const PLANET := DustballPrimeContent.PLANET

const PLANETS := [
	PLANET,
	CongelariaContent.PLANET,
	Micelia404Content.PLANET,
	FerroVelhoOmegaContent.PLANET,
	CassinoQuasarContent.PLANET,
	AeropolisPenhoraContent.PLANET,
	ArquivoAbissalN9Content.PLANET,
]

const TARGETS := [
	DustballPrimeContent.TARGET_GLOOP,
	DustballPrimeContent.TARGET_BARON_BOOM,
	DustballPrimeContent.TARGET_MADAME_VACUUM,
	DustballPrimeContent.TARGET_MAYOR_GOLD_DUST,
	CongelariaContent.TARGET_AUDITOR_FROST,
	CongelariaContent.TARGET_CHEF_COLDFLAME,
	CongelariaContent.TARGET_EXECUTIVE_PENGUIN,
	CongelariaContent.TARGET_DIRECTOR_KELVIN,
	Micelia404Content.TARGET_LANDLORD_SPORE,
	Micelia404Content.TARGET_COUNTESS_TRUFFLE,
	Micelia404Content.TARGET_CAPTAIN_CHLOROPHYLL,
	Micelia404Content.TARGET_MOTHER_MYCELIA,
	FerroVelhoOmegaContent.TARGET_BOLT_COLLECTOR,
	FerroVelhoOmegaContent.TARGET_DOCTOR_PATCHWORK,
	FerroVelhoOmegaContent.TARGET_CRANE_KING,
	FerroVelhoOmegaContent.TARGET_OMEGA_JUNKYARD,
	CassinoQuasarContent.TARGET_DEALER_COMET,
	CassinoQuasarContent.TARGET_DUCHESS_JACKPOT,
	CassinoQuasarContent.TARGET_MISFORTUNE_AUDITOR,
	CassinoQuasarContent.TARGET_HOUSE_ETERNAL,
	AeropolisPenhoraContent.TARGET_COURIER_CUMULUS,
	AeropolisPenhoraContent.TARGET_DUCHESS_LOW_PRESSURE,
	AeropolisPenhoraContent.TARGET_ENGINEER_THUNDER,
	AeropolisPenhoraContent.TARGET_STORM_BANK,
	ArquivoAbissalN9Content.TARGET_EEL_COURIER,
	ArquivoAbissalN9Content.TARGET_CORAL_LANDLADY,
	ArquivoAbissalN9Content.TARGET_NOTARY_OCTOPUS,
	ArquivoAbissalN9Content.TARGET_PROTOCOL_LEVIATHAN,
]

const PLAYER_ATTACKS := [
	"Ricochete de Plasma",
	"Cobrança à Queima-Roupa",
	"Disparo Quase Calculado",
	"Cláusula de Perfuração",
]

const CONTRACT_APPROACHES := [
	{
		"id": "quiet_net",
		"name": "Rede Silenciosa",
		"tag": "SEGURO · +XP",
		"description": "Cerque o alvo, desligue as saídas e finja que tudo estava planejado.",
		"duration_mult": 1.35,
		"power_mult": 0.92,
		"defense_mult": 0.85,
		"health_mult": 1.0,
		"credits_mult": 0.90,
		"xp_mult": 1.25,
		"color": "#55e5ff",
	},
	{
		"id": "hot_hatch",
		"name": "Entrada pela Escotilha",
		"tag": "RÁPIDO · +35% CRÉDITOS",
		"description": "Chegue antes do plano, chute a porta errada e cobre taxa de urgência.",
		"duration_mult": 0.65,
		"power_mult": 1.18,
		"defense_mult": 1.08,
		"health_mult": 1.28,
		"frontier_health_bonus": 0.22,
		"planet_health_step": 0.03,
		"credits_mult": 1.35,
		"xp_mult": 1.0,
		"color": "#ff6f7d",
	},
	{
		"id": "premium_warrant",
		"name": "Mandado Corporativo",
		"tag": "LUCRO · +100% CR · +3 SUCATA",
		"description": "A corporação paga muito mais e libera peças da oficina, desde que o alvo possa revidar muito mais.",
		"duration_mult": 1.0,
		"power_mult": 1.22,
		"defense_mult": 1.14,
		"health_mult": 1.32,
		"frontier_health_bonus": 0.32,
		"planet_health_step": 0.02,
		"credits_mult": 2.0,
		"xp_mult": 0.90,
		"scrap_reward": 3,
		"color": "#ffc857",
	},
]

const HUNT_EVENTS := [
	DustballPrimeContent.EVENT_TOLL_DRONE,
	DustballPrimeContent.EVENT_BOUNTY_STREAMER,
	CongelariaContent.EVENT_HEAT_INSPECTOR,
	CongelariaContent.EVENT_CORPORATE_AVALANCHE,
	Micelia404Content.EVENT_SPORE_CUSTOMS,
	Micelia404Content.EVENT_SENTIENT_SHORTCUT,
	FerroVelhoOmegaContent.EVENT_MAGNETIC_STORM,
	FerroVelhoOmegaContent.EVENT_WARRANTY_GHOST,
	CassinoQuasarContent.EVENT_GRAVITY_ROULETTE,
	CassinoQuasarContent.EVENT_LUCK_INSPECTOR,
	AeropolisPenhoraContent.EVENT_PRESSURE_TOLL,
	AeropolisPenhoraContent.EVENT_LIGHTNING_STRIKE,
	ArquivoAbissalN9Content.EVENT_BATHYAL_CUSTOMS,
	ArquivoAbissalN9Content.EVENT_DECOMPRESSION_QUEUE,
]

const ITEM_TRAITS := {
	"weapon": [
		{"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0},
		{"id": "argument_amplifier", "name": "AMPLIFICADOR DE ARGUMENTO", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6},
		{"id": "ambush_capacitor", "name": "CAPACITOR DE EMBOSCADA", "description": "+5 dano no primeiro disparo.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 5},
	],
	"armor": [
		{"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "power_bonus": 0, "health_bonus": 14},
		{"id": "illegal_servos", "name": "SERVOS NÃO DECLARADOS", "description": "+1 poder e +8 integridade.", "power_bonus": 1, "health_bonus": 8},
		{"id": "bureaucratic_dampener", "name": "AMORTECEDOR BUROCRÁTICO", "description": "-2 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 2},
	],
	"helmet": [
		{"id": "contraband_visor", "name": "VISEIRA DE CONTRABANDO", "description": "+3 dano de abertura.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3},
		{"id": "cranial_warranty", "name": "GARANTIA CRANIANA", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "neural_calculator", "name": "CALCULADORA NEURAL", "description": "+1 poder e +1 dano de abertura.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 1},
	],
	"gloves": [
		{"id": "unlicensed_servos", "name": "SERVOS SEM LICENÇA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0},
		{"id": "reactive_grip", "name": "PEGA REATIVA", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6},
		{"id": "parry_mesh", "name": "MALHA DE APARO", "description": "-1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1},
	],
	"boots": [
		{"id": "inertial_soles", "name": "SOLAS INERCIAIS", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "evasion_gyros", "name": "GIROSCÓPIOS DE FUGA", "description": "-1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1},
		{"id": "argument_thrusters", "name": "PROPULSORES DE ARGUMENTO", "description": "+1 poder e +2 dano de abertura.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2},
	],
	"rig": [
		{"id": "smuggler_harness", "name": "ARNÊS DE CONTRABANDO", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "counterweight_servos", "name": "SERVOS DE CONTRAPESO", "description": "-1 dano por golpe e +1 contra-ataque a cada 4 turnos.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1, "counter_damage_bonus": 1, "counter_every_rounds": 4},
		{"id": "quickdraw_bus", "name": "BARRAMENTO DE SAQUE", "description": "+1 poder, +2 abertura e rajada de 5% em tiro perfeito.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2, "follow_up_roll_threshold": 0.99, "follow_up_damage_ratio": 0.05},
	],
	"implant": [
		{"id": "reflex_archive", "name": "ARQUIVO DE REFLEXOS", "description": "+3 dano de abertura.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3},
		{"id": "illegal_adrenaline", "name": "ADRENALINA ILEGAL", "description": "+1 poder, +6 integridade e +1% esquiva.", "power_bonus": 1, "health_bonus": 6, "evasion_chance_bonus": 0.01},
		{"id": "null_synapse", "name": "SINAPSE NULA", "description": "+2 poder e ignora 1 defesa.", "power_bonus": 2, "health_bonus": 0, "defense_bypass_bonus": 1},
	],
	"gadget": [
		{"id": "warrant_flare", "name": "SINALIZADOR DE MANDADO", "description": "+4 dano de abertura e +4 integridade.", "power_bonus": 0, "health_bonus": 4, "opening_damage_bonus": 4},
		{"id": "probability_decoy", "name": "ISCO DE PROBABILIDADE", "description": "+8 integridade e +1,5% esquiva.", "power_bonus": 0, "health_bonus": 8, "evasion_chance_bonus": 0.015},
		{"id": "breach_assistant", "name": "ASSISTENTE DE RUPTURA", "description": "+1 poder, +2 abertura e ignora 2 defesa.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2, "defense_bypass_bonus": 2},
	],
	"relic": [
		{"id": "gravity_knot", "name": "NÓ DE GRAVIDADE", "description": "+16 integridade e -1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 16, "damage_reduction": 1},
		{"id": "recurring_second", "name": "SEGUNDO RECORRENTE", "description": "+3 abertura e +2 contra-ataque a cada 4 turnos.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3, "counter_damage_bonus": 2, "counter_every_rounds": 4},
		{"id": "null_prism", "name": "PRISMA DO NULO", "description": "+2 poder, +8 integridade, ignora 2 defesa e rajada de 5% em tiro perfeito.", "power_bonus": 2, "health_bonus": 8, "defense_bypass_bonus": 2, "follow_up_roll_threshold": 0.99, "follow_up_damage_ratio": 0.05},
	],
}


const ITEM_CATALOG := DustballPrimeContent.ITEMS

const PLANET_ITEM_CATALOGS := {
	"congelaria_sa": CongelariaContent.ITEMS,
	"micelia_404": Micelia404Content.ITEMS,
	"ferro_velho_omega": FerroVelhoOmegaContent.ITEMS,
	"cassino_quasar": CassinoQuasarContent.ITEMS,
	"aeropolis_penhora": AeropolisPenhoraContent.ITEMS,
	"arquivo_abissal_n9": ArquivoAbissalN9Content.ITEMS,
}

const SECONDARY_ITEM_CATALOGS := {
	"congelaria_sa": CongelariaContent.SECONDARY_ITEMS,
	"micelia_404": Micelia404Content.SECONDARY_ITEMS,
	"ferro_velho_omega": FerroVelhoOmegaContent.SECONDARY_ITEMS,
	"cassino_quasar": CassinoQuasarContent.SECONDARY_ITEMS,
	"aeropolis_penhora": AeropolisPenhoraContent.SECONDARY_ITEMS,
	"arquivo_abissal_n9": ArquivoAbissalN9Content.SECONDARY_ITEMS,
}


static func get_planet(planet_id: String) -> Dictionary:
	for planet in PLANETS:
		if str(planet.id) == planet_id:
			return planet.duplicate(true)
	return PLANET.duplicate(true)


static func is_planet_unlocked(planet_id: String, completed_planets: Array) -> bool:
	var planet := get_planet(planet_id)
	var requirement := str(planet.get("unlock_after", ""))
	return requirement.is_empty() or completed_planets.has(requirement)


static func available_bounties(reputation: int, planet_id := "dustball_prime", chapter_tier := -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unlocked_tier: int = reputation if chapter_tier < 0 else chapter_tier
	for target in TARGETS:
		if str(target.get("planet_id", "dustball_prime")) == planet_id and int(target.rank) <= reputation and int(target.get("chapter_tier", target.rank)) <= unlocked_tier:
			result.append(target.duplicate(true))
	return result


static func board_bounties(reputation: int, planet_id: String, chapter_tier: int, captures_by_target: Dictionary, limit := 3) -> Array[Dictionary]:
	var unlocked := available_bounties(reputation, planet_id, chapter_tier)
	if unlocked.is_empty() or limit <= 0:
		return []
	var primary_index := 0
	for index in unlocked.size():
		if int(unlocked[index].get("chapter_tier", 0)) > int(unlocked[primary_index].get("chapter_tier", 0)):
			primary_index = index
	var primary: Dictionary = unlocked[primary_index]
	var primary_captures := int(captures_by_target.get(str(primary.id), 0))
	var chapter_complete := bool(primary.get("boss", false)) and primary_captures > 0
	var repeats: Array[Dictionary] = []
	for index in unlocked.size():
		if index == primary_index and not chapter_complete:
			continue
		var candidate: Dictionary = unlocked[index].duplicate(true)
		var captures := int(captures_by_target.get(str(candidate.id), 0))
		var mastery_level := CoreRulesScript.target_mastery_level(captures)
		var next_requirement := CoreRulesScript.target_mastery_next_requirement(mastery_level)
		candidate["board_mastery_remaining"] = 999 if next_requirement < 0 else next_requirement - captures
		repeats.append(candidate)
	repeats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var remaining_a := int(a.get("board_mastery_remaining", 999))
		var remaining_b := int(b.get("board_mastery_remaining", 999))
		if remaining_a != remaining_b:
			return remaining_a < remaining_b
		return int(a.get("chapter_tier", 0)) > int(b.get("chapter_tier", 0))
	)
	var result: Array[Dictionary] = []
	if not chapter_complete:
		primary = primary.duplicate(true)
		primary["board_role"] = "primary"
		primary["board_reason"] = "MANDADO FINAL" if bool(primary.get("boss", false)) else "MANDADO PRINCIPAL"
		result.append(primary)
	for candidate in repeats:
		if result.size() >= limit:
			break
		var captures := int(captures_by_target.get(str(candidate.id), 0))
		var mastery_level := CoreRulesScript.target_mastery_level(captures)
		var next_requirement := CoreRulesScript.target_mastery_next_requirement(mastery_level)
		candidate["board_role"] = "repeat"
		candidate["board_reason"] = "CONTRATO RECORRENTE · PERÍCIA MÁX." if next_requirement < 0 else "ROTA DE PERÍCIA · FALTAM %d" % (next_requirement - captures)
		candidate.erase("board_mastery_remaining")
		result.append(candidate)
	return result


static func contract_approaches() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for approach in CONTRACT_APPROACHES:
		result.append(approach.duplicate(true))
	return result


static func get_target(target_id: String) -> Dictionary:
	for target in TARGETS:
		if str(target.get("id", "")) == target_id:
			return target.duplicate(true)
	return {}


static func target_for_planet_tier(planet_id: String, tier: int) -> Dictionary:
	for target in TARGETS:
		if str(target.get("planet_id", "")) == planet_id and int(target.get("chapter_tier", -1)) == tier:
			return target.duplicate(true)
	return {}


static func planet_tier_from_target_captures(planet_id: String, captures_by_target: Dictionary) -> int:
	var tier := 0
	for prerequisite_tier in 3:
		var prerequisite := target_for_planet_tier(planet_id, prerequisite_tier)
		if prerequisite.is_empty() or int(captures_by_target.get(str(prerequisite.id), 0)) < 3:
			break
		tier = prerequisite_tier + 1
	return tier


static func warrant_progress(planet_id: String, captures_by_target: Dictionary) -> Dictionary:
	var tier := planet_tier_from_target_captures(planet_id, captures_by_target)
	var next_target := target_for_planet_tier(planet_id, tier + 1)
	if next_target.is_empty():
		return {"tier": tier, "next_target": {}, "progress": 0, "requirement": 0}
	var prerequisite := target_for_planet_tier(planet_id, tier)
	return {
		"tier": tier,
		"next_target": next_target,
		"progress": mini(3, int(captures_by_target.get(str(prerequisite.id), 0))),
		"requirement": 3,
		"prerequisite": prerequisite,
	}


static func apply_approach(bounty: Dictionary, approach: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	result["approach"] = approach.duplicate(true)
	# Contract danger affects the encounter, not the equipment tier that drops.
	# Otherwise the fastest recommended route compounds its own power advantage.
	result["loot_power"] = int(bounty.get("loot_power", bounty.power))
	var planet_index := planet_index_for(str(bounty.get("planet_id", PLANET.id)))
	# Small first-chapter targets under-round route multipliers and saturate after
	# the first loot drops. The correction is intentionally isolated to Dustball
	# so established planet balance and endpoint guard rails remain unchanged.
	var frontier_pressure := float(approach.get("frontier_health_bonus", 0.0)) if planet_index == 0 else 0.0
	var health_mult := float(approach.health_mult) + float(approach.get("planet_health_step", 0.0)) * planet_index + frontier_pressure
	if bool(bounty.get("mission_offer", false)):
		result["pursuit_duration"] = maxf(1.0, float(bounty.get("pursuit_duration", 1.0)) * float(approach.duration_mult))
		result["duration"] = maxi(1, ceili(float(bounty.get("travel_duration", 0.0)) + float(result.pursuit_duration)))
	else:
		result["duration"] = maxi(1, ceili(float(bounty.duration) * float(approach.duration_mult)))
	result["power"] = maxi(1, roundi(float(bounty.power) * float(approach.power_mult)))
	result["defense"] = maxi(0, roundi(float(bounty.defense) * float(approach.defense_mult)))
	result["health"] = maxi(1, roundi(float(bounty.health) * health_mult))
	result["credits"] = maxi(1, roundi(float(bounty.credits) * float(approach.credits_mult)))
	result["xp"] = maxi(1, roundi(float(bounty.xp) * float(approach.xp_mult)))
	result["scrap_reward"] = maxi(0, int(approach.get("scrap_reward", 0)))
	return result


static func planet_index_for(planet_id: String) -> int:
	for index in PLANETS.size():
		if str(PLANETS[index].id) == planet_id:
			return index
	return 0


static func random_hunt_event(rng: RandomNumberGenerator, planet_id := "dustball_prime") -> Dictionary:
	var candidates: Array[Dictionary] = []
	for event in HUNT_EVENTS:
		if str(event.get("planet_id", "dustball_prime")) == planet_id:
			candidates.append(event)
	if candidates.is_empty():
		candidates.append(HUNT_EVENTS[0])
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)


static func apply_hunt_choice(bounty: Dictionary, choice: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	for stat in ["power", "defense", "health", "credits", "xp"]:
		var multiplier_key := "%s_mult" % stat
		if choice.has(multiplier_key):
			result[stat] = maxi(1 if stat != "defense" else 0, roundi(float(result[stat]) * float(choice[multiplier_key])))
	result["hunt_event_result"] = str(choice.get("result", "A perseguição ficou ligeiramente mais estranha."))
	result["hunt_event_choice_id"] = str(choice.get("id", ""))
	result["hunt_event_credit_cost"] = maxi(0, int(choice.get("credit_cost", 0)))
	return result


static func generate_loot(target: Dictionary, rng: RandomNumberGenerator, mastery_level := 0, forced_slot := "") -> Dictionary:
	var planet_id := str(target.get("planet_id", "dustball_prime"))
	var available_slots := loot_slots_for_planet(planet_id)
	var slot := forced_slot if available_slots.has(forced_slot) else choose_loot_slot(available_slots, rng.randf())
	var catalog := item_catalog_for(planet_id, slot)
	var catalog_index := rng.randi_range(0, catalog.size() - 1)
	var definition: Dictionary = catalog[catalog_index]
	var secondary_slot := slot != "weapon" and slot != "armor"
	var quality_roll := rng.randf()
	var base_power := 1 if secondary_slot else int(int(target.get("loot_power", target.power)) * lerpf(0.36, 0.68, quality_roll))
	# Secondary equipment creates lateral build choices instead of three extra
	# weapon curves. Its progression lives in rare modifications, not target tier.
	var rarity_roll := rng.randf()
	var rarity_thresholds := CoreRulesScript.loot_rarity_thresholds(mastery_level)
	var rarity := "Comum"
	var rarity_color := "#b9c2d9"
	var bonus := 0
	if rarity_roll > float(rarity_thresholds.epic):
		rarity = "Épico"
		rarity_color = "#d789ff"
		bonus = 1 if secondary_slot else 5
	elif rarity_roll > float(rarity_thresholds.rare):
		rarity = "Raro"
		rarity_color = "#58d9ff"
		bonus = 0 if secondary_slot else 2
	var generation_seed := rng.randi()
	var item := {
		"id": "%s_%s_%d" % [target.id, slot, generation_seed],
		"name": definition.name,
		"description": definition.description,
		"slot": slot,
		"origin_planet_id": planet_id,
		"template_id": EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index),
		"item_level": EquipmentGenerationRulesScript.item_level(target),
		"quality": EquipmentGenerationRulesScript.quality_for_roll(quality_roll),
		"variant_id": EquipmentGenerationRulesScript.variant_for_roll(generation_seed),
		"generation_seed": generation_seed,
		"power": maxi(1, base_power + bonus),
		"rarity": rarity,
		"color": rarity_color,
	}
	var rare_trait_chance := 0.85 if planet_id == "ferro_velho_omega" or planet_id == "cassino_quasar" else 0.65
	if rarity == "Épico" or (rarity == "Raro" and rng.randf() < rare_trait_chance):
		# Attribute packages replace an ordinary modification; they never stack
		# with one on the same drop. Only secondary gear enters this first slice.
		if AttributePackageRulesScript.is_eligible_slot(slot) and rng.randf() < 0.35:
			item.attribute_package_id = str(AttributePackageRulesScript.package_for_index(rng.randi()).id)
		else:
			var traits: Array = ITEM_TRAITS[slot]
			item.trait = traits[rng.randi_range(0, traits.size() - 1)].duplicate(true)
	return item


static func loot_slots_for_planet(planet_id: String) -> Array[String]:
	match planet_id:
		"congelaria_sa":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet"]
		"micelia_404":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves"]
		"ferro_velho_omega", "cassino_quasar":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves", "boots"]
		"aeropolis_penhora":
			return ["weapon", "weapon", "weapon", "armor", "armor", "rig", "rig"]
		"arquivo_abissal_n9":
			return ["weapon", "weapon", "weapon", "armor", "armor", "implant", "implant"]
		_:
			return ["weapon", "weapon", "weapon", "armor", "armor"]


static func choose_loot_slot(weighted_slots: Array[String], roll: float) -> String:
	if weighted_slots.is_empty():
		return "weapon"
	var index := mini(weighted_slots.size() - 1, floori(clampf(roll, 0.0, 0.999999) * float(weighted_slots.size())))
	return weighted_slots[index]


static func item_catalog_for(planet_id: String, slot: String) -> Array:
	if slot == "weapon" or slot == "armor":
		var core_family: Dictionary = PLANET_ITEM_CATALOGS.get(planet_id, ITEM_CATALOG)
		return core_family.get(slot, ITEM_CATALOG[slot])
	var secondary_family: Dictionary = SECONDARY_ITEM_CATALOGS.get(planet_id, {})
	return secondary_family.get(slot, [])


static func procedural_collection_ids() -> Array[String]:
	if not procedural_collection_ids_cache.is_empty():
		return procedural_collection_ids_cache.duplicate()
	var ids: Array[String] = []
	for planet in PLANETS:
		var planet_id := str(planet.id)
		for slot in CoreRulesScript.EQUIPMENT_SLOTS:
			var catalog := item_catalog_for(planet_id, slot)
			for catalog_index in catalog.size():
				var template := EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index)
				for variant_id in EquipmentGenerationRulesScript.VARIANT_IDS:
					var collection_id := "%s::%s" % [template, str(variant_id)]
					if not ids.has(collection_id):
						ids.append(collection_id)
	procedural_collection_ids_cache = ids
	return ids.duplicate()


static func procedural_collection_total() -> int:
	if procedural_collection_ids_cache.is_empty():
		procedural_collection_ids()
	return procedural_collection_ids_cache.size()


static func procedural_collection_entries() -> Array[Dictionary]:
	if not procedural_collection_entries_cache.is_empty():
		return procedural_collection_entries_cache.duplicate(true)
	var entries: Array[Dictionary] = []
	for planet in PLANETS:
		var planet_id := str(planet.id)
		for slot in CoreRulesScript.EQUIPMENT_SLOTS:
			var catalog := item_catalog_for(planet_id, slot)
			for catalog_index in catalog.size():
				entries.append({
					"template_id": EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index),
					"planet_id": planet_id,
					"slot": slot,
					"name": str(catalog[catalog_index].get("name", "")),
					"description": str(catalog[catalog_index].get("description", "")),
				})
	procedural_collection_entries_cache = entries
	return entries.duplicate(true)


static func player_attack(rng: RandomNumberGenerator) -> String:
	return PLAYER_ATTACKS[rng.randi_range(0, PLAYER_ATTACKS.size() - 1)]


static func target_attack(target: Dictionary, rng: RandomNumberGenerator) -> String:
	var attacks: Array = target.get("attacks", ["Golpe Suspeito"])
	return attacks[rng.randi_range(0, attacks.size() - 1)]
