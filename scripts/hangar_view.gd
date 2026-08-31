class_name HangarView
extends RefCounted

const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")
const StateScript = preload("res://scripts/game_state.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	title_row.add_child(titles)
	titles.add_child(host.scene_title(t("HANGAR_TITLE", "HANGAR DUVIDOSO")))
	titles.add_child(host.readable_caption(t("HANGAR_SUBTITLE", "Transportes permanentes para chegar antes da desculpa.")))
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.name = "HangarBack"
	back.custom_minimum_size.x = 118
	back.pressed.connect(func():
		host.call("open_frontier_menu")
	)
	title_row.add_child(back)

	var active := TransportRulesScript.active_transport(state.player)
	var status := host.illustrated_panel(HBoxContainer.new(), 16)
	status.name = "HangarStatus"
	var status_row := host.illustrated_panel_content(status) as HBoxContainer
	status_row.add_theme_constant_override("separation", 14)
	var status_box := VBoxContainer.new()
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_box.add_theme_constant_override("separation", 5)
	if active.is_empty():
		status_box.add_child(host.label(t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO"), UIDesignSystem.FONT_BODY, host.GOLD))
		status_box.add_child(host.readable_caption(t("HANGAR_FULL_DURATION", "As viagens usam a duração interestelar completa.")))
	else:
		var active_icon := host.transport_icon(active, 82)
		active_icon.name = "HangarActiveTransportIcon"
		status_row.add_child(active_icon)
		status_box.add_child(host.label(t("HANGAR_ACTIVE", "ATIVO · %s", [localized_transport_field(active, "name")]), UIDesignSystem.FONT_BODY, Color(str(active.color))))
		status_box.add_child(host.readable_caption(t("HANGAR_ACTIVE_BONUS", "VIAGENS %d%% MAIS RÁPIDAS · perseguições e incidentes não recebem desconto", [roundi(float(active.speed_bonus) * 100.0)]), host.LIME))
	status_row.add_child(status_box)
	content.add_child(status)

	var market_summary := SpendingGuidanceScript.market_upgrade_summary(state.player, state.market_offers())
	var alternative := host.panel(HBoxContainer.new(), Color("#342b1c"), 16, 12)
	alternative.name = "HangarMarketAlternative"
	var alternative_row := alternative.get_child(0) as HBoxContainer
	alternative_row.add_theme_constant_override("separation", 10)
	var alternative_copy := VBoxContainer.new()
	alternative_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alternative_row.add_child(alternative_copy)
	if int(market_summary.count) > 0:
		var upgrade_label := host.label(t("HANGAR_COMBAT_ALTERNATIVE", "ALTERNATIVA DE COMBATE · %d MELHORIAS", [int(market_summary.count)]), UIDesignSystem.FONT_CAPTION, host.GOLD)
		upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(upgrade_label)
		var price_label := host.label(t("HANGAR_MARKET_PRICE", "Stock atual desde ◈ %d · equipamento imediato", [int(market_summary.cheapest_price)]), UIDesignSystem.FONT_CAPTION, host.MUTED)
		price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(price_label)
	else:
		var no_upgrade_label := host.label(t("HANGAR_NO_COMBAT_UPGRADE", "ALTERNATIVA DE COMBATE · SEM MELHORIA DIRETA"), UIDesignSystem.FONT_CAPTION, host.MUTED)
		no_upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(no_upgrade_label)
		var collection_label := host.label(t("HANGAR_COLLECTION_ONLY", "O stock atual serve apenas coleção; renovar é opcional."), UIDesignSystem.FONT_CAPTION, host.MUTED)
		collection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(collection_label)
	var market_action := host.secondary_action(t("HANGAR_VIEW_MARKET", "VER MERCADO"), host.GOLD)
	market_action.name = "HangarMarketAction"
	market_action.custom_minimum_size.x = 148
	market_action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	market_action.pressed.connect(func():
		host.view_mode = "market"
		host.call("render")
	)
	alternative_row.add_child(market_action)
	content.add_child(alternative)

	if state.last_notice_context == "hangar" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#16363b"), 15, 12)
		receipt.name = "HangarReceipt"
		var receipt_label := host.readable_caption(state.last_notice, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_label)
		content.add_child(receipt)

	if host.hangar_selected_transport_index < 0:
		host.hangar_selected_transport_index = transport_index_for(str(state.player.get("active_transport_id", "")))
	host.hangar_selected_transport_index = clampi(host.hangar_selected_transport_index, 0, maxi(0, TransportRulesScript.DEFINITIONS.size() - 1))
	var selectors := GridContainer.new()
	selectors.name = "HangarTransportSelectors"
	selectors.columns = 2
	selectors.add_theme_constant_override("h_separation", 8)
	selectors.add_theme_constant_override("v_separation", 8)
	content.add_child(selectors)
	for index in TransportRulesScript.DEFINITIONS.size():
		selectors.add_child(transport_selector(host, state, TransportRulesScript.DEFINITIONS[index], index, index == host.hangar_selected_transport_index))

	var scroller := TouchScrollContainer.new()
	scroller.name = "HangarScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)
	if not TransportRulesScript.DEFINITIONS.is_empty():
		list.add_child(transport_card(host, state, TransportRulesScript.DEFINITIONS[host.hangar_selected_transport_index]))


static func transport_selector(host: CrookedUIFactory, state: StateScript, transport: Dictionary, index: int, selected: bool) -> PanelContainer:
	var transport_id := str(transport.id)
	var owned := TransportRulesScript.is_owned(state.player, transport_id)
	var active := str(state.player.get("active_transport_id", "")) == transport_id
	# A transport legitimately owned by an older save must remain usable even if a
	# later balance pass raises its nominal unlock level.
	var unlocked := TransportRulesScript.is_unlocked(state.player, transport) or owned
	var accent := Color(str(transport.color)) if unlocked else host.MUTED
	var card := host.panel(VBoxContainer.new(), Color("#1f3159") if selected else host.PANEL, 6, 6)
	card.name = "HangarTransport_%s" % transport_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var state_text := t("HANGAR_ACTION_ACTIVE", "ATIVO") if active else (t("HANGAR_ACTION_EQUIP", "EQUIPAR") if owned else ("◈ %d" % int(transport.price) if unlocked else "N%d" % int(transport.required_level)))
	var action := host.secondary_action("-%d%% · %s" % [roundi(float(transport.speed_bonus) * 100.0), state_text], accent)
	action.name = "HangarSelect_%s" % transport_id
	action.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	action.disabled = selected
	action.pressed.connect(func():
		host.hangar_selected_transport_index = index
		host.hangar_scroll_position = 0
		host.call("render")
	)
	(card.get_child(0) as VBoxContainer).add_child(action)
	return card


static func transport_index_for(transport_id: String) -> int:
	for index in TransportRulesScript.DEFINITIONS.size():
		if str(TransportRulesScript.DEFINITIONS[index].id) == transport_id:
			return index
	return 0


static func transport_card(host: CrookedUIFactory, state: StateScript, transport: Dictionary) -> PanelContainer:
	var transport_id := str(transport.id)
	var owned := TransportRulesScript.is_owned(state.player, transport_id)
	var active := str(state.player.get("active_transport_id", "")) == transport_id
	# Ownership is permanent; never present an equipped legacy transport as locked.
	var unlocked := TransportRulesScript.is_unlocked(state.player, transport) or owned
	var affordable := int(state.player.credits) >= int(transport.price)
	var card := host.panel(VBoxContainer.new(), host.PANEL_LIGHT if unlocked else host.PANEL, 16, 14)
	card.name = "HangarSelectedTransport"
	var card_box := card.get_child(0) as VBoxContainer
	card_box.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card_box.add_child(row)
	var transport_icon := host.transport_icon(transport, 72)
	transport_icon.name = "HangarTransportIcon_%s" % transport_id
	row.add_child(transport_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var name_label := host.label(localized_transport_field(transport, "name"), UIDesignSystem.FONT_BODY, Color(str(transport.color)) if unlocked else host.MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(name_label)
	copy.add_child(host.label(t("HANGAR_PERMANENT_BONUS", "-%d%% TEMPO DE VIAGEM · PERMANENTE", [roundi(float(transport.speed_bonus) * 100.0)]), UIDesignSystem.FONT_CAPTION, host.GOLD if unlocked else host.MUTED))
	var tagline := host.label(localized_transport_field(transport, "tagline"), UIDesignSystem.FONT_CAPTION, host.INK if unlocked else host.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(tagline)
	if not unlocked:
		copy.add_child(host.label(t("HANGAR_UNLOCK_LEVEL", "DESBLOQUEIA NO NÍVEL %d", [int(transport.required_level)]), UIDesignSystem.FONT_CAPTION, host.MUTED))

	var action_text := t("HANGAR_ACTION_ACTIVE", "ATIVO") if active else (t("HANGAR_ACTION_EQUIP", "EQUIPAR") if owned else (t("HANGAR_ACTION_BUY", "COMPRAR · ◈ %d", [int(transport.price)]) if affordable else t("MARKET_MISSING_CREDITS", "FALTAM ◈ %d", [int(transport.price) - int(state.player.credits)])))
	if not unlocked:
		action_text = t("GALAXY_LOCKED", "BLOQUEADO")
	var enabled := unlocked and not active and (owned or affordable)
	var action := host.secondary_action(action_text, Color(str(transport.color)) if enabled else host.MUTED)
	action.name = "HangarAction_%s" % transport_id
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.disabled = not enabled
	action.pressed.connect(func(): state.acquire_or_equip_transport(transport_id))
	card_box.add_child(action)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_transport_field(transport: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("transport", str(transport.get("id", "")), field), str(transport.get(field, "")))
