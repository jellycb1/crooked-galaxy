class_name ClassesView
extends RefCounted

const ClassRulesScript = preload("res://scripts/class_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func text(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_class_field(definition: Dictionary, field: String) -> String:
	return text("CLASS_%s_%s" % [str(definition.get("id", "")).to_upper(), field.to_upper()], str(definition.get(field, "")))


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	title_row.add_child(titles)
	titles.add_child(host.scene_title(text("CLASS_VIEW_TITLE", "CLASSE DO CAÇADOR")))
	titles.add_child(host.readable_caption(text("CLASS_VIEW_SUBTITLE", "Escolha a especialização que amplifica seu atributo principal.")))
	var back := host.secondary_action(text("COMMON_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func():
		host.class_draft = ""
		host.view_mode = "attributes"
		host.call("render")
	)
	title_row.add_child(back)

	var current_id := str(state.player.get("class_id", ClassRulesScript.UNASSIGNED_ID))
	var pending_id := host.class_draft if not host.class_draft.is_empty() else current_id
	if pending_id.is_empty() and not ClassRulesScript.DEFINITIONS.is_empty():
		pending_id = str(ClassRulesScript.DEFINITIONS[0].id)
	var scroller := TouchScrollContainer.new()
	scroller.name = "ClassScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroller.add_child(page)
	var info := host.supporting_panel(VBoxContainer.new(), host.PANEL_LIGHT, 24)
	info.name = "ClassSupportingInfo"
	page.add_child(info)
	var info_copy := host.supporting_panel_content(info) as VBoxContainer
	info_copy.add_child(host.label(text("CLASS_VIEW_PROVISIONAL", "CLASSES INICIAIS · TROCA GRATUITA"), UIDesignSystem.FONT_CAPTION, host.LIME))
	var explanation := host.label(text("CLASS_VIEW_EXPLANATION", "O atributo principal amplia Poder e a mecânica exclusiva da classe. Todos os demais atributos continuam ativos."), UIDesignSystem.FONT_CAPTION, host.INK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_copy.add_child(explanation)

	var list := VBoxContainer.new()
	list.name = "ClassSelectorList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	page.add_child(list)
	for definition in ClassRulesScript.DEFINITIONS:
		list.add_child(class_selector(host, definition, pending_id, current_id))

	var focused_definition := ClassRulesScript.get_definition(pending_id)
	if not focused_definition.is_empty():
		page.add_child(class_detail(host, focused_definition, state.player, current_id))

	var changed := not host.class_draft.is_empty() and host.class_draft != current_id
	var confirm := host.primary_action(text("CLASS_VIEW_CONFIRM", "CONFIRMAR CLASSE"), host.LIME)
	confirm.name = "ConfirmClass"
	confirm.disabled = not changed
	confirm.pressed.connect(func():
		var selected := host.class_draft
		host.class_draft = ""
		state.select_class(selected)
	)
	content.add_child(confirm)


static func class_selector(host: CrookedUIFactory, definition: Dictionary, pending_id: String, current_id: String) -> PanelContainer:
	var class_id := str(definition.id)
	var selected := class_id == pending_id
	var committed_or_drafted := class_id == current_id or (not host.class_draft.is_empty() and class_id == host.class_draft)
	var card := host.panel(HBoxContainer.new(), Color("#1b3151") if selected else Color("#0d1730"), 16, 12)
	card.name = "Class_%s" % class_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var reference_icon := class_reference_icon(host, class_id, 58)
	if reference_icon != null:
		row.add_child(reference_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	var status := text("CLASS_VIEW_CURRENT_SUFFIX", " · ATUAL") if class_id == current_id else (text("CLASS_VIEW_FOCUSED_SUFFIX", " · EM FOCO") if selected else "")
	copy.add_child(host.label("%s%s" % [ClassRulesScript.class_name_for(class_id), status], UIDesignSystem.FONT_BODY, host.GOLD if selected else host.INK))
	copy.add_child(host.label(text("CLASS_VIEW_PRIMARY", "ATRIBUTO PRINCIPAL · %s", [localized_class_field(definition, "primary_name")]), UIDesignSystem.FONT_CAPTION, host.LIME if selected else host.MUTED))
	var choose_text := text("CLASS_VIEW_IN_FOCUS", "EM FOCO") if selected and committed_or_drafted else (text("COMMON_CHOOSE", "ESCOLHER") if selected else text("CLASS_VIEW_SHEET", "VER FICHA"))
	var choose := host.secondary_action(choose_text, host.GOLD if selected else host.CYAN)
	choose.name = "ClassSelect_%s" % class_id
	choose.custom_minimum_size.x = 112
	choose.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	choose.disabled = selected and committed_or_drafted
	choose.pressed.connect(func():
		host.class_draft = class_id
		host.call("render")
	)
	row.add_child(choose)
	return card


static func class_detail(host: CrookedUIFactory, definition: Dictionary, player: Dictionary, current_id: String) -> PanelContainer:
	var class_id := str(definition.id)
	var detail := host.illustrated_panel(HBoxContainer.new(), 22)
	detail.name = "ClassDetail"
	var row := host.illustrated_panel_content(detail) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	var reference_icon: Control = class_reference_icon(host, class_id, 104)
	if reference_icon != null:
		reference_icon.name = "ClassIcon_%s" % class_id
		row.add_child(reference_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)
	var state_text := text("CLASS_VIEW_CURRENT", "CLASSE ATUAL") if class_id == current_id else (text("CLASS_VIEW_PENDING", "ALTERAÇÃO PENDENTE") if not current_id.is_empty() else text("CLASS_VIEW_FIRST", "PRIMEIRA CLASSE"))
	copy.add_child(host.label(state_text, UIDesignSystem.FONT_CAPTION, host.LIME))
	copy.add_child(host.label(ClassRulesScript.class_name_for(class_id), UIDesignSystem.FONT_BODY, host.GOLD))
	var tagline := host.label(localized_class_field(definition, "tagline"), UIDesignSystem.FONT_CAPTION, host.INK)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(tagline)
	var flavor := host.label(localized_class_field(definition, "flavor"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(flavor)
	var specialization := host.label(text("CLASS_VIEW_SPECIALIZATION", "ESPECIALIZAÇÃO · %s", [ClassRulesScript.specialization_text(definition)]), UIDesignSystem.FONT_CAPTION, host.GOLD)
	specialization.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(specialization)
	var route_profile := host.label(text("CLASS_VIEW_CONTRACT_STYLE", "ESTILO DE CONTRATO · %s", [localized_class_field(definition, "route_style")]), UIDesignSystem.FONT_CAPTION, host.CYAN)
	route_profile.name = "ClassRouteProfile_%s" % class_id
	route_profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(route_profile)
	var impact := host.label(current_impact_text(definition, player), UIDesignSystem.FONT_CAPTION, host.LIME)
	impact.name = "ClassImpact_%s" % class_id
	impact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(impact)
	return detail


static func class_reference_icon(host: CrookedUIFactory, class_id: String, dimension: float = 76.0) -> Control:
	var icon := host.class_icon(class_id, dimension)
	icon.name = "ClassIcon_%s" % class_id
	return icon


static func current_impact_text(definition: Dictionary, player: Dictionary) -> String:
	var preview := ClassRulesScript.specialization_preview(definition, player.get("attributes", {}), Rules.BASE_ATTRIBUTE_VALUE)
	var parts: Array[String] = []
	if int(preview.power) > 0:
		parts.append(text("CLASS_VIEW_BONUS_POWER", "+%d PODER", [int(preview.power)]))
	if int(preview.opening_damage) > 0:
		parts.append(text("CLASS_VIEW_BONUS_OPENING", "+%d ABERTURA", [int(preview.opening_damage)]))
	if int(preview.damage_reduction) > 0:
		parts.append(text("CLASS_VIEW_BONUS_REDUCTION", "-%d DANO/GOLPE", [int(preview.damage_reduction)]))
	if float(preview.attack_roll_bonus) > 0.0:
		parts.append(text("CLASS_VIEW_BONUS_AIM", "+%.1f%% MIRA", [float(preview.attack_roll_bonus) * 100.0]))
	if int(preview.counter_damage) > 0:
		parts.append(text("CLASS_VIEW_BONUS_COUNTER", "+%d CONTRA-ATAQUE/3T", [int(preview.counter_damage)]))
	if float(preview.evasion_chance) > 0.0:
		parts.append(text("CLASS_VIEW_BONUS_EVASION", "%.1f%% ESQUIVA", [float(preview.evasion_chance) * 100.0]))
	if int(preview.defense_bypass) > 0:
		parts.append(text("CLASS_VIEW_BONUS_OVERLOAD", "-%d DEFESA", [int(preview.defense_bypass)]))
	return text("CLASS_VIEW_BUILD_BONUS", "BÔNUS NA BUILD · %s", [" · ".join(parts) if not parts.is_empty() else text("CLASS_VIEW_INACTIVE", "AINDA INATIVO")])
