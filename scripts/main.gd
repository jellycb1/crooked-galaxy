extends Control

const SpaceBackdropScript = preload("res://scripts/space_backdrop.gd")
const CombatBackdropScript = preload("res://scripts/combat_backdrop.gd")
const PortraitScript = preload("res://scripts/procedural_portrait.gd")
const SoundFXScript = preload("res://scripts/sound_fx.gd")
const INK := Color("#f4f2ff")
const MUTED := Color("#9da8c8")
const CYAN := Color("#55e5ff")
const LIME := Color("#b8f45d")
const GOLD := Color("#ffc857")
const CORAL := Color("#ff6f7d")
const PANEL := Color("#111a38")
const PANEL_LIGHT := Color("#18264b")

var body: VBoxContainer
var content: VBoxContainer
var combat_timer: Timer
var victory_timer: Timer
var last_combat_message := ""
var view_mode := "board"
var combat_fast := false
var sound_fx: Node
var previous_phase := -1


func _ready() -> void:
	build_shell()
	GameState.changed.connect(render)
	get_tree().set_auto_accept_quit(false)
	render()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()
		get_tree().quit()


func build_shell() -> void:
	var background: Control = SpaceBackdropScript.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	sound_fx = SoundFXScript.new()
	add_child(sound_fx)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 30)
	safe.add_theme_constant_override("margin_right", 30)
	safe.add_theme_constant_override("margin_top", 28)
	safe.add_theme_constant_override("margin_bottom", 24)
	add_child(safe)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	safe.add_child(body)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	body.add_child(content)

	combat_timer = Timer.new()
	combat_timer.wait_time = 0.72
	combat_timer.timeout.connect(on_combat_timer)
	add_child(combat_timer)
	victory_timer = Timer.new()
	victory_timer.one_shot = true
	victory_timer.wait_time = 1.35
	victory_timer.timeout.connect(GameState.open_reward)
	add_child(victory_timer)

	var hunt_timer := Timer.new()
	hunt_timer.wait_time = 0.1
	hunt_timer.timeout.connect(on_hunt_timer)
	hunt_timer.autostart = true
	add_child(hunt_timer)


func render() -> void:
	if sound_fx:
		sound_fx.enabled = bool(GameState.player.get("sound_enabled", true))
	var phase_changed := previous_phase >= 0 and previous_phase != GameState.phase
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
	for child in content.get_children():
		child.queue_free()
	build_header()
	match GameState.phase:
		GameState.Phase.BOARD:
			if view_mode == "arsenal":
				build_arsenal()
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
	if GameState.phase == GameState.Phase.COMBAT:
		if combat_timer.is_stopped():
			combat_timer.start()
	else:
		combat_timer.stop()
	if GameState.phase == GameState.Phase.VICTORY:
		if victory_timer.is_stopped():
			victory_timer.start()
	else:
		victory_timer.stop()


