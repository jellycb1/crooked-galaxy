extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_mobile_audit")


func run_mobile_audit() -> void:
	var state = root.get_node_or_null("GameState")
	if state == null:
		check(false, "autoload is available for mobile audit")
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.player.weapon.origin_planet_id = "dustball_prime"
	state.player.armor.origin_planet_id = "dustball_prime"
	state.player.inventory = [
		{"id": "mobile_weapon", "name": "Arma de Bolso", "slot": "weapon", "power": 4, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "mobile_armor", "name": "Colete de Bolso", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9"},
	]
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check_touch_targets(scene, "bounty board")

	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	check_touch_targets(scene, "arsenal")
	var inventory_scroll := scene.find_child("InventoryScroll", true, false) as ScrollContainer
	check(inventory_scroll != null and inventory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "arsenal disables horizontal scrolling")
	check(inventory_scroll != null and inventory_scroll.size.y >= 120.0, "arsenal reserves useful vertical space for the inventory on mobile")

	scene.view_mode = "career"
	scene.render()
	await process_frame
	check_touch_targets(scene, "career navigation")

	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	check_touch_targets(scene, "contract briefing")
	state.choose_approach("quiet_net")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check_touch_targets(scene, "hunt incident")

	state.player = state.default_player()
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = {"id": "mobile_first_reward", "name": "Zapper de Bolso", "slot": "weapon", "power": 3, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"}
	scene.render()
	await process_frame
	check_reward_action_in_viewport(scene, "ClaimAndRepeat", "first reward repeat")
	check_reward_action_in_viewport(scene, "ClaimAndBoard", "first reward board route")

	state.player.captures_by_target = {"gloop": 2}
	state.player.captures_by_planet = {"dustball_prime": 2}
	state.pending_loot = {"id": "mobile_threshold_reward", "name": "Colete de Limiar", "slot": "armor", "power": 5, "rarity": "Raro", "color": "#58d9ff", "origin_planet_id": "dustball_prime"}
	scene.render()
	await process_frame
	check_reward_action_in_viewport(scene, "ClaimAndWorkshop", "combined reward workshop route")
	check_reward_action_in_viewport(scene, "ClaimAndUnlock", "combined reward warrant route")

	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func check_touch_targets(node: Node, context: String) -> void:
	var viewport_width := float((node as Control).size.x)
	for candidate in node.find_children("*", "Button", true, false):
		var button := candidate as Button
		if not button.visible or button.disabled:
			continue
		check(button.size.y >= 40.0, "%s button keeps a 40-unit touch target: %s" % [context, button.name])
		check(button.global_position.x >= -0.5 and button.global_position.x + button.size.x <= viewport_width + 0.5, "%s button stays inside the horizontal viewport: %s" % [context, button.name])


func check_reward_action_in_viewport(scene: Control, node_name: String, context: String) -> void:
	var button := scene.find_child(node_name, true, false) as Button
	check(button != null, "%s exists" % context)
	if button == null:
		return
	check(button.size.y >= 40.0, "%s keeps a 40-unit touch target" % context)
	check(button.global_position.y >= -0.5 and button.global_position.y + button.size.y <= scene.size.y + 0.5, "%s stays inside the vertical viewport" % context)


func finish() -> void:
	if failures == 0:
		print("PASS: mobile safe areas, touch targets, and scrolling are valid")
		quit(0)
	else:
		printerr("FAIL: %d mobile UI issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
