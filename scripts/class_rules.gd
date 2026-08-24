class_name ClassRules
extends RefCounted

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
		"effects": {"power_per_primary_points": 2},
	},
	{
		"id": "orbit_gunslinger",
		"name": "PISTOLEIRO ORBITAL",
		"prototype": true,
		"primary_attribute": "dexterity",
		"primary_name": "DESTREZA",
		"tagline": "Reflexos, posicionamento e precisão em movimento.",
		"flavor": "Transforma ângulos ruins e probabilidades piores em vantagem.",
		"effects": {"power_per_primary_points": 2},
	},
	{
		"id": "contract_hacker",
		"name": "HACKER DE CONTRATOS",
		"prototype": true,
		"primary_attribute": "intelligence",
		"primary_name": "INTELIGÊNCIA",
		"tagline": "Dispositivos, abertura tática e tecnologia improvisada.",
		"flavor": "Reescreve fechaduras, drones e ocasionalmente a definição de legal.",
		"effects": {"power_per_primary_points": 2, "opening_damage_per_primary_point": 2},
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
	return "SEM CLASSE" if definition.is_empty() else str(definition.name)


static func primary_attribute(class_id: String) -> String:
	return str(get_definition(class_id).get("primary_attribute", ""))


static func is_prototype(class_id: String) -> bool:
	return bool(get_definition(class_id).get("prototype", false))


static func specialization_text(definition: Dictionary) -> String:
	var effects: Dictionary = definition.get("effects", {})
	var parts: Array[String] = []
	var power_step := int(effects.get("power_per_primary_points", 0))
	if power_step > 0:
		parts.append("+1 Poder a cada %d pontos de %s investidos" % [power_step, str(definition.get("primary_name", "atributo principal")).capitalize()])
	var opening_multiplier := int(effects.get("opening_damage_per_primary_point", 0))
	if opening_multiplier > 0:
		parts.append("+%d abertura por ponto investido" % opening_multiplier)
	return ". ".join(parts) + ("." if not parts.is_empty() else "Sem bônus mecânico.")


static func primary_investment(player: Dictionary, base_attribute_value: int) -> int:
	var attribute_id := primary_attribute(str(player.get("class_id", UNASSIGNED_ID)))
	if attribute_id.is_empty():
		return 0
	return maxi(0, int(player.get("attributes", {}).get(attribute_id, base_attribute_value)) - base_attribute_value)


static func specialization_power(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	var points_per_power := int(definition.get("effects", {}).get("power_per_primary_points", 0))
	if points_per_power <= 0:
		return 0
	return floori(float(primary_investment(player, base_attribute_value)) / float(points_per_power))


static func specialization_opening_damage(player: Dictionary, base_attribute_value: int) -> int:
	var definition := get_definition(str(player.get("class_id", UNASSIGNED_ID)))
	var multiplier := int(definition.get("effects", {}).get("opening_damage_per_primary_point", 0))
	return primary_investment(player, base_attribute_value) * maxi(0, multiplier)
