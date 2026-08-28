class_name RewardView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const DailyObjectiveRules = preload("res://scripts/daily_objective_rules.gd")
const ChallengeRules = preload("res://scripts/challenge_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const RewardProgressIconScript = preload("res://scripts/reward_progress_icon.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")


static func local_text(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_content(prefix: String, definition: Dictionary, field: String) -> String:
	return local_text(LocaleRules.content_key(prefix, str(definition.get("id", "")), field), str(definition.get(field, "")))


static func localized_item_field(item: Dictionary, field: String) -> String:
	var item_id := str(item.get("id", ""))
	if str(item.get("challenge_origin", "")) == "fenda_clandestina":
		return local_text("RIFT_REWARD_%s_%s" % [item_id.trim_suffix("_reward").to_upper(), field.to_upper()], str(item.get(field, "")))
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
	content.add_child(host.center_label(local_text("REWARD_CONTRACT_COMPLETE", "CONTRATO CONCLUÍDO · %s", [localized_content("target", state.current_bounty, "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.LIME))
	content.add_child(host.center_label(local_text("REWARD_CAPTURED", "RECOMPENSA CAPTURADA"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
	var reward_scroll := ScrollContainer.new()
	reward_scroll.name = "RewardScroll"
	reward_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(reward_scroll)
	var reward_stack := VBoxContainer.new()
	reward_stack.name = "RewardScrollContent"
	reward_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_scroll.add_child(reward_stack)
	var reward_panel := host.illustrated_panel(VBoxContainer.new(), 12)
	reward_panel.name = "RewardPanel"
	reward_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_stack.add_child(reward_panel)
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
	loot_copy.add_child(host.label("%s · %s" % [localized_rarity(str(item.rarity)), localized_slot(str(item.slot)).to_upper()], UIDesignSystem.FONT_CAPTION, Color(str(item.color))))
	var procedural_identity := EquipmentPresentation.procedural_identity_text(item)
	if not procedural_identity.is_empty():
		loot_copy.add_child(host.label(procedural_identity, UIDesignSystem.FONT_CAPTION, host.CYAN))
	var collection_state := EquipmentPresentation.collection_state(state.player, item)
	if not collection_state.is_empty():
		var collection_label := host.label(local_text("ITEM_COLLECTION_PREVIEW_NEW", "★ NOVA SÉRIE · será registada ao receber") if collection_state == "new" else local_text("ITEM_COLLECTION_PREVIEW_REGISTERED", "✓ SÉRIE JÁ REGISTADA"), UIDesignSystem.FONT_CAPTION, host.GOLD if collection_state == "new" else host.MUTED)
		collection_label.name = "RewardCollectionStatus"
		collection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loot_copy.add_child(collection_label)
	var item_name := host.label(localized_item_field(item, "name"), UIDesignSystem.FONT_BODY, host.INK)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_copy.add_child(item_name)
	var origin_id := str(item.get("origin_planet_id", ""))
	if not origin_id.is_empty():
		loot_copy.add_child(host.label(local_text("REWARD_ORIGIN", "ORIGEM · %s", [localized_content("planet", Content.get_planet(origin_id), "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var description := host.label(localized_item_field(item, "description") if item.has("description") else local_text("REWARD_UNKNOWN_ORIGIN", "Procedência criativamente desconhecida."), UIDesignSystem.FONT_CAPTION, host.MUTED)
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
	var modifier_text := EquipmentPresentation.modifier_text(item)
	if not modifier_text.is_empty():
		var trait_label := host.center_label("◆ %s" % modifier_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(trait_label)
	var equipment_delta := host.center_label(EquipmentPresentation.equipment_delta_text(state.player, item), UIDesignSystem.FONT_CAPTION, host.LIME if effective_upgrade else host.MUTED)
	equipment_delta.name = "RewardEquipmentDelta"
	box.add_child(equipment_delta)
	box.add_child(host.center_label(local_text("REWARD_RECYCLE_VALUE", "RECICLAGEM · %d SUCATA", [Rules.salvage_value(item)]), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var receipt_panel := host.panel(VBoxContainer.new(), Color("#0d1530"), 10, 8)
	receipt_panel.name = "RewardContractReceipt"
	box.add_child(receipt_panel)
	var receipt_box := receipt_panel.get_child(0) as VBoxContainer
	receipt_box.add_theme_constant_override("separation", 3)
	var contract_scrap := int(state.current_bounty.get("scrap_reward", 0))
	var reward_line := local_text("REWARD_RECEIPT", "RECIBO · ◈ %d CRÉDITOS · %d XP", [int(reward_preview.credits), int(state.current_bounty.xp)])
	if contract_scrap > 0:
		reward_line += local_text("REWARD_SCRAP_SUFFIX", " · %d sucata", [contract_scrap])
	var reward_totals := host.center_label(reward_line, UIDesignSystem.FONT_CAPTION, host.GOLD)
	reward_totals.name = "RewardContractTotals"
	receipt_box.add_child(reward_totals)
	var incident_cost := maxi(0, int(state.current_bounty.get("hunt_event_credit_cost", 0)))
	if incident_cost > 0:
		var incident_net := host.center_label(local_text("REWARD_INCIDENT_NET", "INCIDENTE JÁ PAGO · -%d CRÉDITOS · SALDO DO CONTRATO +%d", [incident_cost, int(reward_preview.credits) - incident_cost]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		incident_net.name = "RewardIncidentNet"
		receipt_box.add_child(incident_net)
	var progress_box := VBoxContainer.new()
	progress_box.name = "RewardProgressSummary"
	progress_box.add_theme_constant_override("separation", 5)
	# Preview the retention consequence before the player commits the reward. This
	# keeps the daily system discoverable without interrupting the hunt flow.
	var daily_before := state.daily_objectives()
	var projected_player: Dictionary = state.player.duplicate(true)
	projected_player.daily_hunts_completed = int(projected_player.get("daily_hunts_completed", 0)) + 1
	Rules.apply_xp(projected_player, int(state.current_bounty.xp))
	var new_planets := MissionRules.newly_available_planets(int(state.player.get("level", 1)), int(projected_player.get("level", 1)))
	var unlocks_new_planet := not new_planets.is_empty()
	var projected_hunts := mini(5, int(projected_player.daily_hunts_completed))
	var ready_daily_before := daily_before.filter(func(entry): return bool(entry.complete) and not bool(entry.claimed)).size()
	var unlocks_daily_payment := DailyObjectiveRules.rewards_ready(projected_player).size() > ready_daily_before
	var daily_text := local_text("REWARD_DAILY_PAYMENT_READY", "AO RECEBER · TURNO %d/5 · PAGAMENTO LIBERADO", [projected_hunts]) if unlocks_daily_payment else local_text("REWARD_DAILY_PROGRESS", "AO RECEBER · TURNO %d/5", [projected_hunts])
	var daily_label := host.center_label(daily_text, UIDesignSystem.FONT_CAPTION, host.GOLD if unlocks_daily_payment else host.CYAN)
	daily_label.name = "RewardDailyProgress"
	progress_box.add_child(reward_progress_row(host, "daily", daily_label, null, host.GOLD if unlocks_daily_payment else host.CYAN))
	var previous_captures := int(state.player.get("captures_by_target", {}).get(str(state.current_bounty.id), 0))
	var reward_mastery := Rules.target_mastery_level(previous_captures)
	if reward_mastery > 0:
		var mastery_label := host.center_label(local_text("REWARD_TARGET_MASTERY", "PERÍCIA COM ALVO %d/3 · QUALIDADE DE LOOT AMPLIADA", [reward_mastery]), UIDesignSystem.FONT_CAPTION, host.LIME)
		mastery_label.name = "RewardMastery"
		progress_box.add_child(reward_progress_row(host, "mastery", mastery_label, null, host.LIME))
	var captures_after_reward := previous_captures + 1
	var mastery_after_reward := Rules.target_mastery_level(captures_after_reward)
	var planet_id := str(state.current_bounty.get("planet_id", Content.PLANET.id))
	var network_mission := bool(state.current_bounty.get("mission_offer", false))
	var captures_before: Dictionary = state.player.get("captures_by_target", {})
	var captures_after := captures_before.duplicate(true)
	var bounty_id := str(state.current_bounty.id)
	captures_after[bounty_id] = int(captures_after.get(bounty_id, 0)) + 1
	var tier_before := 0 if network_mission else Content.planet_tier_from_target_captures(planet_id, captures_before)
	var tier_after := 0 if network_mission else Content.planet_tier_from_target_captures(planet_id, captures_after)
	var progress_after := {} if network_mission else Content.warrant_progress(planet_id, captures_after)
	var next_target: Dictionary = {} if network_mission else (Content.target_for_planet_tier(planet_id, tier_after) if tier_after > tier_before else progress_after.next_target)
	var unlocks_new_warrant := tier_after > tier_before and not next_target.is_empty()
	var combined_next_capture := not network_mission and captures_after_reward == 2 and reward_mastery == 0 and not next_target.is_empty() and int(progress_after.progress) == 2 and int(progress_after.requirement) == 3
	if mastery_after_reward > reward_mastery:
		var mastery_unlock := host.center_label(local_text("REWARD_NEW_MASTERY", "NOVA PERÍCIA AO RECEBER · NÍVEL %d/3", [mastery_after_reward]), UIDesignSystem.FONT_CAPTION, host.GOLD)
		mastery_unlock.name = "RewardMasteryUnlock"
		var mastery_bonus := host.center_label(local_text("REWARD_MASTERY_BONUS", "+%d%% RARO · +%d%% ÉPICO · OFICINA +%d SUCATA", [mastery_after_reward * 5, mastery_after_reward * 2, Rules.target_mastery_scrap_reward(mastery_after_reward)]), UIDesignSystem.FONT_CAPTION, host.LIME)
		mastery_bonus.name = "RewardMasteryUnlockBonus"
		progress_box.add_child(reward_progress_row(host, "mastery", mastery_unlock, mastery_bonus, host.GOLD))
	elif captures_after_reward > 1:
		var next_mastery_requirement := Rules.target_mastery_next_requirement(reward_mastery)
		if next_mastery_requirement > 0:
			var mastery_progress_text := local_text("REWARD_NEXT_MASTERY", "PRÓXIMA PERÍCIA · %d/%d CAPTURAS", [captures_after_reward, next_mastery_requirement])
			if combined_next_capture:
				mastery_progress_text = local_text("REWARD_NEXT_CAPTURE_COMBINED", "PRÓXIMA CAPTURA · PERÍCIA 1/3 + MANDADO %s", [localized_content("target", next_target, "name").to_upper()])
			var mastery_progress := host.center_label(mastery_progress_text, UIDesignSystem.FONT_CAPTION, host.CYAN)
			mastery_progress.name = "RewardMasteryProgress"
			progress_box.add_child(reward_progress_row(host, "mastery", mastery_progress, null, host.CYAN))
	if int(reward_preview.bonus_credits) > 0:
		var streak_bonus := host.center_label(local_text("REWARD_MOMENTUM_BONUS", "EMBALO ×%d · +%d créditos (+%d%%)", [int(reward_preview.streak), int(reward_preview.bonus_credits), int(reward_preview.bonus_percent)]), UIDesignSystem.FONT_CAPTION, host.LIME)
		streak_bonus.name = "RewardStreakBonus"
		progress_box.add_child(reward_progress_row(host, "streak", streak_bonus, null, host.LIME))
	elif int(reward_preview.streak) == 1:
		var streak_start := host.center_label(local_text("REWARD_MOMENTUM_START", "EMBALO REINICIADO ×1 · BÔNUS COMEÇA NA PRÓXIMA CAPTURA"), UIDesignSystem.FONT_CAPTION, host.CYAN)
		streak_start.name = "RewardStreakStart"
		progress_box.add_child(reward_progress_row(host, "streak", streak_start, null, host.CYAN))
	if network_mission:
		var network_refresh := host.center_label(local_text("REWARD_NETWORK_REFRESH", "REDE PRONTA · TRÊS NOVOS MANDADOS AO VOLTAR AO QUADRO"), UIDesignSystem.FONT_CAPTION, host.CYAN)
		network_refresh.name = "RewardNetworkRefresh"
		progress_box.add_child(reward_progress_row(host, "warrant", network_refresh, null, host.CYAN))
	if unlocks_new_planet:
		var planet_names: Array[String] = []
		for planet in new_planets:
			planet_names.append(localized_content("planet", planet, "name").to_upper())
		var planet_unlock := host.center_label(local_text("REWARD_NEW_PLANET", "NOVO DESTINO AO RECEBER · %s", [", ".join(planet_names)]), UIDesignSystem.FONT_CAPTION, host.GOLD)
		planet_unlock.name = "RewardPlanetUnlock"
		var planet_context := host.center_label(local_text("REWARD_NEW_PLANET_CONTEXT", "PASSA A APARECER ENTRE OS TRÊS MANDADOS DIÁRIOS"), UIDesignSystem.FONT_CAPTION, host.LIME)
		planet_context.name = "RewardPlanetUnlockContext"
		progress_box.add_child(reward_progress_row(host, "warrant", planet_unlock, planet_context, host.GOLD))
	if unlocks_new_warrant:
		var unlock_label := host.center_label(local_text("REWARD_NEW_WARRANT", "NOVO MANDADO AO RECEBER · %s", [localized_content("target", next_target, "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.LIME)
		unlock_label.name = "RewardWarrantUnlock"
		var unlock_impact := warrant_impact_label(host, state.player, item, next_target, effective_upgrade, int(state.current_bounty.xp), "RewardWarrantOdds")
		progress_box.add_child(reward_progress_row(host, "warrant", unlock_label, unlock_impact, host.LIME))
	elif not next_target.is_empty() and not combined_next_capture:
		var progress_label := host.center_label(local_text("REWARD_WARRANT_PROGRESS", "RUMO A %s · %d/%d CAPTURAS DE %s", [localized_content("target", next_target, "name").to_upper(), int(progress_after.progress), int(progress_after.requirement), localized_content("target", progress_after.prerequisite, "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		progress_label.name = "RewardWarrantProgress"
		var next_impact := warrant_impact_label(host, state.player, item, next_target, effective_upgrade, int(state.current_bounty.xp), "RewardNextHuntImpact")
		progress_box.add_child(reward_progress_row(host, "warrant", progress_label, next_impact, host.CYAN))
	if progress_box.get_child_count() > 0:
		var progress_panel := host.panel(progress_box, Color("#10233b"), 10, 7)
		progress_panel.name = "RewardProgressPanel"
		box.add_child(progress_panel)
	var completes_chapter: bool = bool(state.current_bounty.get("boss", false)) and not bool(state.player.get("completed_planets", []).has(planet_id))
	var safe_to_recycle := state.can_recycle_reward(item)
	if not completes_chapter and not unlocks_new_warrant and not unlocks_new_planet:
		var next_streak_reward := Rules.bounty_streak_reward(int(state.current_bounty.credits), int(reward_preview.streak) + 1)
		var repeat_value := host.center_label(local_text("REWARD_NEXT_CAPTURE_MOMENTUM", "PRÓXIMA CAPTURA SEGUIDA · EMBALO ×%d · +%d%% SOBRE O PAGAMENTO", [int(next_streak_reward.streak), int(next_streak_reward.bonus_percent)]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		repeat_value.name = "RewardRepeatValue"
		content.add_child(repeat_value)
		var repeat := host.primary_action(local_text("REWARD_EQUIP_REPEAT", "EQUIPAR E REPETIR") if effective_upgrade else local_text("REWARD_STORE_REPEAT", "GUARDAR E REPETIR"), host.LIME)
		repeat.name = "ClaimAndRepeat"
		repeat.pressed.connect(func(): state.claim_reward(effective_upgrade, true))
		content.add_child(repeat)
		if safe_to_recycle:
			var recycle_repeat := host.secondary_action(local_text("REWARD_RECYCLE_REPEAT", "RECICLAR +%d SUCATA E REPETIR", [Rules.salvage_value(item)]), host.CORAL)
			recycle_repeat.name = "RecycleAndRepeat"
			recycle_repeat.pressed.connect(func(): state.claim_reward(false, true, true))
			content.add_child(recycle_repeat)
	elif safe_to_recycle:
		var recycle_destination := local_text("REWARD_VIEW_NEW_WARRANT", "VER NOVO MANDADO") if unlocks_new_warrant else local_text("REWARD_COMPLETE", "CONCLUIR")
		var recycle_complete := host.secondary_action(local_text("REWARD_RECYCLE_COMPLETE", "RECICLAR +%d SUCATA E %s", [Rules.salvage_value(item), recycle_destination]), host.CORAL)
		recycle_complete.name = "RecycleAndComplete"
		recycle_complete.pressed.connect(func(): state.claim_reward(false, false, true))
		content.add_child(recycle_complete)
	if mastery_after_reward > reward_mastery and not completes_chapter:
		var workshop_text := local_text("REWARD_EQUIP_WORKSHOP", "EQUIPAR E IR À OFICINA") if effective_upgrade else local_text("REWARD_STORE_WORKSHOP", "GUARDAR E IR À OFICINA")
		if unlocks_new_warrant:
			workshop_text = local_text("REWARD_EQUIP_PREPARE_WARRANT", "EQUIPAR E PREPARAR NOVO MANDADO") if effective_upgrade else local_text("REWARD_STORE_PREPARE_WARRANT", "GUARDAR E PREPARAR NOVO MANDADO")
		var workshop := host.secondary_action(workshop_text, host.CYAN)
		workshop.name = "ClaimAndWorkshop"
		workshop.pressed.connect(func():
			host.arsenal_section = "workshop"
			host.view_mode = "arsenal"
			state.claim_reward(effective_upgrade)
		)
		content.add_child(workshop)
	var claim_text := ""
	if completes_chapter:
		claim_text = local_text("REWARD_CLAIM_COMPLETE_CHAPTER", "RECEBER E CONCLUIR CAPÍTULO")
	elif unlocks_new_planet:
		claim_text = local_text("REWARD_EQUIP_VIEW_PLANET", "EQUIPAR E VER NOVO DESTINO") if effective_upgrade else local_text("REWARD_STORE_VIEW_PLANET", "GUARDAR E VER NOVO DESTINO")
	elif unlocks_new_warrant:
		claim_text = local_text("REWARD_EQUIP_VIEW_WARRANT", "EQUIPAR E VER NOVO MANDADO") if effective_upgrade else local_text("REWARD_STORE_VIEW_WARRANT", "GUARDAR E VER NOVO MANDADO")
	else:
		claim_text = local_text("REWARD_EQUIP_BOARD", "EQUIPAR E VOLTAR AO QUADRO") if effective_upgrade else local_text("REWARD_STORE_BOARD", "GUARDAR E VOLTAR AO QUADRO")
	var claim := host.primary_action(claim_text, host.LIME) if completes_chapter or unlocks_new_warrant or unlocks_new_planet else host.secondary_action(claim_text, host.GOLD)
	claim.name = "ClaimAndPlanet" if unlocks_new_planet else ("ClaimAndUnlock" if unlocks_new_warrant else "ClaimAndBoard")
	claim.pressed.connect(func():
		if unlocks_new_planet:
			host.view_mode = "galaxy"
		state.claim_reward(effective_upgrade)
	)
	content.add_child(claim)


static func build_challenge_reward(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var item := state.pending_loot
	var equipped: Dictionary = state.player.get(str(item.slot), {})
	var effective_upgrade := Rules.is_upgrade_for_player(state.player, item)
	content.add_child(host.center_label(local_text("RIFT_REWARD_FLOOR_CLEAR", "FENDA CLANDESTINA · ANDAR %d LIMPO", [int(state.current_bounty.get("challenge_index", 0)) + 1]), UIDesignSystem.FONT_CAPTION, host.LIME))
	content.add_child(host.center_label(local_text("RIFT_REWARD_ARTIFACT", "ARTEFATO RECUPERADO"), UIDesignSystem.FONT_SECTION_TITLE, host.INK))
	var reward_scroll := ScrollContainer.new()
	reward_scroll.name = "ChallengeRewardScroll"
	reward_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(reward_scroll)
	var reward_stack := VBoxContainer.new()
	reward_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_scroll.add_child(reward_stack)
	var reward_panel := host.illustrated_panel(VBoxContainer.new(), 16)
	reward_panel.name = "ChallengeRewardPanel"
	reward_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_stack.add_child(reward_panel)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(host.equipment_icon(item, 76))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(host.label("%s · %s" % [localized_rarity(str(item.rarity)), localized_slot(str(item.slot)).to_upper()], UIDesignSystem.FONT_CAPTION, Color(str(item.color))))
	var procedural_identity := EquipmentPresentation.procedural_identity_text(item)
	if not procedural_identity.is_empty():
		copy.add_child(host.label(procedural_identity, UIDesignSystem.FONT_CAPTION, host.CYAN))
	copy.add_child(host.label(localized_item_field(item, "name"), UIDesignSystem.FONT_BODY, host.INK))
	var description := host.label(localized_item_field(item, "description"), UIDesignSystem.FONT_CAPTION, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	var modifier_text := EquipmentPresentation.modifier_text(item)
	if not modifier_text.is_empty():
		var modification := host.center_label("◆ %s" % modifier_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
		modification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(modification)
	box.add_child(host.center_label(EquipmentPresentation.equipment_delta_text(state.player, item), UIDesignSystem.FONT_CAPTION, host.LIME if effective_upgrade else host.MUTED))
	box.add_child(host.center_label(local_text("RIFT_REWARD_RECEIPT", "RECIBO DA FENDA · ◈ %d CRÉDITOS · %d XP", [int(state.current_bounty.credits), int(state.current_bounty.xp)]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var comparison := host.center_label(local_text("RIFT_REWARD_EQUIPPED", "EQUIPADO AGORA · +%d PODER", [int(equipped.get("power", 0))]), UIDesignSystem.FONT_CAPTION, host.MUTED)
	comparison.name = "ChallengeEquippedComparison"
	box.add_child(comparison)
	var next_floor := int(state.current_bounty.get("challenge_index", 0)) + 2
	var progress := host.center_label(local_text("RIFT_REWARD_NEXT_FLOOR", "AO RECEBER · ANDAR %d SERÁ ABERTO", [next_floor]) if next_floor <= ChallengeRules.STAGES.size() else local_text("RIFT_REWARD_COMPLETE", "AO RECEBER · FENDA SERÁ CONCLUÍDA"), UIDesignSystem.FONT_CAPTION, host.CYAN)
	progress.name = "ChallengeRewardProgress"
	box.add_child(progress)
	var claim := host.primary_action(local_text("RIFT_REWARD_EQUIP_RETURN", "EQUIPAR E VOLTAR À FENDA") if effective_upgrade else local_text("RIFT_REWARD_STORE_RETURN", "GUARDAR E VOLTAR À FENDA"), host.LIME)
	claim.name = "ClaimChallengeReward"
	claim.pressed.connect(func(): state.claim_reward(effective_upgrade))
	content.add_child(claim)


static func reward_metric_chip(host: CrookedUIFactory, title: String, value: String, color: Color, node_name: String) -> PanelContainer:
	var chip := host.panel(VBoxContainer.new(), Color("#0a1025"), 8, 5)
	chip.name = node_name
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chip_box := chip.get_child(0) as VBoxContainer
	chip_box.add_theme_constant_override("separation", 0)
	chip_box.add_child(host.label(title, UIDesignSystem.FONT_CAPTION, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	chip_box.add_child(host.label(value, UIDesignSystem.FONT_BODY, color, HORIZONTAL_ALIGNMENT_CENTER))
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
	var result := host.center_label(text, UIDesignSystem.FONT_CAPTION, host.GOLD)
	result.name = node_name
	return result
