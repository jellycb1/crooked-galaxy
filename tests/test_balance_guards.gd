extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const Contracts = preload("res://scripts/contract_rules.gd")

var failures := 0


func _init() -> void:
	var starter := {"level": 1, "base_power": 10, "weapon": {"power": 1}, "armor": {"power": 1}}
	var first_upgrade := {"level": 1, "base_power": 10, "weapon": {"power": 6}, "armor": {"power": 1}}
	var gloop: Dictionary = Content.TARGETS[0]
	var baron: Dictionary = Content.TARGETS[1]
	check(Rules.bounty_odds(starter, gloop) >= 0.90, "the onboarding bounty remains dependable")
	var base_odds := Rules.bounty_odds(first_upgrade, baron)
	check(base_odds >= 0.15 and base_odds <= 0.35, "the first upgrade makes Baron possible but not trivial")
	var quiet_baron := Content.apply_approach(baron, Content.CONTRACT_APPROACHES[0])
	var quiet_odds := Rules.bounty_odds(first_upgrade, quiet_baron)
	check(quiet_odds >= 0.65 and quiet_odds <= 0.90, "the safe approach creates a viable early progression path")

	var tactical := first_upgrade.duplicate(true)
	tactical.weapon.trait = {"opening_damage_bonus": 5}
	tactical.armor.trait = {"damage_reduction": 2}
	check(Rules.bounty_odds(tactical, baron) >= 0.85, "a complete tactical pair materially changes the Baron matchup")

	var mixed_kit := first_upgrade.duplicate(true)
	mixed_kit.weapon.origin_planet_id = "dustball_prime"
	mixed_kit.armor.origin_planet_id = "congelaria_sa"
	var matched_kit := mixed_kit.duplicate(true)
	matched_kit.armor.origin_planet_id = "dustball_prime"
	var mixed_odds := Rules.bounty_odds(mixed_kit, baron)
	var matched_odds := Rules.bounty_odds(matched_kit, baron)
	check(matched_odds >= 0.70 and matched_odds - mixed_odds >= 0.40, "the first planetary kit creates a visible strategic payoff")

	var casino_boss_ready := {
		"level": 19,
		"base_power": 48,
		"weapon": {"power": 86, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar"},
		"armor": {"power": 69, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar"},
	}
	var casino_boss: Dictionary = Content.TARGETS[19]
	var casino_options := Contracts.evaluate_approaches(casino_boss_ready, casino_boss, Content.contract_approaches())
	check(float(casino_options[0].odds) >= 0.95, "the fifth boss retains a dependable recovery route")
	check(float(casino_options[1].odds) >= 0.25 and float(casino_options[1].odds) <= 0.60, "the fifth boss fast route remains a meaningful gamble")
	check(float(casino_options[2].odds) <= 0.20, "the fifth boss corporate route remains explicitly dangerous")
	check(Contracts.recommended_approach_id(casino_options) == "quiet_net", "the fifth boss endpoint recommends recovery over a weak premium payout")

	if failures == 0:
		print("PASS: early and fifth-chapter balance guard rails are intact")
		quit(0)
	else:
		printerr("FAIL: %d balance guard(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
