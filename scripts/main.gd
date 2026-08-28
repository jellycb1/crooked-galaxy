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
const DailyObjectivesViewScript = preload("res://scripts/daily_objectives_view.gd")
const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const OnboardingViewScript = preload("res://scripts/onboarding_view.gd")
const ServerRulesScript = preload("res://scripts/server_rules.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")
const PlanetIconScript = preload("res://scripts/planet_icon.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const MonetizationRulesScript = preload("res://scripts/monetization_rules.gd")
const AndroidFeedbackScript = preload("res://scripts/android_feedback.gd")
const HuntChoiceIconScript = preload("res://scripts/hunt_choice_icon.gd")
const HubDestinationIconScript = preload("res://scripts/hub_destination_icon.gd")
const NavigationDockScript = preload("res://scripts/navigation_dock.gd")

var body: VBoxContainer
var content: VBoxContainer
var navigation_dock: PanelContainer
var hunt_timer: Timer
var combat_timer: Timer
var victory_timer: Timer
var arsenal_warmup_timer: Timer
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
var selected_board_offer_index := 0
var last_hunt_remaining := -1
var last_hunt_percent := -1
const IDLE_BACKGROUND_PREFETCH := ["workshop", "world", "combat"]


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
		if view_mode == "market" or view_mode == "hangar" or view_mode == "career" or view_mode == "daily" or view_mode == "settings" or view_mode == "challenges":
			return "menu"
		if view_mode != "board":
			return "board"
		return "board_bounties" if board_section != "bounties" else "quit"
	if is_active_hunt_phase() and view_mode != "hunt":
		return "hunt"
	if GameState.phase == GameState.Phase.HUNT_EVENT:
		return "ignore_hunt_event"
	if GameState.phase == GameState.Phase.HUNT:
		return "menu"
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
		"ignore_hunt_event":
			GameState.ignore_hunt_event()
		"hunt":
			view_mode = "hunt"
			render()
		"quit":
			if try_save_before_quit():
				get_tree().quit()
		# Timed hunts, combat, victory, rewards, and finales all have explicit safe
		# actions. Incidents are the exception: Back performs their neutral ignore.
		# Other contract screens consume Back rather than abandoning or claiming.
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
	if GameState.phase == GameState.Phase.HUNT or GameState.phase == GameState.Phase.HUNT_EVENT:
		on_hunt_timer()
		if (GameState.phase == GameState.Phase.HUNT or GameState.phase == GameState.Phase.HUNT_EVENT) and hunt_timer != null:
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
	safe_container.clip_contents = true
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
	# Four updates per second keep the bar fluid while avoiding ten wakeups per
	# second during multi-minute Android hunts. Visible second text is deduplicated.
	hunt_timer.wait_time = 0.25
	hunt_timer.timeout.connect(on_hunt_timer)
	add_child(hunt_timer)

	arsenal_warmup_timer = Timer.new()
	arsenal_warmup_timer.one_shot = true
	arsenal_warmup_timer.wait_time = 0.001
	arsenal_warmup_timer.timeout.connect(on_arsenal_warmup_timer)
	add_child(arsenal_warmup_timer)


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
	if view_mode != "market":
		market_refresh_confirmation = false
	if GameState.phase not in [GameState.Phase.BOARD, GameState.Phase.BRIEFING]:
		fuel_refill_confirmation = false
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
	var prior_phase := previous_phase
	var phase_changed := previous_phase >= 0 and previous_phase != GameState.phase
	if phase_changed and GameState.phase == GameState.Phase.HUNT and prior_phase in [GameState.Phase.BOARD, GameState.Phase.BRIEFING]:
		view_mode = "hunt"
	if phase_changed and GameState.phase == GameState.Phase.COMBAT:
		last_combat_message = ""
	if phase_changed and (GameState.phase == GameState.Phase.HUNT or GameState.phase == GameState.Phase.HUNT_EVENT):
		last_hunt_remaining = -1
		last_hunt_percent = -1
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
	for scroll_definition in [
		{"name": "MarketScroll", "property": "market_scroll_position"},
		{"name": "HangarScroll", "property": "hangar_scroll_position"},
		{"name": "InventoryScroll", "property": "inventory_scroll_position"},
		{"name": "CollectionScroll", "property": "collection_scroll_position"},
		{"name": "DailyObjectivesScroll", "property": "daily_scroll_position"},
		{"name": "GalaxyScroll", "property": "galaxy_scroll_position"},
	]:
		var remembered_scroll := content.find_child(str(scroll_definition.name), false, false) as ScrollContainer
		if remembered_scroll != null:
			set(str(scroll_definition.property), remembered_scroll.scroll_vertical)
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
			build_hub_surface()
		GameState.Phase.HUNT:
			if view_mode == "hunt":
				build_hunt()
			else:
				build_hub_surface()
		GameState.Phase.COMBAT:
			build_combat()
		GameState.Phase.REWARD:
			build_reward()
		GameState.Phase.VICTORY:
			build_victory()
		GameState.Phase.BRIEFING:
			build_briefing()
		GameState.Phase.HUNT_EVENT:
			if view_mode == "hunt":
				build_hunt_event()
			else:
				build_hub_surface()
		GameState.Phase.CHAPTER_COMPLETE:
			build_chapter_complete()
	update_primary_navigation()
	restore_session_scroll(current_generation)
	schedule_arsenal_warmup(current_generation)
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
	if (GameState.phase == GameState.Phase.HUNT or GameState.phase == GameState.Phase.HUNT_EVENT) and not timed_actions_suspended:
		if hunt_timer.is_stopped():
			hunt_timer.start()
	else:
		hunt_timer.stop()
	if GameState.phase == GameState.Phase.COMBAT and GameState.consume_mission_ready_feedback():
		AndroidFeedbackScript.mission_ready(t("MISSION_READY_ANDROID", "Alvo localizado. O combate está pronto."))
	call_deferred("restore_action_focus", previous_focus_name, current_generation)


func schedule_arsenal_warmup(expected_generation: int) -> void:
	if GameState.phase != GameState.Phase.BOARD or view_mode != "board" or GameState.requires_onboarding() or GameState.save_recovery_required:
		if arsenal_warmup_timer != null:
			arsenal_warmup_timer.stop()
		return
	arsenal_warmup_timer.set_meta("generation", expected_generation)
	arsenal_warmup_timer.set_meta("step", 0)
	arsenal_warmup_timer.set_meta("background_prefetch_index", -1)
	arsenal_warmup_timer.wait_time = 0.001
	arsenal_warmup_timer.start()


func on_arsenal_warmup_timer() -> void:
	var expected_generation := int(arsenal_warmup_timer.get_meta("generation", -1))
	var step := int(arsenal_warmup_timer.get_meta("step", 0))
	if expected_generation != render_generation or not is_inside_tree() or timed_actions_suspended:
		return
	if GameState.phase != GameState.Phase.BOARD or view_mode != "board":
		return
	var background_prefetch_index := int(arsenal_warmup_timer.get_meta("background_prefetch_index", -1))
	if background_prefetch_index >= 0:
		if environment_backdrop != null and background_prefetch_index < IDLE_BACKGROUND_PREFETCH.size():
			environment_backdrop.prefetch_context(str(IDLE_BACKGROUND_PREFETCH[background_prefetch_index]))
		background_prefetch_index += 1
		arsenal_warmup_timer.set_meta("background_prefetch_index", background_prefetch_index)
		if background_prefetch_index < IDLE_BACKGROUND_PREFETCH.size():
			arsenal_warmup_timer.start()
		else:
			arsenal_warmup_timer.wait_time = 0.001
		return
	if ArsenalView.warm_field_readiness_step(GameState, step):
		if environment_backdrop != null:
			environment_backdrop.prefetch_context("workshop")
		arsenal_warmup_timer.set_meta("background_prefetch_index", 1)
		arsenal_warmup_timer.wait_time = 0.05
		arsenal_warmup_timer.start()
		return
	arsenal_warmup_timer.set_meta("step", step + 1)
	arsenal_warmup_timer.start()


func restore_session_scroll(expected_generation: int) -> void:
	var scroll_name := ""
	var position := 0
	if GameState.phase == GameState.Phase.BOARD or is_active_hunt_phase():
		if view_mode == "market":
			scroll_name = "MarketScroll"
			position = market_scroll_position
		elif view_mode == "hangar":
			scroll_name = "HangarScroll"
			position = hangar_scroll_position
		elif view_mode == "arsenal" and arsenal_section == "inventory":
			scroll_name = "InventoryScroll"
			position = inventory_scroll_position
		elif view_mode == "arsenal" and arsenal_section == "collection":
			scroll_name = "CollectionScroll"
			position = collection_scroll_position
		elif view_mode == "daily":
			scroll_name = "DailyObjectivesScroll"
			position = daily_scroll_position
		elif view_mode == "galaxy" and galaxy_focus_planet_id.is_empty():
			scroll_name = "GalaxyScroll"
			position = galaxy_scroll_position
	if scroll_name.is_empty() or position <= 0:
		return
	get_tree().process_frame.connect(Callable(self, "apply_session_scroll").bind(expected_generation, scroll_name, position, false), CONNECT_ONE_SHOT)


func apply_session_scroll(expected_generation: int, scroll_name: String, position: int, final_pass: bool) -> void:
	if expected_generation != render_generation or not is_inside_tree():
		return
	var scroll := content.find_child(scroll_name, false, false) as ScrollContainer
	if scroll == null:
		return
	scroll.scroll_vertical = position
	if not final_pass:
		get_tree().process_frame.connect(Callable(self, "apply_session_scroll").bind(expected_generation, scroll_name, position, true), CONNECT_ONE_SHOT)


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
			if is_active_hunt_phase():
				view_mode = "hunt"
			else:
				view_mode = "board"
				board_section = "bounties"
		"arsenal":
			view_mode = "arsenal"
			var failed_contract := not GameState.combat_summary.is_empty() and not bool(GameState.combat_summary.get("won", true))
			var funded_field_test := GameState.last_notice_context == "reward_equipped" and int(GameState.player.get("scrap", 0)) >= mini(CoreRules.equipment_upgrade_cost(GameState.player.weapon), CoreRules.equipment_upgrade_cost(GameState.player.armor))
			if failed_contract or funded_field_test:
				arsenal_section = "workshop"
			elif GameState.collection_rewards_ready() > 0:
				arsenal_section = "collection"
			else:
				arsenal_section = "equipped"
		"hunter":
			view_mode = "attributes"
		"galaxy":
			view_mode = "galaxy"
			var unseen := GameState.unseen_planets()
			if not unseen.is_empty():
				galaxy_focus_planet_id = str(unseen[0].id)
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
	var active_hunt := is_active_hunt_phase()
	if (GameState.phase != GameState.Phase.BOARD and not active_hunt) or GameState.save_recovery_required or (GameState.phase == GameState.Phase.HUNT_EVENT and view_mode == "hunt"):
		navigation_dock.hide_and_clear()
		return
	var active_id := "contracts"
	if view_mode == "arsenal":
		active_id = "arsenal"
	elif view_mode == "attributes" or view_mode == "classes":
		active_id = "hunter"
	elif view_mode == "galaxy":
		active_id = "galaxy"
	elif view_mode == "market" or view_mode == "hangar" or view_mode == "career" or view_mode == "daily" or view_mode == "settings" or view_mode == "challenges" or board_section == "destinations":
		active_id = "menu"
	var labels := {}
	var badges := {}
	if active_hunt:
		labels.contracts = t("NAV_HUNT_ACTIVE", "CAÇADA")
		badges.contracts = 1
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
	var collection_ready := GameState.collection_rewards_ready()
	if collection_ready > 0:
		badges.arsenal = int(badges.get("arsenal", 0)) + collection_ready
		if not labels.has("arsenal"):
			labels.arsenal = t("NAV_SERIES", "SÉRIES")
	var unseen_planets := GameState.unseen_planets()
	if not unseen_planets.is_empty():
		labels.galaxy = t("NAV_NEW_WORLD", "NOVO")
		badges.galaxy = unseen_planets.size()
	var ready_rewards := GameState.career_rewards_ready()
	var daily_ready := GameState.daily_rewards_ready()
	if ready_rewards + daily_ready > 0:
		badges.menu = ready_rewards + daily_ready
	navigation_dock.configure(active_id, labels, badges)


func environment_context() -> String:
	if GameState.requires_onboarding():
		return "world"
	if GameState.phase == GameState.Phase.BOARD or (is_active_hunt_phase() and view_mode != "hunt"):
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
		if view_mode == "galaxy" or view_mode == "career" or view_mode == "daily" or view_mode == "attributes" or view_mode == "classes":
			return "world"
	if GameState.phase == GameState.Phase.COMBAT or GameState.phase == GameState.Phase.VICTORY:
		return "combat"
	return "contracts"


func is_active_hunt_phase() -> bool:
	return GameState.phase == GameState.Phase.HUNT or GameState.phase == GameState.Phase.HUNT_EVENT


func build_hub_surface() -> void:
	if view_mode == "arsenal":
		build_arsenal()
	elif view_mode == "galaxy":
		build_galaxy_map()
	elif view_mode == "career":
		build_career()
	elif view_mode == "daily":
		build_daily()
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
	if GameState.phase == GameState.Phase.BOARD and (view_mode == "attributes" or view_mode == "classes"):
		build_character_header()
		return
	if GameState.phase == GameState.Phase.BOARD and view_mode != "attributes" and view_mode != "classes":
		build_bounty_board_header()
		return
	var planet := active_planet()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", UIDesignSystem.FONT_SECTION_TITLE, CYAN))
	var location_row := HBoxContainer.new()
	location_row.add_theme_constant_override("separation", 10)
	identity.add_child(location_row)
	var location := label(localized_content_field("planet", planet, "name").to_upper(), UIDesignSystem.FONT_CAPTION, Color(str(planet.accent)))
	location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_row.add_child(location)
	var server_short := ServerRulesScript.short_name_for(str(GameState.account.get("server_id", "")))
	var build_version := label("%s · v%s" % [server_short, str(ProjectSettings.get_setting("application/config/version", "dev"))], UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	build_version.name = "BuildVersion"
	location_row.add_child(build_version)

	var character_badge := Button.new()
	character_badge.name = "HeaderCharacterAction"
	character_badge.custom_minimum_size = Vector2(156, UIDesignSystem.TOUCH_TARGET_MIN)
	character_badge.clip_contents = true
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
	var header_portrait := framed_hunter_portrait(40)
	header_portrait.name = "HeaderHunterPortrait"
	badge_row.add_child(header_portrait)
	var badge_copy := VBoxContainer.new()
	badge_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_copy)
	var level_label := label(t("HEADER_LEVEL", "NÍVEL %d", [int(GameState.player.level)]), UIDesignSystem.FONT_CAPTION, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	level_label.name = "HeaderCharacterLevel"
	level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	badge_copy.add_child(level_label)
	var power_label := label(t("HEADER_POWER", "PODER %d", [CoreRules.player_power(GameState.player)]), UIDesignSystem.FONT_CAPTION, INK, HORIZONTAL_ALIGNMENT_CENTER)
	power_label.name = "HeaderCharacterPower"
	power_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	badge_copy.add_child(power_label)

	var ledger := panel(HBoxContainer.new(), Color("#09132a"), 9, 6)
	ledger.name = "HeaderResourceStrip"
	var stats := ledger.get_child(0) as HBoxContainer
	stats.add_theme_constant_override("separation", 4)
	stats.add_child(header_resource_cell("HeaderCredits", t("RESOURCE_CREDITS", "CRÉDITOS"), str(GameState.player.credits), GOLD))
	stats.add_child(header_resource_cell("HeaderWarpChips", t("RESOURCE_WARP_CHIPS", "FICHAS"), str(GameState.player.get("warp_chips", 0)), Color("#d789ff")))
	stats.add_child(header_resource_cell("HeaderScrap", t("RESOURCE_SCRAP", "SUCATA"), str(GameState.player.get("scrap", 0)), CORAL))
	stats.add_child(header_resource_cell("HeaderReputation", t("RESOURCE_RANK", "RANK"), str(int(GameState.player.reputation) + 1), LIME))
	stats.add_child(header_resource_cell("HeaderWins", t("RESOURCE_WINS", "VITÓRIAS"), str(GameState.player.wins), CYAN))
	content.add_child(ledger)


func build_bounty_board_header() -> void:
	var planet := active_planet()
	var top := VBoxContainer.new()
	top.name = "BountyBoardHeader"
	top.custom_minimum_size.y = 122
	top.add_theme_constant_override("separation", 6)
	content.add_child(top)
	var identity_row := HBoxContainer.new()
	identity_row.name = "BountyBoardIdentityRow"
	identity_row.custom_minimum_size.y = 72
	identity_row.add_theme_constant_override("separation", 10)
	top.add_child(identity_row)

	var character_badge := Button.new()
	character_badge.name = "HeaderCharacterAction"
	character_badge.custom_minimum_size = Vector2(134, 72)
	character_badge.focus_mode = Control.FOCUS_ALL
	character_badge.tooltip_text = t("HEADER_HUNTER_TOOLTIP", "Abrir classe e atributos")
	character_badge.add_theme_stylebox_override("normal", bordered_box_style(Color("#0b1630e8"), 16, Color("#536b87"), 1))
	character_badge.add_theme_stylebox_override("hover", bordered_box_style(Color("#172b4d"), 16, CYAN, 2))
	character_badge.add_theme_stylebox_override("pressed", bordered_box_style(Color("#071126"), 16, CYAN, 2))
	character_badge.add_theme_stylebox_override("focus", bordered_box_style(Color("#16284d"), 16, GOLD, 3))
	character_badge.pressed.connect(func():
		attribute_draft = {}
		view_mode = "attributes"
		render()
	)
	identity_row.add_child(character_badge)
	var badge_margin := MarginContainer.new()
	badge_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		badge_margin.add_theme_constant_override("margin_%s" % side, 8)
	badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_badge.add_child(badge_margin)
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_margin.add_child(badge_row)
	var header_portrait := framed_hunter_portrait(54)
	header_portrait.name = "HeaderHunterPortrait"
	badge_row.add_child(header_portrait)
	var badge_copy := VBoxContainer.new()
	badge_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_copy)
	var hunter_name := str(GameState.player.get("hunter_name", "CAÇADOR"))
	badge_copy.add_child(label(hunter_name.to_upper(), UIDesignSystem.FONT_CAPTION, CYAN))
	badge_copy.add_child(label(t("HEADER_LEVEL", "NÍVEL %d", [int(GameState.player.level)]), UIDesignSystem.FONT_CAPTION, GOLD))

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity_row.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", UIDesignSystem.FONT_EMPHASIS, INK, HORIZONTAL_ALIGNMENT_CENTER))
	identity.add_child(label(localized_content_field("planet", planet, "name").to_upper(), UIDesignSystem.FONT_CAPTION, Color(str(planet.accent)), HORIZONTAL_ALIGNMENT_CENTER))
	var server_short := ServerRulesScript.short_name_for(str(GameState.account.get("server_id", "")))
	var build_version := label("%s · v%s" % [server_short, str(ProjectSettings.get_setting("application/config/version", "dev"))], UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	build_version.name = "BuildVersion"
	identity.add_child(build_version)

	var ledger := panel(GridContainer.new(), Color("#09132ae8"), 12, 5)
	ledger.name = "HeaderResourceStrip"
	ledger.custom_minimum_size = Vector2(0, 44)
	ledger.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stats := ledger.get_child(0) as GridContainer
	stats.columns = 5
	stats.add_theme_constant_override("h_separation", 4)
	stats.add_theme_constant_override("v_separation", 0)
	stats.add_child(header_resource_cell("HeaderCredits", t("RESOURCE_CREDITS", "CRÉDITOS"), str(GameState.player.credits), GOLD, true))
	stats.add_child(header_resource_cell("HeaderWarpChips", t("RESOURCE_WARP_CHIPS", "FICHAS"), str(GameState.player.get("warp_chips", 0)), Color("#d789ff"), true))
	stats.add_child(header_resource_cell("HeaderScrap", t("RESOURCE_SCRAP", "SUCATA"), str(GameState.player.get("scrap", 0)), CORAL, true))
	stats.add_child(header_resource_cell("HeaderReputation", t("RESOURCE_RANK", "RANK"), str(int(GameState.player.reputation) + 1), LIME, true))
	stats.add_child(header_resource_cell("HeaderWins", t("RESOURCE_WINS", "VITÓRIAS"), str(GameState.player.wins), CYAN, true))
	top.add_child(ledger)


func header_resource_cell(node_name: String, title: String, value: String, color: Color, rebuild_scale := false) -> BoxContainer:
	var cell: BoxContainer = VBoxContainer.new() if rebuild_scale else HBoxContainer.new()
	cell.name = node_name
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 4 if not rebuild_scale else 0)
	var title_label := label(title, UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_child(title_label)
	var value_label := label(value, UIDesignSystem.FONT_BODY, color, HORIZONTAL_ALIGNMENT_CENTER)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_child(value_label)
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
	identity.add_child(label("CROOKED GALAXY", UIDesignSystem.FONT_BODY, CYAN))
	identity.add_child(label(localized_content_field("planet", planet, "name").to_upper(), UIDesignSystem.FONT_CAPTION, Color(str(planet.accent))))
	var server_short := ServerRulesScript.short_name_for(str(GameState.account.get("server_id", "")))
	var build_version := label("%s · v%s" % [server_short, str(ProjectSettings.get_setting("application/config/version", "dev"))], UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
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
	title_box.add_child(scene_title(t("BOARD_TITLE", "QUADRO DE PROCURADOS")))
	var subtitle_text := t("BOARD_TUTORIAL_SUBTITLE", "Seu primeiro alvo. Uma captura para entrar na rede.") if int(GameState.player.get("wins", 0)) <= 0 else t("BOARD_INTERSTELLAR_SUBTITLE", "Três contratos. Rotas diferentes. Uma nave com manutenção questionável.")
	var subtitle := readable_caption(subtitle_text)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(subtitle)
	var xp_needed := CoreRules.xp_needed(int(GameState.player.level))
	var xp_text := "XP %d/%d" % [int(GameState.player.xp), xp_needed]
	var xp_label := label(xp_text, UIDesignSystem.FONT_CAPTION, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	xp_label.name = "BoardXpStatus"
	xp_label.custom_minimum_size = Vector2(88, 0)
	title_row.add_child(xp_label)
	build_board_bounties()


func build_frontier_menu() -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	content.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	title_row.add_child(title_box)
	title_box.add_child(scene_title(t("MENU_TITLE", "MENU DA FRONTEIRA")))
	title_box.add_child(readable_caption(t("MENU_SUBTITLE", "Serviços, carreira e preferências do caçador.")))
	var menu_marker: Control = HubDestinationIconScript.new()
	menu_marker.name = "FrontierMenuMarker"
	menu_marker.configure("menu", CYAN)
	menu_marker.custom_minimum_size = Vector2(58, 58)
	title_row.add_child(menu_marker)

	var section_label := label(t("MENU_SECTION", "SERVIÇOS E PROGRESSO"), UIDesignSystem.FONT_CAPTION, CYAN)
	section_label.name = "FrontierMenuSection"
	content.add_child(section_label)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.name = "FrontierMenuScroll"
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(menu_scroll)
	var menu_body := VBoxContainer.new()
	menu_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_body.add_theme_constant_override("separation", 14)
	menu_scroll.add_child(menu_body)

	var hub_grid := GridContainer.new()
	hub_grid.name = "BoardHubGrid"
	hub_grid.columns = 2
	hub_grid.add_theme_constant_override("h_separation", 10)
	hub_grid.add_theme_constant_override("v_separation", 10)
	menu_body.add_child(hub_grid)
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
	var rift_status := GameState.rift_status()
	var challenge_floor := int(rift_status.progress)
	var challenge_detail := t("MENU_RIFT_LOCKED", "DESBLOQUEIA NO NÍVEL %d", [ChallengeRulesScript.UNLOCK_LEVEL]) if not bool(rift_status.unlocked) else (t("MENU_RIFT_COMPLETE", "REALIDADE CONCLUÍDA") if challenge_floor >= ChallengeRulesScript.STAGES.size() else (t("MENU_RIFT_ENTRY_USED", "ENTRADA DIÁRIA USADA") if not bool(rift_status.entry_available) else t("MENU_RIFT_FLOOR", "INIMIGO %d DE %d", [challenge_floor + 1, ChallengeRulesScript.STAGES.size()])))
	hub_grid.add_child(board_hub_action(t("MENU_RIFT", "FENDA"), challenge_detail, CORAL, "contracts", "BoardChallengeAction", func():
		view_mode = "challenges"
		render()
	))
	var daily_ready := GameState.daily_rewards_ready()
	var daily_progress := clampi(int(GameState.player.get("daily_hunts_completed", 0)), 0, 5)
	var daily_detail := t("MENU_DAILY_READY", "%d PAGAMENTOS DISPONÍVEIS", [daily_ready]) if daily_ready > 0 else t("MENU_DAILY_DETAIL", "%d/5 CONTRATOS HOJE", [daily_progress])
	hub_grid.add_child(board_hub_action(t("MENU_DAILY", "TURNO"), daily_detail, GOLD, "daily", "BoardDailyAction", func():
		view_mode = "daily"
		render()
	))
	var settings_action := board_hub_action(t("SETTINGS_TITLE", "AJUSTES"), t("MENU_SETTINGS_DETAIL", "ÁUDIO E MOVIMENTO"), MUTED, "settings", "BoardSettingsAction", func():
		view_mode = "settings"
		render()
	)
	hub_grid.add_child(settings_action)
	var hub_divider := reference_ui_decoration("hub_divider", 12.0)
	if hub_divider != null:
		menu_body.add_child(hub_divider)
	var status := panel(HBoxContainer.new(), Color("#0d1530"), 16, 14)
	status.name = "BoardDestinationStatus"
	var status_row := status.get_child(0) as HBoxContainer
	status_row.add_theme_constant_override("separation", 14)
	var planet_icon: Control = PlanetIconScript.new()
	planet_icon.name = "FrontierMenuPlanetIcon"
	planet_icon.custom_minimum_size = Vector2(66, 66)
	planet_icon.configure(active_planet(), true, true)
	status_row.add_child(planet_icon)
	var status_box := VBoxContainer.new()
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_box.add_child(label(t("MENU_CURRENT_POSITION", "POSIÇÃO ATUAL"), UIDesignSystem.FONT_CAPTION, MUTED))
	status_box.add_child(label(localized_content_field("planet", active_planet(), "name").to_upper(), UIDesignSystem.FONT_BODY, GOLD))
	var transport_text := t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO") if active_transport.is_empty() else t("MENU_IN_TRANSIT", "EM TRÂNSITO · %s", [localized_content_field("transport", active_transport, "name").to_upper()])
	status_box.add_child(label(transport_text, UIDesignSystem.FONT_CAPTION, MUTED))
	status_row.add_child(status_box)
	if not active_transport.is_empty():
		var active_transport_icon := transport_icon(active_transport, 62)
		active_transport_icon.name = "FrontierMenuTransportIcon"
		status_row.add_child(active_transport_icon)
	menu_body.add_child(status)


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
	content.add_child(fuel_reserve_panel())
	var streak := int(GameState.player.get("capture_streak", 0))
	var streak_started_inside_receipt := streak == 1 and GameState.last_notice_context.begins_with("reward_")
	if streak > 0 and not streak_started_inside_receipt:
		var next_reward := CoreRules.bounty_streak_reward(100, streak + 1)
		var streak_notice := notice_banner(t("BOARD_STREAK", "EMBALO ×%d · próximo contrato recebe +%d%% de créditos · derrota ou abandono encerra a sequência", [streak, int(next_reward.bonus_percent)]), GOLD)
		streak_notice.name = "StreakNotice"
		content.add_child(streak_notice)
	var scroller := ScrollContainer.new()
	scroller.name = "BountyScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UIDesignSystem.SECTION_GAP)
	scroller.add_child(list)
	var board_bounties := MissionRulesScript.board_offers(GameState.player)
	var first_contract := int(GameState.player.get("wins", 0)) <= 0
	if first_contract:
		selected_board_offer_index = 0
		var tutorial_hint := readable_caption(t("BOARD_TUTORIAL_OFFER_HINT", "PRIMEIRO MANDADO · CONCLUA A CAPTURA PARA ABRIR A REDE DE TRÊS CONTRATOS"), CYAN)
		tutorial_hint.name = "BoardTutorialOfferHint"
		tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(tutorial_hint)
	elif board_bounties.size() > 1:
		selected_board_offer_index = clampi(selected_board_offer_index, 0, board_bounties.size() - 1)
		var choice_hint := readable_caption(t("BOARD_OFFER_HINT", "ESCOLHA UM MANDADO · TRÊS ROTAS, UMA CAÇADA"))
		choice_hint.name = "BoardChoiceHint"
		choice_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(choice_hint)
		var selectors := GridContainer.new()
		selectors.name = "BoardOfferSelectors"
		selectors.columns = board_bounties.size()
		selectors.add_theme_constant_override("h_separation", 8)
		list.add_child(selectors)
		for offer_index in board_bounties.size():
			selectors.add_child(bounty_offer_selector(board_bounties[offer_index], offer_index, offer_index == selected_board_offer_index))
	if not board_bounties.is_empty():
		list.add_child(bounty_card(board_bounties[0] if first_contract else board_bounties[selected_board_offer_index]))


func select_board_offer(offer_index: int) -> void:
	selected_board_offer_index = maxi(0, offer_index)
	board_details_open = false
	render()


func fuel_reserve_panel() -> PanelContainer:
	var status: Dictionary = GameState.hunt_fuel_status()
	var remaining := int(status.remaining)
	var refill_cost := int(status.refill_cost)
	var can_refill := bool(status.can_refill)
	var enough_chips := int(GameState.player.get("warp_chips", 0)) >= refill_cost
	var reserve := panel(VBoxContainer.new(), Color("#132541e8"), 12, 9)
	reserve.name = "HuntFuelPanel"
	var box := reserve.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	box.add_child(summary)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(copy)
	var fuel_color := LIME if remaining >= 20 else (GOLD if remaining > 0 else CORAL)
	var title := label(t("FUEL_RESERVE_STATUS", "COMBUSTÍVEL · %d DISPONÍVEL", [remaining]), UIDesignSystem.FONT_BODY, fuel_color)
	title.name = "HuntFuelStatus"
	copy.add_child(title)
	copy.add_child(label(t("FUEL_RESET_RULE", "RESERVA DIÁRIA %d · REINÍCIO 00:00 UTC", [int(status.daily_reserve)]), UIDesignSystem.FONT_CAPTION, MUTED))
	if not fuel_refill_confirmation:
		var refill_text := t("FUEL_REFILL_ACTION", "+%d COMBUSTÍVEL · ◆ %d", [int(status.refill_amount), refill_cost]) if can_refill else t("FUEL_REFILL_LIMIT", "RECARGAS %d/%d", [int(status.refill_count), int(status.refill_limit)])
		var refill := secondary_action(refill_text, GOLD if can_refill and enough_chips else MUTED)
		refill.name = "HuntFuelRefill"
		refill.custom_minimum_size.x = 190
		refill.disabled = not can_refill or not enough_chips
		refill.pressed.connect(func():
			fuel_refill_confirmation = true
			render()
		)
		summary.add_child(refill)
	else:
		box.add_child(readable_caption(t("FUEL_REFILL_CONFIRMATION", "CONFIRMAR RECARGA · +%d COMBUSTÍVEL POR ◆ %d · USO %d/%d", [int(status.refill_amount), refill_cost, int(status.refill_count) + 1, int(status.refill_limit)]), GOLD))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		box.add_child(actions)
		var cancel := secondary_action(t("COMMON_CANCEL", "CANCELAR"), MUTED)
		cancel.name = "HuntFuelRefillCancel"
		cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cancel.pressed.connect(func():
			fuel_refill_confirmation = false
			render()
		)
		actions.add_child(cancel)
		var confirm := primary_action(t("FUEL_REFILL_CONFIRM", "REABASTECER · ◆ %d", [refill_cost]), GOLD)
		confirm.name = "HuntFuelRefillConfirm"
		confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confirm.pressed.connect(func():
			fuel_refill_confirmation = false
			GameState.refill_hunt_fuel(refill_cost)
		)
		actions.add_child(confirm)
	return reserve


func bounty_offer_selector(bounty: Dictionary, offer_index: int, selected: bool) -> Button:
	var destination := ContentDB.get_planet(str(bounty.get("planet_id", ContentDB.PLANET.id)))
	var accent := GOLD if selected else Color(str(destination.accent))
	var selector := action_button(localized_content_field("target", bounty, "name"), accent, true)
	selector.name = "BoardOfferSelector_%d" % offer_index
	selector.custom_minimum_size = Vector2(0, 204)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.tooltip_text = "%s · %s" % [localized_content_field("target", bounty, "name"), localized_content_field("planet", destination, "name")]
	for theme_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		selector.add_theme_color_override(theme_color, Color.TRANSPARENT)
	if selected:
		var selected_style := box_style(Color("#33290f"), 14)
		selected_style.border_width_left = 3
		selected_style.border_width_top = 3
		selected_style.border_width_right = 3
		selected_style.border_width_bottom = 3
		selected_style.border_color = GOLD
		selector.add_theme_stylebox_override("normal", selected_style)

	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 5)
	inset.add_theme_constant_override("margin_right", 5)
	inset.add_theme_constant_override("margin_top", 6)
	inset.add_theme_constant_override("margin_bottom", 6)
	selector.add_child(inset)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 1)
	inset.add_child(copy)
	var portrait := character_portrait(str(bounty.id), 58)
	portrait.name = "BoardOfferPortrait_%d" % offer_index
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(portrait)
	var target_name := label(localized_content_field("target", bounty, "name"), UIDesignSystem.FONT_BODY, GOLD if selected else INK, HORIZONTAL_ALIGNMENT_CENTER)
	target_name.name = "BoardOfferTarget_%d" % offer_index
	target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_name.max_lines_visible = 2
	target_name.custom_minimum_size.y = 46
	target_name.clip_text = true
	target_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(target_name)
	var planet_name := label(localized_content_field("planet", destination, "name").to_upper(), UIDesignSystem.FONT_CAPTION, accent, HORIZONTAL_ALIGNMENT_CENTER)
	planet_name.name = "BoardOfferPlanet_%d" % offer_index
	planet_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	planet_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(planet_name)
	var odds := CoreRules.bounty_odds(GameState.player, bounty)
	var odds_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var role_id := str(bounty.get("mission_role", "standard"))
	var role_short := t("BOARD_ROLE_SAFE_SHORT", "ROTINA") if role_id == "safe" else (t("BOARD_ROLE_DANGEROUS_SHORT", "ALTO VALOR") if role_id == "dangerous" else t("BOARD_ROLE_STANDARD_SHORT", "PRIORIDADE"))
	var comparison := label("%s%s · %d%%" % ["◆ " if selected else "", role_short, roundi(odds * 100.0)], UIDesignSystem.FONT_CAPTION, odds_color, HORIZONTAL_ALIGNMENT_CENTER)
	comparison.name = "BoardOfferOdds_%d" % offer_index
	comparison.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	comparison.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(comparison)
	var duration := TransportRulesScript.effective_mission_duration(GameState.player, bounty)
	var payout := CoreRules.bounty_streak_reward(int(bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var summary := label("◈ %d · %s" % [int(payout.credits), format_hunt_duration(duration)], UIDesignSystem.FONT_CAPTION, INK, HORIZONTAL_ALIGNMENT_CENTER)
	summary.name = "BoardOfferSummary_%d" % offer_index
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(summary)
	var selector_index := offer_index
	selector.pressed.connect(func(): select_board_offer(selector_index))
	return selector


func board_hub_action(title: String, detail: String, color: Color, icon_kind: String, node_name: String, callback: Callable) -> Button:
	var button := action_button(title, color, true)
	button.name = node_name
	button.custom_minimum_size = Vector2(0, 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s · %s" % [title.capitalize(), detail.capitalize()]
	for theme_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(theme_color, Color.TRANSPARENT)
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 12)
	inset.add_theme_constant_override("margin_right", 12)
	inset.add_theme_constant_override("margin_top", 10)
	inset.add_theme_constant_override("margin_bottom", 10)
	button.add_child(inset)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	inset.add_child(row)
	var icon: Control = HubDestinationIconScript.new()
	icon.name = "BoardHubIcon_%s" % icon_kind
	icon.configure(icon_kind, color)
	icon.custom_minimum_size = Vector2(56, 56)
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	var title_label := label(title, UIDesignSystem.FONT_BODY, color)
	title_label.name = "BoardHubTitle_%s" % icon_kind
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title_label)
	var detail_label := label(detail, UIDesignSystem.FONT_CAPTION, INK)
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
	row.add_child(label(t("BOARD_NETWORK_LEVEL", "REDE DE MANDADOS · NÍVEL %d", [level]), UIDesignSystem.FONT_CAPTION, CYAN))
	var discovered := label(t("BOARD_DISCOVERED_WORLDS", "%d/%d MUNDOS CONHECIDOS", [available.size(), ContentDB.PLANETS.size()]), UIDesignSystem.FONT_CAPTION, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	discovered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(discovered)
	var unseen := GameState.unseen_planets()
	if not unseen.is_empty():
		var discovery := primary_action(t("BOARD_NEW_DESTINATION", "NOVO DESTINO · %s", [localized_content_field("planet", unseen[0], "name").to_upper()]), GOLD)
		discovery.name = "BoardNewDestination"
		discovery.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		discovery.pressed.connect(func():
			view_mode = "galaxy"
			galaxy_focus_planet_id = str(unseen[0].id)
			render()
		)
		box.add_child(discovery)
	var next_planet: Dictionary = {}
	for planet in ContentDB.PLANETS:
		if level < int(planet.get("unlock_level", 1)):
			next_planet = planet
			break
	var progress_value := level
	var progress_max := level
	if not next_planet.is_empty():
		progress_max = int(next_planet.unlock_level)
		box.add_child(readable_caption(t("BOARD_NEXT_WORLD", "PRÓXIMO DESTINO · %s NO NÍVEL %d", [localized_content_field("planet", next_planet, "name").to_upper(), progress_max])))
	else:
		box.add_child(readable_caption(t("BOARD_ALL_WORLDS", "TODOS OS DESTINOS ATUAIS ESTÃO NA REDE"), LIME))
	var progress := ProgressBar.new()
	progress.max_value = maxi(1, progress_max)
	progress.value = progress_value
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 14)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 5))
	progress.add_theme_stylebox_override("fill", box_style(GOLD, 5))
	box.add_child(progress)
	return card


func build_galaxy_map() -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	content.add_child(title_row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	title_row.add_child(copy)
	copy.add_child(scene_title(t("GALAXY_TITLE", "MAPA GALÁCTICO")))
	copy.add_child(readable_caption(t("GALAXY_SUBTITLE", "Mundos conhecidos, distâncias e ocorrências da rede de mandados.")))
	var back := secondary_action(t("ACTION_BACK", "VOLTAR"), CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func():
		view_mode = "board"
		render()
	)
	title_row.add_child(back)
	var active_transport := TransportRulesScript.active_transport(GameState.player)
	var transport_status := panel(HBoxContainer.new(), Color("#173356"), 16, 14)
	transport_status.name = "GalaxyTransportStatus"
	var transport_row := transport_status.get_child(0) as HBoxContainer
	transport_row.add_theme_constant_override("separation", 14)
	var transport_copy := VBoxContainer.new()
	transport_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if active_transport.is_empty():
		transport_copy.add_child(label(t("MENU_NO_TRANSPORT", "SEM TRANSPORTE ATIVO"), UIDesignSystem.FONT_BODY, GOLD))
		transport_copy.add_child(readable_caption(t("GALAXY_STANDARD_SPEED", "O mapa calcula cada rota na velocidade burocrática padrão.")))
	else:
		var map_icon := transport_icon(active_transport, 72)
		map_icon.name = "GalaxyTransportIcon"
		transport_row.add_child(map_icon)
		transport_copy.add_child(label(t("MENU_IN_TRANSIT", "EM TRÂNSITO · %s", [localized_content_field("transport", active_transport, "name").to_upper()]), UIDesignSystem.FONT_BODY, Color(str(active_transport.color))))
		transport_copy.add_child(readable_caption(t("GALAXY_TRANSPORT_BONUS", "-%d%% no tempo de viagem de todos os contratos", [roundi(float(active_transport.speed_bonus) * 100.0)]), LIME))
	transport_row.add_child(transport_copy)
	var open_hangar := secondary_action(t("GALAXY_OPEN_HANGAR", "ABRIR HANGAR"), CYAN)
	open_hangar.name = "GalaxyHangarAction"
	open_hangar.custom_minimum_size.x = 138
	open_hangar.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	open_hangar.pressed.connect(func():
		view_mode = "hangar"
		render()
	)
	transport_row.add_child(open_hangar)
	content.add_child(transport_status)
	var route_scroll := ScrollContainer.new()
	route_scroll.name = "GalaxyScroll"
	route_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(route_scroll)
	var route := VBoxContainer.new()
	route.name = "GalaxyRoutes"
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_theme_constant_override("separation", 14)
	route_scroll.add_child(route)
	for planet in ContentDB.PLANETS:
		route.add_child(planet_card(planet))
	if not galaxy_focus_planet_id.is_empty():
		var focused_planet_id := galaxy_focus_planet_id
		galaxy_focus_planet_id = ""
		get_tree().process_frame.connect(Callable(self, "focus_galaxy_planet").bind(render_generation, focused_planet_id, false), CONNECT_ONE_SHOT)


func focus_galaxy_planet(expected_generation: int, planet_id: String, final_pass: bool) -> void:
	if expected_generation != render_generation or view_mode != "galaxy":
		return
	var scroll := content.find_child("GalaxyScroll", false, false) as ScrollContainer
	var card := content.find_child("GalaxyPlanet_%s" % planet_id, true, false) as Control
	if scroll == null or card == null:
		return
	scroll.ensure_control_visible(card)
	galaxy_scroll_position = scroll.scroll_vertical
	if not final_pass:
		get_tree().process_frame.connect(Callable(self, "focus_galaxy_planet").bind(expected_generation, planet_id, true), CONNECT_ONE_SHOT)


func planet_card(planet: Dictionary) -> PanelContainer:
	var planet_id := str(planet.id)
	var current := planet_id == str(GameState.player.get("current_planet_id", ContentDB.PLANET.id))
	var unlocked := MissionRulesScript.is_planet_available(planet_id, int(GameState.player.get("level", 1)))
	var visited := GameState.planet_capture_count(planet_id) > 0
	var newly_discovered: bool = unlocked and not bool(GameState.player.get("seen_planet_ids", []).has(planet_id))
	var accent := Color(str(planet.accent))
	var card_fill := Color("#173356") if current else (Color("#121d3d") if visited else (PANEL_LIGHT if unlocked else Color("#0b1228")))
	var card := panel(VBoxContainer.new(), card_fill, 18, 15)
	card.name = "GalaxyPlanet_%s" % planet_id
	if current:
		# Support styles are shared across cards; duplicate before adding the
		# destination-specific selected edge.
		var current_style := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		current_style.border_color = accent
		current_style.border_width_left = 2
		current_style.border_width_top = 2
		current_style.border_width_right = 2
		current_style.border_width_bottom = 2
		card.add_theme_stylebox_override("panel", current_style)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	box.add_child(heading)
	var destination_icon := PlanetIconScript.new()
	destination_icon.name = "GalaxyPlanetIcon_%s" % planet_id
	destination_icon.configure(planet, unlocked, current)
	destination_icon.custom_minimum_size = Vector2(70, 70)
	heading.add_child(destination_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(names)
	names.add_child(label(localized_content_field("planet", planet, "name").to_upper(), UIDesignSystem.FONT_BODY, accent if unlocked else MUTED))
	var context_text := localized_content_field("planet", planet, "subtitle")
	var context_color := MUTED
	if unlocked:
		context_text = t("GALAXY_WORLD_RECORD", "ROTA-BASE %s · %d CAPTURAS REGISTADAS", [format_hunt_duration(float(planet.get("travel_duration", 0.0))), GameState.planet_capture_count(planet_id)])
		context_color = LIME if visited else GOLD
		var progress := label(context_text, UIDesignSystem.FONT_CAPTION, context_color)
		progress.name = "GalaxyPlanetProgress_%s" % planet_id
		progress.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		names.add_child(progress)
	else:
		context_text = t("GALAXY_LEVEL_REQUIREMENT", "ENTRA NA REDE NO NÍVEL %d", [int(planet.get("unlock_level", 1))])
		var requirement_label := label(context_text, UIDesignSystem.FONT_CAPTION, MUTED)
		requirement_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		names.add_child(requirement_label)
	var route_status := t("GALAXY_NEW_DESTINATION", "NOVO") if newly_discovered else (t("GALAXY_NETWORK_AVAILABLE", "NA REDE") if unlocked else t("GALAXY_LOCKED", "BLOQUEADO"))
	var status := label(route_status, UIDesignSystem.FONT_CAPTION, accent if unlocked else CORAL, HORIZONTAL_ALIGNMENT_RIGHT)
	status.custom_minimum_size = Vector2(92, 0)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(status)
	if newly_discovered:
		var acknowledge := primary_action(t("GALAXY_RECORD_DESTINATION", "REGISTAR DESTINO"), accent)
		acknowledge.name = "GalaxyAcknowledge_%s" % planet_id
		acknowledge.pressed.connect(func(): GameState.acknowledge_planet(planet_id))
		box.add_child(acknowledge)
	return card


func build_career() -> void:
	CareerViewScript.build(self, content, GameState)


func build_daily() -> void:
	DailyObjectivesViewScript.build(self, content, GameState)


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
	var banner := panel(HBoxContainer.new(), Color("#10264be8"), 16, UIDesignSystem.SUPPORT_PANEL_PADDING)
	banner.name = "FirstHunterOnboarding"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", UIDesignSystem.CONTROL_GAP)
	var class_pending := str(GameState.player.get("class_id", "")).is_empty()
	var marker := center_label("!" if class_pending else "1", UIDesignSystem.FONT_DISPLAY, GOLD if class_pending else CYAN)
	marker.custom_minimum_size.x = 58
	row.add_child(marker)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	copy.add_child(label(t("BOARD_DEFINE_STYLE", "DEFINA SEU ESTILO") if class_pending else t("BOARD_FIRST_JOB", "PRIMEIRO TRABALHO"), UIDesignSystem.FONT_BODY, GOLD if class_pending else CYAN))
	var message := readable_caption(t("BOARD_DEFINE_STYLE_DESCRIPTION", "Escolha como prefere resolver contratos. A troca continua gratuita durante os testes.") if class_pending else t("BOARD_FIRST_JOB_DESCRIPTION", "Capture Gloop para aprender o ciclo e receber o primeiro loot."), INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.max_lines_visible = 2
	copy.add_child(message)
	if class_pending:
		var choose_class := secondary_action(t("BOARD_CHOOSE_CLASS", "ESCOLHER CLASSE"), GOLD)
		choose_class.name = "OnboardingClassAction"
		choose_class.custom_minimum_size.x = 190
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
	row.add_child(label("!" if color == CORAL else "✓", UIDesignSystem.FONT_EMPHASIS, color))
	var message_label := label(message, UIDesignSystem.FONT_CAPTION, INK)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(message_label)
	if dismiss_callback.is_valid():
		var dismiss := secondary_action(t("COMMON_OK", "OK"), color)
		dismiss.name = "BoardNoticeDismiss"
		dismiss.custom_minimum_size.x = 96
		dismiss.pressed.connect(dismiss_callback)
		row.add_child(dismiss)
	return banner


func save_warning_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#3b1824"), 14, 12)
	banner.name = "SaveWarningBanner"
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var message := label(GameState.save_warning, UIDesignSystem.FONT_CAPTION, INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message)
	var recovery_required := GameState.save_recovery_required
	var retry := action_button(t("SAVE_START_FRESH", "INICIAR\nNOVO SAVE") if recovery_required else t("SAVE_RETRY", "TENTAR\nNOVAMENTE"), CORAL, true)
	retry.name = "StartFreshSaveAction" if recovery_required else "RetrySaveAction"
	retry.custom_minimum_size = Vector2(132, 72)
	retry.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
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
	var verdict := center_label("✓" if won else "×", UIDesignSystem.FONT_BODY, LIME if won else CORAL)
	verdict.name = "CombatReportVerdict"
	verdict.custom_minimum_size = Vector2(28, 28)
	report_header.add_child(verdict)
	var report_heading := label(report_title, UIDesignSystem.FONT_CAPTION, LIME if won else CORAL)
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
	var evidence := label(evidence_text, UIDesignSystem.FONT_CAPTION, GOLD if not effects.is_empty() else MUTED)
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
			var route_diagnosis := label(route_diagnosis_text, UIDesignSystem.FONT_CAPTION, GOLD)
			route_diagnosis.name = "DefeatFieldTestDiagnosis"
			route_diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(route_diagnosis)
		var remaining := int(summary.get("enemy_hp_remaining", 0))
		var diagnosis := label(t("COMBAT_DEFEAT_DIAGNOSIS", "O alvo conservou %d HP. Compare as odds, ative um kit ou invista na oficina antes da revanche.", [remaining]), UIDesignSystem.FONT_CAPTION, INK)
		diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(diagnosis)
		var lost_streak := int(summary.get("lost_streak", 0))
		if lost_streak > 0:
			var streak_loss := label(t("COMBAT_STREAK_LOST", "EMBALO ×%d ENCERRADO · a próxima captura recomeça em ×1", [lost_streak]), UIDesignSystem.FONT_CAPTION, CORAL)
			streak_loss.name = "DefeatStreakLoss"
			streak_loss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(streak_loss)
		var workshop := secondary_action(t("COMBAT_OPEN_WORKSHOP", "ABRIR OFICINA E TESTAR BUILD"), CYAN)
		workshop.name = "DefeatWorkshopAction"
		workshop.pressed.connect(func():
			arsenal_section = "workshop"
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
	row.add_child(center_label("AFK", UIDesignSystem.FONT_EMPHASIS, CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(t("AFK_PATROL_COMPLETE", "PATRULHA CONCLUÍDA · %s", [format_duration(int(report.minutes))]), UIDesignSystem.FONT_CAPTION, CYAN))
	copy.add_child(label(t("AFK_PATROL_REWARD", "+%d créditos · +%d sucata%s", [int(report.credits), int(report.scrap), t("AFK_CAP", " · LIMITE 8H") if bool(report.capped) else ""]), UIDesignSystem.FONT_BODY, INK))
	if include_recovery:
		var recovery := label(GameState.last_notice, UIDesignSystem.FONT_CAPTION, LIME)
		recovery.name = "AfkRecoveryNotice"
		recovery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(recovery)
	var dismiss := secondary_action(t("COMMON_OK", "OK"), CYAN)
	dismiss.name = "AfkDismiss"
	dismiss.custom_minimum_size.x = 96
	dismiss.pressed.connect(func(): GameState.dismiss_afk_report(include_recovery))
	row.add_child(dismiss)
	return banner


func format_duration(minutes: int) -> String:
	if minutes >= 60:
		return "%dh %02dmin" % [floori(float(minutes) / 60.0), minutes % 60]
	return "%dmin" % minutes


func bounty_card(bounty: Dictionary) -> PanelContainer:
	var card := focal_scene_panel(VBoxContainer.new())
	card.name = "BountyCard_%s" % str(bounty.id)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", UIDesignSystem.SECTION_GAP)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var target_portrait := character_portrait(str(bounty.id), 220)
	target_portrait.name = "BountyPortrait_%s" % str(bounty.id)
	row.add_child(target_portrait)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)
	var destination := ContentDB.get_planet(str(bounty.get("planet_id", ContentDB.PLANET.id)))
	var role_id := str(bounty.get("mission_role", "standard"))
	var role_text := t("BOARD_ROLE_SAFE", "MANDADO DE ROTINA") if role_id == "safe" else (t("BOARD_ROLE_DANGEROUS", "MANDADO DE ALTO VALOR") if role_id == "dangerous" else t("BOARD_ROLE_STANDARD", "MANDADO PRIORITÁRIO"))
	var mission_role := readable_caption("%s · %s" % [role_text, localized_content_field("planet", destination, "name").to_upper()], Color(str(destination.accent)))
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
		var role := readable_caption(board_reason, role_color)
		role.name = "BountyRole_%s" % str(bounty.id)
		details.add_child(role)
	elif bool(bounty.get("boss", false)):
		details.add_child(readable_caption(t("BOARD_CHAPTER_BOSS", "CHEFE DO CAPÍTULO"), GOLD))
	details.add_child(label(localized_content_field("target", bounty, "name"), UIDesignSystem.FONT_SCREEN_TITLE, GOLD if bool(bounty.get("boss", false)) else INK))
	var target_title := readable_body(localized_content_field("target", bounty, "title"), CORAL)
	target_title.max_lines_visible = 2
	details.add_child(target_title)
	var description := readable_body(localized_content_field("target", bounty, "description"), MUTED)
	description.max_lines_visible = 3
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(description)

	var captures: Dictionary = GameState.player.get("captures_by_target", {})
	var capture_count := int(captures.get(str(bounty.id), 0))
	var mastery_level := CoreRules.target_mastery_level(capture_count)
	var odds := CoreRules.bounty_odds(GameState.player, bounty)
	var payout := CoreRules.bounty_streak_reward(int(bounty.credits), int(GameState.player.get("capture_streak", 0)) + 1)
	var footer := panel(HBoxContainer.new(), Color("#09132acc"), 12, 14)
	footer.name = "BountyDecisionSummary_%s" % str(bounty.id)
	box.add_child(footer)
	var footer_row := footer.get_child(0) as HBoxContainer
	footer_row.add_theme_constant_override("separation", 12)
	var hunt_duration := TransportRulesScript.effective_mission_duration(GameState.player, bounty)
	var fuel_cost := MonetizationRulesScript.mission_fuel_cost(bounty)
	var payout_summary := readable_body("◈ %d%s   ✦ %d XP   %s   %s" % [int(payout.credits), t("BOARD_STREAK_SUFFIX", " +EMBALO") if int(payout.bonus_credits) > 0 else "", int(bounty.xp), format_hunt_duration(hunt_duration), t("FUEL_COST_SHORT", "COMB. %d", [fuel_cost])], GOLD)
	payout_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(payout_summary)
	var risk_text := localized_risk(odds)
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	footer_row.add_child(label("%s · %d%%" % [risk_text, roundi(odds * 100.0)], UIDesignSystem.FONT_BODY, risk_color, HORIZONTAL_ALIGNMENT_RIGHT))

	var actions := HBoxContainer.new()
	actions.name = "BountyPrimaryActions_%s" % str(bounty.id)
	actions.add_theme_constant_override("separation", UIDesignSystem.CONTROL_GAP)
	box.add_child(actions)
	var hunt := primary_action(t("BOARD_REPEAT_HUNT", "REPETIR CAÇADA") if is_repeat else t("BOARD_ANALYZE_APPROACHES", "ANALISAR ABORDAGENS"), GOLD if is_repeat else CYAN)
	hunt.name = "BountyAction_%s" % str(bounty.id)
	hunt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hunt.pressed.connect(func():
		briefing_context = {}
		board_details_open = false
		GameState.select_bounty(bounty)
	)
	actions.add_child(hunt)
	var detail_action := secondary_action(t("COMMON_HIDE_DETAILS", "FECHAR DETALHES") if board_details_open else t("COMMON_DETAILS", "DETALHES"), GOLD)
	detail_action.name = "BountyDetailsAction_%s" % str(bounty.id)
	detail_action.custom_minimum_size.x = 190
	detail_action.pressed.connect(func():
		board_details_open = not board_details_open
		render()
	)
	actions.add_child(detail_action)

	if board_details_open:
		var secondary := panel(VBoxContainer.new(), Color("#09132ae8"), 14, UIDesignSystem.SUPPORT_PANEL_PADDING)
		secondary.name = "BountySecondaryDetails"
		var secondary_box := secondary.get_child(0) as VBoxContainer
		secondary_box.add_theme_constant_override("separation", 8)
		secondary_box.add_child(readable_caption(t("BOARD_DETAILS_TITLE", "FICHA DO MANDADO"), CYAN))
		secondary_box.add_child(rank_progress_panel())
		if capture_count > 0:
			var next_requirement := CoreRules.target_mastery_next_requirement(mastery_level)
			var mastery_progress := t("COMMON_MAX", "MÁX.") if next_requirement < 0 else "%d/%d" % [capture_count, next_requirement]
			var mastery_label := readable_caption(t("BOARD_MASTERY_PROGRESS", "CAPTURAS %d · PERÍCIA %d/3 · %s", [capture_count, mastery_level, mastery_progress]), LIME)
			mastery_label.name = "BountyMastery_%s" % str(bounty.id)
			secondary_box.add_child(mastery_label)
		var mastery_objective := CareerRulesScript.next_mastery_objective(GameState.player, ContentDB.TARGETS)
		if not mastery_objective.is_empty() and str(mastery_objective.target.id) == str(bounty.id):
			var remaining_captures := int(mastery_objective.remaining)
			var route_label := readable_caption(t("BOARD_MASTERY_CAPTURES_PLURAL", "ROTA DE PERÍCIA · FALTAM %d CAPTURAS", [remaining_captures]) if remaining_captures != 1 else t("BOARD_MASTERY_CAPTURE_SINGULAR", "ROTA DE PERÍCIA · FALTA 1 CAPTURA"), GOLD)
			route_label.name = "MasteryRoute_%s" % str(bounty.id)
			secondary_box.add_child(route_label)
		if bool(bounty.get("mission_offer", false)):
			var saved := TransportRulesScript.mission_saved_seconds(GameState.player, bounty)
			var timing := t("BOARD_MISSION_TIMING", "VIAGEM %s · PERSEGUIÇÃO %s", [format_hunt_duration(float(bounty.get("travel_duration", 0.0))), format_hunt_duration(float(bounty.get("pursuit_duration", 0.0)))])
			if saved > 0.5:
				timing += t("BOARD_TRANSPORT_SAVING", " · NAVE POUPA %s", [format_hunt_duration(saved)])
			var timing_label := readable_caption(timing, LIME if saved > 0.5 else MUTED)
			secondary_box.add_child(timing_label)
			var starter_discount := float(bounty.get("starter_travel_discount", 0.0))
			if starter_discount > 0.001:
				var acceleration := readable_caption(t("BOARD_STARTER_TRAVEL_ACCELERATION", "ACELERAÇÃO INICIAL ATIVA · VIAGEM -%d%%", [roundi(starter_discount * 100.0)]), CYAN)
				acceleration.name = "StarterTravelAcceleration_%s" % str(bounty.id)
				secondary_box.add_child(acceleration)
		box.add_child(secondary)
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
	var target_dossier := illustrated_panel(HBoxContainer.new(), 10)
	target_dossier.name = "BriefingTargetDossier"
	content.add_child(target_dossier)
	var target_row := target_dossier.get_child(0) as HBoxContainer
	target_row.add_theme_constant_override("separation", 18)
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
	target_copy.add_child(label(t("BRIEFING_TITLE", "BRIEFING DO CONTRATO"), UIDesignSystem.FONT_CAPTION, CYAN))
	target_copy.add_child(label(localized_content_field("target", bounty, "name"), UIDesignSystem.FONT_SECTION_TITLE, INK))
	if str(briefing_context.get("target_id", "")) == str(bounty.id) and str(briefing_context.get("approach_id", "")) == recommended_id:
		var tested_context := label(t("BRIEFING_TESTED_BUILD", "BUILD TESTADA · %s · %d%% · RECOMENDAÇÃO CONFIRMADA", [localized_approach_name(str(briefing_context.get("approach_id", "")), str(briefing_context.get("approach_name", "CONTRATO BASE"))).to_upper(), roundi(float(briefing_context.get("odds", 0.0)) * 100.0)]), UIDesignSystem.FONT_CAPTION, LIME)
		tested_context.name = "BriefingFieldTestContext"
		target_copy.add_child(tested_context)
	var kit_origin := CoreRules.equipment_set_origin(GameState.player)
	if not kit_origin.is_empty():
		var kit_planet := ContentDB.get_planet(kit_origin)
		target_copy.add_child(label(t("BRIEFING_PLANETARY_KIT", "KIT PLANETÁRIO · %s · +%d PODER · +%d VIDA", [localized_content_field("planet", kit_planet, "name").to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]), UIDesignSystem.FONT_CAPTION, GOLD))
	var target_captures := int(GameState.player.get("captures_by_target", {}).get(str(bounty.id), 0))
	var target_mastery := CoreRules.target_mastery_level(target_captures)
	if target_mastery > 0:
		var mastery_label := label(t("BRIEFING_MASTERY", "PERÍCIA %d/3 · +%d%% RARO · +%d%% ÉPICO", [target_mastery, target_mastery * 5, target_mastery * 2]), UIDesignSystem.FONT_CAPTION, LIME)
		mastery_label.name = "BriefingMastery"
		target_copy.add_child(mastery_label)
	target_dossier.tooltip_text = "%s\n%s" % [
		t("BRIEFING_FLAVOR", "O alvo é o mesmo. A quantidade de problemas é uma escolha sua."),
		t("BRIEFING_HINT", "BUILD = chance atual · RECOMENDADO = risco + retorno + tempo."),
	]
	if not MonetizationRulesScript.can_start_mission(GameState.player, bounty):
		content.add_child(fuel_reserve_panel())
	var profile_id := EnemyProfileRulesScript.profile_id_for(bounty)
	var profile := EnemyProfileRulesScript.profile_for(bounty)
	var deferred_profile_card: PanelContainer = null
	if not profile.is_empty():
		var tactical_response := label(t("ENEMY_PROFILE_RESPONSE", "RESPOSTA · %s", [t("ENEMY_PROFILE_%s_RESPONSE" % profile_id.to_upper(), str(profile.response))]), UIDesignSystem.FONT_CAPTION, LIME)
		tactical_response.name = "BriefingTacticalResponse"
		tactical_response.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		target_copy.add_child(tactical_response)
		var profile_card := panel(VBoxContainer.new(), Color("#14263de8"), 12, 8)
		profile_card.name = "BriefingEnemyProfile"
		var profile_copy := profile_card.get_child(0) as VBoxContainer
		profile_copy.add_child(label(t("ENEMY_PROFILE_%s_TITLE" % profile_id.to_upper(), str(profile.title)), UIDesignSystem.FONT_BODY, CORAL))
		var profile_summary := label(t("ENEMY_PROFILE_%s_SUMMARY" % profile_id.to_upper(), str(profile.summary)), UIDesignSystem.FONT_CAPTION, MUTED)
		profile_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		profile_copy.add_child(profile_summary)
		profile_copy.add_child(label(t("ENEMY_PROFILE_RESPONSE", "RESPOSTA · %s", [t("ENEMY_PROFILE_%s_RESPONSE" % profile_id.to_upper(), str(profile.response))]), UIDesignSystem.FONT_CAPTION, LIME))
		deferred_profile_card = profile_card

	var scroller := ScrollContainer.new()
	scroller.name = "BriefingScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroller.add_child(list)
	for index in GameState.offered_approaches.size():
		list.add_child(approach_card(GameState.offered_approaches[index], evaluations[index], recommended_id))
	if deferred_profile_card != null:
		list.add_child(deferred_profile_card)
	var cancel := secondary_action(t("BRIEFING_BACK", "VOLTAR AO QUADRO"), CORAL)
	cancel.name = "BriefingCancel"
	cancel.pressed.connect(func():
		briefing_context = {}
		GameState.cancel_briefing()
	)
	content.add_child(cancel)


func approach_card(approach: Dictionary, evaluation: Dictionary, recommended_id: String) -> PanelContainer:
	var preview: Dictionary = evaluation.preview
	var color := Color(str(approach.color))
	var is_recommended := str(approach.id) == recommended_id
	var card := panel(VBoxContainer.new(), Color("#172744") if is_recommended else PANEL, 13, 4)
	card.name = "ApproachCard_%s" % str(approach.id)
	if is_recommended:
		var recommended_style := box_style(Color("#172744"), 13)
		recommended_style.content_margin_left = 4
		recommended_style.content_margin_right = 4
		recommended_style.content_margin_top = 4
		recommended_style.content_margin_bottom = 4
		recommended_style.border_width_left = 2
		recommended_style.border_width_top = 2
		recommended_style.border_width_right = 2
		recommended_style.border_width_bottom = 2
		recommended_style.border_color = LIME
		card.add_theme_stylebox_override("panel", recommended_style)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 1)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var translated_name := localized_content_field("approach", approach, "name")
	var route_name := label(translated_name.to_upper(), UIDesignSystem.FONT_BODY, color)
	route_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(route_name)
	if is_recommended:
		var recommendation := label(localized_recommendation(str(approach.id)), UIDesignSystem.FONT_CAPTION, LIME, HORIZONTAL_ALIGNMENT_RIGHT)
		recommendation.name = "RecommendedApproach_%s" % str(approach.id)
		heading.add_child(recommendation)
	var odds := float(evaluation.odds)
	var risk_text := localized_risk(odds)
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var route_summary := label(t("BRIEFING_RISK_SUMMARY", "%s · RISCO %s", [localized_content_field("approach", approach, "tag"), risk_text]), UIDesignSystem.FONT_CAPTION, risk_color)
	route_summary.name = "ApproachBuildRisk_%s" % str(approach.id)
	route_summary.custom_minimum_size = Vector2.ZERO
	route_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(route_summary)
	var description := label(localized_content_field("approach", approach, "description"), UIDesignSystem.FONT_CAPTION, INK)
	description.name = "ApproachDescription_%s" % str(approach.id)
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.tooltip_text = description.text
	box.add_child(description)
	card.tooltip_text = description.text
	var benefits: Array[String] = []
	if int(evaluation.get("streak_bonus", 0)) > 0:
		benefits.append(t("BRIEFING_STREAK_INCLUDED", "EMBALO +%d%% INCLUÍDO", [int(evaluation.streak_bonus_percent)]))
	var scrap_reward := int(preview.get("scrap_reward", 0))
	if scrap_reward > 0:
		benefits.append(t("BRIEFING_SCRAP_REWARD", "+%d SUCATA NA VITÓRIA", [scrap_reward]))
	if not benefits.is_empty():
		route_summary.text += " · %s" % " · ".join(benefits)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	box.add_child(metrics)
	var hunt_duration := TransportRulesScript.effective_mission_duration(GameState.player, preview)
	metrics.add_child(briefing_metric_chip(t("BRIEFING_TIME", "TEMPO"), format_hunt_duration(hunt_duration), MUTED, "ApproachTime_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip(t("BRIEFING_BUILD", "BUILD"), "%d%%" % roundi(odds * 100.0), risk_color, "ApproachBuild_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip(t("COMMON_CREDITS", "CRÉDITOS"), "◈ %d" % int(evaluation.credits), GOLD, "ApproachCredits_%s" % str(approach.id)))
	metrics.add_child(briefing_metric_chip("XP", str(int(preview.xp)), CYAN, "ApproachXp_%s" % str(approach.id)))
	var choose := action_button(t("BRIEFING_CHOOSE", "ESCOLHER · %s", [translated_name.to_upper()]), color)
	var fuel_cost := MonetizationRulesScript.mission_fuel_cost(preview)
	var has_fuel := MonetizationRulesScript.can_start_mission(GameState.player, preview)
	if fuel_cost > 0:
		choose.text = t("BRIEFING_CHOOSE_WITH_FUEL", "ESCOLHER · %s · COMB. %d", [translated_name.to_upper(), fuel_cost]) if has_fuel else t("BRIEFING_NEEDS_FUEL", "PRECISA DE %d COMBUSTÍVEL", [fuel_cost])
	choose.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	choose.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	var approach_id := str(approach.id)
	choose.name = "ChooseApproach_%s" % approach_id
	choose.disabled = fuel_cost > 0 and not has_fuel
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
	chip.custom_minimum_size = Vector2(0, 44)
	var box := chip.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 0)
	box.add_child(label(title, UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, UIDesignSystem.FONT_BODY, color, HORIZONTAL_ALIGNMENT_CENTER))
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
	var result := center_label(text_value, UIDesignSystem.FONT_CAPTION, text_color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.name = node_name
	return result


func build_hunt() -> void:
	var bounty := GameState.current_bounty
	content.add_spacer(false)
	content.add_child(center_label(t("HUNT_TITLE", "CAÇADA EM ANDAMENTO"), UIDesignSystem.FONT_EMPHASIS, CYAN))
	content.add_child(character_portrait(str(bounty.id), 150))
	content.add_child(center_label(localized_content_field("target", bounty, "name"), UIDesignSystem.FONT_SECTION_TITLE, INK))
	var approach: Dictionary = bounty.get("approach", {})
	if not approach.is_empty():
		content.add_child(center_label(localized_content_field("approach", approach, "name").to_upper(), UIDesignSystem.FONT_BODY, Color(str(approach.color))))
	var transport := TransportRulesScript.active_transport(GameState.player)
	if not transport.is_empty():
		var transport_row := HBoxContainer.new()
		transport_row.name = "HuntTransportStatus"
		transport_row.alignment = BoxContainer.ALIGNMENT_CENTER
		transport_row.add_theme_constant_override("separation", 8)
		var hunt_transport := transport_icon(transport, 46)
		hunt_transport.name = "HuntTransportIcon"
		transport_row.add_child(hunt_transport)
		transport_row.add_child(label(t("HUNT_TRANSPORT", "%s · -%d%% TEMPO", [localized_content_field("transport", transport, "name"), roundi(float(transport.speed_bonus) * 100.0)]), UIDesignSystem.FONT_CAPTION, Color(str(transport.color))))
		content.add_child(transport_row)
	var field_test_record := field_test_record_label("HuntFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	content.add_child(center_label(t("HUNT_FLAVOR", "Seguindo sinais, subornando robôs e fingindo ter um plano."), UIDesignSystem.FONT_CAPTION, MUTED))
	if bounty.has("hunt_event_result"):
		content.add_child(notice_banner(localized_hunt_result(bounty), GOLD))

	var progress_value := clampf(GameState.hunt_progress(), 0.0, 1.0)
	var progress_row := HBoxContainer.new()
	progress_row.name = "HuntProgressStatus"
	progress_row.add_theme_constant_override("separation", 8)
	progress_row.add_child(label(t("HUNT_DEPARTURE", "PARTIDA"), UIDesignSystem.FONT_CAPTION, MUTED))
	var stage_text := t("HUNT_LEAVING_SECTOR", "SAINDO DO SETOR") if progress_value < 0.25 else (t("HUNT_TRACKING_SIGNAL", "RASTREANDO SINAL") if progress_value < 0.8 else t("HUNT_CONTACT_IMMINENT", "CONTATO IMINENTE"))
	var stage := label("%s · %d%%" % [stage_text, roundi(progress_value * 100.0)], UIDesignSystem.FONT_CAPTION, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	stage.name = "HuntProgressStage"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(stage)
	progress_row.add_child(label(t("HUNT_TARGET", "ALVO"), UIDesignSystem.FONT_CAPTION, GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
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
	var countdown := center_label(t("HUNT_COUNTDOWN", "ALVO LOCALIZADO EM %ds", [remaining]), UIDesignSystem.FONT_CAPTION, GOLD)
	countdown.name = "HuntCountdown"
	content.add_child(countdown)
	content.add_spacer(false)
	var abandon := secondary_action(abandon_contract_text(), CORAL)
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
	heading_copy.add_child(label(t("HUNT_EVENT_TITLE", "IMPREVISTO NA CAÇADA"), UIDesignSystem.FONT_EMPHASIS, CORAL))
	heading_copy.add_child(label(t("HUNT_EVENT_PAUSED", "DECISÃO EM MOVIMENTO · A CAÇA CONTINUA"), UIDesignSystem.FONT_CAPTION, MUTED))
	var minimize := secondary_action(t("HUNT_MINIMIZE", "MINIMIZAR"), CYAN)
	minimize.name = "HuntMinimizeAction"
	minimize.custom_minimum_size.x = 164
	minimize.pressed.connect(open_frontier_menu)
	event_heading.add_child(minimize)
	var field_test_record := field_test_record_label("IncidentFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	var incident := illustrated_panel(HBoxContainer.new(), 18)
	incident.name = "HuntEventDossier"
	content.add_child(incident)
	var incident_row := incident.get_child(0) as HBoxContainer
	incident_row.add_theme_constant_override("separation", 14)
	var symbol := str(event.get("symbol", "?!"))
	var signal_panel := panel(VBoxContainer.new(), Color("#08142d"), 14, 10)
	signal_panel.name = "HuntEventSignal"
	signal_panel.custom_minimum_size = Vector2(96, 96)
	var signal_box := signal_panel.get_child(0) as VBoxContainer
	signal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	signal_box.add_child(center_label(t("HUNT_EVENT_SIGNAL", "SINAL"), UIDesignSystem.FONT_CAPTION, MUTED))
	signal_box.add_child(center_label(symbol, UIDesignSystem.FONT_SCREEN_TITLE, accent))
	incident_row.add_child(signal_panel)
	var incident_box := VBoxContainer.new()
	incident_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	incident_box.alignment = BoxContainer.ALIGNMENT_CENTER
	incident_box.add_theme_constant_override("separation", 4)
	incident_row.add_child(incident_box)
	incident_box.add_child(label(localized_content_field("hunt_event", event, "title"), UIDesignSystem.FONT_EMPHASIS, INK))
	var description := label(localized_content_field("hunt_event", event, "description"), UIDesignSystem.FONT_CAPTION, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	incident_box.add_child(description)
	var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
	var pause_status := label(t("HUNT_EVENT_PAUSE_STATUS", "ROTA EM CURSO · %s RESTANTES · IGNORAR = SEM ALTERAÇÃO", [format_hunt_duration(remaining)]), UIDesignSystem.FONT_CAPTION, GOLD)
	pause_status.name = "HuntEventPauseStatus"
	incident_box.add_child(pause_status)

	var choices := VBoxContainer.new()
	choices.name = "HuntEventChoices"
	choices.add_theme_constant_override("separation", 10)
	content.add_child(choices)
	for choice in event.get("choices", []):
		choices.add_child(hunt_choice_card(choice, accent, str(event.get("id", ""))))
	var footer_actions := HBoxContainer.new()
	footer_actions.name = "HuntEventFooterActions"
	footer_actions.add_theme_constant_override("separation", 8)
	content.add_child(footer_actions)
	var ignore := secondary_action(t("HUNT_EVENT_IGNORE", "IGNORAR · CONTINUAR ROTA"), CYAN)
	ignore.name = "HuntEventIgnoreAction"
	ignore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ignore.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	ignore.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ignore.pressed.connect(GameState.ignore_hunt_event)
	footer_actions.add_child(ignore)
	var abandon := secondary_action(abandon_contract_text(), CORAL)
	abandon.name = "HuntAbandonAction"
	abandon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abandon.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	abandon.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	abandon.pressed.connect(GameState.abandon_bounty)
	footer_actions.add_child(abandon)


func abandon_contract_text() -> String:
	var streak := int(GameState.player.get("capture_streak", 0))
	return t("HUNT_ABANDON_STREAK", "ABANDONAR · PERDER EMBALO ×%d", [streak]) if streak > 0 else t("HUNT_ABANDON", "ABANDONAR CONTRATO")


func hunt_choice_card(choice: Dictionary, accent: Color, event_id: String = "") -> PanelContainer:
	var kind := hunt_choice_kind(choice)
	var choice_color := GOLD if kind == "tactical" else (CYAN if kind == "detour" else CORAL)
	var card_fill := Color("#181d38") if kind == "tactical" else (Color("#10213d") if kind == "detour" else Color("#25162f"))
	var card := panel(HBoxContainer.new(), card_fill, 16, 14)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var decision_icon: Control = HuntChoiceIconScript.new()
	decision_icon.name = "HuntChoiceIcon_%s" % str(choice.id)
	decision_icon.configure(kind, choice_color)
	row.add_child(decision_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(localized_hunt_choice_field(event_id, choice, "name"), UIDesignSystem.FONT_BODY, choice_color))
	var effect := label(localized_hunt_choice_field(event_id, choice, "effect_text"), UIDesignSystem.FONT_CAPTION, MUTED)
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
	var payment := label(payment_text, UIDesignSystem.FONT_CAPTION, choice_color)
	payment.name = "HuntChoicePayment_%s" % str(choice.id)
	copy.add_child(payment)
	var affordable := GameState.can_afford_hunt_choice(choice)
	var missing_credits := maxi(0, choice_cost - int(GameState.player.credits))
	var choice_text := t("HUNT_EVENT_CHOOSE", "ESCOLHER") if affordable else t("HUNT_EVENT_MISSING_CREDITS", "FALTAM %d CR", [missing_credits])
	var choose := secondary_action(choice_text, choice_color)
	choose.custom_minimum_size.x = 130
	choose.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	choose.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	var dossier := panel(VBoxContainer.new(), Color("#111a31e8"), 14, 10)
	dossier.name = "CombatContractDossier"
	var dossier_row := dossier.get_child(0) as VBoxContainer
	dossier_row.add_theme_constant_override("separation", 6)
	var dossier_copy := VBoxContainer.new()
	dossier_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_copy.custom_minimum_size = Vector2.ZERO
	dossier_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	dossier_row.add_child(dossier_copy)
	var encounter_type := label(t("COMBAT_RIFT_COMBAT", "COMBATE DA FENDA") if challenge_combat else t("COMBAT_AUTOMATIC_ENCOUNTER", "ENCONTRO AUTOMÁTICO"), UIDesignSystem.FONT_CAPTION, MUTED)
	encounter_type.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	dossier_copy.add_child(encounter_type)
	if bool(GameState.combat_summary.get("arrived_from_hunt", false)):
		var ready_status := label(t("COMBAT_HUNT_COMPLETE", "TEMPO CONCLUÍDO · ALVO LOCALIZADO"), UIDesignSystem.FONT_CAPTION, LIME)
		ready_status.name = "CombatHuntComplete"
		dossier_copy.add_child(ready_status)
	var turn_approach := label(t("COMBAT_TURN_APPROACH", "TURNO %d · %s", [GameState.combat_round, approach_name]), UIDesignSystem.FONT_BODY, CORAL)
	turn_approach.name = "CombatTurnApproach"
	turn_approach.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	dossier_copy.add_child(turn_approach)
	if not challenge_combat:
		var combat_profile_id := EnemyProfileRulesScript.profile_id_for(GameState.current_bounty)
		var combat_profile := EnemyProfileRulesScript.profile_for(GameState.current_bounty)
		if not combat_profile.is_empty():
			var combat_profile_label := label(t("COMBAT_ENEMY_PROFILE", "PERFIL · %s", [t("ENEMY_PROFILE_%s_TITLE" % combat_profile_id.to_upper(), str(combat_profile.title))]), UIDesignSystem.FONT_CAPTION, CYAN)
			combat_profile_label.name = "CombatEnemyProfile"
			combat_profile_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			dossier_copy.add_child(combat_profile_label)
	if GameState.current_bounty.has("hunt_event_result"):
		var incident_receipt := t("COMBAT_INCIDENT", "INCIDENTE · %s", [localized_hunt_result(GameState.current_bounty)])
		var incident_preview := incident_receipt if incident_receipt.length() <= 52 else incident_receipt.left(51).strip_edges() + "…"
		var incident_summary := label(incident_preview, UIDesignSystem.FONT_CAPTION, GOLD)
		incident_summary.name = "CombatIncidentSummary"
		incident_summary.custom_minimum_size = Vector2(0, 20)
		incident_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		incident_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		incident_summary.tooltip_text = incident_receipt
		dossier_copy.add_child(incident_summary)
	var payment_status := metric_chip(t("COMBAT_REWARD", "RECOMPENSA") if challenge_combat else t("COMBAT_PAYMENT", "PAGAMENTO"), "◈ %d" % int(GameState.current_bounty.credits if challenge_combat else combat_payment.credits), GOLD)
	payment_status.name = "CombatPaymentStatus"
	payment_status.custom_minimum_size = Vector2.ZERO
	payment_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not challenge_combat and int(combat_payment.bonus_credits) > 0:
		var payment_box := payment_status.get_child(0) as VBoxContainer
		var streak_bonus := label(t("COMBAT_MOMENTUM", "EMBALO +%d", [int(combat_payment.bonus_credits)]), UIDesignSystem.FONT_CAPTION, LIME, HORIZONTAL_ALIGNMENT_CENTER)
		streak_bonus.name = "CombatPaymentStreakBonus"
		payment_box.add_child(streak_bonus)
	dossier_row.add_child(payment_status)
	content.add_child(dossier)
	var field_test_record := field_test_record_label("CombatFieldTestContext")
	if field_test_record != null:
		content.add_child(field_test_record)
	var stage := PanelContainer.new()
	stage.name = "CombatArenaStage"
	stage.clip_contents = true
	stage.custom_minimum_size = Vector2(0, 450)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stage_style := bordered_box_style(PANEL, 18, Color("#8a7046"), 2)
	stage_style.content_margin_left = 3
	stage_style.content_margin_top = 3
	stage_style.content_margin_right = 3
	stage_style.content_margin_bottom = 3
	stage.add_theme_stylebox_override("panel", stage_style)
	content.add_child(stage)
	var backdrop: Control = CombatBackdropScript.new()
	backdrop.name = "CombatBackdrop"
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
	stage_box.custom_minimum_size = Vector2.ZERO
	stage_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var advantage := center_label(t("COMBAT_RELATIVE_HEALTH", "VIDA RELATIVA · VOCÊ %d%% · ALVO %d%% · PRESSÃO %s", [roundi(player_health_ratio * 100.0), roundi(enemy_health_ratio * 100.0), pressure_text]), UIDesignSystem.FONT_CAPTION, pressure_color)
	advantage.name = "CombatAdvantage"
	advantage.custom_minimum_size = Vector2.ZERO
	advantage.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
		event_row.add_child(center_label(t("COMBAT_SENSORS_LOCKED", "SENSORES TRAVADOS · ARMAS CARREGADAS"), UIDesignSystem.FONT_CAPTION, GOLD))
	else:
		for event in GameState.combat_events:
			event_row.add_child(combat_event_chip(event))
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 20)
	stage_box.add_child(arena)
	arena.add_child(fighter(t("COMBAT_YOU", "VOCÊ"), "hunter", GameState.player_hp, CoreRules.max_health(GameState.player), CYAN))
	arena.add_child(center_label("VS", UIDesignSystem.FONT_SECTION_TITLE, GOLD))
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
	var turn_heading := label(turn_heading_text, UIDesignSystem.FONT_CAPTION, turn_heading_color)
	turn_heading.name = "CombatTurnBalance"
	log_box.add_child(turn_heading)
	var message := localized_combat_narrative()
	var log_label := label(message, UIDesignSystem.FONT_BODY, INK)
	log_label.name = "CombatTurnNarrative"
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(log_label)
	var speed := secondary_action(t("COMBAT_SPEED", "VELOCIDADE · %s", ["2×" if combat_fast else "1×"]), CYAN)
	speed.name = "CombatSpeedAction"
	speed.pressed.connect(toggle_combat_speed)
	content.add_child(speed)


func toggle_combat_speed() -> void:
	combat_fast = not combat_fast
	combat_timer.wait_time = 0.34 if combat_fast else 0.72
	var speed := find_child("CombatSpeedAction", true, false) as Button
	if speed != null:
		speed.text = t("COMBAT_SPEED", "VELOCIDADE · %s", ["2×" if combat_fast else "1×"])


func refresh_combat_view() -> bool:
	if GameState.phase != GameState.Phase.COMBAT:
		return false
	var stage := find_child("CombatArenaStage", true, false) as PanelContainer
	var turn_approach := find_child("CombatTurnApproach", true, false) as Label
	var event_row := find_child("CombatEventRow", true, false) as HBoxContainer
	var advantage := find_child("CombatAdvantage", true, false) as Label
	if stage == null or turn_approach == null or event_row == null or advantage == null:
		return false

	var challenge_combat := bool(GameState.current_bounty.get("challenge", false))
	var approach: Dictionary = GameState.current_bounty.get("approach", {})
	var approach_name := t("COMBAT_DIRECT_INCURSION", "INCURSÃO DIRETA") if challenge_combat else localized_content_field("approach", approach, "name").to_upper()
	turn_approach.text = t("COMBAT_TURN_APPROACH", "TURNO %d · %s", [GameState.combat_round, approach_name])

	var player_maximum := CoreRules.max_health(GameState.player)
	var enemy_maximum := maxi(1, int(GameState.current_bounty.health))
	var player_health_ratio := clampf(float(GameState.player_hp) / float(maxi(1, player_maximum)), 0.0, 1.0)
	var enemy_health_ratio := clampf(float(GameState.enemy_hp) / float(enemy_maximum), 0.0, 1.0)
	var pressure_text := t("COMBAT_PRESSURE_BALANCED", "EQUILIBRADA")
	var pressure_color := GOLD
	var health_gap := player_health_ratio - enemy_health_ratio
	if health_gap >= 0.08:
		pressure_text = t("COMBAT_PRESSURE_YOURS", "SUA")
		pressure_color = LIME
	elif health_gap <= -0.08:
		pressure_text = t("COMBAT_PRESSURE_TARGET", "DO ALVO")
		pressure_color = CORAL
	advantage.text = t("COMBAT_RELATIVE_HEALTH", "VIDA RELATIVA · VOCÊ %d%% · ALVO %d%% · PRESSÃO %s", [roundi(player_health_ratio * 100.0), roundi(enemy_health_ratio * 100.0), pressure_text])
	advantage.add_theme_color_override("font_color", pressure_color)
	var pressure_total := player_health_ratio + enemy_health_ratio
	var player_share := 0.5 if pressure_total <= 0.0 else player_health_ratio / pressure_total
	var player_pressure := find_child("CombatPressurePlayer", true, false) as ColorRect
	var enemy_pressure := find_child("CombatPressureEnemy", true, false) as ColorRect
	if player_pressure != null:
		player_pressure.size_flags_stretch_ratio = maxf(0.05, player_share)
	if enemy_pressure != null:
		enemy_pressure.size_flags_stretch_ratio = maxf(0.05, 1.0 - player_share)

	refresh_fighter_health("hunter", GameState.player_hp, player_maximum, CYAN)
	refresh_fighter_health(str(GameState.current_bounty.id), GameState.enemy_hp, enemy_maximum, CORAL)
	var backdrop := find_child("CombatBackdrop", true, false)
	if backdrop != null:
		backdrop.set("events", GameState.combat_events)
		backdrop.queue_redraw()
	for child in event_row.get_children():
		event_row.remove_child(child)
		child.free()
	if GameState.combat_events.is_empty():
		event_row.add_child(center_label(t("COMBAT_SENSORS_LOCKED", "SENSORES TRAVADOS · ARMAS CARREGADAS"), UIDesignSystem.FONT_CAPTION, GOLD))
	else:
		for event in GameState.combat_events:
			event_row.add_child(combat_event_chip(event))

	var player_turn_damage := 0
	var enemy_turn_damage := 0
	for event in GameState.combat_events:
		if str(event.get("actor", "")) == "player":
			player_turn_damage += int(event.get("damage", 0))
		else:
			enemy_turn_damage += int(event.get("damage", 0))
	var turn_heading := find_child("CombatTurnBalance", true, false) as Label
	if turn_heading != null:
		var turn_balance := player_turn_damage - enemy_turn_damage
		turn_heading.text = t("COMBAT_NEXT_TURN", "PRÓXIMO TURNO · ARMAS PRONTAS") if GameState.combat_events.is_empty() else t("COMBAT_LAST_TURN", "ÚLTIMO TURNO · VOCÊ %d DANO · ALVO %d DANO", [player_turn_damage, enemy_turn_damage])
		turn_heading.add_theme_color_override("font_color", MUTED if GameState.combat_events.is_empty() else (LIME if turn_balance > 0 else (CORAL if turn_balance < 0 else GOLD)))
	var narrative := find_child("CombatTurnNarrative", true, false) as Label
	if narrative != null:
		narrative.text = localized_combat_narrative()
	return true


func refresh_fighter_health(character_id: String, hp: int, maximum: int, color: Color) -> void:
	var health := find_child("CombatHealthBar_%s" % character_id, true, false) as ProgressBar
	if health != null:
		health.max_value = maximum
		health.value = hp
	var health_label := find_child("CombatHealth_%s" % character_id, true, false) as Label
	if health_label != null:
		var health_percent := roundi(clampf(float(hp) / float(maxi(1, maximum)), 0.0, 1.0) * 100.0)
		health_label.text = "%d / %d HP · %d%%" % [hp, maximum, health_percent]
		health_label.add_theme_color_override("font_color", color)


func combat_event_chip(event: Dictionary) -> PanelContainer:
	var player_action := str(event.get("actor", "")) == "player"
	var color := CYAN if player_action else CORAL
	var chip := panel(VBoxContainer.new(), Color("#0a1025cc"), 10, 8)
	chip.name = "CombatEventPlayer" if player_action else "CombatEventEnemy"
	chip.custom_minimum_size = Vector2.ZERO
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	var action_label := label(localized_combat_action(str(event.get("action", t("COMBAT_HIT", "GOLPE"))), "player" if player_action else "enemy").to_upper(), UIDesignSystem.FONT_CAPTION, color, HORIZONTAL_ALIGNMENT_CENTER)
	action_label.custom_minimum_size = Vector2.ZERO
	action_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(action_label)
	var raw_quality := str(event.get("quality", "ACERTO"))
	var quality := t("COMBAT_QUALITY_CRITICAL", "CRÍTICO") if raw_quality == "CRÍTICO" else (t("COMBAT_QUALITY_GRAZE", "DE RASPÃO") if raw_quality == "DE RASPÃO" else t("COMBAT_QUALITY_HIT", "ACERTO"))
	var quality_color := GOLD if raw_quality == "CRÍTICO" else (MUTED if raw_quality == "DE RASPÃO" else INK)
	var quality_label := label(t("COMBAT_DAMAGE_QUALITY", "%d DANO · %s", [int(event.get("damage", 0)), quality]), UIDesignSystem.FONT_CAPTION, quality_color, HORIZONTAL_ALIGNMENT_CENTER)
	quality_label.custom_minimum_size = Vector2.ZERO
	quality_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(quality_label)
	if event.has("effect"):
		var effect_label := label(localized_combat_effect(str(event.effect)), UIDesignSystem.FONT_CAPTION, LIME if player_action else CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		effect_label.custom_minimum_size = Vector2.ZERO
		effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(effect_label)
	return chip


func build_victory() -> void:
	var challenge_victory := bool(GameState.current_bounty.get("challenge", false))
	content.add_spacer(false)
	var stamp := illustrated_panel(HBoxContainer.new(), 18)
	stamp.name = "VictoryDossier"
	content.add_child(stamp)
	var dossier := stamp.get_child(0) as HBoxContainer
	dossier.add_theme_constant_override("separation", 16)
	dossier.add_child(character_portrait(str(GameState.current_bounty.id), 142))
	var stamp_box := VBoxContainer.new()
	stamp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamp_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dossier.add_child(stamp_box)
	stamp_box.add_child(label(t("VICTORY_INCURSION_COMPLETE", "INCURSÃO CONCLUÍDA") if challenge_victory else t("VICTORY_WARRANT_EXECUTED", "MANDADO EXECUTADO"), UIDesignSystem.FONT_CAPTION, MUTED))
	stamp_box.add_child(label(t("VICTORY_FLOOR_CLEAR", "ANDAR LIMPO") if challenge_victory else t("VICTORY_TARGET_CAPTURED", "ALVO CAPTURADO"), UIDesignSystem.FONT_SECTION_TITLE, LIME))
	stamp_box.add_child(label(localized_content_field("target", GameState.current_bounty, "name"), UIDesignSystem.FONT_BODY, INK))
	if not GameState.combat_events.is_empty():
		var final_event: Dictionary = GameState.combat_events[0]
		var final_blow := label(t("VICTORY_FINAL_BLOW", "GOLPE FINAL · %s · %d DANO", [localized_combat_action(str(final_event.action), str(final_event.get("actor", "player"))).to_upper(), int(final_event.damage)]), UIDesignSystem.FONT_CAPTION, GOLD)
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
	var payment_card := panel(HBoxContainer.new(), Color("#19263d"), 16, 13)
	payment_card.name = "VictoryPaymentCard"
	var payment_row := payment_card.get_child(0) as HBoxContainer
	payment_row.add_theme_constant_override("separation", 10)
	var payment_stamp := center_label("◈", UIDesignSystem.FONT_EMPHASIS, GOLD)
	payment_stamp.custom_minimum_size = Vector2(32, 32)
	payment_row.add_child(payment_stamp)
	var payment_copy := VBoxContainer.new()
	payment_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	payment_row.add_child(payment_copy)
	var payment := label(payment_text, UIDesignSystem.FONT_BODY, GOLD)
	payment.name = "VictoryPayment"
	payment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	payment_copy.add_child(payment)
	var payment_explanation := label(t("VICTORY_AUTHENTICATING", "Autenticando pagamento e sacudindo os bolsos do alvo..."), UIDesignSystem.FONT_CAPTION, MUTED)
	payment_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	payment_copy.add_child(payment_explanation)
	content.add_child(payment_card)
	content.add_spacer(false)
	var open_reward := primary_action(t("VICTORY_OPEN_REWARD", "ABRIR RECOMPENSA"), LIME)
	open_reward.name = "OpenRewardAction"
	open_reward.pressed.connect(GameState.open_reward)
	content.add_child(open_reward)


func build_reward() -> void:
	RewardViewScript.build(self, content, GameState)


func build_chapter_complete() -> void:
	var completion := GameState.chapter_completion
	var target: Dictionary = completion.get("target", {})
	var planet: Dictionary = completion.get("planet", ContentDB.PLANET)
	var chapter := illustrated_panel(VBoxContainer.new(), 24)
	chapter.name = "ChapterComplete"
	content.add_child(chapter)
	var box := chapter.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	var planet_name := localized_content_field("planet", planet, "name")
	var target_name := localized_content_field("target", target, "name")
	box.add_child(center_label(t("CHAPTER_COMPLETE_TITLE", "CAPÍTULO CONCLUÍDO"), UIDesignSystem.FONT_CAPTION, GOLD))
	box.add_child(center_label(planet_name.to_upper(), UIDesignSystem.FONT_SCREEN_TITLE, INK))
	box.add_child(character_portrait(str(target.get("id", "mayor_gold_dust")), 174))
	box.add_child(center_label(t("CHAPTER_COMPLETE_FINAL_WARRANT", "MANDADO FINAL EXECUTADO"), UIDesignSystem.FONT_CAPTION, LIME))
	box.add_child(center_label(target_name, UIDesignSystem.FONT_EMPHASIS, GOLD))
	var verdict := center_label(localized_content_field("planet", planet, "completion_text"), UIDesignSystem.FONT_CAPTION, MUTED)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(verdict)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	box.add_child(stats)
	stats.add_child(metric_chip(t("COMMON_CAPTURES", "CAPTURAS"), str(completion.get("total_captures", GameState.player.wins)), CYAN))
	stats.add_child(metric_chip(t("COMMON_REPUTATION", "REPUTAÇÃO"), t("COMMON_RANK_VALUE", "RANK %d", [int(GameState.player.reputation) + 1]), LIME))
	stats.add_child(metric_chip(t("CHAPTER_COMPLETE_PAYMENT", "PAGAMENTO"), "◈ %d" % int(completion.get("credits", 0)), GOLD))
	var open_world := center_label(t("CHAPTER_COMPLETE_OPEN", "%s permanece aberto para novas caçadas e equipamento melhor.", [planet_name]), UIDesignSystem.FONT_CAPTION, MUTED)
	open_world.name = "ChapterOpenWorld"
	open_world.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(open_world)
	content.add_spacer(false)
	var continue_button := primary_action(t("CHAPTER_COMPLETE_CONTINUE", "CONTINUAR CAÇANDO"), GOLD)
	continue_button.pressed.connect(GameState.continue_after_chapter)
	content.add_child(continue_button)


func fighter(title: String, character_id: String, hp: int, maximum: int, color: Color) -> VBoxContainer:
	var fighter_box := VBoxContainer.new()
	fighter_box.name = "CombatFighter_%s" % character_id
	fighter_box.custom_minimum_size = Vector2(242, 290)
	fighter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	fighter_box.add_child(character_portrait(character_id, 152, GameState.player if character_id == "hunter" else {}))
	var name_label := center_label(title.to_upper(), UIDesignSystem.FONT_BODY, color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fighter_box.add_child(name_label)
	if character_id == "hunter":
		var loadout := center_label(t("COMBAT_LOADOUT", "BUILD · +%d ARMA · +%d ARMADURA", [int(GameState.player.weapon.power), int(GameState.player.armor.power)]), UIDesignSystem.FONT_CAPTION, CYAN)
		loadout.name = "CombatLoadoutSummary"
		loadout.custom_minimum_size = Vector2.ZERO
		loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fighter_box.add_child(loadout)
		var kit_origin := CoreRules.equipment_set_origin(GameState.player)
		if not kit_origin.is_empty():
			var kit_label := center_label(t("COMBAT_KIT", "KIT %s · +%d PODER · +%d VIDA", [localized_content_field("planet", ContentDB.get_planet(kit_origin), "name").to_upper(), CoreRules.PLANETARY_KIT_POWER_BONUS, CoreRules.PLANETARY_KIT_HEALTH_BONUS]), UIDesignSystem.FONT_CAPTION, GOLD)
			kit_label.custom_minimum_size = Vector2.ZERO
			kit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fighter_box.add_child(kit_label)
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
	var health_label := center_label("%d / %d HP · %d%%" % [hp, maximum, health_percent], UIDesignSystem.FONT_CAPTION, color)
	health_label.name = "CombatHealth_%s" % character_id
	fighter_box.add_child(health_label)
	return fighter_box


func on_hunt_timer() -> void:
	if GameState.phase != GameState.Phase.HUNT and GameState.phase != GameState.Phase.HUNT_EVENT:
		return
	var now := Time.get_unix_time_from_system()
	if GameState.update_hunt(now):
		return
	var remaining := maxi(0, ceili(GameState.hunt_ends_at - now))
	if GameState.phase == GameState.Phase.HUNT_EVENT:
		if remaining != last_hunt_remaining:
			var event_status := find_child("HuntEventPauseStatus", true, false) as Label
			if event_status:
				event_status.text = t("HUNT_EVENT_PAUSE_STATUS", "ROTA EM CURSO · %s RESTANTES · IGNORAR = SEM ALTERAÇÃO", [format_hunt_duration(remaining)])
			last_hunt_remaining = remaining
		return
	var progress := find_child("HuntProgress", true, false) as ProgressBar
	var countdown := find_child("HuntCountdown", true, false) as Label
	var progress_value := GameState.hunt_progress(now)
	if progress:
		progress.value = progress_value * 100.0
	var percent := roundi(progress_value * 100.0)
	if percent != last_hunt_percent:
		var stage := find_child("HuntProgressStage", true, false) as Label
		if stage:
			var stage_text := t("HUNT_LEAVING_SECTOR", "SAINDO DO SETOR") if progress_value < 0.25 else (t("HUNT_TRACKING_SIGNAL", "RASTREANDO SINAL") if progress_value < 0.8 else t("HUNT_CONTACT_IMMINENT", "CONTATO IMINENTE"))
			stage.text = "%s · %d%%" % [stage_text, percent]
		last_hunt_percent = percent
	if countdown and remaining != last_hunt_remaining:
		countdown.text = t("HUNT_COUNTDOWN", "ALVO LOCALIZADO EM %ds", [remaining])
		last_hunt_remaining = remaining


func on_combat_timer() -> void:
	if GameState.phase != GameState.Phase.COMBAT:
		combat_timer.stop()
		return
	var result := GameState.combat_step()
	last_combat_message = str(result.get("message", ""))
	if sound_fx:
		sound_fx.play_combat(GameState.combat_events)
	if not bool(result.get("finished", false)):
		if not refresh_combat_view():
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
