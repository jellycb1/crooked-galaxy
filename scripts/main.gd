extends "res://scripts/ui_factory.gd"

const SpaceBackdropScript = preload("res://scripts/space_backdrop.gd")
const ReferencePlaceholderBackdropScript = preload("res://scripts/reference_placeholder_backdrop.gd")
const CombatBackdropScript = preload("res://scripts/combat_backdrop.gd")
const SoundFXScript = preload("res://scripts/sound_fx.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const CareerRulesScript = preload("res://scripts/career_rules.gd")
const ArsenalView = preload("res://scripts/arsenal_view.gd")
const RewardViewScript = preload("res://scripts/reward_view.gd")
const CareerViewScript = preload("res://scripts/career_view.gd")

var body: VBoxContainer
var content: VBoxContainer
var combat_timer: Timer
var victory_timer: Timer
var last_combat_message := ""
var combat_fast := false
var sound_fx: Node
var previous_phase := -1
var space_backdrop: Control
var reference_backdrop: Control
var safe_container: MarginContainer
var render_generation := 0
var lifecycle_suspensions: Dictionary = {}
var timed_actions_suspended := false
var suspended_victory_time_left := 0.0


func _ready() -> void:
	build_shell()
	GameState.changed.connect(render)
	get_tree().set_auto_accept_quit(false)
	render()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_RESIZED and is_node_ready():
		call_deferred("apply_safe_area")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_lifecycle_suspension("focus", true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_lifecycle_suspension("focus", false)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		GameState.save_game()
		set_lifecycle_suspension("application", true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_lifecycle_suspension("application", false)


func set_lifecycle_suspension(reason: String, suspended: bool) -> void:
	if suspended:
		lifecycle_suspensions[reason] = true
	else:
		lifecycle_suspensions.erase(reason)
	var should_suspend := not lifecycle_suspensions.is_empty()
	if should_suspend == timed_actions_suspended:
		return
	timed_actions_suspended = should_suspend
	if timed_actions_suspended:
		if combat_timer != null:
			combat_timer.stop()
		if victory_timer != null and not victory_timer.is_stopped():
			suspended_victory_time_left = maxf(0.05, victory_timer.time_left)
			victory_timer.stop()
		return
	if GameState.phase == GameState.Phase.HUNT:
		on_hunt_timer()
	if GameState.phase == GameState.Phase.COMBAT and combat_timer != null:
		combat_timer.start()
	elif GameState.phase == GameState.Phase.VICTORY and victory_timer != null:
		victory_timer.start(suspended_victory_time_left if suspended_victory_time_left > 0.0 else victory_timer.wait_time)
		suspended_victory_time_left = 0.0


func build_shell() -> void:
	space_backdrop = SpaceBackdropScript.new()
	space_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(space_backdrop)
	reference_backdrop = ReferencePlaceholderBackdropScript.new()
	add_child(reference_backdrop)
	sound_fx = SoundFXScript.new()
	add_child(sound_fx)

	safe_container = MarginContainer.new()
	safe_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe_container)
	apply_safe_area()

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	safe_container.add_child(body)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	body.add_child(content)

	combat_timer = Timer.new()
	combat_timer.wait_time = 0.72
	combat_timer.timeout.connect(on_combat_timer)
	add_child(combat_timer)
	victory_timer = Timer.new()
	victory_timer.one_shot = true
	victory_timer.wait_time = 2.8
	victory_timer.timeout.connect(GameState.open_reward)
	add_child(victory_timer)

	var hunt_timer := Timer.new()
	hunt_timer.wait_time = 0.1
	hunt_timer.timeout.connect(on_hunt_timer)
	hunt_timer.autostart = true
	add_child(hunt_timer)


func apply_safe_area() -> void:
	if not safe_container:
		return
	var viewport_size := get_viewport_rect().size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_rect := Rect2(DisplayServer.get_display_safe_area())
	var margins := CoreRules.safe_content_margins(viewport_size, screen_size, safe_rect)
	safe_container.add_theme_constant_override("margin_left", roundi(margins.x))
	safe_container.add_theme_constant_override("margin_top", roundi(margins.y))
	safe_container.add_theme_constant_override("margin_right", roundi(margins.z))
	safe_container.add_theme_constant_override("margin_bottom", roundi(margins.w))


func render() -> void:
	var previous_focus_name := ""
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and content != null and content.is_ancestor_of(focus_owner):
		previous_focus_name = str(focus_owner.name)
	render_generation += 1
	var current_generation := render_generation
	if space_backdrop:
		space_backdrop.planet_id = str(GameState.player.get("current_planet_id", ContentDB.PLANET.id))
	if reference_backdrop:
		reference_backdrop.show_context(reference_placeholder_context())
	if sound_fx:
		sound_fx.enabled = bool(GameState.player.get("sound_enabled", true))
	var phase_changed := previous_phase >= 0 and previous_phase != GameState.phase
	if phase_changed and GameState.phase == GameState.Phase.COMBAT:
		last_combat_message = ""
	if phase_changed and sound_fx:
		match GameState.phase:
			GameState.Phase.HUNT:
				sound_fx.play_accept()
			GameState.Phase.VICTORY:
				sound_fx.play_victory()
			GameState.Phase.REWARD:
				sound_fx.play_reward(str(GameState.pending_loot.get("rarity", "Comum")))
			GameState.Phase.HUNT_EVENT:
				sound_fx.play("accept", 0.72)
			GameState.Phase.CHAPTER_COMPLETE:
				sound_fx.play_victory()
	previous_phase = GameState.phase
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	build_header()
	if not GameState.save_warning.is_empty():
		content.add_child(save_warning_banner())
	if GameState.save_recovery_required:
		combat_timer.stop()
		victory_timer.stop()
		call_deferred("restore_action_focus", previous_focus_name, current_generation)
		return
	match GameState.phase:
		GameState.Phase.BOARD:
			if view_mode == "arsenal":
				build_arsenal()
			elif view_mode == "galaxy":
				build_galaxy_map()
			elif view_mode == "career":
				build_career()
			else:
				build_board()
		GameState.Phase.HUNT:
			build_hunt()
		GameState.Phase.COMBAT:
			build_combat()
		GameState.Phase.REWARD:
			build_reward()
		GameState.Phase.VICTORY:
			build_victory()
		GameState.Phase.BRIEFING:
			build_briefing()
		GameState.Phase.HUNT_EVENT:
			build_hunt_event()
		GameState.Phase.CHAPTER_COMPLETE:
			build_chapter_complete()
	if GameState.phase == GameState.Phase.COMBAT and not timed_actions_suspended:
		if combat_timer.is_stopped():
			combat_timer.start()
	else:
		combat_timer.stop()
	if GameState.phase == GameState.Phase.VICTORY and not timed_actions_suspended:
		if victory_timer.is_stopped():
			victory_timer.start()
	else:
		victory_timer.stop()
	call_deferred("restore_action_focus", previous_focus_name, current_generation)


func reference_placeholder_context() -> String:
	if GameState.phase == GameState.Phase.BOARD:
		if view_mode == "arsenal":
			return "workshop"
		if view_mode == "galaxy" or view_mode == "career":
			return "world"
	if GameState.phase == GameState.Phase.COMBAT or GameState.phase == GameState.Phase.VICTORY:
		return "combat"
	return "contracts"


func restore_action_focus(previous_focus_name: String, expected_generation: int) -> void:
	if expected_generation != render_generation or content == null:
		return
	var current := get_viewport().gui_get_focus_owner()
	if current is Button and content.is_ancestor_of(current) and current.visible and not current.disabled:
		return
	var fallback: Button = null
	for candidate in content.find_children("*", "Button", true, false):
		var button := candidate as Button
		if not button.visible or button.disabled or button.focus_mode == Control.FOCUS_NONE:
			continue
		if fallback == null:
			fallback = button
		if not previous_focus_name.is_empty() and str(button.name) == previous_focus_name:
			button.grab_focus()
			return
	if fallback != null:
		fallback.grab_focus()


func build_header() -> void:
	var planet := active_planet()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", 30, CYAN))
	identity.add_child(label(str(planet.name).to_upper(), 15, Color(str(planet.accent))))

	var level_badge := panel(VBoxContainer.new(), PANEL_LIGHT, 14, 14)
	level_badge.custom_minimum_size = Vector2(122, 72)
	top.add_child(level_badge)
	var badge_box := level_badge.get_child(0) as VBoxContainer
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_box.add_child(label("NÍVEL %d" % int(GameState.player.level), 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	badge_box.add_child(label("PODER %d" % CoreRules.player_power(GameState.player), 18, INK, HORIZONTAL_ALIGNMENT_CENTER))

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	content.add_child(stats)
	stats.add_child(stat_chip("CRÉDITOS", str(GameState.player.credits), GOLD))
	stats.add_child(stat_chip("SUCATA", str(GameState.player.get("scrap", 0)), CORAL))
	stats.add_child(stat_chip("REPUTAÇÃO", "RANK %d" % (int(GameState.player.reputation) + 1), LIME))
	stats.add_child(stat_chip("VITÓRIAS", str(GameState.player.wins), CYAN))


func active_planet() -> Dictionary:
	return ContentDB.get_planet(str(GameState.player.get("current_planet_id", ContentDB.PLANET.id)))


func build_board() -> void:
	var planet := active_planet()
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	title_box.add_child(label("QUADRO DE PROCURADOS", 24, INK))
	title_box.add_child(label(str(planet.subtitle), 15, MUTED))

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	title_row.add_child(actions)
	var xp_needed := CoreRules.xp_needed(int(GameState.player.level))
	var xp_text := "XP %d/%d" % [int(GameState.player.xp), xp_needed]
	actions.add_child(label(xp_text, 14, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	var equipped_receipt := GameState.last_notice_context == "reward_equipped"
	var scrap := int(GameState.player.get("scrap", 0))
	var cheapest_calibration := mini(CoreRules.equipment_upgrade_cost(GameState.player.weapon), CoreRules.equipment_upgrade_cost(GameState.player.armor))
	var funded_field_test := equipped_receipt and scrap >= cheapest_calibration
	var arsenal := action_button("TESTAR BUILD" if funded_field_test else "ARSENAL · %d" % GameState.player.inventory.size(), LIME if funded_field_test else GOLD, true)
	arsenal.name = "PostClaimFieldTestAction" if funded_field_test else "ArsenalAction"
	arsenal.custom_minimum_size = Vector2(160, 48)
	arsenal.add_theme_font_size_override("font_size", 13)
	arsenal.pressed.connect(func():
		view_mode = "arsenal"
		render()
	)
	actions.add_child(arsenal)
	var galaxy := action_button("MAPA GALÁCTICO", CYAN, true)
	galaxy.custom_minimum_size = Vector2(160, 48)
	galaxy.add_theme_font_size_override("font_size", 12)
	galaxy.pressed.connect(func():
		view_mode = "galaxy"
		render()
	)
	actions.add_child(galaxy)
	var ready_rewards := GameState.career_rewards_ready()
	var career_text := "CARREIRA · %d" % ready_rewards if ready_rewards > 0 else "CARREIRA"
	var career := action_button(career_text, LIME, true)
	career.name = "BoardCareerAction"
	career.custom_minimum_size = Vector2(160, 48)
	career.add_theme_font_size_override("font_size", 12)
	career.pressed.connect(func():
		view_mode = "career"
		render()
	)
	actions.add_child(career)

	var recovery_inside_afk := not GameState.afk_report.is_empty() and GameState.last_notice_context == "system_recovery"
	var defeat_report_visible := GameState.last_notice_context == "defeat" and not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true))
	if not GameState.afk_report.is_empty():
		content.add_child(afk_return_banner(recovery_inside_afk))
	if not GameState.last_notice.is_empty() and not recovery_inside_afk and not defeat_report_visible:
		var notice_color := CORAL if not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true)) else LIME
		var dismiss_callback := Callable()
		if GameState.last_notice_context == "system_recovery":
			dismiss_callback = func(): GameState.dismiss_notice("system_recovery")
		var board_notice := notice_banner(GameState.last_notice, notice_color, dismiss_callback)
		board_notice.name = "BoardNotice"
		content.add_child(board_notice)
	elif int(GameState.player.wins) == 0:
		content.add_child(onboarding_banner())
	if not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true)):
		content.add_child(combat_summary_panel(false))
	var streak := int(GameState.player.get("capture_streak", 0))
	var streak_started_inside_receipt := streak == 1 and GameState.last_notice_context.begins_with("reward_")
	if streak > 0 and not streak_started_inside_receipt:
		var next_reward := CoreRules.bounty_streak_reward(100, streak + 1)
		var streak_notice := notice_banner("EMBALO ×%d · próximo contrato recebe +%d%% de créditos · derrota ou abandono encerra a sequência" % [streak, int(next_reward.bonus_percent)], GOLD)
		streak_notice.name = "StreakNotice"
		content.add_child(streak_notice)
	content.add_child(rank_progress_panel())

	var scroller := ScrollContainer.new()
	scroller.name = "BountyScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroller.add_child(list)
	var board_bounties := ContentDB.board_bounties(
		int(GameState.player.reputation),
		str(planet.id),
		GameState.planet_tier(str(planet.id)),
		GameState.player.get("captures_by_target", {})
	)
	if board_bounties.size() > 1:
		var has_primary := board_bounties.any(func(bounty): return str(bounty.get("board_role", "")) == "primary")
		var hint_text := "MANDADO PRINCIPAL EM DESTAQUE · ROTAS DE PERÍCIA CONTINUAM DISPONÍVEIS" if has_primary else "SETOR PACIFICADO · ESCOLHA UMA ROTA DE PERÍCIA"
		var choice_hint := label(hint_text, 11, MUTED)
		choice_hint.name = "BoardChoiceHint"
		choice_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(choice_hint)
	for bounty in board_bounties:
		list.add_child(bounty_card(bounty))

	var equipment := HBoxContainer.new()
	equipment.add_theme_constant_override("separation", 10)
	content.add_child(equipment)
	equipment.add_child(equipment_chip(GameState.player.weapon))
	equipment.add_child(equipment_chip(GameState.player.armor))


