extends SceneTree

const CareerRules = preload("res://scripts/career_rules.gd")
const ChallengeRules = preload("res://scripts/challenge_rules.gd")
const CollectionRules = preload("res://scripts/collection_rules.gd")
const DailyRules = preload("res://scripts/daily_objective_rules.gd")
const WeeklyRules = preload("res://scripts/weekly_operation_rules.gd")

var failures := 0


func _init() -> void:
	check(ContentDB.PLANETS.size() == 35 and ContentDB.TARGETS.size() == 140 and ContentDB.HUNT_EVENTS.size() == 70, "the launch mission axis is complete")
	check(ContentDB.procedural_collection_total() == 2180, "the permanent equipment collection spans the complete launch catalog")
	check(DailyRules.OBJECTIVE_IDS.size() == 3 and WeeklyRules.OBJECTIVE_IDS.size() == 3, "daily and weekly objective ladders remain bounded")
	var rift_victories := 0
	for reality in ChallengeRules.REALITIES:
		rift_victories += reality.stages.size()
	check(ChallengeRules.REALITIES.size() == 3 and rift_victories == 36, "the current Rift contributes exactly 36 first-clear days")
	var circuit_player := {"level": 320}
	var circuit_worlds := {}
	for week_id in 12:
		for planet_id in WeeklyRules.rotating_planet_ids(circuit_player, week_id):
			circuit_worlds[planet_id] = true
	check(circuit_worlds.size() == 35, "twelve mature Network Circuits rotate the complete launch world catalog")
	check(WeeklyRules.ROUTE_PLANET_QUOTA == 2 and WeeklyRules.ROUTE_REWARD_CREDITS == 250 and WeeklyRules.ROUTE_REWARD_SCRAP == 18, "the repeatable route keeps a six-hunt bounded weekly reward envelope")

	var complete_player := {
		"wins": 3000,
		"level": 320,
		"captures_by_target": {"gloop": 3},
		"scrap_recycled_total": 25,
		"best_capture_streak": 5,
		"claimed_milestones": [],
	}
	var milestones := CareerRules.milestones(complete_player)
	var milestone_ids := milestones.map(func(milestone): return str(milestone.id))
	for id in ["hundred_warrants", "five_hundred_warrants", "thousand_warrants", "two_thousand_warrants", "three_thousand_warrants"]:
		check(milestone_ids.has(id), "career ladder covers warrant horizon %s" % id)
	for id in ["ten_frontiers", "fifteen_frontiers", "twenty_frontiers", "twenty_five_frontiers", "thirty_frontiers", "complete_launch_atlas"]:
		check(milestone_ids.has(id), "career ladder covers discovery horizon %s" % id)
	check(milestones.size() == 19 and milestones.all(func(milestone): return bool(milestone.complete)), "nineteen stable milestones span onboarding through launch completion")
	var total_credits := 0
	var total_scrap := 0
	for milestone in milestones:
		total_credits += int(milestone.credits)
		total_scrap += int(milestone.scrap)
	check(total_credits == 46230 and total_scrap == 482, "career rewards remain explicit and bounded across the complete ladder")
	check(CollectionRules.milestones({}, ContentDB.procedural_collection_total()).back().threshold == 2180, "collection completion follows catalog growth")

	if failures == 0:
		print("PASS: launch content coverage and long-horizon career goals are explicit")
	quit(1 if failures > 0 else 0)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
