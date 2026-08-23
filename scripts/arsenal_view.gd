class_name ArsenalView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("ARSENAL", 26, host.INK))
	titles.add_child(host.label("Troque peças para ajustar seu poder de caça.", 14, host.MUTED))
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(130, 48)
	back.pressed.connect(func():
		host.view_mode = "board"
		host.call("render")
	)
	title_row.add_child(back)

	content.add_child(host.label("OFICINA · %d SUCATA · PODER TOTAL %d" % [int(state.player.get("scrap", 0)), Rules.player_power(state.player)], 14, host.GOLD))
	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 10)
	content.add_child(equipped_row)
	equipped_row.add_child(workshop_upgrade_card(host, state, "weapon"))
	equipped_row.add_child(workshop_upgrade_card(host, state, "armor"))
	content.add_child(loadout_toolbar(host, state))

	var visible_items := filtered_inventory(host, state)
	content.add_child(host.label("ITENS ENCONTRADOS · %d / %d" % [visible_items.size(), state.player.inventory.size()], 14, host.MUTED))
	content.add_child(inventory_toolbar(host, state))
	var scroller := ScrollContainer.new()
	scroller.name = "InventoryScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroller.add_child(list)
	if visible_items.is_empty():
		var empty := host.panel(VBoxContainer.new(), host.PANEL, 24, 24)
		var empty_box := empty.get_child(0) as VBoxContainer
		empty_box.add_child(host.center_label("Nenhuma peça neste filtro.", 18, host.MUTED))
		empty_box.add_child(host.center_label("Outros compartimentos talvez estejam menos vazios.", 14, host.MUTED))
		list.add_child(empty)
	else:
		for item in visible_items:
			list.add_child(inventory_item_card(host, state, item))

	var audio := host.action_button("SOM · %s" % ("LIGADO" if bool(state.player.get("sound_enabled", true)) else "DESLIGADO"), host.CYAN, true)
	audio.custom_minimum_size = Vector2(0, 48)
	audio.pressed.connect(state.toggle_sound)
	content.add_child(audio)
	if OS.is_debug_build():
		var reset := host.action_button("DEV · REINICIAR PROGRESSO", host.CORAL, true)
		reset.custom_minimum_size = Vector2(0, 48)
		reset.pressed.connect(func():
			host.view_mode = "board"
			state.reset_progress()
		)
		content.add_child(reset)


static func filtered_inventory(host: CrookedUIFactory, state: StateScript) -> Array:
	return EquipmentPresentation.filtered_inventory(state.player.inventory, host.inventory_filter, host.inventory_sort)


static func inventory_toolbar(host: CrookedUIFactory, state: StateScript) -> VBoxContainer:
	var toolbar := VBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 7)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	toolbar.add_child(filters)
	for definition in [
		{"id": "all", "text": "TODOS"},
		{"id": "weapon", "text": "ARMAS"},
		{"id": "armor", "text": "ARMADURAS"},
	]:
		var mode := str(definition.id)
		var selected := host.inventory_filter == mode
		var filter_button := host.action_button(str(definition.text), host.CYAN if selected else host.MUTED, not selected)
		filter_button.name = "InventoryFilter_%s" % mode
		filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_button.custom_minimum_size = Vector2(0, 44)
		filter_button.add_theme_font_size_override("font_size", 10)
		filter_button.pressed.connect(func():
			host.inventory_filter = mode
			host.call("render")
		)
		filters.add_child(filter_button)
	var sort := host.action_button("ORDEM · %s" % ("RARIDADE" if host.inventory_sort == "rarity" else "PODER"), host.GOLD, true)
	sort.name = "InventorySort"
	sort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort.custom_minimum_size = Vector2(0, 44)
	sort.add_theme_font_size_override("font_size", 10)
	sort.pressed.connect(func():
		host.inventory_sort = "rarity" if host.inventory_sort == "power" else "power"
		host.call("render")
	)
	filters.add_child(sort)
	var preview := state.inferior_recycle_preview()
	var recycle := host.action_button("RECICLAR INFERIORES · %d PEÇAS · +%d SUCATA" % [int(preview.count), int(preview.scrap)], host.CORAL if int(preview.count) > 0 else host.MUTED, true)
	recycle.name = "RecycleInferior"
	recycle.disabled = int(preview.count) <= 0
	recycle.custom_minimum_size = Vector2(0, 46)
	recycle.add_theme_font_size_override("font_size", 11)
	recycle.tooltip_text = "Recicla apenas peças comuns sem modificações ou investimento que não superam o efeito atual."
	recycle.pressed.connect(state.recycle_inferior_inventory)
	toolbar.add_child(recycle)
	return toolbar


