extends SceneTree

const OUTPUT_DIR := "res://builds"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var state = root.get_node_or_null("GameState")
	if state:
		state.persistence_enabled = false
		state.player = state.default_player()
		state.phase = state.Phase.BOARD
		state.current_bounty = {}
		state.pending_loot = {}
		state.last_notice = ""
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if save_frame("ui_board.png") != OK:
		quit(1)
		return

	var bounty: Dictionary = ContentDB.TARGETS[0].duplicate(true)
	state.current_bounty = bounty
	state.begin_combat()
	state.player_hp -= 21
	state.enemy_hp -= 34
	state.combat_round = 4
	state.combat_events.assign([
		{"actor": "player", "action": "Ricochete de Plasma", "damage": 14, "quality": "CRÍTICO"},
		{"actor": "enemy", "action": "Tapa Tentacular", "damage": 8, "quality": "ACERTO"},
	])
	scene.last_combat_message = "Ricochete de Plasma causa 14. Tapa Tentacular responde com 8."
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_combat.png") != OK:
		quit(1)
		return

	state.finish_combat(true)
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_victory.png") != OK:
		quit(1)
		return

	state.open_reward()
	await process_frame
	await process_frame
	await create_timer(0.42).timeout
	if save_frame("ui_reward.png") != OK:
		quit(1)
		return
	state.claim_reward(true)
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_arsenal.png") != OK:
		quit(1)
		return
	print("Captured board, combat, victory, reward, and arsenal UI to %s" % OUTPUT_DIR)
	quit(0)


func save_frame(filename: String) -> Error:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("Failed to capture %s: %s" % [path, error_string(error)])
	return error
