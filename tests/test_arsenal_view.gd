extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ArsenalScript = preload("res://scripts/arsenal_view.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.scrap = 20
	state.player.inventory = [
		{"id": "view_weapon", "name": "Arma de Vista", "slot": "weapon", "power": 5, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "view_armor", "name": "Armadura de Vista", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9"},
	]
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	ArsenalScript.build(host, content, state)

	check(host.find_child("InventoryScroll", true, false) != null, "isolated arsenal builds its inventory scroller")
	check(host.find_child("Upgrade_weapon", true, false) != null and host.find_child("Reinforce_armor", true, false) != null, "isolated arsenal builds both workshop paths")
	check(host.find_child("LoadoutToolbar", true, false) != null, "isolated arsenal builds persistent loadouts")
	check(ArsenalScript.filtered_inventory(host, state).size() == 2, "renderer receives inventory through explicit state")
	host.inventory_filter = "weapon"
	check(ArsenalScript.filtered_inventory(host, state).size() == 1, "renderer preserves host filter state")

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