static func loadout_toolbar(host: CrookedUIFactory, state: StateScript) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "LoadoutToolbar"
	row.add_theme_constant_override("separation", 8)
	for index in 2:
		var loadouts: Array = state.player.get("equipment_loadouts", [])
		var loadout: Dictionary = loadouts[index] if index < loadouts.size() else {}
		var weapon := state.inventory_item_by_id(str(loadout.get("weapon_id", "")))
		var armor := state.inventory_item_by_id(str(loadout.get("armor_id", "")))
		var ready := not weapon.is_empty() and not armor.is_empty()
		var card := host.panel(VBoxContainer.new(), Color("#0d1530"), 11, 9)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card)
		var box := card.get_child(0) as VBoxContainer
		box.add_child(host.label("LOADOUT · %s" % state.loadout_name(index), 10, host.GOLD))
		var summary := "%s / %s" % [str(weapon.get("name", "não salvo")), str(armor.get("name", "não salvo"))]
		var summary_label := host.label(summary, 9, host.MUTED)
		summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(summary_label)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 5)
		box.add_child(actions)
		var save := host.action_button("SALVAR", host.CYAN, true)
		save.name = "SaveLoadout_%d" % index
		save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		save.custom_minimum_size = Vector2(0, 44)
		save.add_theme_font_size_override("font_size", 9)
		save.pressed.connect(func(): state.save_equipment_loadout(index))
		actions.add_child(save)
		var apply := host.action_button("USAR", host.LIME if ready else host.MUTED, true)
		apply.name = "ApplyLoadout_%d" % index
		apply.disabled = not ready
		apply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		apply.custom_minimum_size = Vector2(0, 44)
		apply.add_theme_font_size_override("font_size", 9)
		apply.pressed.connect(func(): state.apply_equipment_loadout(index))
		actions.add_child(apply)
	return row


static func inventory_item_card(host: CrookedUIFactory, state: StateScript, item: Dictionary) -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), host.PANEL, 15, 15)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var icon := host.center_label("⚙", 34, Color(str(item.color)))
	icon.custom_minimum_size = Vector2(54, 54)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var item_name := host.label(str(item.name), 16, host.INK)
	item_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(item_name)
	details.add_child(host.label("%s · %s · +%d poder" % [str(item.rarity), host.slot_name(str(item.slot)), int(item.power)], 13, Color(str(item.color))))
	if Rules.has_workshop_investment(item):
		var workshop_parts: Array[String] = []
		if int(item.get("power_upgrades", 0)) > 0:
			workshop_parts.append("%d calib." % int(item.power_upgrades))
		if int(item.get("integrity_upgrades", 0)) > 0:
			workshop_parts.append("%d reforços · +%d vida" % [int(item.integrity_upgrades), int(item.integrity_upgrades) * Rules.INTEGRITY_HEALTH_PER_LEVEL])
		details.add_child(host.label("◇ OFICINA · %s" % " · ".join(workshop_parts), 11, host.CYAN))
	if item.has("trait"):
		var trait_line := host.label("◆ %s · %s" % [str(item.trait.name), str(item.trait.description)], 11, host.GOLD)
		trait_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(trait_line)
	var current: Dictionary = state.player[str(item.slot)]
	var equipped := str(current.get("id", "")) == str(item.get("id", ""))
	var score_difference := Rules.equipment_score(item) - Rules.equipment_score(current)
	var comparison_text := "EQUIPADO" if equipped else EquipmentPresentation.equipment_delta_text(state.player, item)
	var status := host.label(comparison_text, 11, host.LIME if score_difference > 0 or equipped else (host.GOLD if score_difference == 0 else host.MUTED))
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(status)
	if not equipped:
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		row.add_child(buttons)
		var equip_button := host.action_button("EQUIPAR", host.CYAN, true)
		equip_button.custom_minimum_size = Vector2(110, 46)
		var item_id := str(item.id)
		equip_button.pressed.connect(func(): state.equip_from_inventory(item_id))
		buttons.add_child(equip_button)
		var manually_locked: bool = state.player.get("locked_item_ids", []).has(item_id)
		var lock_button := host.action_button("LIBERAR" if manually_locked else "PROTEGER", host.GOLD, true)
		lock_button.name = "Lock_%s" % item_id
		lock_button.custom_minimum_size = Vector2(110, 40)
		lock_button.add_theme_font_size_override("font_size", 10)
		lock_button.pressed.connect(func(): state.toggle_item_lock(item_id))
		buttons.add_child(lock_button)
		var scrap_button := host.action_button("RECICLAR +%d" % Rules.salvage_value(item), host.CORAL, true)
		scrap_button.name = "Scrap_%s" % item_id
		scrap_button.custom_minimum_size = Vector2(110, 44)
		scrap_button.add_theme_font_size_override("font_size", 11)
		scrap_button.disabled = state.is_item_protected(item_id)
		scrap_button.pressed.connect(func(): state.scrap_item(item_id))
		buttons.add_child(scrap_button)
	return card


