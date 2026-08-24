class_name ArsenalView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	content.add_theme_constant_override("separation", 14)
	var readiness := field_readiness(state)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.label("ARSENAL", 26, host.INK))
	var subtitle := host.label("Troque peças para ajustar seu poder de caça.", 14, host.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	if not readiness.is_empty() and bool(readiness.target_available):
		var focused_target: Dictionary = readiness.target
		var analyze := host.action_button("ESCOLHER ROTA", host.LIME, true)
		analyze.name = "FieldReadinessAction"
		analyze.custom_minimum_size = Vector2(150, 48)
		analyze.add_theme_font_size_override("font_size", 12)
		var target_id := str(focused_target.id)
		analyze.pressed.connect(func():
			host.view_mode = "board"
			host.briefing_context = {
				"target_id": target_id,
				"approach_id": str(readiness.get("approach", {}).get("id", "")),
				"approach_name": str(readiness.get("approach", {}).get("name", "CONTRATO BASE")),
				"odds": float(readiness.get("current_odds", 0.0)),
			}
			state.select_bounty(Content.get_target(target_id))
		)
		title_row.add_child(analyze)
	var back := host.action_button("VOLTAR", host.CYAN, true)
	back.custom_minimum_size = Vector2(96, 48)
	back.pressed.connect(func():
		host.view_mode = "board"
		host.call("render")
	)
	title_row.add_child(back)

	var notice_context := str(state.last_notice_context)
	if notice_context == "workshop" or notice_context.begins_with("reward_"):
		var notice_title := "REGISTRO DA OFICINA" if notice_context == "workshop" else "RECIBO DE CONTRATO"
		var notice := host.label("%s · %s" % [notice_title, state.last_notice], 11, host.LIME)
		notice.name = "WorkshopNotice"
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(notice)
	content.add_child(host.label("OFICINA · %d SUCATA · PODER TOTAL %d" % [int(state.player.get("scrap", 0)), Rules.player_power(state.player)], 14, host.GOLD))
	var set_origin := Rules.equipment_set_origin(state.player)
	var set_text := "KIT PLANETÁRIO · INATIVO · combine arma e armadura da mesma origem"
	var set_color := host.MUTED
	if not set_origin.is_empty():
		set_text = "KIT PLANETÁRIO · %s · +%d PODER · +%d VIDA" % [str(Content.get_planet(set_origin).name).to_upper(), Rules.PLANETARY_KIT_POWER_BONUS, Rules.PLANETARY_KIT_HEALTH_BONUS]
		set_color = host.LIME
	var set_label := host.label(set_text, 12, set_color)
	set_label.name = "PlanetaryKitStatus"
	content.add_child(set_label)
	content.add_child(field_readiness_card(host, state, readiness))
	var workshop_recommendation := recommended_workshop_action(state)
	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 10)
	content.add_child(equipped_row)
	equipped_row.add_child(workshop_upgrade_card(host, state, "weapon", workshop_recommendation))
	equipped_row.add_child(workshop_upgrade_card(host, state, "armor", workshop_recommendation))
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

	var preferences := HBoxContainer.new()
	preferences.name = "AccessibilityPreferences"
	preferences.add_theme_constant_override("separation", 8)
	content.add_child(preferences)
	var audio := host.action_button("SOM · %s" % ("LIGADO" if bool(state.player.get("sound_enabled", true)) else "DESLIGADO"), host.CYAN, true)
	audio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio.custom_minimum_size = Vector2(0, 48)
	audio.pressed.connect(state.toggle_sound)
	preferences.add_child(audio)
	var motion := host.action_button("MOVIMENTO · %s" % ("REDUZIDO" if bool(state.player.get("reduced_motion", false)) else "COMPLETO"), host.CYAN, true)
	motion.name = "MotionPreferenceAction"
	motion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	motion.custom_minimum_size = Vector2(0, 48)
	motion.tooltip_text = "Remove transições decorativas; não altera o combate automático nem as pausas de leitura."
	motion.pressed.connect(state.toggle_reduced_motion)
	preferences.add_child(motion)
	if OS.is_debug_build():
		var reset := host.action_button("DEV · REINICIAR PROGRESSO", host.CORAL, true)
		reset.custom_minimum_size = Vector2(0, 48)
		reset.pressed.connect(func():
			host.reset_transient_navigation()
			state.reset_progress()
		)
		content.add_child(reset)


