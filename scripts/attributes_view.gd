class_name AttributesView
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const ClassRulesScript = preload("res://scripts/class_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const AttributeIconScript = preload("res://scripts/attribute_icon.gd")

const DEFINITIONS := [
	{"id": "strength", "name": "FORÇA", "description": "Potência muscular, impacto e armas pesadas."},
	{"id": "vitality", "name": "VITALIDADE", "description": "Fôlego para contratos que recusam terminar."},
	{"id": "dexterity", "name": "DESTREZA", "description": "Reflexos, posicionamento e redução de dano."},
	{"id": "intelligence", "name": "INTELIGÊNCIA", "description": "Tecnologia, dispositivos e vantagem de abertura."},
	{"id": "cunning", "name": "ASTÚCIA", "description": "Improviso que empurra ataques para resultados melhores."},
]


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("ATRIBUTOS DO CAÇADOR", 25, host.INK))
	var subtitle := host.label("Atributos universais e especialização da classe em um só perfil.", 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(112, 48)
	back.pressed.connect(func():
		host.attribute_draft = {}
		host.view_mode = "board"
		host.call("render")
	)
	title_row.add_child(back)

	var class_id := str(state.player.get("class_id", ClassRulesScript.UNASSIGNED_ID))
	var class_definition := ClassRulesScript.get_definition(class_id)
	var class_panel := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 12)
	class_panel.name = "HunterClassSummary"
	content.add_child(class_panel)
	var class_row := class_panel.get_child(0) as HBoxContainer
	class_row.add_theme_constant_override("separation", 12)
	var reference_icon := class_reference_icon(host, class_id)
	if reference_icon != null:
		class_row.add_child(reference_icon)
	var class_copy := VBoxContainer.new()
	class_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_row.add_child(class_copy)
	class_copy.add_child(host.label("CLASSE", 11, host.MUTED))
	class_copy.add_child(host.label(ClassRulesScript.class_name_for(class_id), 17, host.GOLD if not class_definition.is_empty() else host.CORAL))
	if not class_definition.is_empty():
		var class_effect := "PRINCIPAL · %s · +%d PODER" % [str(class_definition.primary_name), ClassRulesScript.specialization_power(state.player, Rules.BASE_ATTRIBUTE_VALUE)]
		var class_opening := ClassRulesScript.specialization_opening_damage(state.player, Rules.BASE_ATTRIBUTE_VALUE)
		if class_opening > 0:
			class_effect += " · +%d ABERTURA" % class_opening
		class_copy.add_child(host.label(class_effect, 11, host.LIME))
	var choose_class := host.action_button("TROCAR" if not class_definition.is_empty() else "ESCOLHER", host.CYAN, true)
	choose_class.name = "ChooseClassAction"
	choose_class.custom_minimum_size = Vector2(112, 48)
	choose_class.pressed.connect(func():
		host.class_draft = ""
		host.view_mode = "classes"
		host.call("render")
	)
	class_row.add_child(choose_class)

	var drafted := draft_total(host.attribute_draft)
	var available := maxi(0, int(state.player.get("stat_points", 0)) - drafted)
	var point_panel := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 12)
	content.add_child(point_panel)
	var point_row := point_panel.get_child(0) as HBoxContainer
	point_row.add_theme_constant_override("separation", 12)
	var point_copy := VBoxContainer.new()
	point_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	point_row.add_child(point_copy)
	point_copy.add_child(host.label("PONTOS DISPONÍVEIS", 12, host.MUTED))
	var point_value := host.label(str(available), 28, host.GOLD)
	point_value.name = "AttributePoints"
	point_copy.add_child(point_value)
	point_row.add_child(host.label("+%d POR NÍVEL" % Rules.ATTRIBUTE_POINTS_PER_LEVEL, 13, host.LIME, HORIZONTAL_ALIGNMENT_RIGHT))

	var scroller := ScrollContainer.new()
	scroller.name = "AttributeScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroller.add_child(list)
	for definition in DEFINITIONS:
		list.add_child(attribute_card(host, state, definition, available))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var discard := host.action_button("DESCARTAR RASCUNHO", host.CORAL, true)
	discard.name = "DiscardAttributes"
	discard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discard.disabled = drafted <= 0
	discard.pressed.connect(func():
		host.attribute_draft = {}
		host.call("render")
	)
	actions.add_child(discard)
	var confirm := host.action_button("CONFIRMAR · %d" % drafted, host.LIME, true)
	confirm.name = "ConfirmAttributes"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.disabled = drafted <= 0
	confirm.pressed.connect(func():
		var allocations: Dictionary = host.attribute_draft.duplicate(true)
		host.attribute_draft = {}
		state.allocate_attribute_points(allocations)
	)
	actions.add_child(confirm)


