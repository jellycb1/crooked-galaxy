class_name OnboardingView
extends RefCounted

const ClassRulesScript = preload("res://scripts/class_rules.gd")
const SpeciesRulesScript = preload("res://scripts/species_rules.gd")
const SpeciesIconScript = preload("res://scripts/species_icon.gd")
const StateScript = preload("res://scripts/game_state.gd")

const STEP_INDEX := {"login": 1, "class": 2, "species": 3, "name": 4}


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var step := state.onboarding_step()
	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 2)
	content.add_child(brand)
	brand.add_child(host.center_label("CROOKED GALAXY", 27, host.CYAN))
	var progress := host.center_label("REGISTRO DE CAÇADOR · ETAPA %d/4" % int(STEP_INDEX.get(step, 4)), 11, host.GOLD)
	progress.name = "OnboardingProgress"
	brand.add_child(progress)

	var scroll := ScrollContainer.new()
	scroll.name = "OnboardingScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 11)
	scroll.add_child(stack)

	match step:
		"login":
			build_login(host, stack, state)
		"class":
			build_class(host, stack, state)
		"species":
			build_species(host, stack, state)
		"name":
			build_name(host, stack, state)
	if step == "species" and host.onboarding_scroll_position > 0:
		host.call_deferred("restore_onboarding_scroll")


