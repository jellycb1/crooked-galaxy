extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_mobile_audit")


func run_mobile_audit() -> void:
	check_android_first_project_profile()
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
	state.player.owned_transport_ids = ["licensed_junkbox"]
	state.player.active_transport_id = "licensed_junkbox"
	state.player.inventory = [
		{"id": "mobile_weapon", "name": "Arma de Bolso", "slot": "weapon", "power": 4, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "mobile_armor", "name": "Colete de Bolso", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9"},
	]
	for index in 28:
		state.player.inventory.append({"id": "mobile_page_%02d" % index, "name": "Peça Móvel %02d" % index, "slot": "weapon" if index % 2 == 0 else "armor", "power": index + 2, "rarity": "Comum", "color": "#b9c2d9"})
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check_touch_targets(scene, "bounty board")
	var build_version := scene.find_child("BuildVersion", true, false) as Label
	check(build_version != null and build_version.text == "v%s" % str(ProjectSettings.get_setting("application/config/version")), "installed build version remains visible in the compact header")
	check(scene.hunt_timer.is_stopped(), "high-frequency hunt refresh stays asleep on the bounty board")
	check(scene.android_back_action() == "quit", "Android Back exits only from the root bounty board")

	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	check_touch_targets(scene, "arsenal")
	check(scene.android_back_action() == "board", "Android Back routes secondary hubs to the bounty board")
	scene.handle_android_back_request()
	await process_frame
	check(scene.view_mode == "board" and state.phase == state.Phase.BOARD, "Android Back performs safe hub navigation without exiting")
	state.player.credits = 99999
	scene.view_mode = "market"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "planet market")
	check(scene.find_child("MarketScroll", true, false) != null and scene.find_children("MarketOffer_*", "PanelContainer", true, false).size() == 3, "all three market offers remain reachable in the portrait scroller")
	check(scene.android_back_action() == "board", "Android Back routes the market safely to the bounty board")
	scene.view_mode = "hangar"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "transport hangar")
	check(scene.find_child("HangarScroll", true, false) != null and scene.find_children("HangarTransport_*", "PanelContainer", true, false).size() == 4, "all four transports remain reachable in the portrait scroller")
	check(scene.find_children("HangarTransportIcon_*", "Control", true, false).size() == 4, "hangar silhouettes remain visible at the mobile card size")
	check(scene.android_back_action() == "board", "Android Back routes the hangar safely to the bounty board")
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check_touch_targets(scene, "transport galaxy status")
	check(scene.find_child("GalaxyTransportIcon", true, false) != null and scene.find_child("GalaxyHangarAction", true, false) != null, "galaxy map carries the active transport identity and hangar route")
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	await process_frame
	var inventory_scroll := scene.find_child("InventoryScroll", true, false) as ScrollContainer
	check(inventory_scroll != null and inventory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "arsenal disables horizontal scrolling")
	check(inventory_scroll != null and inventory_scroll.size.y >= 48.0, "arsenal reserves a complete touch row for the inventory on mobile (actual %.1f)" % (inventory_scroll.size.y if inventory_scroll != null else -1.0))
	check(scene.find_children("InventoryItem_*", "PanelContainer", true, false).size() == 12, "mobile arsenal instantiates only one bounded inventory page")
	var next_inventory_page := scene.find_child("InventoryPageNext", true, false) as Button
	check(next_inventory_page != null and next_inventory_page.custom_minimum_size.y >= 48.0, "inventory pager preserves a complete mobile touch target")
	if next_inventory_page != null:
		next_inventory_page.pressed.emit()
		await process_frame
	check(scene.inventory_page == 1 and (scene.find_child("InventoryPageStatus", true, false) as Label).text == "2 / 3", "mobile inventory navigation advances one page without touching the save")

	scene.view_mode = "career"
	scene.render()
	await process_frame
	check_touch_targets(scene, "career navigation")

	state.player.stat_points = 2
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "attributes")
	check(scene.find_child("AttributeScroll", true, false) != null and scene.find_children("AttributeAdd_*", "Button", true, false).size() == 5, "all five attributes remain reachable in the portrait scroller")

	scene.view_mode = "classes"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "class selection")
	check(scene.find_child("ClassScroll", true, false) != null and scene.find_children("ClassSelect_*", "Button", true, false).size() == 3, "all initial classes remain reachable in the portrait scroller")

	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	check_touch_targets(scene, "contract briefing")
	check(scene.find_child("BriefingTransportIcon", true, false) != null, "contract briefing carries the active transport silhouette")
	check(scene.android_back_action() == "cancel_briefing", "Android Back maps an uncommitted briefing to its safe cancel action")
	scene.handle_android_back_request()
	await process_frame
	check(state.phase == state.Phase.BOARD, "Android Back cancels a briefing before any route is committed")
	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	state.choose_approach("quiet_net")
	await process_frame
	check(scene.find_child("HuntTransportIcon", true, false) != null, "active hunt carries the transport silhouette and timing identity")
	check(not scene.hunt_timer.is_stopped(), "hunt refresh wakes only for the timed hunt phase")
	check(scene.android_back_action() == "guard_contract", "Android Back cannot accidentally abandon an active timed contract")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(scene.hunt_timer.is_stopped(), "hunt refresh sleeps again while an incident awaits input")
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


func check_android_first_project_profile() -> void:
	check(str(ProjectSettings.get_setting("application/boot_splash/image", "")) == "res://assets/boot_splash.png", "startup uses the original Crooked Galaxy boot splash")
	var splash := load("res://assets/boot_splash.png") as Texture2D
	check(splash != null and splash.get_width() == 720 and splash.get_height() == 1280, "boot splash matches the portrait design canvas")
	check(not bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)), "Godot delegates Android Back to the safe in-game router")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 720, "project keeps the 720-unit portrait design width")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 1280, "project keeps the 1280-unit portrait design height")
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)) == 1, "handheld orientation remains portrait")
	check(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items", "mobile layout uses canvas-items stretching")
	check(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand", "modern tall screens expand beyond the 9:16 minimum instead of letterboxing")
	check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) == "gl_compatibility", "mobile renderer stays on the broad-compatibility path")
	check(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "mobile texture compression remains enabled")


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
