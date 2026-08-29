extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const Content = preload("res://scripts/content_db.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var mature_level := int(Content.PLANETS[-1].get("unlock_level", 1))
	var state = root.get_node("GameState")
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.class_id = "orbit_gunslinger"
	state.player.species_id = "terran"
	state.player.hunter_name = "Benchmark"
	state.phase = state.Phase.BOARD
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for mode in ["board", "arsenal_cold", "arsenal_warm", "arsenal_collection_cold", "arsenal_collection_warm", "market_cold", "market_warm", "market_confirmation", "hangar", "career", "career_archive", "daily", "galaxy", "galaxy_mature", "attributes", "challenges", "board_network_cold", "board_network_warm"]:
		if not mode.ends_with("_warm"):
			Rules.clear_bounty_odds_cache()
		if mode.begins_with("board_network"):
			state.player.wins = 7
			state.player.level = 4
		if mode == "board_network_warm":
			scene.selected_board_offer_index = 1
		if mode == "galaxy_mature":
			state.player.level = mature_level
		var base_mode: String = "galaxy" if mode == "galaxy_mature" else str(mode).trim_suffix("_cold").trim_suffix("_warm").trim_suffix("_collection").trim_suffix("_confirmation")
		scene.view_mode = "board" if base_mode == "board_network" else ("career" if base_mode == "career_archive" else base_mode)
		if mode == "career" or mode == "career_archive":
			scene.career_section = "archive" if mode == "career_archive" else "progress"
		if mode.begins_with("arsenal_collection"):
			scene.arsenal_section = "collection"
		if mode == "market_confirmation":
			state.player.warp_chips = 99
			scene.market_refresh_confirmation = true
		var started := Time.get_ticks_usec()
		scene.render()
		var elapsed := Time.get_ticks_usec() - started
		print("UI_RENDER_BENCHMARK mode=%s sync=%d us nodes=%d" % [mode, elapsed, scene.content.find_children("*", "", true, false).size()])
		await process_frame
		if mode == "galaxy_mature":
			state.player.level = 4
	var allocating_started := Time.get_ticks_usec()
	var lookup_checksum := 0
	for _cycle in 1000:
		for planet in Content.PLANETS:
			lookup_checksum += 1 if MissionRules.available_planets(mature_level).any(func(candidate): return str(candidate.id) == str(planet.id)) else 0
	var allocating_elapsed := Time.get_ticks_usec() - allocating_started
	var direct_started := Time.get_ticks_usec()
	for _cycle in 1000:
		for planet in Content.PLANETS:
			lookup_checksum += 1 if MissionRules.is_planet_available(str(planet.id), mature_level) else 0
	var direct_elapsed := Time.get_ticks_usec() - direct_started
	print("GALAXY_UNLOCK_LOOKUP_BENCHMARK allocating=%d us direct=%d us checksum=%d" % [allocating_elapsed, direct_elapsed, lookup_checksum])
	var linear_target_started := Time.get_ticks_usec()
	var target_checksum := 0
	for _cycle in 1000:
		for requested_target in Content.TARGETS:
			for candidate in Content.TARGETS:
				if str(candidate.id) == str(requested_target.id):
					target_checksum += int(candidate.chapter_tier)
					break
	var linear_target_elapsed := Time.get_ticks_usec() - linear_target_started
	var indexed_target_started := Time.get_ticks_usec()
	for _cycle in 1000:
		for requested_target in Content.TARGETS:
			target_checksum += int(Content.get_target(str(requested_target.id)).chapter_tier)
	var indexed_target_elapsed := Time.get_ticks_usec() - indexed_target_started
	print("TARGET_ID_LOOKUP_BENCHMARK linear=%d us indexed=%d us checksum=%d" % [linear_target_elapsed, indexed_target_elapsed, target_checksum])
	scene.free()
	quit(0)
