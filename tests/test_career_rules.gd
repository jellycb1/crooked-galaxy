extends SceneTree

const CareerRules = preload("res://scripts/career_rules.gd")

var failures := 0


func _init() -> void:
	var player := {
		"wins": 12,
		"captures_by_target": {"repeat": 3},
		"completed_planets": ["a", "b", "c", "d", "e"],
		"scrap_recycled_total": 25,
		"best_capture_streak": 5,
		"claimed_milestones": ["first_warrant"],
	}
	var milestones := CareerRules.milestones(player)
	check(milestones.size() == 8, "career rules expose every milestone")
	check(milestones.all(func(milestone): return bool(milestone.complete)), "advanced progress completes every milestone")
	var ready := CareerRules.rewards_ready(player)
	check(ready.size() == 7, "ready rewards exclude claimed milestones")
	check(not ready.any(func(milestone): return str(milestone.id) == "first_warrant"), "claimed stable ids cannot become ready again")
	check(player.claimed_milestones.size() == 1, "derived career rules do not mutate player progress")
	var targets := [
		{"id": "far", "name": "Far", "planet_id": "a"},
		{"id": "near", "name": "Near", "planet_id": "a"},
		{"id": "mastered", "name": "Mastered", "planet_id": "a"},
	]
	player.captures_by_target = {"far": 3, "near": 5, "mastered": 10}
	var objective := CareerRules.next_mastery_objective(player, targets)
	check(str(objective.target.id) == "near" and int(objective.remaining) == 1, "career recommends the closest unfinished mastery tier")
	check(int(objective.next_level) == 2 and int(objective.rare_bonus) == 10 and int(objective.epic_bonus) == 4 and int(objective.scrap_bonus) == 10, "mastery objective explains the next loot and workshop bonus")
	player.captures_by_target = {"mastered": 10}
	check(CareerRules.next_mastery_objective(player, targets).is_empty(), "fully mastered archives need no repeat directive")

	if failures == 0:
		print("PASS: career milestones and repeat objectives are deterministic")
		quit(0)
	else:
		printerr("FAIL: %d career rule test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
