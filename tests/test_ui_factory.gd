extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")

var failures := 0


func _init() -> void:
	var factory = FactoryScript.new()
	root.add_child(factory)
	var title := factory.label("TESTE", 18, factory.CYAN)
	check(title.text == "TESTE" and title.get_theme_font_size("font_size") == 18, "factory builds themed labels")
	var button := factory.action_button("AÇÃO", factory.GOLD)
	check(button.custom_minimum_size.y >= 48.0, "factory buttons preserve mobile touch height")
	var outlined := factory.action_button("VOLTAR", factory.CYAN, true)
	check(outlined.get_theme_stylebox("normal") is StyleBoxFlat, "factory builds outlined button styles")
	var portrait := factory.character_portrait("hunter", 80)
	check(portrait.custom_minimum_size == Vector2(80, 80), "factory builds consistently sized portraits")
	var equipment := factory.equipment_chip({"name": "Arma Teste", "slot": "weapon", "power": 5, "integrity_upgrades": 2})
	check(equipment is PanelContainer and equipment.get_child_count() == 1, "factory builds reinforced equipment chips")
	var card := factory.panel(VBoxContainer.new(), factory.PANEL, 12, 10)
	check(card.get_theme_stylebox("panel") is StyleBoxFlat, "factory panels retain reusable styling")
	factory.view_mode = "career"
	factory.inventory_filter = "armor"
	factory.inventory_sort = "rarity"
	factory.inventory_page = 3
	factory.arsenal_section = "inventory"
	factory.briefing_context = {"target_id": "gloop"}
	factory.career_section = "archive"
	factory.career_scroll_position = 900
	factory.career_section_switch_pending = true
	factory.reset_transient_navigation()
	check(factory.view_mode == "board" and factory.inventory_filter == "all" and factory.inventory_sort == "power" and factory.inventory_page == 0 and factory.arsenal_section == "equipped" and factory.board_section == "bounties", "factory reset restores default hub navigation")
	check(factory.briefing_context.is_empty() and factory.career_section == "progress" and factory.career_scroll_position == 0 and not factory.career_section_switch_pending, "factory reset clears stale briefing and career positions")

	for control in [title, button, outlined, portrait, equipment, card]:
		control.free()
	factory.free()
	if failures == 0:
		print("PASS: reusable UI factory is valid")
		quit(0)
	else:
		printerr("FAIL: %d UI factory test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
