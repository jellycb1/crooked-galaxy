class_name DailyObjectivesView
extends RefCounted

const StateScript = preload("res://scripts/game_state.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const WeeklyOperationsViewScript = preload("res://scripts/weekly_operations_view.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.scene_title(t("OPERATIONS_TITLE", "OPERAÇÕES")))
	var subtitle := host.readable_caption(t("OPERATIONS_SUBTITLE", "Rotinas da rede, pagamentos e mandados especiais."))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func(): host.call("open_frontier_menu"))
	title_row.add_child(back)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	var daily_tab := host.secondary_action(t("OPERATIONS_DAILY_TAB", "DIÁRIO"), host.GOLD if host.operations_section == "daily" else host.MUTED)
	daily_tab.name = "OperationsDailyTab"
	daily_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_tab.pressed.connect(func():
		host.operations_section = "daily"
		host.daily_scroll_position = 0
		host.render()
	)
	tabs.add_child(daily_tab)
	var weekly_tab := host.secondary_action(t("OPERATIONS_WEEKLY_TAB", "SEMANAL"), host.CORAL if host.operations_section == "weekly" else host.MUTED)
	weekly_tab.name = "OperationsWeeklyTab"
	weekly_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weekly_tab.pressed.connect(func():
		host.operations_section = "weekly"
		host.daily_scroll_position = 0
		host.render()
	)
	tabs.add_child(weekly_tab)
	if host.operations_section == "weekly":
		WeeklyOperationsViewScript.build_content(host, content, state)
		return

	var scroller := TouchScrollContainer.new()
	scroller.name = "DailyObjectivesScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)

	var objectives := state.daily_objectives()
	var claimed_count := objectives.filter(func(entry): return bool(entry.claimed)).size()
	var summary := host.panel(VBoxContainer.new(), Color("#173356"), 15, 12)
	summary.name = "DailyObjectivesSummary"
	var summary_box := summary.get_child(0) as VBoxContainer
	summary_box.add_child(host.label(t("DAILY_PROGRESS", "TURNO · %d CONTRATOS · %d/%d RESGATADOS", [int(state.player.get("daily_hunts_completed", 0)), claimed_count, objectives.size()]), UIDesignSystem.FONT_BODY, host.GOLD))
	var policy := host.label(t("DAILY_POLICY", "Objetivos usam apenas caçadas concluídas; Fenda e compras não contam. O estado deste APK é local."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	policy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_box.add_child(policy)
	list.add_child(summary)
	if state.last_notice_context == "daily" and not state.last_notice.is_empty():
		var receipt := host.success_receipt_panel(VBoxContainer.new(), 22)
		receipt.name = "DailyClaimReceipt"
		var receipt_label := host.label(str(state.last_notice), UIDesignSystem.FONT_CAPTION, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(host.success_receipt_content(receipt) as VBoxContainer).add_child(receipt_label)
		list.add_child(receipt)
	var ready := state.daily_rewards_ready()
	if ready > 0:
		var claim_all := host.primary_action(t("DAILY_CLAIM_ALL", "RESGATAR TURNO · %d", [ready]), host.LIME)
		claim_all.name = "ClaimAllDailyObjectives"
		claim_all.pressed.connect(func(): state.claim_all_daily_objectives())
		list.add_child(claim_all)
	for objective in objectives:
		list.add_child(objective_card(host, state, objective))
	scroller.get_v_scroll_bar().value_changed.connect(func(value: float): host.daily_scroll_position = roundi(value))


static func objective_card(host: CrookedUIFactory, state: StateScript, objective: Dictionary) -> PanelContainer:
	var complete := bool(objective.complete)
	var claimed := bool(objective.claimed)
	var card := host.panel(VBoxContainer.new(), Color("#10233b") if not claimed else Color("#12332f"), 14, 12)
	card.name = "DailyObjective_%s" % str(objective.id)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	box.add_child(heading)
	var status := host.center_label("✓" if claimed else ("!" if complete else "·"), UIDesignSystem.FONT_BODY, host.LIME if claimed else (host.GOLD if complete else host.MUTED))
	status.custom_minimum_size = Vector2(30, 30)
	heading.add_child(status)
	var name_label := host.label(str(objective.name), UIDesignSystem.FONT_BODY, host.LIME if claimed else (host.GOLD if complete else host.INK))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(name_label)
	var progress := host.label(t("DAILY_OBJECTIVE_PROGRESS", "%d/%d CONTRATOS", [int(objective.progress), int(objective.goal)]), UIDesignSystem.FONT_CAPTION, host.CYAN if complete else host.MUTED)
	progress.name = "DailyObjectiveProgress_%s" % str(objective.id)
	box.add_child(progress)
	var reward_parts: Array[String] = []
	if int(objective.credits) > 0:
		reward_parts.append("◈ %d" % int(objective.credits))
	if int(objective.scrap) > 0:
		reward_parts.append(t("DAILY_REWARD_SCRAP", "%d SUCATA", [int(objective.scrap)]))
	box.add_child(host.label(t("DAILY_REWARD", "PAGAMENTO · %s", [" · ".join(reward_parts)]), UIDesignSystem.FONT_CAPTION, host.LIME if claimed else host.GOLD))
	if complete and not claimed:
		var claim := host.secondary_action(t("ACTION_CLAIM", "RESGATAR"), host.GOLD)
		claim.name = "ClaimDaily_%s" % str(objective.id)
		var objective_id := str(objective.id)
		claim.pressed.connect(func(): state.claim_daily_objective(objective_id))
		box.add_child(claim)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)
