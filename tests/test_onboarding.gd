extends SceneTree

const Species = preload("res://scripts/species_rules.gd")

var failures := 0
var state
var test_save_path := ""


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for onboarding")
	if state == null:
		finish()
		return
	test_save_path = "user://onboarding_test_%d.json" % Time.get_ticks_usec()
	state.save_path = test_save_path
	state.persistence_enabled = true
	state.account = {}
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	check(Species.DEFINITIONS.size() == 3 and Species.DEFINITIONS.all(func(definition): return bool(definition.prototype)), "the first species roster is explicitly provisional")
	check(state.requires_onboarding() and state.onboarding_step() == "login", "a new local profile cannot bypass login")
	state.select_bounty(ContentDB.TARGETS[0])
	check(state.phase == state.Phase.BOARD and state.current_bounty.is_empty(), "state-level bounty entry is blocked before identity completion")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.find_child("OnboardingLoginAction", true, false) != null and scene.find_child("HeaderResourceStrip", true, false) == null, "login replaces the game shell instead of overlaying it")
	check_onboarding_touch_targets(scene, "login")
	var login := scene.find_child("OnboardingLoginAction", true, false) as Button
	login.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "class" and state.account.keys().all(func(key): return key == "mode" or key == "session_id"), "local login stores session identity without credentials")
	check(scene.find_children("OnboardingClass_*", "PanelContainer", true, false).size() == 3, "mandatory class step shows the complete prototype trio")
	check_onboarding_touch_targets(scene, "class")
	var class_confirm := scene.find_child("OnboardingClassConfirm", true, false) as Button
	check(class_confirm != null and class_confirm.disabled, "class confirmation requires an explicit choice")
	var class_action := scene.find_child("OnboardingClassAction_contract_hacker", true, false) as Button
	class_action.pressed.emit()
	await process_frame
	class_confirm = scene.find_child("OnboardingClassConfirm", true, false) as Button
	check(class_confirm != null and not class_confirm.disabled and str(state.player.class_id).is_empty(), "class focus remains a draft until confirmation")
	class_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "species" and str(state.player.class_id) == "contract_hacker", "confirmed class advances exactly to species")
	check(scene.find_children("OnboardingSpecies_*", "PanelContainer", true, false).size() == 3, "species step exposes three replaceable origins")
	check(scene.find_children("OnboardingSpeciesIcon_*", "Control", true, false).size() == 3, "every provisional species has an original scalable emblem")
	check_onboarding_touch_targets(scene, "species")
	var species_action := scene.find_child("OnboardingSpeciesAction_discontinued_synthetic", true, false) as Button
	species_action.pressed.emit()
	await process_frame
	var species_confirm := scene.find_child("OnboardingSpeciesConfirm", true, false) as Button
	check(species_confirm != null and not species_confirm.disabled and str(state.player.species_id).is_empty(), "species focus remains a draft until confirmation")
	species_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "name" and str(state.player.species_id) == "discontinued_synthetic", "confirmed species advances exactly to hunter naming")
	check(scene.find_child("OnboardingHunterPortrait", true, false) != null and scene.find_child("OnboardingChangeClass", true, false) != null and scene.find_child("OnboardingChangeSpecies", true, false) != null, "final identity review shows the hunter and both correction routes")
	var change_class := scene.find_child("OnboardingChangeClass", true, false) as Button
	change_class.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "class" and str(state.player.species_id) == "discontinued_synthetic", "class correction retains the already confirmed species")
	(scene.find_child("OnboardingClassAction_contract_hacker", true, false) as Button).pressed.emit()
	await process_frame
	(scene.find_child("OnboardingClassConfirm", true, false) as Button).pressed.emit()
	await process_frame
	var change_species := scene.find_child("OnboardingChangeSpecies", true, false) as Button
	change_species.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "species" and str(state.player.class_id) == "contract_hacker", "species correction retains the already confirmed class")
	(scene.find_child("OnboardingSpeciesAction_discontinued_synthetic", true, false) as Button).pressed.emit()
	await process_frame
	(scene.find_child("OnboardingSpeciesConfirm", true, false) as Button).pressed.emit()
	await process_frame
	check(state.onboarding_step() == "name", "corrected class and species return to final naming")
	var name_input := scene.find_child("OnboardingNameInput", true, false) as LineEdit
	var name_confirm := scene.find_child("OnboardingNameConfirm", true, false) as Button
	check(name_input != null and name_confirm != null and name_confirm.disabled, "empty hunter names cannot finish creation")
	check_onboarding_touch_targets(scene, "name")
	name_input.text = "  Nova   Vex  "
	name_input.text_changed.emit(name_input.text)
	await process_frame
	check(not name_confirm.disabled, "a valid mobile name enables explicit entry")
	name_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "complete" and str(state.player.hunter_name) == "Nova Vex", "completion stores the normalized hunter name")
	check(scene.find_child("HeaderResourceStrip", true, false) != null and scene.find_child("PrimaryNavigationDock", true, false) != null, "completed identity enters the real game shell")
	check(scene.find_child("OnboardingScroll", true, false) == null, "onboarding is removed after completion")

	var persisted: Dictionary = state.read_save_dictionary(test_save_path)
	check(str(persisted.account.mode) == "local_test" and str(persisted.player.class_id) == "contract_hacker" and str(persisted.player.species_id) == "discontinued_synthetic" and str(persisted.player.hunter_name) == "Nova Vex", "every confirmed onboarding stage survives interruption")
	scene.queue_free()
	await process_frame
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func check_onboarding_touch_targets(scene: Control, step: String) -> void:
	for candidate in scene.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button.visible:
			check(button.custom_minimum_size.y >= 48.0, "%s action '%s' remains a mobile touch target" % [step, str(button.name)])


func finish() -> void:
	state.persistence_enabled = false
	for path in [test_save_path, "%s.tmp" % test_save_path, "%s.bak" % test_save_path]:
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("PASS: mandatory onboarding gates and persists hunter identity")
		quit(0)
	else:
		printerr("FAIL: %d onboarding issue(s)" % failures)
		quit(1)
