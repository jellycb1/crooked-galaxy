extends SceneTree

const PortraitScript = preload("res://scripts/procedural_portrait.gd")
const OUTPUT_PATH := "res://builds/ui_portraits.png"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var background := ColorRect.new()
	background.color = Color("#071022")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	root.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 34)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "CROOKED GALAXY · PROCEDURAL CAST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#55e5ff"))
	layout.add_child(title)
	var characters := [
		{"id": "hunter", "name": "O CAÇADOR"},
		{"id": "gloop", "name": "GLOOP"},
		{"id": "baron_boom", "name": "BARÃO BOOM"},
		{"id": "madame_vacuum", "name": "MADAME VÁCUO"},
	]
	for row_index in 2:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 34)
		layout.add_child(row)
		for column_index in 2:
			var definition: Dictionary = characters[row_index * 2 + column_index]
			var cell := VBoxContainer.new()
			cell.custom_minimum_size = Vector2(270, 350)
			cell.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(cell)
			var portrait: Control = PortraitScript.new()
			portrait.character_id = str(definition.id)
			portrait.custom_minimum_size = Vector2(260, 260)
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.add_child(portrait)
			var caption := Label.new()
			caption.text = str(definition.name)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 18)
			caption.add_theme_color_override("font_color", Color("#f4f2ff"))
			cell.add_child(caption)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds"))
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error == OK:
		print("Captured portrait review to %s" % OUTPUT_PATH)
		quit(0)
	else:
		printerr("Failed to capture portraits: %s" % error_string(error))
		quit(1)
