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
	state.select_bounty(bounty)
	await process_frame
	await process_frame
	if save_frame("ui_briefing.png") != OK:
		quit(1)
		return
	state.choose_approach("quiet_net")
	await process_frame
	await process_frame
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_hunt_event.png") != OK:
		quit(1)
		return
	state.resolve_hunt_event("detour")
	await process_frame
	await process_frame
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
	state.player.wins = 10
	state.player.reputation = 3
	state.player.level = 4
	state.player.base_power = 16
	state.player.weapon = {"name": "Canhão de Recibos", "slot": "weapon", "power": 15, "rarity": "Raro", "color": "#58d9ff"}
	state.player.armor = {"name": "Poncho de Titânio", "slot": "armor", "power": 11, "rarity": "Raro", "color": "#58d9ff"}
	state.player.completed_planets = [ContentDB.PLANET.id]
	state.player.captures_by_target = {"gloop": 4, "baron_boom": 3, "madame_vacuum": 2, "mayor_gold_dust": 1}
	state.chapter_completion = {
		"planet": ContentDB.PLANET.duplicate(true),
		"target": ContentDB.TARGETS[3].duplicate(true),
		"total_captures": 10,
		"credits": ContentDB.TARGETS[3].credits,
		"xp": ContentDB.TARGETS[3].xp,
	}
	state.phase = state.Phase.CHAPTER_COMPLETE
	scene.view_mode = "board"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_chapter_complete.png") != OK:
		quit(1)
		return
	state.continue_after_chapter()
	await process_frame
	await process_frame
	var bounty_scroll := scene.content.find_child("BountyScroll", true, false) as ScrollContainer
	if bounty_scroll:
		await create_timer(0.1).timeout
		var scroll_bar := bounty_scroll.get_v_scroll_bar()
		bounty_scroll.scroll_vertical = maxi(0, roundi(scroll_bar.max_value - scroll_bar.page))
		await process_frame
		await process_frame
	else:
		printerr("Failed to locate BountyScroll for boss capture")
		quit(1)
		return
	if save_frame("ui_boss_board.png") != OK:
		quit(1)
		return
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_galaxy_map.png") != OK:
		quit(1)
		return
	scene.view_mode = "board"
	state.travel_to_planet("congelaria_sa")
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_congelaria_board.png") != OK:
		quit(1)
		return
	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	print("Captured primary UI, galaxy map, boss board, chapter completion, and Congelária board to %s" % OUTPUT_DIR)
	quit(0)


func save_frame(filename: String) -> Error:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("Failed to capture %s: %s" % [path, error_string(error)])
	return error
