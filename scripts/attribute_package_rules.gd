class_name AttributePackageRules
extends RefCounted

const ELIGIBLE_SLOTS := ["helmet", "gloves", "boots", "rig", "implant"]
const DEFINITIONS := [
	{"id": "breach_calibration", "attribute_id": "strength", "bonus": 2, "name": "CALIBRAÇÃO DE RUPTURA"},
	{"id": "reinforced_biomesh", "attribute_id": "vitality", "bonus": 3, "name": "BIOMALHA REFORÇADA"},
	{"id": "reflex_tuning", "attribute_id": "dexterity", "bonus": 3, "name": "AFINAÇÃO DE REFLEXOS"},
	{"id": "neural_overclock", "attribute_id": "intelligence", "bonus": 2, "name": "OVERCLOCK NEURAL"},
	{"id": "crooked_instinct", "attribute_id": "cunning", "bonus": 3, "name": "INSTINTO TORTO"},
]


static func is_eligible_slot(slot: String) -> bool:
	return ELIGIBLE_SLOTS.has(slot)


static func definition_for(package_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.id) == package_id:
			return definition
	return {}


static func is_valid(package_id: String, slot := "") -> bool:
	if definition_for(package_id).is_empty():
		return false
	return slot.is_empty() or is_eligible_slot(slot)


static func package_for_index(index: int) -> Dictionary:
	if DEFINITIONS.is_empty():
		return {}
	return DEFINITIONS[posmod(index, DEFINITIONS.size())].duplicate(true)


static func attribute_bonus(player: Dictionary, attribute_id: String) -> int:
	var bonus := 0
	for slot in ELIGIBLE_SLOTS:
		var package_id := str(player.get(slot, {}).get("attribute_package_id", ""))
		var definition := definition_for(package_id)
		if str(definition.get("attribute_id", "")) == attribute_id:
			bonus += int(definition.get("bonus", 0))
	return bonus


static func item_score(item: Dictionary) -> int:
	var definition := definition_for(str(item.get("attribute_package_id", "")))
	match str(definition.get("attribute_id", "")):
		"strength": return int(definition.get("bonus", 0)) * 3
		"vitality": return int(definition.get("bonus", 0)) * 4
		"dexterity": return int(definition.get("bonus", 0)) * 3
		"intelligence": return int(definition.get("bonus", 0))
		"cunning": return roundi(float(definition.get("bonus", 0)) * 2.5)
		_: return 0


static func effective_attributes(player: Dictionary, base_attribute_value: int) -> Dictionary:
	var result: Dictionary = player.get("attributes", {}).duplicate(true)
	for definition in DEFINITIONS:
		var attribute_id := str(definition.attribute_id)
		result[attribute_id] = int(result.get(attribute_id, base_attribute_value)) + attribute_bonus(player, attribute_id)
	return result