static func filtered_inventory(host: CrookedUIFactory, state: StateScript) -> Array:
	return EquipmentPresentation.filtered_inventory(state.player.inventory, host.inventory_filter, host.inventory_sort)


static func field_readiness(state: StateScript) -> Dictionary:
	var planet_id := str(state.player.get("current_planet_id", Content.PLANET.id))
	var tier := state.planet_tier(planet_id)
	var current_target := Content.target_for_planet_tier(planet_id, tier)
	var current_captures := int(state.player.get("captures_by_target", {}).get(str(current_target.get("id", "")), 0))
	var target_is_available := not current_target.is_empty() and current_captures == 0
	var target := current_target if target_is_available else Content.target_for_planet_tier(planet_id, mini(3, tier + 1))
	var recovery_focus := false
	if not state.combat_summary.is_empty() and not bool(state.combat_summary.get("won", true)):
		var defeated_id := str(state.combat_summary.get("target_id", state.current_bounty.get("id", "")))
		var defeated_target := Content.get_target(defeated_id)
		if not defeated_target.is_empty() and str(defeated_target.get("planet_id", "")) == planet_id and int(defeated_target.get("chapter_tier", defeated_target.rank)) <= tier:
			target = defeated_target
			target_is_available = true
			recovery_focus = true
	if target.is_empty():
		target = Content.target_for_planet_tier(planet_id, tier)
	if target.is_empty():
		return {}
	var evaluations := ContractRules.evaluate_approaches(state.player, target, Content.contract_approaches())
	var recommended_id := ContractRules.recommended_approach_id(evaluations)
	var contract := target
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			contract = evaluation.preview
			break
	var power_player := state.player.duplicate(true)
	var powered_weapon: Dictionary = power_player.get("weapon", {}).duplicate(true)
	powered_weapon.power = int(powered_weapon.get("power", 0)) + 1
	power_player.weapon = powered_weapon
	var health_player := state.player.duplicate(true)
	var reinforced := false
	for slot in ["weapon", "armor"]:
		var candidate: Dictionary = health_player.get(slot, {}).duplicate(true)
		if Rules.can_upgrade_integrity(candidate):
			candidate.integrity_upgrades = int(candidate.get("integrity_upgrades", 0)) + 1
			health_player[slot] = candidate
			reinforced = true
			break
	return {
		"target": target,
		"contract": contract,
		"approach": contract.get("approach", {}),
		"current_odds": Rules.bounty_odds(state.player, contract),
		"power_odds": Rules.bounty_odds(power_player, contract),
		"health_odds": Rules.bounty_odds(health_player, contract) if reinforced else Rules.bounty_odds(state.player, contract),
		"can_reinforce": reinforced,
		"target_available": target_is_available,
		"recovery_focus": recovery_focus,
		"planet_tier": tier,
	}


static func field_readiness_card(host: CrookedUIFactory, state: StateScript, readiness: Dictionary = {}) -> PanelContainer:
	if readiness.is_empty():
		readiness = field_readiness(state)
	var card := host.panel(VBoxContainer.new(), Color("#13233e"), 12, 10)
	card.name = "FieldReadiness"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	if readiness.is_empty():
		box.add_child(host.label("TESTE DE CAMPO INDISPONÍVEL", 11, host.MUTED))
		return card
	var target: Dictionary = readiness.target
	var target_context := "REVANCHE" if bool(readiness.get("recovery_focus", false)) else ("MANDADO ATUAL" if bool(readiness.target_available) else "PRÓXIMO MANDADO")
	if int(readiness.planet_tier) >= 3 and not bool(readiness.get("recovery_focus", false)):
		target_context = "CHEFE DO CAPÍTULO"
	var target_label := host.label("TESTE DE CAMPO · %s: %s" % [target_context, str(target.name).to_upper()], 11, host.GOLD)
	target_label.name = "FieldReadinessTarget"
	box.add_child(target_label)
	if bool(readiness.get("recovery_focus", false)):
		var route_diagnosis_text := ContractRules.field_test_defeat_text(state.combat_summary.get("field_test_context", {}))
		if not route_diagnosis_text.is_empty():
			var route_diagnosis := host.label(route_diagnosis_text, 10, host.GOLD)
			route_diagnosis.name = "FieldReadinessRecoveryRoute"
			route_diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(route_diagnosis)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 7)
	box.add_child(metrics)
	metrics.add_child(host.metric_chip("AGORA", "%d%%" % roundi(float(readiness.current_odds) * 100.0), readiness_color(host, float(readiness.current_odds))))
	metrics.add_child(host.metric_chip("+1 PODER", "%d%%" % roundi(float(readiness.power_odds) * 100.0), readiness_color(host, float(readiness.power_odds))))
	var health_title := "+8 VIDA" if bool(readiness.can_reinforce) else "REF. MÁX."
	metrics.add_child(host.metric_chip(health_title, "%d%%" % roundi(float(readiness.health_odds) * 100.0), readiness_color(host, float(readiness.health_odds))))
	var approach: Dictionary = readiness.get("approach", {})
	var approach_name := str(approach.get("name", "CONTRATO BASE")).to_upper()
	var approach_label := host.label("ABORDAGEM TESTADA · %s · incidentes ainda podem alterar as chances" % approach_name, 9, host.MUTED)
	approach_label.name = "FieldReadinessApproach"
	box.add_child(approach_label)
	return card


