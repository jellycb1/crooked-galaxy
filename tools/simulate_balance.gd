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
			enemy_hp -= CoreRules.damage_roll(CoreRules.player_power(player), int(target.defense), rng.randf())
			if enemy_hp <= 0:
				wins += 1
				break
			player_hp -= CoreRules.damage_roll(int(target.power), int(player.armor.power) + 3, rng.randf())
		total_rounds += rounds
	return {"wins": wins, "rounds": total_rounds}
