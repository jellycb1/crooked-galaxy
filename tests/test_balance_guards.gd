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
		"level": 29,
		"base_power": 66,
		"class_id": "orbit_gunslinger",
		"attributes": {"strength": 10, "vitality": 24, "dexterity": 38, "intelligence": 10, "cunning": 24},
		"weapon": {"power": 80, "origin_planet_id": "cassino_quasar"},
		"armor": {"power": 64, "integrity_upgrades": 3, "origin_planet_id": "cassino_quasar"},
	}
	var casino_boss: Dictionary = Content.TARGETS[19]
	var casino_options := Contracts.evaluate_approaches(casino_boss_ready, casino_boss, Content.contract_approaches())
	check(float(casino_options[0].odds) >= 0.95, "the fifth boss retains a dependable recovery route")
	check(float(casino_options[1].odds) >= 0.25 and float(casino_options[1].odds) <= 0.80, "the fifth boss fast route remains a meaningful gamble (actual %d%%)" % roundi(float(casino_options[1].odds) * 100.0))
	check(float(casino_options[2].odds) >= 0.10 and float(casino_options[2].odds) <= 0.60, "the fifth boss corporate route remains a costly high-risk option (actual %d%%)" % roundi(float(casino_options[2].odds) * 100.0))
	check(float(casino_options[0].odds) - float(casino_options[1].odds) >= 0.15 and float(casino_options[1].odds) - float(casino_options[2].odds) >= 0.10, "mature contract routes preserve two visible risk gaps")
	check(Contracts.recommended_approach_id(casino_options) == "quiet_net", "the fifth boss endpoint recommends recovery over a weak premium payout")

	var omega_arrival := {
		"level": 16,
		"base_power": 40,
		"class_id": "orbit_gunslinger",
		"attributes": {"strength": 10, "vitality": 18, "dexterity": 26, "intelligence": 10, "cunning": 18},
		"weapon": {"power": 40, "origin_planet_id": "ferro_velho_omega"},
		"armor": {"power": 34, "integrity_upgrades": 2, "origin_planet_id": "ferro_velho_omega"},
	}
	var omega_options := Contracts.evaluate_approaches(omega_arrival, Content.TARGETS[12], Content.contract_approaches())
	check(float(omega_options[0].odds) >= 0.90, "fourth-planet arrival retains a dependable recovery route")
	check(float(omega_options[1].odds) >= 0.25 and float(omega_options[1].odds) <= 0.90, "fourth-planet fast route escapes saturation (actual %d%%)" % roundi(float(omega_options[1].odds) * 100.0))
	check(float(omega_options[2].odds) >= 0.10 and float(omega_options[2].odds) <= 0.75, "fourth-planet corporate route remains viable but risky (actual %d%%)" % roundi(float(omega_options[2].odds) * 100.0))
	check(float(omega_options[0].odds) > float(omega_options[1].odds) and float(omega_options[1].odds) > float(omega_options[2].odds), "fourth-planet contract risks remain strictly ordered")

	var frozen_arrival := {
		"level": 8,
		"base_power": 24,
		"class_id": "orbit_gunslinger",
		"attributes": {"strength": 10, "vitality": 14, "dexterity": 18, "intelligence": 10, "cunning": 10},
		"weapon": {"power": 14, "origin_planet_id": "dustball_prime"},
		"armor": {"power": 10, "origin_planet_id": "dustball_prime"},
	}
	var frozen_options := Contracts.evaluate_approaches(frozen_arrival, Content.TARGETS[4], Content.contract_approaches())
	check(float(frozen_options[0].odds) >= 0.95, "second-planet arrival retains a dependable recovery route")
	check(float(frozen_options[1].odds) >= 0.45 and float(frozen_options[1].odds) <= 0.90, "second-planet fast route is a meaningful choice (actual %d%%)" % roundi(float(frozen_options[1].odds) * 100.0))
	check(float(frozen_options[2].odds) >= 0.10 and float(frozen_options[2].odds) <= 0.65, "second-planet corporate route preserves visible risk (actual %d%%)" % roundi(float(frozen_options[2].odds) * 100.0))

	var mycelial_boss_ready := {
		"level": 15,
		"base_power": 40,
		"class_id": "orbit_gunslinger",
		"attributes": {"strength": 10, "vitality": 18, "dexterity": 32, "intelligence": 10, "cunning": 10},
		"weapon": {"power": 38, "origin_planet_id": "micelia_404"},
		"armor": {"power": 30, "integrity_upgrades": 3, "origin_planet_id": "micelia_404"},
	}
	var mycelial_options := Contracts.evaluate_approaches(mycelial_boss_ready, Content.TARGETS[11], Content.contract_approaches())
	check(float(mycelial_options[0].odds) >= 0.95, "third boss retains a dependable recovery route")
	check(float(mycelial_options[1].odds) >= 0.45 and float(mycelial_options[1].odds) <= 0.90, "third-boss fast route escapes saturation (actual %d%%)" % roundi(float(mycelial_options[1].odds) * 100.0))
	check(float(mycelial_options[2].odds) >= 0.15 and float(mycelial_options[2].odds) <= 0.65, "third-boss corporate route remains viable but risky (actual %d%%)" % roundi(float(mycelial_options[2].odds) * 100.0))
	check(float(mycelial_options[0].odds) > float(mycelial_options[1].odds) and float(mycelial_options[1].odds) > float(mycelial_options[2].odds), "third-boss contract risks remain strictly ordered")

	for target_index in range(4, 12):
		check(Content.TARGETS[target_index].has("loot_power"), "rebalanced mid-campaign target %d separates combat and loot power" % target_index)

	if failures == 0:
		print("PASS: early, mid-campaign, and late balance guard rails are intact")
		quit(0)
	else:
		printerr("FAIL: %d balance guard(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