static func readiness_color(host: CrookedUIFactory, odds: float) -> Color:
	return host.LIME if odds >= 0.72 else (host.GOLD if odds >= 0.42 else host.CORAL)


static func recommended_workshop_action(state: StateScript) -> Dictionary:
	var readiness := field_readiness(state)
	if readiness.is_empty():
		return {}
	var target: Dictionary = readiness.contract
	var current_odds := float(readiness.current_odds)
	var current_score := Rules.player_build_score(state.player)
	var scrap := int(state.player.get("scrap", 0))
	var best: Dictionary = {}
	var best_value := -1.0
	for slot in ["weapon", "armor"]:
		var item: Dictionary = state.player[slot]
		var actions := [{"kind": "power", "cost": Rules.equipment_upgrade_cost(item)}]
		if Rules.can_upgrade_integrity(item):
			actions.append({"kind": "integrity", "cost": Rules.equipment_integrity_upgrade_cost(item)})
		for action in actions:
			var cost := int(action.cost)
			if cost > scrap:
				continue
			var simulated := state.player.duplicate(true)
			var simulated_item: Dictionary = simulated[slot].duplicate(true)
			if str(action.kind) == "power":
				simulated_item.power = int(simulated_item.get("power", 0)) + 1
			else:
				simulated_item.integrity_upgrades = int(simulated_item.get("integrity_upgrades", 0)) + 1
			simulated[slot] = simulated_item
			var projected_odds := Rules.bounty_odds(simulated, target)
			var odds_gain := maxf(0.0, projected_odds - current_odds)
			var score_gain := maxf(0.0, Rules.player_build_score(simulated) - current_score)
			var value := odds_gain / float(cost) + score_gain / float(cost) * 0.00001
			if value > best_value:
				best_value = value
				best = {"slot": slot, "kind": action.kind, "cost": cost, "odds": projected_odds, "odds_gain": odds_gain}
	return best


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
	toolbar.add_child(sort)
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
		card.custom_minimum_size = Vector2.ZERO
		row.add_child(card)
		var box := card.get_child(0) as VBoxContainer
		box.add_child(host.label("LOADOUT · %s" % state.loadout_name(index), 10, host.GOLD))
		var summary := "%s / %s" % [str(weapon.get("name", "não salvo")), str(armor.get("name", "não salvo"))]
		var summary_label := host.label(summary, 9, host.MUTED)
		summary_label.custom_minimum_size = Vector2.ZERO
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
	var icon := host.equipment_icon(item, 58)
	icon.name = "EquipmentIcon_%s" % str(item.get("id", "unknown"))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.custom_minimum_size = Vector2.ZERO
	row.add_child(details)
	var item_name := host.label(str(item.name), 16, host.INK)
	item_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(item_name)
	var stat_line := host.label("%s · %s · +%d poder" % [str(item.rarity), host.slot_name(str(item.slot)), int(item.power)], 13, Color(str(item.color)))
	stat_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(stat_line)
	var origin_id := str(item.get("origin_planet_id", ""))
	if not origin_id.is_empty():
		var origin_line := host.label("ORIGEM · %s" % str(Content.get_planet(origin_id).name).to_upper(), 10, host.CYAN)
		origin_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(origin_line)
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
	var simulated := state.player.duplicate(true)
	simulated[str(item.slot)] = item
	var score_difference := Rules.player_build_score(simulated) - Rules.player_build_score(state.player)
	var comparison_text := "EQUIPADO" if equipped else EquipmentPresentation.equipment_delta_text(state.player, item)
	var status := host.label(comparison_text, 11, host.LIME if score_difference > 0 or equipped else (host.GOLD if score_difference == 0 else host.MUTED))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(status)
	if not equipped:
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		row.add_child(buttons)
		var equip_button := host.action_button("EQUIPAR", host.CYAN, true)
		equip_button.custom_minimum_size = Vector2(88, 46)
		var item_id := str(item.id)
		equip_button.pressed.connect(func(): state.equip_from_inventory(item_id))
		buttons.add_child(equip_button)
		var manually_locked: bool = state.player.get("locked_item_ids", []).has(item_id)
		var lock_button := host.action_button("LIBERAR" if manually_locked else "PROTEGER", host.GOLD, true)
		lock_button.name = "Lock_%s" % item_id
		lock_button.custom_minimum_size = Vector2(88, 40)
		lock_button.add_theme_font_size_override("font_size", 10)
		lock_button.pressed.connect(func(): state.toggle_item_lock(item_id))
		buttons.add_child(lock_button)
		var scrap_button := host.action_button("RECICLAR +%d" % Rules.salvage_value(item), host.CORAL, true)
		scrap_button.name = "Scrap_%s" % item_id
		scrap_button.custom_minimum_size = Vector2(88, 44)
		scrap_button.add_theme_font_size_override("font_size", 11)
		scrap_button.disabled = state.is_item_protected(item_id)
		scrap_button.pressed.connect(func(): state.scrap_item(item_id))
		buttons.add_child(scrap_button)
	return card


