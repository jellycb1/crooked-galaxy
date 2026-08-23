extends SceneTree

const FIGHTS_PER_CASE := 5000


func _init() -> void:
	print("Crooked Galaxy balance simulation (%d fights per target)" % FIGHTS_PER_CASE)
	var profiles := [
		{"name": "starter", "level": 1, "xp": 0, "base_power": 10, "weapon": {"power": 1}, "armor": {"power": 1}},
		{"name": "first upgrade", "level": 1, "xp": 42, "base_power": 10, "weapon": {"power": 6}, "armor": {"power": 1}},
		{"name": "level 2 geared", "level": 2, "xp": 10, "base_power": 12, "weapon": {"power": 6}, "armor": {"power": 4}},
		{"name": "rank 3 geared", "level": 3, "xp": 40, "base_power": 14, "weapon": {"power": 11}, "armor": {"power": 8}},
		{"name": "boss ready", "level": 4, "xp": 35, "base_power": 16, "weapon": {"power": 15}, "armor": {"power": 11}},
		{"name": "frozen tier 2", "level": 6, "xp": 40, "base_power": 20, "weapon": {"power": 21}, "armor": {"power": 17}},
		{"name": "chapter 2 boss ready", "level": 8, "xp": 55, "base_power": 24, "weapon": {"power": 27}, "armor": {"power": 23}},
		{"name": "fungal tier 2", "level": 10, "xp": 70, "base_power": 28, "weapon": {"power": 33}, "armor": {"power": 27}},
		{"name": "chapter 3 boss ready", "level": 12, "xp": 90, "base_power": 32, "weapon": {"power": 41}, "armor": {"power": 34}},
		{"name": "scrapyard tier 2", "level": 14, "xp": 110, "base_power": 36, "weapon": {"power": 48, "trait": {"power_bonus": 2}}, "armor": {"power": 40, "trait": {"health_bonus": 14}}},
		{"name": "chapter 4 boss ready", "level": 16, "xp": 130, "base_power": 40, "weapon": {"power": 56, "trait": {"power_bonus": 2}}, "armor": {"power": 49, "trait": {"power_bonus": 1, "health_bonus": 8}}},
		{"name": "casino tier 2", "level": 18, "xp": 150, "base_power": 44, "weapon": {"power": 79, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar"}, "armor": {"power": 61, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar", "trait": {"health_bonus": 6}}},
		{"name": "chapter 5 boss ready", "level": 19, "xp": 170, "base_power": 48, "weapon": {"power": 86, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar"}, "armor": {"power": 69, "integrity_upgrades": 5, "origin_planet_id": "cassino_quasar"}},
	]
	for profile in profiles:
		print("\n%s (power %d, hp %d)" % [profile.name, CoreRules.player_power(profile), CoreRules.max_health(profile)])
		for target in ContentDB.TARGETS:
			var result := simulate_target(profile, target, FIGHTS_PER_CASE)
			print("  %-24s win=%5.1f%%  rounds=%4.1f  UI estimate=%d%%" % [
				target.name,
				float(result.wins) / FIGHTS_PER_CASE * 100.0,
				float(result.rounds) / FIGHTS_PER_CASE,
				roundi(CoreRules.bounty_odds(profile, target) * 100.0),
			])

	var approach_profile: Dictionary = profiles[1]
	var approach_target: Dictionary = ContentDB.TARGETS[1]
	print("\nContract approaches: %s vs. %s" % [approach_profile.name, approach_target.name])
	for approach in ContentDB.contract_approaches():
		var adjusted := ContentDB.apply_approach(approach_target, approach)
		var result := simulate_target(approach_profile, adjusted, FIGHTS_PER_CASE)
		print("  %-26s win=%5.1f%% estimate=%3d%% time=%ds credits=%d xp=%d" % [
			approach.name,
			float(result.wins) / FIGHTS_PER_CASE * 100.0,
			roundi(CoreRules.bounty_odds(approach_profile, adjusted) * 100.0),
			int(adjusted.duration),
			int(adjusted.credits),
			int(adjusted.xp),
		])

	var tactical_profile: Dictionary = profiles[1].duplicate(true)
	tactical_profile.name = "tactical traits"
	tactical_profile.weapon.trait = {"opening_damage_bonus": 5}
	tactical_profile.armor.trait = {"damage_reduction": 2}
	var tactical_result := simulate_target(tactical_profile, approach_target, FIGHTS_PER_CASE)
	print("\nTactical traits vs. %s: win=%.1f%% estimate=%d%% opening=+%d reduction=%d" % [
		str(approach_target.name),
		float(tactical_result.wins) / FIGHTS_PER_CASE * 100.0,
		roundi(CoreRules.bounty_odds(tactical_profile, approach_target) * 100.0),
		CoreRules.player_opening_damage(tactical_profile),
		CoreRules.player_damage_reduction(tactical_profile),
	])

	var mixed_kit_profile: Dictionary = profiles[1].duplicate(true)
	mixed_kit_profile.weapon.origin_planet_id = "dustball_prime"
	mixed_kit_profile.armor.origin_planet_id = "congelaria_sa"
	var matched_kit_profile: Dictionary = mixed_kit_profile.duplicate(true)
	matched_kit_profile.armor.origin_planet_id = "dustball_prime"
	var mixed_kit_result := simulate_target(mixed_kit_profile, approach_target, FIGHTS_PER_CASE)
	var matched_kit_result := simulate_target(matched_kit_profile, approach_target, FIGHTS_PER_CASE)
	print("\nPlanetary kit vs. %s: mixed=%5.1f%% matched=%5.1f%% estimate=%d%% bonus=+%d power/+%d health" % [
		str(approach_target.name),
		float(mixed_kit_result.wins) / FIGHTS_PER_CASE * 100.0,
		float(matched_kit_result.wins) / FIGHTS_PER_CASE * 100.0,
		roundi(CoreRules.bounty_odds(matched_kit_profile, approach_target) * 100.0),
		CoreRules.equipment_set_bonus_power(matched_kit_profile),
		CoreRules.equipment_set_bonus_health(matched_kit_profile),
	])

	var event_profile: Dictionary = profiles[0]
	var safe_contract := ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[0])
	var event: Dictionary = ContentDB.HUNT_EVENTS[0]
	print("\nHunt incident: %s during %s" % [event.title, safe_contract.name])
	for choice in event.choices:
		var adjusted := ContentDB.apply_hunt_choice(safe_contract, choice)
		var result := simulate_target(event_profile, adjusted, FIGHTS_PER_CASE)
		print("  %-24s win=%5.1f%% estimate=%3d%% cost=%d time=%ds credits=%d" % [
			choice.name,
			float(result.wins) / FIGHTS_PER_CASE * 100.0,
			roundi(CoreRules.bounty_odds(event_profile, adjusted) * 100.0),
			int(choice.get("credit_cost", 0)),
			int(adjusted.duration) + int(choice.get("duration_add", 0)),
			int(adjusted.credits),
		])

	var frozen_profile: Dictionary = profiles[3]
	var frozen_contract := ContentDB.apply_approach(ContentDB.TARGETS[4], ContentDB.CONTRACT_APPROACHES[0])
	var frozen_event: Dictionary = ContentDB.HUNT_EVENTS[2]
	print("\nPlanet incident: %s during %s" % [frozen_event.title, frozen_contract.name])
	for choice in frozen_event.choices:
		var adjusted := ContentDB.apply_hunt_choice(frozen_contract, choice)
		var result := simulate_target(frozen_profile, adjusted, FIGHTS_PER_CASE)
		print("  %-24s win=%5.1f%% estimate=%3d%% cost=%d time=%ds credits=%d" % [
			choice.name,
			float(result.wins) / FIGHTS_PER_CASE * 100.0,
			roundi(CoreRules.bounty_odds(frozen_profile, adjusted) * 100.0),
			int(choice.get("credit_cost", 0)),
			int(adjusted.duration) + int(choice.get("duration_add", 0)),
			int(adjusted.credits),
		])
	quit(0)


func simulate_target(player: Dictionary, target: Dictionary, count: int) -> Dictionary:
	var wins := 0
	var total_rounds := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210 + int(target.power)
	for _fight in count:
		var player_hp := CoreRules.max_health(player)
		var enemy_hp := int(target.health)
		var rounds := 0
		while player_hp > 0 and enemy_hp > 0 and rounds < 100:
			rounds += 1
			enemy_hp -= CoreRules.player_attack_damage(player, int(target.defense), rng.randf(), rounds)
			if enemy_hp <= 0:
				wins += 1
				break
			player_hp -= CoreRules.enemy_attack_damage(player, int(target.power), rng.randf())
		total_rounds += rounds
	return {"wins": wins, "rounds": total_rounds}
