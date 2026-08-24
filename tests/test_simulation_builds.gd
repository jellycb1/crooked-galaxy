extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Builds = preload("res://tools/simulation_builds.gd")

var failures := 0


func _init() -> void:
	for policy in Builds.POLICIES:
		var player := {
			"class_id": "",
			"attributes": Rules.default_attributes(),
			"stat_points": 8,
		}
		Builds.configure_player(player, policy)
		var cycle: Array = policy.allocation_cycle
		var primary_id := str(cycle[0])
		check(str(player.class_id) == str(policy.class_id), "%s selects its declared prototype class" % str(policy.name))
		check(int(player.stat_points) == 0 and Builds.total_investment(player.attributes) == 8, "%s spends every earned point exactly once" % str(policy.name))
		check(int(player.attributes[primary_id]) == 14 and int(player.attributes.vitality) == 12 and int(player.attributes.cunning) == 12, "%s follows the 50/25/25 primary-vitality-cunning policy" % str(policy.name))

	var control := {"class_id": "", "attributes": Rules.default_attributes(), "stat_points": 8}
	Builds.configure_player(control, Builds.CONTROL_POLICY)
	check(str(control.class_id).is_empty() and int(control.stat_points) == 8 and Builds.total_investment(control.attributes) == 0, "legacy control remains unassigned and intentionally leaves points untouched")
	check(Builds.selected_policies("missing_build").is_empty(), "unknown build filters fail closed instead of silently selecting another profile")

	if failures == 0:
		print("PASS: campaign build policies allocate classes and attributes deterministically")
		quit(0)
	else:
		printerr("FAIL: %d simulation build policy test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
