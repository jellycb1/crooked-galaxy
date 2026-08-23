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
	for slot in ["weapon", "armor"]:
		check(ContentDB.ITEM_TRAITS.has(slot) and ContentDB.ITEM_TRAITS[slot].size() >= 3, "equipment slot has modification variety: %s" % slot)
		for modification in ContentDB.ITEM_TRAITS[slot]:
			var trait_id := str(modification.get("id", ""))
			check(not trait_id.is_empty() and not trait_ids.has(trait_id), "equipment modification id is unique: %s" % trait_id)
			trait_ids[trait_id] = true
			check(int(modification.get("power_bonus", 0)) > 0 or int(modification.get("health_bonus", 0)) > 0 or int(modification.get("opening_damage_bonus", 0)) > 0 or int(modification.get("damage_reduction", 0)) > 0, "equipment modification has a mechanical effect: %s" % trait_id)

	check(ContentDB.CONTRACT_APPROACHES.size() == 3, "every contract keeps three strategic approaches")
	check(int(ContentDB.CONTRACT_APPROACHES[0].get("scrap_reward", 0)) == 0 and int(ContentDB.CONTRACT_APPROACHES[1].get("scrap_reward", 0)) == 0 and int(ContentDB.CONTRACT_APPROACHES[2].get("scrap_reward", 0)) == 2, "only the high-risk corporate warrant funds the workshop")
	var dustball_premium := ContentDB.apply_approach(ContentDB.TARGETS[1], ContentDB.CONTRACT_APPROACHES[2])
	var omega_premium := ContentDB.apply_approach(ContentDB.TARGETS[13], ContentDB.CONTRACT_APPROACHES[2])
	check(int(omega_premium.scrap_reward) == 2, "corporate scrap reward survives contract application")
	check(int(dustball_premium.power) == roundi(float(ContentDB.TARGETS[1].power) * 1.18), "first-chapter risk calibration remains stable")
	check(int(omega_premium.power) == roundi(float(ContentDB.TARGETS[13].power) * 1.18), "contract danger remains consistent across frontiers")
	var base_loot_rng := RandomNumberGenerator.new()
	var premium_loot_rng := RandomNumberGenerator.new()
	base_loot_rng.seed = 4417
	premium_loot_rng.seed = 4417
	var canonical_omega_loot := ContentDB.generate_loot(ContentDB.TARGETS[13], base_loot_rng)
	var premium_omega_loot := ContentDB.generate_loot(omega_premium, premium_loot_rng)
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
