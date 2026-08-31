extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const DesignSystem = preload("res://scripts/ui_design_system.gd")
const StateIndicatorScript = preload("res://scripts/ui_state_indicator.gd")

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
	var illustrated_frame := illustrated.get_child(0) as PanelContainer
	check(illustrated.get_theme_stylebox("panel") is StyleBoxFlat and illustrated_frame.get_theme_stylebox("panel") is StyleBoxTexture, "factory layers a readable navy fill behind the approved reusable 9-slice")
	var matching_illustrated := factory.illustrated_panel(VBoxContainer.new(), 20)
	var matching_illustrated_frame := matching_illustrated.get_child(0) as PanelContainer
	check(illustrated_frame.get_theme_stylebox("panel") == matching_illustrated_frame.get_theme_stylebox("panel"), "matching focal dossiers reuse one 9-slice style resource")
	var supporting := factory.supporting_panel(VBoxContainer.new(), factory.PANEL_LIGHT, 24)
	var supporting_frame := supporting.get_child(0) as PanelContainer
	check(supporting.custom_minimum_size.y >= 112.0 and supporting.get_theme_stylebox("panel") is StyleBoxFlat and supporting_frame.get_theme_stylebox("panel") is StyleBoxTexture, "factory reserves the supplied supporting frame for section-level panels with safe physical height")
	check(factory.supporting_panel_content(supporting) is VBoxContainer, "supporting panel exposes its content without leaking the fill/frame composition")
	var matching_supporting := factory.supporting_panel(VBoxContainer.new(), factory.PANEL_LIGHT, 24)
	var matching_supporting_frame := matching_supporting.get_child(0) as PanelContainer
	check(supporting_frame.get_theme_stylebox("panel") == matching_supporting_frame.get_theme_stylebox("panel"), "matching supporting panels reuse one 9-slice style resource")
	var confirmation := factory.confirmation_panel(VBoxContainer.new(), 28)
	check(confirmation.custom_minimum_size.y >= 180.0 and confirmation.get_theme_stylebox("panel") is StyleBoxTexture, "confirmation surfaces use the supplied modal 9-slice with a safe mobile height")
	var success_receipt := factory.success_receipt_panel(VBoxContainer.new(), 22)
	check(success_receipt.custom_minimum_size.y >= 152.0 and factory.success_receipt_content(success_receipt) is VBoxContainer, "success receipts preserve a readable fill behind the supplied transparent frame")
	var selected_tab := factory.selected_tab_action("EQUIPAMENTO")
	check(selected_tab.custom_minimum_size.y >= 100.0 and selected_tab.get_theme_stylebox("normal") is StyleBoxTexture, "selected two-column tabs use the supplied illustrated state at its safe height")
	var divider := factory.runtime_divider()
	check(divider.texture != null and divider.custom_minimum_size.y >= 20.0, "the supplied plain divider resolves as a non-interactive runtime texture")
	var slider := factory.configure_slider(HSlider.new())
	check(slider.get_theme_icon("grabber") != null, "the supplied slider handle is exposed without forcing a slider into current screens")
	var checkbox := factory.state_indicator("checkbox", true, factory.GOLD)
	var radio := factory.state_indicator("radio", false, factory.CYAN)
	var toggle := factory.state_indicator("toggle", true, factory.CYAN)
	check(checkbox.get_script() == StateIndicatorScript and checkbox.custom_minimum_size == Vector2(28, 28), "code-native checkbox state preserves a compact readable contract")
	check(radio.get_script() == StateIndicatorScript and not bool(radio.selected), "code-native radio state exposes the current selection without incomplete raster states")
	check(toggle.get_script() == StateIndicatorScript and toggle.custom_minimum_size == Vector2(44, 28) and bool(toggle.selected), "code-native toggle state exposes both positions without incomplete raster states")
	var compact_equipment := factory.equipment_icon({"slot": "weapon", "rarity": "Raro"}, 72)
	check(compact_equipment is EquipmentIcon and bool(compact_equipment.draw_outer_frame), "compact equipment retains the readable procedural rarity frame")
	var large_equipment := factory.equipment_icon({"slot": "weapon", "rarity": "Raro"}, 116)
	check(large_equipment.name == "SuppliedRarityFrame_Raro" and not large_equipment.find_children("*", "TextureRect", true, false).is_empty(), "large equipment receives the supplied rarity frame without a duplicate procedural border")
	var compact_frame := factory.framed_portrait("hunter", 160)
	check(compact_frame.find_child("ProceduralPortraitFrame", true, false) != null, "portraits below the physical gate retain the procedural frame")
	var large_frame := factory.framed_portrait("hunter", 170, {}, "allied")
	check(large_frame.find_child("SuppliedPortraitFrame_allied", true, false) != null, "large portraits receive the relationship-specific supplied frame")
	check(factory.rarity_frame_asset_id("Incomum") == "rarity_tier_2" and factory.rarity_frame_asset_id("Épico") == "rarity_tier_4", "rarity tier two remains reserved while current top rarity maps to tier four")
	factory.view_mode = "career"
	factory.inventory_filter = "armor"
	factory.inventory_sort = "rarity"
	factory.inventory_page = 3
	factory.arsenal_section = "inventory"
	factory.briefing_context = {"target_id": "gloop"}
	factory.career_section = "archive"
	factory.career_scroll_position = 900
	factory.career_section_switch_pending = true
	factory.career_archive_planet_index = 3
	factory.market_scroll_position = 120
	factory.hangar_scroll_position = 140
	factory.inventory_scroll_position = 160
	factory.galaxy_scroll_position = 180
	factory.galaxy_page_index = 3
	factory.galaxy_focus_planet_id = "congelaria_sa"
	factory.reset_transient_navigation()
	check(factory.view_mode == "board" and factory.inventory_filter == "all" and factory.inventory_sort == "power" and factory.inventory_page == 0 and factory.arsenal_section == "equipped" and factory.board_section == "bounties", "factory reset restores default hub navigation")
	check(factory.briefing_context.is_empty() and factory.career_section == "progress" and factory.career_scroll_position == 0 and factory.career_archive_planet_index == 0 and not factory.career_section_switch_pending, "factory reset clears stale briefing and career positions")
	check(factory.market_scroll_position == 0 and factory.hangar_scroll_position == 0 and factory.inventory_scroll_position == 0 and factory.galaxy_scroll_position == 0 and factory.galaxy_page_index == -1 and factory.galaxy_focus_planet_id.is_empty(), "factory reset clears remembered commerce, inventory, and Galaxy positions")

	for control in [title, button, outlined, rebuild_title, rebuild_body, rebuild_primary, rebuild_secondary, metric, rebuild_focal, portrait, equipment, card, matching_card, illustrated, matching_illustrated, supporting, matching_supporting, confirmation, success_receipt, selected_tab, divider, slider, checkbox, radio, toggle, compact_equipment, large_equipment, compact_frame, large_frame]:
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
