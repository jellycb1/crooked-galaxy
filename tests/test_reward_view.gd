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
	state.player.captures_by_target = {"gloop": 2}
	RewardScript.build(host, content, state)
	var mastery_unlock := host.find_child("RewardMasteryUnlock", true, false) as Label
	check(mastery_unlock != null and mastery_unlock.text.contains("+6 SUCATA"), "isolated reward previews the mastery threshold and its workshop funding before claiming")

	clear_content(content)
	state.player.captures_by_target = {}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	RewardScript.build(host, content, state)
	check(host.find_child("RewardWarrantUnlock", true, false) != null, "isolated reward previews a threshold unlock")
	check(host.find_child("ClaimAndRepeat", true, false) == null and host.find_child("ClaimAndUnlock", true, false) != null, "threshold unlock prioritizes the expanded board")

	clear_content(content)
	state.player.captures_by_planet = {}
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
