extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ArsenalScript = preload("res://scripts/arsenal_view.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.last_notice = "Perícia com alvo 1: +6 sucata"
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

	check(host.find_child("InventoryScroll", true, false) != null, "isolated arsenal builds its inventory scroller")
	var workshop_notice := host.find_child("WorkshopNotice", true, false) as Label
	check(workshop_notice != null and workshop_notice.text.contains("+6 sucata"), "isolated arsenal preserves the transaction that funded the workshop")
	check(host.find_child("Upgrade_weapon", true, false) != null and host.find_child("Reinforce_armor", true, false) != null, "isolated arsenal builds both workshop paths")
	var recommended_buttons := host.find_children("*", "Button", true, false).filter(func(button): return str(button.text).begins_with("★"))
	check(recommended_buttons.size() == 1, "workshop marks exactly one affordable best-value action")
	check(host.find_child("LoadoutToolbar", true, false) != null, "isolated arsenal builds persistent loadouts")
	check(host.find_child("FieldReadiness", true, false) != null, "isolated arsenal translates upgrades into next-warrant odds")
	var readiness := ArsenalScript.field_readiness(state)
	check(str(readiness.target.id) == "baron_boom", "field test selects the next planet-tier target")
	check(float(readiness.power_odds) >= float(readiness.current_odds) and float(readiness.health_odds) >= float(readiness.current_odds), "field test projections are monotonic for real upgrades")
	state.player.captures_by_target = {"gloop": 3}
	state.player.captures_by_planet = {"dustball_prime": 3}
	var unlocked_readiness := ArsenalScript.field_readiness(state)
	check(str(unlocked_readiness.target.id) == "baron_boom" and bool(unlocked_readiness.target_available), "field test keeps a newly unlocked uncaptured warrant in focus")
	clear_children(content)
	ArsenalScript.build(host, content, state)
	var unlocked_target_label := host.find_child("FieldReadinessTarget", true, false) as Label
	check(unlocked_target_label != null and unlocked_target_label.text.contains("MANDADO ATUAL: BARÃO BOOM"), "field test explains that the newly unlocked warrant is currently actionable")
	var field_action := host.find_child("FieldReadinessAction", true, false) as Button
	check(field_action != null and field_action.text == "CAÇAR AGORA", "field test links an available uncaptured warrant directly")
	state.player.captures_by_target.baron_boom = 1
	state.player.captures_by_planet.dustball_prime = 4
	check(str(ArsenalScript.field_readiness(state).target.id) == "madame_vacuum", "field test advances after the new warrant's first capture")
	state.player.captures_by_target.erase("baron_boom")
	state.player.captures_by_planet.dustball_prime = 3
	field_action.pressed.emit()
	check(state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "baron_boom", "field-test action opens the focused warrant briefing")
	var kit_status := host.find_child("PlanetaryKitStatus", true, false) as Label
	check(kit_status != null and kit_status.text.contains("DUSTBALL PRIME") and kit_status.text.contains("+1 PODER") and kit_status.text.contains("+6 VIDA"), "arsenal exposes the active planetary kit")
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


func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()
