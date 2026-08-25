extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const Simulator = preload("res://tools/simulate_challenges.gd")
const Builds = preload("res://tools/simulation_builds.gd")

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
	var anomaly_counts := {}
	for index in Challenge.STAGES.size():
		var stage := Challenge.stage_at(index)
		var reward := Challenge.reward_for(stage, ContentDB.ITEM_TRAITS)
		check(bool(stage.challenge) and int(stage.challenge_index) == index, "floor %d has canonical challenge identity" % (index + 1))
		check(str(reward.slot) == ("rig" if index < 3 else "implant"), "floor %d advances the intended universal equipment family" % (index + 1))
		check(reward.has("trait") and int(reward.power) <= 2, "floor %d reward remains lateral and mechanically complete" % (index + 1))
		check(not stage.get("anomaly", {}).is_empty() and Challenge.ANOMALY_PROFILES.has(str(stage.anomaly_id)), "floor %d resolves a canonical combat profile" % (index + 1))
		anomaly_counts[str(stage.anomaly_id)] = int(anomaly_counts.get(str(stage.anomaly_id), 0)) + 1
		if index > 0:
			check(int(stage.power) > int(Challenge.STAGES[index - 1].power) and int(stage.health) > int(Challenge.STAGES[index - 1].health), "floor %d is harder than the previous floor" % (index + 1))
	check(anomaly_counts.size() == 3, "the ladder teaches three mechanically distinct anomaly families")
	for anomaly_id in Challenge.ANOMALY_PROFILES:
		check(int(anomaly_counts.get(anomaly_id, 0)) == 2, "anomaly '%s' returns once at higher pressure" % anomaly_id)
	var profile_probe := Simulator.checkpoint_player(Simulator.CHECKPOINTS[0], Builds.POLICIES[1])
	var opening_probe := profile_probe.duplicate(true)
	opening_probe.rig = {"power": 0, "trait": {"opening_damage_bonus": 5}}
	var reduction_probe := profile_probe.duplicate(true)
	reduction_probe.rig = {"power": 0, "trait": {"damage_reduction": 2}}
	var health_probe := profile_probe.duplicate(true)
	health_probe.rig = {"power": 0, "trait": {"health_bonus": 14}}
	var volatile_profile := Challenge.anomaly_profile("volatile_opening")
	var rupture_profile := Challenge.anomaly_profile("armor_rupture")
	var anchor_profile := Challenge.anomaly_profile("inertial_anchor")
	var volatile_opening_damage := CoreRules.player_attack_damage(opening_probe, 15, 0.5, 1, float(volatile_profile.opening_damage_multiplier))
	var rupture_opening_damage := CoreRules.player_attack_damage(opening_probe, 15, 0.5, 1, float(rupture_profile.opening_damage_multiplier))
	var rupture_reduction := CoreRules.enemy_attack_breakdown(reduction_probe, 48, 0.5, float(rupture_profile.damage_reduction_piercing))
	var anchor_reduction := CoreRules.enemy_attack_breakdown(reduction_probe, 48, 0.5, float(anchor_profile.damage_reduction_piercing))
	check(volatile_opening_damage > rupture_opening_damage, "volatile chambers amplify opening gear more than containment failures")
	check(int(anchor_reduction.prevented) > int(rupture_reduction.prevented), "inertial anchors preserve more mitigation than containment failures")
	check(CoreRules.max_health(health_probe) == CoreRules.max_health(profile_probe) + 14, "integrity gear remains fully active when mitigation is mostly pierced")
	var maximum_campaign_safe_delta := 0.0
	var maximum_campaign_route_delta := 0.0
	for stage_index in Challenge.STAGES.size():
		var checkpoint: Dictionary = Simulator.CHECKPOINTS[stage_index]
		var class_odds: Array[float] = []
		for policy in Builds.POLICIES:
			var player := Simulator.checkpoint_player(checkpoint, policy)
			var bare_player := player.duplicate(true)
			Simulator.apply_prior_rewards(player, stage_index)
			class_odds.append(CoreRules.bounty_odds(player, Challenge.stage_at(stage_index)))
			for approach_index in ContentDB.CONTRACT_APPROACHES.size():
				var contract := ContentDB.apply_approach(ContentDB.TARGETS[int(checkpoint.campaign_target)], ContentDB.CONTRACT_APPROACHES[approach_index])
				var route_delta := CoreRules.bounty_odds(player, contract) - CoreRules.bounty_odds(bare_player, contract)
				maximum_campaign_route_delta = maxf(maximum_campaign_route_delta, route_delta)
				if approach_index == 0:
					maximum_campaign_safe_delta = maxf(maximum_campaign_safe_delta, route_delta)
		class_odds.sort()
		var class_spread := float(class_odds[2]) - float(class_odds[0])
		check(float(class_odds[0]) >= 0.40 and float(class_odds[2]) <= 0.90, "floor %d stays aspirational but viable across all prototype classes (%d-%d%%)" % [stage_index + 1, roundi(float(class_odds[0]) * 100.0), roundi(float(class_odds[2]) * 100.0)])
		check(class_spread <= 0.35, "floor %d class spread remains bounded at %d percentage points" % [stage_index + 1, roundi(class_spread * 100.0)])
	check(maximum_campaign_safe_delta <= 0.05, "Fenda rewards do not become mandatory for campaign recovery routes")
	check(maximum_campaign_route_delta <= 0.25, "Fenda rewards improve risky campaign routes without erasing their risk")
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
	check(scene.find_child("ChallengeAnomalyRule", true, false) != null, "challenge dossier exposes its class-neutral anomaly profile before entry")
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
