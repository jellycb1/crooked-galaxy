extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")

var failures := 0


func _init() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var starter: Dictionary = MissionRules.board_offers(state.player)[1]
	check(MonetizationRules.mission_fuel_cost(starter) == 5 and int(starter.fuel_cost) == 5, "Dustball consumes its five-minute base route")
	var original_duration := TransportRules.effective_mission_duration(state.player, starter)
	state.player.owned_transport_ids = ["licensed_junkbox"]
	state.player.active_transport_id = "licensed_junkbox"
	check(TransportRules.effective_mission_duration(state.player, starter) < original_duration and MonetizationRules.mission_fuel_cost(starter) == 5, "transport saves waiting time without buying extra daily hunts")

	state.select_bounty(starter)
	check(state.choose_approach("quiet_net"), "funded mission starts from briefing")
	check(state.phase == state.Phase.HUNT and int(state.player.hunt_fuel) == 95, "route commitment charges fuel exactly once")
	var charged := int(state.player.hunt_fuel)
	check(not state.start_hunt() and int(state.player.hunt_fuel) == charged, "duplicate start signal cannot charge the same route twice")

	var blocked := StateScript.new()
	blocked.persistence_enabled = false
	blocked.player = blocked.default_player()
	blocked.player.hunt_fuel = 4
	blocked.select_bounty(starter)
	check(not blocked.choose_approach("quiet_net"), "mission below its fuel cost remains blocked")
	check(blocked.phase == blocked.Phase.BRIEFING and int(blocked.player.hunt_fuel) == 4 and blocked.offered_approaches.size() == 3, "rejected route preserves fuel and briefing choices")

	var refill := StateScript.new()
	refill.persistence_enabled = false
	refill.player = refill.default_player()
	refill.player.warp_chips = 26
	check(refill.refill_hunt_fuel() and int(refill.player.hunt_fuel) == 120 and int(refill.player.warp_chips) == 25, "first refill grants twenty fuel for one chip")
	check(refill.refill_hunt_fuel() and int(refill.player.hunt_fuel) == 140 and int(refill.player.warp_chips) == 20, "second refill costs five chips")
	check(refill.refill_hunt_fuel() and int(refill.player.hunt_fuel) == 160 and int(refill.player.warp_chips) == 0, "third refill costs twenty chips and reaches the daily ceiling")
	check(not refill.refill_hunt_fuel(), "fourth daily refill is blocked")
	var next_day := float(int(refill.player.economy_day) + 1) * MonetizationRules.SECONDS_PER_DAY
	check(refill.normalize_daily_economy(next_day) and int(refill.player.hunt_fuel) == 100 and int(refill.player.hunt_fuel_refill_count) == 0, "UTC day rollover restores the free reserve and refill ladder")
	refill.player.economy_day = MonetizationRules.utc_day_id() - 1
	refill.player.hunt_fuel_refill_count = 2
	refill.player.hunt_fuel = 140
	refill.player.warp_chips = 20
	check(not refill.refill_hunt_fuel(20) and int(refill.player.hunt_fuel) == 100 and int(refill.player.warp_chips) == 20, "midnight rollover refreshes stale confirmation instead of charging a different price")

	var malformed := refill.default_player()
	malformed.hunt_fuel = 9999
	malformed.hunt_fuel_refill_count = 999
	var repaired: Dictionary = refill.sanitize_loaded_player(malformed)
	check(bool(repaired.repaired) and int(repaired.player.hunt_fuel_refill_count) == 3 and int(repaired.player.hunt_fuel) == 160, "save sanitizer bounds fuel and premium refill count")
	check(MonetizationRules.mission_fuel_cost({"challenge": true}) == 0, "Fenda challenges remain outside normal hunt fuel")

	var fuel_save := "res://.godot/crooked_galaxy_fuel_test_%s.json" % OS.get_process_id()
	remove_save_family(fuel_save)
	var persisted := StateScript.new()
	persisted.save_path = fuel_save
	persisted.player = persisted.default_player()
	persisted.player.warp_chips = 1
	check(persisted.refill_hunt_fuel(), "fuel refill commits through the normal save transaction")
	var restored := StateScript.new()
	restored.save_path = fuel_save
	restored.load_game()
	check(int(restored.player.hunt_fuel) == 120 and int(restored.player.hunt_fuel_refill_count) == 1 and int(restored.player.warp_chips) == 0, "reload preserves premium cost, refill count, and fuel atomically")
	persisted.free()
	restored.free()
	remove_save_family(fuel_save)

	state.free()
	blocked.free()
	refill.free()
	if failures == 0:
		print("PASS: daily hunt fuel, refill escalation, transport boundary, and repair are coherent")
		quit(0)
	else:
		printerr("FAIL: %d hunt fuel test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func remove_save_family(path: String) -> void:
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