static func workshop_upgrade_card(host: CrookedUIFactory, state: StateScript, slot: String, recommendation: Dictionary = {}) -> PanelContainer:
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
	card.custom_minimum_size = Vector2.ZERO
	var box := card.get_child(0) as VBoxContainer
	box.add_child(host.label(host.slot_name(slot).to_upper(), 11, host.MUTED))
	var item_label := host.label("%s · +%d" % [str(item.name), int(item.power)], 13, host.INK)
	item_label.custom_minimum_size = Vector2.ZERO
	item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(item_label)
	var workshop_status := host.label("CAL %d · REF %d/%d · +%d VIDA" % [calibration_level, integrity_level, Rules.MAX_INTEGRITY_UPGRADES, integrity_level * Rules.INTEGRITY_HEALTH_PER_LEVEL], 9, host.CYAN if calibration_level > 0 or integrity_level > 0 else host.MUTED)
	workshop_status.custom_minimum_size = Vector2.ZERO
	workshop_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(workshop_status)
	if item.has("trait"):
		var trait_label := host.label("◆ %s" % str(item.trait.name), 10, host.GOLD)
		trait_label.custom_minimum_size = Vector2.ZERO
		trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(trait_label)
	var improve := host.action_button("+1 PODER · %d SUCATA" % power_cost, host.LIME if power_affordable else host.MUTED, true)
	if str(recommendation.get("slot", "")) == slot and str(recommendation.get("kind", "")) == "power":
		improve.text = "★ " + improve.text
		improve.tooltip_text = "Melhor ganho projetado por sucata contra o alvo do teste de campo."
	improve.name = "Upgrade_%s" % slot
	improve.disabled = not power_affordable
	improve.custom_minimum_size = Vector2(0, 44)
	improve.add_theme_font_size_override("font_size", 11)
	improve.pressed.connect(func(): state.upgrade_equipped(slot))
	box.add_child(improve)
	var reinforce_text := "+%d VIDA · %d SUCATA" % [Rules.INTEGRITY_HEALTH_PER_LEVEL, integrity_cost] if integrity_available else "INTEGRIDADE MÁXIMA"
	var reinforce := host.action_button(reinforce_text, host.CYAN if integrity_affordable and integrity_available else host.MUTED, true)
	if str(recommendation.get("slot", "")) == slot and str(recommendation.get("kind", "")) == "integrity":
		reinforce.text = "★ " + reinforce.text
		reinforce.tooltip_text = "Melhor ganho projetado por sucata contra o alvo do teste de campo."
	reinforce.name = "Reinforce_%s" % slot
	reinforce.disabled = not integrity_affordable or not integrity_available
	reinforce.custom_minimum_size = Vector2(0, 44)
	reinforce.add_theme_font_size_override("font_size", 11)
	reinforce.pressed.connect(func(): state.reinforce_equipped(slot))
	box.add_child(reinforce)
	return card
