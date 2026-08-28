extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const PackContract = preload("res://scripts/content/planet_content_pack.gd")
const Registry = preload("res://scripts/content/content_pack_registry.gd")
const Dustball = preload("res://scripts/content/packs/dustball_prime.gd")
const Congelaria = preload("res://scripts/content/packs/congelaria_sa.gd")
const Micelia = preload("res://scripts/content/packs/micelia_404.gd")

var failures := 0


func _init() -> void:
	check(Registry.validation_errors().is_empty(), "registered planet packs satisfy the complete content contract")
	check(Registry.PACK_SCRIPTS.size() == 3, "the registry contains the first three canonical planet packs")
	check(Registry.pack_for_planet("dustball_prime") == Dustball.PACK, "registry resolves the canonical Dustball pack")
	check(Registry.pack_for_planet("congelaria_sa") == Congelaria.PACK, "registry resolves the canonical Congelaria pack")
	check(Registry.pack_for_planet("micelia_404") == Micelia.PACK, "registry resolves the canonical Micelia pack")
	check(Registry.pack_for_planet("unknown").is_empty(), "unknown planet packs fail closed")
	var detached := Registry.pack_for_planet("dustball_prime")
	detached.planet.name = "MUTATED"
	check(str(Registry.pack_for_planet("dustball_prime").planet.name) == "Dustball Prime", "registry callers cannot mutate canonical pack data")

	check(Content.PLANET == Dustball.PLANET, "ContentDB preserves the public starter planet constant")
	check(Content.ITEM_CATALOG == Dustball.ITEMS, "ContentDB preserves the starter item catalog")
	check(Content.TARGETS.slice(0, 4) == Dustball.TARGETS, "ContentDB preserves all four starter targets in canonical order")
	check(Content.HUNT_EVENTS.slice(0, 2) == Dustball.EVENTS, "ContentDB preserves both starter incidents in canonical order")
	check([Content.TARGETS[0].power, Content.TARGETS[1].power, Content.TARGETS[2].power, Content.TARGETS[3].power] == [11, 16, 23, 28], "starter combat anchors remain unchanged")
	check([Content.TARGETS[0].credits, Content.TARGETS[1].credits, Content.TARGETS[2].credits, Content.TARGETS[3].credits] == [38, 58, 88, 138], "starter economy anchors remain unchanged")

	check(Content.PLANETS.slice(1, 3) == [Congelaria.PLANET, Micelia.PLANET], "ContentDB preserves the next two planets in canonical order")
	check(Content.TARGETS.slice(4, 8) == Congelaria.TARGETS, "ContentDB preserves all four Congelaria targets")
	check(Content.TARGETS.slice(8, 12) == Micelia.TARGETS, "ContentDB preserves all four Micelia targets")
	check(Content.HUNT_EVENTS.slice(2, 4) == Congelaria.EVENTS, "ContentDB preserves both Congelaria incidents")
	check(Content.HUNT_EVENTS.slice(4, 6) == Micelia.EVENTS, "ContentDB preserves both Micelia incidents")
	check(Content.PLANET_ITEM_CATALOGS.congelaria_sa == Congelaria.ITEMS, "Congelaria primary equipment remains canonical")
	check(Content.PLANET_ITEM_CATALOGS.micelia_404 == Micelia.ITEMS, "Micelia primary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.congelaria_sa == Congelaria.SECONDARY_ITEMS, "Congelaria helmet catalog remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.micelia_404 == Micelia.SECONDARY_ITEMS, "Micelia helmet and gloves catalogs remain canonical")
	check(Content.loot_slots_for_planet("congelaria_sa") == ["weapon", "weapon", "weapon", "armor", "armor", "helmet"], "Congelaria introduces only helmets")
	check(Content.loot_slots_for_planet("micelia_404") == ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves"], "Micelia adds gloves without removing helmets")
	check([Congelaria.TARGETS[0].power, Congelaria.TARGETS[3].power, Micelia.TARGETS[0].power, Micelia.TARGETS[3].power] == [31, 45, 47, 69], "mid-campaign combat anchors remain unchanged")

	var forged := Dustball.PACK.duplicate(true)
	forged.targets.pop_back()
	check(not PackContract.is_valid(forged), "incomplete planet packs are rejected")
	forged = Dustball.PACK.duplicate(true)
	forged.events[0].planet_id = "other_world"
	check(not PackContract.is_valid(forged), "cross-planet incident leakage is rejected")
	forged = Dustball.PACK.duplicate(true)
	forged.targets[0].id = "../unsafe"
	check(not PackContract.is_valid(forged), "unsafe content ids are rejected")
	forged = Dustball.PACK.duplicate(true)
	forged.events = "not_an_array"
	check(not PackContract.is_valid(forged), "malformed top-level sections fail closed")
	forged = Dustball.PACK.duplicate(true)
	forged.secondary_items = {"helmet": "not_an_array"}
	check(not PackContract.is_valid(forged), "malformed secondary catalogs fail closed")
	forged = Dustball.PACK.duplicate(true)
	forged.targets[0].boss = true
	forged.targets[3].erase("boss")
	check(not PackContract.is_valid(forged), "planet bosses are reserved for tier three")

	if failures == 0:
		print("PASS: the first three modular planet packs preserve canonical content and slot progression")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
