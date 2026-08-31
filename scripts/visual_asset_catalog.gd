class_name VisualAssetCatalog
extends RefCounted

const ContentDB = preload("res://scripts/content_db.gd")
const ClassRules = preload("res://scripts/class_rules.gd")
const SpeciesRules = preload("res://scripts/species_rules.gd")
const AppearanceRules = preload("res://scripts/appearance_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const ChallengeRules = preload("res://scripts/challenge_rules.gd")

const MAX_LONG_EDGE := {
	"runtime": 1280,
	"class_promo": 1024,
	"species_base": 1024,
	"species_mask": 1024,
	"species_occlusion": 1024,
	"species_eyes": 1024,
	"species_feature": 1024,
	"species_marking": 1024,
	"target_portrait": 1024,
	"planet_habitat": 1280,
	"planet_arena": 1280,
	"planet_icon": 512,
	"transport": 1024,
	"rift_enemy": 1024,
	"ui_icon": 256,
}

const STATIC_RUNTIME_PATHS := {
	"panel_frame": "res://assets/ui/main-dossier-frame-runtime-512x384.png",
	"boot_splash": "res://assets/boot_splash.png",
	"contracts_fallback": "res://assets/backgrounds/bounty_office.png",
	"world_fallback": "res://assets/backgrounds/frontier_spaceport.png",
	"workshop_fallback": "res://assets/backgrounds/arsenal_workshop.png",
	"combat_fallback": "res://assets/backgrounds/frontier_arena.png",
}

const UI_ICON_IDS := [
	"credits", "warp_chips", "fuel", "scrap", "xp", "level", "power", "health",
	"rift_key", "clock", "lock", "notification", "purchase_complete", "error",
	"server", "language",
	"nav_contracts", "nav_arsenal", "nav_hunter", "nav_galaxy", "nav_menu",
	"attribute_strength", "attribute_vitality", "attribute_dexterity",
	"attribute_intelligence", "attribute_cunning",
	"action_attack", "action_negotiate", "action_hack", "action_escape",
	"action_investigate", "action_repair", "action_risk", "action_pay",
	"action_help", "action_steal", "action_wait", "action_improvise",
]

const SPECIES_SIMPLE_KINDS := ["species_base", "species_mask", "species_occlusion"]
const SPECIES_LAYER_OPTIONS := {
	"species_eyes": "eyes",
	"species_feature": "feature",
	"species_marking": "marking",
}


static func is_safe_id(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		var code := character.unicode_at(0)
		var lowercase := code >= 97 and code <= 122
		var digit := code >= 48 and code <= 57
		if not lowercase and not digit and character != "_":
			return false
	return true


static func asset_path(kind: String, asset_id: String, variant := "") -> String:
	if not is_safe_id(asset_id) or (not variant.is_empty() and not is_safe_id(variant)):
		return ""
	match kind:
		"runtime":
			return str(STATIC_RUNTIME_PATHS.get(asset_id, ""))
		"class_promo":
			return "res://assets/characters/classes/%s.png" % asset_id
		"species_base":
			return "res://assets/characters/species/%s/base.png" % asset_id
		"species_mask":
			return "res://assets/characters/species/%s/palette_mask.png" % asset_id
		"species_occlusion":
			return "res://assets/characters/species/%s/equipment_occlusion.png" % asset_id
		"species_eyes":
			return "res://assets/characters/species/%s/eyes_%s.png" % [asset_id, variant]
		"species_feature":
			return "res://assets/characters/species/%s/feature_%s.png" % [asset_id, variant]
		"species_marking":
			return "res://assets/characters/species/%s/marking_%s.png" % [asset_id, variant]
		"target_portrait":
			return "res://assets/characters/targets/%s.png" % asset_id
		"planet_habitat":
			return "res://assets/planets/%s/habitat.png" % asset_id
		"planet_arena":
			return "res://assets/planets/%s/arena.png" % asset_id
		"planet_icon":
			return "res://assets/planets/%s/icon.png" % asset_id
		"transport":
			return "res://assets/transports/%s.png" % asset_id
		"rift_enemy":
			return "res://assets/rift/enemies/%s.png" % asset_id
		"ui_icon":
			return "res://assets/ui/icons/%s.svg" % asset_id
		_:
			return ""


static func asset_exists(kind: String, asset_id: String, variant := "") -> bool:
	var path := asset_path(kind, asset_id, variant)
	return not path.is_empty() and ResourceLoader.exists(path)


static func load_texture(kind: String, asset_id: String, variant := "") -> Texture2D:
	var path := asset_path(kind, asset_id, variant)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D


static func texture_fits_budget(kind: String, texture: Texture2D) -> bool:
	if texture == null or not MAX_LONG_EDGE.has(kind):
		return false
	return maxi(texture.get_width(), texture.get_height()) <= int(MAX_LONG_EDGE[kind])


static func record(kind: String, asset_id: String, variant := "", group := "") -> Dictionary:
	var path := asset_path(kind, asset_id, variant)
	return {
		"kind": kind,
		"id": asset_id,
		"variant": variant,
		"group": group if not group.is_empty() else kind,
		"path": path,
		"exists": not path.is_empty() and ResourceLoader.exists(path),
		"max_long_edge": int(MAX_LONG_EDGE.get(kind, 0)),
	}


static func current_required_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for runtime_id in STATIC_RUNTIME_PATHS:
		records.append(record("runtime", str(runtime_id), "", "runtime_core"))
	for definition in ClassRules.DEFINITIONS:
		records.append(record("class_promo", str(definition.id), "", "classes"))
	for definition in SpeciesRules.DEFINITIONS:
		var species_id := str(definition.id)
		for kind in SPECIES_SIMPLE_KINDS:
			records.append(record(kind, species_id, "", "species"))
		for kind in SPECIES_LAYER_OPTIONS:
			var category := str(SPECIES_LAYER_OPTIONS[kind])
			for option in AppearanceRules.OPTIONS[category]:
				records.append(record(kind, species_id, str(option), "species"))
	for target in ContentDB.TARGETS:
		records.append(record("target_portrait", str(target.id), "", "targets"))
	for planet in ContentDB.PLANETS:
		var planet_id := str(planet.id)
		for kind in ["planet_habitat", "planet_arena", "planet_icon"]:
			records.append(record(kind, planet_id, "", "planets"))
	for transport in TransportRules.DEFINITIONS:
		records.append(record("transport", str(transport.id), "", "transports"))
	for reality in ChallengeRules.REALITIES:
		var reality_id := str(reality.id)
		var stages: Array = reality.get("stages", [])
		for stage_index in stages.size():
			records.append(record("rift_enemy", "%s_%02d" % [reality_id, stage_index + 1], "", "rift"))
	for icon_id in UI_ICON_IDS:
		records.append(record("ui_icon", icon_id, "", "ui_icons"))
	return records


static func readiness_summary(records := current_required_records()) -> Dictionary:
	var groups := {}
	var available := 0
	for entry in records:
		var group := str(entry.get("group", "unknown"))
		if not groups.has(group):
			groups[group] = {"available": 0, "required": 0, "missing": 0}
		groups[group].required += 1
		if bool(entry.get("exists", false)):
			groups[group].available += 1
			available += 1
		else:
			groups[group].missing += 1
	return {
		"available": available,
		"required": records.size(),
		"missing": records.size() - available,
		"groups": groups,
	}


static func missing_records(records := current_required_records()) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	for entry in records:
		if not bool(entry.get("exists", false)):
			missing.append(entry)
	return missing


static func fallback_contract(kind: String) -> String:
	match kind:
		"class_promo": return "class_icon.gd"
		"species_base", "species_mask", "species_occlusion", "species_eyes", "species_feature", "species_marking": return "procedural_portrait.gd"
		"target_portrait", "rift_enemy": return "procedural_portrait.gd"
		"planet_habitat": return "environment_backdrop.gd contracts/world fallback"
		"planet_arena": return "environment_backdrop.gd combat fallback"
		"planet_icon": return "planet_icon.gd"
		"transport": return "transport_icon.gd"
		"ui_icon": return "code-native icon scripts"
		"runtime": return "none"
		_: return "unsupported"
