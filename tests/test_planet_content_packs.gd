extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const PackContract = preload("res://scripts/content/planet_content_pack.gd")
const Registry = preload("res://scripts/content/content_pack_registry.gd")
const Dustball = preload("res://scripts/content/packs/dustball_prime.gd")

var failures := 0


func _init() -> void:
	check(Registry.validation_errors().is_empty(), "registered planet packs satisfy the complete content contract")
	check(Registry.PACK_SCRIPTS.size() == 1, "the incremental migration starts with one canonical pack")
	check(Registry.pack_for_planet("dustball_prime") == Dustball.PACK, "registry resolves the canonical Dustball pack")
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
		print("PASS: modular planet packs preserve the canonical Dustball content exactly")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
