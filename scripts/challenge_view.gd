class_name ChallengeView
extends RefCounted

const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: CrookedGameState) -> void:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	content.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(host.label("FENDA CLANDESTINA", 24, host.INK))
	var subtitle := host.label("Uma escada de inimigos fora da campanha planetária.", 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_copy.add_child(subtitle)
	var marker := host.metric_chip("SETOR", "NULO", host.CORAL)
	marker.name = "ChallengeMarker"
	heading.add_child(marker)

	if not ChallengeRulesScript.is_unlocked(state.player):
		var locked := host.panel(VBoxContainer.new(), Color("#20182f"), 20, 18)
		locked.name = "ChallengeLockedPanel"
		var locked_box := locked.get_child(0) as VBoxContainer
		locked_box.add_theme_constant_override("separation", 9)
		locked_box.add_child(host.center_label("SINAL CRIPTOGRAFADO", 13, host.CORAL))
		locked_box.add_child(host.center_label("FENDA AINDA INACESSÍVEL", 24, host.INK))
		var requirement := host.center_label("Conclua Dustball Prime para localizar a entrada e abrir a primeira incursão.", 14, host.MUTED)
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
		var chip := host.metric_chip("ANDAR", value, color)
		chip.name = "ChallengeFloor_%d" % (index + 1)
		track.add_child(chip)

	if floor >= ChallengeRulesScript.STAGES.size():
		var complete := host.panel(VBoxContainer.new(), Color("#173f3c"), 22, 20)
		complete.name = "ChallengeCompletePanel"
		var complete_box := complete.get_child(0) as VBoxContainer
		complete_box.add_child(host.center_label("ARQUIVO IMPOSSÍVEL ENCERRADO", 15, host.LIME))
		complete_box.add_child(host.center_label("FENDA LIMPA", 30, host.INK))
		var complete_copy := host.center_label("Os seis carcereiros foram removidos. Cinto técnico e implante permanecem universais para todas as classes.", 14, host.MUTED)
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
	content.add_child(scroller)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	scroller.add_child(stack)
	var dossier := host.panel(HBoxContainer.new(), Color("#17182fe8"), 16, 14)
	dossier.name = "ChallengeCurrentDossier"
	stack.add_child(dossier)
	var row := dossier.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 13)
	row.add_child(host.character_portrait(str(stage.id), 112))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(stage.title), 11, host.CORAL))
	copy.add_child(host.label(str(stage.name), 21, host.INK))
	var description := host.label(str(stage.description), 13, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)

	var odds := Rules.bounty_odds(state.player, stage)
	var readiness_color := host.LIME if odds >= 0.65 else (host.GOLD if odds >= 0.45 else host.CORAL)
	var metrics := HBoxContainer.new()
	metrics.name = "ChallengeMetrics"
	metrics.add_theme_constant_override("separation", 7)
	stack.add_child(metrics)
	metrics.add_child(host.metric_chip("CHANCE", "%d%%" % roundi(odds * 100.0), readiness_color))
	metrics.add_child(host.metric_chip("PODER", str(int(stage.power)), host.CORAL))
	metrics.add_child(host.metric_chip("VIDA", str(int(stage.health)), host.CYAN))
	var anomaly: Dictionary = stage.anomaly
	var anomaly_panel := host.panel(VBoxContainer.new(), Color("#26172f"), 12, 10)
	anomaly_panel.name = "ChallengeAnomalyRule"
	var anomaly_copy := anomaly_panel.get_child(0) as VBoxContainer
	anomaly_copy.add_child(host.center_label("ANOMALIA · %s · TESTE DE %s" % [str(anomaly.name), str(anomaly.favored_axis)], 11, host.CORAL))
	var anomaly_description := host.center_label(str(anomaly.description), 11, host.INK)
	anomaly_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anomaly_copy.add_child(anomaly_description)
	anomaly_copy.add_child(host.center_label("MITIGAÇÃO IGNORADA %d%% · ABERTURA ×%.1f" % [roundi(float(stage.damage_reduction_piercing) * 100.0), float(stage.opening_damage_multiplier)], 10, host.MUTED))
	stack.add_child(anomaly_panel)

	var reward := ChallengeRulesScript.reward_for(stage, ContentDB.ITEM_TRAITS)
	var reward_panel := host.panel(HBoxContainer.new(), Color("#10233b"), 13, 11)
	reward_panel.name = "ChallengeRewardPreview"
	var reward_row := reward_panel.get_child(0) as HBoxContainer
	reward_row.add_theme_constant_override("separation", 10)
	reward_row.add_child(host.equipment_icon(reward, 62))
	var reward_copy := VBoxContainer.new()
	reward_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_child(reward_copy)
	reward_copy.add_child(host.label("RECOMPENSA ÚNICA · %s" % host.slot_name(str(reward.slot)).to_upper(), 10, host.GOLD))
	reward_copy.add_child(host.label(str(reward.name), 16, host.INK))
	if reward.has("trait"):
		var effect := host.label("◆ %s · %s" % [str(reward.trait.name), str(reward.trait.description)], 11, host.LIME)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_copy.add_child(effect)
	reward_copy.add_child(host.label("◈ %d CRÉDITOS · %d XP" % [int(stage.credits), int(stage.xp)], 11, host.GOLD))
	stack.add_child(reward_panel)

	var rules := host.center_label("Sem caça, incidentes ou repetição. Derrota não consome o embalo dos mandados.", 11, host.MUTED)
	rules.name = "ChallengeRulesNotice"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(rules)
	var enter := host.action_button("INICIAR INCURSÃO · ANDAR %d" % (floor + 1), readiness_color)
	enter.name = "ChallengeEnterAction"
	enter.custom_minimum_size = Vector2(0, 52)
	var stage_id := str(stage.id)
	enter.pressed.connect(func(): state.start_challenge(stage_id))
	stack.add_child(enter)
