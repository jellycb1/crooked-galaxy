class_name CareerView
extends RefCounted

const CareerRulesScript = preload("res://scripts/career_rules.gd")
const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const StateScript = preload("res://scripts/game_state.gd")
const PlanetIconScript = preload("res://scripts/planet_icon.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	if not host.career_section in ["progress", "archive"]:
		host.career_section = "progress"
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	title_row.add_child(titles)
	titles.add_child(host.scene_title(t("CAREER_TITLE", "CARREIRA DE CAÇADOR")))
	titles.add_child(host.readable_caption(t("CAREER_SUBTITLE", "A galáxia esquece crimes. Seu currículo não.")))
	var back := host.secondary_action(t("ACTION_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 118
	back.pressed.connect(func():
		host.call("open_frontier_menu")
	)
	title_row.add_child(back)

	var scroller := ScrollContainer.new()
	scroller.name = "CareerScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.name = "CareerPage"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)

	list.add_child(summary_card(host, state))
	var claim_notice := career_claim_notice(state)
	if not claim_notice.is_empty():
		list.add_child(claim_receipt_card(host, claim_notice))
	var ready_count := state.career_rewards_ready()
	if ready_count > 0:
		var claim_all := host.primary_action(t("CAREER_CLAIM_ALL", "RESGATAR TODOS · %d", [ready_count]), host.GOLD)
		claim_all.name = "ClaimAllMilestones"
		claim_all.pressed.connect(state.claim_all_career_milestones)
		list.add_child(claim_all)
	var objective := CareerRulesScript.next_mastery_objective(state.player, Content.TARGETS)
	if host.career_section == "progress" and not objective.is_empty():
		list.add_child(mastery_directive_card(host, state, objective))

	var section_nav := HBoxContainer.new()
	section_nav.name = "CareerSectionNav"
	section_nav.add_theme_constant_override("separation", 8)
	list.add_child(section_nav)
	var progress_jump := host.primary_action(t("CAREER_PROGRESS", "PROGRESSO"), host.CYAN) if host.career_section == "progress" else host.secondary_action(t("CAREER_PROGRESS", "PROGRESSO"), host.CYAN)
	progress_jump.name = "CareerProgressJump"
	progress_jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_jump.pressed.connect(func(): select_section(host, "progress"))
	section_nav.add_child(progress_jump)
	var archive_jump := host.primary_action(t("CAREER_WANTED_COUNT", "PROCURADOS · %d", [Content.TARGETS.size()]), host.GOLD) if host.career_section == "archive" else host.secondary_action(t("CAREER_WANTED_COUNT", "PROCURADOS · %d", [Content.TARGETS.size()]), host.GOLD)
	archive_jump.name = "CareerArchiveJump"
	archive_jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_jump.pressed.connect(func(): select_section(host, "archive"))
	section_nav.add_child(archive_jump)

	if host.career_section == "archive":
		var archive_heading := host.label(t("CAREER_WANTED_ARCHIVE", "ARQUIVO DE PROCURADOS · PLANETA ATUAL PRIMEIRO"), UIDesignSystem.FONT_CAPTION, host.MUTED)
		archive_heading.name = "WantedArchiveHeading"
		list.add_child(archive_heading)
		for target in ordered_archive_targets(state):
			list.add_child(target_card(host, state, target))
	else:
		var progress_heading := host.label(t("CAREER_PLANET_PROGRESS", "PROGRESSO PLANETÁRIO"), UIDesignSystem.FONT_CAPTION, host.MUTED)
		progress_heading.name = "CareerProgressHeading"
		list.add_child(progress_heading)
		for planet in Content.PLANETS:
			list.add_child(planet_card(host, state, planet))
		list.add_child(host.label(t("CAREER_PARALLEL_PROGRESS", "PROGRESSO PARALELO"), UIDesignSystem.FONT_CAPTION, host.MUTED))
		list.add_child(challenge_progress_card(host, state))
		list.add_child(host.label(t("CAREER_MILESTONES", "MARCOS DA CARREIRA"), UIDesignSystem.FONT_CAPTION, host.MUTED))
		for milestone in state.career_milestones():
			list.add_child(milestone_card(host, state, milestone))
	scroller.get_v_scroll_bar().value_changed.connect(func(value: float):
		host.career_scroll_position = roundi(value)
	)
	if host.career_scroll_position > 0:
		restore_scroll_position(host, scroller, host.career_scroll_position)
	host.career_section_switch_pending = false


static func select_section(host: CrookedUIFactory, section: String) -> void:
	if host.career_section == section:
		return
	host.career_section = section
	host.career_scroll_position = 0
	host.career_section_switch_pending = true
	if host.has_method("render"):
		host.call("render")


static func restore_scroll_position(host: CrookedUIFactory, scroller: ScrollContainer, position: int) -> void:
	var scroll_bar := scroller.get_v_scroll_bar()
	scroll_bar.set_block_signals(true)
	scroller.get_tree().process_frame.connect(func():
		if not is_instance_valid(scroller):
			return
		scroller.scroll_vertical = position
		scroller.get_tree().process_frame.connect(func():
			if not is_instance_valid(scroller):
				return
			scroller.scroll_vertical = position
			scroll_bar.set_block_signals(false)
			host.career_scroll_position = scroller.scroll_vertical
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


static func ordered_archive_targets(state: StateScript) -> Array[Dictionary]:
	var current_planet_id := str(state.player.get("current_planet_id", Content.PLANET.id))
	var ordered: Array[Dictionary] = []
	for target in Content.TARGETS:
		if str(target.get("planet_id", Content.PLANET.id)) == current_planet_id:
			ordered.append(target)
	for target in Content.TARGETS:
		if str(target.get("planet_id", Content.PLANET.id)) != current_planet_id:
			ordered.append(target)
	return ordered


static func career_claim_notice(state: StateScript) -> String:
	return str(state.last_notice) if state.last_notice_context == "career" else ""


static func claim_receipt_card(host: CrookedUIFactory, notice: String) -> PanelContainer:
	var receipt := host.panel(HBoxContainer.new(), Color("#173356"), 12, 11)
	receipt.name = "CareerClaimReceipt"
	var row := receipt.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var stamp := host.center_label("✓", UIDesignSystem.FONT_BODY, host.LIME)
	stamp.custom_minimum_size = Vector2(28, 28)
	row.add_child(stamp)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(t("CAREER_RECEIPT", "RECIBO DA CARREIRA"), UIDesignSystem.FONT_CAPTION, host.LIME))
	var message := host.label(notice, UIDesignSystem.FONT_CAPTION, host.INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(message)
	return receipt


static func summary_card(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var summary := host.illustrated_panel(HBoxContainer.new(), 18)
	summary.name = "CareerSummary"
	var row := summary.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	row.add_child(framed_portrait(host, "hunter", 92, state.player))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(t("CAREER_HUNTER_LEVEL", "CAÇADOR NÍVEL %d", [int(state.player.level)]), UIDesignSystem.FONT_BODY, host.GOLD))
	copy.add_child(host.readable_caption(t("CAREER_CAPTURE_SECTORS", "%d CAPTURAS · %d/%d MUNDOS CONHECIDOS", [int(state.player.wins), MissionRules.available_planets(int(state.player.get("level", 1))).size(), Content.PLANETS.size()]), host.INK))
	var xp_needed := Rules.xp_needed(int(state.player.level))
	var xp_row := HBoxContainer.new()
	copy.add_child(xp_row)
	var xp_caption := host.label(t("CAREER_NEXT_LEVEL", "PRÓXIMO NÍVEL"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	xp_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_row.add_child(xp_caption)
	xp_row.add_child(host.label("%d / %d XP" % [int(state.player.xp), xp_needed], UIDesignSystem.FONT_CAPTION, host.CYAN, HORIZONTAL_ALIGNMENT_RIGHT))
	var xp_bar := ProgressBar.new()
	xp_bar.name = "CareerXpProgress"
	xp_bar.max_value = xp_needed
	xp_bar.value = int(state.player.xp)
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 12)
	xp_bar.add_theme_stylebox_override("background", host.box_style(Color("#091126"), 4))
	xp_bar.add_theme_stylebox_override("fill", host.box_style(host.CYAN, 4))
	copy.add_child(xp_bar)
	var lifetime := host.label(t("CAREER_LIFETIME_EARNINGS", "AFK ◈ %d / %d sucata · PRÊMIOS ◈ %d / %d sucata", [int(state.player.get("afk_credits_earned", 0)), int(state.player.get("afk_scrap_earned", 0)), int(state.player.get("career_credits_claimed", 0)), int(state.player.get("career_scrap_claimed", 0))]), UIDesignSystem.FONT_CAPTION, host.MUTED)
	lifetime.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(lifetime)
	var complete_count := 0
	var milestones := state.career_milestones()
	for milestone in milestones:
		if bool(milestone.complete):
			complete_count += 1
	var badge_text := t("CAREER_MILESTONE_BADGE", "MARCOS\n%d / %d", [complete_count, milestones.size()])
	var ready_count := state.career_rewards_ready()
	if ready_count > 0:
		badge_text += t("CAREER_READY_BADGE", "\n%d A RESGATAR", [ready_count])
	var badge := host.center_label(badge_text, UIDesignSystem.FONT_CAPTION, host.LIME)
	badge.custom_minimum_size = Vector2(88, 78)
	row.add_child(badge)
	return summary


static func mastery_directive_card(host: CrookedUIFactory, state: StateScript, objective: Dictionary) -> PanelContainer:
	var target: Dictionary = objective.target
	var planet := Content.get_planet(str(target.planet_id))
	var card := host.panel(HBoxContainer.new(), Color("#152a42"), 16, 14)
	card.name = "MasteryDirective"
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	row.add_child(framed_portrait(host, str(target.id), 72))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.readable_caption(t("CAREER_NEXT_MASTERY", "PRÓXIMA PERÍCIA · %s", [localized_content_field("target", target, "name").to_upper()]), host.GOLD))
	copy.add_child(host.readable_caption(t("CAREER_MASTERY_REMAINING", "Faltam %d capturas para perícia %d/3", [int(objective.remaining), int(objective.next_level)]), host.INK))
	copy.add_child(host.readable_caption(t("CAREER_MASTERY_BONUS", "Próximo bônus: +%d%% raro · +%d%% épico · +%d sucata", [int(objective.rare_bonus), int(objective.epic_bonus), int(objective.scrap_bonus)]), host.LIME))
	var action := host.secondary_action(t("CAREER_CHOOSE_ROUTE", "ESCOLHER\nROTA"), Color(str(planet.accent)))
	action.name = "MasteryDirectiveAction"
	action.custom_minimum_size.x = 118
	action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	var target_id := str(target.id)
	action.pressed.connect(func():
		host.view_mode = "board"
		host.briefing_context = {}
		var offer := MissionRules.offer_for_target(state.player, Content.get_target(target_id))
		if not offer.is_empty():
			state.select_bounty(offer)
	)
	row.add_child(action)
	return card


static func framed_portrait(host: CrookedUIFactory, character_id: String, dimension: float, profile: Dictionary = {}) -> Control:
	var stack := host.framed_portrait(character_id, dimension, profile)
	stack.name = "OriginalFramedPortrait_%s" % character_id
	return stack


static func planet_card(host: CrookedUIFactory, state: StateScript, planet: Dictionary) -> PanelContainer:
	var planet_id := str(planet.id)
	var unlocked: bool = MissionRules.is_planet_available(planet_id, int(state.player.get("level", 1)))
	var captures: int = state.planet_capture_count(planet_id)
	var visited := captures > 0
	var accent := Color(str(planet.accent))
	var card := host.panel(HBoxContainer.new(), Color("#0d1530"), 16, 14)
	card.name = "CareerPlanet_%s" % planet_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 9)
	var icon: Control = PlanetIconScript.new()
	icon.name = "CareerPlanetIcon_%s" % planet_id
	icon.custom_minimum_size = Vector2(64, 64)
	icon.configure(planet, unlocked, planet_id == str(state.player.get("current_planet_id", Content.PLANET.id)))
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(localized_content_field("planet", planet, "name").to_upper(), UIDesignSystem.FONT_BODY, accent if unlocked else host.MUTED))
	var planet_targets := 0
	for target in Content.TARGETS:
		if str(target.get("planet_id", "")) == planet_id:
			planet_targets += 1
	var target_captures := maxi(1, planet_targets * 3)
	var progress := ProgressBar.new()
	progress.name = "CareerPlanetProgress_%s" % planet_id
	progress.max_value = target_captures
	progress.value = mini(captures, target_captures)
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	progress.add_theme_stylebox_override("background", host.box_style(Color("#071025"), 4))
	progress.add_theme_stylebox_override("fill", host.box_style(accent if unlocked else host.MUTED.darkened(0.35), 4))
	copy.add_child(progress)
	copy.add_child(host.label(t("CAREER_PLANET_CAPTURES", "%d CAPTURAS · ROTA-BASE %s", [captures, format_duration(float(planet.get("travel_duration", 0.0)))]), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var status: String = t("CAREER_VISITED", "VISITADO") if visited else (t("CAREER_DISCOVERED", "DESCOBERTO") if unlocked else t("GALAXY_LOCKED", "BLOQUEADO"))
	var status_copy := VBoxContainer.new()
	status_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(status_copy)
	status_copy.add_child(host.label("✓" if visited else ("→" if unlocked else "×"), UIDesignSystem.FONT_BODY, host.LIME if visited else (host.GOLD if unlocked else host.MUTED), HORIZONTAL_ALIGNMENT_CENTER))
	status_copy.add_child(host.label(status, UIDesignSystem.FONT_CAPTION, host.LIME if visited else (host.GOLD if unlocked else host.MUTED), HORIZONTAL_ALIGNMENT_RIGHT))
	return card


static func format_duration(seconds: float) -> String:
	var rounded := maxi(0, ceili(seconds))
	if rounded >= 60:
		return "%dmin %02ds" % [rounded / 60, rounded % 60]
	return "%ds" % rounded


static func challenge_progress_card(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var unlocked := ChallengeRulesScript.is_unlocked(state.player)
	var floor := ChallengeRulesScript.progress(state.player)
	var total := ChallengeRulesScript.STAGES.size()
	var complete := floor >= total
	var accent: Color = host.CORAL if unlocked else host.MUTED
	var card := host.panel(HBoxContainer.new(), Color("#181630") if unlocked else Color("#0a1025"), 12, 11)
	card.name = "CareerChallengeProgress"
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	var seal := host.center_label("✓" if complete else ("◇" if unlocked else "×"), UIDesignSystem.FONT_EMPHASIS, host.LIME if complete else accent)
	seal.custom_minimum_size = Vector2(40, 48)
	row.add_child(seal)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(t("RIFT_TITLE", "FENDA CLANDESTINA"), UIDesignSystem.FONT_BODY, host.LIME if complete else accent))
	var progress := ProgressBar.new()
	progress.name = "CareerChallengeBar"
	progress.max_value = total
	progress.value = floor
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 7)
	progress.add_theme_stylebox_override("background", host.box_style(Color("#071025"), 4))
	progress.add_theme_stylebox_override("fill", host.box_style(host.CORAL if unlocked else host.MUTED.darkened(0.35), 4))
	copy.add_child(progress)
	var detail := t("CAREER_RIFT_LOCKED", "BLOQUEADA · DESBLOQUEIA NO NÍVEL %d", [ChallengeRulesScript.UNLOCK_LEVEL])
	if complete:
		detail = t("CAREER_RIFT_COMPLETE", "%d/%d ANDARES · ARQUIVO CONCLUÍDO", [floor, total])
	elif unlocked:
		var stage := ChallengeRulesScript.current_stage(state.player)
		detail = t("CAREER_RIFT_NEXT", "%d/%d LIMPOS · PRÓXIMO: %s", [floor, total, localized_content_field("rift_stage", stage, "name").to_upper()])
	var detail_label := host.label(detail, UIDesignSystem.FONT_CAPTION, host.MUTED)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail_label)
	var status := t("CAREER_LOCKED_FEMININE", "BLOQUEADA")
	if complete:
		status = t("CAREER_COMPLETE_FEMININE", "COMPLETA")
	elif unlocked:
		match ChallengeRulesScript.sector_slot_for_floor(floor):
			"rig":
				status = t("CAREER_RIGS", "CINTOS\nTÉCNICOS")
			"implant":
				status = t("CAREER_IMPLANTS", "IMPLANTES")
			"gadget":
				status = t("CAREER_GADGETS", "DISPOSITIVOS")
			"relic":
				status = t("CAREER_RELICS", "RELÍQUIAS")
	var action_column := VBoxContainer.new()
	action_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(action_column)
	action_column.add_child(host.label(status, UIDesignSystem.FONT_CAPTION, host.LIME if complete else accent, HORIZONTAL_ALIGNMENT_CENTER))
	if unlocked and not complete:
		var action := host.action_button(t("CAREER_OPEN", "ABRIR"), host.CORAL, true)
		action.name = "CareerChallengeAction"
		action.custom_minimum_size = Vector2(104, 72)
		action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		action.pressed.connect(func():
			host.view_mode = "challenges"
			if host.has_method("render"):
				host.call("render")
		)
		action_column.add_child(action)
	return card


static func milestone_card(host: CrookedUIFactory, state: StateScript, milestone: Dictionary) -> PanelContainer:
	var complete := bool(milestone.complete)
	var claimed := bool(milestone.claimed)
	var card := host.panel(HBoxContainer.new(), Color("#11213a") if complete else Color("#0a1025"), 11, 10)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	row.add_child(host.center_label("✓" if claimed else ("!" if complete else "·"), UIDesignSystem.FONT_BODY, host.LIME if claimed else (host.GOLD if complete else host.MUTED)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(milestone.name), UIDesignSystem.FONT_BODY, host.LIME if claimed else (host.GOLD if complete else host.INK)))
	var milestone_description := host.label(str(milestone.description), UIDesignSystem.FONT_CAPTION, host.MUTED)
	milestone_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(milestone_description)
	var reward_text := "◈ %d" % int(milestone.credits)
	if int(milestone.scrap) > 0:
		reward_text += t("CAREER_REWARD_SCRAP", " · %d sucata", [int(milestone.scrap)])
	if claimed:
		row.add_child(host.label(t("CAREER_CLAIMED", "RESGATADO"), UIDesignSystem.FONT_CAPTION, host.LIME, HORIZONTAL_ALIGNMENT_RIGHT))
	elif complete:
		var claim := host.action_button(t("CAREER_CLAIM", "RESGATAR\n%s", [reward_text]), host.GOLD)
		claim.name = "ClaimMilestone_%s" % str(milestone.id)
		claim.custom_minimum_size = Vector2(132, 72)
		claim.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		var milestone_id := str(milestone.id)
		claim.pressed.connect(func(): state.claim_career_milestone(milestone_id))
		row.add_child(claim)
	else:
		row.add_child(host.label(reward_text, UIDesignSystem.FONT_CAPTION, host.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	return card


static func target_card(host: CrookedUIFactory, state: StateScript, target: Dictionary) -> PanelContainer:
	var target_id := str(target.id)
	var planet_id := str(target.get("planet_id", Content.PLANET.id))
	var planet := Content.get_planet(planet_id)
	var captures := int(state.player.get("captures_by_target", {}).get(target_id, 0))
	var planet_unlocked: bool = MissionRules.is_planet_available(planet_id, int(state.player.get("level", 1)))
	var revealed: bool = captures > 0 or planet_unlocked
	var card := host.panel(HBoxContainer.new(), Color("#101d39") if revealed else Color("#080e20"), 12, 10)
	card.name = "CareerTarget_%s" % target_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 11)
	if revealed:
		row.add_child(host.character_portrait(target_id, 58))
	else:
		var classified := host.center_label("?", UIDesignSystem.FONT_SECTION_TITLE, host.MUTED)
		classified.custom_minimum_size = Vector2(58, 58)
		row.add_child(classified)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(localized_content_field("target", target, "name") if revealed else t("CAREER_CLASSIFIED_WARRANT", "MANDADO CLASSIFICADO"), UIDesignSystem.FONT_BODY, Color(str(planet.accent)) if revealed else host.MUTED))
	var target_context := host.label("%s · %s" % [localized_content_field("planet", planet, "name"), localized_content_field("target", target, "title") if revealed else t("CAREER_INSUFFICIENT_CREDENTIALS", "credenciais insuficientes")], UIDesignSystem.FONT_CAPTION, host.MUTED)
	target_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(target_context)
	var record := t("CAREER_TARGET_CAPTURES", "CAPTURAS %d", [captures]) if captures > 0 else (t("CAREER_AVAILABLE", "DISPONÍVEL") if revealed else t("GALAXY_LOCKED", "BLOQUEADO"))
	if captures > 0:
		record += t("CAREER_TARGET_MASTERY", " · PERÍCIA %d/3", [Rules.target_mastery_level(captures)])
	var record_box := VBoxContainer.new()
	record_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(record_box)
	record_box.add_child(host.label(record, UIDesignSystem.FONT_CAPTION, host.LIME if captures > 0 else (host.GOLD if revealed else host.MUTED), HORIZONTAL_ALIGNMENT_RIGHT))
	if planet_unlocked:
		var open_target := host.action_button(t("CAREER_OPEN", "ABRIR"), Color(str(planet.accent)), true)
		open_target.name = "CareerTargetAction_%s" % target_id
		open_target.custom_minimum_size = Vector2(104, 72)
		open_target.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		open_target.pressed.connect(func():
			host.view_mode = "board"
			host.briefing_context = {}
			var offer := MissionRules.offer_for_target(state.player, Content.get_target(target_id))
			if not offer.is_empty():
				state.select_bounty(offer)
		)
		record_box.add_child(open_target)
	return card


static func t(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_content_field(prefix: String, definition: Dictionary, field: String) -> String:
	return t(LocaleRules.content_key(prefix, str(definition.get("id", "")), field), str(definition.get(field, "")))
