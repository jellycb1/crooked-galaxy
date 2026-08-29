extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")

var failures := 0


func _init() -> void:
	for index in Content.PLANETS.size():
		var canonical_planet: Dictionary = Content.PLANETS[index]
		var planet_id := str(canonical_planet.id)
		check(Content.get_planet(planet_id) == canonical_planet, "planet index preserves canonical data for %s" % planet_id)
		check(Content.planet_index_for(planet_id) == index, "planet index preserves authored order for %s" % planet_id)
		var expected_targets: Array[Dictionary] = []
		for canonical_target in Content.TARGETS:
			if str(canonical_target.get("planet_id", "")) == planet_id:
				expected_targets.append(canonical_target)
		var indexed_targets := Content.targets_for_planet(planet_id)
		check(indexed_targets == expected_targets, "planet target index preserves authored order for %s" % planet_id)
		check(Content.target_count_for_planet(planet_id) == expected_targets.size(), "planet target count resolves without allocating copies for %s" % planet_id)
		check(MissionRules.targets_for_planet(planet_id) == expected_targets, "mission rules use the canonical target index for %s" % planet_id)
		for target in expected_targets:
			var target_id := str(target.id)
			var tier := int(target.chapter_tier)
			check(Content.get_target(target_id) == target, "target id index resolves %s" % target_id)
			check(Content.target_for_planet_tier(planet_id, tier) == target, "planet tier index resolves %s" % target_id)

	check(Content.get_planet("missing_planet") == Content.PLANET, "unknown planets retain the starter fallback contract")
	check(Content.planet_index_for("missing_planet") == 0, "unknown planet indices retain the starter fallback contract")
	check(Content.get_target("missing_target").is_empty(), "unknown target ids remain empty")
	check(Content.targets_for_planet("missing_planet").is_empty(), "unknown planet target lists remain empty")
	check(Content.target_for_planet_tier("missing_planet", 0).is_empty(), "unknown planet tiers remain empty")
	check(Content.highest_target_rank() == Content.TARGETS.reduce(func(highest, target): return maxi(int(highest), int(target.rank)), 0), "highest target rank is derived from the complete canonical catalog")
	check(MissionRules.available_planet_count(1) == MissionRules.available_planets(1).size(), "starter available count matches the allocating API")
	check(MissionRules.available_planet_count(int(Content.PLANETS[-1].unlock_level)) == Content.PLANETS.size(), "mature available count includes the complete catalog")

	var planet_copy := Content.get_planet(str(Content.PLANETS[0].id))
	planet_copy["name"] = "MUTATED"
	check(str(Content.get_planet(str(Content.PLANETS[0].id)).name) != "MUTATED", "planet lookups return defensive copies")
	var target_copy := Content.get_target(str(Content.TARGETS[0].id))
	target_copy["name"] = "MUTATED"
	check(str(Content.get_target(str(Content.TARGETS[0].id)).name) != "MUTATED", "target lookups return defensive copies")
	var targets_copy := Content.targets_for_planet(str(Content.PLANETS[0].id))
	targets_copy[0]["name"] = "MUTATED"
	targets_copy.clear()
	check(Content.targets_for_planet(str(Content.PLANETS[0].id)).size() == 4 and str(Content.targets_for_planet(str(Content.PLANETS[0].id))[0].name) != "MUTATED", "planet target lists and entries are defensive copies")
	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = 41021
	var event_copy := Content.random_hunt_event(event_rng, str(Content.PLANETS[0].id))
	var event_id := str(event_copy.id)
	var canonical_choice: Dictionary = event_copy.choices[0]
	var indexed_choice := Content.hunt_choice(str(canonical_choice.id))
	check(str(indexed_choice.event_id) == event_id and indexed_choice.choice == canonical_choice, "incident choice id resolves its owning event and canonical choice")
	indexed_choice.choice["mutation_probe"] = true
	check(not Content.hunt_choice(str(canonical_choice.id)).choice.has("mutation_probe"), "incident choice lookup returns a defensive deep copy")
	event_copy["mutation_probe"] = true
	event_rng.seed = 41021
	var event_again := Content.random_hunt_event(event_rng, str(Content.PLANETS[0].id))
	check(str(event_again.id) == event_id and not event_again.has("mutation_probe"), "incident lookup returns a defensive copy without changing seeded selection")
	check(Content.hunt_choice("missing_choice").is_empty(), "unknown incident choice ids remain empty")

	if failures == 0:
		print("PASS: indexed content lookups preserve behavior and mutation safety")
		quit(0)
	else:
		printerr("FAIL: %d indexed content lookup issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
