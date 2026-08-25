class_name ClassRules
extends RefCounted

const LocaleRules = preload("res://scripts/locale_rules.gd")

const UNASSIGNED_ID := ""
const DEFINITIONS := [
	{
		"id": "warrant_breaker",
		"name": "QUEBRA-MANDADOS",
		"prototype": true,
		"primary_attribute": "strength",
		"primary_name": "FORÇA",
		"tagline": "Impacto, armamento pesado e cobranças sem sutileza.",
		"flavor": "Resolve contratos pesados com ferramentas ainda mais pesadas.",
		"preferred_approach": "premium_warrant",
		"route_style": "PRESSÃO CORPORATIVA",
		"approach_affinity": 1.18,
		"effects": {"power_per_primary_points": 2, "base_damage_reduction": 1, "damage_reduction_per_primary_points": 2},
	},
	{
		"id": "orbit_gunslinger",
		"name": "PISTOLEIRO ORBITAL",
		"prototype": true,
		"primary_attribute": "dexterity",
		"primary_name": "DESTREZA",
		"tagline": "Reflexos, posicionamento e precisão em movimento.",
		"flavor": "Transforma ângulos ruins e probabilidades piores em vantagem.",
		"preferred_approach": "hot_hatch",
		"route_style": "ENTRADA RÁPIDA",
		"approach_affinity": 1.18,
		"effects": {"power_per_primary_points": 2, "base_attack_roll_bonus": 0.005, "attack_roll_bonus_per_primary_point": 0.0025, "attack_roll_bonus_cap": 0.03},
	},
	{
		"id": "contract_hacker",
		"name": "HACKER DE CONTRATOS",
		"prototype": true,
		"primary_attribute": "intelligence",
		"primary_name": "INTELIGÊNCIA",
		"tagline": "Dispositivos, abertura tática e tecnologia improvisada.",
		"flavor": "Reescreve fechaduras, drones e ocasionalmente a definição de legal.",
		"preferred_approach": "quiet_net",
		"route_style": "CONTROLE TÁTICO",
		"approach_affinity": 2.25,
		"effects": {"power_per_primary_points": 2, "base_opening_damage": 2, "opening_damage_per_primary_point": 1},
	},
]


static func is_valid(class_id: String) -> bool:
	if class_id == UNASSIGNED_ID:
		return true
	for definition in DEFINITIONS:
		if str(definition.id) == class_id:
			return true
	return false


static func get_definition(class_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.id) == class_id:
			return definition
	return {}


static func class_name_for(class_id: String) -> String:
	var definition := get_definition(class_id)
	if definition.is_empty():
		return str(TranslationServer.translate("CLASS_NONE"))
	var key := "CLASS_%s_NAME" % class_id.to_upper()
	var translated := str(TranslationServer.translate(key))
	return str(definition.name) if translated == key else translated


static func primary_attribute(class_id: String) -> String:
	return str(get_definition(class_id).get("primary_attribute", ""))


static func is_prototype(class_id: String) -> bool:
	return bool(get_definition(class_id).get("prototype", false))


static func approach_affinity(class_id: String, approach_id: String) -> float:
	var definition := get_definition(class_id)
	if definition.is_empty() or str(definition.get("preferred_approach", "")) != approach_id:
		return 1.0
	return maxf(1.0, float(definition.get("approach_affinity", 1.0)))


static func route_profile_text(class_id: String, approach_id: String) -> String:
	var definition := get_definition(class_id)
	if definition.is_empty() or str(definition.get("preferred_approach", "")) != approach_id:
		return ""
	return class_name_for(class_id)


