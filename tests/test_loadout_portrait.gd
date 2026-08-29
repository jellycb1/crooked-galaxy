extends SceneTree

const PortraitScript = preload("res://scripts/procedural_portrait.gd")
const Catalog = preload("res://scripts/visual_asset_catalog.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var portrait := PortraitScript.new()
	portrait.character_id = "hunter"
	portrait.equipment_profile = {
		"species_id": "synthetic",
		"appearance": {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"},
		"weapon": {"color": "#d789ff", "origin_planet_id": "cassino_quasar", "power_upgrades": 3},
		"armor": {"color": "#58d9ff", "origin_planet_id": "cassino_quasar", "integrity_upgrades": 2},
	}
	portrait.custom_minimum_size = Vector2(118, 118)
	root.add_child(portrait)
	await process_frame
	check(portrait.equipment_color(portrait.equipment_profile.weapon, Color.WHITE) == Color("#d789ff"), "hunter visor inherits equipped weapon rarity")
	check(portrait.planet_loadout_color("cassino_quasar") == Color("#ff75d8"), "matching planetary kit resolves a stable visual accent")
	check(portrait.planet_loadout_color("unknown") == Color("#55e5ff"), "unknown equipment origins keep the hunter fallback palette")
	check(portrait.species_skin_color("synthetic") != portrait.species_skin_color("terran"), "species identity changes the hunter face palette")
	check(portrait.species_accent_color("starworn") == Color("#b8f45d"), "species identity resolves a stable non-combat accent")
	var visual_species := ["terran", "synthetic", "starworn", "fungoid", "abyssal", "mothari", "scraproot", "glitchlight"]
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
	var target_visuals := {}
	var pending_user_art := 0
	for target in ContentDB.TARGETS:
		portrait.character_id = str(target.id)
		var visual_id := portrait.visual_identity_id()
		if str(target.get("visual_delivery", "")) == "pending_user_asset":
			pending_user_art += 1
			check(visual_id == "fallback" and not Catalog.asset_path("target_portrait", str(target.id)).is_empty(), "target %s keeps an explicit deterministic user-art delivery path" % str(target.id))
		else:
			check(visual_id != "fallback", "target %s owns an authored procedural portrait" % str(target.id))
			target_visuals[visual_id] = true
	check(target_visuals.size() == ContentDB.TARGETS.size() - pending_user_art, "every completed target resolves a stable individual visual identity")
	check(pending_user_art == 56, "the level-50 through level-180 packs record exactly fifty-six pending user-authored portraits")
	portrait.queue_free()
	if failures == 0:
		print("PASS: hunter loadout, completed portraits, and pending user-art boundaries are explicit")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
