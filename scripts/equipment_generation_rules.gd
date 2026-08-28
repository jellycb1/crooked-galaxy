class_name EquipmentGenerationRules
extends RefCounted

const VARIANT_IDS := ["standard", "patched", "polished", "weathered", "contraband"]
const MIN_QUALITY := 1
const MAX_QUALITY := 100


static func template_id(planet_id: String, slot: String, catalog_index: int) -> String:
	return "%s_%s_%02d" % [planet_id, slot, maxi(0, catalog_index)]


static func item_level(target: Dictionary) -> int:
	# Mission offers carry their scaled player level. Legacy authored targets use
	# loot power as a stable approximation until their explicit level is added.
	if target.has("mission_level"):
		return maxi(1, int(target.mission_level))
	return maxi(1, roundi(float(target.get("loot_power", target.get("power", 1))) / 10.0))


static func quality_for_roll(roll: float) -> int:
	# Quality describes the base-stat roll inside the template's range. Rarity is
	# reported separately and must never disguise a weak base roll as a perfect one.
	return clampi(roundi(clampf(roll, 0.0, 1.0) * float(MAX_QUALITY - MIN_QUALITY) + MIN_QUALITY), MIN_QUALITY, MAX_QUALITY)


static func variant_for_roll(roll: int) -> String:
	return str(VARIANT_IDS[posmod(roll, VARIANT_IDS.size())])


static func variant_is_valid(variant_id: String) -> bool:
	return VARIANT_IDS.has(variant_id)


static func collection_id(item: Dictionary) -> String:
	var template := str(item.get("template_id", ""))
	var variant := str(item.get("variant_id", ""))
	if template.is_empty() or not variant_is_valid(variant):
		return ""
	return "%s::%s" % [template, variant]
