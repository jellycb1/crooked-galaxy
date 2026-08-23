extends SceneTree

const CareerRules = preload("res://scripts/career_rules.gd")

var failures := 0


func _init() -> void:
	var player := {
		"wins": 12,
		"captures_by_target": {"repeat": 3},
		"completed_planets": ["a", "b", "c", "d"],
		"scrap_recycled_total": 25,
		"best_capture_streak": 5,
		"claimed_milestones": ["first_warrant"],
	}
	var milestones := CareerRules.milestones(player)
	check(milestones.size() == 7, "career rules expose every milestone")
	check(milestones.all(func(milestone): return bool(milestone.complete)), "advanced progress completes every milestone")
	var ready := CareerRules.rewards_ready(player)
	check(ready.size() == 6, "ready rewards exclude claimed milestones")
	check(not ready.any(func(milestone): return str(milestone.id) == "first_warrant"), "claimed stable ids cannot become ready again")
	check(player.claimed_milestones.size() == 1, "derived career rules do not mutate player progress")

	if failures == 0:
		print("PASS: career milestones are deterministic")
		quit(0)
	else:
		printerr("FAIL: %d career rule test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
