extends SceneTree

const WeeklyRules = preload("res://scripts/weekly_operation_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const SaveMigrations = preload("res://scripts/save_migrations.gd")

var failures := 0


func _init() -> void:
	var sunday := Time.get_unix_time_from_datetime_string("2026-08-30T23:59:59")
	var monday := Time.get_unix_time_from_datetime_string("2026-08-31T00:00:00")
	check(WeeklyRules.utc_week_id(sunday) + 1 == WeeklyRules.utc_week_id(monday), "weekly reset boundary is Monday at 00:00 UTC")
	check(WeeklyRules.utc_week_id(monday) == WeeklyRules.utc_week_id(monday + 6 * 86400 + 86399), "one weekly cycle covers the complete Monday-to-Sunday interval")

	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var objectives := WeeklyRules.objectives(state.player)
	check(objectives.map(func(entry): return int(entry.goal)) == [8, 20, 35], "weekly cadence fits short, regular, and committed free play")
	check(objectives.reduce(func(total: int, entry: Dictionary): return total + int(entry.credits), 0) == 550, "weekly objectives grant a bounded 550 credits")
	check(objectives.reduce(func(total: int, entry: Dictionary): return total + int(entry.scrap), 0) == 40, "weekly objectives grant a bounded forty scrap")

	var week_id := WeeklyRules.utc_week_id(monday)
	var eligible := WeeklyRules.eligible_special_targets(state.player)
	check(eligible.size() == 1 and bool(eligible[0].boss), "a new hunter rotates only through elite targets on unlocked planets")
	var target_id := WeeklyRules.rotating_target_id(state.player, week_id)
	var special := WeeklyRules.special_contract(state.player, target_id, week_id)
	check(bool(special.weekly_special) and int(special.weekly_cycle_id) == week_id and bool(special.mission_offer), "Black Warrant is a canonical network mission with an immutable weekly identity")
	check(int(special.scrap_reward) == 8 and int(special.fuel_cost) > 0, "Black Warrant grants bounded normal resources and consumes normal fuel")
	check(MissionRules.canonical_offer(special) == special, "a Black Warrant survives canonical save repair exactly")

	state.player.level = 320
	var covered_worlds := {}
	for week_offset in 12:
		for planet_id in WeeklyRules.rotating_planet_ids(state.player, week_id + week_offset):
			covered_worlds[planet_id] = true
	check(covered_worlds.size() == 35, "twelve weekly circuits expose the complete thirty-five-world launch catalog")
	var route_ids := WeeklyRules.rotating_planet_ids(state.player, week_id)
	state.player.weekly_route_planet_ids = route_ids
	state.player.weekly_route_captures = {}
	state.player.weekly_route_claimed = false
	state.player.seen_planet_ids = MissionRules.available_planets(320).map(func(planet): return str(planet.id))
	var route_board := MissionRules.board_offers(state.player)
	check(route_board.any(func(offer): return route_ids.has(str(offer.planet_id))), "every board guarantees one normal warrant from the weekly circuit")
	for route_id in route_ids:
		check(WeeklyRules.record_route_capture(state.player, route_id), "the first circuit capture advances its snapshotted world")
		check(WeeklyRules.record_route_capture(state.player, route_id), "the second circuit capture completes its snapshotted world")
		check(not WeeklyRules.record_route_capture(state.player, route_id), "circuit progress is capped at two captures per world")
	var route_status := state.weekly_route_status()
	check(bool(route_status.complete) and int(route_status.progress) == 6 and int(route_status.goal) == 6, "three circuit worlds require exactly six normal captures")
	var route_balance := {"credits": int(state.player.credits), "scrap": int(state.player.scrap)}
	check(state.claim_weekly_route(), "a completed circuit exposes one explicit claim")
	check(int(state.player.credits) == int(route_balance.credits) + 250 and int(state.player.scrap) == int(route_balance.scrap) + 18, "circuit payout remains bounded to 250 credits and eighteen scrap")
	check(not state.claim_weekly_route(), "a circuit cannot be paid twice")

	state.player.weekly_cycle_id = week_id
	state.player.weekly_special_target_id = target_id
	check(state.start_weekly_special() and state.phase == StateScript.Phase.BRIEFING, "weekly action enters the normal approach briefing instead of a parallel combat loop")
	check(bool(state.current_bounty.weekly_special), "briefing preserves weekly contract metadata")
	state.cancel_briefing()

	state.player.weekly_hunts_completed = 35
	check(state.weekly_rewards_ready() == 3, "thirty-five ordinary hunts make all three weekly payments ready")
	var balance := {"credits": int(state.player.credits), "scrap": int(state.player.scrap)}
	var receipt := state.claim_all_weekly_objectives()
	check(int(receipt.count) == 3 and int(state.player.credits) == int(balance.credits) + 550 and int(state.player.scrap) == int(balance.scrap) + 40, "weekly claim-all applies each advertised reward once")
	check(state.claim_all_weekly_objectives().count == 0, "claimed weekly rewards cannot mint resources twice")

	state.player.weekly_special_completed = true
	var next_monday := monday + 7 * 86400
	check(state.normalize_weekly_operations(next_monday), "the next Monday resets weekly state atomically")
	check(int(state.player.weekly_hunts_completed) == 0 and state.player.claimed_weekly_objectives.is_empty() and not bool(state.player.weekly_special_completed), "weekly progress, claims, and special completion reset together")
	check(not str(state.player.weekly_special_target_id).is_empty(), "the new cycle snapshots its own eligible elite target")
	check(state.player.weekly_route_captures.is_empty() and not bool(state.player.weekly_route_claimed) and not state.player.weekly_route_planet_ids.is_empty(), "the new cycle atomically snapshots a fresh unclaimed circuit")

	var malformed := state.default_player()
	malformed.weekly_hunts_completed = 999999
	malformed.claimed_weekly_objectives = ["weekly_patrol", "weekly_patrol", "forged"]
	malformed.weekly_special_target_id = "forged_boss"
	malformed.weekly_cycle_id = "forged_week"
	malformed.weekly_special_completed = "false"
	malformed.weekly_route_planet_ids = ["forged_world"]
	malformed.weekly_route_captures = {"forged_world": 999}
	malformed.weekly_route_claimed = "true"
	var repaired := state.sanitize_loaded_player(malformed)
	check(bool(repaired.repaired) and int(repaired.player.weekly_hunts_completed) == 10000, "loaded weekly progress is bounded defensively")
	check(repaired.player.claimed_weekly_objectives == ["weekly_patrol"] and str(repaired.player.weekly_special_target_id).is_empty(), "loaded weekly claims and target identity are canonicalized")
	check(int(repaired.player.weekly_cycle_id) == WeeklyRules.utc_week_id() and not bool(repaired.player.weekly_special_completed), "loaded weekly cycle and completion types cannot be forged")
	check(repaired.player.weekly_route_planet_ids.is_empty() and repaired.player.weekly_route_captures.is_empty() and not bool(repaired.player.weekly_route_claimed), "loaded circuit identity, progress, and claim types cannot be forged")

	var migrated := SaveMigrations.migrate({"version": 22, "player": {"level": 7}})
	check(int(migrated.version) == SaveMigrations.CURRENT_VERSION and int(migrated.player.weekly_cycle_id) == -1, "schema twenty-three initializes a neutral weekly cycle without inventing progress")
	check(migrated.player.claimed_weekly_objectives.is_empty() and not bool(migrated.player.weekly_special_completed), "weekly migration never claims content for an existing hunter")
	check(migrated.player.weekly_route_planet_ids.is_empty() and migrated.player.weekly_route_captures.is_empty() and not bool(migrated.player.weekly_route_claimed), "schema twenty-four initializes a neutral circuit snapshot without inventing captures")
	state.free()

	if failures == 0:
		print("PASS: weekly operations are deterministic, bounded, and migration-safe")
		quit(0)
	else:
		printerr("FAIL: %d weekly operation test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
