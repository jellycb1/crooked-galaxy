extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_text_audit")


func run_text_audit() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for text audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.completed_planets = ContentDB.PLANETS.map(func(planet): return str(planet.id))
	state.player.current_planet_id = "cassino_quasar"
	state.player.inventory = [
		{"id": "long_weapon", "name": "Desatomizador Interplanetário de Garantias Vencidas", "slot": "weapon", "power": 44, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "cassino_quasar", "trait": ContentDB.ITEM_TRAITS.weapon[1].duplicate(true)},
		{"id": "long_armor", "name": "Colete Executivo de Responsabilidade Criativamente Limitada", "slot": "armor", "power": 42, "rarity": "Raro", "color": "#58d9ff", "origin_planet_id": "cassino_quasar", "trait": ContentDB.ITEM_TRAITS.armor[1].duplicate(true)},
	]
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	# Exercise a conservative curved-screen gutter in addition to the regular
	# 450x800 capture. Some Android vendors report no lateral cutout even though
	# rounded glass still needs more breathing room than the desktop viewport.
	scene.safe_container.add_theme_constant_override("margin_left", 54)
	scene.safe_container.add_theme_constant_override("margin_right", 54)
	await process_frame
	await audit_scaled_screen(scene, "bounty board hub")

	state.phase = state.Phase.BRIEFING
	state.current_bounty = ContentDB.TARGETS[19].duplicate(true)
	state.offered_approaches.assign(ContentDB.contract_approaches())
	scene.render()
	await audit_scaled_screen(scene, "final briefing")

	state.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[19], ContentDB.CONTRACT_APPROACHES[2])
	state.hunt_event = ContentDB.HUNT_EVENTS[-1].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 7.0
	state.hunt_remaining_after_event = 9.0
	state.player.credits = 0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await audit_scaled_screen(scene, "casino incident")

	state.player = state.default_player()
	state.player.captures_by_target = {"dealer_comet": 2}
	state.player.captures_by_planet = {"cassino_quasar": 2}
	state.player.completed_planets = ContentDB.PLANETS.map(func(planet): return str(planet.id))
	state.player.current_planet_id = "cassino_quasar"
	state.current_bounty = ContentDB.TARGETS[16].duplicate(true)
	state.pending_loot = {"id": "verbose_reward", "name": "Calculadora Balística de Probabilidades Contratuais", "description": "Converte cláusulas extensas em projéteis com parecer jurídico anexado.", "slot": "weapon", "power": 46, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "cassino_quasar", "trait": ContentDB.ITEM_TRAITS.weapon[1].duplicate(true)}
	state.phase = state.Phase.REWARD
	scene.render()
	await audit_scaled_screen(scene, "threshold reward")

	state.player.wins = 30
	state.player.completed_planets = ContentDB.PLANETS.map(func(planet): return str(planet.id))
	state.player.captures_by_target = {"dealer_comet": 5}
	state.phase = state.Phase.BOARD
	scene.view_mode = "career"
	scene.render()
	await audit_scaled_screen(scene, "complete career")

	state.player.challenge_floor = 2
	scene.view_mode = "challenges"
	scene.render()
	await audit_scaled_screen(scene, "Fenda anomaly dossier")

	state.player.inventory = [
		{"id": "long_weapon", "name": "Desatomizador Interplanetário de Garantias Vencidas", "slot": "weapon", "power": 44, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "cassino_quasar", "trait": ContentDB.ITEM_TRAITS.weapon[1].duplicate(true)},
		{"id": "long_armor", "name": "Colete Executivo de Responsabilidade Criativamente Limitada", "slot": "armor", "power": 42, "rarity": "Raro", "color": "#58d9ff", "origin_planet_id": "cassino_quasar", "trait": ContentDB.ITEM_TRAITS.armor[1].duplicate(true)},
	]
	scene.view_mode = "arsenal"
	scene.render()
	await audit_scaled_screen(scene, "verbose arsenal")

	state.player.credits = 99999
	scene.view_mode = "market"
	scene.render()
	await audit_scaled_screen(scene, "planet market")

	state.player.stat_points = 8
	scene.view_mode = "attributes"
	scene.render()
	await audit_scaled_screen(scene, "attribute allocation")

	scene.view_mode = "classes"
	scene.render()
	await audit_scaled_screen(scene, "class selection")

	state.persistence_enabled = true
	state.account = {"mode": "local_test", "session_id": "text_fixture", "locale_id": "pt", "server_id": "international_1"}
	state.player = state.default_player()
	state.player.class_id = "contract_hacker"
	scene.render()
	await audit_scaled_screen(scene, "mandatory species onboarding")
	state.persistence_enabled = false

	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func audit_scaled_screen(scene: Control, context: String) -> void:
	await process_frame
	await process_frame
	audit_label_geometry(scene, context)
	for candidate in scene.content.find_children("*", "Control", true, false):
		var control := candidate as Control
		if (control is Label or control is Button) and control.has_theme_font_size_override("font_size"):
			control.add_theme_font_size_override("font_size", ceili(float(control.get_theme_font_size("font_size")) * 1.25))
	await process_frame
	await process_frame
	audit_label_geometry(scene, "%s · 125%% text" % context)
	var viewport_size := scene.size
	for candidate in scene.content.find_children("*", "Button", true, false):
		var button := candidate as Button
		if not button.visible or button.disabled:
			continue
		check(button.global_position.x >= -0.5 and button.global_position.x + button.size.x <= viewport_size.x + 0.5, "%s expanded action stays horizontally visible: %s (x %.1f + w %.1f / %.1f)" % [context, button.name, button.global_position.x, button.size.x, viewport_size.x])
		check(button.size.y >= 40.0, "%s expanded action keeps its touch target: %s" % [context, button.name])
		if not has_scroll_ancestor(button):
			check(button.global_position.y >= -0.5 and button.global_position.y + button.size.y <= viewport_size.y + 0.5, "%s fixed action stays vertically visible: %s '%s' (y %.1f + h %.1f / %.1f)" % [context, button.name, button.text, button.global_position.y, button.size.y, viewport_size.y])


func audit_label_geometry(scene: Control, context: String) -> void:
	var safe_rect: Rect2 = scene.safe_container.get_global_rect()
	for candidate in scene.find_children("*", "Label", true, false):
		var text_label := candidate as Label
		if not text_label.is_visible_in_tree() or text_label.text.strip_edges().is_empty():
			continue
		var rect := text_label.get_global_rect()
		check(rect.position.x >= safe_rect.position.x - 0.5 and rect.end.x <= safe_rect.end.x + 0.5, "%s label control stays inside horizontal safe area: %s '%s' (x %.1f..%.1f / %.1f..%.1f)" % [context, text_label.name, text_label.text, rect.position.x, rect.end.x, safe_rect.position.x, safe_rect.end.x])
		if text_label.autowrap_mode != TextServer.AUTOWRAP_OFF or text_label.clip_text or text_label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			continue
		var font := text_label.get_theme_font("font")
		var font_size := text_label.get_theme_font_size("font_size")
		var required_width := font.get_multiline_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		check(required_width <= text_label.size.x + 1.0, "%s unwrapped label fits its control: %s '%s' (needs %.1f / has %.1f)" % [context, text_label.name, text_label.text, required_width, text_label.size.x])


func has_scroll_ancestor(control: Control) -> bool:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			return true
		ancestor = ancestor.get_parent()
	return false


func finish() -> void:
	if failures == 0:
		print("PASS: dense layouts tolerate 125 percent text expansion")
		quit(0)
	else:
		printerr("FAIL: %d expanded-text layout issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
