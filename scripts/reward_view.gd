class_name RewardView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var item := state.pending_loot
	var reward_preview := Rules.bounty_streak_reward(int(state.current_bounty.credits), int(state.player.get("capture_streak", 0)) + 1)
	content.add_child(host.center_label("CONTRATO CONCLUÍDO · %s" % str(state.current_bounty.name).to_upper(), 16, host.LIME))
	content.add_child(host.center_label("RECOMPENSA CAPTURADA", 32, host.INK))
	var reward_panel := host.panel(VBoxContainer.new(), host.PANEL_LIGHT, 20, 20)
	reward_panel.modulate = Color(1, 1, 1, 0)
	content.add_child(reward_panel)
	reward_panel.create_tween().tween_property(reward_panel, "modulate", Color.WHITE, 0.32)
	var box := reward_panel.get_child(0) as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	box.add_child(host.center_label("⚙", 58, Color(str(item.color))))
	box.add_child(host.center_label(str(item.rarity).to_upper(), 15, Color(str(item.color))))
	box.add_child(host.center_label(str(item.name), 25, host.INK))
	var origin_id := str(item.get("origin_planet_id", ""))
	if not origin_id.is_empty():
		box.add_child(host.center_label("ORIGEM · %s" % str(Content.get_planet(origin_id).name).to_upper(), 12, host.CYAN))
	var description := host.center_label(str(item.get("description", "Procedência criativamente desconhecida.")), 15, host.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	box.add_child(host.center_label("+%d PODER · %s" % [int(item.power), host.slot_name(str(item.slot))], 18, host.GOLD))
	var equipped: Dictionary = state.player[str(item.slot)]
	var comparison := int(item.power) - int(equipped.power)
	if comparison > 0:
		box.add_child(host.center_label("▲ UPGRADE ENCONTRADO", 15, host.LIME))
	var effective_upgrade := Rules.is_upgrade_for_player(state.player, item)
	if effective_upgrade and comparison <= 0:
		box.add_child(host.center_label("▲ MODIFICAÇÃO SUPERIOR", 15, host.LIME))
	if item.has("trait"):
		box.add_child(host.center_label("◆ %s · %s" % [str(item.trait.name), str(item.trait.description)], 13, host.GOLD))
	box.add_child(host.center_label(EquipmentPresentation.equipment_delta_text(state.player, item), 15, host.LIME if effective_upgrade else host.MUTED))
	box.add_child(host.center_label("EQUIPADO: %s +%d · RECICLAGEM: %d SUCATA" % [str(equipped.name), int(equipped.power), Rules.salvage_value(item)], 12, host.MUTED))
	var contract_scrap := int(state.current_bounty.get("scrap_reward", 0))
	var reward_line := "◈ %d créditos   ✦ %d XP" % [int(reward_preview.credits), int(state.current_bounty.xp)]
	if contract_scrap > 0:
		reward_line += "   ⚙ %d sucata" % contract_scrap
	var reward_totals := host.center_label(reward_line, 17, host.GOLD)
	reward_totals.name = "RewardContractTotals"
	box.add_child(reward_totals)
	var incident_cost := maxi(0, int(state.current_bounty.get("hunt_event_credit_cost", 0)))
	if incident_cost > 0:
		var incident_net := host.center_label("INCIDENTE JÁ PAGO · -%d CRÉDITOS · SALDO DO CONTRATO +%d" % [incident_cost, int(reward_preview.credits) - incident_cost], 12, host.CYAN)
		incident_net.name = "RewardIncidentNet"
		box.add_child(incident_net)
	var previous_captures := int(state.player.get("captures_by_target", {}).get(str(state.current_bounty.id), 0))
	var reward_mastery := Rules.target_mastery_level(previous_captures)
	if reward_mastery > 0:
		var mastery_label := host.center_label("PERÍCIA COM ALVO %d/3 · QUALIDADE DE LOOT AMPLIADA" % reward_mastery, 13, host.LIME)
		mastery_label.name = "RewardMastery"
		box.add_child(mastery_label)
	var captures_after_reward := previous_captures + 1
	var mastery_after_reward := Rules.target_mastery_level(captures_after_reward)
	if mastery_after_reward > reward_mastery:
		var mastery_unlock := host.center_label("NOVA PERÍCIA AO RECEBER · NÍVEL %d/3" % mastery_after_reward, 13, host.GOLD)
		mastery_unlock.name = "RewardMasteryUnlock"
		box.add_child(mastery_unlock)
		var mastery_bonus := host.center_label("+%d%% RARO · +%d%% ÉPICO · OFICINA +%d SUCATA" % [mastery_after_reward * 5, mastery_after_reward * 2, Rules.target_mastery_scrap_reward(mastery_after_reward)], 12, host.LIME)
		mastery_bonus.name = "RewardMasteryUnlockBonus"
		box.add_child(mastery_bonus)
	else:
		var next_mastery_requirement := Rules.target_mastery_next_requirement(reward_mastery)
		if next_mastery_requirement > 0:
			var mastery_progress := host.center_label("PRÓXIMA PERÍCIA · %d/%d CAPTURAS" % [captures_after_reward, next_mastery_requirement], 12, host.CYAN)
			mastery_progress.name = "RewardMasteryProgress"
			box.add_child(mastery_progress)
	if int(reward_preview.bonus_credits) > 0:
		var streak_bonus := host.center_label("EMBALO ×%d · +%d créditos (+%d%%)" % [int(reward_preview.streak), int(reward_preview.bonus_credits), int(reward_preview.bonus_percent)], 14, host.LIME)
		streak_bonus.name = "RewardStreakBonus"
		box.add_child(streak_bonus)
	elif int(reward_preview.streak) == 1:
		var streak_start := host.center_label("EMBALO REINICIADO ×1 · BÔNUS COMEÇA NA PRÓXIMA CAPTURA", 12, host.CYAN)
		streak_start.name = "RewardStreakStart"
		box.add_child(streak_start)
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
	if unlocks_new_warrant:
		var unlock_label := host.center_label("NOVO MANDADO AO RECEBER · %s" % str(next_target.name).to_upper(), 14, host.LIME)
		unlock_label.name = "RewardWarrantUnlock"
		box.add_child(unlock_label)
		var projected_player: Dictionary = state.player.duplicate(true)
		if effective_upgrade:
			projected_player[str(item.slot)] = item.duplicate(true)
		var evaluations := ContractRules.evaluate_approaches(projected_player, next_target, Content.contract_approaches())
		var recommended_id := ContractRules.recommended_approach_id(evaluations)
		for evaluation in evaluations:
			if str(evaluation.id) != recommended_id:
				continue
			var route_name := str(evaluation.preview.get("approach", {}).get("name", "ROTA SEGURA"))
			var projection_prefix := "APÓS EQUIPAR" if effective_upgrade else "COM BUILD ATUAL"
			var projection := host.center_label("MELHOR ROTA %s · %s · %d%%" % [projection_prefix, route_name.to_upper(), roundi(float(evaluation.odds) * 100.0)], 12, host.GOLD)
			projection.name = "RewardWarrantOdds"
			box.add_child(projection)
			break
	elif not next_target.is_empty():
		var progress_label := host.center_label("RUMO A %s · %d/%d CAPTURAS DE %s" % [str(next_target.name).to_upper(), int(progress_after.progress), int(progress_after.requirement), str(progress_after.prerequisite.name).to_upper()], 13, host.CYAN)
		progress_label.name = "RewardWarrantProgress"
		box.add_child(progress_label)
	content.add_spacer(false)
	var completes_chapter: bool = bool(state.current_bounty.get("boss", false)) and not bool(state.player.get("completed_planets", []).has(planet_id))
	var safe_to_recycle := state.can_recycle_reward(item)
	if not completes_chapter and not unlocks_new_warrant:
		var next_streak_reward := Rules.bounty_streak_reward(int(state.current_bounty.credits), int(reward_preview.streak) + 1)
		var repeat_value := host.center_label("PRÓXIMA CAPTURA SEGUIDA · EMBALO ×%d · +%d%% SOBRE O PAGAMENTO" % [int(next_streak_reward.streak), int(next_streak_reward.bonus_percent)], 12, host.CYAN)
		repeat_value.name = "RewardRepeatValue"
		content.add_child(repeat_value)
		var repeat := host.action_button("EQUIPAR E REPETIR" if effective_upgrade else "GUARDAR E REPETIR", host.LIME)
		repeat.name = "ClaimAndRepeat"
		repeat.pressed.connect(func(): state.claim_reward(effective_upgrade, true))
		content.add_child(repeat)
		if safe_to_recycle:
			var recycle_repeat := host.action_button("RECICLAR +%d SUCATA E REPETIR" % Rules.salvage_value(item), host.CORAL, true)
			recycle_repeat.name = "RecycleAndRepeat"
			recycle_repeat.custom_minimum_size = Vector2(0, 48)
			recycle_repeat.pressed.connect(func(): state.claim_reward(false, true, true))
			content.add_child(recycle_repeat)
	elif safe_to_recycle:
		var recycle_destination := "VER NOVO MANDADO" if unlocks_new_warrant else "CONCLUIR"
		var recycle_complete := host.action_button("RECICLAR +%d SUCATA E %s" % [Rules.salvage_value(item), recycle_destination], host.CORAL, true)
		recycle_complete.name = "RecycleAndComplete"
		recycle_complete.custom_minimum_size = Vector2(0, 48)
		recycle_complete.pressed.connect(func(): state.claim_reward(false, false, true))
		content.add_child(recycle_complete)
	if mastery_after_reward > reward_mastery and not completes_chapter:
		var workshop_text := "EQUIPAR E IR À OFICINA" if effective_upgrade else "GUARDAR E IR À OFICINA"
		if unlocks_new_warrant:
			workshop_text = "EQUIPAR E PREPARAR NOVO MANDADO" if effective_upgrade else "GUARDAR E PREPARAR NOVO MANDADO"
		var workshop := host.action_button(workshop_text, host.CYAN, true)
		workshop.name = "ClaimAndWorkshop"
		workshop.custom_minimum_size = Vector2(0, 48)
		workshop.pressed.connect(func():
			host.view_mode = "arsenal"
			state.claim_reward(effective_upgrade)
		)
		content.add_child(workshop)
	var claim_text := ""
	if completes_chapter:
		claim_text = "RECEBER E CONCLUIR CAPÍTULO"
	elif unlocks_new_warrant:
		claim_text = "EQUIPAR E VER NOVO MANDADO" if effective_upgrade else "GUARDAR E VER NOVO MANDADO"
	else:
		claim_text = "EQUIPAR E VOLTAR AO QUADRO" if effective_upgrade else "GUARDAR E VOLTAR AO QUADRO"
	var claim := host.action_button(claim_text, host.LIME if completes_chapter or unlocks_new_warrant else host.GOLD, true)
	claim.name = "ClaimAndUnlock" if unlocks_new_warrant else "ClaimAndBoard"
	claim.custom_minimum_size = Vector2(0, 48)
	claim.pressed.connect(func(): state.claim_reward(effective_upgrade))
	content.add_child(claim)
