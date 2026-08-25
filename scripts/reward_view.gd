class_name RewardView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const RewardProgressIconScript = preload("res://scripts/reward_progress_icon.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")


static func local_text(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_content(prefix: String, definition: Dictionary, field: String) -> String:
	return local_text(LocaleRules.content_key(prefix, str(definition.get("id", "")), field), str(definition.get(field, "")))


static func localized_item_field(item: Dictionary, field: String) -> String:
	var planet_id := str(item.get("origin_planet_id", Content.PLANET.id))
	var slot := str(item.get("slot", "weapon"))
	var catalog := Content.item_catalog_for(planet_id, slot)
	for index in catalog.size():
		if str(catalog[index].get("name", "")) == str(item.get("name", "")):
			return local_text("ITEM_%s_%s_%d_%s" % [planet_id.to_upper(), slot.to_upper(), index, field.to_upper()], str(item.get(field, "")))
	return str(item.get(field, ""))


static func localized_trait_field(trait_data: Dictionary, field: String) -> String:
	return local_text("ITEM_TRAIT_%s_%s" % [str(trait_data.get("id", "")).to_upper(), field.to_upper()], str(trait_data.get(field, "")))


static func localized_rarity(rarity: String) -> String:
	match rarity:
		"Épico": return local_text("RARITY_EPIC", "ÉPICO")
		"Raro": return local_text("RARITY_RARE", "RARO")
		_: return local_text("RARITY_COMMON", "COMUM")


static func localized_slot(slot: String) -> String:
	return local_text("SLOT_%s" % slot.to_upper(), Rules.equipment_slot_name(slot))


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	if bool(state.current_bounty.get("challenge", false)):
		build_challenge_reward(host, content, state)
		return
	var item := state.pending_loot
	var reward_preview := Rules.bounty_streak_reward(int(state.current_bounty.credits), int(state.player.get("capture_streak", 0)) + 1)
	var equipped: Dictionary = state.player.get(str(item.get("slot", "")), {})
	var comparison := int(item.get("power", 0)) - int(equipped.get("power", 0))
	var effective_upgrade := Rules.is_upgrade_for_player(state.player, item)
	content.add_child(host.center_label(local_text("REWARD_CONTRACT_COMPLETE", "CONTRATO CONCLUÍDO · %s", [localized_content("target", state.current_bounty, "name").to_upper()]), 16, host.LIME))
	content.add_child(host.center_label(local_text("REWARD_CAPTURED", "RECOMPENSA CAPTURADA"), 28, host.INK))
	var reward_panel := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 20, 12)
	reward_panel.name = "RewardPanel"
	content.add_child(reward_panel)
	if bool(state.player.get("reduced_motion", false)):
		reward_panel.modulate = Color.WHITE
	else:
		reward_panel.modulate = Color(1, 1, 1, 0)
		reward_panel.create_tween().tween_property(reward_panel, "modulate", Color.WHITE, 0.32)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var loot_header := HBoxContainer.new()
	loot_header.name = "RewardLootHeader"
	loot_header.add_theme_constant_override("separation", 12)
	box.add_child(loot_header)
	var loot_icon := host.equipment_icon(item, 68)
	loot_icon.name = "RewardEquipmentIcon"
	loot_header.add_child(loot_icon)
	var loot_copy := VBoxContainer.new()
	loot_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loot_copy.add_theme_constant_override("separation", 1)
	loot_header.add_child(loot_copy)
	loot_copy.add_child(host.label("%s · %s" % [localized_rarity(str(item.rarity)), localized_slot(str(item.slot)).to_upper()], 12, Color(str(item.color))))
	var item_name := host.label(localized_item_field(item, "name"), 21, host.INK)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_copy.add_child(item_name)
	var origin_id := str(item.get("origin_planet_id", ""))
	if not origin_id.is_empty():
		loot_copy.add_child(host.label(local_text("REWARD_ORIGIN", "ORIGEM · %s", [localized_content("planet", Content.get_planet(origin_id), "name").to_upper()]), 10, host.CYAN))
	var description := host.label(localized_item_field(item, "description") if item.has("description") else local_text("REWARD_UNKNOWN_ORIGIN", "Procedência criativamente desconhecida."), 12, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_copy.add_child(description)
	var comparison_row := HBoxContainer.new()
	comparison_row.name = "RewardEquipmentComparison"
	comparison_row.add_theme_constant_override("separation", 7)
	box.add_child(comparison_row)
	comparison_row.add_child(reward_metric_chip(host, local_text("REWARD_NEW", "NOVO"), "+%d" % int(item.get("power", 0)), host.GOLD, "RewardNewPower"))
	comparison_row.add_child(reward_metric_chip(host, local_text("REWARD_EQUIPPED", "EQUIPADO"), "+%d" % int(equipped.get("power", 0)), host.MUTED, "RewardEquippedPower"))
	var result_text := local_text("REWARD_UPGRADE", "UPGRADE") if effective_upgrade else local_text("REWARD_STORE", "GUARDAR")
	if effective_upgrade and comparison <= 0:
		result_text = local_text("REWARD_BETTER_MOD", "MOD MELHOR")
	comparison_row.add_child(reward_metric_chip(host, local_text("REWARD_RESULT", "RESULTADO"), result_text, host.LIME if effective_upgrade else host.MUTED, "RewardEquipmentResult"))
	if item.has("trait"):
		var trait_label := host.center_label("◆ %s · %s" % [localized_trait_field(item.trait, "name"), localized_trait_field(item.trait, "description")], 11, host.GOLD)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(trait_label)
	var equipment_delta := host.center_label(EquipmentPresentation.equipment_delta_text(state.player, item), 12, host.LIME if effective_upgrade else host.MUTED)
	equipment_delta.name = "RewardEquipmentDelta"
	box.add_child(equipment_delta)
	box.add_child(host.center_label(local_text("REWARD_RECYCLE_VALUE", "RECICLAGEM · %d SUCATA", [Rules.salvage_value(item)]), 10, host.MUTED))
	var receipt_panel := host.panel(VBoxContainer.new(), Color("#0d1530"), 10, 8)
	receipt_panel.name = "RewardContractReceipt"
	box.add_child(receipt_panel)
	var receipt_box := receipt_panel.get_child(0) as VBoxContainer
	receipt_box.add_theme_constant_override("separation", 3)
	var contract_scrap := int(state.current_bounty.get("scrap_reward", 0))
	var reward_line := local_text("REWARD_RECEIPT", "RECIBO · ◈ %d CRÉDITOS · %d XP", [int(reward_preview.credits), int(state.current_bounty.xp)])
	if contract_scrap > 0:
		reward_line += local_text("REWARD_SCRAP_SUFFIX", " · %d sucata", [contract_scrap])
	var reward_totals := host.center_label(reward_line, 13, host.GOLD)
	reward_totals.name = "RewardContractTotals"
	receipt_box.add_child(reward_totals)
	var incident_cost := maxi(0, int(state.current_bounty.get("hunt_event_credit_cost", 0)))
	if incident_cost > 0:
		var incident_net := host.center_label(local_text("REWARD_INCIDENT_NET", "INCIDENTE JÁ PAGO · -%d CRÉDITOS · SALDO DO CONTRATO +%d", [incident_cost, int(reward_preview.credits) - incident_cost]), 10, host.CYAN)
		incident_net.name = "RewardIncidentNet"
		receipt_box.add_child(incident_net)
	var progress_box := VBoxContainer.new()
	progress_box.name = "RewardProgressSummary"
	progress_box.add_theme_constant_override("separation", 5)
	var previous_captures := int(state.player.get("captures_by_target", {}).get(str(state.current_bounty.id), 0))
	var reward_mastery := Rules.target_mastery_level(previous_captures)
	if reward_mastery > 0:
		var mastery_label := host.center_label(local_text("REWARD_TARGET_MASTERY", "PERÍCIA COM ALVO %d/3 · QUALIDADE DE LOOT AMPLIADA", [reward_mastery]), 13, host.LIME)
		mastery_label.name = "RewardMastery"
		progress_box.add_child(reward_progress_row(host, "mastery", mastery_label, null, host.LIME))
	var captures_after_reward := previous_captures + 1
	var mastery_after_reward := Rules.target_mastery_level(captures_after_reward)
	var planet_id := str(state.current_bounty.get("planet_id", Content.PLANET.id))
	var captures_before: Dictionary = state.player.get("captures_by_target", {})
	var captures_after := captures_before.duplicate(true)
	var bounty_id := str(state.current_bounty.id)
	captures_after[bounty_id] = int(captures_after.get(bounty_id, 0)) + 1
	var tier_before := Content.planet_tier_from_target_captures(planet_id, captures_before)
	var tier_after := Content.planet_tier_from_target_captures(planet_id, captures_after)
	var progress_after := Content.warrant_progress(planet_id, captures_after)
	var next_target: Dictionary = Content.target_for_planet_tier(planet_id, tier_after) if tier_after > tier_before else progress_after.next_target
	var unlocks_new_warrant := tier_after > tier_before and not next_target.is_empty()
	var combined_next_capture := captures_after_reward == 2 and reward_mastery == 0 and not next_target.is_empty() and int(progress_after.progress) == 2 and int(progress_after.requirement) == 3
	if mastery_after_reward > reward_mastery:
		var mastery_unlock := host.center_label(local_text("REWARD_NEW_MASTERY", "NOVA PERÍCIA AO RECEBER · NÍVEL %d/3", [mastery_after_reward]), 13, host.GOLD)
		mastery_unlock.name = "RewardMasteryUnlock"
		var mastery_bonus := host.center_label(local_text("REWARD_MASTERY_BONUS", "+%d%% RARO · +%d%% ÉPICO · OFICINA +%d SUCATA", [mastery_after_reward * 5, mastery_after_reward * 2, Rules.target_mastery_scrap_reward(mastery_after_reward)]), 12, host.LIME)
		mastery_bonus.name = "RewardMasteryUnlockBonus"
		progress_box.add_child(reward_progress_row(host, "mastery", mastery_unlock, mastery_bonus, host.GOLD))
	elif captures_after_reward > 1:
		var next_mastery_requirement := Rules.target_mastery_next_requirement(reward_mastery)
		if next_mastery_requirement > 0:
			var mastery_progress_text := local_text("REWARD_NEXT_MASTERY", "PRÓXIMA PERÍCIA · %d/%d CAPTURAS", [captures_after_reward, next_mastery_requirement])
			if combined_next_capture:
				mastery_progress_text = local_text("REWARD_NEXT_CAPTURE_COMBINED", "PRÓXIMA CAPTURA · PERÍCIA 1/3 + MANDADO %s", [localized_content("target", next_target, "name").to_upper()])
			var mastery_progress := host.center_label(mastery_progress_text, 12, host.CYAN)
			mastery_progress.name = "RewardMasteryProgress"
			progress_box.add_child(reward_progress_row(host, "mastery", mastery_progress, null, host.CYAN))
	if int(reward_preview.bonus_credits) > 0:
		var streak_bonus := host.center_label(local_text("REWARD_MOMENTUM_BONUS", "EMBALO ×%d · +%d créditos (+%d%%)", [int(reward_preview.streak), int(reward_preview.bonus_credits), int(reward_preview.bonus_percent)]), 14, host.LIME)
		streak_bonus.name = "RewardStreakBonus"
		progress_box.add_child(reward_progress_row(host, "streak", streak_bonus, null, host.LIME))
	elif int(reward_preview.streak) == 1:
		var streak_start := host.center_label(local_text("REWARD_MOMENTUM_START", "EMBALO REINICIADO ×1 · BÔNUS COMEÇA NA PRÓXIMA CAPTURA"), 12, host.CYAN)
		streak_start.name = "RewardStreakStart"
		progress_box.add_child(reward_progress_row(host, "streak", streak_start, null, host.CYAN))
	if unlocks_new_warrant:
		var unlock_label := host.center_label(local_text("REWARD_NEW_WARRANT", "NOVO MANDADO AO RECEBER · %s", [localized_content("target", next_target, "name").to_upper()]), 14, host.LIME)
		unlock_label.name = "RewardWarrantUnlock"
		var unlock_impact := warrant_impact_label(host, state.player, item, next_target, effective_upgrade, int(state.current_bounty.xp), "RewardWarrantOdds")
		progress_box.add_child(reward_progress_row(host, "warrant", unlock_label, unlock_impact, host.LIME))
	elif not next_target.is_empty() and not combined_next_capture:
		var progress_label := host.center_label(local_text("REWARD_WARRANT_PROGRESS", "RUMO A %s · %d/%d CAPTURAS DE %s", [localized_content("target", next_target, "name").to_upper(), int(progress_after.progress), int(progress_after.requirement), localized_content("target", progress_after.prerequisite, "name").to_upper()]), 13, host.CYAN)
		progress_label.name = "RewardWarrantProgress"
		var next_impact := warrant_impact_label(host, state.player, item, next_target, effective_upgrade, int(state.current_bounty.xp), "RewardNextHuntImpact")
		progress_box.add_child(reward_progress_row(host, "warrant", progress_label, next_impact, host.CYAN))
	if progress_box.get_child_count() > 0:
		var progress_panel := host.panel(progress_box, Color("#10233b"), 10, 7)
		progress_panel.name = "RewardProgressPanel"
		box.add_child(progress_panel)
	content.add_spacer(false)
	var completes_chapter: bool = bool(state.current_bounty.get("boss", false)) and not bool(state.player.get("completed_planets", []).has(planet_id))
	var safe_to_recycle := state.can_recycle_reward(item)
	if not completes_chapter and not unlocks_new_warrant:
		var next_streak_reward := Rules.bounty_streak_reward(int(state.current_bounty.credits), int(reward_preview.streak) + 1)
		var repeat_value := host.center_label(local_text("REWARD_NEXT_CAPTURE_MOMENTUM", "PRÓXIMA CAPTURA SEGUIDA · EMBALO ×%d · +%d%% SOBRE O PAGAMENTO", [int(next_streak_reward.streak), int(next_streak_reward.bonus_percent)]), 12, host.CYAN)
		repeat_value.name = "RewardRepeatValue"
		content.add_child(repeat_value)
		var repeat := host.action_button(local_text("REWARD_EQUIP_REPEAT", "EQUIPAR E REPETIR") if effective_upgrade else local_text("REWARD_STORE_REPEAT", "GUARDAR E REPETIR"), host.LIME)
		repeat.name = "ClaimAndRepeat"
		repeat.pressed.connect(func(): state.claim_reward(effective_upgrade, true))
		content.add_child(repeat)
		if safe_to_recycle:
			var recycle_repeat := host.action_button(local_text("REWARD_RECYCLE_REPEAT", "RECICLAR +%d SUCATA E REPETIR", [Rules.salvage_value(item)]), host.CORAL, true)
			recycle_repeat.name = "RecycleAndRepeat"
			recycle_repeat.custom_minimum_size = Vector2(0, 48)
			recycle_repeat.pressed.connect(func(): state.claim_reward(false, true, true))
			content.add_child(recycle_repeat)
	elif safe_to_recycle:
		var recycle_destination := local_text("REWARD_VIEW_NEW_WARRANT", "VER NOVO MANDADO") if unlocks_new_warrant else local_text("REWARD_COMPLETE", "CONCLUIR")
		var recycle_complete := host.action_button(local_text("REWARD_RECYCLE_COMPLETE", "RECICLAR +%d SUCATA E %s", [Rules.salvage_value(item), recycle_destination]), host.CORAL, true)
		recycle_complete.name = "RecycleAndComplete"
		recycle_complete.custom_minimum_size = Vector2(0, 48)
		recycle_complete.pressed.connect(func(): state.claim_reward(false, false, true))
		content.add_child(recycle_complete)
	if mastery_after_reward > reward_mastery and not completes_chapter:
		var workshop_text := local_text("REWARD_EQUIP_WORKSHOP", "EQUIPAR E IR À OFICINA") if effective_upgrade else local_text("REWARD_STORE_WORKSHOP", "GUARDAR E IR À OFICINA")
		if unlocks_new_warrant:
			workshop_text = local_text("REWARD_EQUIP_PREPARE_WARRANT", "EQUIPAR E PREPARAR NOVO MANDADO") if effective_upgrade else local_text("REWARD_STORE_PREPARE_WARRANT", "GUARDAR E PREPARAR NOVO MANDADO")
		var workshop := host.action_button(workshop_text, host.CYAN, true)
		workshop.name = "ClaimAndWorkshop"
		workshop.custom_minimum_size = Vector2(0, 48)
		workshop.pressed.connect(func():
			host.arsenal_section = "equipped"
			host.view_mode = "arsenal"
			state.claim_reward(effective_upgrade)
		)
		content.add_child(workshop)
	var claim_text := ""
	if completes_chapter:
		claim_text = local_text("REWARD_CLAIM_COMPLETE_CHAPTER", "RECEBER E CONCLUIR CAPÍTULO")
	elif unlocks_new_warrant:
		claim_text = local_text("REWARD_EQUIP_VIEW_WARRANT", "EQUIPAR E VER NOVO MANDADO") if effective_upgrade else local_text("REWARD_STORE_VIEW_WARRANT", "GUARDAR E VER NOVO MANDADO")
	else:
		claim_text = local_text("REWARD_EQUIP_BOARD", "EQUIPAR E VOLTAR AO QUADRO") if effective_upgrade else local_text("REWARD_STORE_BOARD", "GUARDAR E VOLTAR AO QUADRO")
	var claim := host.action_button(claim_text, host.LIME if completes_chapter or unlocks_new_warrant else host.GOLD, not (completes_chapter or unlocks_new_warrant))
	claim.name = "ClaimAndUnlock" if unlocks_new_warrant else "ClaimAndBoard"
	claim.custom_minimum_size = Vector2(0, 48)
	claim.pressed.connect(func(): state.claim_reward(effective_upgrade))
	content.add_child(claim)


static func build_challenge_reward(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var item := state.pending_loot
	var equipped: Dictionary = state.player.get(str(item.slot), {})
	var effective_upgrade := Rules.is_upgrade_for_player(state.player, item)
	content.add_child(host.center_label("FENDA CLANDESTINA · ANDAR %d LIMPO" % (int(state.current_bounty.get("challenge_index", 0)) + 1), 16, host.LIME))
	content.add_child(host.center_label("ARTEFATO RECUPERADO", 28, host.INK))
	var reward_panel := host.panel(VBoxContainer.new(), Color("#17182f"), 20, 16)
	reward_panel.name = "ChallengeRewardPanel"
	content.add_child(reward_panel)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(host.equipment_icon(item, 76))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label("%s · %s" % [str(item.rarity).to_upper(), host.slot_name(str(item.slot)).to_upper()], 11, Color(str(item.color))))
	copy.add_child(host.label(str(item.name), 21, host.INK))
	var description := host.label(str(item.description), 12, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	if item.has("trait"):
		var modification := host.center_label("◆ %s · %s" % [str(item.trait.name), str(item.trait.description)], 12, host.GOLD)
		modification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(modification)
	box.add_child(host.center_label(EquipmentPresentation.equipment_delta_text(state.player, item), 13, host.LIME if effective_upgrade else host.MUTED))
	box.add_child(host.center_label("RECIBO DA FENDA · ◈ %d CRÉDITOS · %d XP" % [int(state.current_bounty.credits), int(state.current_bounty.xp)], 13, host.GOLD))
	var comparison := host.center_label("EQUIPADO AGORA · +%d PODER" % int(equipped.get("power", 0)), 11, host.MUTED)
	comparison.name = "ChallengeEquippedComparison"
	box.add_child(comparison)
	var next_floor := int(state.current_bounty.get("challenge_index", 0)) + 2
	var progress := host.center_label("AO RECEBER · ANDAR %d SERÁ ABERTO" % next_floor if next_floor <= 6 else "AO RECEBER · FENDA SERÁ CONCLUÍDA", 12, host.CYAN)
	progress.name = "ChallengeRewardProgress"
	box.add_child(progress)
	content.add_spacer(false)
	var claim := host.action_button("EQUIPAR E VOLTAR À FENDA" if effective_upgrade else "GUARDAR E VOLTAR À FENDA", host.LIME)
	claim.name = "ClaimChallengeReward"
	claim.custom_minimum_size = Vector2(0, 50)
	claim.pressed.connect(func(): state.claim_reward(effective_upgrade))
	content.add_child(claim)


static func reward_metric_chip(host: CrookedUIFactory, title: String, value: String, color: Color, node_name: String) -> PanelContainer:
	var chip := host.panel(VBoxContainer.new(), Color("#0a1025"), 8, 5)
	chip.name = node_name
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chip_box := chip.get_child(0) as VBoxContainer
	chip_box.add_theme_constant_override("separation", 0)
	chip_box.add_child(host.label(title, 9, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	chip_box.add_child(host.label(value, 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


static func reward_progress_row(host: CrookedUIFactory, kind: String, primary: Label, secondary: Label, accent: Color) -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), Color("#0b1830"), 9, 5)
	card.name = "RewardProgressRow_%s" % kind
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 8)
	var icon: Control = RewardProgressIconScript.new()
	icon.name = "RewardProgressIcon_%s" % kind
	icon.configure(kind, accent)
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	primary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(primary)
	if secondary != null:
		secondary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		secondary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(secondary)
	return card


static func warrant_impact(player: Dictionary, item: Dictionary, target: Dictionary, equip_item: bool, reward_xp: int) -> Dictionary:
	var projected_player := player.duplicate(true)
	var levels_gained := Rules.apply_xp(projected_player, reward_xp)
	if equip_item:
		projected_player[str(item.slot)] = item.duplicate(true)
	var projected_evaluations := ContractRules.evaluate_approaches(projected_player, target, Content.contract_approaches())
	var recommended_id := ContractRules.recommended_approach_id(projected_evaluations, str(projected_player.get("class_id", "")))
	var current_evaluations := ContractRules.evaluate_approaches(player, target, Content.contract_approaches())
	var route_name := local_text("REWARD_SAFE_ROUTE", "ROTA SEGURA")
	var current_odds := 0.0
	var projected_odds := 0.0
	for evaluation in projected_evaluations:
		if str(evaluation.id) == recommended_id:
			route_name = localized_content("approach", evaluation.preview.get("approach", {}), "name")
			projected_odds = float(evaluation.odds)
			break
	for evaluation in current_evaluations:
		if str(evaluation.id) == recommended_id:
			current_odds = float(evaluation.odds)
			break
	return {
		"approach_id": recommended_id,
		"route_name": route_name,
		"current_odds": current_odds,
		"projected_odds": projected_odds,
		"levels_gained": levels_gained,
	}


static func warrant_impact_label(host: CrookedUIFactory, player: Dictionary, item: Dictionary, target: Dictionary, equip_item: bool, reward_xp: int, node_name: String) -> Label:
	var impact := warrant_impact(player, item, target, equip_item, reward_xp)
	var route_name := str(impact.route_name)
	var current_odds := float(impact.current_odds)
	var projected_odds := float(impact.projected_odds)
	var text := local_text("REWARD_BEST_CURRENT_ROUTE", "MELHOR ROTA COM BUILD ATUAL · %s · %d%%", [route_name.to_upper(), roundi(current_odds * 100.0)])
	if int(impact.levels_gained) > 0:
		var receipt_action := local_text("REWARD_RECEIVE_EQUIP", "RECEBER + EQUIPAR") if equip_item else local_text("REWARD_RECEIVE_ONLY", "RECEBER SEM EQUIPAR")
		text = local_text("REWARD_AFTER_ACTION", "APÓS %s · %s · %d%% → %d%%", [receipt_action, route_name.to_upper(), roundi(current_odds * 100.0), roundi(projected_odds * 100.0)])
	elif equip_item:
		text = local_text("REWARD_EQUIP_IMPACT", "IMPACTO AO EQUIPAR · %s · %d%% → %d%%", [route_name.to_upper(), roundi(current_odds * 100.0), roundi(projected_odds * 100.0)])
	var result := host.center_label(text, 12, host.GOLD)
	result.name = node_name
	return result
