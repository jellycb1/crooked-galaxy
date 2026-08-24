extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	test_power_and_health()
	test_damage_boundaries()
	test_level_progression()
	test_bounty_streak_rewards()
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
	player.weapon.trait = {"power_bonus": 2, "health_bonus": 0}
	player.armor.trait = {"power_bonus": 0, "health_bonus": 14}
	check(Rules.player_power(player) == 21, "equipment traits contribute combat power")
	check(Rules.max_health(player) == 111, "equipment traits contribute maximum health")
	check(Rules.is_upgrade({"power": 4, "trait": {"power_bonus": 2}}, {"power": 5}), "effective equipment score can outweigh lower base power")
	player.weapon.integrity_upgrades = 2
	check(Rules.max_health(player) == 127, "equipment reinforcement contributes persistent maximum health")
	check(Rules.equipment_integrity_upgrade_cost({"power": 10, "integrity_upgrades": 0}) == 10, "integrity cost scales from item power")
	check(Rules.equipment_integrity_upgrade_cost({"power": 10, "integrity_upgrades": 2}) == 18, "integrity cost rises with reinforcement level")
	check(Rules.can_upgrade_integrity({"integrity_upgrades": 4}) and not Rules.can_upgrade_integrity({"integrity_upgrades": 5}), "integrity reinforcement has an explicit cap")
	var tactical_player := {
		"level": 1,
		"base_power": 10,
		"weapon": {"power": 2, "trait": {"opening_damage_bonus": 5}},
		"armor": {"power": 2, "trait": {"damage_reduction": 2}},
	}
	var raw_player_damage := Rules.damage_roll(Rules.player_power(tactical_player), 4, 0.5)
	check(Rules.player_attack_damage(tactical_player, 4, 0.5, 1) == raw_player_damage + 5, "ambush damage applies only to the opening shot")
	check(Rules.player_attack_damage(tactical_player, 4, 0.5, 2) == raw_player_damage, "ambush damage expires after round one")
	var raw_enemy_damage := Rules.damage_roll(18, 5, 0.5)
	check(Rules.enemy_attack_damage(tactical_player, 18, 0.5) == maxi(1, raw_enemy_damage - 2), "armor dampener reduces every incoming strike")
	var damage_breakdown := Rules.enemy_attack_breakdown(tactical_player, 18, 0.5)
	check(int(damage_breakdown.raw_damage) == raw_enemy_damage and int(damage_breakdown.prevented) == 2, "enemy damage breakdown exposes mitigation without changing final damage")
	check(Rules.equipment_score({"trait": {"opening_damage_bonus": 5}}) == 10, "opening damage participates in equipment comparison")
	check(Rules.equipment_score({"trait": {"damage_reduction": 2}}) == 20, "damage reduction participates in equipment comparison")
	var kit_player := {
		"level": 1,
		"base_power": 10,
		"weapon": {"slot": "weapon", "power": 5, "origin_planet_id": "dustball_prime"},
		"armor": {"slot": "armor", "power": 4, "origin_planet_id": "congelaria_sa"},
	}
	check(Rules.equipment_set_origin(kit_player).is_empty() and Rules.equipment_set_bonus_power(kit_player) == 0, "mixed-origin equipment does not activate a planetary kit")
	var kit_armor := {"slot": "armor", "power": 3, "origin_planet_id": "dustball_prime"}
	check(not Rules.is_upgrade(kit_armor, kit_player.armor), "kit candidate can be weaker in isolation")
	check(Rules.is_upgrade_for_player(kit_player, kit_armor), "matching origin can make a lower-power item improve the complete build")
	kit_player.armor = kit_armor
	check(Rules.equipment_set_origin(kit_player) == "dustball_prime", "matching origins expose the active planetary kit")
	check(Rules.player_power(kit_player) == 19 and Rules.max_health(kit_player) == 95, "planetary kit grants its explicit power and integrity bonuses")


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
	var no_patrol := Rules.offline_patrol_rewards(299.0, 3, 10)
	check(int(no_patrol.credits) == 0, "AFK patrol ignores returns shorter than five minutes")


