class_name CareerView
extends RefCounted

const CareerRulesScript = preload("res://scripts/career_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("CARREIRA DE CAÇADOR", 25, host.INK))
	titles.add_child(host.label("A galáxia esquece crimes. Seu currículo não.", 14, host.MUTED))
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(120, 48)
	back.pressed.connect(func():
		host.view_mode = "board"
		host.call("render")
	)
	title_row.add_child(back)

	content.add_child(summary_card(host, state))
	var ready_count := state.career_rewards_ready()
	if ready_count > 0:
		var claim_all := host.action_button("RESGATAR TODOS · %d" % ready_count, host.GOLD)
		claim_all.name = "ClaimAllMilestones"
		claim_all.custom_minimum_size = Vector2(0, 48)
		claim_all.pressed.connect(state.claim_all_career_milestones)
		content.add_child(claim_all)
	var objective := CareerRulesScript.next_mastery_objective(state.player, Content.TARGETS)
	if not objective.is_empty():
		content.add_child(mastery_directive_card(host, state, objective))

	var section_nav := HBoxContainer.new()
	section_nav.name = "CareerSectionNav"
	section_nav.add_theme_constant_override("separation", 8)
	content.add_child(section_nav)
	var progress_jump := host.action_button("PROGRESSO", host.CYAN, true)
	progress_jump.name = "CareerProgressJump"
	progress_jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_nav.add_child(progress_jump)
	var archive_jump := host.action_button("PROCURADOS · %d" % Content.TARGETS.size(), host.GOLD, true)
	archive_jump.name = "CareerArchiveJump"
	archive_jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_nav.add_child(archive_jump)

	var scroller := ScrollContainer.new()
	scroller.name = "CareerScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroller.add_child(list)
	var progress_heading := host.label("PROGRESSO PLANETÁRIO", 13, host.MUTED)
	list.add_child(progress_heading)
	for planet in Content.PLANETS:
		list.add_child(planet_card(host, state, planet))
	list.add_child(host.label("MARCOS DA CARREIRA", 13, host.MUTED))
	for milestone in state.career_milestones():
		list.add_child(milestone_card(host, state, milestone))
	var archive_heading := host.label("ARQUIVO DE PROCURADOS", 13, host.MUTED)
	archive_heading.name = "WantedArchiveHeading"
	list.add_child(archive_heading)
	for target in Content.TARGETS:
		list.add_child(target_card(host, state, target))
	progress_jump.pressed.connect(func(): scroll_to_section(scroller, progress_heading))
	archive_jump.pressed.connect(func(): scroll_to_section(scroller, archive_heading))


static func scroll_to_section(scroller: ScrollContainer, heading: Control) -> void:
	scroller.scroll_vertical = maxi(0, roundi(heading.position.y))


static func summary_card(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var summary := host.panel(HBoxContainer.new(), host.PANEL_LIGHT, 16, 15)
	summary.name = "CareerSummary"
	var row := summary.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	row.add_child(host.character_portrait("hunter", 76))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label("CAÇADOR NÍVEL %d" % int(state.player.level), 18, host.GOLD))
	copy.add_child(host.label("%d capturas · %d planetas concluídos" % [int(state.player.wins), state.player.get("completed_planets", []).size()], 14, host.INK))
	copy.add_child(host.label("Patrulhas AFK: ◈ %d · %d sucata" % [int(state.player.get("afk_credits_earned", 0)), int(state.player.get("afk_scrap_earned", 0))], 12, host.MUTED))
	copy.add_child(host.label("Prêmios: ◈ %d · %d sucata" % [int(state.player.get("career_credits_claimed", 0)), int(state.player.get("career_scrap_claimed", 0))], 12, host.MUTED))
	var complete_count := 0
	var milestones := state.career_milestones()
	for milestone in milestones:
		if bool(milestone.complete):
			complete_count += 1
	var badge_text := "MARCOS\n%d / %d" % [complete_count, milestones.size()]
	var ready_count := state.career_rewards_ready()
	if ready_count > 0:
		badge_text += "\n%d A RESGATAR" % ready_count
	var badge := host.center_label(badge_text, 13, host.LIME)
	badge.custom_minimum_size = Vector2(75, 70)
	row.add_child(badge)
	return summary


static func mastery_directive_card(host: CrookedUIFactory, state: StateScript, objective: Dictionary) -> PanelContainer:
	var target: Dictionary = objective.target
	var planet := Content.get_planet(str(target.planet_id))
	var card := host.panel(HBoxContainer.new(), Color("#152a42"), 13, 12)
	card.name = "MasteryDirective"
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	row.add_child(host.character_portrait(str(target.id), 58))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label("PRÓXIMA PERÍCIA · %s" % str(target.name).to_upper(), 13, host.GOLD))
	copy.add_child(host.label("Faltam %d captura%s para perícia %d/3" % [int(objective.remaining), "s" if int(objective.remaining) != 1 else "", int(objective.next_level)], 12, host.INK))
	copy.add_child(host.label("Próximo bônus: +%d%% raro · +%d%% épico · +%d sucata" % [int(objective.rare_bonus), int(objective.epic_bonus), int(objective.scrap_bonus)], 11, host.LIME))
	var action := host.action_button("CAÇAR\nAGORA", Color(str(planet.accent)), true)
	action.name = "MasteryDirectiveAction"
	action.custom_minimum_size = Vector2(105, 52)
	action.add_theme_font_size_override("font_size", 10)
	var planet_id := str(target.planet_id)
	var target_id := str(target.id)
	action.pressed.connect(func():
		host.view_mode = "board"
		if state.travel_to_planet(planet_id):
			state.select_bounty(Content.get_target(target_id))
	)
	row.add_child(action)
	return card


