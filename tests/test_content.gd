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
	check(ContentDB.procedural_collection_total() == 560, "eight authored planet packs expose the documented bounded 560-series catalog")
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
