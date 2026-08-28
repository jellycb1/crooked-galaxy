extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const RewardScript = preload("res://scripts/reward_view.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = reward_item(6)
	state.pending_loot.template_id = "dustball_prime_weapon_00"
	state.pending_loot.variant_id = "standard"
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)

	RewardScript.build(host, content, state)
	var reward_scroll := host.find_child("RewardScroll", true, false) as ScrollContainer
	check(reward_scroll != null and reward_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "reward evidence scrolls independently while decisions remain fixed")
	var reward_panel := host.find_child("RewardPanel", true, false) as PanelContainer
	check(reward_panel != null and reward_panel.get_theme_stylebox("panel") is StyleBoxTexture, "isolated reward renderer uses the approved illustrated loot dossier")
	check(host.find_child("RewardLootHeader", true, false) != null and host.find_child("RewardEquipmentComparison", true, false) != null, "isolated reward separates loot identity from equipment comparison")
	var collection_status := host.find_child("RewardCollectionStatus", true, false) as Label
	check(collection_status != null and collection_status.text.contains("NOVA SÉRIE"), "reward decision previews permanent collection progress before equip, store, or recycle")
	check(host.find_child("RewardContractReceipt", true, false) != null and host.find_child("RewardProgressPanel", true, false) != null, "isolated reward groups the contract receipt and progression evidence")
	check(host.find_child("RewardProgressIcon_streak", true, false) != null and host.find_child("RewardProgressIcon_warrant", true, false) != null, "progress receipt gives streak and warrant distinct visual identities")
	var daily_progress := host.find_child("RewardDailyProgress", true, false) as Label
	check(host.find_child("RewardProgressIcon_daily", true, false) != null and daily_progress != null and daily_progress.text.contains("1/5") and daily_progress.text.contains("PAGAMENTO"), "reward preview teaches the first daily payment before claiming the hunt")
	check(host.find_child("RewardNewPower", true, false) != null and host.find_child("RewardEquippedPower", true, false) != null and host.find_child("RewardEquipmentResult", true, false) != null, "equipment decision exposes new, equipped, and result metrics in one row")
	check(host.find_child("RewardWarrantProgress", true, false) != null, "isolated reward renders next-warrant progress")
	var next_hunt_impact := host.find_child("RewardNextHuntImpact", true, false) as Label
	check(next_hunt_impact != null and next_hunt_impact.text.contains("IMPACTO AO EQUIPAR") and next_hunt_impact.text.contains("→"), "ordinary reward translates its upgrade into next-hunt odds")
	var streak_start := host.find_child("RewardStreakStart", true, false) as Label
	check(streak_start != null and streak_start.text.contains("×1") and streak_start.text.contains("PRÓXIMA CAPTURA"), "first reward explains streak restart and when its bonus begins")
	check(host.find_child("RewardMasteryProgress", true, false) == null, "first reward defers mastery vocabulary while warrant progression teaches the immediate repeat goal")
	var repeat_value := host.find_child("RewardRepeatValue", true, false) as Label
	check(repeat_value != null and repeat_value.text.contains("EMBALO ×2") and repeat_value.text.contains("+5% SOBRE O PAGAMENTO") and not repeat_value.text.contains("CRÉDITOS"), "regular reward promises only the approach-invariant next streak value")
	check(host.find_child("ClaimAndRepeat", true, false) != null and host.find_child("ClaimAndBoard", true, false) != null, "isolated reward preserves repeat and board decisions")

	clear_content(content)
	state.current_bounty = MissionRules.offer_for_target(state.player, ContentDB.TARGETS[0])
	state.player.captures_by_target = {"gloop": 2}
	RewardScript.build(host, content, state)
	check(host.find_child("RewardNetworkRefresh", true, false) != null, "network reward previews the refreshed three-offer board")
	check(host.find_child("RewardWarrantProgress", true, false) == null and host.find_child("RewardWarrantUnlock", true, false) == null, "network reward never resurrects sequential warrant progress")
	check(host.find_child("ClaimAndRepeat", true, false) != null, "network reward preserves exact-contract repetition for mastery")
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)

	clear_content(content)
	state.phase = state.Phase.REWARD
	state.player.level = 3
	state.player.xp = CoreRules.xp_needed(3) - 1
	state.player.seen_planet_ids = ["dustball_prime"]
	state.player.captures_by_target = {}
	state.current_bounty = MissionRules.offer_for_target(state.player, ContentDB.TARGETS[0])
	state.current_bounty.xp = 1
	state.pending_loot = reward_item(7)
	RewardScript.build(host, content, state)
	var planet_unlock := host.find_child("RewardPlanetUnlock", true, false) as Label
	var planet_action := host.find_child("ClaimAndPlanet", true, false) as Button
	check(planet_unlock != null and planet_unlock.text.contains("CONGELÁRIA S.A."), "level-band reward names the destination before the player commits XP")
	check(host.find_child("ClaimAndRepeat", true, false) == null and planet_action != null, "new destination replaces habitual repetition with one clear discovery action")
	planet_action.pressed.emit()
	check(host.view_mode == "galaxy" and int(state.player.level) == 4 and state.unseen_planets().size() == 1, "claim routes to the Galaxy while retaining the unseen discovery across the reward transaction")
	check(state.acknowledge_planet("congelaria_sa") and state.unseen_planets().is_empty(), "explicit Galaxy acknowledgement consumes the persistent discovery receipt")
	state.player.level = 1
	state.player.xp = 0
	state.player.seen_planet_ids = ["dustball_prime"]
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = reward_item(6)

	clear_content(content)
	state.player.captures_by_target = {"gloop": 1}
	RewardScript.build(host, content, state)
	var second_capture_mastery := host.find_child("RewardMasteryProgress", true, false) as Label
	check(second_capture_mastery != null and second_capture_mastery.text.contains("PRÓXIMA CAPTURA") and second_capture_mastery.text.contains("PERÍCIA 1/3") and second_capture_mastery.text.contains("BARÃO BOOM"), "second capture unifies its imminent mastery and warrant outcomes")
	check(host.find_child("RewardWarrantProgress", true, false) == null, "combined second-capture promise replaces the duplicate warrant progress line")
	state.player.captures_by_target = {}

	clear_content(content)
	state.current_bounty = ContentDB.apply_hunt_choice(ContentDB.TARGETS[0], ContentDB.HUNT_EVENTS[0].choices[0])
	RewardScript.build(host, content, state)
	var incident_net := host.find_child("RewardIncidentNet", true, false) as Label
	check(incident_net != null and incident_net.text.contains("-8 CRÉDITOS") and incident_net.text.contains("SALDO DO CONTRATO"), "paid incident reward reconciles gross payout with its already charged cost")

	clear_content(content)
	state.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[2])
	state.player.capture_streak = 1
	RewardScript.build(host, content, state)
	var corporate_totals := host.find_child("RewardContractTotals", true, false) as Label
	check(corporate_totals != null and corporate_totals.text.contains("3 sucata"), "isolated reward previews corporate workshop funding")
	check(host.find_child("RewardStreakBonus", true, false) != null, "continued reward distinguishes an active streak bonus from its ×1 baseline")

	clear_content(content)
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.player.capture_streak = 0
	state.player.captures_by_target = {"gloop": 2}
	RewardScript.build(host, content, state)
	var mastery_unlock := host.find_child("RewardMasteryUnlock", true, false) as Label
	var mastery_bonus := host.find_child("RewardMasteryUnlockBonus", true, false) as Label
	check(mastery_unlock != null and mastery_bonus != null and mastery_bonus.text.contains("OFICINA +6 SUCATA"), "isolated reward previews the mastery threshold and its workshop funding before claiming")
	check(host.find_child("RewardProgressIcon_mastery", true, false) != null, "mastery threshold uses its own target marker")
	var workshop_action := host.find_child("ClaimAndWorkshop", true, false) as Button
	check(workshop_action != null, "mastery threshold offers a direct workshop route")
	workshop_action.pressed.emit()
	check(state.phase == state.Phase.BOARD and host.view_mode == "arsenal" and int(state.player.scrap) == 6, "workshop route claims the reward and carries mastery funding into the arsenal")

	clear_content(content)
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = reward_item(12)
	state.player.captures_by_target = {"gloop": 2}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	RewardScript.build(host, content, state)
	check(host.find_child("RewardWarrantUnlock", true, false) != null, "isolated reward previews a threshold unlock")
	check(host.find_child("RewardRepeatValue", true, false) == null, "new-warrant threshold does not distract with obsolete repeat value")
	var warrant_odds := host.find_child("RewardWarrantOdds", true, false) as Label
	check(warrant_odds != null and warrant_odds.text.contains("APÓS RECEBER + EQUIPAR") and warrant_odds.text.contains("→"), "threshold reward includes its pending level gain in the same-route comparison")
	var unlock_action := host.find_child("ClaimAndUnlock", true, false) as Button
	var unlock_style := unlock_action.get_theme_stylebox("normal") as StyleBoxFlat if unlock_action != null else null
	check(host.find_child("ClaimAndRepeat", true, false) == null and unlock_action != null and unlock_style != null and unlock_style.bg_color.a > 0.9, "threshold unlock gives the expanded-board destination the solid primary action")

	clear_content(content)
	state.player.captures_by_target = {"gloop": 2}
	RewardScript.build(host, content, state)
	var combined_workshop := host.find_child("ClaimAndWorkshop", true, false) as Button
	check(combined_workshop != null and combined_workshop.text.contains("PREPARAR NOVO MANDADO"), "combined mastery and warrant threshold can spend its funding before the new contract")

	clear_content(content)
	state.player.captures_by_planet = {}
	state.player.captures_by_target = {}
	state.pending_loot = reward_item(0)
	RewardScript.build(host, content, state)
	check(host.find_child("RecycleAndRepeat", true, false) != null, "isolated reward exposes safe instant recycling")
	var weak_loot_impact := host.find_child("RewardNextHuntImpact", true, false) as Label
	check(weak_loot_impact != null and weak_loot_impact.text.contains("RECEBER SEM EQUIPAR") and weak_loot_impact.text.contains("→"), "non-upgrade loot attributes a projected gain to pending XP instead of the unequipped item")

	clear_content(content)
	state.pending_loot = reward_item(2)
	state.pending_loot.slot = "boots"
	state.player.boots = {}
	RewardScript.build(host, content, state)
	var empty_slot_power := metric_value(host, "RewardEquippedPower")
	var empty_slot_result := metric_value(host, "RewardEquipmentResult")
	check(empty_slot_power == "+0" and empty_slot_result == "UPGRADE", "first secondary-slot drop compares safely against an empty universal equipment slot")

	clear_content(content)
	state.current_bounty = {"id": "rift_test", "challenge": true, "challenge_index": 0, "credits": 118, "xp": 145}
	state.pending_loot = reward_item(4)
	RewardScript.build(host, content, state)
	var challenge_scroll := host.find_child("ChallengeRewardScroll", true, false) as ScrollContainer
	check(challenge_scroll != null and challenge_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Rift artifact evidence uses the same readable scrolling structure")
	check(host.find_child("ChallengeRewardPanel", true, false) != null and host.find_child("ClaimChallengeReward", true, false) != null, "Rift artifact keeps its dossier and fixed return decision")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: isolated reward renderer is valid")
		quit(0)
	else:
		printerr("FAIL: %d reward renderer test(s) failed" % failures)
		quit(1)


func reward_item(power: int) -> Dictionary:
	return {
		"id": "reward_view_item_%d" % power,
		"name": "Peça de Recompensa",
		"description": "Existe para testar decisões sem uma caçada inteira.",
		"slot": "weapon",
		"origin_planet_id": "dustball_prime",
		"power": power,
		"rarity": "Comum",
		"color": "#b9c2d9",
	}


func clear_content(content: VBoxContainer) -> void:
	for child in content.get_children():
		child.free()


func metric_value(host: Node, node_name: String) -> String:
	var chip := host.find_child(node_name, true, false) as PanelContainer
	if chip == null or chip.get_child_count() == 0:
		return ""
	var box := chip.get_child(0) as VBoxContainer
	if box == null or box.get_child_count() < 2:
		return ""
	return str((box.get_child(1) as Label).text)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
