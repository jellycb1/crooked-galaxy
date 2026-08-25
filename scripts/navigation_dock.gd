class_name NavigationDock
extends PanelContainer

signal destination_selected(destination_id: String)

const HubDestinationIconScript = preload("res://scripts/hub_destination_icon.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")

const INK := Color("#f4f2ff")
const MUTED := Color("#9da8c8")
const CYAN := Color("#55e5ff")
const LIME := Color("#b8f45d")
const GOLD := Color("#ffc857")
const CORAL := Color("#ff6f7d")
const DEEP := Color("#071126")
const PANEL := Color("#0b1530")


func _ready() -> void:
	name = "PrimaryNavigationDock"
	custom_minimum_size = Vector2(0, 76)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_process(false)
	visible = false


func configure(active_id: String, labels: Dictionary = {}, badges: Dictionary = {}) -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#071126f2")
	frame.corner_radius_top_left = 16
	frame.corner_radius_top_right = 16
	frame.border_width_top = 2
	frame.border_color = Color("#55e5ff55")
	frame.content_margin_left = 5
	frame.content_margin_right = 5
	frame.content_margin_top = 5
	frame.content_margin_bottom = 5
	add_theme_stylebox_override("panel", frame)
	var definitions := [
		{"id": "contracts", "label": LocaleRulesScript.text("NAV_CONTRACTS", "MANDADOS"), "icon": "contracts", "color": CORAL},
		{"id": "arsenal", "label": LocaleRulesScript.text("NAV_ARSENAL", "ARSENAL"), "icon": "arsenal", "color": GOLD},
		{"id": "hunter", "label": LocaleRulesScript.text("NAV_HUNTER", "CAÇADOR"), "icon": "hunter", "color": CYAN},
		{"id": "galaxy", "label": LocaleRulesScript.text("NAV_GALAXY", "GALÁXIA"), "icon": "galaxy", "color": LIME},
		{"id": "menu", "label": LocaleRulesScript.text("NAV_MENU", "MENU"), "icon": "menu", "color": CYAN},
	]
	var row := get_node_or_null("PrimaryNavigationRow") as HBoxContainer
	if row == null or row.get_child_count() != definitions.size():
		clear_items()
		row = HBoxContainer.new()
		row.name = "PrimaryNavigationRow"
		row.add_theme_constant_override("separation", 4)
		add_child(row)
		for definition in definitions:
			var destination_id := str(definition.id)
			var display_label := str(labels.get(destination_id, definition.label))
			row.add_child(navigation_button(destination_id, display_label, str(definition.icon), definition.color, active_id == destination_id, int(badges.get(destination_id, 0))))
	else:
		for definition in definitions:
			var destination_id := str(definition.id)
			var display_label := str(labels.get(destination_id, definition.label))
			var button := row.get_node_or_null("PrimaryNav_%s" % destination_id) as Button
			if button != null:
				refresh_navigation_button(button, destination_id, display_label, str(definition.icon), definition.color, active_id == destination_id, int(badges.get(destination_id, 0)))
	visible = true


func hide_and_clear() -> void:
	visible = false


func clear_items() -> void:
	for child in get_children():
		remove_child(child)
		# The dock is rebuilt synchronously inside the host render. Free the old
		# row immediately so stale CanvasItems cannot survive into the same frame
		# and intermittently mask freshly drawn icons on mobile GPUs.
		child.free()


func navigation_button(destination_id: String, display_label: String, icon_kind: String, accent: Color, selected: bool, badge_count: int) -> Button:
	var button := Button.new()
	button.name = "PrimaryNav_%s" % destination_id
	button.text = display_label
	button.tooltip_text = display_label.capitalize()
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color.TRANSPARENT)
	var normal := dock_style(Color("#0a1830d9"), accent.darkened(0.42), 1)
	var hover := dock_style(Color("#16284d"), accent, 1)
	var pressed := dock_style(Color("#0b1d3a"), accent, 1)
	var selected_style := dock_style(accent, accent, 0)
	button.add_theme_stylebox_override("normal", selected_style if selected else normal)
	button.add_theme_stylebox_override("hover", selected_style if selected else hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", dock_style(Color("#16284d") if not selected else accent, GOLD, 3))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -2)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var visual_color := DEEP if selected else accent
	var icon: Control = HubDestinationIconScript.new()
	icon.name = "PrimaryNavIcon_%s" % destination_id
	icon.custom_minimum_size = Vector2(42, 42)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.configure(icon_kind, visual_color)
	stack.add_child(icon)
	var caption := Label.new()
	caption.name = "PrimaryNavCaption_%s" % destination_id
	caption.text = display_label
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.add_theme_font_size_override("font_size", 9)
	caption.add_theme_color_override("font_color", DEEP if selected else INK)
	stack.add_child(caption)
	if badge_count > 0:
		add_navigation_badge(button, destination_id, badge_count)
	button.pressed.connect(func(): destination_selected.emit(destination_id))
	return button


func refresh_navigation_button(button: Button, destination_id: String, display_label: String, icon_kind: String, accent: Color, selected: bool, badge_count: int) -> void:
	button.text = display_label
	button.tooltip_text = display_label.capitalize()
	var normal := dock_style(Color("#0a1830d9"), accent.darkened(0.42), 1)
	var hover := dock_style(Color("#16284d"), accent, 1)
	button.add_theme_stylebox_override("normal", dock_style(accent, accent, 0) if selected else normal)
	button.add_theme_stylebox_override("hover", dock_style(accent, accent, 0) if selected else hover)
	button.add_theme_stylebox_override("pressed", dock_style(Color("#0b1d3a"), accent, 1))
	button.add_theme_stylebox_override("focus", dock_style(accent if selected else Color("#16284d"), GOLD, 3))
	var visual_color := DEEP if selected else accent
	var icon := button.find_child("PrimaryNavIcon_%s" % destination_id, true, false) as HubDestinationIcon
	if icon != null:
		icon.configure(icon_kind, visual_color)
	var caption := button.find_child("PrimaryNavCaption_%s" % destination_id, true, false) as Label
	if caption != null:
		caption.text = display_label
		caption.add_theme_color_override("font_color", DEEP if selected else INK)
	var existing_badge := button.find_child("PrimaryNavBadge_%s" % destination_id, false, false) as Label
	if badge_count > 0:
		if existing_badge == null:
			add_navigation_badge(button, destination_id, badge_count)
		else:
			existing_badge.text = str(mini(99, badge_count))
	elif existing_badge != null:
		button.remove_child(existing_badge)
		existing_badge.queue_free()


func add_navigation_badge(button: Button, destination_id: String, badge_count: int) -> void:
	var badge := Label.new()
	badge.name = "PrimaryNavBadge_%s" % destination_id
	badge.text = str(mini(99, badge_count))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -24.0
	badge.offset_top = 3.0
	badge.offset_right = -3.0
	badge.offset_bottom = 24.0
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", DEEP)
	var badge_style := dock_style(CORAL, CORAL, 0)
	badge_style.corner_radius_top_left = 10
	badge_style.corner_radius_top_right = 10
	badge_style.corner_radius_bottom_left = 10
	badge_style.corner_radius_bottom_right = 10
	badge.add_theme_stylebox_override("normal", badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)


func dock_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 11
	style.corner_radius_top_right = 11
	style.corner_radius_bottom_left = 11
	style.corner_radius_bottom_right = 11
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	return style
