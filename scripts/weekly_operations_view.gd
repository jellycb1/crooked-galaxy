class_name WeeklyOperationsView
extends RefCounted

const StateScript = preload("res://scripts/game_state.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const ContentDB = preload("res://scripts/content_db.gd")


static func build_content(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var scroller := ScrollContainer.new()
	scroller.name = "DailyObjectivesScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)

	var objectives := state.weekly_objectives()
	var claimed_count := objectives.filter(func(entry): return bool(entry.claimed)).size()
	var summary := host.panel(VBoxContainer.new(), Color("#173356"), 15, 12)
	var summary_box := summary.get_child(0) as VBoxContainer
	summary_box.add_child(host.label(t("WEEKLY_PROGRESS", "SEMANA · %d CONTRATOS · %d/%d RESGATADOS", [int(state.player.get("weekly_hunts_completed", 0)), claimed_count, objectives.size()]), UIDesignSystem.FONT_BODY, host.GOLD))
	var policy := host.label(t("WEEKLY_POLICY", "Reinício segunda-feira às 00:00 UTC. Fenda e compras não contam; o estado deste APK é local."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	policy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_box.add_child(policy)
	list.add_child(summary)

	if state.last_notice_context == "weekly" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#173f48"), 12, 10)
		var receipt_label := host.label(str(state.last_notice), UIDesignSystem.FONT_CAPTION, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_label)
		list.add_child(receipt)

	list.add_child(special_card(host, state))
	var ready := state.weekly_rewards_ready()
	if ready > 0:
		var claim_all := host.primary_action(t("WEEKLY_CLAIM_ALL", "RESGATAR SEMANA · %d", [ready]), host.LIME)
		claim_all.name = "ClaimAllWeeklyObjectives"
		claim_all.pressed.connect(func(): state.claim_all_weekly_objectives())
		list.add_child(claim_all)
	for objective in objectives:
		list.add_child(objective_card(host, state, objective))
	scroller.get_v_scroll_bar().value_changed.connect(func(value: float): host.daily_scroll_position = roundi(value))


static func special_card(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var status := state.weekly_special_status()
	var completed := bool(status.completed)
	var target: Dictionary = status.target
	var contract: Dictionary = status.contract
	var card := host.panel(VBoxContainer.new(), Color("#35182a") if not completed else Color("#12332f"), 15, 13)
	card.name = "WeeklySpecialCard"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	box.add_child(host.label(t("WEEKLY_SPECIAL_KICKER", "MANDADO NEGRO · UMA VEZ POR SEMANA"), UIDesignSystem.FONT_CAPTION, host.CORAL if not completed else host.LIME))
	if target.is_empty() or contract.is_empty():
		var unavailable := host.label(t("WEEKLY_SPECIAL_UNAVAILABLE", "Nenhum criminoso de elite disponível nesta faixa de nível."), UIDesignSystem.FONT_BODY, host.MUTED)
		unavailable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(unavailable)
		return card
	var target_name := state.localized_content_field("target", target, "name")
	var planet := ContentDB.get_planet(str(target.get("planet_id", "")))
	var planet_name := state.localized_content_field("planet", planet, "name")
	var title := host.label(target_name.to_upper(), UIDesignSystem.FONT_SECTION_TITLE, host.LIME if completed else host.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var route := host.label(t("WEEKLY_SPECIAL_ROUTE", "%s · %d COMBUSTÍVEL · %d CRÉDITOS · %d SUCATA", [planet_name.to_upper(), int(contract.get("fuel_cost", 0)), int(contract.get("credits", 0)), int(contract.get("scrap_reward", 0))]), UIDesignSystem.FONT_CAPTION, host.MUTED)
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(route)
	var explanation := host.label(t("WEEKLY_SPECIAL_RULE", "Um alvo de elite rotativo, mais resistente e com pagamento reforçado. Usa a mesma caçada e o combustível normal."), UIDesignSystem.FONT_CAPTION, host.INK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)
	var action := host.primary_action(t("WEEKLY_SPECIAL_COMPLETE", "MANDADO CONCLUÍDO") if completed else t("WEEKLY_SPECIAL_START", "ANALISAR MANDADO"), host.LIME if completed else host.CORAL)
	action.name = "WeeklySpecialAction"
	action.disabled = completed or state.phase != StateScript.Phase.BOARD
	action.pressed.connect(func(): state.start_weekly_special())
	box.add_child(action)
	return card


static func objective_card(host: CrookedUIFactory, state: StateScript, objective: Dictionary) -> PanelContainer:
	var complete := bool(objective.complete)
	var claimed := bool(objective.claimed)
	var card := host.panel(VBoxContainer.new(), Color("#10233b") if not claimed else Color("#12332f"), 14, 12)
	card.name = "WeeklyObjective_%s" % str(objective.id)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var name_label := host.label(("✓ " if claimed else ("! " if complete else "· ")) + str(objective.name), UIDesignSystem.FONT_BODY, host.LIME if claimed else (host.GOLD if complete else host.INK))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)
	box.add_child(host.label(t("WEEKLY_OBJECTIVE_PROGRESS", "%d/%d CONTRATOS", [int(objective.progress), int(objective.goal)]), UIDesignSystem.FONT_CAPTION, host.CYAN if complete else host.MUTED))
	var reward_parts: Array[String] = []
	if int(objective.credits) > 0:
		reward_parts.append("◈ %d" % int(objective.credits))
	if int(objective.scrap) > 0:
		reward_parts.append(t("DAILY_REWARD_SCRAP", "%d SUCATA", [int(objective.scrap)]))
	box.add_child(host.label(t("DAILY_REWARD", "PAGAMENTO · %s", [" · ".join(reward_parts)]), UIDesignSystem.FONT_CAPTION, host.LIME if claimed else host.GOLD))
	if complete and not claimed:
		var claim := host.secondary_action(t("ACTION_CLAIM", "RESGATAR"), host.GOLD)
		claim.name = "ClaimWeekly_%s" % str(objective.id)
		var objective_id := str(objective.id)
		claim.pressed.connect(func(): state.claim_weekly_objective(objective_id))
		box.add_child(claim)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)
