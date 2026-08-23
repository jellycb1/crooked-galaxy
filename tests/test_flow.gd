extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.rng.seed = 7331

	var bounty: Dictionary = Content.TARGETS[0].duplicate(true)
	bounty.health = 1
	state.select_bounty(bounty)
	check(state.phase == state.Phase.BRIEFING, "selecting a target opens the briefing")
	check(state.offered_approaches.size() == 3, "briefing offers three approaches")
	state.choose_approach("quiet_net")
	check(state.phase == state.Phase.HUNT, "choosing an approach starts a hunt")
	check(str(state.current_bounty.approach.id) == "quiet_net", "approach is attached to the contract")
	var active_bounty: Dictionary = state.current_bounty.duplicate(true)

	state.hunt_ends_at = 0.0
	state.update_hunt()
	check(state.phase == state.Phase.COMBAT, "elapsed hunt starts combat")
	check(state.player_hp > 0 and state.enemy_hp == 1, "combat initializes health")

	var result: Dictionary = state.combat_step()
	check(bool(result.get("won", false)), "winning combat is detected")
	check(state.phase == state.Phase.VICTORY, "victory opens the capture beat")
	check(state.combat_events.size() == 1, "combat records the finishing action")
	check(not state.pending_loot.is_empty(), "victory generates loot")
	state.open_reward()
	check(state.phase == state.Phase.REWARD, "capture beat opens the reward phase")

	var credits_before := int(state.player.credits)
	var claimed_item: Dictionary = state.pending_loot.duplicate(true)
	var summary := state.claim_reward(true)
	check(state.phase == state.Phase.BOARD, "claiming returns to the bounty board")
	check(int(state.player.credits) == credits_before + int(active_bounty.credits), "modified credits are awarded")
	check(int(summary.xp) == int(active_bounty.xp), "modified XP reward is reported")
	check(state.player.inventory.size() == 1, "loot is retained in inventory")
	check(int(state.player.wins) == 1, "victory progression is retained")
	check(str(state.player[str(claimed_item.slot)].id) == str(claimed_item.id), "claimed upgrade is equipped")
	check(not state.last_notice.is_empty(), "reward feedback survives the screen transition")
	check(int(state.player.reputation) == 0, "rank requires three captures")

	state.start_bounty(Content.TARGETS[0].duplicate(true))
	state.begin_combat()
	state.enemy_hp = 9999
	state.player_hp = 1
	var defeat := state.combat_step()
	check(bool(defeat.get("finished", false)) and not bool(defeat.get("won", true)), "defeat is detected")
	check(state.phase == state.Phase.BOARD, "defeat returns to the bounty board")
	check(not state.last_notice.is_empty(), "defeat explains what happened")
	state.select_bounty(Content.TARGETS[0])
	state.cancel_briefing()
	check(state.phase == state.Phase.BOARD and state.current_bounty.is_empty(), "briefing can be cancelled safely")
	state.toggle_sound()
	check(not bool(state.player.sound_enabled), "audio preference can be disabled")

	state.free()
	if failures == 0:
		print("PASS: complete bounty flow")
		quit(0)
	else:
		printerr("FAIL: %d flow test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
