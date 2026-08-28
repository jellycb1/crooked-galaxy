class_name MarketView
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const MonetizationRulesScript = preload("res://scripts/monetization_rules.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	title_row.add_child(titles)
	titles.add_child(host.scene_title(t("MARKET_TITLE", "MERCADO TORTO")))
	titles.add_child(host.readable_caption(t("MARKET_SUBTITLE", "Arma, traje e achado lateral do planeta.")))
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func():
		host.market_refresh_confirmation = false
		host.call("open_frontier_menu")
	)
	title_row.add_child(back)

	var refresh_cost := MarketRulesScript.refresh_cost(state.player)
	var market_info := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 14)
	content.add_child(market_info)
	var info_row := market_info.get_child(0) as HBoxContainer
	info_row.add_theme_constant_override("separation", 14)
	var info_copy := VBoxContainer.new()
	info_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_copy)
	info_copy.add_child(host.label(t("MARKET_BALANCE", "SALDO · ◈ %d CRÉDITOS · ◆ %d FICHAS", [int(state.player.credits), int(state.player.get("warp_chips", 0))]), UIDesignSystem.FONT_BODY, host.GOLD))
	var daily_source_key := "MARKET_DAILY_FREE_READY" if MonetizationRulesScript.first_hunt_chip_available(state.player) else "MARKET_DAILY_FREE_CLAIMED"
	var daily_source_fallback := "FONTE JOGÁVEL · primeira missão de hoje: +1 Ficha" if MonetizationRulesScript.first_hunt_chip_available(state.player) else "FONTE JOGÁVEL · recompensa diária recolhida"
	var daily_source := host.label(t(daily_source_key, daily_source_fallback) + t("MARKET_DAILY_RESET", " · reinício 00:00 UTC"), UIDesignSystem.FONT_CAPTION, host.LIME if MonetizationRulesScript.first_hunt_chip_available(state.player) else host.MUTED)
	daily_source.name = "MarketDailyChipStatus"
	daily_source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_copy.add_child(daily_source)
	var refresh_available := MonetizationRulesScript.can_refresh_market(state.player)
	var can_afford_refresh := refresh_available and int(state.player.get("warp_chips", 0)) >= refresh_cost
	var refresh_text := t("MARKET_REFRESH", "RENOVAR · ◆ %d · %d/3", [refresh_cost, MonetizationRulesScript.market_refresh_count(state.player) + 1]) if refresh_available else t("MARKET_REFRESH_LIMIT", "RENOVAÇÕES ESGOTADAS · 00:00 UTC")
	var refresh := host.secondary_action(refresh_text, host.CYAN if can_afford_refresh else host.MUTED)
	refresh.name = "MarketRefresh"
	refresh.custom_minimum_size.x = 142
	refresh.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	refresh.disabled = not can_afford_refresh
	refresh.pressed.connect(func():
		host.market_refresh_confirmation = true
		host.call("render")
	)
	info_row.add_child(refresh)
	if host.market_refresh_confirmation and can_afford_refresh:
		content.add_child(refresh_confirmation_panel(host, state, refresh_cost))

	var transport_goal := SpendingGuidanceScript.next_transport_goal(state.player)
	var alternative := host.panel(HBoxContainer.new(), Color("#173356"), 16, 12)
	alternative.name = "MarketTransportAlternative"
	var alternative_row := alternative.get_child(0) as HBoxContainer
	alternative_row.add_theme_constant_override("separation", 10)
	var alternative_copy := VBoxContainer.new()
	alternative_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alternative_row.add_child(alternative_copy)
	if transport_goal.is_empty():
		var complete_label := host.label(t("MARKET_TRANSPORT_COMPLETE", "MOBILIDADE PERMANENTE · COLEÇÃO COMPLETA"), UIDesignSystem.FONT_CAPTION, host.CYAN)
		complete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(complete_label)
		var optional_label := host.label(t("MARKET_OPTIONAL", "O mercado continua opcional para equipamento e coleção."), UIDesignSystem.FONT_CAPTION, host.MUTED)
		optional_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(optional_label)
	else:
		var unlocked := TransportRulesScript.is_unlocked(state.player, transport_goal)
		var goal_label := host.label(t("MARKET_TRANSPORT_ALTERNATIVE", "ALTERNATIVA PERMANENTE · %s", [localized_transport_field(transport_goal, "name")]), UIDesignSystem.FONT_CAPTION, host.CYAN if unlocked else host.MUTED)
		goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(goal_label)
		var transport_copy := t("MARKET_TRANSPORT_DETAIL", "-%d%% tempo de caça · ◈ %d", [roundi(float(transport_goal.speed_bonus) * 100.0), int(transport_goal.price)])
		if not unlocked:
			transport_copy += t("MARKET_TRANSPORT_LEVEL_LOCK", " · nível %d", [int(transport_goal.required_level)])
		var detail_label := host.label(transport_copy, UIDesignSystem.FONT_CAPTION, host.MUTED)
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(detail_label)
	var hangar_action := host.secondary_action(t("MARKET_VIEW_HANGAR", "VER HANGAR"), host.CYAN)
	hangar_action.name = "MarketHangarAction"
	hangar_action.custom_minimum_size.x = 132
	hangar_action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	hangar_action.pressed.connect(func():
		host.market_refresh_confirmation = false
		host.view_mode = "hangar"
		host.call("render")
	)
	alternative_row.add_child(hangar_action)
	content.add_child(alternative)

	if state.last_notice_context == "market" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#173356"), 15, 12)
		receipt.name = "MarketReceipt"
		var receipt_label := host.readable_caption(state.last_notice, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_label)
		content.add_child(receipt)

	var offers := state.market_offers()
	host.market_selected_offer_index = clampi(host.market_selected_offer_index, 0, maxi(0, offers.size() - 1))
	var selectors := HBoxContainer.new()
	selectors.name = "MarketOfferSelectors"
	selectors.add_theme_constant_override("separation", 8)
	content.add_child(selectors)
	for index in offers.size():
		selectors.add_child(offer_selector(host, offers[index], index, index == host.market_selected_offer_index))

	var scroller := ScrollContainer.new()
	scroller.name = "MarketScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)
	if not offers.is_empty():
		list.add_child(offer_card(host, state, offers[host.market_selected_offer_index]))


