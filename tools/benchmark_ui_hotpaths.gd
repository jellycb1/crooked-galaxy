extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
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
	for mode in ["board", "arsenal", "market", "hangar", "career", "career_archive", "galaxy", "attributes", "challenges", "board", "arsenal"]:
		Rules.clear_bounty_odds_cache()
		scene.view_mode = "career" if mode == "career_archive" else mode
		if mode == "career" or mode == "career_archive":
			scene.career_section = "archive" if mode == "career_archive" else "progress"
		var started := Time.get_ticks_usec()
		scene.render()
		var elapsed := Time.get_ticks_usec() - started
		print("UI_RENDER_BENCHMARK mode=%s sync=%d us nodes=%d" % [mode, elapsed, scene.content.find_children("*", "", true, false).size()])
		await process_frame
	scene.free()
	quit(0)
