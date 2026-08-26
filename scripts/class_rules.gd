class_name ClassRules
extends RefCounted

const LocaleRules = preload("res://scripts/locale_rules.gd")

const UNASSIGNED_ID := ""
const DEFINITIONS := [
	{
		"id": "warrant_breaker",
		"name": "QUEBRA-MANDADOS",
		"prototype": false,
		"primary_attribute": "strength",
		"primary_name": "FORÇA",
		"tagline": "Impacto, armamento pesado e cobranças sem sutileza.",
		"flavor": "Resolve contratos pesados com ferramentas ainda mais pesadas.",
		"preferred_approach": "premium_warrant",
		"route_style": "PRESSÃO CORPORATIVA",
		"approach_affinity": 1.18,
		"effects": {"power_per_primary_points": 3, "base_damage_reduction": 1, "damage_reduction_per_primary_points": 2, "counter_every_rounds": 3, "base_counter_damage": 1, "counter_damage_per_primary_points": 0},
	},
	{
		"id": "orbit_gunslinger",
		"name": "PISTOLEIRO ORBITAL",
		"prototype": false,
		"primary_attribute": "dexterity",
		"primary_name": "DESTREZA",
		"tagline": "Reflexos, posicionamento e precisão em movimento.",
		"flavor": "Transforma ângulos ruins e probabilidades piores em vantagem.",
		"preferred_approach": "hot_hatch",
		"route_style": "ENTRADA RÁPIDA",
		"approach_affinity": 1.18,
		"effects": {"power_per_primary_points": 2, "base_attack_roll_bonus": 0.005, "attack_roll_bonus_per_primary_point": 0.0, "attack_roll_bonus_cap": 0.005, "base_evasion_chance": 0.005, "evasion_per_primary_point": 0.0005, "evasion_cap": 0.02, "follow_up_roll_threshold": 0.99, "follow_up_damage_ratio": 0.10},
	},
	{
		"id": "contract_hacker",
		"name": "HACKER DE CONTRATOS",
		"prototype": false,
		"primary_attribute": "intelligence",
		"primary_name": "INTELIGÊNCIA",
		"tagline": "Dispositivos, abertura tática e tecnologia improvisada.",
		"flavor": "Reescreve fechaduras, drones e ocasionalmente a definição de legal.",
		"preferred_approach": "quiet_net",
		"route_style": "CONTROLE TÁTICO",
		"approach_affinity": 2.25,
		"effects": {"power_per_primary_points": 2, "base_opening_damage": 2, "opening_damage_per_primary_point": 1, "base_defense_bypass": 1, "defense_bypass_per_primary_points": 0, "defense_bypass_cap": 1},
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
		if roll_per_point_percent > 0:
			parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_AIM")) % [base_roll_percent, roll_per_point_percent, roll_cap_percent])
		else:
			parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_AIM_FIXED")) % [base_roll_percent])
	var counter_damage := int(effects.get("base_counter_damage", 0))
	var counter_every := int(effects.get("counter_every_rounds", 0))
	if counter_damage > 0 and counter_every > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_COUNTER")) % [counter_damage, counter_every])
	var evasion_percent := float(effects.get("base_evasion_chance", 0.0)) * 100.0
	var follow_up_percent := float(effects.get("follow_up_damage_ratio", 0.0)) * 100.0
	if evasion_percent > 0.0 or follow_up_percent > 0.0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_GUNSLINGER")) % [evasion_percent, follow_up_percent])
	var defense_bypass := int(effects.get("base_defense_bypass", 0))
	if defense_bypass > 0:
		parts.append(str(TranslationServer.translate("CLASS_SPECIALIZATION_OVERLOAD")) % [defense_bypass])
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
	var counter_step := maxi(0, int(effects.get("counter_damage_per_primary_points", 0)))
	var counter_damage := maxi(0, int(effects.get("base_counter_damage", 0)))
	if counter_step > 0:
		counter_damage += floori(float(investment) / float(counter_step))
	var evasion_chance := maxf(0.0, float(effects.get("base_evasion_chance", 0.0))) + float(investment) * maxf(0.0, float(effects.get("evasion_per_primary_point", 0.0)))
	var evasion_cap := maxf(0.0, float(effects.get("evasion_cap", evasion_chance)))
	if evasion_cap > 0.0:
		evasion_chance = minf(evasion_chance, evasion_cap)
	var defense_step := maxi(0, int(effects.get("defense_bypass_per_primary_points", 0)))
	var defense_bypass := maxi(0, int(effects.get("base_defense_bypass", 0)))
	if defense_step > 0:
		defense_bypass += floori(float(investment) / float(defense_step))
	var defense_cap := maxi(0, int(effects.get("defense_bypass_cap", defense_bypass)))
	if defense_cap > 0:
		defense_bypass = mini(defense_bypass, defense_cap)
	return {
		"investment": investment,
		"power": power,
		"opening_damage": opening_damage,
		"damage_reduction": damage_reduction,
		"attack_roll_bonus": attack_roll_bonus,
		"counter_damage": counter_damage,
		"evasion_chance": evasion_chance,
		"defense_bypass": defense_bypass,
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


static func specialization_counter_damage(player: Dictionary, base_attribute_value: int, round_number: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	var every := maxi(0, int(definition.get("effects", {}).get("counter_every_rounds", 0)))
	if every <= 0 or round_number <= 0 or round_number % every != 0:
		return 0
	return int(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).counter_damage)


static func specialization_evasion_chance(player: Dictionary, base_attribute_value: int) -> float:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return float(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).evasion_chance)


static func specialization_follow_up_damage(player: Dictionary, adjusted_roll: float, base_damage: int) -> int:
	var effects: Dictionary = get_definition(str(player.get("class_id", UNASSIGNED_ID))).get("effects", {})
	var threshold := float(effects.get("follow_up_roll_threshold", 2.0))
	if adjusted_roll < threshold:
		return 0
	return maxi(1, roundi(float(base_damage) * maxf(0.0, float(effects.get("follow_up_damage_ratio", 0.0)))))


static func specialization_defense_bypass(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	return int(specialization_preview(definition, player.get("attributes", {}), base_attribute_value).defense_bypass)


static func combat_identity_text(player: Dictionary, base_attribute_value: int) -> String:
	var class_id := str(player.get("class_id", UNASSIGNED_ID))
	var definition := get_definition(class_id)
	if definition.is_empty():
		return ""
	var preview := specialization_preview(definition, player.get("attributes", {}), base_attribute_value)
	if int(preview.damage_reduction) > 0:
		return LocaleRules.text("CLASS_IDENTITY_BREAKER", "CASCO DURO · -%d DANO/GOLPE · CONTRA-ATAQUE +%d A CADA 3 TURNOS", [int(preview.damage_reduction), int(preview.counter_damage)])
	if float(preview.attack_roll_bonus) > 0.0:
		return LocaleRules.text("CLASS_IDENTITY_GUNSLINGER", "MIRA ORBITAL · +%.1f%% PRECISÃO · %.1f%% ESQUIVA · RAJADA EM TIRO PERFEITO", [float(preview.attack_roll_bonus) * 100.0, float(preview.evasion_chance) * 100.0])
	if int(preview.opening_damage) > 0:
		return LocaleRules.text("CLASS_IDENTITY_HACKER", "INVASÃO · +%d ABERTURA · SOBRECARGA -%d DEFESA", [int(preview.opening_damage), int(preview.defense_bypass)])
	return LocaleRules.text("CLASS_IDENTITY_INACTIVE", "ESPECIALIZAÇÃO AINDA INATIVA")