static func offer_selector(host: CrookedUIFactory, offer: Dictionary, index: int, selected: bool) -> PanelContainer:
	var item: Dictionary = offer.item
	var purchased := bool(offer.purchased)
	var accent := host.GOLD if selected else (host.MUTED if purchased else Color(str(item.color)))
	var card := host.panel(VBoxContainer.new(), Color("#1f3159") if selected else host.PANEL, 6, 6)
	card.name = "MarketOffer_%s" % str(offer.id)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var action := host.secondary_action("%s\n+%d · ◈ %d" % [EquipmentPresentation.localized_slot(str(item.slot)).to_upper(), int(item.power), int(offer.price)], accent)
	action.name = "MarketSelect_%s" % str(offer.id)
	action.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	action.disabled = selected
	action.pressed.connect(func():
		host.market_selected_offer_index = index
		host.market_scroll_position = 0
		host.call("render")
	)
	(card.get_child(0) as VBoxContainer).add_child(action)
	return card


static func offer_card(host: CrookedUIFactory, state: StateScript, offer: Dictionary) -> PanelContainer:
	var item: Dictionary = offer.item
	var purchased := bool(offer.purchased)
	var affordable := int(state.player.credits) >= int(offer.price)
	var card := host.panel(VBoxContainer.new(), host.PANEL_LIGHT if not purchased else host.PANEL, 16, 14)
	card.name = "MarketSelectedOffer"
	var card_box := card.get_child(0) as VBoxContainer
	card_box.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card_box.add_child(row)
	row.add_child(host.equipment_icon(item, 72))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var item_name := host.label(EquipmentPresentation.localized_item_field(item, "name"), UIDesignSystem.FONT_BODY, host.MUTED if purchased else host.INK)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(item_name)
	copy.add_child(host.label(t("MARKET_ITEM_POWER", "%s · %s · +%d PODER", [EquipmentPresentation.localized_rarity(str(item.rarity)), EquipmentPresentation.localized_slot(str(item.slot)).to_upper(), int(item.power)]), UIDesignSystem.FONT_CAPTION, Color(str(item.color))))
	var procedural_identity := EquipmentPresentation.procedural_identity_text(item)
	if not procedural_identity.is_empty():
		copy.add_child(host.label(procedural_identity, UIDesignSystem.FONT_CAPTION, host.CYAN))
	var collection_state := EquipmentPresentation.collection_state(state.player, item)
	if not collection_state.is_empty():
		var collection_label := host.label(t("ITEM_COLLECTION_MARKET_NEW", "★ NOVA SÉRIE") if collection_state == "new" else t("ITEM_COLLECTION_PREVIEW_REGISTERED", "✓ SÉRIE JÁ REGISTADA"), UIDesignSystem.FONT_CAPTION, host.GOLD if collection_state == "new" else host.MUTED)
		collection_label.name = "MarketCollectionStatus_%s" % str(offer.id)
		copy.add_child(collection_label)
	var description := host.label(EquipmentPresentation.localized_item_field(item, "description"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	var modifier_text := EquipmentPresentation.modifier_text(item)
	if not modifier_text.is_empty():
		var trait_label := host.label("◆ %s" % modifier_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(trait_label)
	var comparison := EquipmentPresentation.equipment_delta_text(state.player, item)
	var comparison_label := host.label(comparison, UIDesignSystem.FONT_CAPTION, host.LIME if Rules.is_upgrade_for_player(state.player, item) else host.MUTED)
	comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(comparison_label)

	var buy_text := t("MARKET_SOLD", "VENDIDO") if purchased else (t("MARKET_BUY", "COMPRAR · ◈ %d", [int(offer.price)]) if affordable else t("MARKET_MISSING_CREDITS", "FALTAM ◈ %d", [int(offer.price) - int(state.player.credits)]))
	var buy := host.secondary_action(buy_text, host.MUTED if purchased or not affordable else host.GOLD)
	buy.name = "MarketBuy_%s" % str(offer.id)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	buy.disabled = purchased or not affordable
	var offer_id := str(offer.id)
	buy.pressed.connect(func(): state.buy_market_offer(offer_id))
	card_box.add_child(buy)
	return card


static func refresh_confirmation_panel(host: CrookedUIFactory, state: StateScript, refresh_cost: int) -> PanelContainer:
	var panel := host.panel(VBoxContainer.new(), Color("#382344"), 15, 12)
	panel.name = "MarketRefreshConfirmation"
	var box := panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 9)
	var warning := host.label(t("MARKET_REFRESH_CONFIRMATION", "CONFIRMAR RENOVAÇÃO · gastar ◆ %d remove estas três ofertas e gera uma nova seleção.", [refresh_cost]), UIDesignSystem.FONT_CAPTION, host.INK)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var cancel := host.secondary_action(t("ACTION_CANCEL", "CANCELAR"), host.MUTED)
	cancel.name = "MarketRefreshCancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func():
		host.market_refresh_confirmation = false
		host.call("render")
	)
	actions.add_child(cancel)
	var confirm := host.primary_action(t("MARKET_REFRESH_CONFIRM", "CONFIRMAR · ◆ %d", [refresh_cost]), host.CYAN)
	confirm.name = "MarketRefreshConfirm"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(func():
		host.market_refresh_confirmation = false
		host.market_selected_offer_index = 0
		host.reset_session_scroll("MarketScroll", "market_scroll_position")
		state.refresh_market()
	)
	actions.add_child(confirm)
	return panel


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_transport_field(transport: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key("transport", str(transport.get("id", "")), field), str(transport.get(field, "")))
