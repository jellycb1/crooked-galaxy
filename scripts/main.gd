extends "res://scripts/ui_factory.gd"

const SpaceBackdropScript = preload("res://scripts/space_backdrop.gd")
const EnvironmentBackdropScript = preload("res://scripts/environment_backdrop.gd")
const CombatBackdropScript = preload("res://scripts/combat_backdrop.gd")
const SoundFXScript = preload("res://scripts/sound_fx.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const ClassRulesScript = preload("res://scripts/class_rules.gd")
const EnemyProfileRulesScript = preload("res://scripts/enemy_profile_rules.gd")
const CareerRulesScript = preload("res://scripts/career_rules.gd")
const ArsenalView = preload("res://scripts/arsenal_view.gd")
const RewardViewScript = preload("res://scripts/reward_view.gd")
const CareerViewScript = preload("res://scripts/career_view.gd")
const AttributesViewScript = preload("res://scripts/attributes_view.gd")
const ClassesViewScript = preload("res://scripts/classes_view.gd")
const MarketViewScript = preload("res://scripts/market_view.gd")
const HangarViewScript = preload("res://scripts/hangar_view.gd")
const SettingsViewScript = preload("res://scripts/settings_view.gd")
const ChallengeViewScript = preload("res://scripts/challenge_view.gd")
const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const OnboardingViewScript = preload("res://scripts/onboarding_view.gd")
const ServerRulesScript = preload("res://scripts/server_rules.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")
const PlanetIconScript = preload("res://scripts/planet_icon.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const HuntChoiceIconScript = preload("res://scripts/hunt_choice_icon.gd")
const HubDestinationIconScript = preload("res://scripts/hub_destination_icon.gd")
const NavigationDockScript = preload("res://scripts/navigation_dock.gd")

var body: VBoxContainer
var content: VBoxContainer
var navigation_dock: PanelContainer
var hunt_timer: Timer
var combat_timer: Timer
var victory_timer: Timer
var last_combat_message := ""
var combat_fast := false
var sound_fx: Node
var previous_phase := -1
var space_backdrop: Control
var environment_backdrop: Control
var safe_container: MarginContainer
var render_generation := 0
var lifecycle_suspensions: Dictionary = {}
var timed_actions_suspended := false
var suspended_victory_time_left := 0.0


func _ready() -> void:
	build_shell()
	GameState.changed.connect(render)
	get_tree().set_auto_accept_quit(false)
	render()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if try_save_before_quit():
			get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_android_back_request()
	elif what == NOTIFICATION_RESIZED and is_node_ready():
		call_deferred("apply_safe_area")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_lifecycle_suspension("focus", true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_lifecycle_suspension("focus", false)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		GameState.save_game()
		set_lifecycle_suspension("application", true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_lifecycle_suspension("application", false)
		if not GameState.save_warning.is_empty():
			call_deferred("render")


func android_back_action() -> String:
	if GameState.requires_onboarding():
		return "quit" if GameState.onboarding_step() == "login" else "guard_onboarding"
	if GameState.phase == GameState.Phase.BOARD:
		if view_mode == "market" or view_mode == "hangar" or view_mode == "career" or view_mode == "settings" or view_mode == "challenges":
			return "menu"
		if view_mode != "board":
			return "board"
		return "board_bounties" if board_section != "bounties" else "quit"
	if GameState.phase == GameState.Phase.BRIEFING:
		return "cancel_briefing"
	return "guard_contract"


func handle_android_back_request() -> void:
	match android_back_action():
		"menu":
			open_frontier_menu()
		"board":
			view_mode = "board"
			board_section = "bounties"
			render()
		"board_bounties":
			board_section = "bounties"
			render()
		"cancel_briefing":
			GameState.cancel_briefing()
		"quit":
			if try_save_before_quit():
				get_tree().quit()
		# Timed hunts, incidents, combat, victory, rewards, and finales all have
		# explicit safe actions. Consume Back rather than turning it into an
		# accidental abandon/claim while the contract owns the screen.
		"guard_contract":
			pass
		"guard_onboarding":
			pass


func try_save_before_quit() -> bool:
	if GameState.save_game():
		return true
	# A failed local write explicitly promises that progress remains in memory.
	# Keep that promise for desktop close and Android Back alike.
	render()
	return false


func set_lifecycle_suspension(reason: String, suspended: bool) -> void:
	if suspended:
		lifecycle_suspensions[reason] = true
	else:
		lifecycle_suspensions.erase(reason)
	var should_suspend := not lifecycle_suspensions.is_empty()
	if should_suspend == timed_actions_suspended:
		return
	timed_actions_suspended = should_suspend
	if timed_actions_suspended:
		if hunt_timer != null:
			hunt_timer.stop()
		if combat_timer != null:
			combat_timer.stop()
		if victory_timer != null and not victory_timer.is_stopped():
			suspended_victory_time_left = maxf(0.05, victory_timer.time_left)
			victory_timer.stop()
		return
	if GameState.phase == GameState.Phase.HUNT:
		on_hunt_timer()
		if GameState.phase == GameState.Phase.HUNT and hunt_timer != null:
			hunt_timer.start()
	if GameState.phase == GameState.Phase.COMBAT and combat_timer != null:
		combat_timer.start()
	elif GameState.phase == GameState.Phase.VICTORY and victory_timer != null:
		victory_timer.start(suspended_victory_time_left if suspended_victory_time_left > 0.0 else victory_timer.wait_time)
		suspended_victory_time_left = 0.0


func build_shell() -> void:
	space_backdrop = SpaceBackdropScript.new()
	space_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(space_backdrop)
	environment_backdrop = EnvironmentBackdropScript.new()
	add_child(environment_backdrop)
	sound_fx = SoundFXScript.new()
	add_child(sound_fx)

	safe_container = MarginContainer.new()
	safe_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe_container)
	apply_safe_area()

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	safe_container.add_child(body)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	body.add_child(content)
	navigation_dock = NavigationDockScript.new()
	navigation_dock.destination_selected.connect(on_primary_navigation)
	body.add_child(navigation_dock)

	combat_timer = Timer.new()
	combat_timer.wait_time = 0.72
	combat_timer.timeout.connect(on_combat_timer)
	add_child(combat_timer)
	victory_timer = Timer.new()
	victory_timer.one_shot = true
	victory_timer.wait_time = 2.8
	victory_timer.timeout.connect(GameState.open_reward)
	add_child(victory_timer)

	hunt_timer = Timer.new()
	hunt_timer.wait_time = 0.1
	hunt_timer.timeout.connect(on_hunt_timer)
	add_child(hunt_timer)


func apply_safe_area() -> void:
	if not safe_container:
		return
	var viewport_size := get_viewport_rect().size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_rect := Rect2(DisplayServer.get_display_safe_area())
	var margins := CoreRules.safe_content_margins(viewport_size, screen_size, safe_rect)
	safe_container.add_theme_constant_override("margin_left", roundi(margins.x))
	safe_container.add_theme_constant_override("margin_top", roundi(margins.y))
	safe_container.add_theme_constant_override("margin_right", roundi(margins.z))
	safe_container.add_theme_constant_override("margin_bottom", roundi(margins.w))


func render() -> void:
	var previous_focus_name := ""
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and content != null and content.is_ancestor_of(focus_owner):
		previous_focus_name = str(focus_owner.name)
	render_generation += 1
	var current_generation := render_generation
	if space_backdrop:
		space_backdrop.planet_id = str(GameState.player.get("current_planet_id", ContentDB.PLANET.id))
	if environment_backdrop:
		environment_backdrop.show_context(environment_context(), str(GameState.player.get("current_planet_id", ContentDB.PLANET.id)))
	if sound_fx:
		sound_fx.enabled = bool(GameState.player.get("sound_enabled", true))
	var phase_changed := previous_phase >= 0 and previous_phase != GameState.phase
	if phase_changed and GameState.phase == GameState.Phase.COMBAT:
		last_combat_message = ""
	if phase_changed and sound_fx:
		match GameState.phase:
			GameState.Phase.HUNT:
				sound_fx.play_accept()
			GameState.Phase.VICTORY:
				sound_fx.play_victory()
			GameState.Phase.REWARD:
				sound_fx.play_reward(str(GameState.pending_loot.get("rarity", "Comum")))
			GameState.Phase.HUNT_EVENT:
				sound_fx.play("accept", 0.72)
			GameState.Phase.CHAPTER_COMPLETE:
				sound_fx.play_victory()
	previous_phase = GameState.phase
	# Preserve the career position before removing earlier siblings changes the
	# old scroll viewport and emits a misleading clamped value during teardown.
	var old_career_scroll := content.find_child("CareerScroll", false, false) as ScrollContainer
	if old_career_scroll != null:
		# A section change intentionally starts its independent list at the top.
		# Otherwise teardown would overwrite the reset with the previous tab's offset.
		career_scroll_position = 0 if career_section_switch_pending else old_career_scroll.scroll_vertical
		old_career_scroll.get_v_scroll_bar().set_block_signals(true)
		content.remove_child(old_career_scroll)
		old_career_scroll.queue_free()
	var old_onboarding_scroll := content.find_child("OnboardingScroll", false, false) as ScrollContainer
	if old_onboarding_scroll != null:
		onboarding_scroll_position = old_onboarding_scroll.scroll_vertical
		old_onboarding_scroll.get_v_scroll_bar().set_block_signals(true)
		content.remove_child(old_onboarding_scroll)
		old_onboarding_scroll.queue_free()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	navigation_dock.hide_and_clear()
	content.add_theme_constant_override("separation", 16)
	build_header()
	if not GameState.save_warning.is_empty():
		content.add_child(save_warning_banner())
	if GameState.save_recovery_required:
		combat_timer.stop()
		victory_timer.stop()
		call_deferred("restore_action_focus", previous_focus_name, current_generation)
		return
	if GameState.requires_onboarding():
		# The recovery surface above must retain precedence when no trustworthy
		# identity can be read. Ordinary incomplete profiles continue here.
		for child in content.get_children():
			content.remove_child(child)
			child.queue_free()
		combat_timer.stop()
		victory_timer.stop()
		hunt_timer.stop()
		OnboardingViewScript.build(self, content, GameState)
		call_deferred("restore_action_focus", previous_focus_name, current_generation)
		return
	match GameState.phase:
		GameState.Phase.BOARD:
			if view_mode == "arsenal":
				build_arsenal()
			elif view_mode == "galaxy":
				build_galaxy_map()
			elif view_mode == "career":
				build_career()
			elif view_mode == "attributes":
				build_attributes()
			elif view_mode == "classes":
				build_classes()
			elif view_mode == "market":
				build_market()
			elif view_mode == "hangar":
				build_hangar()
			elif view_mode == "settings":
				SettingsViewScript.build(self, content, GameState)
			elif view_mode == "challenges":
				ChallengeViewScript.build(self, content, GameState)
			else:
				build_board()
		GameState.Phase.HUNT:
			build_hunt()
		GameState.Phase.COMBAT:
			build_combat()
		GameState.Phase.REWARD:
			build_reward()
		GameState.Phase.VICTORY:
			build_victory()
		GameState.Phase.BRIEFING:
			build_briefing()
		GameState.Phase.HUNT_EVENT:
			build_hunt_event()
		GameState.Phase.CHAPTER_COMPLETE:
			build_chapter_complete()
	update_primary_navigation()
	if GameState.phase == GameState.Phase.COMBAT and not timed_actions_suspended:
		if combat_timer.is_stopped():
			combat_timer.start()
	else:
		combat_timer.stop()
	if GameState.phase == GameState.Phase.VICTORY and not timed_actions_suspended:
		if victory_timer.is_stopped():
			victory_timer.start()
	else:
		victory_timer.stop()
	if GameState.phase == GameState.Phase.HUNT and not timed_actions_suspended:
		if hunt_timer.is_stopped():
			hunt_timer.start()
	else:
		hunt_timer.stop()
	call_deferred("restore_action_focus", previous_focus_name, current_generation)


func restore_onboarding_scroll(expected_generation: int) -> void:
	# The factory rebuilds the onboarding tree when a draft changes. Wait for the
	# new responsive layout with an owned one-shot timer. Because the timer belongs
	# to this scene, teardown cancels it instead of resuming a freed script instance.
	if expected_generation != render_generation:
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.001
	add_child(timer)
	timer.timeout.connect(Callable(self, "apply_onboarding_scroll").bind(expected_generation))
	timer.timeout.connect(timer.queue_free)
	timer.start()


func apply_onboarding_scroll(expected_generation: int) -> void:
	if expected_generation != render_generation:
		return
	var scroll := content.find_child("OnboardingScroll", false, false) as ScrollContainer
	if scroll == null or not GameState.requires_onboarding() or not GameState.onboarding_step() in ["class", "species", "appearance"]:
		return
	scroll.scroll_vertical = onboarding_scroll_position
	onboarding_scroll_position = scroll.scroll_vertical


func on_primary_navigation(destination_id: String) -> void:
	attribute_draft = {}
	class_draft = ""
	match destination_id:
		"contracts":
			view_mode = "board"
			board_section = "bounties"
		"arsenal":
			view_mode = "arsenal"
			arsenal_section = "equipped"
		"hunter":
			view_mode = "attributes"
		"galaxy":
			view_mode = "galaxy"
		"menu":
			view_mode = "board"
			board_section = "destinations"
	if sound_fx:
		sound_fx.play_accept()
	render()


func open_frontier_menu() -> void:
	view_mode = "board"
	board_section = "destinations"
	render()


func update_primary_navigation() -> void:
	if GameState.phase != GameState.Phase.BOARD or GameState.save_recovery_required:
		navigation_dock.hide_and_clear()
		return
	var active_id := "contracts"
	if view_mode == "arsenal":
		active_id = "arsenal"
	elif view_mode == "attributes" or view_mode == "classes":
		active_id = "hunter"
	elif view_mode == "galaxy":
		active_id = "galaxy"
	elif view_mode == "market" or view_mode == "hangar" or view_mode == "career" or view_mode == "settings" or view_mode == "challenges" or board_section == "destinations":
		active_id = "menu"
	var labels := {}
	var badges := {}
	var available_points := int(GameState.player.get("stat_points", 0))
	if str(GameState.player.get("class_id", "")).is_empty():
		labels.hunter = t("NAV_CLASS", "CLASSE")
		badges.hunter = 1
	elif available_points > 0:
		labels.hunter = t("NAV_STATUS", "STATUS")
		badges.hunter = available_points
	var equipped_receipt := GameState.last_notice_context == "reward_equipped"
	var scrap := int(GameState.player.get("scrap", 0))
	var cheapest_calibration := mini(CoreRules.equipment_upgrade_cost(GameState.player.weapon), CoreRules.equipment_upgrade_cost(GameState.player.armor))
	if equipped_receipt and scrap >= cheapest_calibration:
		labels.arsenal = t("NAV_TEST", "TESTAR")
		badges.arsenal = 1
	var ready_rewards := GameState.career_rewards_ready()
	if ready_rewards > 0:
		badges.menu = ready_rewards
	navigation_dock.configure(active_id, labels, badges)


func environment_context() -> String:
	if GameState.requires_onboarding():
		return "world"
	if GameState.phase == GameState.Phase.BOARD:
		if view_mode == "arsenal":
			return "workshop"
		if view_mode == "market":
			return "workshop"
		if view_mode == "hangar":
			return "workshop"
		if view_mode == "settings":
			return "world"
		if view_mode == "challenges":
			return "combat"
		if view_mode == "galaxy" or view_mode == "career" or view_mode == "attributes" or view_mode == "classes":
			return "world"
	if GameState.phase == GameState.Phase.COMBAT or GameState.phase == GameState.Phase.VICTORY:
		return "combat"
	return "contracts"


func restore_action_focus(previous_focus_name: String, expected_generation: int) -> void:
	if expected_generation != render_generation or content == null:
		return
	var current := get_viewport().gui_get_focus_owner()
	if current is Button and content.is_ancestor_of(current) and current.visible and not current.disabled:
		return
	var fallback: Button = null
	for candidate in content.find_children("*", "Button", true, false):
		var button := candidate as Button
		if not button.visible or button.disabled or button.focus_mode == Control.FOCUS_NONE:
			continue
		if fallback == null:
			fallback = button
		if not previous_focus_name.is_empty() and str(button.name) == previous_focus_name:
			button.grab_focus()
			return
	if fallback != null:
		fallback.grab_focus()


func build_header() -> void:
	if GameState.phase == GameState.Phase.BOARD and view_mode == "attributes":
		build_character_header()
		return
	var planet := active_planet()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", 26, CYAN))
	var location_row := HBoxContainer.new()
	location_row.add_theme_constant_override("separation", 10)
	identity.add_child(location_row)
	var location := label(localized_content_field("planet", planet, "name").to_upper(), 13, Color(str(planet.accent)))
	location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_row.add_child(location)
	var server_short := ServerRulesScript.short_name_for(str(GameState.account.get("server_id", "")))
	var build_version := label("%s · v%s" % [server_short, str(ProjectSettings.get_setting("application/config/version", "dev"))], 11, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	build_version.name = "BuildVersion"
	location_row.add_child(build_version)

	var character_badge := Button.new()
	character_badge.name = "HeaderCharacterAction"
	character_badge.custom_minimum_size = Vector2(124, 60)
	character_badge.focus_mode = Control.FOCUS_ALL
	character_badge.tooltip_text = t("HEADER_HUNTER_TOOLTIP", "Abrir classe e atributos")
	character_badge.add_theme_stylebox_override("normal", box_style(PANEL_LIGHT, 14))
	character_badge.add_theme_stylebox_override("hover", bordered_box_style(Color("#213660"), 14, CYAN, 2))
	character_badge.add_theme_stylebox_override("pressed", bordered_box_style(Color("#0c1835"), 14, CYAN, 2))
	character_badge.add_theme_stylebox_override("focus", bordered_box_style(Color("#16284d"), 14, GOLD, 3))
	character_badge.pressed.connect(func():
		attribute_draft = {}
		view_mode = "attributes"
		render()
	)
	top.add_child(character_badge)
	var badge_margin := MarginContainer.new()
	badge_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		badge_margin.add_theme_constant_override("margin_%s" % side, 6)
	badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_badge.add_child(badge_margin)
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 5)
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_margin.add_child(badge_row)
	var header_portrait := framed_hunter_portrait(42)
	header_portrait.name = "HeaderHunterPortrait"
	badge_row.add_child(header_portrait)
	var badge_copy := VBoxContainer.new()
	badge_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_copy)
	var hunter_name := str(GameState.player.get("hunter_name", ""))
	if not hunter_name.is_empty():
		badge_copy.add_child(label(hunter_name.to_upper(), 9, CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	badge_copy.add_child(label(t("HEADER_LEVEL", "NÍVEL %d", [int(GameState.player.level)]), 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	badge_copy.add_child(label(t("HEADER_POWER", "PODER %d", [CoreRules.player_power(GameState.player)]), 11, INK, HORIZONTAL_ALIGNMENT_CENTER))

	var ledger := panel(HBoxContainer.new(), Color("#09132a"), 9, 6)
	ledger.name = "HeaderResourceStrip"
	var stats := ledger.get_child(0) as HBoxContainer
	stats.add_theme_constant_override("separation", 4)
	stats.add_child(header_resource_cell("HeaderCredits", t("RESOURCE_CREDITS", "CRÉDITOS"), str(GameState.player.credits), GOLD))
	stats.add_child(header_resource_cell("HeaderScrap", t("RESOURCE_SCRAP", "SUCATA"), str(GameState.player.get("scrap", 0)), CORAL))
	stats.add_child(header_resource_cell("HeaderReputation", t("RESOURCE_RANK", "RANK"), str(int(GameState.player.reputation) + 1), LIME))
	stats.add_child(header_resource_cell("HeaderWins", t("RESOURCE_WINS", "VITÓRIAS"), str(GameState.player.wins), CYAN))
	content.add_child(ledger)


func header_resource_cell(node_name: String, title: String, value: String, color: Color) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.name = node_name
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 0)
	cell.add_child(label(title, 9, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	cell.add_child(label(value, 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	return cell


func build_character_header() -> void:
	var planet := active_planet()
	var top := HBoxContainer.new()
	top.name = "CharacterCompactHeader"
	top.add_theme_constant_override("separation", 10)
	content.add_child(top)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", 22, CYAN))
	identity.add_child(label(localized_content_field("planet", planet, "name").to_upper(), 11, Color(str(planet.accent))))
	var server_short := ServerRulesScript.short_name_for(str(GameState.account.get("server_id", "")))
	var build_version := label("%s · v%s" % [server_short, str(ProjectSettings.get_setting("application/config/version", "dev"))], 10, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	build_version.name = "BuildVersion"
	build_version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(build_version)


func bordered_box_style(fill: Color, radius: int, border: Color, width: int) -> StyleBoxFlat:
	var style := box_style(fill, radius)
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	return style


func active_planet() -> Dictionary:
	return ContentDB.get_planet(str(GameState.player.get("current_planet_id", ContentDB.PLANET.id)))


func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRulesScript.text(key, fallback, values)


func localized_content_field(prefix: String, definition: Dictionary, field: String) -> String:
	if definition.is_empty():
		return ""
	var raw := str(definition.get(field, ""))
	if prefix == "target" and bool(definition.get("challenge", false)):
		return t(LocaleRulesScript.content_key("rift_stage", str(definition.get("id", "")), field), raw)
	return t(LocaleRulesScript.content_key(prefix, str(definition.get("id", "")), field), raw)


func localized_approach_name(approach_id: String, fallback: String = "CONTRATO BASE") -> String:
	if approach_id.is_empty() and fallback != "CONTRATO BASE":
		return fallback
	for approach in ContentDB.contract_approaches():
		if str(approach.id) == approach_id:
			return localized_content_field("approach", approach, "name")
	return t("CONTRACT_BASE", fallback)


func localized_risk(odds: float) -> String:
	return t("RISK_SAFE", "SEGURO") if odds >= 0.72 else (t("RISK_RISKY", "ARRISCADO") if odds >= 0.42 else t("RISK_BRUTAL", "BRUTAL"))


func localized_recommendation(approach_id: String) -> String:
	var class_id := str(GameState.player.get("class_id", ""))
	var definition := ClassRulesScript.get_definition(class_id)
	if definition.is_empty() or str(definition.get("preferred_approach", "")) != approach_id:
		return t("BRIEFING_BEST_BALANCE", "MELHOR EQUILÍBRIO")
	return t("BRIEFING_SYNERGY", "SINERGIA · %s", [ClassRulesScript.class_name_for(class_id)])


func localized_hunt_choice_field(event_id: String, choice: Dictionary, field: String) -> String:
	var raw := str(choice.get(field, ""))
	var key := "HUNT_EVENT_%s_CHOICE_%s_%s" % [event_id.to_upper(), str(choice.get("id", "")).to_upper(), field.to_upper()]
	return t(key, raw)


func localized_hunt_result(bounty: Dictionary) -> String:
	var choice_id := str(bounty.get("hunt_event_choice_id", ""))
	if choice_id.is_empty():
		return str(bounty.get("hunt_event_result", ""))
	for event in ContentDB.HUNT_EVENTS:
		for choice in event.get("choices", []):
			if str(choice.get("id", "")) == choice_id:
				return localized_hunt_choice_field(str(event.id), choice, "result")
	return str(bounty.get("hunt_event_result", ""))


func localized_combat_action(raw: String, actor: String = "player") -> String:
	if actor == "player":
		var player_index := ContentDB.PLAYER_ATTACKS.find(raw)
		return t("COMBAT_PLAYER_ATTACK_%d" % player_index, raw) if player_index >= 0 else raw
	if bool(GameState.current_bounty.get("challenge", false)):
		var stage := ChallengeRulesScript.get_stage(str(GameState.current_bounty.get("id", "")))
		var stage_attack_index: int = stage.get("attacks", []).find(raw)
		return t("RIFT_STAGE_%s_ATTACK_%d" % [str(stage.get("id", "")).to_upper(), stage_attack_index], raw) if stage_attack_index >= 0 else raw
	var target := ContentDB.get_target(str(GameState.current_bounty.get("id", "")))
	var attacks: Array = target.get("attacks", [])
	var attack_index := attacks.find(raw)
	return t("TARGET_%s_ATTACK_%d" % [str(target.get("id", "")).to_upper(), attack_index], raw) if attack_index >= 0 else raw


func localized_combat_effect(raw: String) -> String:
	var translated_parts: Array[String] = []
	var effect_keys := {"EMBOSCADA": "COMBAT_EFFECT_AMBUSH", "INVASÃO": "COMBAT_EFFECT_BREACH", "INSTABILIDADE": "COMBAT_EFFECT_INSTABILITY", "INTERFERÊNCIA": "COMBAT_EFFECT_INTERFERENCE", "MIRA ORBITAL": "COMBAT_EFFECT_ORBITAL_AIM", "AMORTECEDOR": "COMBAT_EFFECT_DAMPENER", "CASCO DURO": "COMBAT_EFFECT_HARD_SHELL", "RUPTURA": "COMBAT_EFFECT_BREACHING", "SOBRECARGA": "COMBAT_EFFECT_OVERLOAD", "RAJADA TÁTICA": "COMBAT_EFFECT_TACTICAL_BURST", "RAJADA ORBITAL": "COMBAT_EFFECT_ORBITAL_BURST", "CONTRA-ATAQUE": "COMBAT_EFFECT_COUNTER", "EVASÃO TÁTICA": "COMBAT_EFFECT_TACTICAL_EVASION", "EVASÃO ORBITAL": "COMBAT_EFFECT_ORBITAL_EVASION"}
	for part in raw.split(" · "):
		var translated := part
		for prefix in effect_keys:
			if part.begins_with(prefix):
				var suffix := part.trim_prefix(prefix).strip_edges()
				translated = t(str(effect_keys[prefix]), prefix) if suffix.is_empty() else t(str(effect_keys[prefix]), "%s %s" % [prefix, suffix], [suffix])
				break
		translated_parts.append(translated)
	return " · ".join(translated_parts)


func localized_combat_narrative() -> String:
	if GameState.combat_events.is_empty():
		return t("COMBAT_IDLE_NARRATIVE", "Os dois lados avaliam suas escolhas de vida...")
	var player_event: Dictionary = GameState.combat_events[0]
	var narrative := t("COMBAT_PLAYER_HIT", "%s causa %d de dano.", [localized_combat_action(str(player_event.get("action", "")), "player"), int(player_event.get("damage", 0))])
	var enemy_events := GameState.combat_events.filter(func(event): return str(event.get("actor", "")) == "enemy")
	if not enemy_events.is_empty():
		var enemy_event: Dictionary = enemy_events[0]
		narrative += t("COMBAT_ENEMY_HIT", "  %s responde com %d.", [localized_combat_action(str(enemy_event.get("action", "")), "enemy"), int(enemy_event.get("damage", 0))])
	return narrative


func build_board() -> void:
	if board_section == "destinations":
		build_frontier_menu()
		return
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	content.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	title_box.add_child(label(t("BOARD_TITLE", "QUADRO DE PROCURADOS"), 24, INK))
	var subtitle := label(t("BOARD_INTERSTELLAR_SUBTITLE", "Três contratos. Rotas diferentes. Uma nave com manutenção questionável."), 15, MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(subtitle)
	var xp_needed := CoreRules.xp_needed(int(GameState.player.level))
	var xp_text := "XP %d/%d" % [int(GameState.player.xp), xp_needed]
	var xp_label := label(xp_text, 13, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	xp_label.name = "BoardXpStatus"
	xp_label.custom_minimum_size = Vector2(88, 0)
	title_row.add_child(xp_label)
	build_board_bounties()


func build_frontier_menu() -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	content.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	title_box.add_child(label(t("MENU_TITLE", "MENU DA FRONTEIRA"), 24, INK))
	var subtitle := label(t("MENU_SUBTITLE", "Serviços, carreira e preferências do caçador."), 13, MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(subtitle)
	var menu_marker: Control = HubDestinationIconScript.new()
	menu_marker.name = "FrontierMenuMarker"
	menu_marker.configure("menu", CYAN)
	title_row.add_child(menu_marker)

	var section_label := label(t("MENU_SECTION", "SERVIÇOS E PROGRESSO"), 12, CYAN)
	section_label.name = "FrontierMenuSection"
	content.add_child(section_label)

	var hub_grid := GridContainer.new()
	hub_grid.name = "BoardHubGrid"
	hub_grid.columns = 2
	hub_grid.add_theme_constant_override("h_separation", 10)
	hub_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(hub_grid)
	var active_transport := TransportRulesScript.active_transport(GameState.player)
	hub_grid.add_child(board_hub_action(t("MENU_MARKET", "MERCADO"), t("MENU_MARKET_DETAIL", "ARMAS E ARMADURAS"), GOLD, "market", "BoardMarketAction", func():
		view_mode = "market"
		render()
	))
	var hangar_detail := t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO") if active_transport.is_empty() else localized_content_field("transport", active_transport, "name").to_upper()
	hub_grid.add_child(board_hub_action(t("MENU_HANGAR", "HANGAR"), hangar_detail, CYAN, "hangar", "BoardHangarAction", func():
		view_mode = "hangar"
		render()
	))
	var ready_rewards := GameState.career_rewards_ready()
	var career_detail := t("MENU_REWARDS_AVAILABLE", "%d PRÊMIOS DISPONÍVEIS", [ready_rewards]) if ready_rewards > 0 else t("MENU_CAREER_DETAIL", "MARCOS E ARQUIVO")
	hub_grid.add_child(board_hub_action(t("MENU_CAREER", "CARREIRA"), career_detail, LIME, "career", "BoardCareerAction", func():
		view_mode = "career"
		render()
	))
	var challenge_floor := ChallengeRulesScript.progress(GameState.player)
	var challenge_detail := t("MENU_RIFT_LOCKED", "CONCLUA DUSTBALL") if not ChallengeRulesScript.is_unlocked(GameState.player) else (t("MENU_RIFT_COMPLETE", "ARQUIVO CONCLUÍDO") if challenge_floor >= ChallengeRulesScript.STAGES.size() else t("MENU_RIFT_FLOOR", "ANDAR %d DE %d", [challenge_floor + 1, ChallengeRulesScript.STAGES.size()]))
	hub_grid.add_child(board_hub_action(t("MENU_RIFT", "FENDA"), challenge_detail, CORAL, "contracts", "BoardChallengeAction", func():
		view_mode = "challenges"
		render()
	))
	hub_grid.add_child(board_hub_action(t("SETTINGS_TITLE", "AJUSTES"), t("MENU_SETTINGS_DETAIL", "ÁUDIO E MOVIMENTO"), MUTED, "settings", "BoardSettingsAction", func():
		view_mode = "settings"
		render()
	))
	var hub_divider := reference_ui_decoration("hub_divider", 12.0)
	if hub_divider != null:
		content.add_child(hub_divider)
	var status := panel(HBoxContainer.new(), Color("#0d1530"), 14, 11)
	status.name = "BoardDestinationStatus"
	var status_row := status.get_child(0) as HBoxContainer
	status_row.add_theme_constant_override("separation", 10)
	var planet_icon: Control = PlanetIconScript.new()
	planet_icon.name = "FrontierMenuPlanetIcon"
	planet_icon.custom_minimum_size = Vector2(50, 50)
	planet_icon.configure(active_planet(), true, true)
	status_row.add_child(planet_icon)
	var status_box := VBoxContainer.new()
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_box.add_child(label(t("MENU_CURRENT_POSITION", "POSIÇÃO ATUAL"), 10, MUTED))
	status_box.add_child(label(localized_content_field("planet", active_planet(), "name").to_upper(), 14, GOLD))
	var transport_text := t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO") if active_transport.is_empty() else t("MENU_IN_TRANSIT", "EM TRÂNSITO · %s", [localized_content_field("transport", active_transport, "name").to_upper()])
	status_box.add_child(label(transport_text, 10, MUTED))
	status_row.add_child(status_box)
	if not active_transport.is_empty():
		var active_transport_icon := transport_icon(active_transport, 48)
		active_transport_icon.name = "FrontierMenuTransportIcon"
		status_row.add_child(active_transport_icon)
	content.add_child(status)


func build_board_bounties() -> void:
	var recovery_inside_afk := not GameState.afk_report.is_empty() and GameState.last_notice_context == "system_recovery"
	var defeat_report_visible := GameState.last_notice_context == "defeat" and not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true))
	if not GameState.afk_report.is_empty():
		content.add_child(afk_return_banner(recovery_inside_afk))
	if not GameState.last_notice.is_empty() and not recovery_inside_afk and not defeat_report_visible:
		var notice_color := CORAL if not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true)) else LIME
		var dismiss_callback := Callable()
		if GameState.last_notice_context == "system_recovery":
			dismiss_callback = func(): GameState.dismiss_notice("system_recovery")
		var board_notice := notice_banner(GameState.last_notice, notice_color, dismiss_callback)
		board_notice.name = "BoardNotice"
		content.add_child(board_notice)
	elif int(GameState.player.wins) == 0:
		content.add_child(onboarding_banner())
	if not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true)):
		content.add_child(combat_summary_panel(false))
	var streak := int(GameState.player.get("capture_streak", 0))
	var streak_started_inside_receipt := streak == 1 and GameState.last_notice_context.begins_with("reward_")
	if streak > 0 and not streak_started_inside_receipt:
		var next_reward := CoreRules.bounty_streak_reward(100, streak + 1)
		var streak_notice := notice_banner(t("BOARD_STREAK", "EMBALO ×%d · próximo contrato recebe +%d%% de créditos · derrota ou abandono encerra a sequência", [streak, int(next_reward.bonus_percent)]), GOLD)
		streak_notice.name = "StreakNotice"
		content.add_child(streak_notice)
	content.add_child(rank_progress_panel())

	var scroller := ScrollContainer.new()
	scroller.name = "BountyScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroller.add_child(list)
	var board_bounties := MissionRulesScript.board_offers(GameState.player)
	if board_bounties.size() > 1:
		var choice_hint := label(t("BOARD_OFFER_HINT", "A REDE RENOVA OS TRÊS MANDADOS APÓS CADA CAPTURA"), 11, MUTED)
		choice_hint.name = "BoardChoiceHint"
		choice_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(choice_hint)
	for bounty in board_bounties:
		list.add_child(bounty_card(bounty))


func board_hub_action(title: String, detail: String, color: Color, icon_kind: String, node_name: String, callback: Callable) -> Button:
	var button := action_button(title, color, true)
	button.name = node_name
	button.custom_minimum_size = Vector2(0, 82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s · %s" % [title.capitalize(), detail.capitalize()]
	for theme_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(theme_color, Color.TRANSPARENT)
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 8)
	inset.add_theme_constant_override("margin_right", 8)
	inset.add_theme_constant_override("margin_top", 8)
	inset.add_theme_constant_override("margin_bottom", 8)
	button.add_child(inset)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 7)
	inset.add_child(row)
	var icon: Control = HubDestinationIconScript.new()
	icon.name = "BoardHubIcon_%s" % icon_kind
	icon.configure(icon_kind, color)
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	var title_label := label(title, 14, color)
	title_label.name = "BoardHubTitle_%s" % icon_kind
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title_label)
	var detail_label := label(detail, 11, INK)
	detail_label.name = "BoardHubDetail_%s" % icon_kind
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail_label)
	button.pressed.connect(callback)
	return button


func reference_ui_decoration(_key: String, height: float) -> Control:
	var decoration := HSeparator.new()
	decoration.name = "OriginalHubDivider"
	decoration.custom_minimum_size = Vector2(0, height)
	var line := StyleBoxFlat.new()
	line.bg_color = Color(CYAN, 0.34)
	line.content_margin_top = 2.0
	line.content_margin_bottom = 2.0
	decoration.add_theme_stylebox_override("separator", line)
	decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return decoration


func framed_hunter_portrait(dimension: float) -> Control:
	return framed_portrait("hunter", dimension, GameState.player)


func rank_progress_panel() -> PanelContainer:
	var card := panel(VBoxContainer.new(), Color("#0d1530"), 12, 11)
	card.name = "NextWarrantProgress"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	box.add_child(row)
	var level := int(GameState.player.get("level", 1))
	var available := MissionRulesScript.available_planets(level)
	row.add_child(label(t("BOARD_NETWORK_LEVEL", "REDE DE MANDADOS · NÍVEL %d", [level]), 12, CYAN))
	var discovered := label(t("BOARD_DISCOVERED_WORLDS", "%d/%d MUNDOS CONHECIDOS", [available.size(), ContentDB.PLANETS.size()]), 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	discovered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(discovered)
	var next_planet: Dictionary = {}
	for planet in ContentDB.PLANETS:
		if level < int(planet.get("unlock_level", 1)):
			next_planet = planet
			break
	var progress_value := level
	var progress_max := level
	if not next_planet.is_empty():
		progress_max = int(next_planet.unlock_level)
		box.add_child(label(t("BOARD_NEXT_WORLD", "PRÓXIMO DESTINO · %s NO NÍVEL %d", [localized_content_field("planet", next_planet, "name").to_upper(), progress_max]), 10, MUTED))
	else:
		box.add_child(label(t("BOARD_ALL_WORLDS", "TODOS OS DESTINOS ATUAIS ESTÃO NA REDE"), 10, LIME))
	var progress := ProgressBar.new()
	progress.max_value = maxi(1, progress_max)
	progress.value = progress_value
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 5))
	progress.add_theme_stylebox_override("fill", box_style(GOLD, 5))
	box.add_child(progress)
	return card


func build_galaxy_map() -> void:
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(copy)
	copy.add_child(label(t("GALAXY_TITLE", "MAPA GALÁCTICO"), 27, INK))
	copy.add_child(label(t("GALAXY_SUBTITLE", "Mundos conhecidos, distâncias e ocorrências da rede de mandados."), 14, MUTED))
	var back := action_button(t("ACTION_BACK", "VOLTAR"), CYAN, true)
	back.custom_minimum_size = Vector2(120, 48)
	back.pressed.connect(func():
		view_mode = "board"
		render()
	)
	title_row.add_child(back)
	var active_transport := TransportRulesScript.active_transport(GameState.player)
	var transport_status := panel(HBoxContainer.new(), Color("#173356"), 14, 12)
	transport_status.name = "GalaxyTransportStatus"
	var transport_row := transport_status.get_child(0) as HBoxContainer
	transport_row.add_theme_constant_override("separation", 10)
	var transport_copy := VBoxContainer.new()
	transport_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if active_transport.is_empty():
		transport_copy.add_child(label(t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO"), 13, GOLD))
		transport_copy.add_child(label(t("GALAXY_STANDARD_SPEED", "O mapa calcula cada rota na velocidade burocrática padrão."), 11, MUTED))
	else:
		var map_icon := transport_icon(active_transport, 54)
		map_icon.name = "GalaxyTransportIcon"
		transport_row.add_child(map_icon)
		transport_copy.add_child(label(t("MENU_IN_TRANSIT", "EM TRÂNSITO · %s", [localized_content_field("transport", active_transport, "name").to_upper()]), 13, Color(str(active_transport.color))))
		transport_copy.add_child(label(t("GALAXY_TRANSPORT_BONUS", "-%d%% no tempo de viagem de todos os contratos", [roundi(float(active_transport.speed_bonus) * 100.0)]), 11, LIME))
	transport_row.add_child(transport_copy)
	var open_hangar := action_button(t("GALAXY_OPEN_HANGAR", "ABRIR HANGAR"), CYAN, true)
	open_hangar.name = "GalaxyHangarAction"
	open_hangar.custom_minimum_size = Vector2(118, 48)
	open_hangar.add_theme_font_size_override("font_size", 10)
	open_hangar.pressed.connect(func():
		view_mode = "hangar"
		render()
	)
	transport_row.add_child(open_hangar)
	content.add_child(transport_status)
	var route_scroll := ScrollContainer.new()
	route_scroll.name = "GalaxyScroll"
	route_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(route_scroll)
	var route := VBoxContainer.new()
	route.name = "GalaxyRoutes"
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_theme_constant_override("separation", 14)
	route_scroll.add_child(route)
	for planet in ContentDB.PLANETS:
		route.add_child(planet_card(planet))


func planet_card(planet: Dictionary) -> PanelContainer:
	var planet_id := str(planet.id)
	var current := planet_id == str(GameState.player.get("current_planet_id", ContentDB.PLANET.id))
	var unlocked := MissionRulesScript.is_planet_available(planet_id, int(GameState.player.get("level", 1)))
	var visited := GameState.planet_capture_count(planet_id) > 0
	var accent := Color(str(planet.accent))
	var card_fill := Color("#173356") if current else (Color("#121d3d") if visited else (PANEL_LIGHT if unlocked else Color("#0b1228")))
	var card := panel(VBoxContainer.new(), card_fill, 18, 12)
	card.name = "GalaxyPlanet_%s" % planet_id
	if current:
		var current_style := card.get_theme_stylebox("panel") as StyleBoxFlat
		current_style.border_color = accent
		current_style.border_width_left = 2
		current_style.border_width_top = 2
		current_style.border_width_right = 2
		current_style.border_width_bottom = 2
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	box.add_child(heading)
	var destination_icon := PlanetIconScript.new()
	destination_icon.name = "GalaxyPlanetIcon_%s" % planet_id
	destination_icon.configure(planet, unlocked, current)
	heading.add_child(destination_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(names)
	names.add_child(label(localized_content_field("planet", planet, "name").to_upper(), 19, accent if unlocked else MUTED))
	var context_text := localized_content_field("planet", planet, "subtitle")
	var context_color := MUTED
	if unlocked:
		context_text = t("GALAXY_WORLD_RECORD", "ROTA-BASE %s · %d CAPTURAS REGISTADAS", [format_hunt_duration(float(planet.get("travel_duration", 0.0))), GameState.planet_capture_count(planet_id)])
		context_color = LIME if visited else GOLD
		var progress := label(context_text, 11, context_color)
		progress.name = "GalaxyPlanetProgress_%s" % planet_id
		progress.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		names.add_child(progress)
	else:
		context_text = t("GALAXY_LEVEL_REQUIREMENT", "ENTRA NA REDE NO NÍVEL %d", [int(planet.get("unlock_level", 1))])
		var requirement_label := label(context_text, 11, MUTED)
		requirement_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		names.add_child(requirement_label)
	var route_status := t("GALAXY_NETWORK_AVAILABLE", "NA REDE") if unlocked else t("GALAXY_LOCKED", "BLOQUEADO")
	var status := label(route_status, 11, accent if unlocked else CORAL, HORIZONTAL_ALIGNMENT_RIGHT)
	status.custom_minimum_size = Vector2(82, 0)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(status)
	return card


func build_career() -> void:
	CareerViewScript.build(self, content, GameState)


func build_arsenal() -> void:
	ArsenalView.build(self, content, GameState)


func build_attributes() -> void:
	AttributesViewScript.build(self, content, GameState)


func build_classes() -> void:
	ClassesViewScript.build(self, content, GameState)


func build_market() -> void:
	MarketViewScript.build(self, content, GameState)


func build_hangar() -> void:
	HangarViewScript.build(self, content, GameState)


func onboarding_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#173356"), 15, 15)
	banner.name = "FirstHunterOnboarding"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	var class_pending := str(GameState.player.get("class_id", "")).is_empty()
	row.add_child(center_label("!" if class_pending else "1", 30, GOLD if class_pending else CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(t("BOARD_DEFINE_STYLE", "DEFINA SEU ESTILO") if class_pending else t("BOARD_FIRST_JOB", "PRIMEIRO TRABALHO"), 14, GOLD if class_pending else CYAN))
	var message := label(t("BOARD_DEFINE_STYLE_DESCRIPTION", "Escolha como seu caçador prefere resolver contratos. A troca continua gratuita durante os testes.") if class_pending else t("BOARD_FIRST_JOB_DESCRIPTION", "Aceite Gloop. A primeira captura ensina o ciclo e garante seu primeiro loot."), 12 if class_pending else 14, INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(message)
	if class_pending:
		var choose_class := action_button(t("BOARD_CHOOSE_CLASS", "ESCOLHER\nCLASSE"), GOLD, true)
		choose_class.name = "OnboardingClassAction"
		choose_class.custom_minimum_size = Vector2(112, 48)
		choose_class.add_theme_font_size_override("font_size", 10)
		choose_class.pressed.connect(func():
			view_mode = "classes"
			render()
		)
		row.add_child(choose_class)
	return banner


func notice_banner(message: String, color: Color, dismiss_callback := Callable()) -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#16363b"), 14, 13)
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	row.add_child(label("!" if color == CORAL else "✓", 23, color))
	var message_label := label(message, 14, INK)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(message_label)
	if dismiss_callback.is_valid():
		var dismiss := action_button(t("COMMON_OK", "OK"), color, true)
		dismiss.name = "BoardNoticeDismiss"
		dismiss.custom_minimum_size = Vector2(62, 44)
		dismiss.pressed.connect(dismiss_callback)
		row.add_child(dismiss)
	return banner


func save_warning_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#3b1824"), 14, 12)
	banner.name = "SaveWarningBanner"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var message := label(GameState.save_warning, 12, INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message)
	var recovery_required := GameState.save_recovery_required
	var retry := action_button(t("SAVE_START_FRESH", "INICIAR\nNOVO SAVE") if recovery_required else t("SAVE_RETRY", "TENTAR\nNOVAMENTE"), CORAL, true)
	retry.name = "StartFreshSaveAction" if recovery_required else "RetrySaveAction"
	retry.custom_minimum_size = Vector2(112, 48)
	retry.add_theme_font_size_override("font_size", 10)
	retry.pressed.connect(GameState.start_fresh_after_corruption if recovery_required else GameState.retry_save)
	row.add_child(retry)
	return banner


func combat_summary_panel(won: bool) -> PanelContainer:
	var summary := GameState.combat_summary
	var card := panel(VBoxContainer.new(), Color("#16363b") if won else Color("#381c32"), 14, 13)
	card.name = "CombatSummaryVictory" if won else "CombatSummaryDefeat"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var summary_target := ContentDB.get_target(str(summary.get("target_id", "")))
	var summary_target_name := localized_content_field("target", summary_target, "name") if not summary_target.is_empty() else str(summary.get("target_name", t("COMBAT_UNKNOWN_TARGET", "ALVO DESCONHECIDO")))
	var report_title := t("COMBAT_WARRANT_REPORT", "RELATÓRIO DO MANDADO") if won else t("COMBAT_ESCAPE_REPORT", "FUGA: %s", [summary_target_name.to_upper()])
	var report_header := HBoxContainer.new()
	report_header.add_theme_constant_override("separation", 8)
	box.add_child(report_header)
	var verdict := center_label("✓" if won else "×", 18, LIME if won else CORAL)
	verdict.name = "CombatReportVerdict"
	verdict.custom_minimum_size = Vector2(28, 28)
	report_header.add_child(verdict)
	var report_heading := label(report_title, 13, LIME if won else CORAL)
	report_heading.name = "CombatReportTitle"
	report_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	report_header.add_child(report_heading)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 7)
	box.add_child(metrics)
	metrics.add_child(metric_chip(t("COMBAT_ROUNDS", "TURNOS"), str(int(summary.get("rounds", 0))), GOLD))
	metrics.add_child(metric_chip(t("COMBAT_DEALT", "CAUSADO"), str(int(summary.get("damage_dealt", 0))), CYAN))
	metrics.add_child(metric_chip(t("COMBAT_TAKEN", "RECEBIDO"), str(int(summary.get("damage_taken", 0))), CORAL))
	var effects: Array[String] = []
	var report_player := GameState.player.duplicate(true)
	report_player.class_id = str(summary.get("class_id", GameState.player.get("class_id", "")))
	var class_opening_bonus := ClassRulesScript.specialization_opening_damage(report_player, CoreRules.BASE_ATTRIBUTE_VALUE)
	var non_class_opening_bonus := maxi(0, int(summary.get("opening_bonus", 0)) - class_opening_bonus)
	if non_class_opening_bonus > 0:
		effects.append(t("COMBAT_EVIDENCE_AMBUSH", "emboscada +%d", [non_class_opening_bonus]))
	if int(summary.get("damage_prevented", 0)) > 0:
		effects.append(t("COMBAT_EVIDENCE_PREVENTED", "%d dano total amortecido", [int(summary.damage_prevented)]))
	var class_identity := ClassRulesScript.combat_identity_text(report_player, CoreRules.BASE_ATTRIBUTE_VALUE)
	if not class_identity.is_empty():
		effects.append(t("COMBAT_EVIDENCE_CLASS", "especialização %s ativa", [ClassRulesScript.class_name_for(str(report_player.get("class_id", ""))).to_lower()]))
	if int(summary.get("counter_damage", 0)) > 0:
		effects.append(t("COMBAT_EVIDENCE_COUNTER", "%d dano de contra-ataque", [int(summary.counter_damage)]))
	if int(summary.get("follow_up_damage", 0)) > 0:
		effects.append(t("COMBAT_EVIDENCE_FOLLOW_UP", "%d dano de rajada", [int(summary.follow_up_damage)]))
	if int(summary.get("dodges", 0)) > 0:
		effects.append(t("COMBAT_EVIDENCE_DODGES", "%d ataques evitados", [int(summary.dodges)]))
	if int(summary.get("defense_bypassed", 0)) > 0:
		effects.append(t("COMBAT_EVIDENCE_OVERLOAD", "%d defesa total ignorada", [int(summary.defense_bypassed)]))
	var kit_origin := str(summary.get("kit_origin", ""))
	if not kit_origin.is_empty():
		effects.append(t("COMBAT_EVIDENCE_KIT", "kit %s", [localized_content_field("planet", ContentDB.get_planet(kit_origin), "name")]))
	var evidence_text := t("COMBAT_ACTIVE_BUILD", "BUILD ATIVA · %s", [" · ".join(effects)]) if not effects.is_empty() else t("COMBAT_NO_EFFECTS", "SEM EFEITOS TÁTICOS · modificações e kits podem mudar o próximo confronto")
	var evidence := label(evidence_text, 11, GOLD if not effects.is_empty() else MUTED)
	evidence.name = "CombatBuildEvidence"
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(evidence)
	if not won:
		var field_context: Dictionary = summary.get("field_test_context", {})
		var route_diagnosis_text := ""
		if not field_context.is_empty():
			var tested := "%s %d%%" % [localized_approach_name(str(field_context.get("tested_approach_id", "")), str(field_context.get("tested_approach_name", "CONTRATO BASE"))).to_upper(), roundi(float(field_context.get("tested_odds", 0.0)) * 100.0)]
			route_diagnosis_text = t("COMBAT_OVERRIDE_DEFEAT", "OVERRIDE DERROTADO · TESTADA %s → ESCOLHIDA %s · REAVALIE A ROTA", [tested, localized_approach_name(str(field_context.get("chosen_approach_id", "")), str(field_context.get("chosen_approach_name", "CONTRATO BASE"))).to_upper()]) if bool(field_context.get("overridden", false)) else t("COMBAT_TESTED_ROUTE_FAILED", "ROTA TESTADA TAMBÉM FALHOU · %s · REFORCE A BUILD OU REVEJA O INCIDENTE", [tested])
		if not route_diagnosis_text.is_empty():
			var route_diagnosis := label(route_diagnosis_text, 11, GOLD)
			route_diagnosis.name = "DefeatFieldTestDiagnosis"
			route_diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(route_diagnosis)
		var remaining := int(summary.get("enemy_hp_remaining", 0))
		var diagnosis := label(t("COMBAT_DEFEAT_DIAGNOSIS", "O alvo conservou %d HP. Compare as odds, ative um kit ou invista na oficina antes da revanche.", [remaining]), 12, INK)
		diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(diagnosis)
		var lost_streak := int(summary.get("lost_streak", 0))
		if lost_streak > 0:
			var streak_loss := label(t("COMBAT_STREAK_LOST", "EMBALO ×%d ENCERRADO · a próxima captura recomeça em ×1", [lost_streak]), 11, CORAL)
			streak_loss.name = "DefeatStreakLoss"
			streak_loss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(streak_loss)
		var workshop := action_button(t("COMBAT_OPEN_WORKSHOP", "ABRIR OFICINA E TESTAR BUILD"), CYAN, true)
		workshop.name = "DefeatWorkshopAction"
		workshop.custom_minimum_size = Vector2(0, 44)
		workshop.pressed.connect(func():
			arsenal_section = "equipped"
			view_mode = "arsenal"
			render()
		)
		box.add_child(workshop)
	return card


func afk_return_banner(include_recovery := false) -> PanelContainer:
	var report := GameState.afk_report
	var banner := panel(HBoxContainer.new(), Color("#263653"), 15, 14)
	banner.name = "AfkReturnBanner"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	row.add_child(center_label("AFK", 24, CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(t("AFK_PATROL_COMPLETE", "PATRULHA CONCLUÍDA · %s", [format_duration(int(report.minutes))]), 13, CYAN))
	copy.add_child(label(t("AFK_PATROL_REWARD", "+%d créditos · +%d sucata%s", [int(report.credits), int(report.scrap), t("AFK_CAP", " · LIMITE 8H") if bool(report.capped) else ""]), 14, INK))
	if include_recovery:
		var recovery := label(GameState.last_notice, 10, LIME)
		recovery.name = "AfkRecoveryNotice"
		recovery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(recovery)
	var dismiss := action_button(t("COMMON_OK", "OK"), CYAN, true)
	dismiss.name = "AfkDismiss"
	dismiss.custom_minimum_size = Vector2(62, 44)
	dismiss.pressed.connect(func(): GameState.dismiss_afk_report(include_recovery))
	row.add_child(dismiss)
	return banner


func format_duration(minutes: int) -> String:
	if minutes >= 60:
		return "%dh %02dmin" % [floori(float(minutes) / 60.0), minutes % 60]
	return "%dmin" % minutes


func bounty_card(bounty: Dictionary) -> PanelContainer:
	var card := panel(VBoxContainer.new(), PANEL, 18, 20)
	card.name = "BountyCard_%s" % str(bounty.id)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	row.add_child(character_portrait(str(bounty.id), 88))

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var destination := ContentDB.get_planet(str(bounty.get("planet_id", ContentDB.PLANET.id)))
	var role_id := str(bounty.get("mission_role", "standard"))
	var role_text := t("BOARD_ROLE_SAFE", "MANDADO DE ROTINA") if role_id == "safe" else (t("BOARD_ROLE_DANGEROUS", "MANDADO DE ALTO VALOR") if role_id == "dangerous" else t("BOARD_ROLE_STANDARD", "MANDADO PRIORITÁRIO"))
	var mission_role := label("%s · %s" % [role_text, localized_content_field("planet", destination, "name").to_upper()], 11, Color(str(destination.accent)))
	mission_role.name = "BountyRole_%s" % str(bounty.id)
	details.add_child(mission_role)
	var board_reason := str(bounty.get("board_reason", ""))
	var is_primary := str(bounty.get("board_role", "")) == "primary"
	var is_repeat := str(bounty.get("board_role", "")) == "repeat"
	if is_primary:
		board_reason = t("BOARD_FINAL_WARRANT", "MANDADO FINAL") if bool(bounty.get("boss", false)) else t("BOARD_PRIMARY_WARRANT", "MANDADO PRINCIPAL")
	elif is_repeat:
		var repeat_captures := int(GameState.player.get("captures_by_target", {}).get(str(bounty.id), 0))
		var repeat_mastery := CoreRules.target_mastery_level(repeat_captures)
		var repeat_next := CoreRules.target_mastery_next_requirement(repeat_mastery)
		board_reason = t("BOARD_RECURRING_MAX", "CONTRATO RECORRENTE · PERÍCIA MÁX.") if repeat_next < 0 else t("BOARD_MASTERY_ROUTE", "ROTA DE PERÍCIA · FALTAM %d", [maxi(0, repeat_next - repeat_captures)])
	if not board_reason.is_empty():
		var role_color := CORAL if str(bounty.get("board_role", "")) == "primary" else CYAN
		var role := label(board_reason, 12, role_color)
		role.name = "BountyRole_%s" % str(bounty.id)
		details.add_child(role)
	elif bool(bounty.get("boss", false)):
		details.add_child(label(t("BOARD_CHAPTER_BOSS", "CHEFE DO CAPÍTULO"), 12, GOLD))
	details.add_child(label(localized_content_field("target", bounty, "name"), 21, GOLD if bool(bounty.get("boss", false)) else INK))
	details.add_child(label(localized_content_field("target", bounty, "title"), 14, CORAL))
	var captures: Dictionary = GameState.player.get("captures_by_target", {})
	var capture_count := int(captures.get(str(bounty.id), 0))
	var mastery_level := CoreRules.target_mastery_level(capture_count)
	if capture_count > 0:
		var next_requirement := CoreRules.target_mastery_next_requirement(mastery_level)
		var mastery_progress := t("COMMON_MAX", "MÁX.") if next_requirement < 0 else "%d/%d" % [capture_count, next_requirement]
		var mastery_label := label(t("BOARD_MASTERY_PROGRESS", "CAPTURAS %d · PERÍCIA %d/3 · %s", [capture_count, mastery_level, mastery_progress]), 11, LIME)
		mastery_label.name = "BountyMastery_%s" % str(bounty.id)
		details.add_child(mastery_label)
	var mastery_objective := CareerRulesScript.next_mastery_objective(GameState.player, ContentDB.TARGETS)
	if not mastery_objective.is_empty() and str(mastery_objective.target.id) == str(bounty.id):
		var remaining_captures := int(mastery_objective.remaining)
		var route_label := label(t("BOARD_MASTERY_CAPTURES_PLURAL", "ROTA DE PERÍCIA · FALTAM %d CAPTURAS", [remaining_captures]) if remaining_captures != 1 else t("BOARD_MASTERY_CAPTURE_SINGULAR", "ROTA DE PERÍCIA · FALTA 1 CAPTURA"), 11, GOLD)
		route_label.name = "MasteryRoute_%s" % str(bounty.id)
		details.add_child(route_label)
	var description := label(localized_content_field("target", bounty, "description"), 14, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)

	var odds := CoreRules.bounty_odds(GameState.player, bounty)
	var payout := CoreRules.bounty_streak_reward(int(bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	var hunt_duration := TransportRulesScript.effective_mission_duration(GameState.player, bounty)
	footer.add_child(label("◈ %d%s   ✦ %d XP   %s" % [int(payout.credits), t("BOARD_STREAK_SUFFIX", " +EMBALO") if int(payout.bonus_credits) > 0 else "", int(bounty.xp), format_hunt_duration(hunt_duration)], 15, GOLD))
	var risk_text := localized_risk(odds)
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var risk := label("%s · %d%%" % [risk_text, roundi(odds * 100.0)], 14, risk_color, HORIZONTAL_ALIGNMENT_RIGHT)
	risk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(risk)
	var hunt := action_button(t("BOARD_REPEAT_HUNT", "REPETIR CAÇADA") if is_repeat else t("BOARD_ANALYZE_APPROACHES", "ANALISAR ABORDAGENS"), GOLD if is_repeat else CYAN)
	hunt.name = "BountyAction_%s" % str(bounty.id)
	hunt.pressed.connect(func():
		briefing_context = {}
		GameState.select_bounty(bounty)
	)
	box.add_child(hunt)
	if bool(bounty.get("mission_offer", false)):
		var saved := TransportRulesScript.mission_saved_seconds(GameState.player, bounty)
		var timing := t("BOARD_MISSION_TIMING", "VIAGEM %s · PERSEGUIÇÃO %s", [format_hunt_duration(float(bounty.get("travel_duration", 0.0))), format_hunt_duration(float(bounty.get("pursuit_duration", 0.0)))])
		if saved > 0.5:
			timing += t("BOARD_TRANSPORT_SAVING", " · NAVE POUPA %s", [format_hunt_duration(saved)])
		var timing_label := label(timing, 10, LIME if saved > 0.5 else MUTED)
		timing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(timing_label)
	return card


func format_hunt_duration(seconds: float) -> String:
	var rounded := maxi(0, ceili(seconds))
	if rounded >= 60:
		return "%dmin %02ds" % [rounded / 60, rounded % 60]
	return "%ds" % rounded


func build_briefing() -> void:
	var bounty := GameState.current_bounty
	var evaluations := ContractRules.evaluate_approaches(GameState.player, bounty, GameState.offered_approaches)
	var recommended_id := ContractRules.recommended_approach_id(evaluations, str(GameState.player.get("class_id", "")))
	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 18)
	content.add_child(target_row)
	target_row.add_child(character_portrait(str(bounty.id), 82))
	var target_copy := VBoxContainer.new()
	target_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_copy.add_theme_constant_override("separation", 4)
	target_row.add_child(target_copy)
	var active_transport := TransportRulesScript.active_transport(GameState.player)
	if not active_transport.is_empty():
		var briefing_transport := transport_icon(active_transport, 46)
		briefing_transport.name = "BriefingTransportIcon"
		target_row.add_child(briefing_transport)
	target_copy.add_child(label(t("BRIEFING_TITLE", "BRIEFING DO CONTRATO"), 15, CYAN))
	target_copy.add_child(label(localized_content_field("target", bounty, "name"), 26, INK))
	if str(briefing_context.get("target_id", "")) == str(bounty.id) and str(briefing_context.get("approach_id", "")) == recommended_id:
		var tested_context := label(t("BRIEFING_TESTED_BUILD", "BUILD TESTADA · %s · %d%% · RECOMENDAÇÃO CONFIRMADA", [localized_approach_name(str(briefing_context.get("approach_id", "")), str(briefing_context.get("approach_name", "CONTRATO BASE"))).to_upper(), roundi(float(briefing_context.get("odds", 0.0)) * 100.0)]), 11, LIME)
		tested_context.name = "BriefingFieldTestContext"
		target_copy.add_child(tested_context)
	var kit_origin := CoreRules.equipment_set_origin(GameState.player)
	if not kit_origin.is_empty():
		var kit_planet := ContentDB.get_planet(kit_origin)
		target_copy.add_child(label(t("BRIEFING_PLANETARY_KIT", "KIT PLANETÁRIO · %s · +%d PODER · +%d VIDA", [localized_content_field("planet", kit_planet, "name").to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]), 12, GOLD))
	var target_captures := int(GameState.player.get("captures_by_target", {}).get(str(bounty.id), 0))
	var target_mastery := CoreRules.target_mastery_level(target_captures)
	if target_mastery > 0:
		var mastery_label := label(t("BRIEFING_MASTERY", "PERÍCIA %d/3 · +%d%% RARO · +%d%% ÉPICO", [target_mastery, target_mastery * 5, target_mastery * 2]), 12, LIME)
		mastery_label.name = "BriefingMastery"
		target_copy.add_child(mastery_label)
	var flavor := label(t("BRIEFING_FLAVOR", "O alvo é o mesmo. A quantidade de problemas é uma escolha sua."), 14, MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_copy.add_child(flavor)
	var profile_id := EnemyProfileRulesScript.profile_id_for(bounty)
	var profile := EnemyProfileRulesScript.profile_for(bounty)
	if not profile.is_empty():
		var profile_card := panel(VBoxContainer.new(), Color("#14263de8"), 12, 8)
		profile_card.name = "BriefingEnemyProfile"
		var profile_copy := profile_card.get_child(0) as VBoxContainer
		profile_copy.add_child(label(t("ENEMY_PROFILE_%s_TITLE" % profile_id.to_upper(), str(profile.title)), 11, CORAL))
		var profile_summary := label(t("ENEMY_PROFILE_%s_SUMMARY" % profile_id.to_upper(), str(profile.summary)), 10, MUTED)
		profile_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		profile_copy.add_child(profile_summary)
		profile_copy.add_child(label(t("ENEMY_PROFILE_RESPONSE", "RESPOSTA · %s", [t("ENEMY_PROFILE_%s_RESPONSE" % profile_id.to_upper(), str(profile.response))]), 10, LIME))
		content.add_child(profile_card)

	content.add_child(label(t("BRIEFING_COMPARE", "COMPARE E ESCOLHA A ROTA"), 17, GOLD))
	var recommendation_hint := label(t("BRIEFING_HINT", "BUILD mostra sua chance atual; RECOMENDADO equilibra risco, retorno e tempo."), 11, MUTED)
	recommendation_hint.name = "BriefingRecommendationHint"
	recommendation_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(recommendation_hint)
	var scroller := ScrollContainer.new()
	scroller.name = "BriefingScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)
	for index in GameState.offered_approaches.size():
		list.add_child(approach_card(GameState.offered_approaches[index], evaluations[index], recommended_id))
	var cancel := action_button(t("BRIEFING_BACK", "VOLTAR AO QUADRO"), CORAL, true)
	cancel.name = "BriefingCancel"
	cancel.custom_minimum_size = Vector2(0, 48)
	cancel.pressed.connect(func():
		briefing_context = {}
		GameState.cancel_briefing()
	)
	content.add_child(cancel)


func approach_card(approach: Dictionary, evaluation: Dictionary, recommended_id: String) -> PanelContainer:
	var preview: Dictionary = evaluation.preview
	var color := Color(str(approach.color))
	var is_recommended := str(approach.id) == recommended_id
	var card := panel(VBoxContainer.new(), Color("#172744") if is_recommended else PANEL, 13, 10)
	card.name = "ApproachCard_%s" % str(approach.id)
	if is_recommended:
		var recommended_style := box_style(Color("#172744"), 13)
		recommended_style.content_margin_left = 10
		recommended_style.content_margin_right = 10
		recommended_style.content_margin_top = 10
		recommended_style.content_margin_bottom = 10
		recommended_style.border_width_left = 2
		recommended_style.border_width_top = 2
		recommended_style.border_width_right = 2
		recommended_style.border_width_bottom = 2
		recommended_style.border_color = LIME
		card.add_theme_stylebox_override("panel", recommended_style)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var translated_name := localized_content_field("approach", approach, "name")
	var route_name := label(translated_name.to_upper(), 16, color)
	route_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(route_name)
	if is_recommended:
		var recommendation := label(localized_recommendation(str(approach.id)), 9, LIME, HORIZONTAL_ALIGNMENT_RIGHT)
		recommendation.name = "RecommendedApproach_%s" % str(approach.id)
		heading.add_child(recommendation)
	var odds := float(evaluation.odds)
	var risk_text := localized_risk(odds)
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var route_summary := label(t("BRIEFING_RISK_SUMMARY", "%s · RISCO %s", [localized_content_field("approach", approach, "tag"), risk_text]), 11, risk_color)
	route_summary.name = "ApproachBuildRisk_%s" % str(approach.id)
	box.add_child(route_summary)
	var description := label(localized_content_field("approach", approach, "description"), 11, INK)
	description.name = "ApproachDescription_%s" % str(approach.id)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var benefits: Array[String] = []
	if int(evaluation.get("streak_bonus", 0)) > 0:
		benefits.append(t("BRIEFING_STREAK_INCLUDED", "EMBALO +%d%% INCLUÍDO", [int(evaluation.streak_bonus_percent)]))
	var scrap_reward := int(preview.get("scrap_reward", 0))
	if scrap_reward > 0:
		benefits.append(t("BRIEFING_SCRAP_REWARD", "+%d SUCATA NA VITÓRIA", [scrap_reward]))
	if not benefits.is_empty():
		var bonus_summary := label(" · ".join(benefits), 10, GOLD if scrap_reward > 0 else CYAN)
		bonus_summary.name = "ApproachBonusSummary_%s" % str(approach.id)
		box.add_child(bonus_summary)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	box.add_child(metrics)
	var hunt_duration := TransportRulesScript.effective_mission_duration(GameState.player, preview)
	metrics.add_child(briefing_metric_chip(t("BRIEFING_TIME", "TEMPO"), format_hunt_duration(hunt_duration), MUTED, "ApproachTime_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip(t("BRIEFING_BUILD", "BUILD"), "%d%%" % roundi(odds * 100.0), risk_color, "ApproachBuild_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip(t("COMMON_CREDITS", "CRÉDITOS"), "◈ %d" % int(evaluation.credits), GOLD, "ApproachCredits_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip("XP", str(int(preview.xp)), CYAN, "ApproachXp_%s" % str(approach.id)))
	var choose := action_button(t("BRIEFING_CHOOSE", "ESCOLHER · %s", [translated_name.to_upper()]), color)
	choose.custom_minimum_size = Vector2(0, 48)
	choose.add_theme_font_size_override("font_size", 13)
	var approach_id := str(approach.id)
	choose.name = "ChooseApproach_%s" % approach_id
	choose.pressed.connect(func():
		var tested_context := briefing_context.duplicate(true)
		briefing_context = {}
		GameState.choose_approach(approach_id, tested_context)
	)
	box.add_child(choose)
	return card


func briefing_metric_chip(title: String, value: String, color: Color, node_name: String) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0a1025"), 7, 4)
	chip.name = node_name
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.custom_minimum_size = Vector2(0, 32)
	var box := chip.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 0)
	box.add_child(label(title, 9, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, 12, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func field_test_record_label(node_name: String) -> Label:
	var context: Dictionary = GameState.current_bounty.get("field_test_context", {})
	if context.is_empty():
		return null
	var tested_name := localized_approach_name(str(context.get("tested_approach_id", "")), str(context.get("tested_approach_name", "CONTRATO BASE"))).to_upper()
	var chosen_name := localized_approach_name(str(context.get("chosen_approach_id", "")), str(context.get("chosen_approach_name", "CONTRATO BASE"))).to_upper()
	var text_value := t("HUNT_FIELD_TEST_CONFIRMED", "TESTE DE CAMPO CONFIRMADO · %s · %d%%", [tested_name, roundi(float(context.tested_odds) * 100.0)])
	var text_color := LIME
	if bool(context.overridden):
		text_value = t("HUNT_FIELD_TEST_OVERRIDDEN", "ROTA TESTADA SUBSTITUÍDA · %s %d%% → %s", [tested_name, roundi(float(context.tested_odds) * 100.0), chosen_name])
		text_color = GOLD
	var result := center_label(text_value, 13, text_color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.name = node_name
	return result


func build_hunt() -> void:
	var bounty := GameState.current_bounty
	content.add_spacer(false)
	content.add_child(center_label(t("HUNT_TITLE", "CAÇADA EM ANDAMENTO"), 19, CYAN))
	content.add_child(character_portrait(str(bounty.id), 150))
	content.add_child(center_label(localized_content_field("target", bounty, "name"), 30, INK))
	var approach: Dictionary = bounty.get("approach", {})
	if not approach.is_empty():
		content.add_child(center_label(localized_content_field("approach", approach, "name").to_upper(), 16, Color(str(approach.color))))
	var transport := TransportRulesScript.active_transport(GameState.player)
	if not transport.is_empty():
		var transport_row := HBoxContainer.new()
		transport_row.name = "HuntTransportStatus"
		transport_row.alignment = BoxContainer.ALIGNMENT_CENTER
		transport_row.add_theme_constant_override("separation", 8)
		var hunt_transport := transport_icon(transport, 46)
		hunt_transport.name = "HuntTransportIcon"
		transport_row.add_child(hunt_transport)
		transport_row.add_child(label(t("HUNT_TRANSPORT", "%s · -%d%% TEMPO", [localized_content_field("transport", transport, "name"), roundi(float(transport.speed_bonus) * 100.0)]), 12, Color(str(transport.color))))
		content.add_child(transport_row)
	var field_test_record := field_test_record_label("HuntFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	content.add_child(center_label(t("HUNT_FLAVOR", "Seguindo sinais, subornando robôs e fingindo ter um plano."), 16, MUTED))
	if bounty.has("hunt_event_result"):
		content.add_child(notice_banner(localized_hunt_result(bounty), GOLD))

	var progress_value := clampf(GameState.hunt_progress(), 0.0, 1.0)
	var progress_row := HBoxContainer.new()
	progress_row.name = "HuntProgressStatus"
	progress_row.add_theme_constant_override("separation", 8)
	progress_row.add_child(label(t("HUNT_DEPARTURE", "PARTIDA"), 10, MUTED))
	var stage_text := t("HUNT_LEAVING_SECTOR", "SAINDO DO SETOR") if progress_value < 0.25 else (t("HUNT_TRACKING_SIGNAL", "RASTREANDO SINAL") if progress_value < 0.8 else t("HUNT_CONTACT_IMMINENT", "CONTATO IMINENTE"))
	var stage := label("%s · %d%%" % [stage_text, roundi(progress_value * 100.0)], 11, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	stage.name = "HuntProgressStage"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(stage)
	progress_row.add_child(label(t("HUNT_TARGET", "ALVO"), 10, GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	content.add_child(progress_row)
	var progress := ProgressBar.new()
	progress.name = "HuntProgress"
	progress.value = progress_value * 100.0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 24)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 12))
	progress.add_theme_stylebox_override("fill", box_style(CYAN, 12))
	content.add_child(progress)

	var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
	var countdown := center_label(t("HUNT_COUNTDOWN", "ALVO LOCALIZADO EM %ds", [remaining]), 18, GOLD)
	countdown.name = "HuntCountdown"
	content.add_child(countdown)
	content.add_spacer(false)
	var abandon := action_button(abandon_contract_text(), CORAL, true)
	abandon.name = "HuntAbandonAction"
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func build_hunt_event() -> void:
	var event := GameState.hunt_event
	var accent := Color(str(event.get("color", "#ffc857")))
	var event_heading := HBoxContainer.new()
	event_heading.add_theme_constant_override("separation", 8)
	content.add_child(event_heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_heading.add_child(heading_copy)
	heading_copy.add_child(label(t("HUNT_EVENT_TITLE", "IMPREVISTO NA CAÇADA"), 17, CORAL))
	heading_copy.add_child(label(t("HUNT_EVENT_PAUSED", "DECISÃO DE CAMPO · A CAÇA ESTÁ PAUSADA"), 11, MUTED))
	var field_test_record := field_test_record_label("IncidentFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	var incident := panel(HBoxContainer.new(), Color("#18264b"), 18, 16)
	incident.name = "HuntEventDossier"
	content.add_child(incident)
	var incident_row := incident.get_child(0) as HBoxContainer
	incident_row.add_theme_constant_override("separation", 14)
	var symbol := str(event.get("symbol", "?!"))
	var signal_panel := panel(VBoxContainer.new(), Color("#08142d"), 14, 10)
	signal_panel.name = "HuntEventSignal"
	signal_panel.custom_minimum_size = Vector2(86, 86)
	var signal_box := signal_panel.get_child(0) as VBoxContainer
	signal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	signal_box.add_child(center_label(t("HUNT_EVENT_SIGNAL", "SINAL"), 10, MUTED))
	signal_box.add_child(center_label(symbol, 30, accent))
	incident_row.add_child(signal_panel)
	var incident_box := VBoxContainer.new()
	incident_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	incident_box.alignment = BoxContainer.ALIGNMENT_CENTER
	incident_box.add_theme_constant_override("separation", 4)
	incident_row.add_child(incident_box)
	incident_box.add_child(label(localized_content_field("hunt_event", event, "title"), 22, INK))
	var description := label(localized_content_field("hunt_event", event, "description"), 13, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	incident_box.add_child(description)
	var paused_duration := maxf(0.1, GameState.hunt_elapsed_before_event + GameState.hunt_remaining_after_event)
	var paused_percent := roundi(100.0 * GameState.hunt_elapsed_before_event / paused_duration)
	var pause_status := label(t("HUNT_EVENT_PAUSE_STATUS", "CAÇA PAUSADA EM %d%% · %ds RESTANTES APÓS A ESCOLHA", [paused_percent, ceili(GameState.hunt_remaining_after_event)]), 11, GOLD)
	pause_status.name = "HuntEventPauseStatus"
	incident_box.add_child(pause_status)

	var choices := VBoxContainer.new()
	choices.name = "HuntEventChoices"
	choices.add_theme_constant_override("separation", 10)
	content.add_child(choices)
	for choice in event.get("choices", []):
		choices.add_child(hunt_choice_card(choice, accent, str(event.get("id", ""))))
	content.add_spacer(false)
	var abandon := action_button(abandon_contract_text(), CORAL, true)
	abandon.name = "HuntAbandonAction"
	abandon.custom_minimum_size = Vector2(0, 46)
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func abandon_contract_text() -> String:
	var streak := int(GameState.player.get("capture_streak", 0))
	return t("HUNT_ABANDON_STREAK", "ABANDONAR · PERDER EMBALO ×%d", [streak]) if streak > 0 else t("HUNT_ABANDON", "ABANDONAR CONTRATO")


func hunt_choice_card(choice: Dictionary, accent: Color, event_id: String = "") -> PanelContainer:
	var kind := hunt_choice_kind(choice)
	var choice_color := GOLD if kind == "tactical" else (CYAN if kind == "detour" else CORAL)
	var card_fill := Color("#181d38") if kind == "tactical" else (Color("#10213d") if kind == "detour" else Color("#25162f"))
	var card := panel(HBoxContainer.new(), card_fill, 13, 11)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var decision_icon: Control = HuntChoiceIconScript.new()
	decision_icon.name = "HuntChoiceIcon_%s" % str(choice.id)
	decision_icon.configure(kind, choice_color)
	row.add_child(decision_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(localized_hunt_choice_field(event_id, choice, "name"), 15, choice_color))
	var effect := label(localized_hunt_choice_field(event_id, choice, "effect_text"), 13, MUTED)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(effect)
	var projected_contract := ContentDB.apply_hunt_choice(GameState.current_bounty, choice)
	var projected_payment := CoreRules.bounty_streak_reward(int(projected_contract.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var payment_text := t("HUNT_EVENT_VICTORY_PAYMENT", "VITÓRIA ◈ %d", [int(projected_payment.credits)])
	if int(projected_payment.bonus_credits) > 0:
		payment_text += t("HUNT_EVENT_MOMENTUM_INCLUDED", " · EMBALO +%d INCLUÍDO", [int(projected_payment.bonus_credits)])
	var choice_cost := int(choice.get("credit_cost", 0))
	if choice_cost > 0:
		payment_text += t("HUNT_EVENT_NET_PAYMENT", " · LÍQUIDO ◈ %d", [int(projected_payment.credits) - choice_cost])
	var payment := label(payment_text, 11, choice_color)
	payment.name = "HuntChoicePayment_%s" % str(choice.id)
	copy.add_child(payment)
	var affordable := GameState.can_afford_hunt_choice(choice)
	var missing_credits := maxi(0, choice_cost - int(GameState.player.credits))
	var choice_text := t("HUNT_EVENT_CHOOSE", "ESCOLHER") if affordable else t("HUNT_EVENT_MISSING_CREDITS", "FALTAM %d CR", [missing_credits])
	var choose := action_button(choice_text, choice_color, true)
	choose.custom_minimum_size = Vector2(122, 48)
	choose.add_theme_font_size_override("font_size", 13)
	choose.disabled = not affordable
	var choice_id := str(choice.id)
	choose.name = "HuntChoice_%s" % choice_id
	choose.pressed.connect(func(): GameState.resolve_hunt_event(choice_id))
	row.add_child(choose)
	return card


func hunt_choice_kind(choice: Dictionary) -> String:
	if int(choice.get("credit_cost", 0)) > 0:
		return "tactical"
	if float(choice.get("duration_add", 0.0)) > 0.0:
		return "detour"
	return "risk"


func build_combat() -> void:
	var approach: Dictionary = GameState.current_bounty.get("approach", {})
	var challenge_combat := bool(GameState.current_bounty.get("challenge", false))
	var approach_name := t("COMBAT_DIRECT_INCURSION", "INCURSÃO DIRETA") if challenge_combat else localized_content_field("approach", approach, "name").to_upper()
	var combat_payment := CoreRules.bounty_streak_reward(int(GameState.current_bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var dossier := panel(HBoxContainer.new(), Color("#111a31e8"), 14, 10)
	dossier.name = "CombatContractDossier"
	var dossier_row := dossier.get_child(0) as HBoxContainer
	dossier_row.add_theme_constant_override("separation", 10)
	var dossier_copy := VBoxContainer.new()
	dossier_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	dossier_row.add_child(dossier_copy)
	dossier_copy.add_child(label(t("COMBAT_RIFT_COMBAT", "COMBATE DA FENDA") if challenge_combat else t("COMBAT_AUTOMATIC_ENCOUNTER", "ENCONTRO AUTOMÁTICO"), 10, MUTED))
	dossier_copy.add_child(label(t("COMBAT_TURN_APPROACH", "TURNO %d · %s", [GameState.combat_round, approach_name]), 15, CORAL))
	if not challenge_combat:
		var combat_profile_id := EnemyProfileRulesScript.profile_id_for(GameState.current_bounty)
		var combat_profile := EnemyProfileRulesScript.profile_for(GameState.current_bounty)
		if not combat_profile.is_empty():
			var combat_profile_label := label(t("COMBAT_ENEMY_PROFILE", "PERFIL · %s", [t("ENEMY_PROFILE_%s_TITLE" % combat_profile_id.to_upper(), str(combat_profile.title))]), 9, CYAN)
			combat_profile_label.name = "CombatEnemyProfile"
			dossier_copy.add_child(combat_profile_label)
	if GameState.current_bounty.has("hunt_event_result"):
		var incident_summary := label(t("COMBAT_INCIDENT", "INCIDENTE · %s", [localized_hunt_result(GameState.current_bounty)]), 10, GOLD)
		incident_summary.name = "CombatIncidentSummary"
		incident_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dossier_copy.add_child(incident_summary)
	var payment_status := metric_chip(t("COMBAT_REWARD", "RECOMPENSA") if challenge_combat else t("COMBAT_PAYMENT", "PAGAMENTO"), "◈ %d" % int(GameState.current_bounty.credits if challenge_combat else combat_payment.credits), GOLD)
	payment_status.name = "CombatPaymentStatus"
	payment_status.custom_minimum_size = Vector2(104, 0)
	payment_status.size_flags_horizontal = Control.SIZE_SHRINK_END
	if not challenge_combat and int(combat_payment.bonus_credits) > 0:
		var payment_box := payment_status.get_child(0) as VBoxContainer
		var streak_bonus := label(t("COMBAT_MOMENTUM", "EMBALO +%d", [int(combat_payment.bonus_credits)]), 9, LIME, HORIZONTAL_ALIGNMENT_CENTER)
		streak_bonus.name = "CombatPaymentStreakBonus"
		payment_box.add_child(streak_bonus)
	dossier_row.add_child(payment_status)
	content.add_child(dossier)
	var field_test_record := field_test_record_label("CombatFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	var stage := PanelContainer.new()
	stage.clip_contents = true
	stage.custom_minimum_size = Vector2(0, 450)
	stage.add_theme_stylebox_override("panel", box_style(PANEL, 18))
	content.add_child(stage)
	var backdrop: Control = CombatBackdropScript.new()
	backdrop.events = GameState.combat_events
	backdrop.planet_id = str(GameState.current_bounty.get("planet_id", ContentDB.PLANET.id))
	stage.add_child(backdrop)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 18)
	stage_margin.add_theme_constant_override("margin_right", 18)
	stage_margin.add_theme_constant_override("margin_top", 18)
	stage_margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(stage_margin)
	var stage_box := VBoxContainer.new()
	stage_box.add_theme_constant_override("separation", 6)
	stage_margin.add_child(stage_box)
	var player_health_ratio := clampf(float(GameState.player_hp) / float(maxi(1, CoreRules.max_health(GameState.player))), 0.0, 1.0)
	var enemy_health_ratio := clampf(float(GameState.enemy_hp) / float(maxi(1, int(GameState.current_bounty.health))), 0.0, 1.0)
	var health_gap := player_health_ratio - enemy_health_ratio
	var pressure_text := t("COMBAT_PRESSURE_BALANCED", "EQUILIBRADA")
	var pressure_color := GOLD
	if health_gap >= 0.08:
		pressure_text = t("COMBAT_PRESSURE_YOURS", "SUA")
		pressure_color = LIME
	elif health_gap <= -0.08:
		pressure_text = t("COMBAT_PRESSURE_TARGET", "DO ALVO")
		pressure_color = CORAL
	var advantage := center_label(t("COMBAT_RELATIVE_HEALTH", "VIDA RELATIVA · VOCÊ %d%% · ALVO %d%% · PRESSÃO %s", [roundi(player_health_ratio * 100.0), roundi(enemy_health_ratio * 100.0), pressure_text]), 12, pressure_color)
	advantage.name = "CombatAdvantage"
	stage_box.add_child(advantage)
	var pressure_track := HBoxContainer.new()
	pressure_track.name = "CombatPressureTrack"
	pressure_track.custom_minimum_size = Vector2(0, 9)
	pressure_track.add_theme_constant_override("separation", 3)
	stage_box.add_child(pressure_track)
	var pressure_total := player_health_ratio + enemy_health_ratio
	var player_share := 0.5 if pressure_total <= 0.0 else player_health_ratio / pressure_total
	var player_pressure := ColorRect.new()
	player_pressure.name = "CombatPressurePlayer"
	player_pressure.color = CYAN
	player_pressure.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_pressure.size_flags_stretch_ratio = maxf(0.05, player_share)
	pressure_track.add_child(player_pressure)
	var enemy_pressure := ColorRect.new()
	enemy_pressure.name = "CombatPressureEnemy"
	enemy_pressure.color = CORAL
	enemy_pressure.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_pressure.size_flags_stretch_ratio = maxf(0.05, 1.0 - player_share)
	pressure_track.add_child(enemy_pressure)
	var event_row := HBoxContainer.new()
	event_row.name = "CombatEventRow"
	event_row.alignment = BoxContainer.ALIGNMENT_CENTER
	event_row.add_theme_constant_override("separation", 8)
	stage_box.add_child(event_row)
	if GameState.combat_events.is_empty():
		event_row.add_child(center_label(t("COMBAT_SENSORS_LOCKED", "SENSORES TRAVADOS · ARMAS CARREGADAS"), 14, GOLD))
	else:
		for event in GameState.combat_events:
			event_row.add_child(combat_event_chip(event))
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 20)
	stage_box.add_child(arena)
	arena.add_child(fighter(t("COMBAT_YOU", "VOCÊ"), "hunter", GameState.player_hp, CoreRules.max_health(GameState.player), CYAN))
	arena.add_child(center_label("VS", 28, GOLD))
	arena.add_child(fighter(localized_content_field("target", GameState.current_bounty, "name"), str(GameState.current_bounty.id), GameState.enemy_hp, int(GameState.current_bounty.health), CORAL))

	var log_panel := panel(VBoxContainer.new(), PANEL, 18, 14)
	log_panel.name = "CombatTurnReport"
	log_panel.custom_minimum_size = Vector2(0, 105)
	content.add_child(log_panel)
	var log_box := log_panel.get_child(0) as VBoxContainer
	log_box.add_theme_constant_override("separation", 4)
	var player_turn_damage := 0
	var enemy_turn_damage := 0
	for event in GameState.combat_events:
		if str(event.get("actor", "")) == "player":
			player_turn_damage += int(event.get("damage", 0))
		else:
			enemy_turn_damage += int(event.get("damage", 0))
	var turn_balance := player_turn_damage - enemy_turn_damage
	var turn_heading_text := t("COMBAT_NEXT_TURN", "PRÓXIMO TURNO · ARMAS PRONTAS")
	var turn_heading_color := MUTED
	if not GameState.combat_events.is_empty():
		turn_heading_text = t("COMBAT_LAST_TURN", "ÚLTIMO TURNO · VOCÊ %d DANO · ALVO %d DANO", [player_turn_damage, enemy_turn_damage])
		turn_heading_color = LIME if turn_balance > 0 else (CORAL if turn_balance < 0 else GOLD)
	var turn_heading := label(turn_heading_text, 13, turn_heading_color)
	turn_heading.name = "CombatTurnBalance"
	log_box.add_child(turn_heading)
	var message := localized_combat_narrative()
	var log_label := label(message, 16, INK)
	log_label.name = "CombatTurnNarrative"
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(log_label)
	var speed := action_button(t("COMBAT_SPEED", "VELOCIDADE · %s", ["2×" if combat_fast else "1×"]), CYAN, true)
	speed.name = "CombatSpeedAction"
	speed.custom_minimum_size = Vector2(0, 46)
	speed.pressed.connect(func():
		combat_fast = not combat_fast
		combat_timer.wait_time = 0.34 if combat_fast else 0.72
		render()
	)
	content.add_child(speed)


func combat_event_chip(event: Dictionary) -> PanelContainer:
	var player_action := str(event.get("actor", "")) == "player"
	var color := CYAN if player_action else CORAL
	var chip := panel(VBoxContainer.new(), Color("#0a1025cc"), 10, 8)
	chip.name = "CombatEventPlayer" if player_action else "CombatEventEnemy"
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(localized_combat_action(str(event.get("action", t("COMBAT_HIT", "GOLPE"))), "player" if player_action else "enemy").to_upper(), 12, color, HORIZONTAL_ALIGNMENT_CENTER))
	var raw_quality := str(event.get("quality", "ACERTO"))
	var quality := t("COMBAT_QUALITY_CRITICAL", "CRÍTICO") if raw_quality == "CRÍTICO" else (t("COMBAT_QUALITY_GRAZE", "DE RASPÃO") if raw_quality == "DE RASPÃO" else t("COMBAT_QUALITY_HIT", "ACERTO"))
	var quality_color := GOLD if raw_quality == "CRÍTICO" else (MUTED if raw_quality == "DE RASPÃO" else INK)
	box.add_child(label(t("COMBAT_DAMAGE_QUALITY", "%d DANO · %s", [int(event.get("damage", 0)), quality]), 13, quality_color, HORIZONTAL_ALIGNMENT_CENTER))
	if event.has("effect"):
		box.add_child(label(localized_combat_effect(str(event.effect)), 10, LIME if player_action else CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func build_victory() -> void:
	var challenge_victory := bool(GameState.current_bounty.get("challenge", false))
	content.add_spacer(false)
	var stamp := panel(HBoxContainer.new(), Color("#173f3c"), 18, 18)
	stamp.name = "VictoryDossier"
	content.add_child(stamp)
	var dossier := stamp.get_child(0) as HBoxContainer
	dossier.add_theme_constant_override("separation", 16)
	dossier.add_child(character_portrait(str(GameState.current_bounty.id), 142))
	var stamp_box := VBoxContainer.new()
	stamp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamp_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dossier.add_child(stamp_box)
	stamp_box.add_child(label(t("VICTORY_INCURSION_COMPLETE", "INCURSÃO CONCLUÍDA") if challenge_victory else t("VICTORY_WARRANT_EXECUTED", "MANDADO EXECUTADO"), 12, MUTED))
	stamp_box.add_child(label(t("VICTORY_FLOOR_CLEAR", "ANDAR LIMPO") if challenge_victory else t("VICTORY_TARGET_CAPTURED", "ALVO CAPTURADO"), 28, LIME))
	stamp_box.add_child(label(localized_content_field("target", GameState.current_bounty, "name"), 20, INK))
	if not GameState.combat_events.is_empty():
		var final_event: Dictionary = GameState.combat_events[0]
		var final_blow := label(t("VICTORY_FINAL_BLOW", "GOLPE FINAL · %s · %d DANO", [localized_combat_action(str(final_event.action), str(final_event.get("actor", "player"))).to_upper(), int(final_event.damage)]), 11, GOLD)
		final_blow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stamp_box.add_child(final_blow)
	var field_test_record := field_test_record_label("VictoryFieldTestContext")
	if field_test_record != null:
		stamp_box.add_child(field_test_record)
	if not GameState.combat_summary.is_empty():
		content.add_child(combat_summary_panel(true))
	var victory_payment := CoreRules.bounty_streak_reward(int(GameState.current_bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var payment_text := t("VICTORY_ARCHIVE_RECOVERED", "ARQUIVO RECUPERADO · ◈ %d", [int(GameState.current_bounty.credits)]) if challenge_victory else t("VICTORY_PAYMENT_APPROVED", "PAGAMENTO APROVADO · ◈ %d", [int(victory_payment.credits)])
	if not challenge_victory and int(victory_payment.bonus_credits) > 0:
		payment_text += t("VICTORY_MOMENTUM_INCLUDED", " · EMBALO +%d INCLUÍDO", [int(victory_payment.bonus_credits)])
	var incident_cost := maxi(0, int(GameState.current_bounty.get("hunt_event_credit_cost", 0)))
	if incident_cost > 0:
		payment_text += t("VICTORY_NET_AFTER_COST", " · SALDO +%d APÓS CUSTO", [int(victory_payment.credits) - incident_cost])
	var payment_card := panel(HBoxContainer.new(), Color("#19263d"), 12, 10)
	payment_card.name = "VictoryPaymentCard"
	var payment_row := payment_card.get_child(0) as HBoxContainer
	payment_row.add_theme_constant_override("separation", 10)
	var payment_stamp := center_label("◈", 22, GOLD)
	payment_stamp.custom_minimum_size = Vector2(32, 32)
	payment_row.add_child(payment_stamp)
	var payment_copy := VBoxContainer.new()
	payment_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	payment_row.add_child(payment_copy)
	var payment := label(payment_text, 12, GOLD)
	payment.name = "VictoryPayment"
	payment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	payment_copy.add_child(payment)
	payment_copy.add_child(label(t("VICTORY_AUTHENTICATING", "Autenticando pagamento e sacudindo os bolsos do alvo..."), 11, MUTED))
	content.add_child(payment_card)
	content.add_spacer(false)
	var open_reward := action_button(t("VICTORY_OPEN_REWARD", "ABRIR RECOMPENSA"), LIME)
	open_reward.name = "OpenRewardAction"
	open_reward.custom_minimum_size = Vector2(0, 48)
	open_reward.pressed.connect(GameState.open_reward)
	content.add_child(open_reward)


func build_reward() -> void:
	RewardViewScript.build(self, content, GameState)


func build_chapter_complete() -> void:
	var completion := GameState.chapter_completion
	var target: Dictionary = completion.get("target", {})
	var planet: Dictionary = completion.get("planet", ContentDB.PLANET)
	var chapter := panel(VBoxContainer.new(), Color("#302541"), 24, 24)
	chapter.name = "ChapterComplete"
	content.add_child(chapter)
	var box := chapter.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	var planet_name := localized_content_field("planet", planet, "name")
	var target_name := localized_content_field("target", target, "name")
	box.add_child(center_label(t("CHAPTER_COMPLETE_TITLE", "CAPÍTULO CONCLUÍDO"), 16, GOLD))
	box.add_child(center_label(planet_name.to_upper(), 34, INK))
	box.add_child(character_portrait(str(target.get("id", "mayor_gold_dust")), 174))
	box.add_child(center_label(t("CHAPTER_COMPLETE_FINAL_WARRANT", "MANDADO FINAL EXECUTADO"), 18, LIME))
	box.add_child(center_label(target_name, 25, GOLD))
	var verdict := center_label(localized_content_field("planet", planet, "completion_text"), 15, MUTED)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(verdict)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	box.add_child(stats)
	stats.add_child(metric_chip(t("COMMON_CAPTURES", "CAPTURAS"), str(completion.get("total_captures", GameState.player.wins)), CYAN))
	stats.add_child(metric_chip(t("COMMON_REPUTATION", "REPUTAÇÃO"), t("COMMON_RANK_VALUE", "RANK %d", [int(GameState.player.reputation) + 1]), LIME))
	stats.add_child(metric_chip(t("CHAPTER_COMPLETE_PAYMENT", "PAGAMENTO"), "◈ %d" % int(completion.get("credits", 0)), GOLD))
	content.add_child(center_label(t("CHAPTER_COMPLETE_OPEN", "%s permanece aberto para novas caçadas e equipamento melhor.", [planet_name]), 14, MUTED))
	content.add_spacer(false)
	var continue_button := action_button(t("CHAPTER_COMPLETE_CONTINUE", "CONTINUAR CAÇANDO"), GOLD)
	continue_button.pressed.connect(GameState.continue_after_chapter)
	content.add_child(continue_button)


func fighter(title: String, character_id: String, hp: int, maximum: int, color: Color) -> VBoxContainer:
	var fighter_box := VBoxContainer.new()
	fighter_box.name = "CombatFighter_%s" % character_id
	fighter_box.custom_minimum_size = Vector2(242, 290)
	fighter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	fighter_box.add_child(character_portrait(character_id, 152, GameState.player if character_id == "hunter" else {}))
	var name_label := center_label(title.to_upper(), 16, color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fighter_box.add_child(name_label)
	if character_id == "hunter":
		var loadout := center_label(t("COMBAT_LOADOUT", "BUILD · +%d ARMA · +%d ARMADURA", [int(GameState.player.weapon.power), int(GameState.player.armor.power)]), 11, CYAN)
		loadout.name = "CombatLoadoutSummary"
		fighter_box.add_child(loadout)
		var kit_origin := CoreRules.equipment_set_origin(GameState.player)
		if not kit_origin.is_empty():
			fighter_box.add_child(center_label(t("COMBAT_KIT", "KIT %s · +%d PODER · +%d VIDA", [localized_content_field("planet", ContentDB.get_planet(kit_origin), "name").to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]), 10, GOLD))
	var health := ProgressBar.new()
	health.name = "CombatHealthBar_%s" % character_id
	health.max_value = maximum
	health.value = hp
	health.show_percentage = false
	health.custom_minimum_size = Vector2(230, 20)
	health.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 10))
	health.add_theme_stylebox_override("fill", box_style(color, 10))
	fighter_box.add_child(health)
	var health_percent := roundi(clampf(float(hp) / float(maxi(1, maximum)), 0.0, 1.0) * 100.0)
	var health_label := center_label("%d / %d HP · %d%%" % [hp, maximum, health_percent], 15, color)
	health_label.name = "CombatHealth_%s" % character_id
	fighter_box.add_child(health_label)
	return fighter_box


func on_hunt_timer() -> void:
	if GameState.phase != GameState.Phase.HUNT:
		return
	if GameState.update_hunt():
		return
	var progress := find_child("HuntProgress", true, false) as ProgressBar
	var countdown := find_child("HuntCountdown", true, false) as Label
	if progress:
		progress.value = GameState.hunt_progress() * 100.0
	if countdown:
		var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
		countdown.text = t("HUNT_COUNTDOWN", "ALVO LOCALIZADO EM %ds", [remaining])


func on_combat_timer() -> void:
	if GameState.phase != GameState.Phase.COMBAT:
		combat_timer.stop()
		return
	var result := GameState.combat_step()
	last_combat_message = str(result.get("message", ""))
	if sound_fx:
		sound_fx.play_combat(GameState.combat_events)
	if not bool(result.get("finished", false)):
		render()
	if bool(result.get("finished", false)) and not bool(result.get("won", false)):
		show_defeat()


func show_toast(summary: Dictionary) -> void:
	if summary.is_empty():
		return
	var message := t("PROGRESSION_TOAST", "+%d créditos · +%d XP", [int(summary.credits), int(summary.xp)])
	if int(summary.get("scrap", 0)) > 0:
		message += t("PROGRESSION_TOAST_SCRAP", " · +%d SUCATA", [int(summary.scrap)])
	if int(summary.levels) > 0:
		message += t("PROGRESSION_TOAST_LEVEL", " · NÍVEL +%d", [int(summary.levels)])
	if bool(summary.rank_up):
		message += t("PROGRESSION_TOAST_RANK", " · NOVO RANK")
	last_combat_message = message


func show_defeat() -> void:
	last_combat_message = "O alvo escapou. Melhore seu equipamento e tente outra vez."