func build_header() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(identity)
	identity.add_child(label("CROOKED GALAXY", 30, CYAN))
	identity.add_child(label(ContentDB.PLANET.name.to_upper(), 15, MUTED))

	var level_badge := panel(VBoxContainer.new(), PANEL_LIGHT, 14, 14)
	level_badge.custom_minimum_size = Vector2(122, 72)
	top.add_child(level_badge)
	var badge_box := level_badge.get_child(0) as VBoxContainer
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_box.add_child(label("NÍVEL %d" % int(GameState.player.level), 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	badge_box.add_child(label("PODER %d" % CoreRules.player_power(GameState.player), 18, INK, HORIZONTAL_ALIGNMENT_CENTER))

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	content.add_child(stats)
	stats.add_child(stat_chip("CRÉDITOS", str(GameState.player.credits), GOLD))
	stats.add_child(stat_chip("REPUTAÇÃO", "RANK %d" % (int(GameState.player.reputation) + 1), LIME))
	stats.add_child(stat_chip("VITÓRIAS", str(GameState.player.wins), CYAN))


func build_board() -> void:
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	title_box.add_child(label("QUADRO DE PROCURADOS", 24, INK))
	title_box.add_child(label(ContentDB.PLANET.subtitle, 15, MUTED))

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	title_row.add_child(actions)
	var xp_needed := CoreRules.xp_needed(int(GameState.player.level))
	var xp_text := "XP %d/%d" % [int(GameState.player.xp), xp_needed]
	actions.add_child(label(xp_text, 14, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	var arsenal := action_button("ARSENAL · %d" % GameState.player.inventory.size(), GOLD, true)
	arsenal.custom_minimum_size = Vector2(160, 42)
	arsenal.add_theme_font_size_override("font_size", 13)
	arsenal.pressed.connect(func():
		view_mode = "arsenal"
		render()
	)
	actions.add_child(arsenal)

	if not GameState.last_notice.is_empty():
		content.add_child(notice_banner(GameState.last_notice, LIME))
	elif int(GameState.player.wins) == 0:
		content.add_child(onboarding_banner())

	var scroller := ScrollContainer.new()
	scroller.name = "BountyScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroller.add_child(list)
	for bounty in ContentDB.available_bounties(int(GameState.player.reputation)):
		list.add_child(bounty_card(bounty))

	content.add_child(rank_progress_panel())
	var equipment := HBoxContainer.new()
	equipment.add_theme_constant_override("separation", 10)
	content.add_child(equipment)
	equipment.add_child(equipment_chip(GameState.player.weapon))
	equipment.add_child(equipment_chip(GameState.player.armor))


func rank_progress_panel() -> PanelContainer:
	var rank := int(GameState.player.reputation)
	var next_target: Dictionary = {}
	for target in ContentDB.TARGETS:
		if int(target.rank) == rank + 1:
			next_target = target
			break
	var card := panel(VBoxContainer.new(), Color("#0d1530"), 12, 11)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	box.add_child(row)
	if next_target.is_empty():
		var planet_complete: bool = GameState.player.get("completed_planets", []).has(ContentDB.PLANET.id)
		row.add_child(label("RANK MÁXIMO DE DUSTBALL PRIME" if planet_complete else "ALVO-CHEFE DISPONÍVEL", 12, LIME if planet_complete else CORAL))
		var complete := label("SETOR DOMINADO" if planet_complete else "EXECUTE O MANDADO FINAL", 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		complete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(complete)
		return card
	var progress_value := int(GameState.player.wins) % 3
	row.add_child(label("PRÓXIMO ALVO: %s" % str(next_target.name).to_upper(), 12, MUTED))
	var count := label("%d / 3 CAPTURAS" % progress_value, 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(count)
	var progress := ProgressBar.new()
	progress.max_value = 3
	progress.value = progress_value
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 5))
	progress.add_theme_stylebox_override("fill", box_style(GOLD, 5))
	box.add_child(progress)
	return card


func build_arsenal() -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(label("ARSENAL", 26, INK))
	titles.add_child(label("Troque peças para ajustar seu poder de caça.", 14, MUTED))
	var back := action_button("VOLTAR", CYAN, true)
	back.custom_minimum_size = Vector2(130, 48)
	back.pressed.connect(func():
		view_mode = "board"
		render()
	)
	title_row.add_child(back)

	var equipped_title := label("EQUIPADO · PODER TOTAL %d" % CoreRules.player_power(GameState.player), 14, GOLD)
	content.add_child(equipped_title)
	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 10)
	content.add_child(equipped_row)
	equipped_row.add_child(equipment_chip(GameState.player.weapon))
	equipped_row.add_child(equipment_chip(GameState.player.armor))

	var inventory_title := label("ITENS ENCONTRADOS", 14, MUTED)
	content.add_child(inventory_title)
	var scroller := ScrollContainer.new()
	scroller.name = "InventoryScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroller.add_child(list)
	var items: Array = GameState.player.inventory.duplicate(true)
	items.sort_custom(func(a, b): return int(a.power) > int(b.power))
	if items.is_empty():
		var empty := panel(VBoxContainer.new(), PANEL, 24, 24)
		var empty_box := empty.get_child(0) as VBoxContainer
		empty_box.add_child(center_label("Seu arsenal ainda ecoa de tão vazio.", 18, MUTED))
		empty_box.add_child(center_label("Conclua uma bounty para encontrar equipamento.", 14, MUTED))
		list.add_child(empty)
	else:
		for item in items:
			list.add_child(inventory_item_card(item))

	var audio := action_button("SOM · %s" % ("LIGADO" if bool(GameState.player.get("sound_enabled", true)) else "DESLIGADO"), CYAN, true)
	audio.custom_minimum_size = Vector2(0, 48)
	audio.pressed.connect(GameState.toggle_sound)
	content.add_child(audio)
	if OS.is_debug_build():
		var reset := action_button("DEV · REINICIAR PROGRESSO", CORAL, true)
		reset.custom_minimum_size = Vector2(0, 48)
		reset.pressed.connect(func():
			view_mode = "board"
			GameState.reset_progress()
		)
		content.add_child(reset)


func inventory_item_card(item: Dictionary) -> PanelContainer:
	var card := panel(HBoxContainer.new(), PANEL, 15, 15)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var icon := center_label("⚙", 34, Color(str(item.color)))
	icon.custom_minimum_size = Vector2(54, 54)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(label(str(item.name), 16, INK))
	details.add_child(label("%s · %s · +%d poder" % [str(item.rarity), slot_name(str(item.slot)), int(item.power)], 13, Color(str(item.color))))
	var current: Dictionary = GameState.player[str(item.slot)]
	var equipped := str(current.get("id", "")) == str(item.get("id", ""))
	var difference := int(item.power) - int(current.power)
	var status := label("EQUIPADO" if equipped else ("%+d vs. atual" % difference), 13, LIME if difference > 0 or equipped else MUTED)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(status)
	if not equipped:
		var equip_button := action_button("EQUIPAR", CYAN, true)
		equip_button.custom_minimum_size = Vector2(110, 46)
		var item_id := str(item.id)
		equip_button.pressed.connect(func(): GameState.equip_from_inventory(item_id))
		row.add_child(equip_button)
	return card


func onboarding_banner() -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#173356"), 15, 15)
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 14)
	row.add_child(center_label("1", 30, CYAN))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label("PRIMEIRO TRABALHO", 14, CYAN))
	copy.add_child(label("Aceite Gloop. A primeira captura ensina o ciclo e garante seu primeiro loot.", 14, INK))
	return banner


func notice_banner(message: String, color: Color) -> PanelContainer:
	var banner := panel(HBoxContainer.new(), Color("#16363b"), 14, 13)
	var row := banner.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	row.add_child(label("✓", 23, color))
	var message_label := label(message, 14, INK)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(message_label)
	return banner


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
	if bool(bounty.get("boss", false)):
		details.add_child(label("CHEFE DO CAPÍTULO", 12, GOLD))
	details.add_child(label(str(bounty.name), 21, GOLD if bool(bounty.get("boss", false)) else INK))
	details.add_child(label(str(bounty.title), 14, CORAL))
	var captures: Dictionary = GameState.player.get("captures_by_target", {})
	var capture_count := int(captures.get(str(bounty.id), 0))
	if capture_count > 0:
		details.add_child(label("CAPTURAS REGISTRADAS · %d" % capture_count, 11, LIME))
	var description := label(str(bounty.description), 14, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)

	var odds := CoreRules.bounty_odds(GameState.player, bounty)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	footer.add_child(label("◈ %d   ✦ %d XP   %ds" % [int(bounty.credits), int(bounty.xp), int(bounty.duration)], 15, GOLD))
	var risk_text := "SEGURO" if odds >= 0.72 else ("ARRISCADO" if odds >= 0.42 else "BRUTAL")
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var risk := label("%s · %d%%" % [risk_text, roundi(odds * 100.0)], 14, risk_color, HORIZONTAL_ALIGNMENT_RIGHT)
	risk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(risk)
	var hunt := action_button("ANALISAR ABORDAGENS", CYAN)
	hunt.pressed.connect(func(): GameState.select_bounty(bounty))
	box.add_child(hunt)
	return card


func build_briefing() -> void:
	var bounty := GameState.current_bounty
	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 18)
	content.add_child(target_row)
	target_row.add_child(character_portrait(str(bounty.id), 104))
	var target_copy := VBoxContainer.new()
	target_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_copy.add_theme_constant_override("separation", 4)
	target_row.add_child(target_copy)
	target_copy.add_child(label("BRIEFING DO CONTRATO", 15, CYAN))
	target_copy.add_child(label(str(bounty.name), 26, INK))
	var flavor := label("O alvo é o mesmo. A quantidade de problemas é uma escolha sua.", 14, MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_copy.add_child(flavor)

	content.add_child(label("ESCOLHA UMA ABORDAGEM", 17, GOLD))
	var scroller := ScrollContainer.new()
	scroller.name = "BriefingScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroller.add_child(list)
	for approach in GameState.offered_approaches:
		list.add_child(approach_card(bounty, approach))
	var cancel := action_button("VOLTAR AO QUADRO", CORAL, true)
	cancel.custom_minimum_size = Vector2(0, 48)
	cancel.pressed.connect(GameState.cancel_briefing)
	content.add_child(cancel)


func approach_card(bounty: Dictionary, approach: Dictionary) -> PanelContainer:
	var preview := ContentDB.apply_approach(bounty, approach)
	var color := Color(str(approach.color))
	var card := panel(VBoxContainer.new(), PANEL, 16, 16)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(label(str(approach.name).to_upper(), 18, color))
	heading_copy.add_child(label(str(approach.tag), 12, MUTED))
	if int(GameState.player.wins) == 0 and str(approach.id) == "quiet_net":
		heading.add_child(label("RECOMENDADO", 12, LIME, HORIZONTAL_ALIGNMENT_RIGHT))
	var description := label(str(approach.description), 14, INK)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var odds := CoreRules.bounty_odds(GameState.player, preview)
	var risk_text := "SEGURO" if odds >= 0.72 else ("ARRISCADO" if odds >= 0.42 else "BRUTAL")
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	box.add_child(metrics)
	metrics.add_child(metric_chip("TEMPO", "%ds" % int(preview.duration), MUTED))
	metrics.add_child(metric_chip("CHANCE", "%d%%" % roundi(odds * 100.0), risk_color))
	metrics.add_child(metric_chip("PAGAMENTO", "◈ %d" % int(preview.credits), GOLD))
	metrics.add_child(metric_chip("EXPERIÊNCIA", "%d XP" % int(preview.xp), CYAN))
	var choose := action_button("ESCOLHER · %s" % risk_text, color)
	var approach_id := str(approach.id)
	choose.pressed.connect(func(): GameState.choose_approach(approach_id))
	box.add_child(choose)
	return card


func metric_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0a1025"), 9, 7)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(title, 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func build_hunt() -> void:
	var bounty := GameState.current_bounty
	content.add_spacer(false)
	content.add_child(center_label("CAÇADA EM ANDAMENTO", 19, CYAN))
	content.add_child(character_portrait(str(bounty.id), 150))
	content.add_child(center_label(str(bounty.name), 30, INK))
	var approach: Dictionary = bounty.get("approach", {})
	if not approach.is_empty():
		content.add_child(center_label(str(approach.name).to_upper(), 16, Color(str(approach.color))))
	content.add_child(center_label("Seguindo sinais, subornando robôs e fingindo ter um plano.", 16, MUTED))
	if bounty.has("hunt_event_result"):
		content.add_child(notice_banner(str(bounty.hunt_event_result), GOLD))

	var progress := ProgressBar.new()
	progress.name = "HuntProgress"
	progress.value = GameState.hunt_progress() * 100.0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 24)
	progress.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 12))
	progress.add_theme_stylebox_override("fill", box_style(CYAN, 12))
	content.add_child(progress)

	var remaining := maxi(0, ceili(GameState.hunt_ends_at - Time.get_unix_time_from_system()))
	var countdown := center_label("ALVO LOCALIZADO EM %ds" % remaining, 18, GOLD)
	countdown.name = "HuntCountdown"
	content.add_child(countdown)
	content.add_spacer(false)
	var abandon := action_button("ABANDONAR CONTRATO", CORAL, true)
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func build_hunt_event() -> void:
	var event := GameState.hunt_event
	var accent := Color(str(event.get("color", "#ffc857")))
	content.add_spacer(false)
	content.add_child(center_label("IMPREVISTO NA CAÇADA", 17, CORAL))
	var incident := panel(VBoxContainer.new(), Color("#18264b"), 20, 22)
	content.add_child(incident)
	var incident_box := incident.get_child(0) as VBoxContainer
	incident_box.alignment = BoxContainer.ALIGNMENT_CENTER
	incident_box.add_theme_constant_override("separation", 8)
	var symbol := "D-7" if str(event.get("id", "")) == "toll_drone" else "LIVE"
	incident_box.add_child(center_label(symbol, 42, accent))
	incident_box.add_child(center_label(str(event.get("title", "Algo Estranho")), 26, INK))
	var description := center_label(str(event.get("description", "A perseguição ficou mais complicada.")), 15, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	incident_box.add_child(description)
	incident_box.add_child(center_label("A CAÇA ESTÁ PAUSADA", 12, GOLD))

	var choices := VBoxContainer.new()
	choices.name = "HuntEventChoices"
	choices.add_theme_constant_override("separation", 10)
	content.add_child(choices)
	for choice in event.get("choices", []):
		choices.add_child(hunt_choice_card(choice, accent))
	content.add_spacer(false)
	var abandon := action_button("ABANDONAR CONTRATO", CORAL, true)
	abandon.custom_minimum_size = Vector2(0, 46)
	abandon.pressed.connect(GameState.abandon_bounty)
	content.add_child(abandon)


func hunt_choice_card(choice: Dictionary, accent: Color) -> PanelContainer:
	var card := panel(HBoxContainer.new(), PANEL, 13, 12)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label(str(choice.name), 15, accent))
	var effect := label(str(choice.effect_text), 13, MUTED)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(effect)
	var affordable := GameState.can_afford_hunt_choice(choice)
	var choose := action_button("ESCOLHER" if affordable else "SEM CRÉDITOS", accent, true)
	choose.custom_minimum_size = Vector2(142, 48)
	choose.disabled = not affordable
	var choice_id := str(choice.id)
	choose.pressed.connect(func(): GameState.resolve_hunt_event(choice_id))
	row.add_child(choose)
	return card


