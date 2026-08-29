extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const Simulator = preload("res://tools/simulate_challenges.gd")
const Builds = preload("res://tools/simulation_builds.gd")
const Monetization = preload("res://scripts/monetization_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const DAY_SECONDS := 86400.0

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
	state.player.level = Challenge.UNLOCK_LEVEL
	state.player.capture_streak = 4
	check(Challenge.is_unlocked(state.player) and Challenge.progress(state.player) == 0, "hunter level opens the first floor without inventing progress")
	var anomaly_counts := {}
	var reward_families := Challenge.REWARD_SECTORS
	for index in Challenge.STAGES.size():
		var stage := Challenge.stage_at(index)
		var reward := Challenge.reward_for(stage, ContentDB.ITEM_TRAITS)
		check(bool(stage.challenge) and int(stage.challenge_index) == index, "floor %d has canonical challenge identity" % (index + 1))
		check(str(reward.slot) == reward_families[index / 3], "floor %d advances the intended universal equipment family" % (index + 1))
		check(reward.has("trait") and int(reward.power) <= 2, "floor %d reward remains lateral and mechanically complete" % (index + 1))
		check(not stage.get("anomaly", {}).is_empty() and Challenge.ANOMALY_PROFILES.has(str(stage.anomaly_id)), "floor %d resolves a canonical combat profile" % (index + 1))
		anomaly_counts[str(stage.anomaly_id)] = int(anomaly_counts.get(str(stage.anomaly_id), 0)) + 1
		if index > 0:
			check(int(stage.power) > int(Challenge.STAGES[index - 1].power) and int(stage.health) > int(Challenge.STAGES[index - 1].health), "floor %d is harder than the previous floor" % (index + 1))
	check(Challenge.STAGES.size() == 12 and anomaly_counts.size() == 6, "the ladder contains four equipment sectors and six mechanically distinct anomaly families")
	check(Challenge.sector_slot_for_floor(0) == "rig" and Challenge.sector_slot_for_floor(6) == "gadget" and Challenge.sector_slot_for_floor(11) == "relic", "canonical floor-to-sector routing covers the complete ladder")
	check(Challenge.sector_progress(7, 0) == 3 and Challenge.sector_progress(7, 2) == 1 and Challenge.sector_progress(7, 3) == 0, "sector progress summarizes a mature floor without visual arithmetic drift")
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
	check(float(rupture_profile.attack_roll_bonus_multiplier) < float(anchor_profile.attack_roll_bonus_multiplier), "containment failures disrupt precision more than inertial anchors")
	check(is_zero_approx(float(volatile_profile.defense_bypass_multiplier)) and is_zero_approx(float(anchor_profile.counter_damage_multiplier)), "challenge anomalies explicitly suppress the class mechanic they are designed to resist")
	check(CoreRules.max_health(health_probe) == CoreRules.max_health(profile_probe) + 14, "integrity gear remains fully active when mitigation is mostly pierced")
	var gadget_probe := profile_probe.duplicate(true)
	gadget_probe.gadget = {"trait": ContentDB.ITEM_TRAITS.gadget[2].duplicate(true)}
	var relic_probe := profile_probe.duplicate(true)
	relic_probe.relic = {"trait": ContentDB.ITEM_TRAITS.relic[0].duplicate(true)}
	check(CoreRules.player_defense_bypass(gadget_probe) == CoreRules.player_defense_bypass(profile_probe) + 2, "gadget reward family contributes its mature breach mechanic")
	check(CoreRules.max_health(relic_probe) == CoreRules.max_health(profile_probe) + 16 and CoreRules.player_damage_reduction(relic_probe) == CoreRules.player_damage_reduction(profile_probe) + 1, "relic reward family contributes both integrity and mitigation")
	var maximum_campaign_safe_delta := 0.0
	var maximum_campaign_route_delta := 0.0
	var expected_favored_classes := ["contract_hacker", "warrant_breaker", "orbit_gunslinger", "contract_hacker", "warrant_breaker", "orbit_gunslinger"]
	var favorable_floor_counts := {"warrant_breaker": 0, "orbit_gunslinger": 0, "contract_hacker": 0}
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
		var best_odds: float = float(class_odds.max())
		var favored_index: int = class_odds.find(best_odds)
		var favored_class := str(Builds.POLICIES[favored_index].class_id)
		favorable_floor_counts[favored_class] = int(favorable_floor_counts[favored_class]) + 1
		if stage_index < expected_favored_classes.size():
			check(favored_class == str(expected_favored_classes[stage_index]), "floor %d favors its intended introductory class identity (%s)" % [stage_index + 1, favored_class])
		class_odds.sort()
		var class_spread := float(class_odds[2]) - float(class_odds[0])
		check(float(class_odds[0]) >= 0.40 and float(class_odds[2]) <= 0.90, "floor %d stays aspirational but viable across all initial classes (%d-%d%%)" % [stage_index + 1, roundi(float(class_odds[0]) * 100.0), roundi(float(class_odds[2]) * 100.0)])
		check(class_spread <= 0.30, "floor %d class spread remains bounded at %d percentage points" % [stage_index + 1, roundi(class_spread * 100.0)])
	check(favorable_floor_counts.values().all(func(count): return int(count) >= 2), "each initial class retains at least two favorable Fenda matchups")
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
	check(state.start_challenge(str(Challenge.STAGES[0].id), 100.0 * DAY_SECONDS) and state.phase == state.Phase.COMBAT, "the first key opens the current enemy through the shared animated combat")
	check(state.player.rift_reality_keys == ["dead_customs_key"] and int(state.player.rift_entry_day) == 100, "entry discovers the first key and atomically consumes the UTC attempt")
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

	check(not state.start_challenge(str(Challenge.STAGES[1].id), 100.0 * DAY_SECONDS) and state.last_notice_context == "challenge_entry_used", "claim opens the enemy but never grants a second entry on the same UTC day")
	check(state.start_challenge(str(Challenge.STAGES[1].id), 101.0 * DAY_SECONDS), "the next UTC day restores exactly one entry")
	state.player_hp = 0
	state.finish_combat(false)
	check(state.phase == state.Phase.BOARD and int(state.player.challenge_floor) == 1, "defeat leaves challenge progress on the current floor")
	check(int(state.player.capture_streak) == 4 and state.last_notice_context == "challenge_defeat", "challenge defeat preserves warrant streak and exposes its own recovery context")
	state.player.rift_entry_day = Monetization.utc_day_id()

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	check(scene.find_child("ChallengeProgressTrack", true, false) != null, "unlocked ladder renders persistent floor progress")
	for slot in reward_families:
		check(scene.find_child("ChallengeSector_%s" % slot.capitalize(), true, false) != null, "compact progress track exposes the %s sector" % slot)
	check(scene.find_child("ChallengeCurrentDossier", true, false) != null and scene.find_child("ChallengeHiddenReward", true, false) != null, "current enemy and sealed-reward promise share one readable dossier")
	check(scene.find_child("ChallengeRewardPreview", true, false) == null, "the unopened Rift never exposes item, slot, rarity, credits, or XP")
	var challenge_dossier := scene.find_child("ChallengeCurrentDossier", true, false) as PanelContainer
	check(challenge_dossier.get_theme_stylebox("panel") is StyleBoxTexture, "the current Rift enemy uses the approved focal frame")
	check(scene.find_child("ChallengeAnomalyRule", true, false) != null, "challenge dossier exposes its class-neutral anomaly profile before entry")
	var enter := scene.find_child("ChallengeEnterAction", true, false) as Button
	check(enter != null and enter.disabled and enter.size.y >= 48.0 and enter.get_parent() == scene.content, "consumed daily entry remains a fixed disabled Android action outside the evidence scroller")
	var final_build := Simulator.checkpoint_player(Simulator.CHECKPOINTS[11], Builds.POLICIES[0])
	Simulator.apply_prior_rewards(final_build, 11)
	for field in final_build:
		state.player[field] = final_build[field]
	state.player.challenge_floor = 11
	state.player.rift_reality_progress = {Challenge.FIRST_REALITY_ID: 11}
	state.player.sound_enabled = false
	state.phase = state.Phase.BOARD
	check(state.start_challenge(str(Challenge.STAGES[11].id), 102.0 * DAY_SECONDS), "the final relic enemy starts through the same keyed daily transaction")
	state.enemy_hp = 0
	state.finish_combat(true)
	check(str(state.pending_loot.slot) == "relic" and str(state.pending_loot.id) == "rift_last_claim_reward", "the final victory creates the canonical relic")
	state.open_reward()
	scene.render()
	await process_frame
	check(scene.find_children("*", "Label", true, false).any(func(label): return (label as Label).text.contains("FENDA SERÁ CONCLUÍDA")), "the final reward announces completion instead of a nonexistent floor 13")
	var final_summary: Dictionary = state.claim_reward(true)
	check(bool(final_summary.get("challenge", false)) and int(state.player.challenge_floor) == Challenge.STAGES.size(), "claiming the final relic closes exactly twelve floors")
	check(str(state.player.relic.id) == "rift_last_claim_reward" and Challenge.current_stage(state.player).is_empty(), "the final relic equips and no phantom challenge remains")
	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	check(scene.find_child("ChallengeCompletePanel", true, false) != null and scene.find_child("ChallengeEnterAction", true, false) == null, "completed Rift renders a terminal archive without an entry action")
	state.player.level = 100
	var key_hunts := 0
	var discovered_reality := {}
	while discovered_reality.is_empty() and key_hunts < 5:
		state.player.wins = int(state.player.wins) + 1
		discovered_reality = Challenge.record_eligible_hunt_for_key(state.player)
		key_hunts += 1
	check(not discovered_reality.is_empty() and key_hunts <= 5, "completing the prior reality makes the next gameplay key drop within its bounded hunt pity")
	check(state.player.rift_reality_keys == ["dead_customs_key", "frozen_verdict_key"] and str(state.player.selected_rift_reality_id) == "frozen_verdict", "a discovered key is permanent, unique, and selects its newly opened reality")
	var second_opening := Challenge.current_stage(state.player)
	var second_reward := Challenge.reward_for(second_opening, ContentDB.ITEM_TRAITS)
	check(str(second_opening.id).begins_with("frozen_verdict__") and int(second_opening.power) >= int(Challenge.STAGES[11].power), "the second reality owns canonical composite enemies and opens above the first reality finale")
	check(str(second_reward.id).begins_with("frozen_verdict__") and str(second_reward.base_reward_id) == "rift_customs_drone_reward" and str(second_reward.localization_reward_id).begins_with("frozen_verdict__") and int(second_reward.power) == 2, "reality rewards remain unique while retaining mechanical lineage and their own localization identity")
	check(str(second_opening.name) == "Oficial do Segundo Congelado" and str(second_opening.attacks[0]) == "Carimbo de Geada", "the second reality opens with its own authored enemy and combat vocabulary")
	check(str(second_reward.name) == "Arnês do Prazo Suspenso" and str(second_reward.name) != str(Challenge.STAGES[0].reward.name), "the second reality owns a distinct collectible identity without changing its audited trait")
	var first_names := Challenge.STAGES.map(func(stage): return str(stage.name))
	var second_names: Array[String] = []
	var second_reward_names: Array[String] = []
	var unique_second_names := {}
	var unique_second_rewards := {}
	for identity_index in Challenge.STAGES.size():
		var identity_stage := Challenge.stage_at(identity_index, "frozen_verdict")
		second_names.append(str(identity_stage.name))
		second_reward_names.append(str(identity_stage.reward.name))
		unique_second_names[str(identity_stage.name)] = true
		unique_second_rewards[str(identity_stage.reward.name)] = true
	check(second_names.all(func(name): return not first_names.has(name)) and unique_second_names.size() == 12, "all twelve second-reality enemies are distinct from the first reality and from each other")
	check(unique_second_rewards.size() == 12, "all twelve sealed second-reality artifacts have distinct authored identities")
	scene.render()
	await process_frame
	var two_reality_selector := scene.find_child("ChallengeRealitySelector", true, false) as OptionButton
	check(two_reality_selector != null and two_reality_selector.item_count == 2, "the Rift selector exposes only the two realities whose keys are owned")
	check(state.select_rift_reality(Challenge.FIRST_REALITY_ID) and Challenge.current_stage(state.player).is_empty(), "the player can revisit a completed keyed reality without losing either ladder")

	state.player.level = 160
	state.player.rift_reality_progress = {Challenge.FIRST_REALITY_ID: 12, "frozen_verdict": 12}
	var third_key_hunts := 0
	var third_reality := {}
	while third_reality.is_empty() and third_key_hunts < 7:
		state.player.wins = int(state.player.wins) + 1
		third_reality = Challenge.record_eligible_hunt_for_key(state.player)
		third_key_hunts += 1
	check(not third_reality.is_empty() and third_key_hunts <= 7, "completing the frozen verdict makes the third gameplay key drop within seven eligible hunts")
	check(state.player.rift_reality_keys == ["dead_customs_key", "frozen_verdict_key", "rejected_futures_key"] and str(state.player.selected_rift_reality_id) == "rejected_futures", "the third key is permanent, sequential, and selects the new reality")
	var third_opening := Challenge.current_stage(state.player)
	var third_reward := Challenge.reward_for(third_opening, ContentDB.ITEM_TRAITS)
	check(str(third_opening.id).begins_with("rejected_futures__") and int(third_reality.unlock_level) == 160 and int(third_opening.power) > int(Challenge.stage_at(0, "frozen_verdict").power), "the third reality opens at its mature checkpoint with a stable composite enemy")
	check(str(third_opening.name) == "Fiscal de Vistos Temporais" and str(third_opening.attacks[0]) == "Visto Cronológico", "the third reality opens with its own authored enemy and combat vocabulary")
	check(str(third_reward.name) == "Arnês de Fronteira Temporal" and int(third_reward.power) == 3 and str(third_reward.localization_reward_id).begins_with("rejected_futures__"), "the third reality owns a stronger but still lateral sealed artifact identity")
	var all_prior_names := first_names + second_names
	var unique_third_names := {}
	var unique_third_rewards := {}
	for identity_index in Challenge.STAGES.size():
		var identity_stage := Challenge.stage_at(identity_index, "rejected_futures")
		unique_third_names[str(identity_stage.name)] = true
		unique_third_rewards[str(identity_stage.reward.name)] = true
		check(not all_prior_names.has(str(identity_stage.name)), "third-reality enemy %d does not recycle a prior identity" % (identity_index + 1))
	check(unique_third_names.size() == 12 and unique_third_rewards.size() == 12, "all third-reality enemies and sealed artifacts are authored and unique")
	for advanced_reality in [{"id": "frozen_verdict", "start": 100}, {"id": "rejected_futures", "start": 160}]:
		for reward_index in Challenge.STAGES.size():
			var reward_level := int(advanced_reality.start) + reward_index * 5
			var advanced_stage := Challenge.stage_at(reward_index, str(advanced_reality.id))
			var expected_credits := roundi(MissionRules.standard_credit_reward(reward_level) * 1.25)
			var expected_xp := roundi(MissionRules.standard_xp_reward(reward_level) * 1.25)
			var calibration_service := CoreRules.equipment_upgrade_credit_cost({"item_level": reward_level, "power": 1})
			check(int(advanced_stage.credits) == expected_credits and int(advanced_stage.xp) == expected_xp, "%s enemy %d pays the explicit 1.25x standard first-clear envelope" % [str(advanced_reality.id), reward_index + 1])
			check(int(advanced_stage.credits) >= calibration_service and int(advanced_stage.credits) <= calibration_service * 2, "%s enemy %d funds between one and two first workshop services" % [str(advanced_reality.id), reward_index + 1])
	for stage_index in Challenge.STAGES.size():
		var projected_level := 160 + stage_index * 5
		var class_odds: Array[float] = []
		for policy in Builds.POLICIES:
			var mature_player := mature_rift_player(projected_level, policy)
			apply_reality_rewards(mature_player, "rejected_futures", stage_index)
			class_odds.append(CoreRules.bounty_odds(mature_player, Challenge.stage_at(stage_index, "rejected_futures")))
		class_odds.sort()
		check(class_odds[0] >= 0.40 and class_odds[2] <= 0.90, "third-reality enemy %d stays viable and aspirational across all classes (%d-%d%%)" % [stage_index + 1, roundi(class_odds[0] * 100.0), roundi(class_odds[2] * 100.0)])
		check(class_odds[2] - class_odds[0] <= 0.30, "third-reality enemy %d keeps class spread within 30 percentage points" % (stage_index + 1))
	scene.render()
	await process_frame
	var three_reality_selector := scene.find_child("ChallengeRealitySelector", true, false) as OptionButton
	check(three_reality_selector != null and three_reality_selector.item_count == 3 and three_reality_selector.selected == 2, "the keyed selector exposes all three owned realities without revealing future content")
	check(scene.find_child("ChallengeCurrentDossier", true, false) != null and scene.find_child("ChallengeEnterAction", true, false) != null, "the third-reality dossier retains its scrollable evidence and fixed daily action")
	scene.queue_free()
	await process_frame
	finish()


func mature_rift_player(level: int, policy: Dictionary) -> Dictionary:
	var player := state_default_player()
	player.level = level
	player.base_power = 10 + (level - 1) * 2
	player.stat_points = (level - 1) * CoreRules.ATTRIBUTE_POINTS_PER_LEVEL
	var prior_mission_power := 11 + maxi(0, level - 2) * 5
	var gear_power := maxi(1, roundi(float(prior_mission_power) * 0.55))
	player.weapon = {"id": "third_rift_weapon", "slot": "weapon", "power": gear_power}
	player.armor = {"id": "third_rift_armor", "slot": "armor", "power": gear_power}
	Builds.configure_player(player, policy)
	return player


func state_default_player() -> Dictionary:
	var probe = StateScript.new()
	probe.persistence_enabled = false
	var player: Dictionary = probe.default_player()
	probe.free()
	return player


func apply_reality_rewards(player: Dictionary, reality_id: String, stage_index: int) -> void:
	for reward_index in stage_index:
		var reward := Challenge.reward_for(Challenge.stage_at(reward_index, reality_id), ContentDB.ITEM_TRAITS)
		if CoreRules.is_upgrade_for_player(player, reward):
			player[str(reward.slot)] = reward
	CoreRules.clear_bounty_odds_cache()


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