static func planet_card(host: CrookedUIFactory, state: StateScript, planet: Dictionary) -> PanelContainer:
	var planet_id := str(planet.id)
	var completed: bool = state.player.get("completed_planets", []).has(planet_id)
	var unlocked: bool = Content.is_planet_unlocked(planet_id, state.player.get("completed_planets", []))
	var captures: int = state.planet_capture_count(planet_id)
	var accent := Color(str(planet.accent))
	var card := host.panel(HBoxContainer.new(), Color("#0d1530"), 12, 11)
	var row := card.get_child(0) as HBoxContainer
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(planet.name).to_upper(), 15, accent if unlocked else host.MUTED))
	copy.add_child(host.label("%d capturas · Tier %d/3" % [captures, state.planet_tier(planet_id)], 12, host.MUTED))
	var status: String = "CONCLUÍDO" if completed else ("EM ANDAMENTO" if unlocked else "BLOQUEADO")
	row.add_child(host.label(status, 12, host.LIME if completed else (host.GOLD if unlocked else host.MUTED), HORIZONTAL_ALIGNMENT_RIGHT))
	return card


static func milestone_card(host: CrookedUIFactory, state: StateScript, milestone: Dictionary) -> PanelContainer:
	var complete := bool(milestone.complete)
	var claimed := bool(milestone.claimed)
	var card := host.panel(HBoxContainer.new(), Color("#11213a") if complete else Color("#0a1025"), 11, 10)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 10)
	row.add_child(host.center_label("✓" if claimed else ("!" if complete else "·"), 22, host.LIME if claimed else (host.GOLD if complete else host.MUTED)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(milestone.name), 13, host.LIME if claimed else (host.GOLD if complete else host.INK)))
	copy.add_child(host.label(str(milestone.description), 12, host.MUTED))
	var reward_text := "◈ %d" % int(milestone.credits)
	if int(milestone.scrap) > 0:
		reward_text += " · %d sucata" % int(milestone.scrap)
	if claimed:
		row.add_child(host.label("RESGATADO", 11, host.LIME, HORIZONTAL_ALIGNMENT_RIGHT))
	elif complete:
		var claim := host.action_button("RESGATAR\n%s" % reward_text, host.GOLD)
		claim.name = "ClaimMilestone_%s" % str(milestone.id)
		claim.custom_minimum_size = Vector2(112, 48)
		claim.add_theme_font_size_override("font_size", 10)
		var milestone_id := str(milestone.id)
		claim.pressed.connect(func(): state.claim_career_milestone(milestone_id))
		row.add_child(claim)
	else:
		row.add_child(host.label(reward_text, 11, host.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	return card


static func target_card(host: CrookedUIFactory, state: StateScript, target: Dictionary) -> PanelContainer:
	var target_id := str(target.id)
	var planet_id := str(target.get("planet_id", Content.PLANET.id))
	var planet := Content.get_planet(planet_id)
	var captures := int(state.player.get("captures_by_target", {}).get(target_id, 0))
	var planet_unlocked: bool = Content.is_planet_unlocked(planet_id, state.player.get("completed_planets", []))
	var tier_available: bool = int(target.get("chapter_tier", target.rank)) <= state.planet_tier(planet_id)
	var revealed: bool = captures > 0 or (planet_unlocked and tier_available)
	var card := host.panel(HBoxContainer.new(), Color("#101d39") if revealed else Color("#080e20"), 12, 10)
	card.name = "CareerTarget_%s" % target_id
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 11)
	if revealed:
		row.add_child(host.character_portrait(target_id, 58))
	else:
		var classified := host.center_label("?", 28, host.MUTED)
		classified.custom_minimum_size = Vector2(58, 58)
		row.add_child(classified)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label(str(target.name) if revealed else "MANDADO CLASSIFICADO", 14, Color(str(planet.accent)) if revealed else host.MUTED))
	copy.add_child(host.label("%s · %s" % [str(planet.name), str(target.title) if revealed else "credenciais insuficientes"], 11, host.MUTED))
	var record := "CAPTURAS %d" % captures if captures > 0 else ("DISPONÍVEL" if revealed else "BLOQUEADO")
	if captures > 0:
		record += " · PERÍCIA %d/3" % Rules.target_mastery_level(captures)
	row.add_child(host.label(record, 11, host.LIME if captures > 0 else (host.GOLD if revealed else host.MUTED), HORIZONTAL_ALIGNMENT_RIGHT))
	return card