func rank_progress_panel() -> PanelContainer:
	var planet := active_planet()
	var warrant_progress := ContentDB.warrant_progress(str(planet.id), GameState.player.get("captures_by_target", {}))
	var next_target: Dictionary = warrant_progress.next_target
	var card := panel(VBoxContainer.new(), Color("#0d1530"), 12, 11)
	card.name = "NextWarrantProgress"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	box.add_child(row)
	if next_target.is_empty():
		var planet_complete: bool = GameState.player.get("completed_planets", []).has(str(planet.id))
		var has_boss := false
		for target in ContentDB.TARGETS:
			if str(target.get("planet_id", "")) == str(planet.id) and bool(target.get("boss", false)):
				has_boss = true
		var left_text := "RANK MÁXIMO DE %s" % str(planet.name).to_upper() if planet_complete else ("ALVO-CHEFE DISPONÍVEL" if has_boss else "FRONTEIRA RECÉM-ABERTA")
		var right_text := "SETOR DOMINADO" if planet_complete else ("EXECUTE O MANDADO FINAL" if has_boss else "NOVOS MANDADOS EM BREVE")
		row.add_child(label(left_text, 12, LIME if planet_complete or not has_boss else CORAL))
		var complete := label(right_text, 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		complete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(complete)
		return card
	var progress_value := int(warrant_progress.progress)
	row.add_child(label("PRÓXIMO ALVO: %s" % str(next_target.name).to_upper(), 12, MUTED))
	var prerequisite: Dictionary = warrant_progress.prerequisite
	var count := label("%d / 3 · %s" % [progress_value, str(prerequisite.name).to_upper()], 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(count)
	var progress := ProgressBar.new()
	progress.max_value = 3
	progress.value = progress_value
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 5))
	progress.add_theme_stylebox_override("fill", box_style(GOLD, 5))
	box.add_child(progress)
	return card