func test_bounty_streak_rewards() -> void:
	check(int(Rules.bounty_streak_reward(100, 1).credits) == 100, "first capture has no streak bonus")
	check(int(Rules.bounty_streak_reward(100, 3).credits) == 110, "third consecutive capture grants ten percent")
	check(int(Rules.bounty_streak_reward(100, 20).credits) == 125, "streak reward is capped at twenty-five percent")
	check(Rules.target_mastery_level(2) == 0 and Rules.target_mastery_level(3) == 1, "target mastery begins on the third capture")
	check(Rules.target_mastery_level(6) == 2 and Rules.target_mastery_level(10) == 3, "target mastery advances at stable capture thresholds")
	check(Rules.target_mastery_next_requirement(2) == 10 and Rules.target_mastery_next_requirement(3) == -1, "target mastery exposes its next requirement and cap")
	var mastery_thresholds := Rules.loot_rarity_thresholds(3)
	check(is_equal_approx(float(mastery_thresholds.rare), 0.53) and is_equal_approx(float(mastery_thresholds.epic), 0.86), "maximum mastery improves rare and epic thresholds")
	var patrol := Rules.offline_patrol_rewards(3600.0, 2, 10)
	check(int(patrol.minutes) == 60 and int(patrol.credits) == 180, "AFK credits scale with completed planets")
	check(int(patrol.scrap) == 4, "AFK scrap is awarded in thirty-minute cycles")
	var capped_patrol := Rules.offline_patrol_rewards(12.0 * 3600.0, 3, 10)
	check(int(capped_patrol.minutes) == 480 and bool(capped_patrol.capped), "AFK rewards cap at eight hours")
	check(int(Rules.offline_patrol_rewards(3600.0, 3, 0).credits) == 0, "AFK patrol requires a completed first bounty")
	var safe_margins := Rules.safe_content_margins(Vector2(720, 1280), Vector2(1080, 2400), Rect2(0, 90, 1080, 2220))
	check(int(safe_margins.x) == 30 and int(safe_margins.z) == 30, "safe-area calculation preserves base horizontal margins")
	check(int(safe_margins.y) == 48 and int(safe_margins.w) == 48, "safe-area calculation converts physical top and bottom insets")


func test_bounty_odds() -> void:
	Rules.clear_bounty_odds_cache()
	var player := {"level": 1, "base_power": 10, "weapon": {"power": 1}, "armor": {"power": 1}}
	var easy := {"power": 4, "defense": 1, "health": 20}
	var brutal := {"power": 99, "defense": 30, "health": 999}
	var easy_odds := Rules.bounty_odds(player, easy)
	check(easy_odds > 0.9, "easy fights show strong odds")
	check(Rules.bounty_odds_cache.size() == 1, "first unique build-target pair populates the odds cache")
	var irrelevant_change := player.duplicate(true)
	irrelevant_change.credits = 99999
	check(is_equal_approx(Rules.bounty_odds(irrelevant_change, easy), easy_odds) and Rules.bounty_odds_cache.size() == 1, "noncombat player fields reuse the deterministic odds result")
	check(Rules.bounty_odds(player, brutal) < 0.1, "brutal fights show low odds")
	var upgraded := {"level": 1, "base_power": 10, "weapon": {"power": 6}, "armor": {"power": 1}}
	var safe_baron := Content.apply_approach(Content.TARGETS[1], Content.CONTRACT_APPROACHES[0])
	var calibrated := Rules.bounty_odds(upgraded, safe_baron)
	check(calibrated > 0.70 and calibrated < 0.84, "displayed odds stay calibrated to the actual combat rules")
	var power_projection := upgraded.duplicate(true)
	power_projection.weapon.power = int(power_projection.weapon.power) + 1
	var health_projection := upgraded.duplicate(true)
	health_projection.weapon.integrity_upgrades = 1
	check(Rules.bounty_odds(power_projection, safe_baron) >= calibrated, "same-target power upgrades never display worse simulated odds")
	check(Rules.bounty_odds(health_projection, safe_baron) >= calibrated, "same-target health upgrades never display worse simulated odds")
	check(Rules.target_mastery_scrap_reward(0) == 0 and Rules.target_mastery_scrap_reward(1) == 6 and Rules.target_mastery_scrap_reward(3) == 14, "mastery scrap rewards scale once per earned tier")


