class_name RiftYearOneChronologyModel
extends RefCounted

const Challenge = preload("res://scripts/challenge_rules.gd")
const Monetization = preload("res://scripts/monetization_rules.gd")
const Pacing = preload("res://tools/audit_year_one_pacing.gd")

const DAYS := 365
const BASELINE_PER_ATTEMPT_ODDS := 0.55
const PROFILES := [
	{"id": "free_balanced", "strategy": "standard", "daily_fuel": 100, "paid_retries": 0},
	{"id": "free_efficient", "strategy": "cheapest", "daily_fuel": 100, "paid_retries": 0},
	{"id": "premium_efficient", "strategy": "cheapest", "daily_fuel": 160, "paid_retries": 3},
]


static func simulate(profile: Dictionary, per_attempt_odds := BASELINE_PER_ATTEMPT_ODDS) -> Dictionary:
	var pacing := Pacing.simulate_fuel_days(DAYS, str(profile.strategy), int(profile.daily_fuel))
	var retries := clampi(int(profile.paid_retries), 0, Monetization.MAX_RIFT_RETRIES_PER_DAY)
	var daily_success := Monetization.rift_daily_success_probability(per_attempt_odds, retries)
	var expected_days_per_clear := 1.0 / maxf(0.0001, daily_success)
	var expected_chip_spend_per_open_day := Monetization.expected_rift_retry_chip_spend(per_attempt_odds, retries)
	var realities: Array[Dictionary] = []
	var previous_completion_day := 0.0
	var total_expected_open_days := 0.0
	var authored_clears := 0
	for reality_index in Challenge.REALITIES.size():
		var definition: Dictionary = Challenge.REALITIES[reality_index]
		var unlock_level := int(definition.unlock_level)
		var level_day := float(pacing.milestone_days.get(unlock_level, INF))
		var prerequisite_day := previous_completion_day + 1.0 if reality_index > 0 else 1.0
		var eligible_day := maxf(level_day, prerequisite_day)
		var pity_days := maxi(1, int(definition.get("key_pity_days", 1)))
		var expected_key_delay := 0.0 if reality_index == 0 else float(pity_days - 1) * 0.5
		var expected_key_day := eligible_day + expected_key_delay
		var floor_count: int = definition.stages.size()
		var open_days := float(floor_count) * expected_days_per_clear
		var expected_completion_day := expected_key_day + open_days - 1.0
		var earliest_completion_day := eligible_day + float(floor_count - 1)
		var pity_first_try_completion_day := eligible_day + float(pity_days - 1) + float(floor_count - 1)
		var reachable := not is_inf(level_day) and expected_key_day <= DAYS
		if reachable:
			previous_completion_day = expected_completion_day
			total_expected_open_days += open_days
			authored_clears += floor_count
		realities.append({
			"id": str(definition.id),
			"unlock_level": unlock_level,
			"level_day": level_day,
			"eligible_day": eligible_day,
			"pity_days": pity_days,
			"expected_key_day": expected_key_day,
			"expected_completion_day": expected_completion_day,
			"earliest_completion_day": earliest_completion_day,
			"pity_first_try_completion_day": pity_first_try_completion_day,
			"reachable": reachable,
		})
	return {
		"id": str(profile.id),
		"final_level": int(pacing.level),
		"daily_success_probability": daily_success,
		"expected_days_per_clear": expected_days_per_clear,
		"expected_chip_spend_per_open_day": expected_chip_spend_per_open_day,
		"expected_total_retry_chip_spend": expected_chip_spend_per_open_day * total_expected_open_days,
		"authored_clears_reached": authored_clears,
		"expected_open_days": total_expected_open_days,
		"realities": realities,
	}
