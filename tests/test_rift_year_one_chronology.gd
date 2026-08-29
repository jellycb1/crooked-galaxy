extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const Model = preload("res://tools/rift_year_one_chronology_model.gd")
const Monetization = preload("res://scripts/monetization_rules.gd")

var failures := 0


func _init() -> void:
	check(Monetization.mission_fuel_cost(Challenge.stage_at(0)) == 0, "Rift encounters never consume normal hunt fuel")
	check(is_equal_approx(Monetization.rift_daily_success_probability(0.5, 0), 0.5), "the free daily entry has one combat attempt")
	check(is_equal_approx(Monetization.rift_daily_success_probability(0.5, 3), 0.9375), "three paid retries produce four attempts, never extra daily victories")
	check(is_equal_approx(Monetization.expected_rift_retry_chip_spend(0.5, 3), 4.25), "expected 1/5/20 retry spend is weighted only by preceding defeats")
	var free_result := Model.simulate(Model.PROFILES[0])
	var premium_result := Model.simulate(Model.PROFILES[2])
	check(float(premium_result.daily_success_probability) > float(free_result.daily_success_probability), "paid retries reduce defeat delay without multiplying the one-victory daily cap")
	check(float(premium_result.expected_days_per_clear) >= 1.0, "even four successful attempts cannot clear more than one enemy per day")
	check(int(free_result.authored_clears_reached) < Challenge.REALITIES.size() * 12, "the free balanced level curve does not pretend every advanced gate is reachable in year one")
	check(int(premium_result.authored_clears_reached) == Challenge.REALITIES.size() * 12, "the fastest audited progression reaches all currently authored realities")
	var premium_realities: Array = premium_result.realities
	check(float(premium_realities[1].eligible_day) > float(premium_realities[0].expected_completion_day), "the second key remains sequential and level-gated")
	check(float(premium_realities[2].eligible_day) > float(premium_realities[1].expected_completion_day), "the third key remains sequential and level-gated")
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: year-one Rift chronology respects fuel separation, keys, levels, retries, and the daily victory cap")
		quit(0)
	else:
		printerr("FAIL: %d Rift chronology test(s) failed" % failures)
		quit(1)
