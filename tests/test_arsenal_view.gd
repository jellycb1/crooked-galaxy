extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ArsenalScript = preload("res://scripts/arsenal_view.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.last_notice = "Perícia com alvo 1: +6 sucata"
	state.last_notice_context = "reward_stored"
	state.player.captures_by_target = {"gloop": 1}
	state.player.captures_by_planet = {"dustball_prime": 1}
	state.player.scrap = 20
	state.player.credits = 50000
	state.player.weapon.origin_planet_id = "dustball_prime"
	state.player.armor.origin_planet_id = "dustball_prime"
	state.player.rig = {"id": "rift_rig", "name": "Arnês da Fenda", "slot": "rig", "power": 0, "rarity": "Raro", "color": "#58d9ff", "item_level": 100}
	state.player.inventory = [
		{"id": "view_weapon", "name": "Arma de Vista", "slot": "weapon", "power": 5, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "view_armor", "name": "Armadura de Vista", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9"},
	]
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	ArsenalScript.build(host, content, state)

	check(host.find_child("ArsenalSectionTabs", true, false) != null and host.find_child("ArsenalTab_equipped", true, false) != null and host.find_child("ArsenalTab_workshop", true, false) != null and host.find_child("ArsenalTab_inventory", true, false) != null and host.find_child("ArsenalTab_settings", true, false) == null, "isolated arsenal separates equipped gear, workshop, and backpack")
	var universal_sheet := host.find_child("UniversalEquipmentCard", true, false) as PanelContainer
	check(universal_sheet != null and universal_sheet.get_theme_stylebox("panel") is StyleBoxTexture, "the universal equipment sheet owns Arsenal's single illustrated focal frame")
	check(host.find_child("InventoryScroll", true, false) == null, "equipped section does not compete with the backpack list")
	check(host.find_child("LoadoutToolbar", true, false) is VBoxContainer, "isolated equipped section stacks persistent loadouts at full mobile width")
	host.arsenal_section = "workshop"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	var workshop_notice := host.find_child("WorkshopNotice", true, false) as Label
	check(workshop_notice != null and workshop_notice.text.contains("+6 sucata"), "isolated arsenal preserves the transaction that funded the workshop")
	var readiness_target := host.find_child("FieldReadinessTarget", true, false) as Label
	check(workshop_notice.get_theme_font_size("font_size") >= 18 and readiness_target != null and readiness_target.get_theme_font_size("font_size") >= 18, "workshop receipts and field-test context meet the Android readability floor")
	var workshop_grid := host.find_child("WorkshopSlotGrid", true, false) as GridContainer
	check(workshop_grid != null and workshop_grid.get_child_count() == CoreRules.EQUIPMENT_SLOTS.size(), "workshop exposes the same universal nine-slot equipment contract")
	check(not (host.find_child("WorkshopSlot_weapon", true, false) as Button).disabled and not (host.find_child("WorkshopSlot_rig", true, false) as Button).disabled and (host.find_child("WorkshopSlot_relic", true, false) as Button).disabled, "workbench selector enables equipped slots and disables empty ones")
	check(host.find_child("Upgrade_weapon", true, false) != null and host.find_child("Reinforce_weapon", true, false) != null and host.find_child("Upgrade_armor", true, false) == null, "workshop renders one selected mobile dossier instead of competing upgrade cards")
	check(host.find_child("EquippedWorkbenchIcon_weapon", true, false) != null and host.find_child("EquippedWorkbenchIcon_armor", true, false) == null, "selected workbench item owns the single visual identity")
	var recommended_buttons := host.find_children("*", "Button", true, false).filter(func(button): return str(button.text).begins_with("★"))
	check(recommended_buttons.size() <= 1, "selected workbench marks at most one affordable best-value action")
	var recommendation := ArsenalScript.recommended_workshop_action(state)
	var recommendation_card := host.find_child("WorkshopRecommendation", true, false) as PanelContainer
	var recommendation_action := host.find_child("RecommendedWorkshopAction", true, false) as Button
	check(recommendation_card != null and recommendation_action != null and recommendation_action.text == "APLICAR", "workshop elevates the best-value upgrade into one explicit primary action")
	check(recommendation_action != null and recommendation_action.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION, "workshop recommendation remains readable at the Android target")
	var upgrade_weapon := host.find_child("Upgrade_weapon", true, false) as Button
	var reinforce_weapon := host.find_child("Reinforce_weapon", true, false) as Button
	check(upgrade_weapon != null and reinforce_weapon != null and upgrade_weapon.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION and reinforce_weapon.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION, "dense workshop actions retain the shared caption floor")
	check(recommendation_action != null and UIDesignSystem.is_safe_touch_target(recommendation_action.custom_minimum_size.y) and UIDesignSystem.is_safe_touch_target(upgrade_weapon.custom_minimum_size.y) and UIDesignSystem.is_safe_touch_target(reinforce_weapon.custom_minimum_size.y), "every workshop transaction remains a safe physical Android touch target")
	check(upgrade_weapon.text.contains("◈") and upgrade_weapon.text.contains("SUC") and reinforce_weapon.text.contains("◈"), "workshop actions expose both currencies before confirmation")
	check(not recommendation.is_empty() and int(recommendation.cost) <= int(state.player.scrap) and int(recommendation.credit_cost) <= int(state.player.credits) and recommendation.has("current_odds") and recommendation.has("score_gain"), "workshop recommendation carries an affordable, auditable dual-cost projection")
	check(ArsenalScript.workshop_projection_candidates(state).any(func(candidate): return str(candidate.slot) == "rig"), "workshop projections include non-weapon and non-armor equipment")
	host.workshop_slot = "rig"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	check(host.find_child("Upgrade_rig", true, false) != null and host.find_child("Reinforce_rig", true, false) != null and host.find_child("EquippedWorkbenchIcon_rig", true, false) != null, "a Rift rig receives the complete universal workshop service")
	check((host.find_child("Upgrade_rig", true, false) as Button).text.contains("◈ 10020"), "advanced Rift item preserves its level-scaled first calibration price")
	host.workshop_slot = "weapon"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	check(host.find_child("FieldReadiness", true, false) != null, "isolated arsenal translates upgrades into next-warrant odds")
	var readiness := ArsenalScript.field_readiness(state)
	check(str(readiness.target.id) == "baron_boom", "field test selects the next planet-tier target")
	check(str(readiness.approach.id) == "quiet_net" and str(readiness.contract.approach.id) == "quiet_net", "field test uses the same viable approach recommendation as the briefing")
	check(float(readiness.current_odds) == CoreRules.bounty_odds(state.player, readiness.contract), "field test odds use the applied contract rather than the canonical target")
	check(float(readiness.power_odds) >= float(readiness.current_odds) and float(readiness.health_odds) >= float(readiness.current_odds), "field test projections are monotonic for real upgrades")
	var player_before_warmup := JSON.stringify(state.player)
	CoreRules.clear_bounty_odds_cache()
	var warmup_complete := false
	var warmup_steps := ContentDB.contract_approaches().size() + 2 + ArsenalScript.workshop_projection_candidates(state).size()
	for step in warmup_steps:
		warmup_complete = ArsenalScript.warm_field_readiness_step(state, step)
		check(warmup_complete == (step == warmup_steps - 1), "field readiness warmup completes only after its final bounded estimate")
	var warmed_estimate_count := CoreRules.bounty_odds_cache.size()
	ArsenalScript.field_readiness(state)
	check(warmed_estimate_count > 0 and CoreRules.bounty_odds_cache.size() == warmed_estimate_count, "incremental field warmup covers every estimate used by the first Arsenal visit")
	check(JSON.stringify(state.player) == player_before_warmup, "incremental field warmup never mutates player state")
	state.player.captures_by_target = {"gloop": 3}
	state.player.captures_by_planet = {"dustball_prime": 3}
	var unlocked_readiness := ArsenalScript.field_readiness(state)
	check(str(unlocked_readiness.target.id) == "baron_boom" and bool(unlocked_readiness.target_available), "field test keeps a newly unlocked uncaptured warrant in focus")
	clear_children(content)
	ArsenalScript.build(host, content, state)
	var unlocked_target_label := host.find_child("FieldReadinessTarget", true, false) as Label
	check(unlocked_target_label != null and unlocked_target_label.text.contains("MANDADO ATUAL: BARÃO BOOM"), "field test explains that the newly unlocked warrant is currently actionable")
	var readiness_approach := host.find_child("FieldReadinessApproach", true, false) as Label
	check(readiness_approach != null and readiness_approach.text.contains("REDE SILENCIOSA"), "field test names the fixed approach behind its projections")
	var field_action := host.find_child("FieldReadinessAction", true, false) as Button
	check(field_action != null and field_action.text == "ESCOLHER ROTA", "field test truthfully links an available warrant to route selection")
	state.player.captures_by_target.baron_boom = 1
	state.player.captures_by_planet.dustball_prime = 4
	check(str(ArsenalScript.field_readiness(state).target.id) == "baron_boom", "mastery captures do not silently reroll the immutable board cycle")
	state.current_bounty = {}
	state.combat_summary = {
		"won": false,
		"enemy_hp_remaining": 12,
		"target_id": "baron_boom",
		"field_test_context": {"tested_approach_name": "Rede Silenciosa", "tested_odds": 0.74, "chosen_approach_name": "Mandado Corporativo", "overridden": true},
	}
	var recovery_readiness := ArsenalScript.field_readiness(state)
	check(str(recovery_readiness.target.id) == "baron_boom" and bool(recovery_readiness.recovery_focus), "field test keeps the defeated warrant in focus instead of projecting a locked tier")
	var power_before_recovery_upgrade := int(state.player.weapon.power)
	var credits_before_recovery_upgrade := int(state.player.credits)
	var recovery_service_cost := CoreRules.equipment_upgrade_credit_cost(state.player.weapon)
	check(state.upgrade_equipped("weapon") and int(state.player.weapon.power) == power_before_recovery_upgrade + 1, "recovery workshop accepts a real upgrade transaction")
	check(int(state.player.credits) == credits_before_recovery_upgrade - recovery_service_cost, "recovery workshop records the Credit service expense")
	var recovery_after_upgrade := ArsenalScript.field_readiness(state)
	check(str(recovery_after_upgrade.target.id) == "baron_boom", "upgrade transaction preserves revenge focus")
	clear_children(content)
	ArsenalScript.build(host, content, state)
	var recovery_notice := host.find_child("WorkshopNotice", true, false) as Label
	var recovery_label := host.find_child("FieldReadinessTarget", true, false) as Label
	var recovery_route := host.find_child("FieldReadinessRecoveryRoute", true, false) as Label
	check(recovery_notice != null and recovery_notice.text.contains("calibrado") and recovery_label != null and recovery_label.text.contains("REVANCHE: BARÃO BOOM"), "workshop shows the upgrade record beside the preserved revenge projection")
	check(recovery_route != null and recovery_route.text.contains("OVERRIDE DERROTADO") and recovery_route.text.contains("REAVALIE A ROTA"), "recovery workshop retains the defeated tested-route override diagnosis")
	field_action = host.find_child("FieldReadinessAction", true, false) as Button
	state.combat_summary = {}
	state.player.captures_by_target.erase("baron_boom")
	state.player.captures_by_planet.dustball_prime = 3
	field_action.pressed.emit()
	check(state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "baron_boom", "field-test action opens the focused warrant briefing")
	check(str(host.briefing_context.approach_id) == str(recovery_after_upgrade.approach.id), "field-test handoff carries its tested recommendation into the briefing host")
	var briefing_evaluations := ContractRules.evaluate_approaches(state.player, state.current_bounty, state.offered_approaches)
	check(ContractRules.recommended_approach_id(briefing_evaluations) == str(recovery_after_upgrade.approach.id), "briefing preserves the same recommended approach shown by the field test")
	var late_state = StateScript.new()
	late_state.persistence_enabled = false
	late_state.player = late_state.default_player()
	late_state.player.current_planet_id = "ferro_velho_omega"
	late_state.player.level = 20
	late_state.player.base_power = 48
	late_state.player.class_id = "orbit_gunslinger"
	late_state.player.attributes = {"strength": 10, "vitality": 20, "dexterity": 30, "intelligence": 10, "cunning": 20}
	late_state.player.weapon = {"id": "late_weapon", "name": "Prensa Portátil", "slot": "weapon", "power": 60, "origin_planet_id": "ferro_velho_omega", "integrity_upgrades": 3, "trait": {"power_bonus": 2}}
	late_state.player.armor = {"id": "late_armor", "name": "Chassi Executivo", "slot": "armor", "power": 52, "origin_planet_id": "ferro_velho_omega", "integrity_upgrades": 3, "trait": {"power_bonus": 1, "health_bonus": 8}}
	late_state.player.captures_by_target = {"bolt_collector": 3, "doctor_patchwork": 3, "crane_king": 3}
	late_state.player.captures_by_planet = {"ferro_velho_omega": 9}
	var late_readiness := ArsenalScript.field_readiness(late_state)
	check(bool(late_readiness.target.get("mission_offer", false)) and int(late_readiness.target.mission_level) == 20 and str(late_readiness.target.mission_role) == "standard", "late field test focuses the board's fixed level-banded standard contract")
	var late_base_odds := CoreRules.bounty_odds(late_state.player, late_readiness.target)
	check(float(late_readiness.current_odds) <= late_base_odds and float(late_readiness.current_odds) == CoreRules.bounty_odds(late_state.player, late_readiness.contract), "late projection preserves the selected approach's exact risk without scaling from equipped power")
	late_state.free()
	host.arsenal_section = "equipped"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	var kit_status := host.find_child("PlanetaryKitStatus", true, false) as Label
	check(kit_status != null and kit_status.text.contains("DUSTBALL PRIME") and kit_status.text.contains("+1 PODER") and kit_status.text.contains("+6 VIDA"), "arsenal exposes the active planetary kit")
	check(kit_status.get_theme_font_size("font_size") >= 18, "equipped-kit status remains readable on the physical Android target")
	check(ArsenalScript.filtered_inventory(host, state).size() == 2, "renderer receives inventory through explicit state")
	host.inventory_filter = "weapon"
	check(ArsenalScript.filtered_inventory(host, state).size() == 1, "renderer preserves host filter state")
	host.inventory_filter = "all"
	state.player.inventory.clear()
	for index in 30:
		state.player.inventory.append({"id": "page_%02d" % index, "name": "Peça %02d" % index, "slot": "weapon" if index % 2 == 0 else "armor", "power": index + 1, "rarity": "Comum", "color": "#b9c2d9"})
	host.inventory_page = 0
	var first_page := ArsenalScript.paginated_inventory(host, state)
	check(first_page.items.size() == ArsenalScript.INVENTORY_PAGE_SIZE and int(first_page.page_count) == 3, "inventory pagination bounds the rendered card window")
	host.inventory_page = 2
	var last_page := ArsenalScript.paginated_inventory(host, state)
	check(last_page.items.size() == 6 and int(last_page.page) == 2, "final inventory page keeps the exact remainder")
	host.inventory_page = 99
	check(int(ArsenalScript.paginated_inventory(host, state).page) == 2, "inventory page clamps after filtering, recycling, or stale navigation")
	host.arsenal_section = "inventory"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	check(host.find_child("EquipmentCollectionProgress", true, false) != null, "backpack exposes permanent procedural-series collection progress")
	check(host.find_child("InventoryScroll", true, false) != null and host.find_child("Upgrade_weapon", true, false) == null, "backpack section reserves the screen for item management")
	check(host.find_children("InventoryItem_*", "PanelContainer", true, false).size() == 6, "arsenal builds only the active page's item cards")
	var previous_page := host.find_child("InventoryPagePrevious", true, false) as Button
	var next_page := host.find_child("InventoryPageNext", true, false) as Button
	check(previous_page != null and not previous_page.disabled and next_page != null and next_page.disabled, "pager exposes correct boundary actions on the last page")
	var arsenal_tabs := host.find_child("ArsenalSectionTabs", true, false) as HBoxContainer
	check(arsenal_tabs != null and arsenal_tabs.get_child_count() == 4, "arsenal navigation separates equipped gear, workshop, backpack, and series")
	check(host.find_child("ArsenalTab_settings", true, false) == null and host.find_child("AccessibilityPreferences", true, false) == null, "device settings no longer leak into equipment management")
	host.arsenal_section = "collection"
	clear_children(content)
	var first_collection_id := str(ContentDB.procedural_collection_ids()[0])
	state.player.discovered_item_variant_ids = [first_collection_id]
	ArsenalScript.build(host, content, state)
	check(host.find_child("CollectionScroll", true, false) != null and host.find_child("EquipmentCollectionOverview", true, false) != null, "series tab opens a dedicated scrollable permanent catalog")
	check(host.find_child("CollectionMilestones", true, false) != null and host.find_child("ClaimAllCollectionMilestones", true, false) != null, "series catalog exposes earned lifetime rewards without hiding the claim action")
	check(host.find_children("CollectionMilestone_*", "HBoxContainer", true, false).size() == 1, "series catalog keeps only the next actionable milestone in the mobile layout")
	var first_planet_family_count := ContentDB.procedural_collection_entries().filter(func(entry): return str(entry.planet_id) == str(ContentDB.PLANETS[0].id)).size()
	check(host.find_children("CollectionPlanet_*", "PanelContainer", true, false).size() == 1 and host.find_child("CollectionPlanetNavigation", true, false) != null, "series catalog renders one navigable planet at a time for mobile performance")
	check(host.find_children("CollectionFamily_*", "VBoxContainer", true, false).size() == first_planet_family_count, "series catalog exposes every discovered and missing family from the active planet")
	state.last_notice = "Rota confirmada: Congelária S.A."
	state.last_notice_context = "travel"
	host.arsenal_section = "equipped"
	clear_children(content)
	ArsenalScript.build(host, content, state)
	check(host.find_child("WorkshopNotice", true, false) == null, "arsenal ignores receipts owned by unrelated hubs")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: isolated arsenal renderer is valid")
		quit(0)
	else:
		printerr("FAIL: %d arsenal renderer test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()
