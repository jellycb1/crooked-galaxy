extends SceneTree

var failures := 0
var test_dir := "res://.godot/unavailable_save_%s" % OS.get_process_id()
var test_save := "%s/progress.json" % test_dir


func _init() -> void:
	call_deferred("run_save_failure_audit")


func run_save_failure_audit() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for save failure audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = true
	state.save_path = test_save
	state.player = state.default_player()
	state.player.credits = 777
	check(not state.save_game(), "save reports failure when its local parent is unavailable")
	check(not state.save_warning.is_empty(), "failed write creates a dedicated persistent warning")
	check(not FileAccess.file_exists(test_save), "failed write cannot pretend a save exists")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var warning := scene.find_child("SaveWarningBanner", true, false) as PanelContainer
	var retry := scene.find_child("RetrySaveAction", true, false) as Button
	check(warning != null and retry != null, "save failure is visible with an explicit retry action")
	state.phase = state.Phase.VICTORY
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = {"id": "unsaved_loot", "name": "Peça em Memória", "slot": "weapon", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	scene.render()
	await process_frame
	var open_reward := scene.find_child("OpenRewardAction", true, false) as Button
	check(open_reward != null and open_reward.global_position.y + open_reward.size.y <= scene.size.y + 0.5, "save warning keeps the victory advance action visible")
	retry = scene.find_child("RetrySaveAction", true, false) as Button

	var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_dir))
	check(make_error == OK, "test storage becomes available")
	retry.pressed.emit()
	await process_frame
	check(state.save_warning.is_empty() and scene.find_child("SaveWarningBanner", true, false) == null, "confirmed retry clears the warning")
	check(FileAccess.file_exists(test_save), "successful retry creates the save")
	var file := FileAccess.open(test_save, FileAccess.READ)
	var payload = JSON.parse_string(file.get_as_text())
	check(payload is Dictionary and int(payload.player.credits) == 777, "successful retry persists the exact in-memory progress")

	scene.free()
	await process_frame
	state.persistence_enabled = false
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_dir))
	await create_timer(0.5).timeout
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: save-write failures stay visible until a confirmed retry")
		quit(0)
	else:
		printerr("FAIL: %d save failure issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
