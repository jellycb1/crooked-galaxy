extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")
const Content = preload("res://scripts/content_db.gd")
const Classes = preload("res://scripts/class_rules.gd")
const Species = preload("res://scripts/species_rules.gd")
const Transports = preload("res://scripts/transport_rules.gd")
const Challenges = preload("res://scripts/challenge_rules.gd")

var failures := 0


func _init() -> void:
	check(Catalog.is_safe_id("dustball_prime"), "stable lowercase content ids are accepted")
	check(not Catalog.is_safe_id("../outside"), "path traversal is rejected")
	check(not Catalog.is_safe_id("Target Name"), "display text cannot become an asset path")
	check(Catalog.asset_path("class_promo", "orbit_gunslinger") == "res://assets/characters/classes/orbit_gunslinger.png", "class delivery path is deterministic")
	check(Catalog.asset_path("species_eyes", "terran", "wide") == "res://assets/characters/species/terran/eyes_wide.png", "species layers have deterministic paths")
	check(Catalog.asset_path("target_portrait", "../unsafe").is_empty(), "unsafe ids fail closed")
	check(Catalog.asset_path("unknown", "safe_id").is_empty(), "unknown asset kinds fail closed")

	var records := Catalog.current_required_records()
	var expected_rift_enemies := 0
	for reality in Challenges.REALITIES:
		expected_rift_enemies += reality.get("stages", []).size()
	var expected_species_units := Species.DEFINITIONS.size() * 12
	var expected := Catalog.STATIC_RUNTIME_PATHS.size() + Classes.DEFINITIONS.size() + expected_species_units + Content.TARGETS.size() + Content.PLANETS.size() * 3 + Transports.DEFINITIONS.size() + expected_rift_enemies + Catalog.UI_ICON_IDS.size()
	check(records.size() == expected, "the catalog accounts for every current authored-content delivery")
	check(count_group(records, "species") == expected_species_units, "the modular species contract avoids 648 flattened portraits")
	check(count_group(records, "targets") == Content.TARGETS.size(), "every current target owns one reusable portrait delivery")
	check(count_group(records, "planets") == Content.PLANETS.size() * 3, "every current planet owns habitat, arena and icon deliveries")
	check(count_group(records, "rift") == expected_rift_enemies, "every current Rift floor owns one enemy delivery id")

	var unique_paths := {}
	for entry in records:
		var path := str(entry.path)
		check(not path.is_empty(), "required catalog records always resolve a path")
		check(not unique_paths.has(path), "asset delivery paths are unique: %s" % path)
		unique_paths[path] = true
	check(unique_paths.size() == records.size(), "no two deliveries overwrite the same file")

	var summary := Catalog.readiness_summary(records)
	check(int(summary.required) == records.size(), "readiness summary preserves the required total")
	check(int(summary.available) + int(summary.missing) == int(summary.required), "readiness totals are internally consistent")
	check(int(summary.groups.runtime_core.missing) == 0, "all existing runtime core assets remain present")
	check(Catalog.technical_errors(records).is_empty(), "all available catalog assets load and respect their mobile budgets")
	for runtime_id in Catalog.STATIC_RUNTIME_PATHS:
		var texture := Catalog.load_texture("runtime", str(runtime_id))
		check(texture != null, "runtime core texture loads through the catalog: %s" % runtime_id)
		check(Catalog.texture_fits_budget("runtime", texture), "runtime core texture respects the mobile budget: %s" % runtime_id)

	check(Catalog.fallback_contract("class_promo") == "class_icon.gd", "missing class art retains its procedural fallback")
	check(Catalog.fallback_contract("target_portrait") == "procedural_portrait.gd", "missing target art retains its procedural fallback")
	check(Catalog.fallback_contract("planet_habitat").contains("fallback"), "missing planet art retains its environment fallback")
	check(Catalog.fallback_contract("transport") == "transport_icon.gd", "missing transport art retains its procedural fallback")

	if failures == 0:
		print("PASS: visual asset catalog is deterministic, safe, lazy and fallback-complete")
	quit(1 if failures > 0 else 0)


func count_group(records: Array[Dictionary], group: String) -> int:
	var count := 0
	for entry in records:
		if str(entry.get("group", "")) == group:
			count += 1
	return count


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
