class_name ChallengeView
extends RefCounted

const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


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
	var reality_id := str(status.reality_id)
	var reality: Dictionary = status.reality
	var floor := int(status.progress)
	if state.player.get("rift_reality_keys", []).size() > 1:
		var reality_tabs := VBoxContainer.new()
		reality_tabs.name = "ChallengeRealityTabs"
		reality_tabs.add_theme_constant_override("separation", 7)
		content.add_child(reality_tabs)
		for reality_definition in ChallengeRulesScript.REALITIES:
			var candidate_id := str(reality_definition.id)
			if not ChallengeRulesScript.has_reality_key(state.player, candidate_id):
				continue
			var candidate_floor := ChallengeRulesScript.progress(state.player, candidate_id)
			var candidate_name := t(LocaleRules.content_key("rift_reality", candidate_id, "name"), str(reality_definition.name))
			var tab_text := t("RIFT_REALITY_TAB", "%s · %d/12", [candidate_name.to_upper(), candidate_floor])
			var tab := host.primary_action(tab_text, host.CORAL) if candidate_id == reality_id else host.secondary_action(tab_text, host.CYAN)
			tab.name = "ChallengeRealityTab_%s" % candidate_id
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab.disabled = candidate_id == reality_id
			tab.pressed.connect(Callable(state, "select_rift_reality").bind(candidate_id))
			reality_tabs.add_child(tab)
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
	var scroller := ScrollContainer.new()
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

	var rules := host.center_label(t("RIFT_RULES", "Uma entrada por dia · sem combustível · derrota mantém o inimigo atual e preserva o embalo dos mandados."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	rules.name = "ChallengeRulesNotice"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(rules)
	var entry_available := bool(status.entry_available)
	var enter_text := t("RIFT_START", "ENTRAR NA FENDA · INIMIGO %d/12", [floor + 1]) if entry_available else t("RIFT_ENTRY_USED", "ENTRADA USADA · REABRE ÀS 00:00 UTC")
	var enter := host.primary_action(enter_text, readiness_color if entry_available else host.MUTED)
	enter.name = "ChallengeEnterAction"
	enter.disabled = not entry_available
	var stage_id := str(stage.id)
	enter.pressed.connect(func(): state.start_challenge(stage_id))
	content.add_child(enter)


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_stage_field(stage: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_stage", str(stage.get("base_stage_id", stage.get("id", ""))), field), str(stage.get(field, "")))


static func localized_anomaly_field(anomaly_id: String, anomaly: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_anomaly", anomaly_id, field), str(anomaly.get(field, "")))
