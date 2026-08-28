extends SceneTree

const MissionRules = preload("res://scripts/mission_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ContentDB = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var starter := MissionRules.board_offers(state.player)
	check(starter.size() == 3, "a fresh hunter receives three mission choices")
	check(starter.all(func(offer): return str(offer.planet_id) == "dustball_prime"), "level one keeps all offers inside the only discovered world")
	check(starter.map(func(offer): return str(offer.mission_role)) == ["safe", "standard", "dangerous"], "the board exposes safe, standard, and dangerous bands")
	check(starter.all(func(offer): return int(offer.mission_level) == 1), "all role pressure is anchored to the same snapshotted hunter level")
	check(int(starter[0].power) < int(starter[1].power) and int(starter[1].power) < int(starter[2].power), "all three roles remain genuinely ordered at the level-one floor")
	check(float(starter[0].base_travel_duration) == 300.0 and float(starter[0].travel_duration) == 120.0 and float(starter[0].pursuit_duration) > 0.0, "starter acceleration preserves the five-minute base route while travel and pursuit remain independent")
	check(int(starter[0].fuel_cost) == 5, "mission snapshots expose fuel from base route minutes")
	check(is_equal_approx(float(starter[0].starter_travel_discount), 0.60), "levels one to three expose the strongest starter travel reduction")
	var level_four_discoveries := MissionRules.newly_available_planets(3, 4)
	check(level_four_discoveries.size() == 1 and str(level_four_discoveries[0].id) == "congelaria_sa", "crossing a level band reports only the newly available destination")
	check(MissionRules.newly_available_planets(4, 7).is_empty(), "levels inside one discovery band never invent a destination")
	check(MissionRules.newly_available_planets(3, 13).map(func(planet): return str(planet.id)) == ["congelaria_sa", "micelia_404", "ferro_velho_omega"], "multi-level rewards preserve every crossed destination in authored order")
	var expected_travel_multipliers := {1: 0.40, 4: 0.60, 8: 0.80, 13: 1.00, 19: 1.00, 50: 1.00, 100: 1.00}
	for checkpoint_level in [1, 4, 8, 13, 19, 50, 100]:
		state.player.level = checkpoint_level
		state.player.wins = 0
		var checkpoint_offers := MissionRules.board_offers(state.player)
		check(int(checkpoint_offers[0].power) < int(checkpoint_offers[1].power) and int(checkpoint_offers[1].power) < int(checkpoint_offers[2].power), "role pressure remains ordered at level %d" % checkpoint_level)
		check(int(checkpoint_offers[1].xp) < CoreRules.xp_needed(checkpoint_level), "one balanced warrant cannot trigger runaway leveling at level %d" % checkpoint_level)
		check(is_equal_approx(MissionRules.travel_multiplier(checkpoint_level), float(expected_travel_multipliers[checkpoint_level])), "starter travel multiplier changes at the intended level %d threshold" % checkpoint_level)

	state.player.level = 19
	state.player.wins = 7
	var mature := MissionRules.board_offers(state.player)
	var worlds := {}
	for offer in mature:
		worlds[str(offer.planet_id)] = true
	check(worlds.size() == 3, "three unlocked destinations produce three different mission worlds")
	var equipment_changed: Dictionary = state.player.duplicate(true)
	equipment_changed.weapon.power = 999
	equipment_changed.armor.power = 999
	check(MissionRules.board_offers(equipment_changed) == mature, "offer enemies never read or mirror current equipment power")
	check(MissionRules.board_offers(state.player) == mature, "unchanged level and completion cycle preserve deterministic offers")

	var planet_slot_counts := {}
	var seen_target_ids := {}
	var previous_pairs := {}
	state.player.level = int(ContentDB.PLANETS[-1].unlock_level)
	state.player.seen_planet_ids = ContentDB.PLANETS.slice(0, ContentDB.PLANETS.size() - 1).map(func(planet): return str(planet.id))
	var spotlight_target_ids := {}
	for cycle in 6:
		state.player.wins = cycle
		var spotlight_offers := MissionRules.board_offers(state.player)
		var newest_offers := spotlight_offers.filter(func(offer): return str(offer.planet_id) == str(ContentDB.PLANETS[-1].id))
		check(newest_offers.size() == 1, "an unacknowledged newest world receives exactly one rotating spotlight at cycle %d" % cycle)
		if not newest_offers.is_empty():
			spotlight_target_ids[str(newest_offers[0].id)] = true
	check(spotlight_target_ids.size() == 4, "six spotlight boards expose all four identities from a newly unlocked world")
	state.player.seen_planet_ids = ContentDB.PLANETS.map(func(planet): return str(planet.id))
	# Sixteen passes across the complete current world catalog balance both the
	# three destination slots and all four authored target tiers as the catalog
	# grows beyond the early least-common rotation periods.
	for cycle in ContentDB.PLANETS.size() * 16:
		state.player.wins = cycle
		var rotating := MissionRules.board_offers(state.player)
		var board_worlds := {}
		var board_targets := {}
		var current_pairs := {}
		for offer in rotating:
			var planet_id := str(offer.planet_id)
			var target_id := str(offer.id)
			board_worlds[planet_id] = true
			board_targets[target_id] = true
			seen_target_ids[target_id] = true
			planet_slot_counts[planet_id] = int(planet_slot_counts.get(planet_id, 0)) + 1
			current_pairs["%s/%s" % [planet_id, target_id]] = true
		check(board_worlds.size() == 3, "every mature board keeps three distinct unlocked destinations at cycle %d" % cycle)
		check(board_targets.size() == 3, "every board avoids duplicate target identities at cycle %d" % cycle)
		if not previous_pairs.is_empty():
			var repeats := current_pairs.keys().filter(func(pair): return previous_pairs.has(pair))
			check(repeats.size() < 3, "a refreshed board never repeats all three planet-target pairs at cycle %d" % cycle)
		previous_pairs = current_pairs
	var planet_counts: Array = planet_slot_counts.values()
	check(int(planet_counts.max()) - int(planet_counts.min()) <= 1, "all unlocked destinations receive balanced exposure across complete rotation epochs")
	check(seen_target_ids.size() == ContentDB.TARGETS.size(), "the bounded mature rotation exposes every current target identity")
	state.player.level = 19
	state.player.wins = 7
	mature = MissionRules.board_offers(state.player)

	var canonical := MissionRules.canonical_offer(mature[1])
	check(canonical == mature[1], "a snapshotted mission offer reconstructs exactly for safe persistence")
	var tampered := mature[1].duplicate(true)
	tampered.power = 1
	check(int(MissionRules.canonical_offer(tampered).power) == int(mature[1].power), "canonical reconstruction rejects player-scaled or tampered enemy strength")
	var mismatched_role := mature[1].duplicate(true)
	mismatched_role.offer_index = 0
	check(MissionRules.canonical_offer(mismatched_role).is_empty(), "canonical reconstruction rejects mismatched offer-role metadata")

	state.player.owned_transport_ids = ["executive_escape_yacht"]
	state.player.active_transport_id = "executive_escape_yacht"
	var route := mature[2]
	var expected_saved := float(route.travel_duration) * 0.50
	check(is_equal_approx(TransportRules.mission_saved_seconds(state.player, route), expected_saved), "transport savings apply to planetary travel")
	check(is_equal_approx(TransportRules.effective_mission_duration(state.player, route), float(route.pursuit_duration) + float(route.travel_duration) * 0.50), "transport never discounts pursuit time")

	state.free()
	if failures == 0:
		print("PASS: interplanetary level-banded mission offers are coherent")
		quit(0)
	else:
		printerr("FAIL: %d mission rule test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
