extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_attributes_test")


func run_attributes_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for the attribute test")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	check(state.player.attributes == Rules.default_attributes() and int(state.player.stat_points) == 0, "new hunters start with five neutral attributes and no unearned points")

	var leveled: Dictionary = state.default_player()
	check(Rules.apply_xp(leveled, Rules.xp_needed(1)) == 1 and int(leveled.stat_points) == Rules.ATTRIBUTE_POINTS_PER_LEVEL, "each gained level awards the canonical attribute-point allowance")
	var baseline: Dictionary = state.default_player()
	var strength: Dictionary = baseline.duplicate(true)
	strength.attributes.strength = 12
	check(Rules.player_power(strength) == Rules.player_power(baseline) + 1, "strength provides its universal power bonus")
	var vitality: Dictionary = baseline.duplicate(true)
	vitality.attributes.vitality = 11
	check(Rules.max_health(vitality) == Rules.max_health(baseline) + 4, "vitality provides its universal health bonus")
	var dexterity: Dictionary = baseline.duplicate(true)
	dexterity.attributes.dexterity = 13
	check(Rules.player_damage_reduction(dexterity) == Rules.player_damage_reduction(baseline) + 1, "dexterity provides its universal mitigation bonus")
	var intelligence: Dictionary = baseline.duplicate(true)
	intelligence.attributes.intelligence = 12
	check(Rules.player_opening_damage(intelligence) == Rules.player_opening_damage(baseline) + 1, "intelligence provides its universal opening bonus")
	var cunning: Dictionary = baseline.duplicate(true)
	cunning.attributes.cunning = 11
	check(is_equal_approx(Rules.player_attack_roll(cunning, 0.5), 0.505), "cunning improves the attack roll by its documented amount")

	state.player.stat_points = 3
	check(not state.allocate_attribute_points({"unknown": 1}), "unknown attributes cannot consume points")
	check(not state.allocate_attribute_points({"strength": 4}), "allocations cannot overspend the available pool")
	check(state.allocate_attribute_points({"strength": 2, "cunning": 1}), "a valid mixed allocation commits atomically")
	check(int(state.player.attributes.strength) == 12 and int(state.player.attributes.cunning) == 11 and int(state.player.stat_points) == 0, "committed allocations update exact values and consume the exact pool")

	state.player = state.default_player()
	state.player.stat_points = 2
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.board_section = "destinations"
	scene.render()
	await process_frame
	check(scene.find_child("PrimaryNav_hunter", true, false) != null, "the persistent game navigation exposes the attribute hub")
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	await process_frame
	check(scene.find_child("HunterProfile", true, false) != null and scene.find_child("HunterProfilePortrait", true, false) != null, "the hunter sheet keeps the equipped character visually central")
	var hunter_profile := scene.find_child("HunterProfile", true, false) as PanelContainer
	check(hunter_profile.get_theme_stylebox("panel") is StyleBoxTexture, "hunter identity owns one illustrated equipment dossier")
	check(scene.find_children("HunterEquipment_*", "PanelContainer", true, false).size() == Rules.EQUIPMENT_SLOTS.size(), "the hunter sheet shows the complete universal equipment contract")
	var helmet_label := scene.find_child("HunterEquipmentLabel_helmet", true, false) as Label
	check(helmet_label != null and helmet_label.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION, "compact universal equipment labels remain readable on Android")
	check(scene.find_child("HunterCombatStatus", true, false) != null and scene.find_child("HunterArsenalAction", true, false) != null, "the hunter sheet exposes combat status and an equipment-management route")
	(scene.find_child("HunterTab_attributes", true, false) as Button).pressed.emit()
	await process_frame
	check(scene.find_children("Attribute_*", "PanelContainer", true, false).size() == 5, "the attribute section renders all five agreed attributes")
	check(scene.find_children("AttributeGlyph_*", "Control", true, false).size() == 5, "every attribute has a distinct compact visual glyph")
	var add_strength := scene.find_child("AttributeAdd_strength", true, false) as Button
	check(add_strength != null and not add_strength.disabled, "an available point enables the mobile strength action")
	if add_strength != null:
		add_strength.pressed.emit()
		await process_frame
	check(int(state.player.attributes.strength) == 10 and int(scene.attribute_draft.get("strength", 0)) == 1, "attribute taps remain a reversible draft before confirmation")
	var confirm := scene.find_child("ConfirmAttributes", true, false) as Button
	check(confirm != null and not confirm.disabled and confirm.text.contains("1"), "the confirmation action names the drafted cost")
	if confirm != null:
		confirm.pressed.emit()
		await process_frame
	check(int(state.player.attributes.strength) == 11 and int(state.player.stat_points) == 1 and scene.attribute_draft.is_empty(), "confirmation commits once and clears the transient draft")
	check(scene.android_back_action() == "board", "Android Back treats attributes as a safe secondary hub")
	(scene.find_child("HunterTab_profile", true, false) as Button).pressed.emit()
	await process_frame
	var arsenal_action := scene.find_child("HunterArsenalAction", true, false) as Button
	if arsenal_action != null:
		arsenal_action.pressed.emit()
		await process_frame
	check(scene.view_mode == "arsenal" and scene.arsenal_section == "equipped" and scene.find_child("UniversalEquipmentCard", true, false) != null and scene.find_child("FieldReadiness", true, false) == null, "the hunter sheet opens the focused equipped loadout without mixing workshop projections")

	scene.free()
	await process_frame
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: class-ready attributes earn, preview, and commit safely")
		quit(0)
	else:
		printerr("FAIL: %d attribute system test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