static func specialization_text(definition: Dictionary) -> String:
	var effects: Dictionary = definition.get("effects", {})
	var parts: Array[String] = []
	var power_step := int(effects.get("power_per_primary_points", 0))
	var primary_id := str(definition.get("primary_attribute", ""))
	var primary_key := "ATTRIBUTE_%s" % primary_id.to_upper()
	var primary_name := str(TranslationServer.translate(primary_key))
	if primary_name == primary_key:
		primary_name = str(definition.get("primary_name", "atributo principal")).capitalize()
	if power_step > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_POWER")) % [power_step, primary_name])
	var opening_multiplier := int(effects.get("opening_damage_per_primary_point", 0))
	var base_opening := int(effects.get("base_opening_damage", 0))
	if base_opening > 0 or opening_multiplier > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_INVASION")) % [base_opening, opening_multiplier])
	var reduction_step := int(effects.get("damage_reduction_per_primary_points", 0))
	var base_reduction := int(effects.get("base_damage_reduction", 0))
	if base_reduction > 0 or reduction_step > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_HULL")) % [base_reduction, reduction_step])
	var base_roll_percent := float(effects.get("base_attack_roll_bonus", 0.0)) * 100.0
	var roll_per_point_percent := float(effects.get("attack_roll_bonus_per_primary_point", 0.0)) * 100.0
	var roll_cap_percent := float(effects.get("attack_roll_bonus_cap", 0.0)) * 100.0
	if base_roll_percent > 0 or roll_per_point_percent > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_AIM")) % [base_roll_percent, roll_per_point_percent, roll_cap_percent])
	return ". ".join(parts) + ("." if not parts.is_empty() else str(TranslationServer.translate("CLASS_SPECIALIZATION_NONE")))


static func specialization_preview(definition: Dictionary, attributes: Dictionary, base_attribute_value: int) -> Dictionary:
	var attribute_id := str(definition.get("primary_attribute", ""))
	var investment := maxi(0, int(attributes.get(attribute_id, base_attribute_value)) - base_attribute_value) if not attribute_id.is_empty() else 0
	var effects: Dictionary = definition.get("effects", {})
	var points_per_power := int(effects.get("power_per_primary_points", 0))
	var power := floori(float(investment) / float(points_per_power)) if points_per_power > 0 else 0
	var opening_multiplier := maxi(0, int(effects.get("opening_damage_per_primary_point", 0)))
	var opening_damage := maxi(0, int(effects.get("base_opening_damage", 0))) + investment * opening_multiplier
	var reduction_step := int(effects.get("damage_reduction_per_primary_points", 0))
	var damage_reduction := maxi(0, int(effects.get("base_damage_reduction", 0)))
	if reduction_step > 0:
		damage_reduction += floori(float(investment) / float(reduction_step))
	var attack_roll_bonus := maxf(0.0, float(effects.get("base_attack_roll_bonus", 0.0))) + float(investment) * maxf(0.0, float(effects.get("attack_roll_bonus_per_primary_point", 0.0)))
	var attack_roll_cap := maxf(0.0, float(effects.get("attack_roll_bonus_cap", attack_roll_bonus)))
	if attack_roll_cap > 0.0:
		attack_roll_bonus = minf(attack_roll_bonus, attack_roll_cap)
	return {
		"investment": investment,
		"power": power,
		"opening_damage": opening_damage,
		"damage_reduction": damage_reduction,
		"attack_roll_bonus": attack_roll_bonus,
	}


static func specialization_power(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return int(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).power)


static func specialization_opening_damage(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return int(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).opening_damage)


static func specialization_damage_reduction(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return int(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).damage_reduction)


static func specialization_attack_roll_bonus(player: Dictionary, base_attribute_value: int) -> float:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return float(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).attack_roll_bonus)


static func combat_identity_text(player: Dictionary, base_attribute_value: int) -> String:
	var class_id := str(player.get("class_id", UNASSIGNED_ID))
	var definition := get_definition(class_id)
	if definition.is_empty():
		return ""
	var preview := specialization_preview(definition, player.get("attributes", {}), base_attribute_value)
	if int(preview.damage_reduction) > 0:
		return LocaleRules.text("CLASS_IDENTITY_HARD_SHELL", "CASCO DURO · -%d DANO POR GOLPE", [int(preview.damage_reduction)])
	if float(preview.attack_roll_bonus) > 0.0:
		return LocaleRules.text("CLASS_IDENTITY_ORBITAL_AIM", "MIRA ORBITAL · +%.1f%% PRECISÃO", [float(preview.attack_roll_bonus) * 100.0])
	if int(preview.opening_damage) > 0:
		return LocaleRules.text("CLASS_IDENTITY_BREACH", "INVASÃO · +%d DANO DE ABERTURA", [int(preview.opening_damage)])
	return LocaleRules.text("CLASS_IDENTITY_INACTIVE", "ESPECIALIZAÇÃO AINDA INATIVA")
