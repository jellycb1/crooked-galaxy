extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for universal equipment tests")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	check(Rules.EQUIPMENT_SLOTS.size() == 9 and Rules.equipped_item_count(state.player) == 2, "new hunters expose nine universal slots while retaining only their two starter pieces")
	check(Rules.EQUIPMENT_SLOTS.all(func(slot): return state.player.has(slot)), "the player schema owns every universal slot independently of class")
	check(state.player.helmet.is_empty() and state.player.relic.is_empty(), "reserved slots begin empty instead of granting artificial power")

	var baseline_power := Rules.player_power(state.player)
	var helmet := {"id": "test_helmet", "name": "Capacete de Auditoria", "slot": "helmet", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	state.equip(helmet)
	check(str(state.player.helmet.id) == "test_helmet" and Rules.player_power(state.player) == baseline_power + 2, "a non-core slot equips through the same transaction and contributes to the universal build")
	check(state.save_equipment_loadout(0) and str(state.player.equipment_loadouts[0].helmet_id) == "test_helmet", "loadouts snapshot non-core equipment with the same contract")
	check(state.is_item_protected("test_helmet"), "equipment saved in any universal slot is protected from recycling")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	check(scene.find_children("HunterEquipment_*", "PanelContainer", true, false).size() == 9, "hunter paper doll renders all nine universal spaces")
	scene.view_mode = "arsenal"
	scene.arsenal_section = "equipped"
	scene.render()
	await process_frame
	check(scene.find_children("UniversalSlot_*", "PanelContainer", true, false).size() == 9, "arsenal overview renders the same nine-slot contract")
	check(scene.find_child("UniversalSlot_relic", true, false) != null and scene.find_child("UniversalSlot_weapon", true, false) != null, "filled and future equipment positions remain stable across classes")
	scene.free()
	await process_frame
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: universal equipment slots share one save, loadout, combat, and UI contract")
		quit(0)
	else:
		printerr("FAIL: %d universal equipment test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
