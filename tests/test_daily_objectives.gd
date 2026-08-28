extends SceneTree

const DailyObjectiveRules = preload("res://scripts/daily_objective_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var objectives := DailyObjectiveRules.objectives(state.player)
	check(objectives.size() == 3, "daily shift exposes exactly three legible objectives")
	check(objectives.map(func(entry): return int(entry.goal)) == [1, 3, 5], "objective cadence rewards a short, medium, and complete play session")
	check(objectives.reduce(func(total: int, entry: Dictionary): return total + int(entry.credits), 0) == 85, "the complete daily shift grants a bounded 85 credits")
	check(objectives.reduce(func(total: int, entry: Dictionary): return total + int(entry.scrap), 0) == 8, "the complete daily shift grants a bounded eight scrap")
	check(objectives.all(func(entry): return not bool(entry.complete) and not bool(entry.claimed)), "a fresh shift never invents progress or claims")

	state.player.daily_hunts_completed = 1
	check(state.daily_rewards_ready() == 1, "one completed contract unlocks only the first payment")
	var credits_before := int(state.player.credits)
	check(state.claim_daily_objective("first_capture"), "a completed daily objective can be claimed")
	check(int(state.player.credits) == credits_before + 25 and int(state.player.scrap) == 0, "the first payment applies its exact advertised resources")
	check(not state.claim_daily_objective("first_capture") and not state.claim_daily_objective("full_shift"), "daily payments cannot be double-claimed or claimed early")

	state.player.daily_hunts_completed = 5
	var balance_before_all := {"credits": int(state.player.credits), "scrap": int(state.player.scrap)}
	var all_receipt := state.claim_all_daily_objectives()
	check(int(all_receipt.count) == 2 and int(all_receipt.credits) == 60 and int(all_receipt.scrap) == 8, "claim-all excludes prior claims and returns an auditable receipt")
	check(int(state.player.credits) == int(balance_before_all.credits) + 60 and int(state.player.scrap) == int(balance_before_all.scrap) + 8, "claim-all applies the remaining two payments atomically")
	check(state.claim_all_daily_objectives() == {"count": 0, "credits": 0, "scrap": 0}, "an exhausted daily shift cannot mint resources again")

	var malformed := state.default_player()
	malformed.daily_hunts_completed = 999999
	malformed.claimed_daily_objectives = ["first_capture", "first_capture", "forged_reward"]
	var repaired := state.sanitize_loaded_player(malformed)
	check(bool(repaired.repaired) and int(repaired.player.daily_hunts_completed) == 1000, "loaded daily progress is bounded defensively")
	check(repaired.player.claimed_daily_objectives == ["first_capture"], "loaded daily claim ids are canonical and unique")

	state.player.daily_hunts_completed = 5
	state.player.claimed_daily_objectives = ["first_capture"]
	state.player.market_refresh_count = 2
	var tomorrow := (int(state.player.economy_day) + 1) * int(MonetizationRules.SECONDS_PER_DAY)
	check(state.normalize_daily_economy(tomorrow), "the UTC day boundary performs one explicit economy reset")
	check(int(state.player.daily_hunts_completed) == 0 and state.player.claimed_daily_objectives.is_empty(), "the day boundary resets activity and claims together")
	check(int(state.player.market_refresh_count) == 0, "daily objectives share the existing UTC economy clock instead of creating a second reset")
	state.free()

	if failures == 0:
		print("PASS: daily objectives are bounded, honest, and reset atomically")
		quit(0)
	else:
		printerr("FAIL: %d daily objective test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
