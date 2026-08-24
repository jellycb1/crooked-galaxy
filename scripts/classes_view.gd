class_name ClassesView
extends RefCounted

const ClassRulesScript = preload("res://scripts/class_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("CLASSE DO CAÇADOR", 25, host.INK))
	var subtitle := host.label("Escolha a especialização que amplifica seu atributo principal.", 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(112, 48)
	back.pressed.connect(func():
		host.class_draft = ""
		host.view_mode = "attributes"
		host.call("render")
	)
	title_row.add_child(back)

	var current_id := str(state.player.get("class_id", ClassRulesScript.UNASSIGNED_ID))
	var pending_id := host.class_draft if not host.class_draft.is_empty() else current_id
	var info := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 16, 12)
	content.add_child(info)
	var info_copy := info.get_child(0) as VBoxContainer
	info_copy.add_child(host.label("ARQUÉTIPOS PROVISÓRIOS · TROCA GRATUITA", 12, host.LIME))
	var explanation := host.label("A classe concede +1 Poder a cada 2 pontos investidos no atributo principal. Seus demais atributos continuam ativos.", 12, host.INK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_copy.add_child(explanation)

	var scroller := ScrollContainer.new()
	scroller.name = "ClassScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroller.add_child(list)
	for definition in ClassRulesScript.DEFINITIONS:
		list.add_child(class_card(host, definition, state.player, pending_id, current_id))

	var changed := not host.class_draft.is_empty() and host.class_draft != current_id
	var confirm := host.action_button("CONFIRMAR CLASSE", host.LIME, true)
	confirm.name = "ConfirmClass"
	confirm.disabled = not changed
	confirm.pressed.connect(func():
		var selected := host.class_draft
		host.class_draft = ""
		state.select_class(selected)
	)
	content.add_child(confirm)


static func class_card(host: CrookedUIFactory, definition: Dictionary, player: Dictionary, pending_id: String, current_id: String) -> PanelContainer:
	var class_id := str(definition.id)
	var selected := class_id == pending_id
	var card := host.panel(HBoxContainer.new(), host.PANEL_LIGHT if selected else host.PANEL, 15, 12)
	card.name = "Class_%s" % class_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var reference_icon := class_reference_icon(host, class_id)
	if reference_icon != null:
		row.add_child(reference_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var status := " · ATUAL" if class_id == current_id else (" · RASCUNHO" if selected else "")
	copy.add_child(host.label("%s%s" % [str(definition.name), status], 16, host.GOLD if selected else host.CYAN))
	copy.add_child(host.label("PRINCIPAL · %s" % str(definition.primary_name), 11, host.LIME))
	var tagline := host.label(str(definition.tagline), 12, host.INK)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(tagline)
	var flavor := host.label(str(definition.flavor), 11, host.MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(flavor)
	var specialization := host.label("ESPECIALIZAÇÃO · %s" % ClassRulesScript.specialization_text(definition), 10, host.GOLD)
	specialization.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(specialization)
	var impact := host.label(current_impact_text(definition, player), 11, host.LIME)
	impact.name = "ClassImpact_%s" % class_id
	impact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(impact)
	var choose := host.action_button("MARCADO" if selected else "ESCOLHER", host.GOLD if selected else host.CYAN, true)
	choose.name = "ClassSelect_%s" % class_id
	choose.custom_minimum_size = Vector2(104, 48)
	choose.disabled = selected
	choose.pressed.connect(func():
		host.class_draft = class_id
		host.call("render")
	)
	row.add_child(choose)
	return card


static func class_reference_icon(host: CrookedUIFactory, class_id: String) -> TextureRect:
	var reference_layer = host.get("reference_backdrop")
	if reference_layer == null or not reference_layer.has_method("ui_texture"):
		return null
	var texture: Texture2D = reference_layer.ui_texture(class_id)
	if texture == null:
		return null
	var icon := TextureRect.new()
	icon.name = "ClassReferenceIcon_%s" % class_id
	icon.custom_minimum_size = Vector2(76, 76)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.tooltip_text = "PLACEHOLDER INTERNO · identidade visual provisória"
	return icon


static func current_impact_text(definition: Dictionary, player: Dictionary) -> String:
	var preview := ClassRulesScript.specialization_preview(definition, player.get("attributes", {}), Rules.BASE_ATTRIBUTE_VALUE)
	var parts: Array[String] = []
	if int(preview.power) > 0:
		parts.append("+%d PODER" % int(preview.power))
	if int(preview.opening_damage) > 0:
		parts.append("+%d ABERTURA" % int(preview.opening_damage))
	return "BÔNUS NA BUILD · %s" % (" · ".join(parts) if not parts.is_empty() else "AINDA INATIVO")
