extends SceneTree

var failures := 0


func _init() -> void:
	var planet_ids := {}
	for planet in ContentDB.PLANETS:
		var planet_id := str(planet.get("id", ""))
		check(not planet_id.is_empty(), "planet has a stable id")
		check(not planet_ids.has(planet_id), "planet id is unique: %s" % planet_id)
		planet_ids[planet_id] = true
		check(not str(planet.get("name", "")).is_empty(), "planet has a name: %s" % planet_id)
		check(not str(planet.get("accent", "")).is_empty(), "planet has an accent: %s" % planet_id)
		var unlock_after := str(planet.get("unlock_after", ""))
		check(unlock_after.is_empty() or planet_ids.has(unlock_after), "planet unlock chain points backward: %s" % planet_id)

	var target_ids := {}
	for planet in ContentDB.PLANETS:
		var planet_id := str(planet.id)
		var tier_counts := [0, 0, 0, 0]
		var boss_count := 0
		for target in ContentDB.TARGETS:
			if str(target.get("planet_id", "")) != planet_id:
				continue
			var target_id := str(target.get("id", ""))
			check(not target_id.is_empty() and not target_ids.has(target_id), "target id is unique: %s" % target_id)
			target_ids[target_id] = true
			var tier := int(target.get("chapter_tier", -1))
			check(tier >= 0 and tier <= 3, "target tier is valid: %s" % target_id)
			if tier >= 0 and tier <= 3:
				tier_counts[tier] += 1
			check(int(target.get("power", 0)) > 0 and int(target.get("health", 0)) > 0, "target combat stats are positive: %s" % target_id)
			check(not target.get("attacks", []).is_empty(), "target has named attacks: %s" % target_id)
			if bool(target.get("boss", false)):
				boss_count += 1
		check(tier_counts == [1, 1, 1, 1], "planet has exactly one target per tier: %s" % planet_id)
		check(boss_count == 1, "planet has exactly one boss: %s" % planet_id)

	var event_ids := {}
	for planet in ContentDB.PLANETS:
		var event_count := 0
		for event in ContentDB.HUNT_EVENTS:
			if str(event.get("planet_id", "")) != str(planet.id):
				continue
			event_count += 1
			var event_id := str(event.get("id", ""))
			check(not event_id.is_empty() and not event_ids.has(event_id), "event id is unique: %s" % event_id)
			event_ids[event_id] = true
			check(event.get("choices", []).size() == 3, "event has three choices: %s" % event_id)
			check(not str(event.get("symbol", "")).is_empty(), "event has a UI symbol: %s" % event_id)
		check(event_count >= 2, "planet has at least two hunt incidents: %s" % str(planet.id))

	for planet in ContentDB.PLANETS:
		if str(planet.id) == ContentDB.PLANET.id:
			continue
		var family: Dictionary = ContentDB.PLANET_ITEM_CATALOGS.get(str(planet.id), {})
		check(family.has("weapon") and family.get("weapon", []).size() >= 4, "planet has a weapon family: %s" % str(planet.id))
		check(family.has("armor") and family.get("armor", []).size() >= 4, "planet has an armor family: %s" % str(planet.id))

	var trait_ids := {}
	for slot in ["weapon", "armor", "helmet", "gloves", "boots", "rig", "implant"]:
		check(ContentDB.ITEM_TRAITS.has(slot) and ContentDB.ITEM_TRAITS[slot].size() >= 3, "equipment slot has modification variety: %s" % slot)
		for modification in ContentDB.ITEM_TRAITS[slot]:
			var trait_id := str(modification.get("id", ""))
			check(not trait_id.is_empty() and not trait_ids.has(trait_id), "equipment modification id is unique: %s" % trait_id)
			trait_ids[trait_id] = true
			check(int(modification.get("power_bonus", 0)) > 0 or int(modification.get("health_bonus", 0)) > 0 or int(modification.get("opening_damage_bonus", 0)) > 0 or int(modification.get("damage_reduction", 0)) > 0, "equipment modification has a mechanical effect: %s" % trait_id)

	check(ContentDB.CONTRACT_APPROACHES.size() == 3, "every contract keeps three strategic approaches")
	check(int(ContentDB.CONTRACT_APPROACHES[0].get("scrap_reward", 0)) == 0 and int(ContentDB.CONTRACT_APPROACHES[1].get("scrap_reward", 0)) == 0 and int(ContentDB.CONTRACT_APPROACHES[2].get("scrap_reward", 0)) == 3, "only the high-risk corporate warrant funds the workshop")
	var dustball_premium := ContentDB.apply_approach(ContentDB.TARGETS[1], ContentDB.CONTRACT_APPROACHES[2])
	var omega_premium := ContentDB.apply_approach(ContentDB.TARGETS[13], ContentDB.CONTRACT_APPROACHES[2])
	check(int(omega_premium.scrap_reward) == 3, "corporate scrap reward survives contract application")
	check(int(dustball_premium.health) > roundi(float(ContentDB.TARGETS[1].health) * float(ContentDB.CONTRACT_APPROACHES[2].health_mult)), "high-risk routes retain extra pressure while frontier stats are still small")
	check(int(omega_premium.health) > roundi(float(ContentDB.TARGETS[13].health) * float(ContentDB.CONTRACT_APPROACHES[2].health_mult)), "aggressive contract resistance grows across later planets")
	check(int(omega_premium.loot_power) == int(ContentDB.TARGETS[13].power), "late route pressure never inflates its equipment tier")
	check(int(dustball_premium.power) == roundi(float(ContentDB.TARGETS[1].power) * float(ContentDB.CONTRACT_APPROACHES[2].power_mult)), "first-chapter risk calibration remains stable")
	check(int(omega_premium.power) == roundi(float(ContentDB.TARGETS[13].power) * float(ContentDB.CONTRACT_APPROACHES[2].power_mult)), "contract attack pressure remains consistent across frontiers")
	var base_loot_rng := RandomNumberGenerator.new()
	var premium_loot_rng := RandomNumberGenerator.new()
	base_loot_rng.seed = 4417
	premium_loot_rng.seed = 4417
	var canonical_omega_loot := ContentDB.generate_loot(ContentDB.TARGETS[13], base_loot_rng)
	var premium_omega_loot := ContentDB.generate_loot(omega_premium, premium_loot_rng)
	check(not str(canonical_omega_loot.get("template_id", "")).is_empty() and int(canonical_omega_loot.get("item_level", 0)) >= 1, "generated equipment records its stable template family and item level")
	check(int(canonical_omega_loot.get("quality", 0)) >= 1 and int(canonical_omega_loot.get("quality", 0)) <= 100 and not str(canonical_omega_loot.get("variant_id", "")).is_empty(), "generated equipment records bounded quality and a visual variant")
	check(canonical_omega_loot.has("generation_seed"), "generated equipment persists a reproducible instance seed")
	check(ContentDB.procedural_collection_ids().size() >= 100 and ContentDB.procedural_collection_ids().all(func(id): return str(id).contains("::")), "finite template families expose a bounded multi-variant collection catalog")
	check(ContentDB.procedural_collection_entries().size() * 5 == ContentDB.procedural_collection_ids().size(), "every collectible template exposes exactly the five canonical series variants")
	check(ContentDB.procedural_collection_total() == ContentDB.procedural_collection_ids().size(), "hot collection counts avoid rebuilding or exposing the canonical identifier cache")
	check(ContentDB.procedural_collection_total() == 1640, "twenty-six authored planet packs expose the documented bounded 1640-series catalog")
	check(int(premium_omega_loot.power) == int(canonical_omega_loot.power), "contract danger does not inflate the dropped equipment tier")
	check(str(ContentDB.target_for_planet_tier("dustball_prime", 1).id) == "baron_boom", "planet tier resolves the next warrant deterministically")
	check(ContentDB.planet_tier_from_target_captures("dustball_prime", {"gloop": 9}) == 1, "farming the first warrant cannot skip sequential tiers")
	check(ContentDB.planet_tier_from_target_captures("dustball_prime", {"gloop": 3, "baron_boom": 3, "madame_vacuum": 3}) == 3, "three captures of each prerequisite unlock the boss")
	var warrant_progress := ContentDB.warrant_progress("dustball_prime", {"gloop": 3, "baron_boom": 2})
	check(str(warrant_progress.next_target.id) == "madame_vacuum" and int(warrant_progress.progress) == 2, "warrant progress names the exact prerequisite target")
	check(ContentDB.target_for_planet_tier("missing_planet", 1).is_empty(), "unknown planet tiers fail safely")
	var promoted_loot := 0
	for seed in 240:
		var base_rng := RandomNumberGenerator.new()
		base_rng.seed = seed + 1000
		var mastery_rng := RandomNumberGenerator.new()
		mastery_rng.seed = seed + 1000
		var base_loot := ContentDB.generate_loot(ContentDB.TARGETS[0], base_rng, 0)
		var mastery_loot := ContentDB.generate_loot(ContentDB.TARGETS[0], mastery_rng, 3)
		check(str(base_loot.origin_planet_id) == "dustball_prime" and str(mastery_loot.origin_planet_id) == "dustball_prime", "generated loot keeps a valid origin for seed %d" % seed)
		check(rarity_weight(str(mastery_loot.rarity)) >= rarity_weight(str(base_loot.rarity)), "mastery never lowers loot rarity for seed %d" % seed)
		if rarity_weight(str(mastery_loot.rarity)) > rarity_weight(str(base_loot.rarity)):
			promoted_loot += 1
	check(promoted_loot > 0, "maximum mastery promotes deterministic loot rolls")
	check(ContentDB.loot_slots_for_planet("dustball_prime").all(func(slot): return slot == "weapon" or slot == "armor"), "Dustball keeps the two-slot loot tutorial")
	check(ContentDB.loot_slots_for_planet("congelaria_sa").has("helmet") and not ContentDB.loot_slots_for_planet("congelaria_sa").has("gloves"), "Congelária introduces helmets without opening later slots early")
	check(ContentDB.loot_slots_for_planet("micelia_404").has("gloves") and not ContentDB.loot_slots_for_planet("micelia_404").has("boots"), "Micélia introduces gloves after helmets")
	check(ContentDB.loot_slots_for_planet("ferro_velho_omega").has("boots"), "Ferro-Velho completes the first secondary equipment layer")
	check(ContentDB.loot_slots_for_planet("aeropolis_penhora").has("rig") and not ContentDB.loot_slots_for_planet("aeropolis_penhora").has("implant"), "Aeropolis introduces rigs without leaking the next year-one equipment family")
	check(ContentDB.loot_slots_for_planet("arquivo_abissal_n9").has("implant") and not ContentDB.loot_slots_for_planet("arquivo_abissal_n9").has("gadget"), "Abyssal Archive introduces implants without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("verdantia_patenteada").has("boots") and not ContentDB.loot_slots_for_planet("verdantia_patenteada").has("gadget"), "Patent Verdantia deepens universal boots without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("caldeira_garantia").has("gloves") and not ContentDB.loot_slots_for_planet("caldeira_garantia").has("gadget"), "Warranty Caldera deepens universal gloves without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("condominio_lunar_7").has("helmet") and not ContentDB.loot_slots_for_planet("condominio_lunar_7").has("gadget"), "Lunar Estate deepens universal helmets without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("necropole_solar_umbral").has("rig") and not ContentDB.loot_slots_for_planet("necropole_solar_umbral").has("gadget"), "Solar Necropolis deepens universal rigs without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("central_tempestades_24h").has("implant") and not ContentDB.loot_slots_for_planet("central_tempestades_24h").has("gadget"), "Storm Center deepens universal implants without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("museu_amanha_obsoleto").has("boots") and not ContentDB.loot_slots_for_planet("museu_amanha_obsoleto").has("gadget"), "Obsolete Tomorrow deepens universal boots without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("biblioteca_silencio_taxado").has("gloves") and not ContentDB.loot_slots_for_planet("biblioteca_silencio_taxado").has("gadget"), "Taxed Silence deepens universal gloves without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("resort_horizonte_eventos").has("helmet") and not ContentDB.loot_slots_for_planet("resort_horizonte_eventos").has("gadget"), "Event Horizon Resort deepens universal helmets without leaking Rift-only equipment families")
	check(ContentDB.loot_slots_for_planet("tribunal_clones_nao_autorizados").has("rig") and not ContentDB.loot_slots_for_planet("tribunal_clones_nao_autorizados").has("gadget"), "Unauthorized Clone Court deepens universal rigs without leaking Rift-only equipment families")
	var aerial_rng := RandomNumberGenerator.new()
	aerial_rng.seed = 303030
	var aerial_rig := ContentDB.generate_loot(ContentDB.TARGETS[20], aerial_rng, 3, "rig")
	check(str(aerial_rig.slot) == "rig" and str(aerial_rig.origin_planet_id) == "aeropolis_penhora" and not str(aerial_rig.name).is_empty(), "the level-30 pack produces canonical themed rig equipment")
	var abyssal_rng := RandomNumberGenerator.new()
	abyssal_rng.seed = 404040
	var abyssal_implant := ContentDB.generate_loot(ContentDB.TARGETS[24], abyssal_rng, 3, "implant")
	check(str(abyssal_implant.slot) == "implant" and str(abyssal_implant.origin_planet_id) == "arquivo_abissal_n9" and not str(abyssal_implant.name).is_empty(), "the level-40 pack produces canonical themed implant equipment")
	var verdantia_rng := RandomNumberGenerator.new()
	verdantia_rng.seed = 505050
	var verdantia_boots := ContentDB.generate_loot(ContentDB.TARGETS[28], verdantia_rng, 3, "boots")
	check(str(verdantia_boots.slot) == "boots" and str(verdantia_boots.origin_planet_id) == "verdantia_patenteada" and not str(verdantia_boots.name).is_empty(), "the level-50 pack produces canonical themed boot equipment")
	var caldeira_rng := RandomNumberGenerator.new()
	caldeira_rng.seed = 606060
	var caldeira_gloves := ContentDB.generate_loot(ContentDB.TARGETS[32], caldeira_rng, 3, "gloves")
	check(str(caldeira_gloves.slot) == "gloves" and str(caldeira_gloves.origin_planet_id) == "caldeira_garantia" and not str(caldeira_gloves.name).is_empty(), "the level-60 pack produces canonical themed glove equipment")
	var lunar_rng := RandomNumberGenerator.new()
	lunar_rng.seed = 707070
	var lunar_helmet := ContentDB.generate_loot(ContentDB.TARGETS[36], lunar_rng, 3, "helmet")
	check(str(lunar_helmet.slot) == "helmet" and str(lunar_helmet.origin_planet_id) == "condominio_lunar_7" and not str(lunar_helmet.name).is_empty(), "the level-70 pack produces canonical themed helmet equipment")
	var solar_rng := RandomNumberGenerator.new()
	solar_rng.seed = 808080
	var solar_rig := ContentDB.generate_loot(ContentDB.TARGETS[40], solar_rng, 3, "rig")
	check(str(solar_rig.slot) == "rig" and str(solar_rig.origin_planet_id) == "necropole_solar_umbral" and not str(solar_rig.name).is_empty(), "the level-80 pack produces canonical themed rig equipment")
	var storm_rng := RandomNumberGenerator.new()
	storm_rng.seed = 909090
	var storm_implant := ContentDB.generate_loot(ContentDB.TARGETS[44], storm_rng, 3, "implant")
	check(str(storm_implant.slot) == "implant" and str(storm_implant.origin_planet_id) == "central_tempestades_24h" and not str(storm_implant.name).is_empty(), "the level-90 pack produces canonical themed implant equipment")
	var museum_rng := RandomNumberGenerator.new()
	museum_rng.seed = 1000100
	var museum_boots := ContentDB.generate_loot(ContentDB.TARGETS[48], museum_rng, 3, "boots")
	check(str(museum_boots.slot) == "boots" and str(museum_boots.origin_planet_id) == "museu_amanha_obsoleto" and not str(museum_boots.name).is_empty(), "the level-100 pack produces canonical themed boot equipment")
	var library_rng := RandomNumberGenerator.new()
	library_rng.seed = 1100110
	var library_gloves := ContentDB.generate_loot(ContentDB.TARGETS[52], library_rng, 3, "gloves")
	check(str(library_gloves.slot) == "gloves" and str(library_gloves.origin_planet_id) == "biblioteca_silencio_taxado" and not str(library_gloves.name).is_empty(), "the level-110 pack produces canonical themed glove equipment")
	var resort_rng := RandomNumberGenerator.new()
	resort_rng.seed = 1200120
	var resort_helmet := ContentDB.generate_loot(ContentDB.TARGETS[56], resort_rng, 3, "helmet")
	check(str(resort_helmet.slot) == "helmet" and str(resort_helmet.origin_planet_id) == "resort_horizonte_eventos" and not str(resort_helmet.name).is_empty(), "the level-120 pack produces canonical themed helmet equipment")
	var clone_rng := RandomNumberGenerator.new()
	clone_rng.seed = 1300130
	var clone_rig := ContentDB.generate_loot(ContentDB.TARGETS[60], clone_rng, 3, "rig")
	check(str(clone_rig.slot) == "rig" and str(clone_rig.origin_planet_id) == "tribunal_clones_nao_autorizados" and not str(clone_rig.name).is_empty(), "the level-130 pack produces canonical themed rig equipment")
	var monastery_rng := RandomNumberGenerator.new()
	monastery_rng.seed = 1400140
	var monastery_implant := ContentDB.generate_loot(ContentDB.TARGETS[64], monastery_rng, 3, "implant")
	check(str(monastery_implant.slot) == "implant" and str(monastery_implant.origin_planet_id) == "mosteiro_gravidade_reversa" and not str(monastery_implant.name).is_empty(), "the level-140 pack produces canonical themed implant equipment")
	var market_rng := RandomNumberGenerator.new()
	market_rng.seed = 1500150
	var market_boots := ContentDB.generate_loot(ContentDB.TARGETS[68], market_rng, 3, "boots")
	check(str(market_boots.slot) == "boots" and str(market_boots.origin_planet_id) == "mercado_memorias_usadas" and not str(market_boots.name).is_empty(), "the level-150 pack produces canonical themed boot equipment")
	var shipyard_rng := RandomNumberGenerator.new()
	shipyard_rng.seed = 1600160
	var shipyard_gloves := ContentDB.generate_loot(ContentDB.TARGETS[72], shipyard_rng, 3, "gloves")
	check(str(shipyard_gloves.slot) == "gloves" and str(shipyard_gloves.origin_planet_id) == "estaleiro_naufragios_temporais" and not str(shipyard_gloves.name).is_empty(), "the level-160 pack produces canonical themed glove equipment")
	var moon_exchange_rng := RandomNumberGenerator.new()
	moon_exchange_rng.seed = 1700170
	var moon_exchange_helmet := ContentDB.generate_loot(ContentDB.TARGETS[76], moon_exchange_rng, 3, "helmet")
	check(str(moon_exchange_helmet.slot) == "helmet" and str(moon_exchange_helmet.origin_planet_id) == "bolsa_luas_fracionadas" and not str(moon_exchange_helmet.name).is_empty(), "the level-170 pack produces canonical themed helmet equipment")
	var solar_factory_rng := RandomNumberGenerator.new()
	solar_factory_rng.seed = 1800180
	var solar_factory_rig := ContentDB.generate_loot(ContentDB.TARGETS[80], solar_factory_rng, 3, "rig")
	check(str(solar_factory_rig.slot) == "rig" and str(solar_factory_rig.origin_planet_id) == "fabrica_sois_recondicionados" and not str(solar_factory_rig.name).is_empty(), "the level-180 pack produces canonical themed rig equipment")
	var planet_clinic_rng := RandomNumberGenerator.new()
	planet_clinic_rng.seed = 1900190
	var planet_clinic_implant := ContentDB.generate_loot(ContentDB.TARGETS[84], planet_clinic_rng, 3, "implant")
	check(str(planet_clinic_implant.slot) == "implant" and str(planet_clinic_implant.origin_planet_id) == "clinica_planetas_descontinuados" and not str(planet_clinic_implant.name).is_empty(), "the level-190 pack produces canonical themed implant equipment")
	var wormhole_post_rng := RandomNumberGenerator.new()
	wormhole_post_rng.seed = 2000200
	var wormhole_post_boots := ContentDB.generate_loot(ContentDB.TARGETS[88], wormhole_post_rng, 3, "boots")
	check(str(wormhole_post_boots.slot) == "boots" and str(wormhole_post_boots.origin_planet_id) == "correio_buracos_minhoca" and not str(wormhole_post_boots.name).is_empty(), "the level-200 pack produces canonical themed boot equipment")
	var aquarium_rng := RandomNumberGenerator.new()
	aquarium_rng.seed = 2100210
	var aquarium_gloves := ContentDB.generate_loot(ContentDB.TARGETS[92], aquarium_rng, 3, "gloves")
	check(str(aquarium_gloves.slot) == "gloves" and str(aquarium_gloves.origin_planet_id) == "aquario_oceanos_confiscados" and not str(aquarium_gloves.name).is_empty(), "the level-210 pack produces canonical themed glove equipment")
	var dreams_rng := RandomNumberGenerator.new()
	dreams_rng.seed = 2200220
	var dreams_helmet := ContentDB.generate_loot(ContentDB.TARGETS[96], dreams_rng, 3, "helmet")
	check(str(dreams_helmet.slot) == "helmet" and str(dreams_helmet.origin_planet_id) == "central_sonhos_penhorados" and not str(dreams_helmet.name).is_empty(), "the level-220 pack produces canonical themed helmet equipment")
	var kennel_rng := RandomNumberGenerator.new()
	kennel_rng.seed = 2300230
	var kennel_rig := ContentDB.generate_loot(ContentDB.TARGETS[100], kennel_rng, 3, "rig")
	check(str(kennel_rig.slot) == "rig" and str(kennel_rig.origin_planet_id) == "canil_asteroides_domesticos", "the level-230 pack produces canonical themed rig equipment")
	for secondary_case in [
		{"target": ContentDB.TARGETS[4], "slot": "helmet"},
		{"target": ContentDB.TARGETS[8], "slot": "gloves"},
		{"target": ContentDB.TARGETS[12], "slot": "boots"},
	]:
		var secondary_rng := RandomNumberGenerator.new()
		secondary_rng.seed = 9917
		var secondary_item := ContentDB.generate_loot(secondary_case.target, secondary_rng, 3, str(secondary_case.slot))
		check(str(secondary_item.slot) == str(secondary_case.slot) and int(secondary_item.power) <= 2, "%s loot uses its lateral secondary power budget" % str(secondary_case.slot))
		check(not str(secondary_item.name).is_empty() and ContentDB.ITEM_TRAITS.has(str(secondary_item.slot)), "%s loot owns a themed catalog and modification family" % str(secondary_case.slot))
	for frontier_case in [
		{"target": ContentDB.TARGETS[4], "expected": ["weapon", "armor", "helmet"]},
		{"target": ContentDB.TARGETS[8], "expected": ["weapon", "armor", "helmet", "gloves"]},
		{"target": ContentDB.TARGETS[12], "expected": ["weapon", "armor", "helmet", "gloves", "boots"]},
	]:
		var seen_slots := {}
		for seed in 240:
			var frontier_rng := RandomNumberGenerator.new()
			frontier_rng.seed = 7000 + seed
			var frontier_item := ContentDB.generate_loot(frontier_case.target, frontier_rng)
			seen_slots[str(frontier_item.slot)] = true
		check(frontier_case.expected.all(func(slot): return seen_slots.has(slot)), "%s deterministic drops exercise every unlocked equipment family" % str(frontier_case.target.planet_id))
		check(seen_slots.keys().all(func(slot): return frontier_case.expected.has(slot)), "%s drops never leak a future equipment family" % str(frontier_case.target.planet_id))
	if failures == 0:
		print("PASS: all Crooked Galaxy content is internally consistent")
		quit(0)
	else:
		printerr("FAIL: %d content validation issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func rarity_weight(rarity: String) -> int:
	match rarity:
		"Épico":
			return 2
		"Raro":
			return 1
		_:
			return 0
