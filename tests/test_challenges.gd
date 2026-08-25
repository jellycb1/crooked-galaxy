extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_audit")


func run_audit() -> void:
	var state = root.get_node_or_null("GameState")
	if state == null:
		check(false, "autoload is available for challenge audit")
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	check(not Challenge.is_unlocked(state.player), "challenge ladder stays outside the opening planet tutorial")
	check(not state.start_challenge(str(Challenge.STAGES[0].id)), "locked ladder rejects direct state calls")
	state.player.completed_planets = [Challenge.UNLOCK_PLANET_ID]
	state.player.capture_streak = 4
	check(Challenge.is_unlocked(state.player) and Challenge.progress(state.player) == 0, "Dustball completion opens the first floor without inventing progress")
	for index in Challenge.STAGES.size():
		var stage := Challenge.stage_at(index)
		var reward := Challenge.reward_for(stage, ContentDB.ITEM_TRAITS)
		check(bool(stage.challenge) and int(stage.challenge_index) == index, "floor %d has canonical challenge identity" % (index + 1))
		check(str(reward.slot) == ("rig" if index < 3 else "implant"), "floor %d advances the intended universal equipment family" % (index + 1))
		check(reward.has("trait") and int(reward.power) <= 2, "floor %d reward remains lateral and mechanically complete" % (index + 1))
		if index > 0:
			check(int(stage.power) > int(Challenge.STAGES[index - 1].power) and int(stage.health) > int(Challenge.STAGES[index - 1].health), "floor %d is harder than the previous floor" % (index + 1))
	var progression_builds := [
		{"stage": 0, "minimum": 0.60, "maximum": 0.85, "player": {"level": 8, "base_power": 24, "class_id": "orbit_gunslinger", "attributes": {"strength": 10, "vitality": 14, "dexterity": 18, "intelligence": 10, "cunning": 10}, "weapon": {"power": 14, "origin_planet_id": "dustball_prime"}, "armor": {"power": 10, "origin_planet_id": "dustball_prime"}}},
		{"stage": 2, "minimum": 0.60, "maximum": 0.85, "player": {"level": 15, "base_power": 40, "class_id": "orbit_gunslinger", "attributes": {"strength": 10, "vitality": 18, "dexterity": 32, "intelligence": 10, "cunning": 10}, "weapon": {"power": 38, "origin_planet_id": "micelia_404"}, "armor": {"power": 30, "integrity_upgrades": 3, "origin_planet_id": "micelia_404"}}},
		{"stage": 3, "minimum": 0.60, "maximum": 0.85, "player": {"level": 16, "base_power": 40, "class_id": "orbit_gunslinger", "attributes": {"strength": 10, "vitality": 18, "dexterity": 26, "intelligence": 10, "cunning": 18}, "weapon": {"power": 40, "origin_planet_id": "ferro_velho_omega"}, "armor": {"power": 34, "integrity_upgrades": 2, "origin_planet_id": "ferro_velho_omega"}}},
		{"stage": 5, "minimum": 0.20, "maximum": 0.45, "player": {"level": 29, "base_power": 66, "class_id": "orbit_gunslinger", "attributes": {"strength": 10, "vitality": 24, "dexterity": 38, "intelligence": 10, "cunning": 24}, "weapon": {"power": 80, "origin_planet_id": "cassino_quasar"}, "armor": {"power": 64, "integrity_upgrades": 3, "origin_planet_id": "cassino_quasar"}}},
	]
	for audit in progression_builds:
		var odds: float = CoreRules.bounty_odds(audit.player, Challenge.stage_at(int(audit.stage)))
		check(odds >= float(audit.minimum) and odds <= float(audit.maximum), "floor %d lands in its intended campaign power window (actual %d%%)" % [int(audit.stage) + 1, roundi(odds * 100.0)])
	var canonical_stage: Dictionary = state.canonicalize_loaded_bounty(Challenge.stage_at(1))
	check(not bool(canonical_stage.repaired) and bool(canonical_stage.bounty.challenge), "an interrupted canonical challenge round-trips without false recovery")
	var tampered_stage: Dictionary = Challenge.stage_at(1)
	tampered_stage.power = 1
	check(bool(state.canonicalize_loaded_bounty(tampered_stage).repaired), "loaded challenge combat stats are restored from canonical content")

	var wins_before := int(state.player.wins)
	var captures_before: Dictionary = state.player.captures_by_target.duplicate(true)
	var credits_before := int(state.player.credits)
	check(state.start_challenge(str(Challenge.STAGES[0].id)) and state.phase == state.Phase.COMBAT, "current floor enters the shared animated combat directly")
	check(not state.start_challenge(str(Challenge.STAGES[1].id)), "a later floor cannot bypass sequential progression")
	state.enemy_hp = 0
	state.finish_combat(true)
	check(state.phase == state.Phase.VICTORY and str(state.pending_loot.slot) == "rig", "challenge victory creates its fixed unique reward")
	state.open_reward()
	var summary: Dictionary = state.claim_reward(true)
	check(bool(summary.get("challenge", false)) and int(state.player.challenge_floor) == 1, "claim advances exactly one challenge floor")
	check(int(state.player.credits) == credits_before + int(Challenge.STAGES[0].credits), "challenge pays its fixed credits without contract streak inflation")
	check(int(state.player.wins) == wins_before and state.player.captures_by_target == captures_before and int(state.player.capture_streak) == 4, "challenge does not contaminate rank, target mastery, or warrant streak")
	check(str(state.player.rig.id) == "rift_customs_drone_reward", "the universal rig slot accepts the first challenge reward")

	check(state.start_challenge(str(Challenge.STAGES[1].id)), "claim opens the next sequential floor")
	state.player_hp = 0
	state.finish_combat(false)
	check(state.phase == state.Phase.BOARD and int(state.player.challenge_floor) == 1, "defeat leaves challenge progress on the current floor")
	check(int(state.player.capture_streak) == 4 and state.last_notice_context == "challenge_defeat", "challenge defeat preserves warrant streak and exposes its own recovery context")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	check(scene.find_child("ChallengeProgressTrack", true, false) != null, "unlocked ladder renders persistent floor progress")
	check(scene.find_child("ChallengeCurrentDossier", true, false) != null and scene.find_child("ChallengeRewardPreview", true, false) != null, "current enemy and unique reward share one readable dossier")
	var enter := scene.find_child("ChallengeEnterAction", true, false) as Button
	check(enter != null and enter.size.y >= 48.0, "challenge entry remains an Android touch target")
	scene.queue_free()
	await process_frame
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: independent challenge ladder preserves campaign boundaries")
		quit(0)
	else:
		printerr("FAIL: %d challenge audit issue(s)" % failures)
		quit(1)
