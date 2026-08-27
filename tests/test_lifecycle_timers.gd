extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_lifecycle_audit")


func run_lifecycle_audit() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for lifecycle audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.select_bounty(ContentDB.TARGETS[19])
	state.choose_approach("premium_warrant")
	state.begin_combat()
	state.player_hp = 9999
	state.enemy_hp = 9999
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(not scene.combat_timer.is_stopped(), "focused combat starts its automatic timer")
	check(scene.hunt_timer.is_stopped(), "hunt refresh is inactive during combat")
	check(scene.hunt_timer.wait_time >= 0.2 and scene.hunt_timer.wait_time <= 0.5, "multi-minute hunt refresh uses a mobile-conscious cadence")

	var round_before := int(state.combat_round)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.combat_timer.is_stopped(), "focus loss pauses automatic combat")
	await create_timer(0.85).timeout
	check(int(state.combat_round) == round_before, "unfocused combat cannot execute an unseen turn")

	scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(scene.combat_timer.is_stopped(), "focus return alone cannot override an active application suspension")
	scene._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not scene.combat_timer.is_stopped(), "combat resumes only after every suspension reason clears")
	# Resume may legitimately schedule one recovery-banner render. Let that frame
	# settle before measuring only the automatic combat tick itself.
	await process_frame
	var render_generation_before_turn := int(scene.render_generation)
	var arena_before_turn := scene.find_child("CombatArenaStage", true, false)
	await create_timer(0.8).timeout
	check(int(state.combat_round) > round_before, "resumed combat continues from the preserved round")
	check(int(scene.render_generation) == render_generation_before_turn and scene.find_child("CombatArenaStage", true, false) == arena_before_turn, "automatic combat updates in place without rebuilding its arena")
	check(not state.current_bounty.is_empty(), "lifecycle fixture retains its active contract before victory")

	state.enemy_hp = 0
	state.finish_combat(true)
	await process_frame
	await create_timer(0.35).timeout
	var victory_remaining: float = scene.victory_timer.time_left
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.victory_timer.is_stopped(), "repeated focus-loss notifications leave victory paused")
	await create_timer(0.7).timeout
	check(state.phase == state.Phase.VICTORY, "paused victory evidence cannot expire in the background")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not scene.victory_timer.is_stopped() and scene.victory_timer.time_left <= victory_remaining + 0.05, "victory resumes from its preserved remaining pause")

	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	state.phase = state.Phase.HUNT
	state.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[0])
	state.hunt_started_at = Time.get_unix_time_from_system() - 5.0
	state.hunt_ends_at = Time.get_unix_time_from_system() - 1.0
	scene.render()
	check(scene.hunt_timer.is_stopped(), "background suspension prevents hunt refresh from waking")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	check(state.phase == state.Phase.COMBAT, "resumed idle hunt reconciles elapsed wall-clock time")
	check(not scene.combat_timer.is_stopped(), "combat produced by hunt reconciliation starts only after resume")

	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: focus and application lifecycle preserve timed gameplay")
		quit(0)
	else:
		printerr("FAIL: %d lifecycle timer issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
