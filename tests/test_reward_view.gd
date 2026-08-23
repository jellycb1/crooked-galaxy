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
	check(host.find_child("RewardMasteryProgress", true, false) != null, "isolated reward previews progress from the pending capture")
	check(host.find_child("ClaimAndRepeat", true, false) != null and host.find_child("ClaimAndBoard", true, false) != null, "isolated reward preserves repeat and board decisions")

	clear_content(content)
	state.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[2])
	RewardScript.build(host, content, state)
	var corporate_totals := host.find_child("RewardContractTotals", true, false) as Label
	check(corporate_totals != null and corporate_totals.text.contains("2 sucata"), "isolated reward previews corporate workshop funding")

	clear_content(content)
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
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
	state.pending_loot = reward_item(6)
	state.player.captures_by_target = {"gloop": 2}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	RewardScript.build(host, content, state)
	check(host.find_child("RewardWarrantUnlock", true, false) != null, "isolated reward previews a threshold unlock")
	var warrant_odds := host.find_child("RewardWarrantOdds", true, false) as Label
	check(warrant_odds != null and warrant_odds.text.contains("BARÃO BOOM") == false and warrant_odds.text.contains("%"), "threshold reward previews the best post-loot route and its odds")
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