static func class_reference_icon(host: CrookedUIFactory, class_id: String) -> TextureRect:
	if class_id.is_empty():
		return null
	var reference_layer = host.get("reference_backdrop")
	if reference_layer == null or not reference_layer.has_method("ui_texture"):
		return null
	var texture: Texture2D = reference_layer.ui_texture(class_id)
	if texture == null:
		return null
	var icon := TextureRect.new()
	icon.name = "AttributeClassReferenceIcon"
	icon.custom_minimum_size = Vector2(62, 62)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.tooltip_text = "PLACEHOLDER INTERNO · identidade visual provisória"
	return icon


static func attribute_card(host: CrookedUIFactory, state: StateScript, definition: Dictionary, available: int) -> PanelContainer:
	var attribute_id := str(definition.id)
	var draft_amount := int(host.attribute_draft.get(attribute_id, 0))
	var value := Rules.attribute_value(state.player, attribute_id) + draft_amount
	var card := host.panel(HBoxContainer.new(), host.PANEL, 15, 10)
	card.name = "Attribute_%s" % attribute_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var value_stack := VBoxContainer.new()
	value_stack.custom_minimum_size = Vector2(54, 0)
	value_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	value_stack.add_theme_constant_override("separation", 0)
	row.add_child(value_stack)
	var glyph := AttributeIconScript.new()
	glyph.name = "AttributeGlyph_%s" % attribute_id
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.configure(attribute_id)
	value_stack.add_child(glyph)
	var value_label := host.center_label(str(value), 18, host.GOLD if draft_amount > 0 else host.INK)
	value_stack.add_child(value_label)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(definition.name), 16, host.CYAN))
	var description := host.label(str(definition.description), 11, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	copy.add_child(host.label(attribute_effect(attribute_id, value), 11, host.LIME))
	var add := host.action_button("+1", host.GOLD, true)
	add.name = "AttributeAdd_%s" % attribute_id
	add.custom_minimum_size = Vector2(72, 48)
	add.disabled = available <= 0
	var captured_id := attribute_id
	add.pressed.connect(func(): add_to_draft(host, state, captured_id))
	row.add_child(add)
	return card


static func add_to_draft(host: CrookedUIFactory, state: StateScript, attribute_id: String) -> void:
	if draft_total(host.attribute_draft) >= int(state.player.get("stat_points", 0)):
		return
	host.attribute_draft[attribute_id] = int(host.attribute_draft.get(attribute_id, 0)) + 1
	host.call("render")


static func draft_total(draft: Dictionary) -> int:
	var total := 0
	for amount in draft.values():
		total += maxi(0, int(amount))
	return total


static func attribute_effect(attribute_id: String, value: int) -> String:
	var investment := maxi(0, value - Rules.BASE_ATTRIBUTE_VALUE)
	match attribute_id:
		"strength":
			return "BÔNUS UNIVERSAL · +%d PODER" % floori(float(investment) / 2.0)
		"vitality":
			return "BÔNUS UNIVERSAL · +%d VIDA" % (investment * 4)
		"dexterity":
			return "BÔNUS UNIVERSAL · -%d DANO RECEBIDO" % floori(float(investment) / 3.0)
		"intelligence":
			return "BÔNUS UNIVERSAL · +%d DANO DE ABERTURA" % floori(float(investment) / 2.0)
		"cunning":
			return "BÔNUS UNIVERSAL · +%.1f%% NO ROLAMENTO" % (minf(0.15, float(investment) * 0.005) * 100.0)
	return ""
