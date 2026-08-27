extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const DesignSystem = preload("res://scripts/ui_design_system.gd")

var failures := 0


func _init() -> void:
	var factory = FactoryScript.new()
	root.add_child(factory)
	var title := factory.label("TESTE", 18, factory.CYAN)
	check(title.text == "TESTE" and title.get_theme_font_size("font_size") == 18, "factory builds themed labels")
	var button := factory.action_button("AÇÃO", factory.GOLD)
	check(button.custom_minimum_size.y >= 48.0 and button.get_theme_font_size("font_size") >= DesignSystem.FONT_CAPTION, "factory buttons preserve mobile touch height and Android-readable text")
	var outlined := factory.action_button("VOLTAR", factory.CYAN, true)
	check(outlined.get_theme_stylebox("normal") is StyleBoxFlat, "factory builds outlined button styles")
	check((outlined.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.a > 0.0, "outlined actions keep a calm navy surface over illustrated backgrounds")
	check(is_equal_approx(DesignSystem.TARGET_SCALE, 0.625), "UI design system maps 720x1280 to the 450x800 Android target")
	check(DesignSystem.is_readable_font(DesignSystem.FONT_CAPTION), "smallest rebuild caption remains readable at physical target size")
	check(DesignSystem.is_safe_touch_target(DesignSystem.TOUCH_TARGET_MIN), "smallest rebuild action remains a safe physical touch target")
	check(DesignSystem.stage_height() >= DesignSystem.FOCAL_ART_MIN_HEIGHT, "shell reserves enough height for a dominant illustrated subject")
	check(DesignSystem.validate_visible_action_count(3) and not DesignSystem.validate_visible_action_count(4), "rebuild composition limits simultaneous primary choices")
	check(str(DesignSystem.composition_for("board").get("subject", "")) == "target", "board rebuild assigns the target as its visual subject")
	var rebuild_title := factory.scene_title("QUADRO DE PROCURADOS")
	check(rebuild_title.get_theme_font_size("font_size") == DesignSystem.FONT_SCREEN_TITLE, "factory exposes the rebuild screen-title scale")
	var rebuild_body := factory.readable_body("Um alvo, uma decisão clara.")
	check(rebuild_body.get_theme_font_size("font_size") == DesignSystem.FONT_BODY and rebuild_body.autowrap_mode != TextServer.AUTOWRAP_OFF, "factory exposes readable wrapping body copy")
	var rebuild_primary := factory.primary_action("ANALISAR ABORDAGENS", factory.GOLD)
	check(rebuild_primary.custom_minimum_size.y == DesignSystem.PRIMARY_ACTION_HEIGHT, "factory exposes the rebuild primary action target")
	var rebuild_secondary := factory.secondary_action("DETALHES", factory.CYAN)
	check(rebuild_secondary.custom_minimum_size.y == DesignSystem.SECONDARY_ACTION_HEIGHT, "factory exposes the rebuild secondary action target")
	var metric := factory.metric_chip("CHANCE", "72%", factory.LIME)
	var metric_stack := metric.get_child(0) as VBoxContainer
	check((metric_stack.get_child(0) as Label).get_theme_font_size("font_size") == DesignSystem.FONT_CAPTION and (metric_stack.get_child(1) as Label).get_theme_font_size("font_size") == DesignSystem.FONT_BODY, "shared metric chips preserve the physical Android readability floor")
	var rebuild_focal := factory.focal_scene_panel(VBoxContainer.new())
	check(rebuild_focal.custom_minimum_size.y == DesignSystem.FOCAL_PANEL_MIN_HEIGHT, "factory exposes the rebuild focal scene surface")
	var portrait := factory.character_portrait("hunter", 80)
	check(portrait.custom_minimum_size == Vector2(80, 80), "factory builds consistently sized portraits")
	for class_id in ["warrant_breaker", "orbit_gunslinger", "contract_hacker"]:
		var class_emblem := factory.class_icon(class_id, 92)
		check(class_emblem != null and class_emblem.custom_minimum_size == Vector2(92, 92), "class '%s' resolves its deliberate vector emblem" % class_id)
		class_emblem.free()
	var equipment := factory.equipment_chip({"name": "Arma Teste", "slot": "weapon", "power": 5, "integrity_upgrades": 2})
	check(equipment is PanelContainer and equipment.get_child_count() == 1, "factory builds reinforced equipment chips")
	var equipment_stack := equipment.get_child(0) as VBoxContainer
	check((equipment_stack.get_child(0) as Label).get_theme_font_size("font_size") >= DesignSystem.FONT_CAPTION and (equipment_stack.get_child(1) as Label).get_theme_font_size("font_size") >= DesignSystem.FONT_BODY, "legacy equipment chips respect the shared Android typography floor")
	var card := factory.panel(VBoxContainer.new(), factory.PANEL, 12, 10)
	check(card.get_theme_stylebox("panel") is StyleBoxFlat, "factory panels retain reusable styling")
	check((card.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top == 1, "support panels share the restrained steel edge")
	var matching_card := factory.panel(VBoxContainer.new(), factory.PANEL, 12, 10)
	check(card.get_theme_stylebox("panel") == matching_card.get_theme_stylebox("panel"), "matching support panels reuse one immutable style resource")
	var illustrated := factory.illustrated_panel(VBoxContainer.new(), 20)
	check(illustrated.get_theme_stylebox("panel") is StyleBoxTexture, "factory exposes the approved illustrated panel as a reusable 9-slice")
	var matching_illustrated := factory.illustrated_panel(VBoxContainer.new(), 20)
	check(illustrated.get_theme_stylebox("panel") == matching_illustrated.get_theme_stylebox("panel"), "matching focal dossiers reuse one 9-slice style resource")
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

	for control in [title, button, outlined, rebuild_title, rebuild_body, rebuild_primary, rebuild_secondary, metric, rebuild_focal, portrait, equipment, card, matching_card, illustrated, matching_illustrated]:
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
