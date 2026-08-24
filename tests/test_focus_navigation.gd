extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_focus_audit")


func run_focus_audit() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for focus audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await settle_focus()
	check_screen_focus(scene, "bounty board")

	for view_mode in ["galaxy", "career", "arsenal"]:
		scene.view_mode = view_mode
		scene.render()
		await settle_focus()
		check_screen_focus(scene, view_mode)

	scene.view_mode = "board"
	state.select_bounty(ContentDB.TARGETS[0])
	await settle_focus()
	check_screen_focus(scene, "contract briefing")
	state.choose_approach("quiet_net")
	await settle_focus()
	check_screen_focus(scene, "hunt")

	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 4.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await settle_focus()
	check_screen_focus(scene, "hunt incident")

	state.player.credits = 100
	state.resolve_hunt_event(str(state.hunt_event.choices[0].id))
	state.begin_combat()
	await settle_focus()
	check_screen_focus(scene, "combat")
	var combat_focus_name := str(root.get_viewport().gui_get_focus_owner().name)
	state.combat_step()
	scene.render()
	await settle_focus()
	check(str(root.get_viewport().gui_get_focus_owner().name) == combat_focus_name, "combat redraw restores the equivalent focused action")

	state.finish_combat(true)
	await settle_focus()
	check_screen_focus(scene, "victory")
	state.open_reward()
	await settle_focus()
	check_screen_focus(scene, "reward")

	state.player.completed_planets = ["dustball_prime"]
	state.chapter_completion = {"planet": ContentDB.PLANETS[0].duplicate(true), "target": ContentDB.TARGETS[3].duplicate(true), "total_captures": 10, "credits": 100, "xp": 50}
	state.phase = state.Phase.CHAPTER_COMPLETE
	scene.render()
	await settle_focus()
	check_screen_focus(scene, "chapter completion")

	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func settle_focus() -> void:
	await process_frame
	await process_frame


func check_screen_focus(scene: Control, context: String) -> void:
	var buttons: Array[Node] = scene.content.find_children("*", "Button", true, false)
	var actionable: Array[Button] = []
	for candidate in buttons:
		var button := candidate as Button
		if button.visible and not button.disabled:
			actionable.append(button)
			check(button.focus_mode == Control.FOCUS_ALL, "%s action accepts keyboard/controller focus: %s" % [context, button.name])
			var focus_style := button.get_theme_stylebox("focus") as StyleBoxFlat
			check(focus_style != null and focus_style.border_width_left >= 3, "%s action has a visible focus ring: %s" % [context, button.name])
	check(not actionable.is_empty(), "%s exposes at least one actionable control" % context)
	var focus_owner: Control = root.get_viewport().gui_get_focus_owner()
	check(focus_owner is Button and scene.content.is_ancestor_of(focus_owner) and focus_owner.visible and not focus_owner.disabled, "%s assigns focus to a visible enabled action" % context)


func finish() -> void:
	if failures == 0:
		print("PASS: every primary phase exposes stable keyboard/controller focus")
		quit(0)
	else:
		printerr("FAIL: %d focus navigation issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
