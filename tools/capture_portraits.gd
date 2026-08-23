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
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	root.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "CROOKED GALAXY · PROCEDURAL CAST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#55e5ff"))
	layout.add_child(title)
	var characters := [
		{"id": "hunter", "name": "O CAÇADOR"},
		{"id": "gloop", "name": "GLOOP"},
		{"id": "baron_boom", "name": "BARÃO BOOM"},
		{"id": "madame_vacuum", "name": "MADAME VÁCUO"},
		{"id": "mayor_gold_dust", "name": "PREFEITO PÓ-DE-OURO"},
		{"id": "auditor_frost", "name": "AUDITOR GEADA"},
		{"id": "chef_coldflame", "name": "CHEF BRASA FRIA"},
		{"id": "executive_penguin", "name": "PINGUIM EXECUTIVO"},
		{"id": "director_kelvin", "name": "DIRETORA KELVIN"},
		{"id": "landlord_spore", "name": "SÍNDICO ESPORÃO"},
		{"id": "countess_truffle", "name": "CONDESSA TRUFA"},
		{"id": "captain_chlorophyll", "name": "CAPITÃO CLOROFILA"},
		{"id": "mother_mycelia", "name": "MÃE MICÉLIA"},
		{"id": "bolt_collector", "name": "COBRADOR REBITE"},
		{"id": "doctor_patchwork", "name": "DRA. GAMBIARRA"},
		{"id": "crane_king", "name": "REI GUINDASTE"},
		{"id": "omega_junkyard", "name": "FERRO-VELHO ÔMEGA"},
		{"id": "dealer_comet", "name": "CRUPIÊ COMETA"},
		{"id": "duchess_jackpot", "name": "DUQUESA JACKPOT"},
		{"id": "misfortune_auditor", "name": "AUDITOR DO AZAR"},
		{"id": "house_eternal", "name": "A CASA ETERNA"},
	]
	for row_index in 7:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		layout.add_child(row)
		for column_index in 3:
			var character_index := row_index * 3 + column_index
			if character_index >= characters.size():
				break
			var definition: Dictionary = characters[character_index]
			var cell := VBoxContainer.new()
			cell.custom_minimum_size = Vector2(105, 102)
			cell.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(cell)
			var portrait: Control = PortraitScript.new()
			portrait.character_id = str(definition.id)
			portrait.custom_minimum_size = Vector2(76, 76)
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.add_child(portrait)
			var caption := Label.new()
			caption.text = str(definition.name)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 9)
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
