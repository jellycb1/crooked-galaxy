extends SceneTree

const ArsenalView = preload("res://scripts/arsenal_view.gd")
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
	state.player.scrap = 20
	state.phase = state.Phase.BOARD
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	# Fifteen idle frames cover the maximum nine one-estimate timer slices plus the
	# single background request without relying on desktop frame timing.
	for _frame in 15:
		await process_frame
	# A real player cannot navigate before this idle interval; it allows the
	# staggered worker requests to begin without hiding their main-thread cost.
	await create_timer(0.2).timeout
	var prefetched_estimates := Rules.bounty_odds_cache.size()
	scene.view_mode = "arsenal"
	var first_visit_started := Time.get_ticks_usec()
	scene.render()
	print("FIRST_VISIT_BENCHMARK component=arsenal_real_first_visit prefetched=%d sync=%d us nodes=%d" % [prefetched_estimates, Time.get_ticks_usec() - first_visit_started, scene.content.find_children("*", "", true, false).size()])
	await process_frame
	scene.view_mode = "board"
	scene.render()

	for context in ["workshop", "world", "combat"]:
		var started := Time.get_ticks_usec()
		scene.environment_backdrop.show_context(context, str(state.player.current_planet_id))
		print("FIRST_VISIT_BENCHMARK component=background_%s transition=%d us" % [context, Time.get_ticks_usec() - started])

	Rules.clear_bounty_odds_cache()
	var readiness_started := Time.get_ticks_usec()
	var readiness := ArsenalView.field_readiness(state)
	print("FIRST_VISIT_BENCHMARK component=arsenal_readiness cold=%d us cache_entries=%d" % [Time.get_ticks_usec() - readiness_started, Rules.bounty_odds_cache.size()])
	var recommendation_started := Time.get_ticks_usec()
	ArsenalView.recommended_workshop_action(state, readiness)
	print("FIRST_VISIT_BENCHMARK component=arsenal_recommendation cold=%d us cache_entries=%d" % [Time.get_ticks_usec() - recommendation_started, Rules.bounty_odds_cache.size()])
	var readiness_warm_started := Time.get_ticks_usec()
	readiness = ArsenalView.field_readiness(state)
	ArsenalView.recommended_workshop_action(state, readiness)
	print("FIRST_VISIT_BENCHMARK component=arsenal_analysis warm=%d us cache_entries=%d" % [Time.get_ticks_usec() - readiness_warm_started, Rules.bounty_odds_cache.size()])

	# All context textures are resident here, so this isolates synchronous UI tree
	# construction from first-use resource decoding. Odds are cold on purpose.
	Rules.clear_bounty_odds_cache()
	scene.view_mode = "arsenal"
	var render_started := Time.get_ticks_usec()
	scene.render()
	print("FIRST_VISIT_BENCHMARK component=arsenal_tree_plus_odds cold=%d us nodes=%d" % [Time.get_ticks_usec() - render_started, scene.content.find_children("*", "", true, false).size()])
	await process_frame

	scene.free()
	quit(0)
