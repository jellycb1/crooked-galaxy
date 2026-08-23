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
	state.start_bounty(bounty)
	await process_frame
	check(scene.find_child("HuntProgress", true, false) != null, "hunt screen renders")

	state.begin_combat()
	await process_frame
	check(state.player_hp > 0 and state.enemy_hp > 0, "combat screen initializes")

	state.finish_combat(true)
	await process_frame
	check(not state.pending_loot.is_empty(), "reward screen receives an item")

	state.claim_reward(true)
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	check(scene.find_child("InventoryScroll", true, false) != null, "arsenal screen renders")
	check(state.player.inventory.size() == 1, "arsenal receives claimed loot")

	scene.queue_free()
	await process_frame
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
