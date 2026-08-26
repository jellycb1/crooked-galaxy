extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const CareerRulesScript = preload("res://scripts/career_rules.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_career_persistence_%s.json" % OS.get_process_id()


func _init() -> void:
	audit_individual_claims()
	audit_bulk_profiles()
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("PASS: career reward claims are atomic across campaign stages")
		quit(0)
	else:
		printerr("FAIL: %d career persistence issue(s)" % failures)
		quit(1)


func audit_individual_claims() -> void:
	var reference := complete_state()
	var milestones := reference.career_milestones()
	reference.free()
	for milestone in milestones:
		var source := complete_state()
		var credits_before := int(source.player.credits)
		var scrap_before := int(source.player.scrap)
		check(source.claim_career_milestone(str(milestone.id)), "milestone %s can be claimed" % str(milestone.id))
		var restored = restore_state()
		var context := str(milestone.id)
		check(restored.last_notice_context != "system_recovery", "milestone %s reloads without recovery" % context)
		check(restored.player.claimed_milestones == [context], "milestone %s persists exactly one claim" % context)
		check(int(restored.player.credits) == credits_before + int(milestone.credits), "milestone %s credits persist once" % context)
		check(int(restored.player.scrap) == scrap_before + int(milestone.scrap), "milestone %s scrap persists once" % context)
		check(int(restored.player.career_credits_claimed) == int(milestone.credits) and int(restored.player.career_scrap_claimed) == int(milestone.scrap), "milestone %s career totals persist" % context)
		var credits_after := int(restored.player.credits)
		var scrap_after := int(restored.player.scrap)
		check(not restored.claim_career_milestone(context), "milestone %s rejects duplicate claim" % context)
		check(int(restored.player.credits) == credits_after and int(restored.player.scrap) == scrap_after, "milestone %s duplicate rejection is side-effect free" % context)
		restored.free()
		source.free()


func audit_bulk_profiles() -> void:
	var profiles := [
		{"name": "early", "wins": 1},
		{"name": "mid", "wins": 5, "captures_by_target": {"gloop": 3}, "completed_count": 1, "scrap_recycled_total": 25, "best_capture_streak": 5},
		{"name": "complete", "wins": 30, "captures_by_target": {"gloop": 10}, "completed_count": ContentDB.PLANETS.size(), "scrap_recycled_total": 25, "best_capture_streak": 10},
	]
	for profile in profiles:
		var source := configured_state(profile)
		var ready := CareerRulesScript.rewards_ready(source.player)
		var expected_credits := 0
		var expected_scrap := 0
		var expected_ids: Array = []
		for milestone in ready:
			expected_credits += int(milestone.credits)
			expected_scrap += int(milestone.scrap)
			expected_ids.append(str(milestone.id))
		var credits_before := int(source.player.credits)
		var scrap_before := int(source.player.scrap)
		var result := source.claim_all_career_milestones()
		check(int(result.count) == ready.size() and int(result.credits) == expected_credits and int(result.scrap) == expected_scrap, "%s bulk claim reports exact rewards" % str(profile.name))
		var restored = restore_state()
		check(restored.last_notice_context != "system_recovery", "%s bulk claim reloads without recovery" % str(profile.name))
		check(int(restored.player.credits) == credits_before + expected_credits and int(restored.player.scrap) == scrap_before + expected_scrap, "%s bulk wallet persists atomically" % str(profile.name))
		check(int(restored.player.career_credits_claimed) == expected_credits and int(restored.player.career_scrap_claimed) == expected_scrap, "%s bulk career totals persist atomically" % str(profile.name))
		check(restored.player.claimed_milestones == expected_ids and restored.career_rewards_ready() == 0, "%s bulk claim consumes every ready milestone" % str(profile.name))
		var credits_after := int(restored.player.credits)
		var scrap_after := int(restored.player.scrap)
		var duplicate := restored.claim_all_career_milestones()
		check(int(duplicate.count) == 0 and int(restored.player.credits) == credits_after and int(restored.player.scrap) == scrap_after, "%s duplicate bulk claim is side-effect free" % str(profile.name))
		restored.free()
		source.free()


func complete_state() -> StateScript:
	return configured_state({
		"wins": 30,
		"captures_by_target": {"gloop": 10},
		"completed_count": ContentDB.PLANETS.size(),
		"scrap_recycled_total": 25,
		"best_capture_streak": 10,
	})


func configured_state(profile: Dictionary) -> StateScript:
	var state = StateScript.new()
	state.save_path = test_save
	state.player = state.default_player()
	state.player.wins = int(profile.get("wins", 0))
	state.player.captures_by_target = profile.get("captures_by_target", {}).duplicate(true)
	state.player.scrap_recycled_total = int(profile.get("scrap_recycled_total", 0))
	state.player.best_capture_streak = int(profile.get("best_capture_streak", 0))
	var discovery_levels := [1, 4, 8, 13, 19]
	var requested_discoveries := int(profile.get("completed_count", 0))
	state.player.level = discovery_levels[mini(discovery_levels.size() - 1, requested_discoveries)] if requested_discoveries > 0 else 1
	var completed: Array = []
	for index in int(profile.get("completed_count", 0)):
		completed.append(str(ContentDB.PLANETS[index].id))
	state.player.completed_planets = completed
	return state


func restore_state() -> StateScript:
	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	return restored


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