func build_combat() -> void:
	var approach: Dictionary = GameState.current_bounty.get("approach", {})
	var approach_suffix := " · %s" % str(approach.get("name", "")).to_upper() if not approach.is_empty() else ""
	content.add_child(center_label("ENCONTRO AUTOMÁTICO · TURNO %d%s" % [GameState.combat_round, approach_suffix], 17, CORAL))
	var stage := PanelContainer.new()
	stage.clip_contents = true
	stage.custom_minimum_size = Vector2(0, 390)
	stage.add_theme_stylebox_override("panel", box_style(PANEL, 18))
	content.add_child(stage)
	var backdrop: Control = CombatBackdropScript.new()
	backdrop.events = GameState.combat_events
	stage.add_child(backdrop)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 18)
	stage_margin.add_theme_constant_override("margin_right", 18)
	stage_margin.add_theme_constant_override("margin_top", 18)
	stage_margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(stage_margin)
	var stage_box := VBoxContainer.new()
	stage_box.add_theme_constant_override("separation", 8)
	stage_margin.add_child(stage_box)
	var event_row := HBoxContainer.new()
	event_row.alignment = BoxContainer.ALIGNMENT_CENTER
	event_row.add_theme_constant_override("separation", 8)
	stage_box.add_child(event_row)
	if GameState.combat_events.is_empty():
		event_row.add_child(center_label("SENSORES TRAVADOS · ARMAS CARREGADAS", 14, GOLD))
	else:
		for event in GameState.combat_events:
			event_row.add_child(combat_event_chip(event))
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 20)
	stage_box.add_child(arena)
	arena.add_child(fighter("VOCÊ", "hunter", GameState.player_hp, CoreRules.max_health(GameState.player), CYAN))
	arena.add_child(center_label("VS", 28, GOLD))
	arena.add_child(fighter(str(GameState.current_bounty.name), str(GameState.current_bounty.id), GameState.enemy_hp, int(GameState.current_bounty.health), CORAL))

	var log_panel := panel(VBoxContainer.new(), PANEL, 18, 18)
	log_panel.custom_minimum_size = Vector2(0, 105)
	content.add_child(log_panel)
	var log_box := log_panel.get_child(0) as VBoxContainer
	log_box.add_child(label("RELATÓRIO DE CAMPO", 14, MUTED))
	var message := last_combat_message if not last_combat_message.is_empty() else "Os dois lados avaliam suas escolhas de vida..."
	var log_label := label(message, 17, INK)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(log_label)
	var speed := action_button("VELOCIDADE · %s" % ("2×" if combat_fast else "1×"), CYAN, true)
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
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(str(event.get("action", "GOLPE")).to_upper(), 11, color, HORIZONTAL_ALIGNMENT_CENTER))
	var quality := str(event.get("quality", "ACERTO"))
	var quality_color := GOLD if quality == "CRÍTICO" else (MUTED if quality == "DE RASPÃO" else INK)
	box.add_child(label("%d DANO · %s" % [int(event.get("damage", 0)), quality], 12, quality_color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func build_victory() -> void:
	content.add_spacer(false)
	content.add_child(center_label("MANDADO EXECUTADO", 16, MUTED))
	content.add_child(character_portrait(str(GameState.current_bounty.id), 132))
	var stamp := panel(VBoxContainer.new(), Color("#173f3c"), 18, 22)
	content.add_child(stamp)
	var stamp_box := stamp.get_child(0) as VBoxContainer
	stamp_box.add_child(center_label("ALVO CAPTURADO", 34, LIME))
	stamp_box.add_child(center_label(str(GameState.current_bounty.name), 21, INK))
	if not GameState.combat_events.is_empty():
		var final_event: Dictionary = GameState.combat_events[0]
		stamp_box.add_child(center_label("Finalizado com %s · %d de dano" % [str(final_event.action), int(final_event.damage)], 14, GOLD))
	content.add_child(center_label("Autenticando pagamento e sacudindo os bolsos do alvo...", 15, MUTED))
	content.add_spacer(false)


func build_reward() -> void:
	var item := GameState.pending_loot
	content.add_child(center_label("CONTRATO CONCLUÍDO · %s" % str(GameState.current_bounty.name).to_upper(), 16, LIME))
	content.add_child(center_label("RECOMPENSA CAPTURADA", 32, INK))
	var reward_panel := panel(VBoxContainer.new(), PANEL_LIGHT, 26, 26)
	reward_panel.modulate = Color(1, 1, 1, 0)
	content.add_child(reward_panel)
	reward_panel.create_tween().tween_property(reward_panel, "modulate", Color.WHITE, 0.32)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.add_child(center_label("⚙", 76, Color(str(item.color))))
	box.add_child(center_label(str(item.rarity).to_upper(), 15, Color(str(item.color))))
	box.add_child(center_label(str(item.name), 25, INK))
	var description := center_label(str(item.get("description", "Procedência criativamente desconhecida.")), 15, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	box.add_child(center_label("+%d PODER · %s" % [int(item.power), slot_name(str(item.slot))], 18, GOLD))
	var equipped: Dictionary = GameState.player[str(item.slot)]
	var comparison := int(item.power) - int(equipped.power)
	var comparison_text := "+%d vs. equipado" % comparison if comparison > 0 else "%d vs. equipado" % comparison
	if comparison > 0:
		box.add_child(center_label("▲ UPGRADE ENCONTRADO", 15, LIME))
	box.add_child(center_label(comparison_text, 15, LIME if comparison > 0 else MUTED))
	box.add_child(center_label("◈ %d créditos   ✦ %d XP" % [int(GameState.current_bounty.credits), int(GameState.current_bounty.xp)], 17, GOLD))
	content.add_spacer(false)
	var equip_now := CoreRules.is_upgrade(item, equipped)
	var claim := action_button("EQUIPAR E CONTINUAR" if equip_now else "GUARDAR E CONTINUAR", LIME)
	claim.pressed.connect(func():
		GameState.claim_reward(equip_now)
	)
	content.add_child(claim)


func build_chapter_complete() -> void:
	var completion := GameState.chapter_completion
	var target: Dictionary = completion.get("target", {})
	var chapter := panel(VBoxContainer.new(), Color("#302541"), 24, 24)
	chapter.name = "ChapterComplete"
	content.add_child(chapter)
	var box := chapter.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	box.add_child(center_label("CAPÍTULO CONCLUÍDO", 16, GOLD))
	box.add_child(center_label(str(ContentDB.PLANET.name).to_upper(), 34, INK))
	box.add_child(character_portrait(str(target.get("id", "mayor_gold_dust")), 174))
	box.add_child(center_label("MANDADO FINAL EXECUTADO", 18, LIME))
	box.add_child(center_label(str(target.get("name", "Prefeito Pó-de-Ouro")), 25, GOLD))
	var verdict := center_label("O prefeito foi afastado do cargo, da delegacia e do próprio cartório. A papelada continua foragida.", 15, MUTED)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(verdict)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	box.add_child(stats)
	stats.add_child(metric_chip("CAPTURAS", str(completion.get("total_captures", GameState.player.wins)), CYAN))
	stats.add_child(metric_chip("REPUTAÇÃO", "RANK %d" % (int(GameState.player.reputation) + 1), LIME))
	stats.add_child(metric_chip("PAGAMENTO", "◈ %d" % int(completion.get("credits", 0)), GOLD))
	content.add_child(center_label("Dustball Prime permanece aberto para novas caçadas e equipamento melhor.", 14, MUTED))
	content.add_spacer(false)
	var continue_button := action_button("CONTINUAR CAÇANDO", GOLD)
	continue_button.pressed.connect(GameState.continue_after_chapter)
	content.add_child(continue_button)


func fighter(title: String, character_id: String, hp: int, maximum: int, color: Color) -> VBoxContainer:
	var fighter_box := VBoxContainer.new()
	fighter_box.custom_minimum_size = Vector2(242, 245)
	fighter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	fighter_box.add_child(character_portrait(character_id, 118))
	var name_label := center_label(title.to_upper(), 16, color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fighter_box.add_child(name_label)
	var health := ProgressBar.new()
	health.max_value = maximum
	health.value = hp
	health.show_percentage = false
	health.custom_minimum_size = Vector2(230, 20)
	health.add_theme_stylebox_override("background", box_style(PANEL_LIGHT, 10))
	health.add_theme_stylebox_override("fill", box_style(color, 10))
	fighter_box.add_child(health)
	fighter_box.add_child(center_label("%d / %d HP" % [hp, maximum], 14, MUTED))
	return fighter_box


func character_portrait(character_id: String, dimension: float) -> Control:
	var result: Control = PortraitScript.new()
	result.character_id = character_id
	result.custom_minimum_size = Vector2(dimension, dimension)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


func stat_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), PANEL, 12, 11)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(title, 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, 16, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func equipment_chip(item: Dictionary) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0d1530"), 12, 10)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(slot_name(str(item.slot)).to_upper(), 11, MUTED))
	box.add_child(label("%s  ·  +%d" % [str(item.name), int(item.power)], 13, INK))
	return chip


func panel(child: Control, color: Color, radius: int, margin: int) -> PanelContainer:
	var container := PanelContainer.new()
	var style := box_style(color, radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	container.add_theme_stylebox_override("panel", style)
	container.add_child(child)
	return container


func box_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func label(text_value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = alignment
	return result


func center_label(text_value: String, size: int, color: Color) -> Label:
	var result := label(text_value, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


func action_button(text_value: String, color: Color, outline := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 62)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", color if outline else Color("#07101c"))
	button.add_theme_color_override("font_hover_color", Color("#07101c"))
	button.add_theme_stylebox_override("normal", box_style(Color("#00000000") if outline else color, 14))
	button.add_theme_stylebox_override("hover", box_style(color.lightened(0.12), 14))
	button.add_theme_stylebox_override("pressed", box_style(color.darkened(0.14), 14))
	if outline:
		var normal := box_style(Color("#00000000"), 14)
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = color
		button.add_theme_stylebox_override("normal", normal)
	return button


func slot_name(slot: String) -> String:
	return "Arma" if slot == "weapon" else "Armadura"


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
		countdown.text = "ALVO LOCALIZADO EM %ds" % remaining


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
	var message := "+%d créditos · +%d XP" % [int(summary.credits), int(summary.xp)]
	if int(summary.levels) > 0:
		message += " · NÍVEL +%d" % int(summary.levels)
	if bool(summary.rank_up):
		message += " · NOVO RANK"
	last_combat_message = message


func show_defeat() -> void:
	last_combat_message = "O alvo escapou. Melhore seu equipamento e tente outra vez."
