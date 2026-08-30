class_name AttributesView
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")
const ClassRulesScript = preload("res://scripts/class_rules.gd")
const SpeciesRulesScript = preload("res://scripts/species_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const AttributeIconScript = preload("res://scripts/attribute_icon.gd")
const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")

const DEFINITIONS := [
	{"id": "strength", "name": "FORÇA", "description": "Potência muscular, impacto e armas pesadas."},
	{"id": "vitality", "name": "VITALIDADE", "description": "Fôlego para contratos que recusam terminar."},
	{"id": "dexterity", "name": "DESTREZA", "description": "Reflexos, posicionamento e redução de dano."},
	{"id": "intelligence", "name": "INTELIGÊNCIA", "description": "Tecnologia, dispositivos e vantagem de abertura."},
	{"id": "cunning", "name": "ASTÚCIA", "description": "Improviso que empurra ataques para resultados melhores."},
]


static func text(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func attribute_name(attribute_id: String, fallback: String = "") -> String:
	return text("ATTRIBUTE_%s" % attribute_id.to_upper(), fallback)


static func localized_class_field(definition: Dictionary, field: String) -> String:
	return text("CLASS_%s_%s" % [str(definition.get("id", "")).to_upper(), field.to_upper()], str(definition.get(field, "")))


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.scene_title(text("HUNTER_TITLE", "CAÇADOR")))
	titles.add_child(host.readable_caption(text("HUNTER_SUBTITLE", "PERSONAGEM · EQUIPAMENTO · ATRIBUTOS")))
	var back := host.secondary_action(text("COMMON_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 150
	back.pressed.connect(func():
		host.attribute_draft = {}
		host.hunter_section = "profile"
		host.view_mode = "board"
		host.call("render")
	)
	title_row.add_child(back)

	var tabs := HBoxContainer.new()
	tabs.name = "HunterSectionTabs"
	tabs.add_theme_constant_override("separation", 10)
	content.add_child(tabs)
	tabs.add_child(hunter_section_tab(host, "profile", text("HUNTER_TAB_PROFILE", "EQUIPAMENTO"), host.CYAN))
	tabs.add_child(hunter_section_tab(host, "attributes", text("HUNTER_TAB_ATTRIBUTES", "ATRIBUTOS"), host.GOLD))

	var drafted := draft_total(host.attribute_draft)
	var available := maxi(0, int(state.player.get("stat_points", 0)) - drafted)
	var scroller := TouchScrollContainer.new()
	scroller.name = "AttributeScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override("separation", 12)
	scroller.add_child(sheet)

	var class_id := str(state.player.get("class_id", ClassRulesScript.UNASSIGNED_ID))
	var class_definition := ClassRulesScript.get_definition(class_id)
	if host.hunter_section == "profile":
		sheet.add_child(hunter_profile(host, state, class_id, class_definition))
		return

	var point_panel := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 18)
	point_panel.name = "HunterAttributePointPanel"
	sheet.add_child(point_panel)
	var point_row := point_panel.get_child(0) as HBoxContainer
	point_row.add_theme_constant_override("separation", 12)
	var point_copy := VBoxContainer.new()
	point_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	point_row.add_child(point_copy)
	point_copy.add_child(host.readable_caption(text("HUNTER_POINTS_AVAILABLE", "PONTOS DISPONÍVEIS")))
	var point_value := host.label(str(available), UIDesignSystem.FONT_DISPLAY, host.GOLD)
	point_value.name = "AttributePoints"
	point_copy.add_child(point_value)
	point_row.add_child(host.label(text("HUNTER_POINTS_PER_LEVEL", "+%d POR NÍVEL", [Rules.ATTRIBUTE_POINTS_PER_LEVEL]), UIDesignSystem.FONT_CAPTION, host.LIME, HORIZONTAL_ALIGNMENT_RIGHT))

	var section_title := host.label(text("HUNTER_STATUS_ATTRIBUTES", "STATUS E ATRIBUTOS"), UIDesignSystem.FONT_SECTION_TITLE, host.INK)
	section_title.name = "HunterAttributeHeading"
	sheet.add_child(section_title)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	sheet.add_child(list)
	for definition in DEFINITIONS:
		list.add_child(attribute_card(host, state, definition, available))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var discard := host.secondary_action(text("HUNTER_DISCARD_DRAFT", "DESCARTAR RASCUNHO"), host.CORAL)
	discard.name = "DiscardAttributes"
	discard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discard.disabled = drafted <= 0
	discard.pressed.connect(func():
		host.attribute_draft = {}
		host.call("render")
	)
	actions.add_child(discard)
	var confirm := host.primary_action(text("HUNTER_CONFIRM_POINTS", "CONFIRMAR · %d", [drafted]), host.LIME)
	confirm.name = "ConfirmAttributes"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.disabled = drafted <= 0
	confirm.pressed.connect(func():
		var allocations: Dictionary = host.attribute_draft.duplicate(true)
		host.attribute_draft = {}
		state.allocate_attribute_points(allocations)
	)
	actions.add_child(confirm)


static func hunter_section_tab(host: CrookedUIFactory, section_id: String, title: String, accent: Color) -> Button:
	var selected := host.hunter_section == section_id
	var tab := host.primary_action(title, accent) if selected else host.secondary_action(title, accent)
	tab.name = "HunterTab_%s" % section_id
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.custom_minimum_size.y = 76
	tab.pressed.connect(func():
		host.hunter_section = section_id
		host.call("render")
	)
	return tab


static func hunter_profile(host: CrookedUIFactory, state: StateScript, class_id: String, class_definition: Dictionary) -> PanelContainer:
	var profile := host.focal_scene_panel(VBoxContainer.new())
	profile.name = "HunterProfile"
	var box := profile.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 16)

	var identity := HBoxContainer.new()
	identity.name = "HunterClassSummary"
	identity.add_theme_constant_override("separation", 14)
	box.add_child(identity)
	var reference_icon := class_reference_icon(host, class_id)
	if reference_icon != null:
		reference_icon.custom_minimum_size = Vector2(72, 72)
		identity.add_child(reference_icon)
	var identity_copy := VBoxContainer.new()
	identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(identity_copy)
	var hunter_name := str(state.player.get("hunter_name", ""))
	if not hunter_name.is_empty():
		var hunter_name_label := host.label(hunter_name.to_upper(), UIDesignSystem.FONT_SECTION_TITLE, host.INK)
		hunter_name_label.name = "HunterName"
		identity_copy.add_child(hunter_name_label)
	identity_copy.add_child(host.label(ClassRulesScript.class_name_for(class_id), 21 if not hunter_name.is_empty() else 28, host.GOLD if not class_definition.is_empty() else host.CORAL))
	var identity_detail := text("HUNTER_IDENTITY_LEVEL", "%s · NÍVEL %d", [SpeciesRulesScript.species_name_for(str(state.player.get("species_id", ""))).to_upper(), int(state.player.get("level", 1))])
	if not class_definition.is_empty():
		identity_detail += text("HUNTER_PRIMARY_SUFFIX", " · PRINCIPAL %s", [localized_class_field(class_definition, "primary_name")])
	identity_copy.add_child(host.readable_caption(identity_detail))
	var class_mechanic_text := ClassRulesScript.combat_identity_text(state.player, Rules.BASE_ATTRIBUTE_VALUE)
	if not class_mechanic_text.is_empty():
		var class_mechanic := host.readable_caption(class_mechanic_text, host.CYAN)
		class_mechanic.name = "HunterClassMechanic"
		class_mechanic.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		identity_copy.add_child(class_mechanic)

	var showcase := HBoxContainer.new()
	showcase.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase.add_theme_constant_override("separation", 16)
	box.add_child(showcase)
	showcase.add_child(equipment_slot(host, state.player.get("weapon", {}), "weapon"))
	var portrait_column := VBoxContainer.new()
	portrait_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_column.size_flags_stretch_ratio = 1.35
	portrait_column.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase.add_child(portrait_column)
	var portrait: Control = host.call("framed_hunter_portrait", 240.0)
	portrait.name = "HunterProfilePortrait"
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_column.add_child(portrait)
	showcase.add_child(equipment_slot(host, state.player.get("armor", {}), "armor"))
	var secondary_grid := GridContainer.new()
	secondary_grid.name = "HunterUniversalEquipment"
	secondary_grid.columns = 4
	secondary_grid.add_theme_constant_override("h_separation", 8)
	secondary_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(secondary_grid)
	for slot_id in Rules.EQUIPMENT_SLOTS:
		if slot_id == "weapon" or slot_id == "armor":
			continue
		secondary_grid.add_child(compact_equipment_slot(host, state.player.get(slot_id, {}), slot_id))
	var kit_origin := Rules.equipment_set_origin(state.player)
	var portrait_caption := host.center_label(text("HUNTER_PLANETARY_KIT_ACTIVE", "KIT PLANETÁRIO ATIVO") if not kit_origin.is_empty() else text("HUNTER_LOADOUT_EQUIPPED", "LOADOUT EQUIPADO"), UIDesignSystem.FONT_CAPTION, host.GOLD if not kit_origin.is_empty() else host.MUTED)
	box.add_child(portrait_caption)

	var metrics := HBoxContainer.new()
	metrics.name = "HunterCombatStatus"
	metrics.add_theme_constant_override("separation", 8)
	box.add_child(metrics)
	metrics.add_child(hunter_metric_chip(host, text("COMMON_POWER", "PODER"), str(Rules.player_power(state.player)), host.GOLD))
	metrics.add_child(hunter_metric_chip(host, text("COMMON_HEALTH", "VIDA"), str(Rules.max_health(state.player)), host.LIME))
	metrics.add_child(hunter_metric_chip(host, text("HUNTER_OPENING", "ABERTURA"), "+%d" % Rules.player_opening_damage(state.player), host.CYAN))
	metrics.add_child(hunter_metric_chip(host, text("HUNTER_REDUCTION", "REDUÇÃO"), "-%d" % Rules.player_damage_reduction(state.player), host.CORAL))

	var profile_actions := HBoxContainer.new()
	profile_actions.add_theme_constant_override("separation", 8)
	box.add_child(profile_actions)
	var choose_class := host.secondary_action(text("NAV_CLASS", "CLASSE"), host.CYAN)
	choose_class.name = "ChooseClassAction"
	choose_class.custom_minimum_size.x = 0
	choose_class.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose_class.pressed.connect(func():
		host.class_draft = ""
		host.view_mode = "classes"
		host.call("render")
	)
	profile_actions.add_child(choose_class)
	var arsenal := host.secondary_action(text("NAV_ARSENAL", "ARSENAL"), host.GOLD)
	arsenal.name = "HunterArsenalAction"
	arsenal.custom_minimum_size.x = 0
	arsenal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arsenal.pressed.connect(func():
		host.attribute_draft = {}
		host.arsenal_section = "equipped"
		host.view_mode = "arsenal"
		host.call("render")
	)
	profile_actions.add_child(arsenal)
	return profile


static func hunter_metric_chip(host: CrookedUIFactory, title: String, value: String, color: Color) -> PanelContainer:
	var chip := host.panel(VBoxContainer.new(), Color("#09132acc"), 12, 10)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(host.center_label(title, UIDesignSystem.FONT_CAPTION, host.MUTED))
	box.add_child(host.center_label(value, UIDesignSystem.FONT_EMPHASIS, color))
	return chip


static func equipment_slot(host: CrookedUIFactory, item_value: Variant, slot_id: String) -> PanelContainer:
	var item: Dictionary = item_value if item_value is Dictionary else {}
	var slot_title := EquipmentPresentation.localized_slot(slot_id).to_upper()
	var slot := host.panel(VBoxContainer.new(), Color("#090f25"), 13, 10)
	slot.name = "HunterEquipment_%s" % slot_id
	slot.custom_minimum_size = Vector2(112, 0)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_stretch_ratio = 0.9
	var box := slot.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.add_child(host.center_label(slot_title, UIDesignSystem.FONT_CAPTION, host.MUTED))
	var icon_item := item.duplicate(true)
	icon_item.slot = slot_id
	var icon := host.equipment_icon(icon_item, 82)
	box.add_child(icon)
	box.add_child(host.center_label(text("HUNTER_SLOT_POWER", "+%d PODER", [int(item.get("power", 0))]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	slot.tooltip_text = "%s · %s" % [slot_title, EquipmentPresentation.localized_item_field(item, "name") if not item.is_empty() else text("HUNTER_EMPTY_SLOT", "SLOT VAZIO")]
	return slot


static func compact_equipment_slot(host: CrookedUIFactory, item_value: Variant, slot_id: String) -> PanelContainer:
	var item: Dictionary = item_value if item_value is Dictionary else {}
	var slot := host.panel(VBoxContainer.new(), Color("#090f25"), 9, 8)
	slot.name = "HunterEquipment_%s" % slot_id
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := slot.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var slot_label := host.center_label(EquipmentPresentation.localized_slot(slot_id).to_upper(), UIDesignSystem.FONT_CAPTION, host.MUTED)
	slot_label.name = "HunterEquipmentLabel_%s" % slot_id
	slot_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(slot_label)
	var icon_item := item.duplicate(true)
	icon_item.slot = slot_id
	box.add_child(host.equipment_icon(icon_item, 54))
	var power_label := host.center_label("+%d" % int(item.get("power", 0)) if not item.is_empty() else text("HUNTER_EMPTY", "VAZIO"), UIDesignSystem.FONT_CAPTION, host.GOLD if not item.is_empty() else host.MUTED)
	power_label.name = "HunterEquipmentPower_%s" % slot_id
	box.add_child(power_label)
	slot.tooltip_text = "%s · %s" % [EquipmentPresentation.localized_slot(slot_id), EquipmentPresentation.localized_item_field(item, "name") if not item.is_empty() else text("HUNTER_EMPTY_SLOT", "SLOT VAZIO")]
	return slot
static func class_reference_icon(host: CrookedUIFactory, class_id: String) -> Control:
	if class_id.is_empty():
		return null
	var icon := host.class_icon(class_id, 62.0)
	icon.name = "AttributeClassReferenceIcon"
	return icon


static func attribute_card(host: CrookedUIFactory, state: StateScript, definition: Dictionary, available: int) -> PanelContainer:
	var attribute_id := str(definition.id)
	var draft_amount := int(host.attribute_draft.get(attribute_id, 0))
	var value := Rules.attribute_value(state.player, attribute_id) + draft_amount
	var card := host.panel(HBoxContainer.new(), host.PANEL, 15, 14)
	card.name = "Attribute_%s" % attribute_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var value_stack := VBoxContainer.new()
	value_stack.custom_minimum_size = Vector2(72, 0)
	value_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	value_stack.add_theme_constant_override("separation", 0)
	row.add_child(value_stack)
	var glyph := AttributeIconScript.new()
	glyph.name = "AttributeGlyph_%s" % attribute_id
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.configure(attribute_id)
	value_stack.add_child(glyph)
	var value_label := host.center_label(str(value), UIDesignSystem.FONT_EMPHASIS, host.GOLD if draft_amount > 0 else host.INK)
	value_stack.add_child(value_label)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(attribute_name(attribute_id, str(definition.name)).to_upper(), UIDesignSystem.FONT_BODY, host.CYAN))
	var effect := host.readable_caption(attribute_effect(attribute_id, value), host.LIME)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(effect)
	var add := host.secondary_action("+1", host.GOLD)
	add.name = "AttributeAdd_%s" % attribute_id
	add.custom_minimum_size = Vector2(88, 76)
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
			return text("ATTRIBUTE_EFFECT_STRENGTH", "BÔNUS UNIVERSAL · +%d PODER", [floori(float(investment) / 2.0)])
		"vitality":
			return text("ATTRIBUTE_EFFECT_VITALITY", "BÔNUS UNIVERSAL · +%d VIDA", [investment * 4])
		"dexterity":
			return text("ATTRIBUTE_EFFECT_DEXTERITY", "BÔNUS UNIVERSAL · -%d DANO RECEBIDO", [floori(float(investment) / 3.0)])
		"intelligence":
			return text("ATTRIBUTE_EFFECT_INTELLIGENCE", "BÔNUS UNIVERSAL · +%d DANO DE ABERTURA", [floori(float(investment) / 2.0)])
		"cunning":
			return text("ATTRIBUTE_EFFECT_CUNNING", "BÔNUS UNIVERSAL · +%.1f%% NO ROLAMENTO", [minf(0.15, float(investment) * 0.005) * 100.0])
	return ""
