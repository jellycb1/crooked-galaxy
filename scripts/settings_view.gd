class_name SettingsView
extends RefCounted

const StateScript = preload("res://scripts/game_state.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")
const ServerRulesScript = preload("res://scripts/server_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	content.add_theme_constant_override("separation", 14)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	title_row.add_child(titles)
	titles.add_child(host.scene_title(t("SETTINGS_TITLE", "AJUSTES")))
	titles.add_child(host.readable_caption(t("SETTINGS_SUBTITLE", "PREFERÊNCIAS DESTE APARELHO")))
	var back := host.secondary_action(t("COMMON_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func(): host.call("open_frontier_menu"))
	title_row.add_child(back)

	var scroller := TouchScrollContainer.new()
	scroller.name = "SettingsScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroller.add_child(page)
	var intro := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 16, 15)
	intro.name = "SettingsIntro"
	var copy := intro.get_child(0) as VBoxContainer
	copy.add_child(host.label(t("SETTINGS_EXPERIENCE", "EXPERIÊNCIA DE JOGO"), UIDesignSystem.FONT_CAPTION, host.LIME))
	var description := host.label(t("SETTINGS_DESCRIPTION", "Preferências locais e ferramentas deste aparelho. Não alteram recompensas, chances ou progressão."), UIDesignSystem.FONT_CAPTION, host.INK)
	description.name = "SettingsExperienceDescription"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	page.add_child(intro)
	page.add_child(preferences_panel(host, state))


static func preferences_panel(host: CrookedUIFactory, state: StateScript) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.name = "SettingsPanel"
	result.add_theme_constant_override("separation", 12)
	var preferences := VBoxContainer.new()
	preferences.name = "AccessibilityPreferences"
	preferences.add_theme_constant_override("separation", 12)
	result.add_child(preferences)
	preferences.add_child(account_panel(host, state))
	preferences.add_child(language_panel(host, state))
	preferences.add_child(preference_row(host, t("SETTINGS_AUDIO", "ÁUDIO"), t("SETTINGS_AUDIO_DESCRIPTION", "Efeitos de interface e combate"), t("COMMON_ON", "LIGADO") if bool(state.player.get("sound_enabled", true)) else t("COMMON_OFF", "DESLIGADO"), "SoundPreferenceAction", state.toggle_sound))
	preferences.add_child(preference_row(host, t("SETTINGS_MOTION", "MOVIMENTO"), t("SETTINGS_MOTION_DESCRIPTION", "Remove apenas transições decorativas"), t("SETTINGS_REDUCED", "REDUZIDO") if bool(state.player.get("reduced_motion", false)) else t("SETTINGS_FULL", "COMPLETO"), "MotionPreferenceAction", state.toggle_reduced_motion))
	if OS.is_debug_build():
		var danger := host.panel(VBoxContainer.new(), Color("#2b1425"), 16, 14)
		var danger_copy := danger.get_child(0) as VBoxContainer
		danger_copy.add_child(host.label(t("SETTINGS_TEST_AREA", "ÁREA DE TESTE"), UIDesignSystem.FONT_CAPTION, host.CORAL))
		var warning := host.label(t("SETTINGS_RESET_WARNING", "Apaga o progresso local deste aparelho e reinicia o jogo neste dispositivo."), UIDesignSystem.FONT_CAPTION, host.MUTED)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		danger_copy.add_child(warning)
		var reset := host.secondary_action(t("SETTINGS_RESET", "REINICIAR PROGRESSO LOCAL"), host.CORAL)
		reset.name = "ResetProgressAction"
		reset.pressed.connect(func():
			host.reset_transient_navigation()
			state.reset_progress()
		)
		danger_copy.add_child(reset)
		result.add_child(danger)
	return result


static func account_panel(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var card := host.panel(VBoxContainer.new(), Color("#172442"), 16, 14)
	card.name = "SettingsAccountPanel"
	var stack := card.get_child(0) as VBoxContainer
	stack.add_theme_constant_override("separation", 4)
	stack.add_child(host.label(t("SETTINGS_ACCOUNT_TITLE", "CONTA E SERVIDOR"), UIDesignSystem.FONT_CAPTION, host.LIME))
	var server_name := ServerRulesScript.server_name_for(str(state.account.get("server_id", ServerRulesScript.DEFAULT_ID)))
	stack.add_child(host.label(t("SETTINGS_ACCOUNT_LOCAL", "PERFIL LOCAL DE TESTE"), UIDesignSystem.FONT_BODY, host.INK))
	stack.add_child(host.label(t("SETTINGS_ACCOUNT_SCOPE", "%s · ESTE DISPOSITIVO", [server_name.to_upper()]), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var description := host.label(t("SETTINGS_ACCOUNT_DESCRIPTION", "Autoridade do progresso: este dispositivo. Este APK ainda não usa credenciais, nuvem ou sincronização com servidor."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	description.name = "SettingsAccountDescription"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(description)
	var revision := maxi(0, int(state.account.get("local_revision", 0)))
	var revision_label := host.label(t("SETTINGS_ACCOUNT_REVISION", "ESTADO LOCAL · REVISÃO %d · SEM CONFLITOS REMOTOS", [revision]), UIDesignSystem.FONT_CAPTION, host.GOLD)
	revision_label.name = "SettingsAccountRevision"
	revision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(revision_label)
	return card


static func language_panel(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var card := host.panel(VBoxContainer.new(), Color("#101d39"), 16, 14)
	card.name = "SettingsLanguagePanel"
	var stack := card.get_child(0) as VBoxContainer
	stack.add_child(host.label(t("SETTINGS_LANGUAGE", "IDIOMA"), UIDesignSystem.FONT_CAPTION, host.INK))
	stack.add_child(host.label(t("SETTINGS_LANGUAGE_DESCRIPTION", "Idioma da interface neste dispositivo"), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	stack.add_child(row)
	var active_id := str(state.account.get("locale_id", TranslationServer.get_locale().left(2)))
	for locale in LocaleRulesScript.DEFINITIONS:
		if not bool(locale.get("selectable", false)):
			continue
		var locale_id := str(locale.id)
		var action := host.primary_action("%s%s" % ["✓ " if locale_id == active_id else "", str(locale.native_name).to_upper()], host.LIME) if locale_id == active_id else host.secondary_action(str(locale.native_name).to_upper(), host.CYAN)
		action.name = "SettingsLanguage_%s" % locale_id
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.disabled = locale_id == active_id
		action.pressed.connect(func(): state.set_locale(locale_id))
		row.add_child(action)
	return card


static func preference_row(host: CrookedUIFactory, title: String, description: String, value: String, action_name: String, callback: Callable) -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), Color("#101d39"), 16, 14)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(title, UIDesignSystem.FONT_CAPTION, host.INK))
	var description_label := host.label(description, UIDesignSystem.FONT_CAPTION, host.MUTED)
	description_label.name = "%sDescription" % action_name
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description_label)
	var action := host.secondary_action(value, host.CYAN)
	action.name = action_name
	action.custom_minimum_size.x = 128
	action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	action.tooltip_text = description
	action.pressed.connect(callback)
	row.add_child(action)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRulesScript.text(key, fallback, values)
