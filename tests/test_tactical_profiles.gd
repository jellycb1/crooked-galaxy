extends SceneTree

const Profiles = preload("res://scripts/enemy_profile_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Classes = preload("res://scripts/class_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	check(Profiles.profile_id_for(ContentDB.TARGETS[0]) == "training", "Dustball remains a readable profile tutorial")
	check(Profiles.profile_id_for(ContentDB.TARGETS[4]) == "plated" and Profiles.profile_id_for(ContentDB.TARGETS[5]) == "reckless" and Profiles.profile_id_for(ContentDB.TARGETS[6]) == "elusive" and Profiles.profile_id_for(ContentDB.TARGETS[7]) == "elite", "later chapters teach three rotating tactical profiles and a mixed boss")
	check(is_equal_approx(Profiles.modifier(ContentDB.TARGETS[4], "opening_damage_multiplier", 1.0), 0.85) and is_equal_approx(Profiles.modifier(ContentDB.TARGETS[5], "damage_reduction_piercing", 0.0), 0.15), "profile modifiers resolve from target identity without mutating content")
	var explicit := ContentDB.TARGETS[4].duplicate(true)
	explicit.opening_damage_multiplier = 2.0
	check(is_equal_approx(Profiles.modifier(explicit, "opening_damage_multiplier", 1.0), 2.0), "explicit incidents and challenge anomalies override ordinary enemy profiles")

	var temporary_state := StateScript.new()
	var neutral := temporary_state.default_player()
	temporary_state.free()
	var counter_rig := {"trait": ContentDB.ITEM_TRAITS.rig[1].duplicate(true)}
	var burst_rig := {"trait": ContentDB.ITEM_TRAITS.rig[2].duplicate(true)}
	var evasion_implant := {"trait": ContentDB.ITEM_TRAITS.implant[1].duplicate(true)}
	var overload_implant := {"trait": ContentDB.ITEM_TRAITS.implant[2].duplicate(true)}
	neutral.rig = counter_rig
	check(Rules.player_counter_damage(neutral, 3) == 0 and Rules.player_counter_damage(neutral, 4) == 1, "counterweight rig grants every class a four-round retaliation cadence")
	neutral.rig = burst_rig
	check(Rules.player_follow_up_damage(neutral, 0.98, 20) == 0 and Rules.player_follow_up_damage(neutral, 0.99, 20) == 1, "quickdraw rig grants every class a bounded perfect-shot burst")
	neutral.rig = {}
	neutral.implant = evasion_implant
	check(is_equal_approx(Rules.player_evasion_chance(neutral), 0.01), "adrenaline implant grants class-neutral evasion")
	neutral.implant = overload_implant
	check(Rules.player_defense_bypass(neutral) == 1, "null implant grants class-neutral defense bypass")

	var breaker := neutral.duplicate(true)
	breaker.class_id = "warrant_breaker"
	breaker.rig = counter_rig
	breaker.implant = {}
	check(Rules.player_counter_damage(breaker, 12) == 2, "class and universal counter mechanics combine additively")
	var gunslinger := neutral.duplicate(true)
	gunslinger.class_id = "orbit_gunslinger"
	gunslinger.rig = burst_rig
	gunslinger.implant = {}
	check(Rules.player_follow_up_damage(gunslinger, 0.99, 20) == 3, "class and universal burst mechanics combine without slot restrictions")
	var hacker := neutral.duplicate(true)
	hacker.class_id = "contract_hacker"
	hacker.rig = {}
	hacker.implant = overload_implant
	check(Rules.player_defense_bypass(hacker) == Classes.specialization_defense_bypass(hacker, Rules.BASE_ATTRIBUTE_VALUE) + 1, "class and universal overload mechanics combine additively")

	var state = root.get_node_or_null("GameState")
	state.persistence_enabled = false
	state.player = state.default_player()
	state.current_bounty = ContentDB.TARGETS[4].duplicate(true)
	state.offered_approaches = ContentDB.contract_approaches()
	state.phase = state.Phase.BRIEFING
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var profile_card := scene.find_child("BriefingEnemyProfile", true, false)
	check(profile_card != null and find_label(scene, "BLINDAGEM IMPROVISADA") != null and find_label(scene, "SOBRECARGA") != null, "briefing exposes enemy behavior and a class-neutral build response")
	state.begin_combat()
	await process_frame
	check(scene.find_child("CombatEnemyProfile", true, false) != null, "combat keeps the selected enemy profile visible")
	scene.free()
	finish()


func find_label(node: Node, fragment: String) -> Label:
	for candidate in node.find_children("*", "Label", true, false):
		if fragment in str((candidate as Label).text):
			return candidate as Label
	return null


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: enemy profiles and universal tactical equipment are coherent")
		quit(0)
	else:
		printerr("FAIL: %d tactical profile test(s) failed" % failures)
		quit(1)
