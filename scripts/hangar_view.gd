class_name HangarView
extends RefCounted

const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("HANGAR DUVIDOSO", 25, host.INK))
	var subtitle := host.label("Transportes permanentes para chegar antes da desculpa.", 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.name = "HangarBack"
	back.custom_minimum_size = Vector2(112, 48)
	back.pressed.connect(func():
		host.call("open_frontier_menu")
	)
	title_row.add_child(back)

	var active := TransportRulesScript.active_transport(state.player)
	var status := host.panel(VBoxContainer.new(), Color("#173356"), 15, 12)
	status.name = "HangarStatus"
	var status_box := status.get_child(0) as VBoxContainer
	if active.is_empty():
		status_box.add_child(host.label("SEM TRANSPORTE ATIVO", 14, host.GOLD))
		status_box.add_child(host.label("As caçadas usam a duração completa da abordagem.", 11, host.MUTED))
	else:
		status_box.add_child(host.label("ATIVO · %s" % str(active.name), 14, Color(str(active.color))))
		status_box.add_child(host.label("CAÇADAS %d%% MAIS RÁPIDAS · atrasos de incidentes não recebem desconto" % roundi(float(active.speed_bonus) * 100.0), 11, host.LIME))
	content.add_child(status)

	var market_summary := SpendingGuidanceScript.market_upgrade_summary(state.player, state.market_offers())
	var alternative := host.panel(HBoxContainer.new(), Color("#342b1c"), 13, 10)
	alternative.name = "HangarMarketAlternative"
	var alternative_row := alternative.get_child(0) as HBoxContainer
	alternative_row.add_theme_constant_override("separation", 10)
	var alternative_copy := VBoxContainer.new()
	alternative_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alternative_row.add_child(alternative_copy)
	if int(market_summary.count) > 0:
		var upgrade_label := host.label("ALTERNATIVA DE COMBATE · %d MELHORIA%s" % [int(market_summary.count), "S" if int(market_summary.count) != 1 else ""], 11, host.GOLD)
		upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(upgrade_label)
		var price_label := host.label("Stock atual desde ◈ %d · equipamento imediato" % int(market_summary.cheapest_price), 10, host.MUTED)
		price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(price_label)
	else:
		var no_upgrade_label := host.label("ALTERNATIVA DE COMBATE · SEM MELHORIA DIRETA", 11, host.MUTED)
		no_upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(no_upgrade_label)
		var collection_label := host.label("O stock atual serve apenas coleção; renovar é opcional.", 10, host.MUTED)
		collection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alternative_copy.add_child(collection_label)
	var market_action := host.action_button("VER MERCADO", host.GOLD, true)
	market_action.name = "HangarMarketAction"
	market_action.custom_minimum_size = Vector2(112, 48)
	market_action.add_theme_font_size_override("font_size", 10)
	market_action.pressed.connect(func():
		host.view_mode = "market"
		host.call("render")
	)
	alternative_row.add_child(market_action)
	content.add_child(alternative)

	if state.last_notice_context == "hangar" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#16363b"), 12, 10)
		receipt.name = "HangarReceipt"
		var receipt_label := host.label(state.last_notice, 11, host.LIME)
		receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_label)
		content.add_child(receipt)

	var scroller := ScrollContainer.new()
	scroller.name = "HangarScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroller.add_child(list)
	for transport in TransportRulesScript.DEFINITIONS:
		list.add_child(transport_card(host, state, transport))


static func transport_card(host: CrookedUIFactory, state: StateScript, transport: Dictionary) -> PanelContainer:
	var transport_id := str(transport.id)
	var owned := TransportRulesScript.is_owned(state.player, transport_id)
	var active := str(state.player.get("active_transport_id", "")) == transport_id
	var unlocked := TransportRulesScript.is_unlocked(state.player, transport)
	var affordable := int(state.player.credits) >= int(transport.price)
	var card := host.panel(HBoxContainer.new(), host.PANEL_LIGHT if unlocked else host.PANEL, 15, 12)
	card.name = "HangarTransport_%s" % transport_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 11)
	var transport_icon := host.transport_icon(transport, 58)
	transport_icon.name = "HangarTransportIcon_%s" % transport_id
	row.add_child(transport_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var name_label := host.label(str(transport.name), 14, Color(str(transport.color)) if unlocked else host.MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(name_label)
	copy.add_child(host.label("-%d%% TEMPO DE CAÇA · PERMANENTE" % roundi(float(transport.speed_bonus) * 100.0), 11, host.GOLD if unlocked else host.MUTED))
	var tagline := host.label(str(transport.tagline), 10, host.INK if unlocked else host.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(tagline)
	if not unlocked:
		copy.add_child(host.label("DESBLOQUEIA APÓS %d CAPÍTULO%s" % [int(transport.required_completed_planets), "S" if int(transport.required_completed_planets) != 1 else ""], 10, host.MUTED))

	var action_text := "ATIVO" if active else ("EQUIPAR" if owned else ("COMPRAR · ◈ %d" % int(transport.price) if affordable else "FALTAM ◈ %d" % (int(transport.price) - int(state.player.credits))))
	if not unlocked:
		action_text = "BLOQUEADO"
	var enabled := unlocked and not active and (owned or affordable)
	var action := host.action_button(action_text, Color(str(transport.color)) if enabled else host.MUTED, true)
	action.name = "HangarAction_%s" % transport_id
	action.custom_minimum_size = Vector2(126, 48)
	action.add_theme_font_size_override("font_size", 10)
	action.disabled = not enabled
	action.pressed.connect(func(): state.acquire_or_equip_transport(transport_id))
	row.add_child(action)
	return card