func test_loot_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4404
	var target: Dictionary = Content.TARGETS[0]
	var item := Content.generate_loot(target, rng)
	check(item.has("id") and not str(item.id).is_empty(), "loot has a stable runtime id")
	check(item.slot == "weapon" or item.slot == "armor", "loot has a valid slot")
	check(int(item.power) >= 1, "loot has positive power")
	check(not str(item.description).is_empty(), "loot carries original flavor text")
	check(str(item.origin_planet_id) == str(target.planet_id), "loot records its planet of origin")
	check(Rules.salvage_value({"power": 9, "rarity": "Comum"}) == 3, "common salvage scales from item power")
	check(Rules.salvage_value({"power": 9, "rarity": "Épico"}) == 12, "rarity increases salvage yield")
	check(Rules.salvage_value({"power": 9, "rarity": "Comum", "trait": {"power_bonus": 1}}) == 5, "modified gear grants extra salvage")
	check(Rules.equipment_upgrade_cost({"power": 10}) == 11, "workshop upgrade cost rises with power")
	check(Rules.salvage_value({"power": 6, "rarity": "Comum", "power_upgrades": 2, "integrity_upgrades": 2}) == 14, "manual salvage partially recovers workshop investment")
	check(Rules.has_workshop_investment({"power_upgrades": 1}) and Rules.has_workshop_investment({"integrity_upgrades": 1}), "either workshop path marks an invested item")
	check(not Rules.has_workshop_investment({"power": 99}), "raw item power is not mistaken for workshop investment")
	var frozen_rng := RandomNumberGenerator.new()
	frozen_rng.seed = 8811
	var frozen_loot := Content.generate_loot(Content.TARGETS[4], frozen_rng)
	check(str(frozen_loot.origin_planet_id) == "congelaria_sa", "planet item families retain their origin for kit building")
	var frozen_names := Content.PLANET_ITEM_CATALOGS.congelaria_sa.weapon + Content.PLANET_ITEM_CATALOGS.congelaria_sa.armor
	check(frozen_names.any(func(definition): return str(definition.name) == str(frozen_loot.name)), "frozen targets use their planet item family")
	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = 551
	var frozen_event := Content.random_hunt_event(event_rng, "congelaria_sa")
	check(str(frozen_event.planet_id) == "congelaria_sa", "hunt incidents are selected from the active planet")
	check(str(frozen_event.symbol) != "D-7" and str(frozen_event.symbol) != "LIVE", "planet incident supplies its own UI symbol")
	check(Content.available_bounties(0).size() == 1, "rank gates advanced bounties")
	check(Content.available_bounties(1).size() == 2, "new reputation unlocks a bounty")
	check(Content.available_bounties(2).size() == 3, "third reputation tier unlocks the final regular bounty")
	check(Content.available_bounties(3).size() == 4, "maximum reputation unlocks the chapter boss")
	var opening_board := Content.board_bounties(0, "dustball_prime", 0, {})
	check(opening_board.size() == 1 and str(opening_board[0].id) == "gloop" and str(opening_board[0].board_role) == "primary", "opening board presents one clear campaign warrant")
	var second_tier_board := Content.board_bounties(1, "dustball_prime", 1, {"gloop": 3})
	check(second_tier_board.size() == 2 and str(second_tier_board[0].id) != "gloop" and str(second_tier_board[0].board_role) == "primary", "newly revealed warrant leads the board without hiding the prior target")
	check(str(second_tier_board[1].id) == "gloop" and str(second_tier_board[1].board_role) == "repeat", "prior targets return as explicit repeat contracts")
	var boss_board := Content.board_bounties(3, "dustball_prime", 3, {"gloop": 3, "baron_boom": 4, "madame_vacuum": 3})
	check(boss_board.size() == 3 and bool(boss_board[0].boss), "board caps choice density while keeping the campaign boss first")
	check(boss_board.all(func(target): return int(target.chapter_tier) <= 3), "board never exposes a future campaign target")
	var completed_board := Content.board_bounties(3, "dustball_prime", 3, {"gloop": 3, "baron_boom": 3, "madame_vacuum": 3, "mayor_gold_dust": 1})
	check(completed_board.size() == 3 and completed_board.all(func(target): return str(target.board_role) == "repeat"), "completed chapters become a focused repeat-contract rotation")
	check(bool(Content.TARGETS[3].boss), "final Dustball target is marked as a chapter boss")
	check(Content.available_bounties(3, "congelaria_sa", 0).size() == 1, "unlocked second planet starts with one bounty")
	check(Content.available_bounties(3, "congelaria_sa", 1).size() == 2, "planet captures unlock the second frozen target")
	check(Content.available_bounties(3, "congelaria_sa", 3).size() == 4, "maximum planet tier unlocks its chapter boss")
	check(bool(Content.TARGETS[7].boss), "Congelaria ends with an explicit chapter boss")
	check(str(Content.get_planet("congelaria_sa").name) == "Congelária S.A.", "planets resolve from stable ids")
	check(not Content.is_planet_unlocked("congelaria_sa", []), "second planet starts locked")
	check(Content.is_planet_unlocked("congelaria_sa", [Content.PLANET.id]), "first chapter completion unlocks the next planet")
	check(str(Content.get_target("gloop").name) == "Gloop, o Inconveniente", "targets can be restored from stable ids")
	check(Content.get_target("missing_target").is_empty(), "unknown target ids fail safely")
	check(not Content.is_planet_unlocked("micelia_404", [Content.PLANET.id]), "third planet remains locked after only one chapter")
	check(Content.is_planet_unlocked("micelia_404", [Content.PLANET.id, "congelaria_sa"]), "Congelaria completion unlocks Micelia")
	check(not Content.is_planet_unlocked("ferro_velho_omega", [Content.PLANET.id, "congelaria_sa"]), "fourth planet remains locked before Micelia completion")
	check(Content.is_planet_unlocked("ferro_velho_omega", [Content.PLANET.id, "congelaria_sa", "micelia_404"]), "Micelia completion unlocks Ferro-Velho Omega")
	check(Content.available_bounties(3, "micelia_404", 0).size() == 1, "third chapter starts with one local target")
	check(Content.available_bounties(3, "micelia_404", 1).size() == 2, "fungal captures unlock the second target")
	check(Content.available_bounties(3, "micelia_404", 3).size() == 4, "maximum fungal tier unlocks its boss")
	check(bool(Content.TARGETS[11].boss), "Micelia ends with an explicit chapter boss")
	check(Content.available_bounties(3, "ferro_velho_omega", 0).size() == 1, "fourth chapter starts with one local target")
	check(Content.available_bounties(3, "ferro_velho_omega", 3).size() == 4, "maximum scrapyard tier unlocks its boss")
	check(bool(Content.TARGETS[15].boss), "Ferro-Velho Omega ends with an explicit chapter boss")
	check(not Content.is_planet_unlocked("cassino_quasar", [Content.PLANET.id, "congelaria_sa", "micelia_404"]), "fifth planet remains locked before Ferro-Velho Omega completion")
	check(Content.is_planet_unlocked("cassino_quasar", [Content.PLANET.id, "congelaria_sa", "micelia_404", "ferro_velho_omega"]), "Ferro-Velho Omega completion unlocks Cassino Quasar")
	check(Content.available_bounties(3, "cassino_quasar", 0).size() == 1 and Content.available_bounties(3, "cassino_quasar", 3).size() == 4, "fifth chapter follows the sequential four-warrant structure")
	check(bool(Content.TARGETS[19].boss), "Cassino Quasar ends with an explicit chapter boss")
	var fungal_rng := RandomNumberGenerator.new()
	fungal_rng.seed = 9921
	var fungal_event := Content.random_hunt_event(fungal_rng, "micelia_404")
	check(str(fungal_event.planet_id) == "micelia_404", "fungal planet selects its own incidents")
	var fungal_loot := Content.generate_loot(Content.TARGETS[8], fungal_rng)
	var fungal_names := Content.PLANET_ITEM_CATALOGS.micelia_404.weapon + Content.PLANET_ITEM_CATALOGS.micelia_404.armor
	check(fungal_names.any(func(definition): return str(definition.name) == str(fungal_loot.name)), "fungal target generates its own item family")
	var scrapyard_rng := RandomNumberGenerator.new()
	scrapyard_rng.seed = 44009
	var scrapyard_event := Content.random_hunt_event(scrapyard_rng, "ferro_velho_omega")
	check(str(scrapyard_event.planet_id) == "ferro_velho_omega", "scrapyard planet selects its own incidents")
	var scrapyard_loot := Content.generate_loot(Content.TARGETS[12], scrapyard_rng)
	var scrapyard_names := Content.PLANET_ITEM_CATALOGS.ferro_velho_omega.weapon + Content.PLANET_ITEM_CATALOGS.ferro_velho_omega.armor
	check(scrapyard_names.any(func(definition): return str(definition.name) == str(scrapyard_loot.name)), "scrapyard target generates its own item family")
	var casino_rng := RandomNumberGenerator.new()
	casino_rng.seed = 55109
	var casino_event := Content.random_hunt_event(casino_rng, "cassino_quasar")
	check(str(casino_event.planet_id) == "cassino_quasar", "casino planet selects its own incidents")
	var casino_loot := Content.generate_loot(Content.TARGETS[16], casino_rng)
	var casino_names := Content.PLANET_ITEM_CATALOGS.cassino_quasar.weapon + Content.PLANET_ITEM_CATALOGS.cassino_quasar.armor
	check(casino_names.any(func(definition): return str(definition.name) == str(casino_loot.name)), "casino target generates its own item family")
	var trait_rng := RandomNumberGenerator.new()
	trait_rng.seed = 77221
	var found_trait := false
	for _roll in 80:
		var rolled_item := Content.generate_loot(Content.TARGETS[7], trait_rng)
		if rolled_item.has("trait"):
			found_trait = true
			check(str(rolled_item.rarity) == "Raro" or str(rolled_item.rarity) == "Épico", "only rare equipment receives a modification")
			break
	check(found_trait, "loot generation produces equipment modifications")
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
	var heat_event: Dictionary = Content.HUNT_EVENTS[2]
	var heated := Content.apply_hunt_choice(Content.TARGETS[4], heat_event.choices[2])
	check(heated.power == 31 and heated.credits == 175, "frozen incident applies its local risk and reward")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
