extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_motion_preference_%s.json" % OS.get_process_id()


func _init() -> void:
	call_deferred("run_motion_audit")


func run_motion_audit() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for motion audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.reduced_motion = true
	prepare_reward(state)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var reduced_panel := scene.find_child("RewardPanel", true, false) as PanelContainer
	check(reduced_panel != null and is_equal_approx(reduced_panel.modulate.a, 1.0), "reduced motion presents loot immediately without a fade")

	state.player.reduced_motion = false
	scene.render()
	var animated_panel := scene.find_child("RewardPanel", true, false) as PanelContainer
	check(animated_panel != null and is_zero_approx(animated_panel.modulate.a), "full motion retains the short loot reveal")

	state.player.reduced_motion = true
	state.phase = state.Phase.VICTORY
	scene.render()
	await process_frame
	check(scene.victory_timer.wait_time >= 2.5 and scene.find_child("OpenRewardAction", true, false) != null, "reduced motion preserves the readable victory pause and immediate advance action")

	state.phase = state.Phase.BOARD
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	var motion_action := scene.find_child("MotionPreferenceAction", true, false) as Button
	check(motion_action != null and motion_action.text.contains("REDUZIDO"), "arsenal exposes the active motion preference")
	motion_action.pressed.emit()
	await process_frame
	var updated_action := scene.find_child("MotionPreferenceAction", true, false) as Button
	check(not bool(state.player.reduced_motion) and updated_action != null and updated_action.text.contains("COMPLETO"), "motion preference toggles and rerenders its exact state")

	var source = StateScript.new()
	source.save_path = test_save
	source.player = source.default_player()
	source.toggle_reduced_motion()
	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	check(bool(restored.player.reduced_motion) and restored.last_notice_context != "system_recovery", "motion preference persists in the current save schema")
	restored.free()
	source.free()

	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func prepare_reward(state) -> void:
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = {"id": "motion_loot", "name": "Peça sem Vertigem", "slot": "weapon", "power": 3, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"}


func finish() -> void:
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("PASS: reduced motion removes decoration without shortening readable pauses")
		quit(0)
	else:
		printerr("FAIL: %d motion preference issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
