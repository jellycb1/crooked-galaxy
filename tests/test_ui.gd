extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_smoke_test")


func run_smoke_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	state.pending_loot = {}
	state.last_notice = ""
	state.last_notice_context = ""

	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.content.get_child_count() >= 4, "bounty board renders")
	var header_character := scene.find_child("HeaderCharacterAction", true, false) as Button
	check(header_character != null and scene.find_child("HeaderHunterPortrait", true, false) != null, "primary header keeps hunter identity and character navigation visible")
	check(scene.find_child("HeaderResourceStrip", true, false) != null and ["HeaderCredits", "HeaderScrap", "HeaderReputation", "HeaderWins"].all(func(node_name): return scene.find_child(node_name, true, false) != null), "primary header keeps all resources in one compact ledger")
	if header_character != null:
		header_character.pressed.emit()
		await process_frame
		check(scene.view_mode == "attributes" and scene.find_child("AttributeScroll", true, false) != null, "header portrait opens the character build directly")
		scene.view_mode = "board"
		scene.render()
		await process_frame
	check(scene.environment_context() == "contracts", "board resolves the original bounty-office environment")
	scene.view_mode = "arsenal"
	check(scene.environment_context() == "workshop", "arsenal resolves the original workshop environment")
	scene.view_mode = "market"
	check(scene.environment_context() == "workshop", "market shares the equipment workshop environment")
	scene.view_mode = "career"
	check(scene.environment_context() == "world", "career resolves the original frontier-world environment")
	scene.view_mode = "attributes"
	check(scene.environment_context() == "world", "attributes resolve the original frontier-world environment")
	scene.view_mode = "board"
	check(scene.find_child("NextWarrantProgress", true, false) != null, "board keeps the next-warrant objective above the contract list")

	var bounty: Dictionary = ContentDB.TARGETS[0].duplicate(true)
	state.player.captures_by_target = {"gloop": 3}
	state.player.reputation = 1
	state.player.capture_streak = 2
	scene.render()
	await process_frame
	check(scene.find_child("BoardChoiceHint", true, false) != null, "expanded board explains the primary-versus-repeat choice")
	check(scene.find_child("BountyRole_gloop", true, false) != null and scene.find_child("BountyAction_gloop", true, false).text == "REPETIR CAÇADA", "prior warrant is clearly presented as a repeat hunt")
	check(scene.find_child("BountyMastery_gloop", true, false) != null, "bounty cards expose target mastery progress")
	check(scene.find_child("MasteryRoute_gloop", true, false) != null, "bounty board preserves the career mastery recommendation")
	(scene.find_child("BountyAction_gloop", true, false) as Button).pressed.emit()
	await process_frame
	check(str(state.current_bounty.id) == "gloop" and int(state.player.captures_by_target.gloop) == 3, "repeat action opens the prior target without mutating campaign progress")
	check(scene.find_child("BriefingScroll", true, false) != null, "contract briefing renders")
	check(scene.find_child("BriefingFieldTestContext", true, false) == null, "ordinary board briefings do not claim a prior field test")
	check(scene.find_child("BriefingMastery", true, false) != null, "briefing explains mastery loot bonuses")
	check(scene.find_children("RecommendedApproach_*", "Label", true, false).size() == 1, "briefing renders exactly one dynamic recommendation")
	check(scene.find_children("ApproachBonusSummary_*", "Label", true, false).size() == 3, "briefing keeps streak-adjusted payment concise on every route")
	var recommendation_hint := scene.find_child("BriefingRecommendationHint", true, false) as Label
	check(recommendation_hint != null and recommendation_hint.text.contains("BUILD") and recommendation_hint.text.contains("risco") and recommendation_hint.text.contains("retorno") and recommendation_hint.text.contains("tempo"), "briefing explains the recommendation's build, risk, return, and time basis")
	var route_buttons := scene.find_children("ChooseApproach_*", "Button", true, false)
	check(route_buttons.size() == 3 and route_buttons.all(func(button): return str(button.text).contains("ESCOLHER · ") and not str(button.text).ends_with("SEGURO")), "each briefing action names the route it will confirm instead of repeating a shared risk tier")
	var corporate_bonus := scene.find_child("ApproachBonusSummary_premium_warrant", true, false) as Label
	check(corporate_bonus != null and corporate_bonus.text.contains("SUCATA NA VITÓRIA"), "briefing exposes the corporate workshop reward before commitment")
	check(scene.find_children("ApproachBuildRisk_*", "Label", true, false).size() == 3 and scene.find_children("ApproachBuild_*", "PanelContainer", true, false).size() == 3, "every route exposes explicit build odds and a risk reading in the same scan order")
	state.choose_approach("quiet_net")
	await process_frame
	var hunt_progress_stage := scene.find_child("HuntProgressStage", true, false) as Label
	check(scene.find_child("HuntProgress", true, false) != null and hunt_progress_stage != null and hunt_progress_stage.text.contains("%"), "hunt screen renders a named pursuit stage with exact progress")
	var hunt_abandon := scene.find_child("HuntAbandonAction", true, false) as Button
	check(hunt_abandon != null and hunt_abandon.text.contains("PERDER EMBALO ×2"), "active hunt announces the exact streak cost before abandonment")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	state.player.credits = 0
	scene.render()
	await process_frame
	check(scene.find_child("HuntEventChoices", true, false) != null, "mid-hunt incident renders")
	check(scene.find_child("HuntEventDossier", true, false) != null and scene.find_child("HuntEventSignal", true, false) != null, "incident leads with one illustrated field dossier before its decisions")
	var incident_icons := scene.find_children("HuntChoiceIcon_*", "Control", true, false)
	var incident_kinds := {}
	for icon in incident_icons:
		incident_kinds[icon.kind] = true
	check(incident_icons.size() == 3 and incident_kinds.size() == 3 and ["tactical", "detour", "risk"].all(func(kind): return incident_kinds.has(kind)), "incident choices carry the reusable tactical, detour, and risk visual grammar")
	var incident_abandon := scene.find_child("HuntAbandonAction", true, false) as Button
	check(incident_abandon != null and incident_abandon.text.contains("PERDER EMBALO ×2"), "paused incident preserves the same explicit abandonment consequence")
	var pause_status := scene.find_child("HuntEventPauseStatus", true, false) as Label
	check(pause_status != null and pause_status.text.contains("PAUSADA EM") and pause_status.text.contains("RESTANTES"), "incident explains the paused hunt position and remaining time")
	var incident_payments := scene.find_children("HuntChoicePayment_*", "Label", true, false)
	check(incident_payments.size() == 3 and incident_payments.all(func(payment): return str(payment.text).contains("EMBALO") and str(payment.text).contains("INCLUÍDO")), "incident choices project streak-adjusted victory payments")
	var paid_incident := scene.find_child("HuntChoicePayment_bribe", true, false) as Label
	check(paid_incident != null and paid_incident.text.contains("LÍQUIDO"), "paid incident choice exposes its net contract gain")
	var unavailable_paid_choice := scene.find_child("HuntChoice_bribe", true, false) as Button
	var free_choice := scene.find_child("HuntChoice_detour", true, false) as Button
	check(unavailable_paid_choice != null and unavailable_paid_choice.disabled and unavailable_paid_choice.text == "FALTAM 8 CR", "unaffordable incident choice names the exact credit shortfall")
	check(free_choice != null and not free_choice.disabled and free_choice.text == "ESCOLHER", "no-cost incident alternatives remain actionable without credits")
	state.player.credits = 25
	state.resolve_hunt_event("bribe")
	await process_frame

	state.begin_combat()
	await process_frame
	check(state.player_hp > 0 and state.enemy_hp > 0, "combat screen initializes")
	check(scene.environment_context() == "combat", "combat resolves the original frontier-arena environment")
	var combat_loadout := scene.find_child("CombatLoadoutSummary", true, false) as Label
	check(combat_loadout != null and combat_loadout.text.contains("ARMA") and combat_loadout.text.contains("ARMADURA"), "combat portrait names the equipment values driving its visual loadout")
	var combat_incident := scene.find_child("CombatIncidentSummary", true, false) as Label
	check(combat_incident != null and combat_incident.text.contains("PAGAMENTO") and combat_incident.text.contains("EMBALO"), "combat carries the chosen incident consequence and adjusted payout")
	var opening_advantage := scene.find_child("CombatAdvantage", true, false) as Label
	check(opening_advantage != null and opening_advantage.text.contains("VOCÊ 100%") and opening_advantage.text.contains("ALVO 100%") and opening_advantage.text.contains("EQUILIBRADA"), "combat opens with an explicit relative-health reading")
	check(scene.find_child("CombatPressureTrack", true, false) != null and scene.find_child("CombatPressurePlayer", true, false) != null and scene.find_child("CombatPressureEnemy", true, false) != null, "combat turns relative health into a persistent two-sided pressure strip")
	state.combat_step()
	scene.render()
	await process_frame
	check(state.combat_events.size() == 2, "combat action cards render")
	var turn_balance := scene.find_child("CombatTurnBalance", true, false) as Label
	var hunter_health := scene.find_child("CombatHealth_hunter", true, false) as Label
	var enemy_health := scene.find_child("CombatHealth_%s" % str(state.current_bounty.id), true, false) as Label
	check(turn_balance != null and turn_balance.text.contains("VOCÊ") and turn_balance.text.contains("ALVO") and turn_balance.text.contains("DANO"), "combat summarizes both sides of the latest automatic turn")
	check(hunter_health != null and enemy_health != null and hunter_health.text.contains("%") and enemy_health.text.contains("%"), "both fighters expose raw and percentage health")
	check(scene.find_child("CombatEventPlayer", true, false) != null and scene.find_child("CombatEventEnemy", true, false) != null, "latest player and enemy events remain visually distinct")
	var combat_speed := scene.find_child("CombatSpeedAction", true, false) as Button
	check(combat_speed != null and combat_speed.text.contains("1×"), "combat exposes its current automatic pace")
	combat_speed.pressed.emit()
	await process_frame
	check(scene.combat_fast and is_equal_approx(scene.combat_timer.wait_time, 0.34), "combat speed switches to a persistent session 2× pace")

	state.finish_combat(true)
	await process_frame
	check(state.phase == state.Phase.VICTORY, "victory screen renders before loot")
	check(scene.combat_timer.is_stopped() and scene.combat_fast, "victory stops automatic turns without resetting the chosen combat pace")
	check(not state.pending_loot.is_empty(), "reward screen receives an item")
	check(scene.find_child("CombatSummaryVictory", true, false) != null, "victory explains aggregate combat performance")
	check(scene.find_child("VictoryDossier", true, false) != null and scene.find_child("VictoryPaymentCard", true, false) != null, "victory groups target, verdict, report, and payment into a coherent dossier")
	var victory_payment := scene.find_child("VictoryPayment", true, false) as Label
	check(victory_payment != null and victory_payment.text.contains("EMBALO") and victory_payment.text.contains("SALDO"), "victory preserves the paid-incident payout receipt")
	var open_reward_action := scene.find_child("OpenRewardAction", true, false) as Button
	check(open_reward_action != null and scene.victory_timer.wait_time >= 2.5, "victory allows an immediate reward while preserving a readable automatic pause")

	state.open_reward()
	await process_frame
	check(scene.find_child("RewardEquipmentIcon", true, false) != null, "reward presents loot with a slot- and origin-specific icon")
	check(scene.find_child("RewardMastery", true, false) != null, "reward screen confirms applied target mastery")
	check(scene.find_child("RewardMasteryProgress", true, false) != null, "reward screen counts the pending capture toward the next mastery")
	check(scene.find_child("RewardWarrantProgress", true, false) != null, "reward screen previews progress toward the next warrant")
	check(scene.find_child("RewardIncidentNet", true, false) != null, "reward screen receives the same paid-incident receipt")
	check(scene.find_child("ClaimAndRepeat", true, false) != null, "reward screen offers another contract immediately")
	check(scene.find_child("ClaimAndBoard", true, false) != null, "reward screen preserves the board return path")
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	state.player.captures_by_target = {"gloop": 2}
	scene.render()
	await process_frame
	check(scene.find_child("RewardWarrantUnlock", true, false) != null, "third capture previews the newly unlocked warrant")
	check(scene.find_child("ClaimAndRepeat", true, false) == null, "unlock reward directs the first visit back to the expanded board")
	var unlock_claim := scene.find_child("ClaimAndUnlock", true, false) as Button
	check(unlock_claim != null and unlock_claim.text.contains("NOVO MANDADO"), "unlock reward CTA names its destination")
	state.player.captures_by_planet = {}
	scene.render()
	await process_frame
	state.claim_reward(true)
	await process_frame
	scene.board_section = "destinations"
	scene.render()
	await process_frame
	var post_claim_field_test := scene.find_child("PrimaryNav_arsenal", true, false) as Button
	check(post_claim_field_test != null and post_claim_field_test.text == "TESTAR" and scene.find_child("PrimaryNavBadge_arsenal", true, false) != null, "equipped reward receipt turns the persistent arsenal destination into a field-test continuation")
	post_claim_field_test.pressed.emit()
	await process_frame
	check(scene.view_mode == "arsenal" and scene.find_child("FieldReadiness", true, false) != null, "post-claim shortcut opens the newly equipped build beside its field odds")
	var tested_route_action := scene.find_child("FieldReadinessAction", true, false) as Button
	check(tested_route_action != null, "post-claim field test offers the focused warrant handoff")
	if tested_route_action != null:
		tested_route_action.pressed.emit()
		await process_frame
		var tested_context := scene.find_child("BriefingFieldTestContext", true, false) as Label
		check(state.phase == state.Phase.BRIEFING and tested_context != null and tested_context.text.contains("RECOMENDAÇÃO CONFIRMADA"), "field-test briefing visibly acknowledges the tested build and recommendation")
		var briefing_cancel := scene.find_child("BriefingCancel", true, false) as Button
		if briefing_cancel != null:
			briefing_cancel.pressed.emit()
			await process_frame
		check(scene.briefing_context.is_empty(), "leaving the tested briefing clears its transient context")
		scene.view_mode = "arsenal"
		scene.render()
		await process_frame
		var second_route_action := scene.find_child("FieldReadinessAction", true, false) as Button
		check(second_route_action != null, "tested briefing can be reopened after a clean cancellation")
		if second_route_action != null:
			second_route_action.pressed.emit()
			await process_frame
			var tested_id := str(scene.briefing_context.get("approach_id", ""))
			var override_id := "premium_warrant" if tested_id != "premium_warrant" else "quiet_net"
			var override_action := scene.find_child("ChooseApproach_%s" % override_id, true, false) as Button
			check(override_action != null, "tested briefing retains an explicit alternative route")
			if override_action != null:
				override_action.pressed.emit()
				await process_frame
				var override_record := scene.find_child("HuntFieldTestContext", true, false) as Label
				check(override_record != null and override_record.text.contains("SUBSTITUÍDA") and override_record.text.contains("→"), "hunt records a deliberate override of the tested route")
				var override_text := override_record.text if override_record != null else ""
				check(scene.briefing_context.is_empty(), "choosing a route clears transient briefing context after persisting the contract record")
				state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
				state.hunt_event_triggered = true
				state.hunt_elapsed_before_event = 2.0
				state.hunt_remaining_after_event = 3.0
				state.phase = state.Phase.HUNT_EVENT
				scene.render()
				await process_frame
				var incident_test_record := scene.find_child("IncidentFieldTestContext", true, false) as Label
				check(incident_test_record != null and incident_test_record.text == override_text, "hunt incident preserves the exact tested-route override record")
				state.resolve_hunt_event(str(ContentDB.HUNT_EVENTS[0].choices[0].id))
				state.begin_combat()
				await process_frame
				var combat_test_record := scene.find_child("CombatFieldTestContext", true, false) as Label
				check(combat_test_record != null and combat_test_record.text == override_text, "combat preserves the exact tested-route override record beside the selected approach")
				state.enemy_hp = 0
				state.finish_combat(true)
				await process_frame
				var victory_test_record := scene.find_child("VictoryFieldTestContext", true, false) as Label
				check(victory_test_record != null and victory_test_record.text == override_text, "victory closes the encounter with the exact tested-route override record")
				scene.victory_timer.stop()
				state.open_reward()
				await process_frame
				check(scene.find_child("VictoryFieldTestContext", true, false) == null and scene.find_child("RewardNextHuntImpact", true, false) != null, "reward cleanly replaces route provenance with the next-hunt loot projection")
				state.phase = state.Phase.BOARD
				state.current_bounty = {}
				state.pending_loot = {}
				state.combat_summary = {}
				scene.render()
				await process_frame
	scene.view_mode = "board"
	state.last_notice = "Contrato pago: Peça de Reserva guardado"
	state.last_notice_context = "reward_stored"
	scene.render()
	await process_frame
	var stored_arsenal_action := scene.find_child("PrimaryNav_arsenal", true, false) as Button
	check(stored_arsenal_action != null and stored_arsenal_action.text == "ARSENAL" and scene.find_child("PrimaryNavBadge_arsenal", true, false) == null, "stored reward receipts keep the ordinary arsenal destination")
	scene.board_section = "bounties"
	state.player.capture_streak = 1
	state.last_notice = "Contrato pago: +34 créditos · +53 XP · Peça de Reserva guardada · Embalo ×1 iniciado: próxima captura +5%"
	state.last_notice_context = "reward_stored"
	scene.render()
	await process_frame
	check(scene.find_child("StreakNotice", true, false) == null, "sequence-opening reward receipt prevents a duplicate streak tutorial on the board")
	state.player.capture_streak = 2
	scene.board_section = "bounties"
	scene.render()
	await process_frame
	check(scene.find_child("StreakNotice", true, false) != null, "an established streak keeps its forward-looking board reminder")
	scene.board_section = "destinations"
	state.player.scrap = 0
	state.last_notice = "Contrato pago: +34 créditos · +53 XP · Primeira Melhoria equipada"
	state.last_notice_context = "reward_equipped"
	scene.render()
	await process_frame
	var unfunded_arsenal_action := scene.find_child("PrimaryNav_arsenal", true, false) as Button
	check(unfunded_arsenal_action != null and unfunded_arsenal_action.text == "ARSENAL" and scene.find_child("PrimaryNavBadge_arsenal", true, false) == null, "equipped receipt without a funded calibration keeps the ordinary arsenal route")
	state.last_notice = "Contrato pago: Recibo antigo equipado"
	state.last_notice_context = "career"
	scene.render()
	await process_frame
	var stale_arsenal_action := scene.find_child("PrimaryNav_arsenal", true, false) as Button
	check(stale_arsenal_action != null and stale_arsenal_action.text == "ARSENAL" and scene.find_child("PrimaryNavBadge_arsenal", true, false) == null, "equipped-looking stale text cannot forge a contextual field-test action")
	state.phase = state.Phase.REWARD
	state.current_bounty = bounty.duplicate(true)
	state.pending_loot = {"id": "ui_instant_scrap", "name": "Zapper Cansado", "slot": "weapon", "power": 0, "rarity": "Comum", "color": "#b9c2d9"}
	scene.render()
	await process_frame
	check(scene.find_child("RecycleAndRepeat", true, false) != null, "inferior common rewards offer immediate recycling")
	state.claim_reward(false, true, true)
	state.phase = state.Phase.BOARD
	state.player.scrap = 18
	state.player.inventory.append({"id": "ui_spare", "name": "Peça Obsoleta", "description": "Serve melhor desmontada.", "slot": "armor", "power": 6, "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "ui_inferior", "name": "Peça Arquivada", "description": "Já perdeu a discussão.", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"})
	scene.view_mode = "arsenal"
	scene.arsenal_section = "equipped"
	scene.render()
	await process_frame
	check(scene.find_child("ArsenalSectionTabs", true, false) != null and scene.find_child("InventoryScroll", true, false) == null, "arsenal opens on a focused equipped-build section")
	check(state.player.inventory.size() == 4, "arsenal receives claimed, replaced starter, spare, and inferior loot")
	check(scene.find_child("Upgrade_weapon", true, false) != null, "workshop renders equipment upgrades")
	check(scene.find_child("Reinforce_weapon", true, false) != null, "workshop renders integrity reinforcement")
	check(scene.find_child("LoadoutToolbar", true, false) != null, "arsenal renders equipment loadouts")
	check(scene.find_child("SaveLoadout_0", true, false) != null, "arsenal can save the hunt loadout")
	var backpack_tab := scene.find_child("ArsenalTab_inventory", true, false) as Button
	backpack_tab.pressed.emit()
	await process_frame
	check(scene.arsenal_section == "inventory" and scene.find_child("InventoryScroll", true, false) != null and scene.find_child("Upgrade_weapon", true, false) == null, "backpack tab replaces workshop controls with the inventory list")
	check(scene.find_child("Scrap_ui_spare", true, false) != null, "workshop renders recycling for spare loot")
	check(scene.find_child("Lock_ui_spare", true, false) != null, "inventory renders manual item protection")
	check(scene.find_child("InventoryFilter_weapon", true, false) != null, "arsenal renders slot filters")
	check(scene.find_child("InventorySort", true, false) != null, "arsenal renders inventory sorting")
	check(scene.find_child("AccessibilityPreferences", true, false) == null, "backpack keeps device preferences out of the item workflow")
	var bulk_recycle := scene.find_child("RecycleInferior", true, false) as Button
	check(bulk_recycle != null and not bulk_recycle.disabled, "arsenal enables safe bulk recycling when inferior items exist")
	var weapon_filter := scene.find_child("InventoryFilter_weapon", true, false) as Button
	weapon_filter.pressed.emit()
	await process_frame
	check(scene.inventory_filter == "weapon", "weapon filter updates arsenal state")
	check(scene.find_child("Scrap_ui_spare", true, false) == null, "weapon filter hides armor inventory cards")
	check(scene.find_child("Scrap_ui_inferior", true, false) != null, "weapon filter keeps weapon inventory cards")
	var sort_button := scene.find_child("InventorySort", true, false) as Button
	sort_button.pressed.emit()
	await process_frame
	check(scene.inventory_sort == "rarity", "sort control toggles from power to rarity")

	state.phase = state.Phase.CHAPTER_COMPLETE
	state.chapter_completion = {
		"planet": ContentDB.PLANET.duplicate(true),
		"target": ContentDB.TARGETS[3].duplicate(true),
		"total_captures": 10,
		"credits": ContentDB.TARGETS[3].credits,
	}
	scene.render()
	await process_frame
	check(scene.find_child("ChapterComplete", true, false) != null, "planet completion screen renders")

	state.phase = state.Phase.BOARD
	state.player.completed_planets = [ContentDB.PLANET.id]
	state.player.current_planet_id = ContentDB.PLANET.id
	state.player.reputation = 3
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(scene.find_child("GalaxyRoutes", true, false) != null, "galaxy map renders unlocked routes")
	var planet_icons := scene.find_children("GalaxyPlanetIcon_*", "Control", true, false)
	check(planet_icons.size() == ContentDB.PLANETS.size(), "every galaxy destination has a stable visual identity")
	var planet_motifs := {}
	for icon in planet_icons:
		planet_motifs[icon.motif_id()] = true
	check(not planet_motifs.has("unknown") and planet_motifs.size() == ContentDB.PLANETS.size(), "every canonical planet resolves a distinct visual motif")
	scene.view_mode = "board"
	scene.board_section = "bounties"
	check(state.travel_to_planet("congelaria_sa"), "UI state can travel to an unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_auditor_frost", true, false) != null, "second planet bounty board renders")
	state.player.completed_planets.append("congelaria_sa")
	check(state.travel_to_planet("micelia_404"), "UI state can enter the third unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_landlord_spore", true, false) != null, "third planet bounty board renders")
	state.player.completed_planets.append("micelia_404")
	check(state.travel_to_planet("ferro_velho_omega"), "UI state can enter the fourth unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_bolt_collector", true, false) != null, "fourth planet bounty board renders")
	state.player.completed_planets.append("ferro_velho_omega")
	check(state.travel_to_planet("cassino_quasar"), "UI state can enter the fifth unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_dealer_comet", true, false) != null, "fifth planet bounty board renders")
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(scene.find_child("GalaxyPlanetProgress_cassino_quasar", true, false) != null, "galaxy map names the active fifth-chapter objective")
	state.afk_report = {"minutes": 95, "credits": 380, "scrap": 6, "capped": false}
	state.last_notice = "SAVE RECUPERADO: progresso válido preservado; registros inconsistentes foram isolados."
	state.last_notice_context = "system_recovery"
	scene.view_mode = "board"
	scene.render()
	await process_frame
	check(scene.find_child("AfkReturnBanner", true, false) != null, "AFK return report renders on the bounty board")
	check(scene.find_child("AfkRecoveryNotice", true, false) != null, "save recovery shares the AFK report instead of stacking another board banner")
	var afk_dismiss := scene.find_child("AfkDismiss", true, false) as Button
	afk_dismiss.pressed.emit()
	await process_frame
	check(state.afk_report.is_empty() and state.last_notice.is_empty(), "acknowledging the combined return card clears both transient reports")
	state.last_notice = "SAVE ATUALIZADO: progresso legado preservado e registros ausentes reconstruídos."
	state.last_notice_context = "system_recovery"
	scene.render()
	await process_frame
	var recovery_dismiss := scene.find_child("BoardNoticeDismiss", true, false) as Button
	check(recovery_dismiss != null, "standalone save recovery offers an explicit acknowledgement")
	recovery_dismiss.pressed.emit()
	await process_frame
	check(state.last_notice.is_empty() and state.last_notice_context.is_empty(), "acknowledging standalone save recovery clears its transient notice")
	state.player.wins = 1
	state.player.captures_by_target = {"gloop": 1}
	scene.view_mode = "career"
	scene.render()
	await process_frame
	check(scene.find_child("CareerSummary", true, false) != null, "career summary renders")
	check(scene.find_child("CareerScroll", true, false) != null, "career planet and milestone list renders")
	check(scene.find_child("CareerProgressJump", true, false) != null and scene.find_child("CareerArchiveJump", true, false) != null, "career exposes progress and archive shortcuts")
	check(scene.find_child("ClaimAllMilestones", true, false) != null, "career renders a bulk claim action")
	check(scene.find_child("ClaimMilestone_first_warrant", true, false) != null, "career renders a claim action for completed milestones")
	check(scene.find_child("CareerTarget_gloop", true, false) != null, "career renders the wanted archive")
	check(scene.find_child("MasteryDirective", true, false) != null and scene.find_child("MasteryDirectiveAction", true, false) != null, "career turns repeat progress into a direct next action")
	var career_archive_jump := scene.find_child("CareerArchiveJump", true, false) as Button
	career_archive_jump.pressed.emit()
	await process_frame
	var career_scroll := scene.find_child("CareerScroll", true, false) as ScrollContainer
	var archive_position := career_scroll.scroll_vertical
	check(archive_position > 0 and scene.career_scroll_position == archive_position, "career remembers direct section navigation")
	var milestone_claim := scene.find_child("ClaimMilestone_first_warrant", true, false) as Button
	milestone_claim.pressed.emit()
	await process_frame
	await process_frame
	career_scroll = null
	for child in scene.content.get_children():
		if child is ScrollContainer:
			career_scroll = child
			break
	check(career_scroll != null and career_scroll.scroll_vertical == archive_position, "claiming a milestone restores the exact career scroll position after rerender")
	var career_receipt := scene.find_child("CareerClaimReceipt", true, false) as PanelContainer
	check(career_receipt != null and state.last_notice.contains("+40 créditos"), "claimed milestone leaves its exact receipt inside the career hub")
	check(scene.find_child("CareerSummary", true, false) != null, "transaction rerender replaces the career tree cleanly without duplicate-name layout drift")
	scene.view_mode = "board"
	scene.render()
	await process_frame
	scene.view_mode = "career"
	scene.render()
	await process_frame
	await process_frame
	career_scroll = null
	for child in scene.content.get_children():
		if child is ScrollContainer:
			career_scroll = child
			break
	check(career_scroll != null and career_scroll.scroll_vertical == archive_position, "career restores its last section after leaving and returning in the same session")

	scene.view_mode = "board"
	state.phase = state.Phase.BOARD
	state.player.current_planet_id = ContentDB.PLANET.id
	state.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[1], ContentDB.CONTRACT_APPROACHES[2])
	state.current_bounty.field_test_context = {"tested_approach_name": "Rede Silenciosa", "tested_odds": 0.74, "chosen_approach_name": "Mandado Corporativo", "overridden": true}
	state.player.capture_streak = 4
	state.begin_combat()
	state.combat_summary.rounds = 6
	state.combat_summary.damage_dealt = 84
	state.combat_summary.damage_taken = 83
	state.player_hp = 0
	state.enemy_hp = 12
	state.finish_combat(false)
	await process_frame
	check(scene.find_child("CombatSummaryDefeat", true, false) != null, "board keeps a concise defeat diagnosis before the next contract")
	var defeat_verdict := scene.find_child("CombatReportVerdict", true, false) as Label
	check(defeat_verdict != null and defeat_verdict.text == "×", "defeat report exposes an immediate visual verdict")
	check(scene.find_child("BoardNotice", true, false) == null, "complete defeat diagnosis replaces the redundant escape receipt")
	var defeat_heading := scene.find_child("CombatReportTitle", true, false) as Label
	check(defeat_heading != null and defeat_heading.text.contains("BARÃO BOOM"), "defeat diagnosis retains the escaped target identity after the redundant receipt is removed")
	scene.board_section = "destinations"
	scene.render()
	await process_frame
	var career_action := scene.find_child("BoardCareerAction", true, false) as Button
	check(career_action != null and (state.career_rewards_ready() == 0 or career_action.text.contains("%d PRÊMIOS" % state.career_rewards_ready())), "claimable career rewards remain counted in the destinations view after a defeat")
	scene.board_section = "bounties"
	scene.render()
	await process_frame
	var defeat_route := scene.find_child("DefeatFieldTestDiagnosis", true, false) as Label
	check(defeat_route != null and defeat_route.text.contains("OVERRIDE DERROTADO") and defeat_route.text.contains("REAVALIE A ROTA"), "defeat board turns the tested-route override into actionable diagnosis")
	var defeat_route_text := defeat_route.text if defeat_route != null else ""
	var streak_loss := scene.find_child("DefeatStreakLoss", true, false) as Label
	check(streak_loss != null and streak_loss.text.contains("×4") and streak_loss.text.contains("×1"), "defeat diagnosis explains the streak reset and restart")
	var defeat_workshop := scene.find_child("DefeatWorkshopAction", true, false) as Button
	check(defeat_workshop != null, "defeat diagnosis offers an immediate workshop recovery route")
	defeat_workshop.pressed.emit()
	await process_frame
	check(scene.view_mode == "arsenal", "defeat recovery route opens the field-test workshop")
	var revenge_target := scene.find_child("FieldReadinessTarget", true, false) as Label
	check(revenge_target != null and revenge_target.text.contains("REVANCHE: BARÃO BOOM"), "real defeat state preserves the failed warrant through its persisted combat report")
	var revenge_route := scene.find_child("FieldReadinessRecoveryRoute", true, false) as Label
	check(revenge_route != null and revenge_route.text == defeat_route_text, "revenge workshop carries the exact tested-route defeat diagnosis")

	scene.free()
	await process_frame
	# Let the dummy audio driver release active playback handles before shutdown.
	await create_timer(0.5).timeout
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: all primary UI phases render")
		quit(0)
	else:
		printerr("FAIL: %d UI smoke test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
