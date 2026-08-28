extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const PackContract = preload("res://scripts/content/planet_content_pack.gd")
const Registry = preload("res://scripts/content/content_pack_registry.gd")
const Dustball = preload("res://scripts/content/packs/dustball_prime.gd")
const Congelaria = preload("res://scripts/content/packs/congelaria_sa.gd")
const Micelia = preload("res://scripts/content/packs/micelia_404.gd")
const FerroVelho = preload("res://scripts/content/packs/ferro_velho_omega.gd")
const Cassino = preload("res://scripts/content/packs/cassino_quasar.gd")
const Aeropolis = preload("res://scripts/content/packs/aeropolis_penhora.gd")
const ArquivoAbissal = preload("res://scripts/content/packs/arquivo_abissal_n9.gd")
const Verdantia = preload("res://scripts/content/packs/verdantia_patenteada.gd")
const Caldeira = preload("res://scripts/content/packs/caldeira_garantia.gd")

var failures := 0


func _init() -> void:
	check(Registry.validation_errors().is_empty(), "registered planet packs satisfy the complete content contract")
	check(Registry.PACK_SCRIPTS.size() == 9, "the registry contains all nine current canonical planet packs")
	check(Registry.PLANETS.size() == 9, "the registry composes all nine planets")
	check(Registry.TARGETS.size() == 36, "the registry composes all 36 targets")
	check(Registry.HUNT_EVENTS.size() == 18, "the registry composes all 18 hunt incidents")
	check(Registry.pack_for_planet("dustball_prime") == Dustball.PACK, "registry resolves the canonical Dustball pack")
	check(Registry.pack_for_planet("congelaria_sa") == Congelaria.PACK, "registry resolves the canonical Congelaria pack")
	check(Registry.pack_for_planet("micelia_404") == Micelia.PACK, "registry resolves the canonical Micelia pack")
	check(Registry.pack_for_planet("ferro_velho_omega") == FerroVelho.PACK, "registry resolves the canonical Ferro-Velho pack")
	check(Registry.pack_for_planet("cassino_quasar") == Cassino.PACK, "registry resolves the canonical Cassino pack")
	check(Registry.pack_for_planet("aeropolis_penhora") == Aeropolis.PACK, "registry resolves the canonical Aeropolis pack")
	check(Registry.pack_for_planet("arquivo_abissal_n9") == ArquivoAbissal.PACK, "registry resolves the canonical Arquivo Abissal pack")
	check(Registry.pack_for_planet("verdantia_patenteada") == Verdantia.PACK, "registry resolves the canonical Verdantia pack")
	check(Registry.pack_for_planet("caldeira_garantia") == Caldeira.PACK, "registry resolves the canonical Warranty Caldera pack")
	check(Registry.pack_for_planet("unknown").is_empty(), "unknown planet packs fail closed")
	var detached := Registry.pack_for_planet("dustball_prime")
	detached.planet.name = "MUTATED"
	check(str(Registry.pack_for_planet("dustball_prime").planet.name) == "Dustball Prime", "registry callers cannot mutate canonical pack data")

	check(Content.PLANET == Dustball.PLANET, "ContentDB preserves the public starter planet constant")
	check(Content.PLANETS == Registry.PLANETS, "ContentDB exposes the registry's canonical planet composition")
	check(Content.TARGETS == Registry.TARGETS, "ContentDB exposes the registry's canonical target composition")
	check(Content.HUNT_EVENTS == Registry.HUNT_EVENTS, "ContentDB exposes the registry's canonical incident composition")
	check(Content.ITEM_CATALOG == Dustball.ITEMS, "ContentDB preserves the starter item catalog")
	check(Content.ITEM_CATALOG == Registry.STARTER_ITEM_CATALOG, "ContentDB exposes the registry's starter item catalog")
	check(Content.PLANET_ITEM_CATALOGS == Registry.PLANET_ITEM_CATALOGS, "ContentDB exposes the registry's primary item catalogs")
	check(Content.SECONDARY_ITEM_CATALOGS == Registry.SECONDARY_ITEM_CATALOGS, "ContentDB exposes the registry's secondary item catalogs")
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

	check(Content.PLANETS.slice(3, 5) == [FerroVelho.PLANET, Cassino.PLANET], "ContentDB preserves both intermediate planets in canonical order")
	check(Content.TARGETS.slice(12, 16) == FerroVelho.TARGETS, "ContentDB preserves all four Ferro-Velho targets")
	check(Content.TARGETS.slice(16, 20) == Cassino.TARGETS, "ContentDB preserves all four Cassino targets")
	check(Content.HUNT_EVENTS.slice(6, 8) == FerroVelho.EVENTS, "ContentDB preserves both Ferro-Velho incidents")
	check(Content.HUNT_EVENTS.slice(8, 10) == Cassino.EVENTS, "ContentDB preserves both Cassino incidents")
	check(Content.PLANET_ITEM_CATALOGS.ferro_velho_omega == FerroVelho.ITEMS, "Ferro-Velho primary equipment remains canonical")
	check(Content.PLANET_ITEM_CATALOGS.cassino_quasar == Cassino.ITEMS, "Cassino primary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.ferro_velho_omega == FerroVelho.SECONDARY_ITEMS, "Ferro-Velho secondary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.cassino_quasar == Cassino.SECONDARY_ITEMS, "Cassino secondary equipment remains canonical")
	var intermediate_slots := ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves", "boots"]
	check(Content.loot_slots_for_planet("ferro_velho_omega") == intermediate_slots, "Ferro-Velho completes the first universal secondary loadout")
	check(Content.loot_slots_for_planet("cassino_quasar") == intermediate_slots, "Cassino deepens the loadout without opening a surprise slot")
	check(FerroVelho.SECONDARY_ITEMS.keys() == Cassino.SECONDARY_ITEMS.keys(), "intermediate packs expose the same secondary slot surface")
	check([FerroVelho.TARGETS[0].power, FerroVelho.TARGETS[3].power, Cassino.TARGETS[0].power, Cassino.TARGETS[3].power] == [69, 90, 96, 124], "intermediate combat anchors remain unchanged")

	check(Content.PLANETS.slice(5, 7) == [Aeropolis.PLANET, ArquivoAbissal.PLANET], "ContentDB preserves both late planets in canonical order")
	check(Content.TARGETS.slice(20, 24) == Aeropolis.TARGETS, "ContentDB preserves all four Aeropolis targets")
	check(Content.TARGETS.slice(24, 28) == ArquivoAbissal.TARGETS, "ContentDB preserves all four Arquivo Abissal targets")
	check(Content.HUNT_EVENTS.slice(10, 12) == Aeropolis.EVENTS, "ContentDB preserves both Aeropolis incidents")
	check(Content.HUNT_EVENTS.slice(12, 14) == ArquivoAbissal.EVENTS, "ContentDB preserves both Arquivo Abissal incidents")
	check(Content.PLANET_ITEM_CATALOGS.aeropolis_penhora == Aeropolis.ITEMS, "Aeropolis primary equipment remains canonical")
	check(Content.PLANET_ITEM_CATALOGS.arquivo_abissal_n9 == ArquivoAbissal.ITEMS, "Arquivo Abissal primary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.aeropolis_penhora == Aeropolis.SECONDARY_ITEMS, "Aeropolis rig catalog remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.arquivo_abissal_n9 == ArquivoAbissal.SECONDARY_ITEMS, "Arquivo Abissal implant catalog remains canonical")
	check(Aeropolis.SECONDARY_ITEMS.keys() == ["rig"], "Aeropolis exposes only its late rig branch")
	check(ArquivoAbissal.SECONDARY_ITEMS.keys() == ["implant"], "Arquivo Abissal exposes only its late implant branch")
	check(Content.loot_slots_for_planet("aeropolis_penhora") == ["weapon", "weapon", "weapon", "armor", "armor", "rig", "rig"], "Aeropolis weights rigs without leaking intermediate slots")
	check(Content.loot_slots_for_planet("arquivo_abissal_n9") == ["weapon", "weapon", "weapon", "armor", "armor", "implant", "implant"], "Arquivo Abissal weights implants without leaking rigs")
	check([Aeropolis.TARGETS[0].power, Aeropolis.TARGETS[3].power, ArquivoAbissal.TARGETS[0].power, ArquivoAbissal.TARGETS[3].power] == [136, 175, 190, 245], "late combat anchors remain unchanged")

	check(Content.PLANETS[7] == Verdantia.PLANET, "the level-50 planet follows Arquivo Abissal in canonical order")
	check(Content.TARGETS.slice(28, 32) == Verdantia.TARGETS, "ContentDB exposes all four Verdantia targets")
	check(Content.HUNT_EVENTS.slice(14, 16) == Verdantia.EVENTS, "ContentDB exposes both Verdantia incidents")
	check(Content.PLANET_ITEM_CATALOGS.verdantia_patenteada == Verdantia.ITEMS, "Verdantia primary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.verdantia_patenteada == Verdantia.SECONDARY_ITEMS, "Verdantia boot catalog remains canonical")
	check(Content.loot_slots_for_planet("verdantia_patenteada") == ["weapon", "weapon", "weapon", "armor", "armor", "boots", "boots"], "Verdantia deepens boots without opening Rift-only slots")
	check([Verdantia.TARGETS[0].power, Verdantia.TARGETS[3].power] == [250, 282], "level-50 combat anchors are explicit")
	check(Verdantia.TARGETS.all(func(target): return str(target.get("visual_delivery", "")) == "pending_user_asset"), "new target art remains explicitly assigned to the user asset pipeline")

	check(Content.PLANETS[8] == Caldeira.PLANET, "the level-60 planet follows Verdantia in canonical order")
	check(Content.TARGETS.slice(32, 36) == Caldeira.TARGETS, "ContentDB exposes all four Caldera targets")
	check(Content.HUNT_EVENTS.slice(16, 18) == Caldeira.EVENTS, "ContentDB exposes both Caldera incidents")
	check(Content.PLANET_ITEM_CATALOGS.caldeira_garantia == Caldeira.ITEMS, "Caldera primary equipment remains canonical")
	check(Content.SECONDARY_ITEM_CATALOGS.caldeira_garantia == Caldeira.SECONDARY_ITEMS, "Caldera glove catalog remains canonical")
	check(Content.loot_slots_for_planet("caldeira_garantia") == ["weapon", "weapon", "weapon", "armor", "armor", "gloves", "gloves"], "Caldera deepens gloves without opening Rift-only slots")
	check([Caldeira.TARGETS[0].power, Caldeira.TARGETS[3].power] == [290, 324], "level-60 combat anchors are explicit")
	check(Caldeira.TARGETS.all(func(target): return str(target.get("visual_delivery", "")) == "pending_user_asset"), "Caldera target art remains explicitly assigned to the user asset pipeline")

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
		print("PASS: all nine current planet packs preserve canonical content and slot progression")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
