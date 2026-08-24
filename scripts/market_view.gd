class_name MarketView
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("MERCADO TORTO", 25, host.INK))
	var subtitle := host.label("Equipamento planetário. Procedência opcional.", 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(112, 48)
	back.pressed.connect(func():
		host.call("open_frontier_menu")
	)
	title_row.add_child(back)

	var refresh_cost := MarketRulesScript.refresh_cost(state.player)
	var market_info := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 15, 12)
	content.add_child(market_info)
	var info_row := market_info.get_child(0) as HBoxContainer
	info_row.add_theme_constant_override("separation", 10)
	var info_copy := VBoxContainer.new()
	info_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_copy)
	info_copy.add_child(host.label("SALDO · ◈ %d CRÉDITOS" % int(state.player.credits), 14, host.GOLD))
	var explanation := host.label("Compras equipam melhorias automaticamente; alternativas vão para o inventário.", 11, host.MUTED)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_copy.add_child(explanation)
	var refresh := host.action_button("RENOVAR · ◈ %d" % refresh_cost, host.CYAN if int(state.player.credits) >= refresh_cost else host.MUTED, true)
	refresh.name = "MarketRefresh"
	refresh.custom_minimum_size = Vector2(128, 48)
	refresh.add_theme_font_size_override("font_size", 11)
	refresh.disabled = int(state.player.credits) < refresh_cost
	refresh.pressed.connect(state.refresh_market)
	info_row.add_child(refresh)

	var transport_goal := SpendingGuidanceScript.next_transport_goal(state.player)
	var alternative := host.panel(HBoxContainer.new(), Color("#173356"), 13, 10)
	alternative.name = "MarketTransportAlternative"
	var alternative_row := alternative.get_child(0) as HBoxContainer
	alternative_row.add_theme_constant_override("separation", 10)
	var alternative_copy := VBoxContainer.new()
	alternative_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alternative_row.add_child(alternative_copy)
	if transport_goal.is_empty():
		var complete_label := host.label("MOBILIDADE PERMANENTE · COLEÇÃO COMPLETA", 11, host.CYAN)
		complete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(complete_label)
		var optional_label := host.label("O mercado continua opcional para equipamento e coleção.", 10, host.MUTED)
		optional_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(optional_label)
	else:
		var unlocked := TransportRulesScript.is_unlocked(state.player, transport_goal)
		var goal_label := host.label("ALTERNATIVA PERMANENTE · %s" % str(transport_goal.name), 11, host.CYAN if unlocked else host.MUTED)
		goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(goal_label)
		var transport_copy := "-%d%% tempo de caça · ◈ %d" % [roundi(float(transport_goal.speed_bonus) * 100.0), int(transport_goal.price)]
		if not unlocked:
			transport_copy += " · após %d capítulos" % int(transport_goal.required_completed_planets)
		var detail_label := host.label(transport_copy, 10, host.MUTED)
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(detail_label)
	var hangar_action := host.action_button("VER HANGAR", host.CYAN, true)
	hangar_action.name = "MarketHangarAction"
	hangar_action.custom_minimum_size = Vector2(112, 48)
	hangar_action.add_theme_font_size_override("font_size", 10)
	hangar_action.pressed.connect(func():
		host.view_mode = "hangar"
		host.call("render")
	)
	alternative_row.add_child(hangar_action)
	content.add_child(alternative)

	if state.last_notice_context == "market" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#173356"), 12, 10)
		receipt.name = "MarketReceipt"
		var receipt_label := host.label(state.last_notice, 11, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_label)
		content.add_child(receipt)

	var scroller := ScrollContainer.new()
	scroller.name = "MarketScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroller.add_child(list)
	for offer in state.market_offers():
		list.add_child(offer_card(host, state, offer))


static func offer_card(host: CrookedUIFactory, state: StateScript, offer: Dictionary) -> PanelContainer:
	var item: Dictionary = offer.item
	var purchased := bool(offer.purchased)
	var affordable := int(state.player.credits) >= int(offer.price)
	var card := host.panel(HBoxContainer.new(), host.PANEL_LIGHT if not purchased else host.PANEL, 15, 12)
	card.name = "MarketOffer_%s" % str(offer.id)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	row.add_child(host.equipment_icon(item, 58))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var item_name := host.label(str(item.name), 15, host.MUTED if purchased else host.INK)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(item_name)
	copy.add_child(host.label("%s · %s · +%d PODER" % [str(item.rarity).to_upper(), host.slot_name(str(item.slot)).to_upper(), int(item.power)], 11, Color(str(item.color))))
	var description := host.label(str(item.description), 10, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	if item.has("trait"):
		var trait_label := host.label("◆ %s · %s" % [str(item.trait.name), str(item.trait.description)], 10, host.GOLD)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(trait_label)
	var comparison := EquipmentPresentation.equipment_delta_text(state.player, item)
	copy.add_child(host.label(comparison, 10, host.LIME if Rules.is_upgrade_for_player(state.player, item) else host.MUTED))

	var buy_text := "VENDIDO" if purchased else ("COMPRAR · ◈ %d" % int(offer.price) if affordable else "FALTAM ◈ %d" % (int(offer.price) - int(state.player.credits)))
	var buy := host.action_button(buy_text, host.MUTED if purchased or not affordable else host.GOLD, true)
	buy.name = "MarketBuy_%s" % str(offer.id)
	buy.custom_minimum_size = Vector2(116, 48)
	buy.add_theme_font_size_override("font_size", 10)
	buy.disabled = purchased or not affordable
	var offer_id := str(offer.id)
	buy.pressed.connect(func(): state.buy_market_offer(offer_id))
	row.add_child(buy)
	return card
