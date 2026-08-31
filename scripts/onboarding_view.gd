class_name OnboardingView
extends RefCounted

const ClassRulesScript = preload("res://scripts/class_rules.gd")
const SpeciesRulesScript = preload("res://scripts/species_rules.gd")
const AppearanceRulesScript = preload("res://scripts/appearance_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const SpeciesIconScript = preload("res://scripts/species_icon.gd")
const ServerRulesScript = preload("res://scripts/server_rules.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const TouchScrollContainerScript = preload("res://scripts/touch_scroll_container.gd")

const STEP_INDEX := {"login": 1, "class": 2, "species": 3, "appearance": 4, "name": 5}


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var step := state.onboarding_step()
	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 2)
	content.add_child(brand)
	brand.add_child(host.center_label("CROOKED GALAXY", UIDesignSystem.FONT_SCREEN_TITLE, host.CYAN))
	var progress := host.center_label(t("ONB_PROGRESS", "REGISTRO DE CAÇADOR · ETAPA %d/5", [int(STEP_INDEX.get(step, 5))]), UIDesignSystem.FONT_CAPTION, host.GOLD)
	progress.name = "OnboardingProgress"
	brand.add_child(progress)

	var scroll := TouchScrollContainerScript.new() as ScrollContainer
	scroll.name = "OnboardingScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 14)
	scroll.add_child(stack)

	match step:
		"login":
			build_login(host, stack, state)
		"class":
			build_class(host, stack, state)
		"species":
			build_species(host, stack, state)
		"appearance":
			build_appearance(host, stack, state)
		"name":
			build_name(host, stack, state)
	if step in ["class", "species"]:
		enable_touch_drag_scrolling(stack)
	if step in ["class", "species", "appearance"]:
		host.call_deferred("restore_onboarding_scroll", int(host.get("render_generation")))


static func build_login(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, t("ONB_LOGIN_TITLE", "ENTRAR"), t("ONB_LOGIN_DESCRIPTION", "A sua carreira começa com uma sessão neste dispositivo."))
	if host.locale_draft.is_empty():
		host.locale_draft = LocaleRulesScript.DEFAULT_ID
	if host.server_draft.is_empty():
		host.server_draft = ServerRulesScript.DEFAULT_ID
	stack.add_child(host.label(t("ONB_LANGUAGE", "IDIOMA"), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var language_row := HBoxContainer.new()
	language_row.name = "OnboardingLanguageSelector"
	language_row.add_theme_constant_override("separation", 8)
	stack.add_child(language_row)
	for locale in LocaleRulesScript.DEFINITIONS:
		var locale_id := str(locale.id)
		var available := bool(locale.selectable)
		var selected := locale_id == host.locale_draft
		var language := host.primary_action("%s%s%s" % ["✓ " if selected else "", str(locale.native_name).to_upper(), t("ONB_TRANSLATION_PENDING", " · EM TRADUÇÃO") if not available else ""], host.LIME if selected else host.CYAN) if selected else host.secondary_action("%s%s%s" % ["", str(locale.native_name).to_upper(), t("ONB_TRANSLATION_PENDING", " · EM TRADUÇÃO") if not available else ""], host.CYAN)
		language.name = "OnboardingLanguage_%s" % locale_id
		language.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		language.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		language.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		language.disabled = not available or selected
		language.tooltip_text = t("ONB_LANGUAGE_AVAILABLE", "Disponível") if available else t("ONB_LANGUAGE_PENDING_TOOLTIP", "A tradução integral será ativada quando todas as telas estiverem localizadas.")
		language.pressed.connect(func():
			host.locale_draft = locale_id
			TranslationServer.set_locale(locale_id)
			host.call("render")
		)
		language_row.add_child(language)
	stack.add_child(host.label(t("ONB_SERVER", "SERVIDOR"), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var server_definition := ServerRulesScript.get_definition(host.server_draft)
	var server := host.illustrated_panel(HBoxContainer.new(), 16)
	server.name = "OnboardingServer_%s" % host.server_draft
	stack.add_child(server)
	var server_row := host.illustrated_panel_content(server) as HBoxContainer
	var server_copy := VBoxContainer.new()
	server_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	server_row.add_child(server_copy)
	server_copy.add_child(host.label(str(server_definition.get("name", "International 1")), UIDesignSystem.FONT_BODY, host.GOLD))
	server_copy.add_child(host.label(t("ONB_SERVER_POLICY", "%s · %s", [str(server_definition.get("region", "GLOBAL")), t("SERVER_POLICY_MULTILINGUAL", "MULTILÍNGUE")]), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var server_status := host.label(t("ONB_SERVER_STATUS", "PRIMEIRO MUNDO · conexão online ainda não ativa neste APK"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	server_status.name = "OnboardingServerStatus"
	server_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	server_copy.add_child(server_status)
	var selected_server := host.secondary_action(t("ONB_ACTIVE_SELECTION", "ATIVO"), host.GOLD)
	selected_server.name = "OnboardingServerSelected"
	selected_server.custom_minimum_size.x = 146
	selected_server.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	selected_server.disabled = true
	server_row.add_child(selected_server)
	var notice := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 16, 15)
	notice.name = "LocalSessionNotice"
	stack.add_child(notice)
	var copy := notice.get_child(0) as VBoxContainer
	copy.add_child(host.label(t("ONB_LOCAL_SESSION_TITLE", "SESSÃO LOCAL DE TESTE"), UIDesignSystem.FONT_CAPTION, host.LIME))
	var explanation := host.label(t("ONB_LOCAL_SESSION_DESCRIPTION", "Ainda não existe servidor de contas. Esta entrada não pede senha, não simula autenticação online e mantém o progresso apenas neste dispositivo."), UIDesignSystem.FONT_CAPTION, host.INK)
	explanation.name = "OnboardingSessionDescription"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(explanation)
	var future := host.label(t("ONB_LOCAL_SESSION_FUTURE", "A identidade da sessão já está separada da classe, raça e nome para receber uma conta online futuramente."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	future.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(future)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	stack.add_child(spacer)
	var enter := host.primary_action(t("ONB_ENTER_SERVER", "ENTRAR EM %s", [str(server_definition.get("name", "International 1")).to_upper()]), host.LIME)
	enter.name = "OnboardingLoginAction"
	enter.pressed.connect(func(): state.begin_local_session(host.locale_draft, host.server_draft))
	stack.add_child(enter)


static func build_class(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, t("ONB_CLASS_TITLE", "ESCOLHA A CLASSE"), t("ONB_CLASS_DESCRIPTION", "A classe define sua especialização inicial de combate e contratos."))
	var pending_id := host.class_draft
	var pending_definition := ClassRulesScript.get_definition(pending_id)
	var preview := host.illustrated_panel(HBoxContainer.new(), 13)
	preview.name = "OnboardingClassPreview"
	stack.add_child(preview)
	var preview_row := host.illustrated_panel_content(preview) as HBoxContainer
	preview_row.add_theme_constant_override("separation", 13)
	var preview_icon: Control = class_reference_icon(host, pending_id, 106.0)
	if preview_icon != null:
		preview_icon.name = "OnboardingClassPreviewIcon"
		preview_row.add_child(preview_icon)
	var preview_copy := VBoxContainer.new()
	preview_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_copy.add_theme_constant_override("separation", 3)
	preview_row.add_child(preview_copy)
	preview_copy.add_child(host.label(t("ONB_CLASS_PREVIEW", "PRÉVIA DO ARQUÉTIPO"), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var preview_name := host.label(localized_class_field(pending_definition, "name", t("ONB_CLASS_NONE", "NENHUMA CLASSE SELECIONADA")), UIDesignSystem.FONT_BODY, host.GOLD if not pending_definition.is_empty() else host.INK)
	preview_name.name = "OnboardingClassPreviewName"
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_copy.add_child(preview_name)
	var preview_primary := t("ONB_CLASS_ATTRIBUTE", "ATRIBUTO · %s", [localized_class_field(pending_definition, "primary_name", t("ONB_CLASS_CHOOSE_BELOW", "ESCOLHA UM ARQUÉTIPO ABAIXO"))])
	preview_copy.add_child(host.label(preview_primary, UIDesignSystem.FONT_CAPTION, host.LIME if not pending_definition.is_empty() else host.MUTED))
	if not pending_definition.is_empty():
		var preview_route := host.label(t("ONB_CLASS_STYLE", "ESTILO · %s", [localized_class_field(pending_definition, "route_style", t("ONB_CLASS_FLEXIBLE", "CONTRATO FLEXÍVEL"))]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		preview_route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_copy.add_child(preview_route)
	for definition in ClassRulesScript.DEFINITIONS:
		var class_id := str(definition.id)
		var selected := class_id == pending_id
		var class_color := {"warrant_breaker": host.CORAL, "orbit_gunslinger": host.GOLD, "contract_hacker": host.CYAN}.get(class_id, host.CYAN) as Color
		var card := choice_card(host, localized_class_field(definition, "name"), t("ONB_CLASS_ATTRIBUTE", "ATRIBUTO · %s", [localized_class_field(definition, "primary_name")]), localized_class_field(definition, "tagline"), selected, class_color, "", class_id)
		card.name = "OnboardingClass_%s" % class_id
		var choose := card.get_meta("action") as Button
		choose.name = "OnboardingClassAction_%s" % class_id
		choose.pressed.connect(func():
			var scroll := stack.get_parent() as ScrollContainer
			host.onboarding_scroll_position = scroll.scroll_vertical
			host.class_draft = class_id
			host.call("render")
		)
		stack.add_child(card)
	if not pending_definition.is_empty():
		var mechanics := host.panel(VBoxContainer.new(), Color("#111d3a"), 14, 11)
		mechanics.name = "OnboardingClassMechanics"
		stack.add_child(mechanics)
		var mechanics_copy := mechanics.get_child(0) as VBoxContainer
		mechanics_copy.add_theme_constant_override("separation", 3)
		mechanics_copy.add_child(host.label(t("ONB_CLASS_PROVISIONAL", "IDENTIDADE DE CLASSE · MECÂNICA ATIVA"), UIDesignSystem.FONT_CAPTION, host.LIME))
		var flavor := host.label(localized_class_field(pending_definition, "flavor"), UIDesignSystem.FONT_CAPTION, host.MUTED)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mechanics_copy.add_child(flavor)
		var specialization := host.label(t("ONB_CLASS_SPECIALIZATION", "ESPECIALIZAÇÃO · %s", [ClassRulesScript.specialization_text(pending_definition)]), UIDesignSystem.FONT_CAPTION, host.GOLD)
		specialization.name = "OnboardingClassSpecialization"
		specialization.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mechanics_copy.add_child(specialization)
	var confirm := host.primary_action(t("ONB_CLASS_CONFIRM", "CONFIRMAR CLASSE"), host.LIME)
	confirm.name = "OnboardingClassConfirm"
	confirm.disabled = pending_id.is_empty()
	confirm.pressed.connect(func():
		var selected := host.class_draft
		host.class_draft = ""
		host.onboarding_scroll_position = 0
		state.select_class(selected)
	)
	var content := stack.get_parent().get_parent() as VBoxContainer
	content.add_child(confirm)


static func build_appearance(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, t("ONB_APPEARANCE_TITLE", "PERSONALIZE O CAÇADOR"), t("ONB_APPEARANCE_DESCRIPTION", "Estas escolhas são visuais e podem combinar-se livremente sem alterar o poder."))
	if not AppearanceRulesScript.is_complete(host.appearance_draft):
		host.appearance_draft = AppearanceRulesScript.default_appearance()
	var profile: Dictionary = state.player.duplicate(true)
	profile.appearance = host.appearance_draft.duplicate(true)
	var preview_panel := host.illustrated_panel(VBoxContainer.new(), 13)
	preview_panel.name = "OnboardingAppearancePreview"
	stack.add_child(preview_panel)
	var preview_copy := host.illustrated_panel_content(preview_panel) as VBoxContainer
	preview_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_copy.add_child(host.character_portrait("hunter", 178.0, profile))
	preview_copy.add_child(host.center_label(SpeciesRulesScript.species_name_for(str(state.player.species_id)), UIDesignSystem.FONT_BODY, host.GOLD))
	for category in AppearanceRulesScript.CATEGORIES:
		var selector := host.panel(HBoxContainer.new(), Color("#0d1730"), 12, 8)
		selector.name = "OnboardingAppearance_%s" % category
		stack.add_child(selector)
		var row := selector.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", 8)
		var previous := host.action_button("‹", host.CYAN, true)
		previous.custom_minimum_size = Vector2(UIDesignSystem.TOUCH_TARGET_MIN, UIDesignSystem.TOUCH_TARGET_MIN)
		previous.name = "OnboardingAppearancePrevious_%s" % category
		row.add_child(previous)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		copy.add_child(host.center_label(t("APPEARANCE_%s" % category.to_upper(), category.to_upper()), UIDesignSystem.FONT_CAPTION, host.MUTED))
		var option_id := str(host.appearance_draft[category])
		copy.add_child(host.center_label(t("APPEARANCE_OPTION_%s" % option_id.to_upper(), option_id.to_upper()), UIDesignSystem.FONT_CAPTION, host.INK))
		var next := host.action_button("›", host.CYAN, true)
		next.custom_minimum_size = Vector2(UIDesignSystem.TOUCH_TARGET_MIN, UIDesignSystem.TOUCH_TARGET_MIN)
		next.name = "OnboardingAppearanceNext_%s" % category
		row.add_child(next)
		previous.pressed.connect(func():
			host.appearance_draft = AppearanceRulesScript.cycle(host.appearance_draft, category, -1)
			host.call("render")
		)
		next.pressed.connect(func():
			host.appearance_draft = AppearanceRulesScript.cycle(host.appearance_draft, category, 1)
			host.call("render")
		)
	var confirm := host.primary_action(t("ONB_APPEARANCE_CONFIRM", "CONFIRMAR APARÊNCIA"), host.LIME)
	confirm.name = "OnboardingAppearanceConfirm"
	confirm.pressed.connect(func():
		var selected := host.appearance_draft.duplicate(true)
		host.appearance_draft = {}
		host.onboarding_scroll_position = 0
		state.confirm_appearance(selected)
	)
	var content := stack.get_parent().get_parent() as VBoxContainer
	content.add_child(confirm)


static func build_species(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, t("ONB_SPECIES_TITLE", "ESCOLHA A RAÇA"), t("ONB_SPECIES_DESCRIPTION", "A raça define a aparência e a origem do caçador. É uma escolha cosmética: não altera atributos, combate ou progressão."))
	var pending_id := host.species_draft
	var pending_definition := SpeciesRulesScript.get_definition(pending_id)
	var preview := host.illustrated_panel(HBoxContainer.new(), 13)
	preview.name = "OnboardingSpeciesPreview"
	stack.add_child(preview)
	var preview_row := host.illustrated_panel_content(preview) as HBoxContainer
	preview_row.add_theme_constant_override("separation", 13)
	var preview_portrait := host.character_portrait("hunter", 106.0, {"species_id": pending_id})
	preview_portrait.name = "OnboardingSpeciesPreviewPortrait"
	preview_row.add_child(preview_portrait)
	var preview_copy := VBoxContainer.new()
	preview_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_copy.add_theme_constant_override("separation", 3)
	preview_row.add_child(preview_copy)
	preview_copy.add_child(host.label(t("ONB_SPECIES_PREVIEW", "PRÉVIA DO CAÇADOR"), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var preview_name := host.label(localized_species_field(pending_definition, "name", t("ONB_SPECIES_NONE", "NENHUMA RAÇA SELECIONADA")), UIDesignSystem.FONT_BODY, Color(str(pending_definition.get("color", "#f4f2ff"))))
	preview_name.name = "OnboardingSpeciesPreviewName"
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_copy.add_child(preview_name)
	var preview_hint := host.label(localized_species_field(pending_definition, "identity", t("ONB_SPECIES_CHOOSE_BELOW", "TOQUE EM UMA ORIGEM ABAIXO")), UIDesignSystem.FONT_CAPTION, host.MUTED)
	preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_copy.add_child(preview_hint)
	for definition in SpeciesRulesScript.DEFINITIONS:
		var species_id := str(definition.id)
		var selected := species_id == pending_id
		var card := choice_card(host, localized_species_field(definition, "name"), localized_species_field(definition, "identity"), localized_species_field(definition, "tagline"), selected, Color(str(definition.color)), species_id)
		card.name = "OnboardingSpecies_%s" % species_id
		var choose := card.get_meta("action") as Button
		choose.name = "OnboardingSpeciesAction_%s" % species_id
		choose.pressed.connect(func():
			var scroll := stack.get_parent() as ScrollContainer
			host.onboarding_scroll_position = scroll.scroll_vertical
			host.species_draft = species_id
			host.call("render")
		)
		stack.add_child(card)
	var confirm := host.primary_action(t("ONB_SPECIES_CONFIRM", "CONFIRMAR RAÇA"), host.LIME)
	confirm.name = "OnboardingSpeciesConfirm"
	confirm.disabled = pending_id.is_empty()
	confirm.pressed.connect(func():
		var selected := host.species_draft
		host.species_draft = ""
		host.onboarding_scroll_position = 0
		state.select_species(selected)
	)
	var content := stack.get_parent().get_parent() as VBoxContainer
	content.add_child(confirm)


static func build_name(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, t("ONB_NAME_TITLE", "NOME DO CAÇADOR"), t("ONB_NAME_DESCRIPTION", "Este é o nome que aparecerá nos mandados, relatórios e registros da carreira."))
	var identity := host.illustrated_panel(HBoxContainer.new(), 13)
	identity.name = "OnboardingIdentitySummary"
	stack.add_child(identity)
	var identity_row := host.illustrated_panel_content(identity) as HBoxContainer
	identity_row.add_theme_constant_override("separation", 12)
	var portrait: Control = host.call("framed_hunter_portrait", 92.0)
	portrait.name = "OnboardingHunterPortrait"
	identity_row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(copy)
	copy.add_child(host.label(t("ONB_NAME_CLASS", "CLASSE · %s", [ClassRulesScript.class_name_for(str(state.player.class_id))]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	copy.add_child(host.label(t("ONB_NAME_SPECIES", "RAÇA · %s", [SpeciesRulesScript.species_name_for(str(state.player.species_id))]), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var corrections := HBoxContainer.new()
	corrections.add_theme_constant_override("separation", 6)
	copy.add_child(corrections)
	var change_class := host.action_button(t("ONB_NAME_CHANGE_CLASS", "ALTERAR CLASSE"), host.GOLD, true)
	change_class.name = "OnboardingChangeClass"
	change_class.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	change_class.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_class.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	change_class.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	change_class.pressed.connect(func():
		host.onboarding_scroll_position = 0
		state.reopen_onboarding_choice("class")
	)
	corrections.add_child(change_class)
	var change_species := host.action_button(t("ONB_NAME_CHANGE_SPECIES", "ALTERAR RAÇA"), host.CYAN, true)
	change_species.name = "OnboardingChangeSpecies"
	change_species.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	change_species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_species.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	change_species.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	change_species.pressed.connect(func():
		host.onboarding_scroll_position = 0
		state.reopen_onboarding_choice("species")
	)
	corrections.add_child(change_species)
	var change_appearance := host.action_button(t("ONB_NAME_CHANGE_APPEARANCE", "ALTERAR APARÊNCIA"), host.LIME, true)
	change_appearance.name = "OnboardingChangeAppearance"
	change_appearance.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	change_appearance.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	change_appearance.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	change_appearance.pressed.connect(func():
		host.onboarding_scroll_position = 0
		state.reopen_onboarding_choice("appearance")
	)
	copy.add_child(change_appearance)
	var input := LineEdit.new()
	input.name = "OnboardingNameInput"
	input.placeholder_text = t("ONB_NAME_PLACEHOLDER", "3–20 caracteres")
	input.max_length = 20
	input.custom_minimum_size.y = UIDesignSystem.TOUCH_TARGET_MIN
	input.add_theme_font_size_override("font_size", UIDesignSystem.FONT_BODY)
	input.add_theme_stylebox_override("normal", host.bordered_box_style(Color("#0d1730"), 12, host.CYAN, 2))
	stack.add_child(input)
	var hint := host.label(t("ONB_NAME_HINT", "Espaços repetidos serão corrigidos. Símbolos de marcação e controles não são aceitos."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(hint)
	var confirm := host.primary_action(t("ONB_NAME_CONFIRM", "ENTRAR NA GALÁXIA"), host.LIME)
	confirm.name = "OnboardingNameConfirm"
	confirm.disabled = true
	confirm.pressed.connect(func(): state.set_hunter_name(input.text))
	input.text_changed.connect(func(value: String): confirm.disabled = state.normalized_hunter_name(value).is_empty())
	input.text_submitted.connect(func(value: String):
		if not state.normalized_hunter_name(value).is_empty():
			state.set_hunter_name(value)
	)
	stack.add_child(confirm)
	input.call_deferred("grab_focus")


static func section_intro(host: CrookedUIFactory, stack: VBoxContainer, title: String, description: String) -> void:
	stack.add_child(host.scene_title(title))
	stack.add_child(host.readable_caption(description))


static func choice_card(host: CrookedUIFactory, title: String, eyebrow: String, description: String, selected: bool, accent: Color, species_id: String = "", class_id: String = "") -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), Color("#1b3151") if selected else Color("#0d1730"), 16, 14)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	if not species_id.is_empty():
		var species_icon: Control = SpeciesIconScript.new()
		species_icon.name = "OnboardingSpeciesIcon_%s" % species_id
		species_icon.configure(species_id, accent)
		row.add_child(species_icon)
	elif not class_id.is_empty():
		var class_icon := class_reference_icon(host, class_id, 58.0)
		if class_icon != null:
			class_icon.name = "OnboardingClassIcon_%s" % class_id
			row.add_child(class_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(eyebrow, UIDesignSystem.FONT_CAPTION, accent))
	copy.add_child(host.label(title, UIDesignSystem.FONT_BODY, host.GOLD if selected else host.INK))
	var flavor := host.label(description, UIDesignSystem.FONT_CAPTION, host.MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(flavor)
	var action := host.secondary_action(t("ONB_ACTIVE_SELECTION", "ATIVO") if selected else t("COMMON_CHOOSE", "ESCOLHER"), accent)
	action.custom_minimum_size.x = 140
	action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action.disabled = selected
	row.add_child(action)
	card.set_meta("action", action)
	return card


static func enable_touch_drag_scrolling(root: Control) -> void:
	# A ScrollContainer can distinguish a tap from a swipe only when the Controls
	# below it let pointer events propagate. Choice cards used the default STOP
	# filter, so Android delivered the gesture to the card/button but never to the
	# scroller. Interactive descendants stay clickable while PASS lets the parent
	# claim motion beyond scroll_deadzone and cancel the pending button press.
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		if not child is Control:
			continue
		var control := child as Control
		if child is Container or child is BaseButton:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if control.get_child_count() > 0:
			enable_touch_drag_scrolling(control)


static func class_reference_icon(host: CrookedUIFactory, class_id: String, dimension: float) -> Control:
	if class_id.is_empty():
		return null
	return host.class_icon(class_id, dimension)


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRulesScript.text(key, fallback, values)


static func localized_class_field(definition: Dictionary, field: String, fallback: String = "") -> String:
	if definition.is_empty():
		return fallback
	var raw := str(definition.get(field, fallback))
	return t(LocaleRulesScript.content_key("class", str(definition.id), field), raw)


static func localized_species_field(definition: Dictionary, field: String, fallback: String = "") -> String:
	if definition.is_empty():
		return fallback
	var raw := str(definition.get(field, fallback))
	return t(LocaleRulesScript.content_key("species", str(definition.id), field), raw)
