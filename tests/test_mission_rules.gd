extends SceneTree

const MissionRules = preload("res://scripts/mission_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var starter := MissionRules.board_offers(state.player)
	check(starter.size() == 3, "a fresh hunter receives three mission choices")
	check(starter.all(func(offer): return str(offer.planet_id) == "dustball_prime"), "level one keeps all offers inside the only discovered world")
	check(starter.map(func(offer): return str(offer.mission_role)) == ["safe", "standard", "dangerous"], "the board exposes safe, standard, and dangerous bands")
	check(int(starter[0].mission_level) == 1 and int(starter[2].mission_level) == 2, "difficulty is a fixed mission-level offset")
	check(int(starter[0].power) < int(starter[1].power) and int(starter[1].power) < int(starter[2].power), "all three roles remain genuinely ordered at the level-one floor")
	check(float(starter[0].travel_duration) == 30.0 and float(starter[0].pursuit_duration) > 0.0, "travel and pursuit are independent timing axes")

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
	var expected_saved := float(route.travel_duration) * 0.40
	check(is_equal_approx(TransportRules.mission_saved_seconds(state.player, route), expected_saved), "transport savings apply to planetary travel")
	check(is_equal_approx(TransportRules.effective_mission_duration(state.player, route), float(route.pursuit_duration) + float(route.travel_duration) * 0.60), "transport never discounts pursuit time")

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
