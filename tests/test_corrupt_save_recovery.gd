extends SceneTree

var failures := 0
var test_save := "res://.godot/crooked_galaxy_unrecoverable_%s.json" % OS.get_process_id()
var corrupt_contents := "{ valuable but truncated progress"


func _init() -> void:
	call_deferred("run_corrupt_save_audit")


func run_corrupt_save_audit() -> void:
	var file := FileAccess.open(test_save, FileAccess.WRITE)
	file.store_string(corrupt_contents)
	file = null
	var state = root.get_node_or_null("GameState")
	state.save_path = test_save
	state.persistence_enabled = true
	state.load_game()
	check(state.save_recovery_required and not state.save_warning.is_empty(), "unrecoverable save blocks ordinary writes with a visible explanation")
	check(not state.save_game(), "ordinary save cannot overwrite the only damaged artifact")
	check(read_text(test_save) == corrupt_contents, "blocked save leaves the damaged primary byte-for-byte intact")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.find_child("StartFreshSaveAction", true, false) != null, "recovery screen offers an explicit fresh-start decision")
	check(scene.find_child("BountyScroll", true, false) == null, "recovery screen blocks gameplay that could create unsaved progress")
	var fresh := scene.find_child("StartFreshSaveAction", true, false) as Button
	fresh.pressed.emit()
	await process_frame
	check(not state.save_recovery_required and state.save_warning.is_empty(), "confirmed fresh start clears the recovery block after saving")
	check(FileAccess.file_exists("%s.corrupt" % test_save) and read_text("%s.corrupt" % test_save) == corrupt_contents, "fresh start preserves the exact damaged artifact")
	var primary: Dictionary = state.read_save_dictionary(test_save)
	check(not primary.is_empty() and int(primary.version) == state.SAVE_VERSION and int(primary.player.credits) == 25, "fresh start creates a valid canonical primary")
	check(not state.read_save_dictionary("%s.bak" % test_save).is_empty(), "fresh start also establishes a valid recovery backup")
	check(scene.find_child("BountyScroll", true, false) != null, "successful fresh start returns to the actionable bounty board")

	scene.free()
	await process_frame
	state.persistence_enabled = false
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save, "%s.corrupt" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await create_timer(0.5).timeout
	finish()


func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func finish() -> void:
	if failures == 0:
		print("PASS: unrecoverable saves require an explicit artifact-preserving fresh start")
		quit(0)
	else:
		printerr("FAIL: %d corrupt save recovery issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