func build_galaxy_map() -> void:
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(copy)
	copy.add_child(label("MAPA GALÁCTICO", 27, INK))
	copy.add_child(label("Planetas são capítulos. Combustível é uma opinião contábil.", 14, MUTED))
	var back := action_button("VOLTAR", CYAN, true)
	back.custom_minimum_size = Vector2(120, 48)
	back.pressed.connect(func():
		view_mode = "board"
		render()
	)
	title_row.add_child(back)
	var route_scroll := ScrollContainer.new()
	route_scroll.name = "GalaxyScroll"
	route_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(route_scroll)
	var route := VBoxContainer.new()
	route.name = "GalaxyRoutes"
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_theme_constant_override("separation", 14)
	route_scroll.add_child(route)
	for planet in ContentDB.PLANETS:
		route.add_child(planet_card(planet))


func planet_card(planet: Dictionary) -> PanelContainer:
	var planet_id := str(planet.id)
	var current := planet_id == str(GameState.player.get("current_planet_id", ContentDB.PLANET.id))
	var unlocked := ContentDB.is_planet_unlocked(planet_id, GameState.player.get("completed_planets", []))
	var completed: bool = GameState.player.get("completed_planets", []).has(planet_id)
	var accent := Color(str(planet.accent))
	var card := panel(VBoxContainer.new(), PANEL_LIGHT if unlocked else Color("#0b1228"), 18, 18)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 9)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(names)
	names.add_child(label(str(planet.name).to_upper(), 22, accent if unlocked else MUTED))
	names.add_child(label(str(planet.subtitle), 14, MUTED))
	var route_status := "EM ÓRBITA" if current else ("CONCLUÍDO" if completed else ("ROTA ABERTA" if unlocked else "BLOQUEADO"))
	heading.add_child(label(route_status, 12, LIME if current or completed else (accent if unlocked else CORAL), HORIZONTAL_ALIGNMENT_RIGHT))
	var description := label(str(planet.get("description", "Fronteira empoeirada, contratos duvidosos e estacionamento abundante.")), 14, INK if unlocked else MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	if unlocked:
		var progress_text := "CAPÍTULO CONCLUÍDO · %d CAPTURAS" % GameState.planet_capture_count(planet_id)
		if not completed:
			var tier := GameState.planet_tier(planet_id)
			var target := ContentDB.target_for_planet_tier(planet_id, tier)
			var required := 1 if tier == 3 else 3
			var target_captures := int(GameState.player.get("captures_by_target", {}).get(str(target.id), 0))
			progress_text = "MANDADO ATUAL: %s · %d/%d" % [str(target.name).to_upper(), target_captures, required]
		var progress := label(progress_text, 12, LIME if completed else GOLD)
		progress.name = "GalaxyPlanetProgress_%s" % planet_id
		box.add_child(progress)
	if unlocked and not current:
		var travel := action_button("VIAJAR PARA %s" % str(planet.name).to_upper(), accent)
		travel.pressed.connect(func():
			view_mode = "board"
			GameState.travel_to_planet(planet_id)
		)
		box.add_child(travel)
	elif not unlocked:
		var requirement := ContentDB.get_planet(str(planet.get("unlock_after", ContentDB.PLANET.id)))
		box.add_child(center_label("CONCLUA %s PARA TRAÇAR ESTA ROTA" % str(requirement.name).to_upper(), 12, MUTED))
	return card


func build_career() -> void:
	CareerViewScript.build(self, content, GameState)


func build_arsenal() -> void:
	ArsenalView.build(self, content, GameState)


func onboarding_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#173356"), 15, 15)
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	row.add_child(center_label("1", 30, CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label("PRIMEIRO TRABALHO", 14, CYAN))
	copy.add_child(label("Aceite Gloop. A primeira captura ensina o ciclo e garante seu primeiro loot.", 14, INK))
	return banner


func notice_banner(message: String, color: Color, dismiss_callback := Callable()) -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#16363b"), 14, 13)
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	row.add_child(label("!" if color == CORAL else "✓", 23, color))
	var message_label := label(message, 14, INK)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(message_label)
	if dismiss_callback.is_valid():
		var dismiss := action_button("OK", color, true)
		dismiss.name = "BoardNoticeDismiss"
		dismiss.custom_minimum_size = Vector2(62, 44)
		dismiss.pressed.connect(dismiss_callback)
		row.add_child(dismiss)
	return banner


func save_warning_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#3b1824"), 14, 12)
	banner.name = "SaveWarningBanner"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var message := label(GameState.save_warning, 12, INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message)
	var recovery_required := GameState.save_recovery_required
	var retry := action_button("INICIAR\nNOVO SAVE" if recovery_required else "TENTAR\nNOVAMENTE", CORAL, true)
	retry.name = "StartFreshSaveAction" if recovery_required else "RetrySaveAction"
	retry.custom_minimum_size = Vector2(112, 48)
	retry.add_theme_font_size_override("font_size", 10)
	retry.pressed.connect(GameState.start_fresh_after_corruption if recovery_required else GameState.retry_save)
	row.add_child(retry)
	return banner


func combat_summary_panel(won: bool) -> PanelContainer:
	var summary := GameState.combat_summary
	var card := panel(VBoxContainer.new(), Color("#16363b") if won else Color("#381c32"), 14, 13)
	card.name = "CombatSummaryVictory" if won else "CombatSummaryDefeat"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var report_title := "RELATÓRIO DO MANDADO" if won else "FUGA: %s" % str(summary.get("target_name", "ALVO DESCONHECIDO")).to_upper()
	var report_heading := label(report_title, 13, LIME if won else CORAL)
	report_heading.name = "CombatReportTitle"
	box.add_child(report_heading)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 7)
	box.add_child(metrics)
	metrics.add_child(metric_chip("TURNOS", str(int(summary.get("rounds", 0))), GOLD))
	metrics.add_child(metric_chip("CAUSADO", str(int(summary.get("damage_dealt", 0))), CYAN))
	metrics.add_child(metric_chip("RECEBIDO", str(int(summary.get("damage_taken", 0))), CORAL))
	var effects: Array[String] = []
	if int(summary.get("opening_bonus", 0)) > 0:
		effects.append("emboscada +%d" % int(summary.opening_bonus))
	if int(summary.get("damage_prevented", 0)) > 0:
		effects.append("%d dano amortecido" % int(summary.damage_prevented))
	var kit_origin := str(summary.get("kit_origin", ""))
	if not kit_origin.is_empty():
		effects.append("kit %s" % str(ContentDB.get_planet(kit_origin).name))
	var evidence_text := "BUILD ATIVA · %s" % " · ".join(effects) if not effects.is_empty() else "SEM EFEITOS TÁTICOS · modificações e kits podem mudar o próximo confronto"
	var evidence := label(evidence_text, 11, GOLD if not effects.is_empty() else MUTED)
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(evidence)
	if not won:
		var route_diagnosis_text := ContractRules.field_test_defeat_text(summary.get("field_test_context", {}))
		if not route_diagnosis_text.is_empty():
			var route_diagnosis := label(route_diagnosis_text, 11, GOLD)
			route_diagnosis.name = "DefeatFieldTestDiagnosis"
			route_diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(route_diagnosis)
		var remaining := int(summary.get("enemy_hp_remaining", 0))
		var diagnosis := label("O alvo conservou %d HP. Compare as odds, ative um kit ou invista na oficina antes da revanche." % remaining, 12, INK)
		diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(diagnosis)
		var lost_streak := int(summary.get("lost_streak", 0))
		if lost_streak > 0:
			var streak_loss := label("EMBALO ×%d ENCERRADO · a próxima captura recomeça em ×1" % lost_streak, 11, CORAL)
			streak_loss.name = "DefeatStreakLoss"
			streak_loss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(streak_loss)
		var workshop := action_button("ABRIR OFICINA E TESTAR BUILD", CYAN, true)
		workshop.name = "DefeatWorkshopAction"
		workshop.custom_minimum_size = Vector2(0, 44)
		workshop.pressed.connect(func():
			view_mode = "arsenal"
			render()
		)
		box.add_child(workshop)
	return card


func afk_return_banner(include_recovery := false) -> PanelContainer:
	var report := GameState.afk_report
	var banner := panel(HBoxContainer.new(), Color("#263653"), 15, 14)
	banner.name = "AfkReturnBanner"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	row.add_child(center_label("AFK", 24, CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label("PATRULHA CONCLUÍDA · %s" % format_duration(int(report.minutes)), 13, CYAN))
	copy.add_child(label("+%d créditos · +%d sucata%s" % [int(report.credits), int(report.scrap), " · LIMITE 8H" if bool(report.capped) else ""], 14, INK))
	if include_recovery:
		var recovery := label(GameState.last_notice, 10, LIME)
		recovery.name = "AfkRecoveryNotice"
		recovery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(recovery)
	var dismiss := action_button("OK", CYAN, true)
	dismiss.name = "AfkDismiss"
	dismiss.custom_minimum_size = Vector2(62, 44)
	dismiss.pressed.connect(func(): GameState.dismiss_afk_report(include_recovery))
	row.add_child(dismiss)
	return banner


func format_duration(minutes: int) -> String:
	if minutes >= 60:
		return "%dh %02dmin" % [floori(float(minutes) / 60.0), minutes % 60]
	return "%dmin" % minutes


func bounty_card(bounty: Dictionary) -> PanelContainer:
	var card := panel(VBoxContainer.new(), PANEL, 18, 20)
	card.name = "BountyCard_%s" % str(bounty.id)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	row.add_child(character_portrait(str(bounty.id), 88))

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var board_reason := str(bounty.get("board_reason", ""))
	if not board_reason.is_empty():
		var role_color := CORAL if str(bounty.get("board_role", "")) == "primary" else CYAN
		var role := label(board_reason, 12, role_color)
		role.name = "BountyRole_%s" % str(bounty.id)
		details.add_child(role)
	elif bool(bounty.get("boss", false)):
		details.add_child(label("CHEFE DO CAPÍTULO", 12, GOLD))
	details.add_child(label(str(bounty.name), 21, GOLD if bool(bounty.get("boss", false)) else INK))
	details.add_child(label(str(bounty.title), 14, CORAL))
	var captures: Dictionary = GameState.player.get("captures_by_target", {})
	var capture_count := int(captures.get(str(bounty.id), 0))
	var mastery_level := CoreRules.target_mastery_level(capture_count)
	if capture_count > 0:
		var next_requirement := CoreRules.target_mastery_next_requirement(mastery_level)
		var mastery_progress := "MÁX." if next_requirement < 0 else "%d/%d" % [capture_count, next_requirement]
		var mastery_label := label("CAPTURAS %d · PERÍCIA %d/3 · %s" % [capture_count, mastery_level, mastery_progress], 11, LIME)
		mastery_label.name = "BountyMastery_%s" % str(bounty.id)
		details.add_child(mastery_label)
	var mastery_objective := CareerRulesScript.next_mastery_objective(GameState.player, ContentDB.TARGETS)
	if not mastery_objective.is_empty() and str(mastery_objective.target.id) == str(bounty.id):
		var route_label := label("ROTA DE PERÍCIA · FALTAM %d CAPTURA%s" % [int(mastery_objective.remaining), "S" if int(mastery_objective.remaining) != 1 else ""], 11, GOLD)
		route_label.name = "MasteryRoute_%s" % str(bounty.id)
		details.add_child(route_label)
	var description := label(str(bounty.description), 14, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)

	var odds := CoreRules.bounty_odds(GameState.player, bounty)
	var payout := CoreRules.bounty_streak_reward(int(bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	footer.add_child(label("◈ %d%s   ✦ %d XP   %ds" % [int(payout.credits), " +EMBALO" if int(payout.bonus_credits) > 0 else "", int(bounty.xp), int(bounty.duration)], 15, GOLD))
	var risk_text := "SEGURO" if odds >= 0.72 else ("ARRISCADO" if odds >= 0.42 else "BRUTAL")
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var risk := label("%s · %d%%" % [risk_text, roundi(odds * 100.0)], 14, risk_color, HORIZONTAL_ALIGNMENT_RIGHT)
	risk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(risk)
	var is_repeat := str(bounty.get("board_role", "")) == "repeat"
	var hunt := action_button("REPETIR CAÇADA" if is_repeat else "ANALISAR ABORDAGENS", GOLD if is_repeat else CYAN)
	hunt.name = "BountyAction_%s" % str(bounty.id)
	hunt.pressed.connect(func():
		briefing_context = {}
		GameState.select_bounty(bounty)
	)
	box.add_child(hunt)
	return card


func build_briefing() -> void:
	var bounty := GameState.current_bounty
	var evaluations := ContractRules.evaluate_approaches(GameState.player, bounty, GameState.offered_approaches)
	var recommended_id := ContractRules.recommended_approach_id(evaluations)
	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 18)
	content.add_child(target_row)
	target_row.add_child(character_portrait(str(bounty.id), 104))
	var target_copy := VBoxContainer.new()
	target_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_copy.add_theme_constant_override("separation", 4)
	target_row.add_child(target_copy)
	target_copy.add_child(label("BRIEFING DO CONTRATO", 15, CYAN))
	target_copy.add_child(label(str(bounty.name), 26, INK))
	if str(briefing_context.get("target_id", "")) == str(bounty.id) and str(briefing_context.get("approach_id", "")) == recommended_id:
		var tested_context := label("BUILD TESTADA · %s · %d%% · RECOMENDAÇÃO CONFIRMADA" % [str(briefing_context.get("approach_name", "CONTRATO BASE")).to_upper(), roundi(float(briefing_context.get("odds", 0.0)) * 100.0)], 11, LIME)
		tested_context.name = "BriefingFieldTestContext"
		target_copy.add_child(tested_context)
	var kit_origin := CoreRules.equipment_set_origin(GameState.player)
	if not kit_origin.is_empty():
		target_copy.add_child(label("KIT PLANETÁRIO · %s · +%d PODER · +%d VIDA" % [str(ContentDB.get_planet(kit_origin).name).to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS], 12, GOLD))
	var target_captures := int(GameState.player.get("captures_by_target", {}).get(str(bounty.id), 0))
	var target_mastery := CoreRules.target_mastery_level(target_captures)
	if target_mastery > 0:
		var mastery_label := label("PERÍCIA %d/3 · +%d%% RARO · +%d%% ÉPICO" % [target_mastery, target_mastery * 5, target_mastery * 2], 12, LIME)
		mastery_label.name = "BriefingMastery"
		target_copy.add_child(mastery_label)
	var flavor := label("O alvo é o mesmo. A quantidade de problemas é uma escolha sua.", 14, MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_copy.add_child(flavor)

	content.add_child(label("ESCOLHA UMA ABORDAGEM", 17, GOLD))
	var recommendation_hint := label("RECOMENDADO equilibra chance, pagamento e experiência.", 11, MUTED)
	recommendation_hint.name = "BriefingRecommendationHint"
	content.add_child(recommendation_hint)
	var scroller := ScrollContainer.new()
	scroller.name = "BriefingScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)
	for index in GameState.offered_approaches.size():
		list.add_child(approach_card(GameState.offered_approaches[index], evaluations[index], recommended_id))
	var cancel := action_button("VOLTAR AO QUADRO", CORAL, true)
	cancel.name = "BriefingCancel"
	cancel.custom_minimum_size = Vector2(0, 48)
	cancel.pressed.connect(func():
		briefing_context = {}
		GameState.cancel_briefing()
	)
	content.add_child(cancel)


func approach_card(approach: Dictionary, evaluation: Dictionary, recommended_id: String) -> PanelContainer:
	var preview: Dictionary = evaluation.preview
	var color := Color(str(approach.color))
	var card := panel(VBoxContainer.new(), PANEL, 16, 16)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(label(str(approach.name).to_upper(), 18, color))
	heading_copy.add_child(label(str(approach.tag), 12, MUTED))
	if str(approach.id) == recommended_id:
		var recommendation := label("RECOMENDADO", 12, LIME, HORIZONTAL_ALIGNMENT_RIGHT)
		recommendation.name = "RecommendedApproach_%s" % str(approach.id)
		heading.add_child(recommendation)
	var description := label(str(approach.description), 14, INK)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var scrap_reward := int(preview.get("scrap_reward", 0))
	if scrap_reward > 0:
		var scrap_bonus := label("BÔNUS DE VITÓRIA · +%d SUCATA PARA A OFICINA" % scrap_reward, 12, GOLD)
		scrap_bonus.name = "ApproachScrapReward_%s" % str(approach.id)
		box.add_child(scrap_bonus)
	if int(evaluation.get("streak_bonus", 0)) > 0:
		var streak_total := label("PAGAMENTO JÁ INCLUI EMBALO ×%d · +%d%% (+%d CRÉDITOS)" % [int(evaluation.streak), int(evaluation.streak_bonus_percent), int(evaluation.streak_bonus)], 11, CYAN)
		streak_total.name = "ApproachStreak_%s" % str(approach.id)
		box.add_child(streak_total)
	var odds := float(evaluation.odds)
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	box.add_child(metrics)
	metrics.add_child(metric_chip("TEMPO", "%ds" % int(preview.duration), MUTED))
	metrics.add_child(metric_chip("CHANCE", "%d%%" % roundi(odds * 100.0), risk_color))
	metrics.add_child(metric_chip("PAGAMENTO", "◈ %d" % int(evaluation.credits), GOLD))
	metrics.add_child(metric_chip("EXPERIÊNCIA", "%d XP" % int(preview.xp), CYAN))
	var choose := action_button("ESCOLHER · %s" % str(approach.name).to_upper(), color)
	var approach_id := str(approach.id)
	choose.name = "ChooseApproach_%s" % approach_id
	choose.pressed.connect(func():
		var tested_context := briefing_context.duplicate(true)
		briefing_context = {}
		GameState.choose_approach(approach_id, tested_context)
	)
	box.add_child(choose)
	return card


func field_test_record_label(node_name: String) -> Label:
	var context: Dictionary = GameState.current_bounty.get("field_test_context", {})
	if context.is_empty():
		return null
	var text_value := "TESTE DE CAMPO CONFIRMADO · %s · %d%%" % [str(context.tested_approach_name).to_upper(), roundi(float(context.tested_odds) * 100.0)]
	var text_color := LIME
	if bool(context.overridden):
		text_value = "ROTA TESTADA SUBSTITUÍDA · %s %d%% → %s" % [str(context.tested_approach_name).to_upper(), roundi(float(context.tested_odds) * 100.0), str(context.chosen_approach_name).to_upper()]
		text_color = GOLD
	var result := center_label(text_value, 13, text_color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.name = node_name
	return result


func build_hunt() -> void:
	var bounty := GameState.current_bounty
	content.add_spacer(false)
	content.add_child(center_label("CAÇADA EM ANDAMENTO", 19, CYAN))
	content.add_child(character_portrait(str(bounty.id), 150))
	content.add_child(center_label(str(bounty.name), 30, INK))
	var approach: Dictionary = bounty.get("approach", {})
	if not approach.is_empty():
		content.add_child(center_label(str(approach.name).to_upper(), 16, Color(str(approach.color))))
	var field_test_record := field_test_record_label("HuntFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	content.add_child(center_label("Seguindo sinais, subornando robôs e fingindo ter um plano.", 16, MUTED))
	if bounty.has("hunt_event_result"):
		content.add_child(notice_banner(str(bounty.hunt_event_result), GOLD))

	var progress := ProgressBar.new()
	progress.name = "HuntProgress"
	progress.value = GameState.hunt_progress() * 100.0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 24)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 12))
	progress.add_theme_stylebox_override("fill", box_style(CYAN, 12))
	content.add_child(progress)

	var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
	var countdown := center_label("ALVO LOCALIZADO EM %ds" % remaining, 18, GOLD)
	countdown.name = "HuntCountdown"
	content.add_child(countdown)
	content.add_spacer(false)
	var abandon := action_button(abandon_contract_text(), CORAL, true)
	abandon.name = "HuntAbandonAction"
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func build_hunt_event() -> void:
	var event := GameState.hunt_event
	var accent := Color(str(event.get("color", "#ffc857")))
	content.add_spacer(false)
	content.add_child(center_label("IMPREVISTO NA CAÇADA", 17, CORAL))
	var field_test_record := field_test_record_label("IncidentFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	var incident := panel(VBoxContainer.new(), Color("#18264b"), 20, 22)
	content.add_child(incident)
	var incident_box := incident.get_child(0) as VBoxContainer
	incident_box.alignment = BoxContainer.ALIGNMENT_CENTER
	incident_box.add_theme_constant_override("separation", 8)
	var symbol := str(event.get("symbol", "?!"))
	incident_box.add_child(center_label(symbol, 42, accent))
	incident_box.add_child(center_label(str(event.get("title", "Algo Estranho")), 26, INK))
	var description := center_label(str(event.get("description", "A perseguição ficou mais complicada.")), 15, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	incident_box.add_child(description)
	var paused_duration := maxf(0.1, GameState.hunt_elapsed_before_event + GameState.hunt_remaining_after_event)
	var paused_percent := roundi(100.0 * GameState.hunt_elapsed_before_event / paused_duration)
	var pause_status := center_label("CAÇA PAUSADA EM %d%% · %ds RESTANTES APÓS A ESCOLHA" % [paused_percent, ceili(GameState.hunt_remaining_after_event)], 12, GOLD)
	pause_status.name = "HuntEventPauseStatus"
	incident_box.add_child(pause_status)

	var choices := VBoxContainer.new()
	choices.name = "HuntEventChoices"
	choices.add_theme_constant_override("separation", 10)
	content.add_child(choices)
	for choice in event.get("choices", []):
		choices.add_child(hunt_choice_card(choice, accent))
	content.add_spacer(false)
	var abandon := action_button(abandon_contract_text(), CORAL, true)
	abandon.name = "HuntAbandonAction"
	abandon.custom_minimum_size = Vector2(0, 46)
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func abandon_contract_text() -> String:
	var streak := int(GameState.player.get("capture_streak", 0))
	return "ABANDONAR · PERDER EMBALO ×%d" % streak if streak > 0 else "ABANDONAR CONTRATO"


func hunt_choice_card(choice: Dictionary, accent: Color) -> PanelContainer:
	var card := panel(HBoxContainer.new(), PANEL, 13, 12)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(str(choice.name), 15, accent))
	var effect := label(str(choice.effect_text), 13, MUTED)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(effect)
	var projected_contract := ContentDB.apply_hunt_choice(GameState.current_bounty, choice)
	var projected_payment := CoreRules.bounty_streak_reward(int(projected_contract.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var payment_text := "PAGAMENTO SE VENCER · ◈ %d" % int(projected_payment.credits)
	if int(projected_payment.bonus_credits) > 0:
		payment_text += " · EMBALO +%d INCLUÍDO" % int(projected_payment.bonus_credits)
	var choice_cost := int(choice.get("credit_cost", 0))
	if choice_cost > 0:
		payment_text += " · LÍQUIDO APÓS CUSTO ◈ %d" % (int(projected_payment.credits) - choice_cost)
	var payment := label(payment_text, 11, GOLD)
	payment.name = "HuntChoicePayment_%s" % str(choice.id)
	copy.add_child(payment)
	var affordable := GameState.can_afford_hunt_choice(choice)
	var missing_credits := maxi(0, choice_cost - int(GameState.player.credits))
	var choice_text := "ESCOLHER" if affordable else "FALTAM %d CR" % missing_credits
	var choose := action_button(choice_text, accent, true)
	choose.custom_minimum_size = Vector2(142, 48)
	choose.disabled = not affordable
	var choice_id := str(choice.id)
	choose.name = "HuntChoice_%s" % choice_id
	choose.pressed.connect(func(): GameState.resolve_hunt_event(choice_id))
	row.add_child(choose)
	return card


func build_combat() -> void:
	var approach: Dictionary = GameState.current_bounty.get("approach", {})
	var approach_suffix := " · %s" % str(approach.get("name", "")).to_upper() if not approach.is_empty() else ""
	content.add_child(center_label("ENCONTRO AUTOMÁTICO · TURNO %d%s" % [GameState.combat_round, approach_suffix], 17, CORAL))
	var field_test_record := field_test_record_label("CombatFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	if GameState.current_bounty.has("hunt_event_result"):
		var combat_payment := CoreRules.bounty_streak_reward(int(GameState.current_bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
		var incident_text := "INCIDENTE APLICADO · %s · PAGAMENTO ◈ %d" % [str(GameState.current_bounty.hunt_event_result), int(combat_payment.credits)]
		if int(combat_payment.bonus_credits) > 0:
			incident_text += " (EMBALO +%d INCLUÍDO)" % int(combat_payment.bonus_credits)
		var incident_summary := center_label(incident_text, 11, GOLD)
		incident_summary.name = "CombatIncidentSummary"
		incident_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(incident_summary)
	var stage := PanelContainer.new()
	stage.clip_contents = true
	stage.custom_minimum_size = Vector2(0, 390)
	stage.add_theme_stylebox_override("panel", box_style(PANEL, 18))
	content.add_child(stage)
	var backdrop: Control = CombatBackdropScript.new()
	backdrop.events = GameState.combat_events
	backdrop.planet_id = str(GameState.current_bounty.get("planet_id", ContentDB.PLANET.id))
	stage.add_child(backdrop)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 18)
	stage_margin.add_theme_constant_override("margin_right", 18)
	stage_margin.add_theme_constant_override("margin_top", 18)
	stage_margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(stage_margin)
	var stage_box := VBoxContainer.new()
	stage_box.add_theme_constant_override("separation", 8)
	stage_margin.add_child(stage_box)
	var event_row := HBoxContainer.new()
	event_row.alignment = BoxContainer.ALIGNMENT_CENTER
	event_row.add_theme_constant_override("separation", 8)
	stage_box.add_child(event_row)
	if GameState.combat_events.is_empty():
		event_row.add_child(center_label("SENSORES TRAVADOS · ARMAS CARREGADAS", 14, GOLD))
	else:
		for event in GameState.combat_events:
			event_row.add_child(combat_event_chip(event))
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 20)
	stage_box.add_child(arena)
	arena.add_child(fighter("VOCÊ", "hunter", GameState.player_hp, CoreRules.max_health(GameState.player), CYAN))
	arena.add_child(center_label("VS", 28, GOLD))
	arena.add_child(fighter(str(GameState.current_bounty.name), str(GameState.current_bounty.id), GameState.enemy_hp, int(GameState.current_bounty.health), CORAL))

	var log_panel := panel(VBoxContainer.new(), PANEL, 18, 18)
	log_panel.custom_minimum_size = Vector2(0, 105)
	content.add_child(log_panel)
	var log_box := log_panel.get_child(0) as VBoxContainer
	log_box.add_child(label("RELATÓRIO DE CAMPO", 14, MUTED))
	var message := last_combat_message if not last_combat_message.is_empty() else "Os dois lados avaliam suas escolhas de vida..."
	var log_label := label(message, 17, INK)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(log_label)
	var speed := action_button("VELOCIDADE · %s" % ("2×" if combat_fast else "1×"), CYAN, true)
	speed.name = "CombatSpeedAction"
	speed.custom_minimum_size = Vector2(0, 46)
	speed.pressed.connect(func():
		combat_fast = not combat_fast
		combat_timer.wait_time = 0.34 if combat_fast else 0.72
		render()
	)
	content.add_child(speed)


func combat_event_chip(event: Dictionary) -> PanelContainer:
	var player_action := str(event.get("actor", "")) == "player"
	var color := CYAN if player_action else CORAL
	var chip := panel(VBoxContainer.new(), Color("#0a1025cc"), 10, 8)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(str(event.get("action", "GOLPE")).to_upper(), 11, color, HORIZONTAL_ALIGNMENT_CENTER))
	var quality := str(event.get("quality", "ACERTO"))
	var quality_color := GOLD if quality == "CRÍTICO" else (MUTED if quality == "DE RASPÃO" else INK)
	box.add_child(label("%d DANO · %s" % [int(event.get("damage", 0)), quality], 12, quality_color, HORIZONTAL_ALIGNMENT_CENTER))
	if event.has("effect"):
		box.add_child(label(str(event.effect), 10, LIME if player_action else CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func build_victory() -> void:
	content.add_spacer(false)
	content.add_child(center_label("MANDADO EXECUTADO", 16, MUTED))
	content.add_child(character_portrait(str(GameState.current_bounty.id), 132))
	var stamp := panel(VBoxContainer.new(), Color("#173f3c"), 18, 22)
	content.add_child(stamp)
	var stamp_box := stamp.get_child(0) as VBoxContainer
	stamp_box.add_child(center_label("ALVO CAPTURADO", 34, LIME))
	stamp_box.add_child(center_label(str(GameState.current_bounty.name), 21, INK))
	if not GameState.combat_events.is_empty():
		var final_event: Dictionary = GameState.combat_events[0]
		stamp_box.add_child(center_label("Finalizado com %s · %d de dano" % [str(final_event.action), int(final_event.damage)], 14, GOLD))
	var field_test_record := field_test_record_label("VictoryFieldTestContext")
	if field_test_record != null:
		stamp_box.add_child(field_test_record)
	if not GameState.combat_summary.is_empty():
		content.add_child(combat_summary_panel(true))
	var victory_payment := CoreRules.bounty_streak_reward(int(GameState.current_bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var payment_text := "PAGAMENTO APROVADO · ◈ %d" % int(victory_payment.credits)
	if int(victory_payment.bonus_credits) > 0:
		payment_text += " · EMBALO +%d INCLUÍDO" % int(victory_payment.bonus_credits)
	var incident_cost := maxi(0, int(GameState.current_bounty.get("hunt_event_credit_cost", 0)))
	if incident_cost > 0:
		payment_text += " · SALDO +%d APÓS CUSTO" % (int(victory_payment.credits) - incident_cost)
	var payment := center_label(payment_text, 12, GOLD)
	payment.name = "VictoryPayment"
	content.add_child(payment)
	content.add_child(center_label("Autenticando pagamento e sacudindo os bolsos do alvo...", 15, MUTED))
	content.add_spacer(false)
	var open_reward := action_button("ABRIR RECOMPENSA", LIME)
	open_reward.name = "OpenRewardAction"
	open_reward.custom_minimum_size = Vector2(0, 48)
	open_reward.pressed.connect(GameState.open_reward)
	content.add_child(open_reward)


func build_reward() -> void:
	RewardViewScript.build(self, content, GameState)


func build_chapter_complete() -> void:
	var completion := GameState.chapter_completion
	var target: Dictionary = completion.get("target", {})
	var planet: Dictionary = completion.get("planet", ContentDB.PLANET)
	var chapter := panel(VBoxContainer.new(), Color("#302541"), 24, 24)
	chapter.name = "ChapterComplete"
	content.add_child(chapter)
	var box := chapter.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	box.add_child(center_label("CAPÍTULO CONCLUÍDO", 16, GOLD))
	box.add_child(center_label(str(planet.name).to_upper(), 34, INK))
	box.add_child(character_portrait(str(target.get("id", "mayor_gold_dust")), 174))
	box.add_child(center_label("MANDADO FINAL EXECUTADO", 18, LIME))
	box.add_child(center_label(str(target.get("name", "Prefeito Pó-de-Ouro")), 25, GOLD))
	var verdict := center_label(str(planet.get("completion_text", "A autoridade local foi retirada do organograma à força.")), 15, MUTED)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(verdict)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	box.add_child(stats)
	stats.add_child(metric_chip("CAPTURAS", str(completion.get("total_captures", GameState.player.wins)), CYAN))
	stats.add_child(metric_chip("REPUTAÇÃO", "RANK %d" % (int(GameState.player.reputation) + 1), LIME))
	stats.add_child(metric_chip("PAGAMENTO", "◈ %d" % int(completion.get("credits", 0)), GOLD))
	content.add_child(center_label("%s permanece aberto para novas caçadas e equipamento melhor." % str(planet.name), 14, MUTED))
	content.add_spacer(false)
	var continue_button := action_button("CONTINUAR CAÇANDO", GOLD)
	continue_button.pressed.connect(GameState.continue_after_chapter)
	content.add_child(continue_button)


func fighter(title: String, character_id: String, hp: int, maximum: int, color: Color) -> VBoxContainer:
	var fighter_box := VBoxContainer.new()
	fighter_box.custom_minimum_size = Vector2(242, 245)
	fighter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	fighter_box.add_child(character_portrait(character_id, 118))
	var name_label := center_label(title.to_upper(), 16, color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fighter_box.add_child(name_label)
	if character_id == "hunter":
		var kit_origin := CoreRules.equipment_set_origin(GameState.player)
		if not kit_origin.is_empty():
			fighter_box.add_child(center_label("KIT %s · +%d PODER · +%d VIDA" % [str(ContentDB.get_planet(kit_origin).name).to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS], 10, GOLD))
	var health := ProgressBar.new()
	health.max_value = maximum
	health.value = hp
	health.show_percentage = false
	health.custom_minimum_size = Vector2(230, 20)
	health.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 10))
	health.add_theme_stylebox_override("fill", box_style(color, 10))
	fighter_box.add_child(health)
	fighter_box.add_child(center_label("%d / %d HP" % [hp, maximum], 14, MUTED))
	return fighter_box


func on_hunt_timer() -> void:
	if GameState.phase != GameState.Phase.HUNT:
		return
	if GameState.update_hunt():
		return
	var progress := find_child("HuntProgress", true, false) as ProgressBar
	var countdown := find_child("HuntCountdown", true, false) as Label
	if progress:
		progress.value = GameState.hunt_progress() * 100.0
	if countdown:
		var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
		countdown.text = "ALVO LOCALIZADO EM %ds" % remaining


func on_combat_timer() -> void:
	if GameState.phase != GameState.Phase.COMBAT:
		combat_timer.stop()
		return
	var result := GameState.combat_step()
	last_combat_message = str(result.get("message", ""))
	if sound_fx:
		sound_fx.play_combat(GameState.combat_events)
	if not bool(result.get("finished", false)):
		render()
	if bool(result.get("finished", false)) and not bool(result.get("won", false)):
		show_defeat()


func show_toast(summary: Dictionary) -> void:
	if summary.is_empty():
		return
	var message := "+%d créditos · +%d XP" % [int(summary.credits), int(summary.xp)]
	if int(summary.get("scrap", 0)) > 0:
		message += " · +%d SUCATA" % int(summary.scrap)
	if int(summary.levels) > 0:
		message += " · NÍVEL +%d" % int(summary.levels)
	if bool(summary.rank_up):
		message += " · NOVO RANK"
	last_combat_message = message


func show_defeat() -> void:
	last_combat_message = "O alvo escapou. Melhore seu equipamento e tente outra vez."
