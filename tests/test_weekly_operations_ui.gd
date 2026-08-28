extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var state = root.get_node("GameState")
	state.persistence_enabled = false
	state.account = {"provider_id": "local_device", "account_id": "weekly_ui", "session_state": "local_ready", "active_character_id": "weekly_hunter", "owned_character_ids": ["weekly_hunter"], "authority": "device", "sync_state": "local_only", "server_id": "international_1", "locale_id": "pt"}
	state.player = state.default_player()
	state.player.character_id = "weekly_hunter"
	state.player.class_id = "orbit_gunslinger"
	state.player.species_id = "terran"
	state.player.appearance = {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	state.player.hunter_name = "Nova"
	state.phase = state.Phase.BOARD
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.view_mode = "daily"
	scene.operations_section = "weekly"
	scene.render()
	await process_frame
	check(scene.find_child("OperationsDailyTab", true, false) is Button and scene.find_child("OperationsWeeklyTab", true, false) is Button, "Operations exposes explicit daily and weekly tabs")
	check(scene.find_child("WeeklySpecialCard", true, false) != null and scene.find_child("WeeklySpecialAction", true, false) is Button, "weekly surface exposes one intentional Black Warrant action")
	check(scene.find_child("WeeklyObjective_weekly_patrol", true, false) != null and scene.find_child("WeeklyObjective_weekly_veteran", true, false) != null, "weekly board renders the complete bounded objective ladder")
	var scroll := scene.find_child("DailyObjectivesScroll", true, false) as ScrollContainer
	check(scroll != null and scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "weekly board remains finger-scrollable at Android height")
	var action := scene.find_child("WeeklySpecialAction", true, false) as Button
	check(action != null and action.custom_minimum_size.y >= 56, "Black Warrant keeps the established Android touch target")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: weekly Operations UI is complete and mobile-scrollable")
		quit(0)
	else:
		printerr("FAIL: %d weekly Operations UI test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
