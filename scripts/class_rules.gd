class_name ClassRules
extends RefCounted

const UNASSIGNED_ID := ""
const DEFINITIONS := [
	{
		"id": "warrant_breaker",
		"name": "QUEBRA-MANDADOS",
		"primary_attribute": "strength",
		"primary_name": "FORÇA",
		"tagline": "Impacto, armamento pesado e cobranças sem sutileza.",
		"flavor": "Resolve contratos pesados com ferramentas ainda mais pesadas.",
	},
	{
		"id": "orbit_gunslinger",
		"name": "PISTOLEIRO ORBITAL",
		"primary_attribute": "dexterity",
		"primary_name": "DESTREZA",
		"tagline": "Reflexos, posicionamento e precisão em movimento.",
		"flavor": "Transforma ângulos ruins e probabilidades piores em vantagem.",
	},
	{
		"id": "contract_hacker",
		"name": "HACKER DE CONTRATOS",
		"primary_attribute": "intelligence",
		"primary_name": "INTELIGÊNCIA",
		"tagline": "Dispositivos, abertura tática e tecnologia improvisada.",
		"flavor": "Reescreve fechaduras, drones e ocasionalmente a definição de legal.",
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


static func specialization_power(player: Dictionary, base_attribute_value: int) -> int:
	var attribute_id := primary_attribute(str(player.get("class_id", UNASSIGNED_ID)))
	if attribute_id.is_empty():
		return 0
	var value := int(player.get("attributes", {}).get(attribute_id, base_attribute_value))
	return floori(float(maxi(0, value - base_attribute_value)) / 2.0)
