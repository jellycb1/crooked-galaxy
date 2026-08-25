class_name SettingsView
extends RefCounted

const StateScript = preload("res://scripts/game_state.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	content.add_theme_constant_override("separation", 14)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label(t("SETTINGS_TITLE", "AJUSTES"), 26, host.INK))
	var subtitle := host.label(t("SETTINGS_SUBTITLE", "PREFERÊNCIAS DESTE APARELHO"), 11, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	var back := host.action_button(t("COMMON_BACK", "VOLTAR"), host.CYAN, true)
	back.custom_minimum_size = Vector2(96, 48)
	back.pressed.connect(func(): host.call("open_frontier_menu"))
	title_row.add_child(back)

	var intro := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 14, 13)
	intro.name = "SettingsIntro"
	var copy := intro.get_child(0) as VBoxContainer
	copy.add_child(host.label(t("SETTINGS_EXPERIENCE", "EXPERIÊNCIA DE JOGO"), 15, host.LIME))
	var description := host.label(t("SETTINGS_DESCRIPTION", "Preferências locais e ferramentas deste aparelho. Não alteram recompensas, chances ou progressão."), 12, host.INK)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	content.add_child(intro)
	content.add_child(preferences_panel(host, state))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)


static func preferences_panel(host: CrookedUIFactory, state: StateScript) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.name = "SettingsPanel"
	result.add_theme_constant_override("separation", 8)
	var preferences := VBoxContainer.new()
	preferences.name = "AccessibilityPreferences"
	preferences.add_theme_constant_override("separation", 8)
	result.add_child(preferences)
	preferences.add_child(preference_row(host, t("SETTINGS_AUDIO", "ÁUDIO"), t("SETTINGS_AUDIO_DESCRIPTION", "Efeitos de interface e combate"), t("COMMON_ON", "LIGADO") if bool(state.player.get("sound_enabled", true)) else t("COMMON_OFF", "DESLIGADO"), "SoundPreferenceAction", state.toggle_sound))
	preferences.add_child(preference_row(host, t("SETTINGS_MOTION", "MOVIMENTO"), t("SETTINGS_MOTION_DESCRIPTION", "Remove apenas transições decorativas"), t("SETTINGS_REDUCED", "REDUZIDO") if bool(state.player.get("reduced_motion", false)) else t("SETTINGS_FULL", "COMPLETO"), "MotionPreferenceAction", state.toggle_reduced_motion))
	if OS.is_debug_build():
		var danger := host.panel(VBoxContainer.new(), Color("#2b1425"), 12, 12)
		var danger_copy := danger.get_child(0) as VBoxContainer
		danger_copy.add_child(host.label(t("SETTINGS_TEST_AREA", "ÁREA DE TESTE"), 11, host.CORAL))
		var warning := host.label(t("SETTINGS_RESET_WARNING", "Apaga o progresso local deste aparelho e reinicia o jogo neste dispositivo."), 11, host.MUTED)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		danger_copy.add_child(warning)
		var reset := host.action_button(t("SETTINGS_RESET", "REINICIAR PROGRESSO LOCAL"), host.CORAL, true)
		reset.name = "ResetProgressAction"
		reset.custom_minimum_size = Vector2(0, 48)
		reset.pressed.connect(func():
			host.reset_transient_navigation()
			state.reset_progress()
		)
		danger_copy.add_child(reset)
		result.add_child(danger)
	return result


static func preference_row(host: CrookedUIFactory, title: String, description: String, value: String, action_name: String, callback: Callable) -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), Color("#101d39"), 12, 11)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(title, 13, host.INK))
	copy.add_child(host.label(description, 10, host.MUTED))
	var action := host.action_button(value, host.CYAN, true)
	action.name = action_name
	action.custom_minimum_size = Vector2(118, 48)
	action.add_theme_font_size_override("font_size", 11)
	action.tooltip_text = description
	action.pressed.connect(callback)
	row.add_child(action)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRulesScript.text(key, fallback, values)