static func build_login(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, "ENTRAR", "A sua carreira começa com uma sessão neste dispositivo.")
	var notice := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 16, 15)
	notice.name = "LocalSessionNotice"
	stack.add_child(notice)
	var copy := notice.get_child(0) as VBoxContainer
	copy.add_child(host.label("SESSÃO LOCAL DE TESTE", 13, host.LIME))
	var explanation := host.label("Ainda não existe servidor de contas. Esta entrada não pede senha, não simula autenticação online e mantém o progresso apenas neste dispositivo.", 12, host.INK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(explanation)
	var future := host.label("A identidade da sessão já está separada da classe, raça e nome para receber uma conta online futuramente.", 11, host.MUTED)
	future.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(future)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	stack.add_child(spacer)
	var enter := host.action_button("ENTRAR NESTE DISPOSITIVO", host.LIME)
	enter.name = "OnboardingLoginAction"
	enter.pressed.connect(state.begin_local_session)
	stack.add_child(enter)


static func build_class(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, "ESCOLHA A CLASSE", "A classe define sua especialização inicial de combate e contratos.")
	var pending_id := host.class_draft
	for definition in ClassRulesScript.DEFINITIONS:
		var class_id := str(definition.id)
		var selected := class_id == pending_id
		var class_color := {"warrant_breaker": host.CORAL, "orbit_gunslinger": host.GOLD, "contract_hacker": host.CYAN}.get(class_id, host.CYAN) as Color
		var card := choice_card(host, str(definition.name), "ATRIBUTO · %s" % str(definition.primary_name), str(definition.tagline), selected, class_color)
		card.name = "OnboardingClass_%s" % class_id
		var choose := card.get_meta("action") as Button
		choose.name = "OnboardingClassAction_%s" % class_id
		choose.pressed.connect(func():
			host.class_draft = class_id
			host.call("render")
		)
		stack.add_child(card)
	var confirm := host.action_button("CONFIRMAR CLASSE", host.LIME)
	confirm.name = "OnboardingClassConfirm"
	confirm.disabled = pending_id.is_empty()
	confirm.pressed.connect(func():
		var selected := host.class_draft
		host.class_draft = ""
		state.select_class(selected)
	)
	stack.add_child(confirm)


static func build_species(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, "ESCOLHA A RAÇA", "A raça define a aparência e a origem do caçador. É uma escolha cosmética: não altera atributos, combate ou progressão.")
	var pending_id := host.species_draft
	var pending_definition := SpeciesRulesScript.get_definition(pending_id)
	var preview := host.panel(HBoxContainer.new(), Color("#162947"), 16, 13)
	preview.name = "OnboardingSpeciesPreview"
	stack.add_child(preview)
	var preview_row := preview.get_child(0) as HBoxContainer
	preview_row.add_theme_constant_override("separation", 13)
	var preview_portrait := host.character_portrait("hunter", 106.0, {"species_id": pending_id})
	preview_portrait.name = "OnboardingSpeciesPreviewPortrait"
	preview_row.add_child(preview_portrait)
	var preview_copy := VBoxContainer.new()
	preview_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_copy.add_theme_constant_override("separation", 3)
	preview_row.add_child(preview_copy)
	preview_copy.add_child(host.label("PRÉVIA DO CAÇADOR", 10, host.CYAN))
	var preview_name := host.label(str(pending_definition.get("name", "NENHUMA RAÇA SELECIONADA")), 17, Color(str(pending_definition.get("color", "#f4f2ff"))))
	preview_name.name = "OnboardingSpeciesPreviewName"
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_copy.add_child(preview_name)
	var preview_hint := host.label(str(pending_definition.get("identity", "TOQUE EM UMA ORIGEM ABAIXO")), 10, host.MUTED)
	preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_copy.add_child(preview_hint)
	for definition in SpeciesRulesScript.DEFINITIONS:
		var species_id := str(definition.id)
		var selected := species_id == pending_id
		var card := choice_card(host, str(definition.name), str(definition.identity), str(definition.tagline), selected, Color(str(definition.color)), species_id)
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
	var confirm := host.action_button("CONFIRMAR RAÇA", host.LIME)
	confirm.name = "OnboardingSpeciesConfirm"
	confirm.disabled = pending_id.is_empty()
	confirm.pressed.connect(func():
		var selected := host.species_draft
		host.species_draft = ""
		state.select_species(selected)
	)
	var content := stack.get_parent().get_parent() as VBoxContainer
	content.add_child(confirm)


static func build_name(host: CrookedUIFactory, stack: VBoxContainer, state: StateScript) -> void:
	section_intro(host, stack, "NOME DO CAÇADOR", "Este é o nome que aparecerá nos mandados, relatórios e registros da carreira.")
	var identity := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 13)
	identity.name = "OnboardingIdentitySummary"
	stack.add_child(identity)
	var identity_row := identity.get_child(0) as HBoxContainer
	identity_row.add_theme_constant_override("separation", 12)
	var portrait: Control = host.call("framed_hunter_portrait", 92.0)
	portrait.name = "OnboardingHunterPortrait"
	identity_row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(copy)
	copy.add_child(host.label("CLASSE · %s" % ClassRulesScript.class_name_for(str(state.player.class_id)), 12, host.GOLD))
	copy.add_child(host.label("RAÇA · %s" % SpeciesRulesScript.species_name_for(str(state.player.species_id)), 12, host.CYAN))
	var corrections := HBoxContainer.new()
	corrections.add_theme_constant_override("separation", 6)
	copy.add_child(corrections)
	var change_class := host.action_button("ALTERAR CLASSE", host.GOLD, true)
	change_class.name = "OnboardingChangeClass"
	change_class.custom_minimum_size = Vector2(0, 48)
	change_class.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_class.add_theme_font_size_override("font_size", 9)
	change_class.pressed.connect(func(): state.reopen_onboarding_choice("class"))
	corrections.add_child(change_class)
	var change_species := host.action_button("ALTERAR RAÇA", host.CYAN, true)
	change_species.name = "OnboardingChangeSpecies"
	change_species.custom_minimum_size = Vector2(0, 48)
	change_species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_species.add_theme_font_size_override("font_size", 9)
	change_species.pressed.connect(func():
		host.onboarding_scroll_position = 0
		state.reopen_onboarding_choice("species")
	)
	corrections.add_child(change_species)
	var input := LineEdit.new()
	input.name = "OnboardingNameInput"
	input.placeholder_text = "3–20 caracteres"
	input.max_length = 20
	input.custom_minimum_size.y = 58
	input.add_theme_font_size_override("font_size", 18)
	input.add_theme_stylebox_override("normal", host.bordered_box_style(Color("#0d1730"), 12, host.CYAN, 2))
	stack.add_child(input)
	var hint := host.label("Espaços repetidos serão corrigidos. Símbolos de marcação e controles não são aceitos.", 11, host.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(hint)
	var confirm := host.action_button("ENTRAR NA GALÁXIA", host.LIME)
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
	stack.add_child(host.label(title, 24, host.INK))
	var subtitle := host.label(description, 13, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(subtitle)


static func choice_card(host: CrookedUIFactory, title: String, eyebrow: String, description: String, selected: bool, accent: Color, species_id: String = "") -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), Color("#1b3151") if selected else Color("#0d1730"), 14, 12)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	if not species_id.is_empty():
		var species_icon: Control = SpeciesIconScript.new()
		species_icon.name = "OnboardingSpeciesIcon_%s" % species_id
		species_icon.configure(species_id, accent)
		row.add_child(species_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(eyebrow, 10, accent))
	copy.add_child(host.label(title, 15, host.GOLD if selected else host.INK))
	var flavor := host.label(description, 11, host.MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(flavor)
	var action := host.action_button("SELECIONADO" if selected else "ESCOLHER", accent, true)
	action.custom_minimum_size = Vector2(104, 52)
	action.add_theme_font_size_override("font_size", 10)
	action.disabled = selected
	row.add_child(action)
	card.set_meta("action", action)
	return card
