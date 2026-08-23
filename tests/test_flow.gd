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
	state.start_bounty(bounty)
	check(state.phase == state.Phase.HUNT, "accepting a bounty starts a hunt")

	state.hunt_ends_at = 0.0
	state.update_hunt()
	check(state.phase == state.Phase.COMBAT, "elapsed hunt starts combat")
	check(state.player_hp > 0 and state.enemy_hp == 1, "combat initializes health")

	var result: Dictionary = state.combat_step()
	check(bool(result.get("won", false)), "winning combat is detected")
	check(state.phase == state.Phase.REWARD, "victory opens the reward phase")
	check(not state.pending_loot.is_empty(), "victory generates loot")

	var credits_before := int(state.player.credits)
	var claimed_item: Dictionary = state.pending_loot.duplicate(true)
	var summary := state.claim_reward(true)
	check(state.phase == state.Phase.BOARD, "claiming returns to the bounty board")
	check(int(state.player.credits) == credits_before + int(bounty.credits), "credits are awarded")
	check(int(summary.xp) == int(bounty.xp), "XP reward is reported")
	check(state.player.inventory.size() == 1, "loot is retained in inventory")
	check(int(state.player.wins) == 1, "victory progression is retained")
	check(str(state.player[str(claimed_item.slot)].id) == str(claimed_item.id), "claimed upgrade is equipped")
	check(not state.last_notice.is_empty(), "reward feedback survives the screen transition")
	check(int(state.player.reputation) == 0, "rank requires three captures")

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
