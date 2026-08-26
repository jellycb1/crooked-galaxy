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
	var illustrated_class := factory.class_illustration("orbit_gunslinger", 140)
	check(illustrated_class != null and illustrated_class.texture is AtlasTexture and illustrated_class.custom_minimum_size == Vector2(119, 140), "factory resolves a readable upper-body crop from the illustrated class slice")
	for class_id in ["warrant_breaker", "orbit_gunslinger", "contract_hacker"]:
		var class_art := factory.class_illustration(class_id, 140)
		check(class_art != null and class_art.texture is AtlasTexture, "initial class '%s' resolves approved illustrated art" % class_id)
		if class_art != null:
			class_art.free()
	check(factory.class_illustration("future_class", 140) == null, "future classes without approved illustrations fail closed to their vector emblem")
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
	factory.market_scroll_position = 120
	factory.hangar_scroll_position = 140
	factory.inventory_scroll_position = 160
	factory.reset_transient_navigation()
	check(factory.view_mode == "board" and factory.inventory_filter == "all" and factory.inventory_sort == "power" and factory.inventory_page == 0 and factory.arsenal_section == "equipped" and factory.board_section == "bounties", "factory reset restores default hub navigation")
	check(factory.briefing_context.is_empty() and factory.career_section == "progress" and factory.career_scroll_position == 0 and not factory.career_section_switch_pending, "factory reset clears stale briefing and career positions")
	check(factory.market_scroll_position == 0 and factory.hangar_scroll_position == 0 and factory.inventory_scroll_position == 0, "factory reset clears remembered commerce and inventory positions")

	for control in [title, button, outlined, portrait, illustrated_class, equipment, card]:
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
