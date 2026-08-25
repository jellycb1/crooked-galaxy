extends SceneTree

const PortraitScript = preload("res://scripts/procedural_portrait.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var portrait := PortraitScript.new()
	portrait.character_id = "hunter"
	portrait.equipment_profile = {
		"species_id": "discontinued_synthetic",
		"weapon": {"color": "#d789ff", "origin_planet_id": "cassino_quasar", "power_upgrades": 3},
		"armor": {"color": "#58d9ff", "origin_planet_id": "cassino_quasar", "integrity_upgrades": 2},
	}
	portrait.custom_minimum_size = Vector2(118, 118)
	root.add_child(portrait)
	await process_frame
	check(portrait.equipment_color(portrait.equipment_profile.weapon, Color.WHITE) == Color("#d789ff"), "hunter visor inherits equipped weapon rarity")
	check(portrait.planet_loadout_color("cassino_quasar") == Color("#ff75d8"), "matching planetary kit resolves a stable visual accent")
	check(portrait.planet_loadout_color("unknown") == Color("#55e5ff"), "unknown equipment origins keep the hunter fallback palette")
	check(portrait.species_skin_color("discontinued_synthetic") != portrait.species_skin_color("patched_terran"), "species identity changes the hunter face palette")
	check(portrait.species_accent_color("nebular_nomad") == Color("#b8f45d"), "species identity resolves a stable non-combat accent")
	var visual_species := ["patched_terran", "discontinued_synthetic", "nebular_nomad", "cellar_mycelian", "rusted_ferrite", "tankborn_abyssal", "unstable_luminar", "catalog_chimera"]
	var skin_colors := visual_species.map(func(species_id): return portrait.species_skin_color(species_id))
	var accent_colors := visual_species.map(func(species_id): return portrait.species_accent_color(species_id))
	check(skin_colors.duplicate().reduce(func(unique, color):
		if not unique.has(color): unique.append(color)
		return unique
	, []).size() == 8, "all eight species retain a distinct portrait palette")
	check(accent_colors.duplicate().reduce(func(unique, color):
		if not unique.has(color): unique.append(color)
		return unique
	, []).size() == 8, "all eight species retain a distinct emblem accent")
	portrait.queue_free()
	if failures == 0:
		print("PASS: hunter portrait reflects the equipped loadout")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
