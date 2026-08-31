class_name VisualAssetCatalog
extends RefCounted

const ContentDB = preload("res://scripts/content_db.gd")
const ClassRules = preload("res://scripts/class_rules.gd")
const SpeciesRules = preload("res://scripts/species_rules.gd")
const AppearanceRules = preload("res://scripts/appearance_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const ChallengeRules = preload("res://scripts/challenge_rules.gd")
const ReleaseReadinessRules = preload("res://scripts/release_readiness_rules.gd")
const ProductionAssetApprovals = preload("res://scripts/production_asset_approvals.gd")

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
	"supporting_panel": "res://assets/ui/supporting-panel-runtime-candidate-v1.png",
	"confirmation_modal": "res://assets/ui/runtime/confirmation-modal-runtime-candidate-v1.png",
	"success_receipt": "res://assets/ui/runtime/success-receipt-panel-runtime-candidate-v1.png",
	"tooltip_frame": "res://assets/ui/runtime/tooltip-frame-runtime-candidate-v1.png",
	"selected_tab": "res://assets/ui/runtime/tab-selected-runtime-candidate-v1.png",
	"plain_divider": "res://assets/ui/runtime/divider-plain-runtime-candidate-v1.png",
	"slider_handle": "res://assets/ui/runtime/slider-handle-runtime-candidate-v1.png",
	"rarity_tier_1": "res://assets/ui/runtime/item-rarity-tier1-runtime-candidate-v1.png",
	"rarity_tier_2": "res://assets/ui/runtime/item-rarity-tier2-runtime-candidate-v1.png",
	"rarity_tier_3": "res://assets/ui/runtime/item-rarity-tier3-runtime-candidate-v1.png",
	"rarity_tier_4": "res://assets/ui/runtime/item-rarity-tier4-runtime-candidate-v1.png",
	"portrait_allied": "res://assets/ui/runtime/portrait-frame-allied-runtime-candidate-v1.png",
	"portrait_boss": "res://assets/ui/runtime/portrait-frame-boss-runtime-candidate-v1.png",
	"portrait_hostile": "res://assets/ui/runtime/portrait-frame-hostile-runtime-candidate-v1.png",
	"portrait_neutral": "res://assets/ui/runtime/portrait-frame-neutral-runtime-candidate-v1.png",
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

const DELIVERY_CONTRACTS := {
	"class_promo": {"canvas": "up to 1024 px long edge", "display": "220-300 px focal figure", "alpha": true, "anchor": "center-bottom", "role": "expressive three-quarter class promotion"},
	"species_base": {"canvas": "shared 1024 px square species canvas", "display": "160-260 px modular portrait", "alpha": true, "anchor": "center-bottom", "role": "neutral anatomy and silhouette base"},
	"species_mask": {"canvas": "exact species-base canvas", "display": "composited only", "alpha": true, "anchor": "pixel-identical to species base", "role": "palette regions without baked color"},
	"species_occlusion": {"canvas": "exact species-base canvas", "display": "composited only", "alpha": true, "anchor": "pixel-identical to species base", "role": "equipment front/back occlusion mask"},
	"species_eyes": {"canvas": "exact species-base canvas", "display": "composited only", "alpha": true, "anchor": "pixel-identical to species base", "role": "one swappable eye expression"},
	"species_feature": {"canvas": "exact species-base canvas", "display": "composited only", "alpha": true, "anchor": "pixel-identical to species base", "role": "one swappable defining feature"},
	"species_marking": {"canvas": "exact species-base canvas", "display": "composited only", "alpha": true, "anchor": "pixel-identical to species base", "role": "one swappable marking overlay"},
	"target_portrait": {"canvas": "up to 1024 px long edge", "display": "96-160 px portrait", "alpha": true, "anchor": "center-bottom", "role": "expressive bust or three-quarter target"},
	"planet_habitat": {"canvas": "9:16, up to 1280 px long edge", "display": "450x800 background crop", "alpha": false, "anchor": "safe focal subject above lower UI", "role": "primary world habitat"},
	"planet_arena": {"canvas": "9:16 overlay, up to 1280 px long edge", "display": "450x800 combat overlay", "alpha": true, "anchor": "bottom", "role": "transparent combat ground/arena layer"},
	"planet_icon": {"canvas": "512 px square", "display": "66-96 px medal", "alpha": true, "anchor": "center", "role": "world silhouette medal"},
	"transport": {"canvas": "up to 1024 px long edge", "display": "72-220 px vehicle", "alpha": true, "anchor": "center-bottom", "role": "side or three-quarter transport illustration"},
	"rift_enemy": {"canvas": "up to 1024 px long edge", "display": "96-160 px portrait", "alpha": true, "anchor": "center-bottom", "role": "surreal expressive Rift enemy"},
}

const PRODUCTION_BATCH_ORDER := ["style_lock", "identity", "worlds", "transports", "rift"]

static var approved_atomic_set_cache: Dictionary = {}


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


static func load_approved_texture(kind: String, asset_id: String, variant := "", require_atomic_set := true) -> Texture2D:
	var path := asset_path(kind, asset_id, variant)
	if path.is_empty() or not ProductionAssetApprovals.is_approved(path):
		return null
	if require_atomic_set and not approved_atomic_set_complete(kind, asset_id, variant):
		return null
	return load_texture(kind, asset_id, variant)


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


static func delivery_contract(kind: String) -> Dictionary:
	return DELIVERY_CONTRACTS.get(kind, {}).duplicate(true)


static func production_batch(entry: Dictionary) -> String:
	var group := str(entry.get("group", ""))
	var asset_id := str(entry.get("id", ""))
	if (group == "classes" and asset_id == "warrant_breaker") \
	or (group == "species" and asset_id == "terran") \
	or (group == "planets" and asset_id == "dustball_prime") \
	or (group == "targets" and asset_id == "gloop"):
		return "style_lock"
	match group:
		"classes", "species": return "identity"
		"planets", "targets": return "worlds"
		"transports": return "transports"
		"rift": return "rift"
		_: return "unscoped"


static func atomic_delivery_set(entry: Dictionary) -> String:
	match str(entry.get("group", "")):
		"species": return "species:%s" % str(entry.get("id", ""))
		"planets": return "planet:%s" % str(entry.get("id", ""))
		_: return "%s:%s" % [str(entry.get("group", "")), str(entry.get("id", ""))]


static func production_delivery_manifest() -> Array[Dictionary]:
	var manifest: Array[Dictionary] = []
	for entry in production_slice_required_records():
		var enriched := entry.duplicate(true)
		var batch := production_batch(enriched)
		enriched["batch"] = batch
		enriched["batch_order"] = PRODUCTION_BATCH_ORDER.find(batch)
		enriched["atomic_set"] = atomic_delivery_set(enriched)
		enriched["contract"] = delivery_contract(str(enriched.kind))
		manifest.append(enriched)
	manifest.sort_custom(func(left: Dictionary, right: Dictionary):
		var left_key := "%02d|%s|%s|%s" % [int(left.batch_order), str(left.atomic_set), str(left.kind), str(left.variant)]
		var right_key := "%02d|%s|%s|%s" % [int(right.batch_order), str(right.atomic_set), str(right.kind), str(right.variant)]
		return left_key < right_key
	)
	return manifest


static func manifest_entry(kind: String, asset_id: String, variant := "") -> Dictionary:
	for entry in production_delivery_manifest():
		if str(entry.kind) == kind and str(entry.id) == asset_id and str(entry.variant) == variant:
			return entry
	return {}


static func approved_atomic_set_complete(kind: String, asset_id: String, variant := "") -> bool:
	var cache_key := "%s|%s|%s" % [kind, asset_id, variant]
	if approved_atomic_set_cache.has(cache_key):
		return bool(approved_atomic_set_cache[cache_key])
	var entry := manifest_entry(kind, asset_id, variant)
	if entry.is_empty():
		approved_atomic_set_cache[cache_key] = false
		return false
	var atomic_set := str(entry.atomic_set)
	for candidate in production_delivery_manifest():
		if str(candidate.atomic_set) == atomic_set:
			var path := str(candidate.path)
			if not ProductionAssetApprovals.is_approved(path) or not ResourceLoader.exists(path):
				approved_atomic_set_cache[cache_key] = false
				return false
	approved_atomic_set_cache[cache_key] = true
	return true


static func rift_asset_id_for_stage(stage_id: String) -> String:
	for reality in ChallengeRules.REALITIES:
		var reality_id := str(reality.id)
		for stage_index in reality.get("stages", []).size():
			if str(ChallengeRules.stage_at(stage_index, reality_id).get("id", "")) == stage_id:
				return "%s_%02d" % [reality_id, stage_index + 1]
	return ""


static func approved_character_texture(character_id: String) -> Texture2D:
	if not ContentDB.get_target(character_id).is_empty():
		return load_approved_texture("target_portrait", character_id)
	var rift_asset_id := rift_asset_id_for_stage(character_id)
	return null if rift_asset_id.is_empty() else load_approved_texture("rift_enemy", rift_asset_id)


static func approved_file_errors() -> Array[String]:
	var errors: Array[String] = []
	var known_paths := {}
	for entry in current_required_records():
		known_paths[str(entry.path)] = entry
	for path_value in ProductionAssetApprovals.APPROVED_FILES:
		var path := str(path_value)
		var expected_hash := ProductionAssetApprovals.expected_sha256(path)
		if not known_paths.has(path):
			errors.append("Approved production asset is outside the catalog: %s" % path)
			continue
		if expected_hash.length() != 64 or not expected_hash.is_valid_hex_number(false):
			errors.append("Approved production asset has an invalid SHA-256: %s" % path)
			continue
		if not FileAccess.file_exists(path):
			errors.append("Approved production source is missing: %s" % path)
			continue
		if FileAccess.get_sha256(path).to_lower() != expected_hash.to_lower():
			errors.append("Approved production source hash drifted: %s" % path)
	var approved_records: Array[Dictionary] = []
	for path in known_paths:
		if ProductionAssetApprovals.is_approved(str(path)):
			approved_records.append(known_paths[path])
	errors.append_array(technical_errors(approved_records))
	return errors


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


static func production_slice_required_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
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
	for target in ReleaseReadinessRules.production_slice_targets():
		records.append(record("target_portrait", str(target.id), "", "targets"))
	for planet in ReleaseReadinessRules.production_slice_planets():
		var planet_id := str(planet.id)
		for kind in ["planet_habitat", "planet_arena", "planet_icon"]:
			records.append(record(kind, planet_id, "", "planets"))
	for transport in ReleaseReadinessRules.production_slice_transports():
		records.append(record("transport", str(transport.id), "", "transports"))
	for stage_index in ReleaseReadinessRules.PRODUCTION_SLICE_RIFT_FLOORS:
		records.append(record("rift_enemy", "%s_%02d" % [ReleaseReadinessRules.PRODUCTION_SLICE_RIFT_REALITY_ID, stage_index + 1], "", "rift"))
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


static func technical_errors(records := current_required_records()) -> Array[String]:
	var errors: Array[String] = []
	for entry in records:
		if not bool(entry.get("exists", false)):
			continue
		var kind := str(entry.get("kind", ""))
		var path := str(entry.get("path", ""))
		var texture := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if texture == null:
			errors.append("Available catalog asset does not load as Texture2D: %s" % path)
		elif not texture_fits_budget(kind, texture):
			errors.append("Catalog asset exceeds the %s mobile long-edge budget: %s" % [kind, path])
	return errors


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