static func workshop_upgrade_card(host: CrookedUIFactory, state: StateScript, slot: String) -> PanelContainer:
	var item: Dictionary = state.player[slot]
	var power_cost := Rules.equipment_upgrade_cost(item)
	var integrity_cost := Rules.equipment_integrity_upgrade_cost(item)
	var power_affordable := int(state.player.get("scrap", 0)) >= power_cost
	var integrity_affordable := int(state.player.get("scrap", 0)) >= integrity_cost
	var integrity_level := int(item.get("integrity_upgrades", 0))
	var calibration_level := int(item.get("power_upgrades", 0))
	var integrity_available := Rules.can_upgrade_integrity(item)
	var card := host.panel(VBoxContainer.new(), Color("#0d1530"), 12, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := card.get_child(0) as VBoxContainer
	box.add_child(host.label(host.slot_name(slot).to_upper(), 11, host.MUTED))
	box.add_child(host.label("%s · +%d" % [str(item.name), int(item.power)], 13, host.INK))
	box.add_child(host.label("CALIBRAÇÃO %d · REFORÇO %d/%d · +%d VIDA" % [calibration_level, integrity_level, Rules.MAX_INTEGRITY_UPGRADES, integrity_level * Rules.INTEGRITY_HEALTH_PER_LEVEL], 10, host.CYAN if calibration_level > 0 or integrity_level > 0 else host.MUTED))
	if item.has("trait"):
		box.add_child(host.label("◆ %s" % str(item.trait.name), 10, host.GOLD))
	var improve := host.action_button("+1 PODER · %d SUCATA" % power_cost, host.LIME if power_affordable else host.MUTED, true)
	improve.name = "Upgrade_%s" % slot
	improve.disabled = not power_affordable
	improve.custom_minimum_size = Vector2(0, 44)
	improve.add_theme_font_size_override("font_size", 11)
	improve.pressed.connect(func(): state.upgrade_equipped(slot))
	box.add_child(improve)
	var reinforce_text := "+%d VIDA · %d SUCATA" % [Rules.INTEGRITY_HEALTH_PER_LEVEL, integrity_cost] if integrity_available else "INTEGRIDADE MÁXIMA"
	var reinforce := host.action_button(reinforce_text, host.CYAN if integrity_affordable and integrity_available else host.MUTED, true)
	reinforce.name = "Reinforce_%s" % slot
	reinforce.disabled = not integrity_affordable or not integrity_available
	reinforce.custom_minimum_size = Vector2(0, 44)
	reinforce.add_theme_font_size_override("font_size", 11)
	reinforce.pressed.connect(func(): state.reinforce_equipped(slot))
	box.add_child(reinforce)
	return card
