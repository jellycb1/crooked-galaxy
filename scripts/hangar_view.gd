class_name HangarView
extends RefCounted

const TransportRulesScript = preload("res://scripts/transport_rules.gd")
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
		host.view_mode = "board"
		host.call("render")
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
