extends Control

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
var last_combat_message := ""


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
	var background := ColorRect.new()
	background.color = Color("#070b1d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var glow := ColorRect.new()
	glow.color = Color("#10234b")
	glow.position = Vector2(0, 0)
	glow.size = Vector2(720, 260)
	background.add_child(glow)

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

	var hunt_timer := Timer.new()
	hunt_timer.wait_time = 0.1
	hunt_timer.timeout.connect(on_hunt_timer)
	hunt_timer.autostart = true
	add_child(hunt_timer)


func render() -> void:
	for child in content.get_children():
		child.queue_free()
	build_header()
	match GameState.phase:
		GameState.Phase.BOARD:
			build_board()
		GameState.Phase.HUNT:
			build_hunt()
		GameState.Phase.COMBAT:
			build_combat()
		GameState.Phase.REWARD:
			build_reward()
	if GameState.phase == GameState.Phase.COMBAT:
		if combat_timer.is_stopped():
			combat_timer.start()
	else:
		combat_timer.stop()


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

	var xp_needed := CoreRules.xp_needed(int(GameState.player.level))
	var xp_text := "XP %d/%d" % [int(GameState.player.xp), xp_needed]
	title_row.add_child(label(xp_text, 14, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroller.add_child(list)
	for bounty in ContentDB.available_bounties(int(GameState.player.reputation)):
		list.add_child(bounty_card(bounty))

	var equipment := HBoxContainer.new()
	equipment.add_theme_constant_override("separation", 10)
	content.add_child(equipment)
	equipment.add_child(equipment_chip(GameState.player.weapon))
	equipment.add_child(equipment_chip(GameState.player.armor))


func bounty_card(bounty: Dictionary) -> PanelContainer:
	var card := panel(VBoxContainer.new(), PANEL, 18, 20)
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var portrait := Label.new()
	portrait.text = str(bounty.emoji)
	portrait.add_theme_font_size_override("font_size", 54)
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.custom_minimum_size = Vector2(88, 88)
	row.add_child(portrait)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(label(str(bounty.name), 21, INK))
	details.add_child(label(str(bounty.title), 14, CORAL))
	var description := label(str(bounty.description), 14, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)

	var odds := CoreRules.bounty_odds(CoreRules.player_power(GameState.player), int(bounty.power))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	footer.add_child(label("◈ %d   ✦ %d XP   %ds" % [int(bounty.credits), int(bounty.xp), int(bounty.duration)], 15, GOLD))
	var risk_text := "SEGURO" if odds >= 0.72 else ("ARRISCADO" if odds >= 0.42 else "BRUTAL")
	var risk_color := LIME if odds >= 0.72 else (GOLD if odds >= 0.42 else CORAL)
	var risk := label("%s · %d%%" % [risk_text, roundi(odds * 100.0)], 14, risk_color, HORIZONTAL_ALIGNMENT_RIGHT)
	risk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(risk)
	var hunt := action_button("ACEITAR CONTRATO", CYAN)
	hunt.pressed.connect(func(): GameState.start_bounty(bounty))
	box.add_child(hunt)
	return card


func build_hunt() -> void:
	var bounty := GameState.current_bounty
	content.add_spacer(false)
	content.add_child(center_label("CAÇADA EM ANDAMENTO", 19, CYAN))
	content.add_child(center_label(str(bounty.emoji), 112, INK))
	content.add_child(center_label(str(bounty.name), 30, INK))
	content.add_child(center_label("Seguindo sinais, subornando robôs e fingindo ter um plano.", 16, MUTED))

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


func build_combat() -> void:
	content.add_child(center_label("ENCONTRO AUTOMÁTICO · TURNO %d" % GameState.combat_round, 17, CORAL))
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 26)
	content.add_child(arena)
	arena.add_child(fighter("VOCÊ", "🤠", GameState.player_hp, CoreRules.max_health(GameState.player), CYAN))
	arena.add_child(center_label("VS", 28, GOLD))
	arena.add_child(fighter(str(GameState.current_bounty.name), str(GameState.current_bounty.emoji), GameState.enemy_hp, int(GameState.current_bounty.health), CORAL))

	var log_panel := panel(VBoxContainer.new(), PANEL, 18, 18)
	log_panel.custom_minimum_size = Vector2(0, 130)
	content.add_child(log_panel)
	var log_box := log_panel.get_child(0) as VBoxContainer
	log_box.add_child(label("RELATÓRIO DE CAMPO", 14, MUTED))
	var message := last_combat_message if not last_combat_message.is_empty() else "Os dois lados avaliam suas escolhas de vida..."
	var log_label := label(message, 17, INK)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(log_label)
	content.add_child(center_label("O combate prossegue automaticamente", 14, MUTED))


func build_reward() -> void:
	var item := GameState.pending_loot
	content.add_spacer(false)
	content.add_child(center_label("CONTRATO CONCLUÍDO", 22, LIME))
	content.add_child(center_label("RECOMPENSA CAPTURADA", 32, INK))
	var reward_panel := panel(VBoxContainer.new(), PANEL_LIGHT, 26, 26)
	content.add_child(reward_panel)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.add_child(center_label("⚙", 76, Color(str(item.color))))
	box.add_child(center_label(str(item.rarity).to_upper(), 15, Color(str(item.color))))
	box.add_child(center_label(str(item.name), 25, INK))
	box.add_child(center_label("+%d PODER · %s" % [int(item.power), slot_name(str(item.slot))], 18, GOLD))
	var equipped: Dictionary = GameState.player[str(item.slot)]
	var comparison := int(item.power) - int(equipped.power)
	var comparison_text := "+%d vs. equipado" % comparison if comparison > 0 else "%d vs. equipado" % comparison
	box.add_child(center_label(comparison_text, 15, LIME if comparison > 0 else MUTED))
	box.add_child(center_label("◈ %d créditos   ✦ %d XP" % [int(GameState.current_bounty.credits), int(GameState.current_bounty.xp)], 17, GOLD))
	content.add_spacer(false)
	var equip_now := CoreRules.is_upgrade(item, equipped)
	var claim := action_button("EQUIPAR E CONTINUAR" if equip_now else "GUARDAR E CONTINUAR", LIME)
	claim.pressed.connect(func():
		var summary := GameState.claim_reward(equip_now)
		show_toast(summary)
	)
	content.add_child(claim)


func fighter(title: String, icon: String, hp: int, maximum: int, color: Color) -> VBoxContainer:
	var fighter_box := VBoxContainer.new()
	fighter_box.custom_minimum_size = Vector2(250, 260)
	fighter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	fighter_box.add_child(center_label(icon, 88, INK))
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
