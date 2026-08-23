class_name CrookedUIFactory
extends Control

const PortraitScript = preload("res://scripts/procedural_portrait.gd")

const INK := Color("#f4f2ff")
const MUTED := Color("#9da8c8")
const CYAN := Color("#55e5ff")
const LIME := Color("#b8f45d")
const GOLD := Color("#ffc857")
const CORAL := Color("#ff6f7d")
const PANEL := Color("#111a38")
const PANEL_LIGHT := Color("#18264b")


func panel(child: Control, color: Color, radius: int, margin: int) -> PanelContainer:
	var container := PanelContainer.new()
	var style := box_style(color, radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	container.add_theme_stylebox_override("panel", style)
	container.add_child(child)
	return container


func box_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func label(text_value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = alignment
	return result


func center_label(text_value: String, size: int, color: Color) -> Label:
	var result := label(text_value, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


func action_button(text_value: String, color: Color, outline := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 62)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", color if outline else Color("#07101c"))
	button.add_theme_color_override("font_hover_color", Color("#07101c"))
	button.add_theme_stylebox_override("normal", box_style(Color("#00000000") if outline else color, 14))
	button.add_theme_stylebox_override("hover", box_style(color.lightened(0.12), 14))
	button.add_theme_stylebox_override("pressed", box_style(color.darkened(0.14), 14))
	if outline:
		var normal := box_style(Color("#00000000"), 14)
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = color
		button.add_theme_stylebox_override("normal", normal)
	return button


func character_portrait(character_id: String, dimension: float) -> Control:
	var result: Control = PortraitScript.new()
	result.character_id = character_id
	result.custom_minimum_size = Vector2(dimension, dimension)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


func stat_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), PANEL, 12, 11)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(title, 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, 16, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func metric_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0a1025"), 9, 7)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(title, 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label(value, 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	return chip


func equipment_chip(item: Dictionary) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0d1530"), 12, 10)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	box.add_child(label(slot_name(str(item.slot)).to_upper(), 11, MUTED))
	box.add_child(label("%s  ·  +%d" % [str(item.name), int(item.power)], 13, INK))
	if int(item.get("integrity_upgrades", 0)) > 0:
		box.add_child(label("REFORÇO +%d VIDA" % (int(item.integrity_upgrades) * CoreRules.INTEGRITY_HEALTH_PER_LEVEL), 10, CYAN))
	return chip


func slot_name(slot: String) -> String:
	return "Arma" if slot == "weapon" else "Armadura"
