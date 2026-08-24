extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Classes = preload("res://scripts/class_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_classes_test")


func run_classes_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for the class test")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	check(Classes.DEFINITIONS.size() == 3, "the first class roster has three focused archetypes")
	var primaries := Classes.DEFINITIONS.map(func(definition): return str(definition.primary_attribute))
	check(primaries == ["strength", "dexterity", "intelligence"], "the roster specializes the three offensive attributes without consuming vitality or cunning")
	check(str(state.player.class_id).is_empty() and Classes.specialization_power(state.player, Rules.BASE_ATTRIBUTE_VALUE) == 0, "new hunters remain safely unassigned until the player chooses")

	for definition in Classes.DEFINITIONS:
		var unassigned: Dictionary = state.default_player()
		var specialized: Dictionary = unassigned.duplicate(true)
		var primary := str(definition.primary_attribute)
		unassigned.attributes[primary] = 12
		specialized.attributes[primary] = 12
		specialized.class_id = str(definition.id)
		check(Rules.player_power(specialized) == Rules.player_power(unassigned) + 1, "%s gains the documented primary-stat specialization" % str(definition.name))

	check(not state.select_class("totally_real_class"), "unknown classes cannot enter the save")
	check(state.select_class("warrant_breaker") and str(state.player.class_id) == "warrant_breaker", "a valid board selection commits immediately")
	check(state.select_class("contract_hacker") and str(state.player.class_id) == "contract_hacker", "early-access reclassification remains free and reversible")
	state.phase = state.Phase.BRIEFING
	check(not state.select_class("orbit_gunslinger") and str(state.player.class_id) == "contract_hacker", "class changes cannot alter a committed contract")

	state.phase = state.Phase.BOARD
	state.player = state.default_player()
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check((scene.find_child("BoardAttributesAction", true, false) as Button).text == "ESCOLHER CLASSE", "the board makes an unassigned class discoverable")
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	check(scene.find_child("HunterClassSummary", true, false) != null and scene.find_child("ChooseClassAction", true, false) != null, "the attribute profile exposes its class summary")
	scene.view_mode = "classes"
	scene.render()
	await process_frame
	check(scene.find_children("Class_*", "PanelContainer", true, false).size() == 3, "the class screen renders every initial archetype")
	var select := scene.find_child("ClassSelect_orbit_gunslinger", true, false) as Button
	check(select != null and not select.disabled, "an archetype can be drafted from its mobile action")
	if select != null:
		select.pressed.emit()
		await process_frame
	check(scene.class_draft == "orbit_gunslinger" and str(state.player.class_id).is_empty(), "class selection remains a reversible draft before confirmation")
	var confirm := scene.find_child("ConfirmClass", true, false) as Button
	check(confirm != null and not confirm.disabled, "a changed class draft enables explicit confirmation")
	if confirm != null:
		confirm.pressed.emit()
		await process_frame
	check(str(state.player.class_id) == "orbit_gunslinger" and scene.class_draft.is_empty(), "confirmation commits the class and clears transient navigation state")
	check(scene.android_back_action() == "board", "Android Back treats the class selector as a safe secondary hub")

	scene.free()
	await process_frame
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: thematic classes specialize attributes and commit safely")
		quit(0)
	else:
		printerr("FAIL: %d class system test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
