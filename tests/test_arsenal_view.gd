extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ArsenalScript = preload("res://scripts/arsenal_view.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")

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
	state.player.weapon.origin_planet_id = "dustball_prime"
	state.player.armor.origin_planet_id = "dustball_prime"
	state.player.inventory = [
		{"id": "view_weapon", "name": "Arma de Vista", "slot": "weapon", "power": 5, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "view_armor", "name": "Armadura de Vista", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9"},
	]
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	ArsenalScript.build(host, content, state)

	check(host.find_child("ArsenalSectionTabs", true, false) != null and host.find_child("ArsenalTab_equipped", true, false) != null and host.find_child("ArsenalTab_inventory", true, false) != null, "isolated arsenal exposes explicit equipped and backpack sections")
	check(host.find_child("InventoryScroll", true, false) == null, "equipped section does not compete with the backpack list")
	var workshop_notice := host.find_child("WorkshopNotice", true, false) as Label
	check(workshop_notice != null and workshop_notice.text.contains("+6 sucata"), "isolated arsenal preserves the transaction that funded the workshop")
	check(host.find_child("Upgrade_weapon", true, false) != null and host.find_child("Reinforce_armor", true, false) != null, "isolated arsenal builds both workshop paths")
	var recommended_buttons := host.find_children("*", "Button", true, false).filter(func(button): return str(button.text).begins_with("★"))
	check(recommended_buttons.size() == 1, "workshop marks exactly one affordable best-value action")
	var recommendation := ArsenalScript.recommended_workshop_action(state)
	var recommendation_card := host.find_child("WorkshopRecommendation", true, false) as PanelContainer
	var recommendation_action := host.find_child("RecommendedWorkshopAction", true, false) as Button
	check(recommendation_card != null and recommendation_action != null and recommendation_action.text == "APLICAR", "workshop elevates the best-value upgrade into one explicit primary action")
	check(not recommendation.is_empty() and int(recommendation.cost) <= int(state.player.scrap) and recommendation.has("current_odds") and recommendation.has("score_gain"), "workshop recommendation carries an affordable, auditable impact projection")
	check(host.find_child("LoadoutToolbar", true, false) != null, "isolated arsenal builds persistent loadouts")
	check(host.find_child("FieldReadiness", true, false) != null, "isolated arsenal translates upgrades into next-warrant odds")
	var readiness := ArsenalScript.field_readiness(state)
	check(str(readiness.target.id) == "baron_boom", "field test selects the next planet-tier target")
	check(str(readiness.approach.id) == "quiet_net" and str(readiness.contract.approach.id) == "quiet_net", "field test uses the same viable approach recommendation as the briefing")
	check(float(readiness.current_odds) == CoreRules.bounty_odds(state.player, readiness.contract), "field test odds use the applied contract rather than the canonical target")
	check(float(readiness.power_odds) >= float(readiness.current_odds) and float(readiness.health_odds) >= float(readiness.current_odds), "field test projections are monotonic for real upgrades")
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
	check(str(ArsenalScript.field_readiness(state).target.id) == "madame_vacuum", "field test advances after the new warrant's first capture")
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
	check(state.upgrade_equipped("weapon") and int(state.player.weapon.power) == power_before_recovery_upgrade + 1, "recovery workshop accepts a real upgrade transaction")
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
	check(str(late_readiness.target.id) == "omega_junkyard" and str(late_readiness.approach.id) == "hot_hatch", "boss-ready field test focuses the viable fast contract instead of a saturated base target")
	var late_base_odds := CoreRules.bounty_odds(late_state.player, late_readiness.target)
	check(float(late_readiness.current_odds) < late_base_odds, "boss-ready projection preserves the recommended approach's real combat risk (route %d%% / base %d%%)" % [roundi(float(late_readiness.current_odds) * 100.0), roundi(late_base_odds * 100.0)])
	late_state.free()
	var kit_status := host.find_child("PlanetaryKitStatus", true, false) as Label
	check(kit_status != null and kit_status.text.contains("DUSTBALL PRIME") and kit_status.text.contains("+1 PODER") and kit_status.text.contains("+6 VIDA"), "arsenal exposes the active planetary kit")
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
	check(host.find_child("InventoryScroll", true, false) != null and host.find_child("Upgrade_weapon", true, false) == null, "backpack section reserves the screen for item management")
	check(host.find_children("InventoryItem_*", "PanelContainer", true, false).size() == 6, "arsenal builds only the active page's item cards")
	var previous_page := host.find_child("InventoryPagePrevious", true, false) as Button
	var next_page := host.find_child("InventoryPageNext", true, false) as Button
	check(previous_page != null and not previous_page.disabled and next_page != null and next_page.disabled, "pager exposes correct boundary actions on the last page")
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
