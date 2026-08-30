class_name ChallengeView
extends RefCounted

const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const RiftPortalVisualScript = preload("res://scripts/rift_portal_visual.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: CrookedGameState) -> void:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	content.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_copy.add_theme_constant_override("separation", 4)
	heading.add_child(heading_copy)
	heading_copy.add_child(host.scene_title(t("RIFT_TITLE", "FENDA CLANDESTINA")))
	heading_copy.add_child(host.readable_caption(t("RIFT_SUBTITLE", "Uma chave abre cada realidade. Uma entrada atravessa a Fenda por dia.")))
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.name = "ChallengeBack"
	back.custom_minimum_size.x = 118
	back.pressed.connect(func(): host.call("open_frontier_menu"))
	heading.add_child(back)
	var key_count: int = state.player.get("rift_reality_keys", []).size()
	if ChallengeRulesScript.is_unlocked(state.player) and not state.player.get("rift_reality_keys", []).has(str(ChallengeRulesScript.REALITIES[0].key_id)):
		key_count += 1
	var marker := host.metric_chip(t("RIFT_KEYS", "CHAVES"), "%d/%d" % [key_count, ChallengeRulesScript.REALITIES.size()], host.CORAL)
	marker.name = "ChallengeMarker"
	marker.custom_minimum_size.y = 52
	content.add_child(marker)

	if not ChallengeRulesScript.is_unlocked(state.player):
		var locked := host.illustrated_panel(VBoxContainer.new(), 24)
		locked.name = "ChallengeLockedPanel"
		var locked_box := locked.get_child(0) as VBoxContainer
		locked_box.add_theme_constant_override("separation", 9)
		locked_box.add_child(host.center_label(t("RIFT_ENCRYPTED_SIGNAL", "SINAL CRIPTOGRAFADO"), UIDesignSystem.FONT_CAPTION, host.CORAL))
		locked_box.add_child(host.center_label(t("RIFT_INACCESSIBLE", "FENDA AINDA INACESSÍVEL"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
		var requirement := host.center_label(t("RIFT_UNLOCK_REQUIREMENT", "Alcance o nível %d de caçador para localizar a entrada e abrir a primeira incursão.", [ChallengeRulesScript.UNLOCK_LEVEL]), UIDesignSystem.FONT_BODY, host.MUTED)
		requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked_box.add_child(requirement)
		content.add_child(locked)
		return

	var status := state.rift_status()
	var unseen_reality: Dictionary = status.get("unseen_key_reality", {})
	if not unseen_reality.is_empty():
		build_portal_reveal(host, content, state, unseen_reality)
		return
	var reality_id := str(status.reality_id)
	var reality: Dictionary = status.reality
	var floor := int(status.progress)
	if state.player.get("rift_reality_keys", []).size() > 1:
		var reality_selector := OptionButton.new()
		reality_selector.name = "ChallengeRealitySelector"
		reality_selector.custom_minimum_size.y = UIDesignSystem.TOUCH_TARGET_MIN
		reality_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reality_selector.fit_to_longest_item = false
		reality_selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		reality_selector.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		var keyed_reality_ids: Array[String] = []
		var selected_index := 0
		for reality_definition in ChallengeRulesScript.REALITIES:
			var candidate_id := str(reality_definition.id)
			if not ChallengeRulesScript.has_reality_key(state.player, candidate_id):
				continue
			var candidate_floor := ChallengeRulesScript.progress(state.player, candidate_id)
			var candidate_name := t(LocaleRules.content_key("rift_reality", candidate_id, "name"), str(reality_definition.name))
			var tab_text := t("RIFT_REALITY_TAB", "%s · %d/12", [candidate_name.to_upper(), candidate_floor])
			keyed_reality_ids.append(candidate_id)
			reality_selector.add_item(tab_text)
			if candidate_id == reality_id:
				selected_index = keyed_reality_ids.size() - 1
		reality_selector.select(selected_index)
		reality_selector.item_selected.connect(func(index: int): state.select_rift_reality(keyed_reality_ids[index]))
		content.add_child(reality_selector)
	var reality_panel := host.panel(VBoxContainer.new(), Color("#17152b"), 15, 11)
	reality_panel.name = "ChallengeRealityPanel"
	var reality_copy := reality_panel.get_child(0) as VBoxContainer
	reality_copy.add_child(host.center_label(t("RIFT_REALITY_LABEL", "REALIDADE ABERTA · CHAVE ESTABILIZADA"), UIDesignSystem.FONT_CAPTION, host.CORAL))
	reality_copy.add_child(host.center_label(t(LocaleRules.content_key("rift_reality", reality_id, "name"), str(reality.name)), UIDesignSystem.FONT_EMPHASIS, host.INK))
	var reality_description := host.center_label(t(LocaleRules.content_key("rift_reality", reality_id, "description"), str(reality.description)), UIDesignSystem.FONT_CAPTION, host.MUTED)
	reality_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reality_copy.add_child(reality_description)
	content.add_child(reality_panel)
	var track := GridContainer.new()
	track.name = "ChallengeProgressTrack"
	track.columns = 2
	track.add_theme_constant_override("h_separation", 7)
	track.add_theme_constant_override("v_separation", 7)
	content.add_child(track)
	var sector_slots := ChallengeRulesScript.REWARD_SECTORS
	for sector_index in sector_slots.size():
		var sector_start := sector_index * ChallengeRulesScript.FLOORS_PER_SECTOR
		var cleared_in_sector := ChallengeRulesScript.sector_progress(floor, sector_index)
		var color := host.LIME if cleared_in_sector == ChallengeRulesScript.FLOORS_PER_SECTOR else (host.GOLD if floor >= sector_start and floor < sector_start + ChallengeRulesScript.FLOORS_PER_SECTOR else host.MUTED)
		var chip := host.metric_chip(EquipmentPresentation.localized_slot(sector_slots[sector_index]).to_upper(), "%d/%d" % [cleared_in_sector, ChallengeRulesScript.FLOORS_PER_SECTOR], color)
		chip.name = "ChallengeSector_%s" % sector_slots[sector_index].capitalize()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.add_child(chip)

	if floor >= ChallengeRulesScript.STAGES.size():
		var complete := host.illustrated_panel(VBoxContainer.new(), 20)
		complete.name = "ChallengeCompletePanel"
		var complete_box := complete.get_child(0) as VBoxContainer
		complete_box.add_child(host.center_label(t("RIFT_ARCHIVE_CLOSED", "ARQUIVO IMPOSSÍVEL ENCERRADO"), UIDesignSystem.FONT_CAPTION, host.LIME))
		complete_box.add_child(host.center_label(t("RIFT_CLEARED", "FENDA LIMPA"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
		var complete_copy := host.center_label(t("RIFT_COMPLETE_DESCRIPTION", "Os doze carcereiros desta realidade foram removidos. A chave e todos os artefatos descobertos permanecem no Arquivo."), UIDesignSystem.FONT_CAPTION, host.MUTED)
		complete_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete_box.add_child(complete_copy)
		content.add_child(complete)
		return

	if not state.last_notice.is_empty() and state.last_notice_context.begins_with("challenge_"):
		var notice_color := host.CORAL if state.last_notice_context == "challenge_defeat" else host.LIME
		var notice: PanelContainer = host.notice_banner(state.last_notice, notice_color)
		notice.name = "ChallengeNotice"
		content.add_child(notice)

	var stage := ChallengeRulesScript.current_stage(state.player, reality_id)
	var scroller := TouchScrollContainer.new()
	scroller.name = "ChallengeScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	scroller.add_child(stack)
	var dossier := host.illustrated_panel(HBoxContainer.new(), 17)
	dossier.name = "ChallengeCurrentDossier"
	stack.add_child(dossier)
	var row := dossier.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 13)
	row.add_child(host.character_portrait(str(stage.id), 112))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(localized_stage_field(stage, "title"), UIDesignSystem.FONT_CAPTION, host.CORAL))
	copy.add_child(host.label(localized_stage_field(stage, "name"), UIDesignSystem.FONT_EMPHASIS, host.INK))
	var recommended_level := host.label(t("RIFT_RECOMMENDED_LEVEL", "ENVELOPE RECOMENDADO · NÍVEL %d", [int(stage.recommended_level)]), UIDesignSystem.FONT_CAPTION, host.GOLD)
	recommended_level.name = "ChallengeRecommendedLevel"
	copy.add_child(recommended_level)
	var description := host.label(localized_stage_field(stage, "description"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)

	var odds := Rules.bounty_odds(state.player, stage)
	var readiness_color := host.LIME if odds >= 0.65 else (host.GOLD if odds >= 0.45 else host.CORAL)
	var metrics := HBoxContainer.new()
	metrics.name = "ChallengeMetrics"
	metrics.add_theme_constant_override("separation", 7)
	stack.add_child(metrics)
	metrics.add_child(host.metric_chip(t("COMMON_CHANCE", "CHANCE"), "%d%%" % roundi(odds * 100.0), readiness_color))
	metrics.add_child(host.metric_chip(t("COMMON_POWER", "PODER"), str(int(stage.power)), host.CORAL))
	metrics.add_child(host.metric_chip(t("COMMON_HEALTH", "VIDA"), str(int(stage.health)), host.CYAN))
	var anomaly: Dictionary = stage.anomaly
	var anomaly_panel := host.panel(VBoxContainer.new(), Color("#26172f"), 16, 13)
	anomaly_panel.name = "ChallengeAnomalyRule"
	var anomaly_copy := anomaly_panel.get_child(0) as VBoxContainer
	anomaly_copy.add_child(host.center_label(t("RIFT_ANOMALY_TEST", "ANOMALIA · %s · TESTE DE %s", [localized_anomaly_field(str(stage.anomaly_id), anomaly, "name"), localized_anomaly_field(str(stage.anomaly_id), anomaly, "favored_axis")]), UIDesignSystem.FONT_CAPTION, host.CORAL))
	var anomaly_description := host.center_label(localized_anomaly_field(str(stage.anomaly_id), anomaly, "description"), UIDesignSystem.FONT_CAPTION, host.INK)
	anomaly_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anomaly_copy.add_child(anomaly_description)
	anomaly_copy.add_child(host.center_label(t("RIFT_ANOMALY_VALUES", "MITIGAÇÃO IGNORADA %d%% · ABERTURA ×%.1f", [roundi(float(stage.damage_reduction_piercing) * 100.0), float(stage.opening_damage_multiplier)]), UIDesignSystem.FONT_CAPTION, host.MUTED))
	stack.add_child(anomaly_panel)

	var mystery := host.panel(VBoxContainer.new(), Color("#10233b"), 15, 12)
	mystery.name = "ChallengeHiddenReward"
	var mystery_copy := mystery.get_child(0) as VBoxContainer
	mystery_copy.add_child(host.center_label(t("RIFT_REWARD_HIDDEN", "RECOMPENSA SELADA"), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var mystery_description := host.center_label(t("RIFT_REWARD_HIDDEN_DESCRIPTION", "A Fenda entrega equipamento e recursos superiores, mas só revela o conteúdo depois da vitória."), UIDesignSystem.FONT_CAPTION, host.INK)
	mystery_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mystery_copy.add_child(mystery_description)
	stack.add_child(mystery)

	var rules := host.center_label(t("RIFT_RULES", "Uma tentativa gratuita · sem combustível · vitória fecha o dia · derrota permite até três repetições por ◆ 1/5/20."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	rules.name = "ChallengeRulesNotice"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(rules)
	var attempt: Dictionary = status.attempt
	var can_attempt := bool(attempt.can_attempt)
	var enter_text := t("RIFT_START", "ENTRAR NA FENDA · INIMIGO %d/12", [floor + 1])
	if bool(attempt.won_today):
		enter_text = t("RIFT_VICTORY_LOCKED", "VITÓRIA REGISTADA · REABRE ÀS 00:00 UTC")
	elif bool(attempt.attempted_today):
		if not bool(attempt.retry_available):
			enter_text = t("RIFT_RETRY_LIMIT", "REPETIÇÕES ESGOTADAS · REABRE ÀS 00:00 UTC")
		elif not bool(attempt.can_afford_retry):
			enter_text = t("RIFT_RETRY_UNAFFORDABLE", "FICHAS INSUFICIENTES · NECESSÁRIO ◆ %d", [int(attempt.retry_cost)])
		else:
			enter_text = t("RIFT_RETRY_PREPARE", "PREPARAR REPETIÇÃO · ◆ %d · RESTAM %d", [int(attempt.retry_cost), int(attempt.retries_remaining)])
	var enter := host.primary_action(enter_text, readiness_color if can_attempt else host.MUTED)
	enter.name = "ChallengeEnterAction"
	enter.disabled = not can_attempt
	var stage_id := str(stage.id)
	if bool(attempt.attempted_today):
		enter.pressed.connect(func():
			host.rift_retry_confirmation = true
			host.call("render")
		)
	else:
		enter.pressed.connect(func(): state.start_challenge(stage_id))
	content.add_child(enter)
	if host.rift_retry_confirmation and bool(attempt.attempted_today) and can_attempt:
		content.add_child(retry_confirmation_panel(host, state, stage_id, int(attempt.retry_cost), int(attempt.retry_count) + 1))


static func build_portal_reveal(host: CrookedUIFactory, content: VBoxContainer, state: CrookedGameState, reality: Dictionary) -> void:
	var panel := host.illustrated_panel(VBoxContainer.new(), 18)
	panel.name = "ChallengePortalReveal"
	var box := panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 10)
	box.add_child(host.center_label(t("RIFT_PORTAL_KEY_DETECTED", "CHAVE DE REALIDADE DETETADA"), UIDesignSystem.FONT_CAPTION, host.GOLD))
	box.add_child(host.center_label(t("RIFT_PORTAL_OPENING", "ABERTURA DE FENDA EM CURSO"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
	var portal := RiftPortalVisualScript.new()
	portal.name = "ChallengePortalVisual"
	portal.configure(portal_color(str(reality.id)), bool(state.player.get("reduced_motion", false)))
	box.add_child(portal)
	var reality_name := t(LocaleRules.content_key("rift_reality", str(reality.id), "name"), str(reality.name))
	var revealed := host.center_label(t("RIFT_PORTAL_DESTINATION", "DESTINO ESTABILIZADO · %s", [reality_name.to_upper()]), UIDesignSystem.FONT_EMPHASIS, host.CYAN)
	revealed.name = "ChallengePortalDestination"
	revealed.modulate.a = 0.25
	box.add_child(revealed)
	var description := host.center_label(t("RIFT_PORTAL_DESCRIPTION", "A chave encaixa no mecanismo e rasga uma passagem permanente para a nova realidade."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var continue_action := host.primary_action(t("RIFT_PORTAL_APPROACH", "APROXIMAR-SE DO PORTAL"), host.CYAN)
	continue_action.name = "ChallengePortalContinue"
	continue_action.disabled = true
	var key_id := str(reality.key_id)
	continue_action.pressed.connect(func(): state.acknowledge_rift_key(key_id))
	box.add_child(continue_action)
	var skip := host.secondary_action(t("RIFT_PORTAL_SKIP", "ESTABILIZAR IMEDIATAMENTE"), host.MUTED)
	skip.name = "ChallengePortalSkip"
	skip.pressed.connect(portal.complete_immediately)
	box.add_child(skip)
	portal.stabilized.connect(func():
		revealed.modulate.a = 1.0
		continue_action.disabled = false
		skip.visible = false
	)
	content.add_child(panel)


static func retry_confirmation_panel(host: CrookedUIFactory, state: CrookedGameState, stage_id: String, cost: int, use_number: int) -> PanelContainer:
	var panel := host.panel(VBoxContainer.new(), Color("#382344"), 15, 12)
	panel.name = "ChallengeRetryConfirmation"
	var box := panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 9)
	var warning := host.label(t("RIFT_RETRY_CONFIRMATION", "CONFIRMAR REPETIÇÃO %d/3 · gastar ◆ %d repete o mesmo inimigo, anomalia e recompensa selada.", [use_number, cost]), UIDesignSystem.FONT_CAPTION, host.INK)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var cancel := host.secondary_action(t("ACTION_CANCEL", "CANCELAR"), host.MUTED)
	cancel.name = "ChallengeRetryCancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func():
		host.rift_retry_confirmation = false
		host.call("render")
	)
	actions.add_child(cancel)
	var confirm := host.primary_action(t("RIFT_RETRY_CONFIRM", "REPETIR · ◆ %d", [cost]), host.CORAL)
	confirm.name = "ChallengeRetryConfirm"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(func():
		host.rift_retry_confirmation = false
		state.start_challenge(stage_id, -1.0, cost)
	)
	actions.add_child(confirm)
	return panel


static func portal_color(reality_id: String) -> Color:
	return {
		"dead_customs": Color("#d789ff"),
		"frozen_verdict": Color("#55e5ff"),
		"rejected_futures": Color("#ff6f7d"),
	}.get(reality_id, Color("#d789ff"))


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_stage_field(stage: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_stage", str(stage.get("localization_stage_id", stage.get("id", ""))), field), str(stage.get(field, "")))


static func localized_anomaly_field(anomaly_id: String, anomaly: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_anomaly", anomaly_id, field), str(anomaly.get(field, "")))
