extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const CareerViewScript = preload("res://scripts/career_view.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.wins = 3
	state.player.captures_by_target = {"gloop": 2, "baron_boom": 1}
	state.player.captures_by_planet = {"dustball_prime": 3}
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	CareerViewScript.build(host, content, state)

	check(host.find_child("CareerSummary", true, false) != null, "isolated career builds its summary")
	check(host.find_child("CareerScroll", true, false) != null, "isolated career builds its archive scroller")
	check(host.find_child("MasteryDirective", true, false) != null, "isolated career turns archive data into a repeat objective")
	check(host.find_child("MasteryDirectiveAction", true, false) != null, "mastery objective links back to its warrant board")
	check(host.find_child("CareerTarget_gloop", true, false) != null, "isolated career preserves wanted records")
	var action := host.find_child("MasteryDirectiveAction", true, false) as Button
	action.pressed.emit()
	check(state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "gloop", "mastery directive opens the recommended target briefing directly")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: isolated career renderer is valid")
		quit(0)
	else:
		printerr("FAIL: %d career renderer test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
