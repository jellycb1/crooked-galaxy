extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const RewardScript = preload("res://scripts/reward_view.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = reward_item(6)
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)

	RewardScript.build(host, content, state)
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
	state.player.captures_by_target = {"gloop": 1}
	RewardScript.build(host, content, state)
	var second_capture_mastery := host.find_child("RewardMasteryProgress", true, false) as Label
	check(second_capture_mastery != null and second_capture_mastery.text.contains("2/3"), "second capture introduces mastery through progress toward its imminent outcome")
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
	check(corporate_totals != null and corporate_totals.text.contains("2 sucata"), "isolated reward previews corporate workshop funding")
	check(host.find_child("RewardStreakBonus", true, false) != null, "continued reward distinguishes an active streak bonus from its ×1 baseline")

	clear_content(content)
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.player.capture_streak = 0
	state.player.captures_by_target = {"gloop": 2}
	RewardScript.build(host, content, state)
	var mastery_unlock := host.find_child("RewardMasteryUnlock", true, false) as Label
	var mastery_bonus := host.find_child("RewardMasteryUnlockBonus", true, false) as Label
	check(mastery_unlock != null and mastery_bonus != null and mastery_bonus.text.contains("OFICINA +6 SUCATA"), "isolated reward previews the mastery threshold and its workshop funding before claiming")
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
	check(host.find_child("ClaimAndRepeat", true, false) == null and host.find_child("ClaimAndUnlock", true, false) != null, "threshold unlock prioritizes the expanded board")

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


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
