extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_smoke_test")


func run_smoke_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	state.pending_loot = {}

	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.content.get_child_count() >= 4, "bounty board renders")

	var bounty: Dictionary = ContentDB.TARGETS[0].duplicate(true)
	state.select_bounty(bounty)
	await process_frame
	check(scene.find_child("BriefingScroll", true, false) != null, "contract briefing renders")
	state.choose_approach("quiet_net")
	await process_frame
	check(scene.find_child("HuntProgress", true, false) != null, "hunt screen renders")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(scene.find_child("HuntEventChoices", true, false) != null, "mid-hunt incident renders")
	state.resolve_hunt_event("detour")
	await process_frame

	state.begin_combat()
	await process_frame
	check(state.player_hp > 0 and state.enemy_hp > 0, "combat screen initializes")
	state.combat_step()
	scene.render()
	await process_frame
	check(state.combat_events.size() == 2, "combat action cards render")

	state.finish_combat(true)
	await process_frame
	check(state.phase == state.Phase.VICTORY, "victory screen renders before loot")
	check(not state.pending_loot.is_empty(), "reward screen receives an item")

	state.open_reward()
	await process_frame
	state.claim_reward(true)
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	check(scene.find_child("InventoryScroll", true, false) != null, "arsenal screen renders")
	check(state.player.inventory.size() == 1, "arsenal receives claimed loot")

	state.phase = state.Phase.CHAPTER_COMPLETE
	state.chapter_completion = {
		"planet": ContentDB.PLANET.duplicate(true),
		"target": ContentDB.TARGETS[3].duplicate(true),
		"total_captures": 10,
		"credits": ContentDB.TARGETS[3].credits,
	}
	scene.render()
	await process_frame
	check(scene.find_child("ChapterComplete", true, false) != null, "planet completion screen renders")

	state.phase = state.Phase.BOARD
	state.player.completed_planets = [ContentDB.PLANET.id]
	state.player.current_planet_id = ContentDB.PLANET.id
	state.player.reputation = 3
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(scene.find_child("GalaxyRoutes", true, false) != null, "galaxy map renders unlocked routes")
	scene.view_mode = "board"
	check(state.travel_to_planet("congelaria_sa"), "UI state can travel to an unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_auditor_frost", true, false) != null, "second planet bounty board renders")

	scene.free()
	await process_frame
	# Let the dummy audio driver release active playback handles before shutdown.
	await create_timer(0.5).timeout
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: all primary UI phases render")
		quit(0)
	else:
		printerr("FAIL: %d UI smoke test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
