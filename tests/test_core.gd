extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	test_power_and_health()
	test_damage_boundaries()
	test_level_progression()
	test_bounty_odds()
	test_loot_generation()
	if failures == 0:
		print("PASS: all Crooked Galaxy core tests")
		quit(0)
	else:
		printerr("FAIL: %d core test(s) failed" % failures)
		quit(1)


func test_power_and_health() -> void:
	var player := {
		"level": 2,
		"base_power": 12,
		"weapon": {"power": 4},
		"armor": {"power": 3},
	}
	check(Rules.player_power(player) == 19, "power includes base, weapon, and armor")
	check(Rules.max_health(player) == 97, "health includes level and armor")


func test_damage_boundaries() -> void:
	var low := Rules.damage_roll(20, 8, 0.0)
	var high := Rules.damage_roll(20, 8, 1.0)
	check(low == 13, "low damage roll is deterministic")
	check(high == 20, "high damage roll is deterministic")
	check(Rules.damage_roll(1, 999, 0.0) == 1, "damage never drops below one")


func test_level_progression() -> void:
	var player := {"level": 1, "xp": 0, "base_power": 10}
	var gained := Rules.apply_xp(player, 210)
	check(gained == 2, "XP can grant multiple levels")
	check(player.level == 3, "level is incremented")
	check(player.xp == 5, "overflow XP is retained")
	check(player.base_power == 14, "level raises base power")


func test_bounty_odds() -> void:
	var player := {"level": 1, "base_power": 10, "weapon": {"power": 1}, "armor": {"power": 1}}
	var easy := {"power": 4, "defense": 1, "health": 20}
	var brutal := {"power": 99, "defense": 30, "health": 999}
	check(Rules.bounty_odds(player, easy) > 0.9, "easy fights show strong odds")
	check(Rules.bounty_odds(player, brutal) < 0.1, "brutal fights show low odds")


func test_loot_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4404
	var target: Dictionary = Content.TARGETS[0]
	var item := Content.generate_loot(target, rng)
	check(item.has("id") and not str(item.id).is_empty(), "loot has a stable runtime id")
	check(item.slot == "weapon" or item.slot == "armor", "loot has a valid slot")
	check(int(item.power) >= 1, "loot has positive power")
	check(not str(item.description).is_empty(), "loot carries original flavor text")
	check(Content.available_bounties(0).size() == 1, "rank gates advanced bounties")
	check(Content.available_bounties(1).size() == 2, "new reputation unlocks a bounty")
	var safe_approach: Dictionary = Content.contract_approaches()[0]
	var adjusted := Content.apply_approach(Content.TARGETS[0], safe_approach)
	check(adjusted.duration == 7, "safe approach lengthens tracking")
	check(adjusted.power == 10, "safe approach lowers target power")
	check(adjusted.credits == 34 and adjusted.xp == 53, "approach modifies visible rewards")
	check(str(adjusted.approach.id) == "quiet_net", "chosen approach is retained")
	var drone_event: Dictionary = Content.HUNT_EVENTS[0]
	var bribed := Content.apply_hunt_choice(Content.TARGETS[0], drone_event.choices[0])
	check(bribed.defense == 3, "hunt choice can weaken target defense")
	var rammed := Content.apply_hunt_choice(Content.TARGETS[0], drone_event.choices[2])
	check(rammed.power == 12 and rammed.credits == 45, "risky hunt choice raises danger and reward")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
