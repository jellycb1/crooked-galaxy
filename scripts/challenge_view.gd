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
	heading_copy.add_child(host.readable_caption(t("RIFT_SUBTITLE", "Uma escada de inimigos fora da campanha planetária.")))
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.name = "ChallengeBack"
	back.custom_minimum_size.x = 118
	back.pressed.connect(func(): host.call("open_frontier_menu"))
	heading.add_child(back)
	var marker := host.metric_chip(t("RIFT_SECTOR", "SETOR"), t("RIFT_NULL", "NULO"), host.CORAL)
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
		var requirement := host.center_label(t("RIFT_UNLOCK_REQUIREMENT", "Conclua Dustball Prime para localizar a entrada e abrir a primeira incursão."), UIDesignSystem.FONT_BODY, host.MUTED)
		requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked_box.add_child(requirement)
		content.add_child(locked)
		return

	var floor := ChallengeRulesScript.progress(state.player)
	var track := HBoxContainer.new()
	track.name = "ChallengeProgressTrack"
	track.add_theme_constant_override("separation", 5)
	content.add_child(track)
	for index in ChallengeRulesScript.STAGES.size():
		var cleared := index < floor
		var current := index == floor
		var color := host.LIME if cleared else (host.GOLD if current else host.MUTED)
		var value := "✓" if cleared else str(index + 1)
		var chip := host.metric_chip(t("RIFT_FLOOR", "ANDAR"), value, color)
		chip.name = "ChallengeFloor_%d" % (index + 1)
		track.add_child(chip)

	if floor >= ChallengeRulesScript.STAGES.size():
		var complete := host.illustrated_panel(VBoxContainer.new(), 20)
		complete.name = "ChallengeCompletePanel"
		var complete_box := complete.get_child(0) as VBoxContainer
		complete_box.add_child(host.center_label(t("RIFT_ARCHIVE_CLOSED", "ARQUIVO IMPOSSÍVEL ENCERRADO"), UIDesignSystem.FONT_CAPTION, host.LIME))
		complete_box.add_child(host.center_label(t("RIFT_CLEARED", "FENDA LIMPA"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
		var complete_copy := host.center_label(t("RIFT_COMPLETE_DESCRIPTION", "Os seis carcereiros foram removidos. Cinto técnico e implante permanecem universais para todas as classes."), UIDesignSystem.FONT_CAPTION, host.MUTED)
		complete_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete_box.add_child(complete_copy)
		content.add_child(complete)
		return

	if not state.last_notice.is_empty() and state.last_notice_context.begins_with("challenge_"):
		var notice_color := host.CORAL if state.last_notice_context == "challenge_defeat" else host.LIME
		var notice: PanelContainer = host.notice_banner(state.last_notice, notice_color)
		notice.name = "ChallengeNotice"
		content.add_child(notice)

	var stage := ChallengeRulesScript.current_stage(state.player)
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

	var reward := ChallengeRulesScript.reward_for(stage, ContentDB.ITEM_TRAITS)
	var reward_panel := host.panel(HBoxContainer.new(), Color("#10233b"), 16, 14)
	reward_panel.name = "ChallengeRewardPreview"
	var reward_row := reward_panel.get_child(0) as HBoxContainer
	reward_row.add_theme_constant_override("separation", 10)
	reward_row.add_child(host.equipment_icon(reward, 72))
	var reward_copy := VBoxContainer.new()
	reward_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_child(reward_copy)
	reward_copy.add_child(host.label(t("RIFT_UNIQUE_REWARD", "RECOMPENSA ÚNICA · %s", [EquipmentPresentation.localized_slot(str(reward.slot)).to_upper()]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var reward_name := host.label(EquipmentPresentation.localized_item_field(reward, "name"), UIDesignSystem.FONT_BODY, host.INK)
	reward_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_name.max_lines_visible = 2
	reward_copy.add_child(reward_name)
	if reward.has("trait"):
		var effect := host.label("◆ %s · %s" % [EquipmentPresentation.localized_trait_field(reward.trait, "name"), EquipmentPresentation.localized_trait_field(reward.trait, "description")], UIDesignSystem.FONT_CAPTION, host.LIME)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_copy.add_child(effect)
	reward_copy.add_child(host.label(t("RIFT_REWARD_TOTAL", "◈ %d CRÉDITOS · %d XP", [int(stage.credits), int(stage.xp)]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	stack.add_child(reward_panel)

	var rules := host.center_label(t("RIFT_RULES", "Sem caça, incidentes ou repetição. Derrota não consome o embalo dos mandados."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	rules.name = "ChallengeRulesNotice"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(rules)
	var enter := host.primary_action(t("RIFT_START", "INICIAR INCURSÃO · ANDAR %d", [floor + 1]), readiness_color)
	enter.name = "ChallengeEnterAction"
	var stage_id := str(stage.id)
	enter.pressed.connect(func(): state.start_challenge(stage_id))
	content.add_child(enter)


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_stage_field(stage: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_stage", str(stage.get("id", "")), field), str(stage.get(field, "")))


static func localized_anomaly_field(anomaly_id: String, anomaly: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("rift_anomaly", anomaly_id, field), str(anomaly.get(field, "")))
