class_name CrookedUIFactory
extends Control

const PortraitScript = preload("res://scripts/procedural_portrait.gd")
const ClassIconScript = preload("res://scripts/class_icon.gd")
const PortraitFrameScript = preload("res://scripts/portrait_frame.gd")
const EquipmentIconScript = preload("res://scripts/equipment_icon.gd")
const TransportIconScript = preload("res://scripts/transport_icon.gd")
const UIStateIndicatorScript = preload("res://scripts/ui_state_indicator.gd")
const EquipmentPresentationScript = preload("res://scripts/equipment_presentation.gd")
const UILocaleRulesScript = preload("res://scripts/locale_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const VisualAssetCatalogScript = preload("res://scripts/visual_asset_catalog.gd")
const ILLUSTRATED_PANEL_TEXTURE = preload("res://assets/ui/main-dossier-frame-runtime-512x384.png")
const ILLUSTRATED_PANEL_TEXTURE_MARGINS := Rect2(79.0, 61.0, 98.0, 68.0)
const ILLUSTRATED_PANEL_FILL := Color("#0b142df2")
const SUPPORTING_PANEL_TEXTURE = preload("res://assets/ui/supporting-panel-runtime-candidate-v1.png")
const SUPPORTING_PANEL_TEXTURE_MARGINS := Rect2(48.0, 44.0, 48.0, 44.0)

const INK := Color("#f4f2ff")
const MUTED := Color("#9da8c8")
const CYAN := Color("#55e5ff")
const LIME := Color("#b8f45d")
const GOLD := Color("#ffc857")
const CORAL := Color("#ff6f7d")
const PANEL := Color("#111a38")
const PANEL_LIGHT := Color("#18264b")
const DEEP := Color("#071126")
const STEEL_EDGE := Color("#55708f73")

var view_mode := "board"
var inventory_filter := "all"
var inventory_sort := "power"
var inventory_page := 0
var arsenal_section := "equipped"
var workshop_slot := "weapon"
var board_section := "bounties"
var board_details_open := false
var hunter_section := "profile"
var briefing_context: Dictionary = {}
var career_section := "progress"
var career_scroll_position := 0
var career_section_switch_pending := false
var career_archive_planet_index := 0
var career_progress_planet_index := -1
var career_milestone_index := 0
var onboarding_scroll_position := 0
var market_scroll_position := 0
var hangar_scroll_position := 0
var hangar_selected_transport_index := -1
var inventory_scroll_position := 0
var collection_planet_index := 0
var collection_scroll_position := 0
var daily_scroll_position := 0
var galaxy_scroll_position := 0
var galaxy_page_index := -1
var galaxy_focus_planet_id := ""
var market_refresh_confirmation := false
var market_selected_offer_index := 0
var fuel_refill_confirmation := false
var rift_retry_confirmation := false
var attribute_draft: Dictionary = {}
var class_draft := ""
var species_draft := ""
var appearance_draft: Dictionary = {}
var locale_draft := ""
var server_draft := ""
var _support_style_cache: Dictionary = {}
var _illustrated_style_cache: Dictionary = {}
var _supporting_frame_style_cache: Dictionary = {}
var _button_style_cache: Dictionary = {}
var _runtime_texture_cache: Dictionary = {}
var _runtime_frame_style_cache: Dictionary = {}


func reset_transient_navigation() -> void:
	view_mode = "board"
	inventory_filter = "all"
	inventory_sort = "power"
	inventory_page = 0
	arsenal_section = "equipped"
	workshop_slot = "weapon"
	board_section = "bounties"
	board_details_open = false
	hunter_section = "profile"
	briefing_context = {}
	career_section = "progress"
	career_scroll_position = 0
	career_section_switch_pending = false
	career_archive_planet_index = 0
	career_progress_planet_index = -1
	career_milestone_index = 0
	onboarding_scroll_position = 0
	market_scroll_position = 0
	hangar_scroll_position = 0
	hangar_selected_transport_index = -1
	inventory_scroll_position = 0
	collection_planet_index = 0
	collection_scroll_position = 0
	daily_scroll_position = 0
	galaxy_scroll_position = 0
	galaxy_page_index = -1
	galaxy_focus_planet_id = ""
	market_refresh_confirmation = false
	market_selected_offer_index = 0
	fuel_refill_confirmation = false
	rift_retry_confirmation = false
	attribute_draft = {}
	class_draft = ""
	species_draft = ""
	appearance_draft = {}
	locale_draft = ""
	server_draft = ""


func reset_session_scroll(node_name: String, property_name: String) -> void:
	set(property_name, 0)
	var scroll := find_child(node_name, true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 0


func panel(child: Control, color: Color, radius: int, margin: int) -> PanelContainer:
	var container := PanelContainer.new()
	var style := cached_support_box_style(color, radius, margin)
	container.add_theme_stylebox_override("panel", style)
	container.add_child(child)
	return container


func illustrated_panel(child: Control, margin: int = 22) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", box_style(ILLUSTRATED_PANEL_FILL, 2))
	var frame := PanelContainer.new()
	frame.name = "DossierFrame"
	frame.add_theme_stylebox_override("panel", cached_illustrated_box_style(margin))
	frame.add_child(child)
	container.add_child(frame)
	return container


func illustrated_panel_content(container: PanelContainer) -> Control:
	var frame := container.get_child(0) as PanelContainer
	return frame.get_child(0) as Control


func supporting_panel(child: Control, fill_color: Color = PANEL_LIGHT, margin: int = 24) -> PanelContainer:
	var container := PanelContainer.new()
	container.custom_minimum_size.y = 112.0
	container.add_theme_stylebox_override("panel", box_style(fill_color, 2))
	var frame := PanelContainer.new()
	frame.name = "SupportingFrame"
	frame.add_theme_stylebox_override("panel", cached_supporting_frame_style(margin))
	frame.add_child(child)
	container.add_child(frame)
	return container


func supporting_panel_content(container: PanelContainer) -> Control:
	var frame := container.get_child(0) as PanelContainer
	return frame.get_child(0) as Control


func confirmation_panel(child: Control, margin: int = 32) -> PanelContainer:
	var container := PanelContainer.new()
	container.name = "ConfirmationModalFrame"
	container.custom_minimum_size.y = 180.0
	container.add_theme_stylebox_override("panel", runtime_frame_style("confirmation_modal", Rect2(64, 56, 64, 56), margin))
	container.add_child(child)
	return container


func success_receipt_panel(child: Control, margin: int = 24) -> PanelContainer:
	var container := PanelContainer.new()
	container.name = "SuccessReceiptSurface"
	container.custom_minimum_size.y = 152.0
	container.add_theme_stylebox_override("panel", box_style(Color("#102438f2"), 2))
	var frame := PanelContainer.new()
	frame.name = "SuccessReceiptFrame"
	frame.add_theme_stylebox_override("panel", runtime_frame_style("success_receipt", Rect2(72, 64, 72, 64), margin))
	frame.add_child(child)
	container.add_child(frame)
	return container


func success_receipt_content(container: PanelContainer) -> Control:
	var frame := container.get_child(0) as PanelContainer
	return frame.get_child(0) as Control


func runtime_divider(minimum_height := 20.0) -> TextureRect:
	var divider := TextureRect.new()
	divider.name = "IllustratedDivider"
	divider.texture = runtime_texture("plain_divider")
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	divider.custom_minimum_size.y = minimum_height
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider


func selected_tab_action(text_value: String) -> Button:
	var button := secondary_action(text_value, CYAN)
	button.custom_minimum_size.y = 100.0
	button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_BODY)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var style := runtime_frame_style("selected_tab", Rect2(44, 24, 44, 20), 14)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", button_box_style(Color("#16284d"), GOLD, 12, 3))
	return button


func configure_slider(slider: Slider) -> Slider:
	var handle := runtime_texture("slider_handle")
	if handle != null:
		slider.add_theme_icon_override("grabber", handle)
		slider.add_theme_icon_override("grabber_highlight", handle)
	return slider


func state_indicator(kind: String, selected: bool, accent: Color = CYAN) -> Control:
	var indicator: Control = UIStateIndicatorScript.new()
	indicator.name = "StateIndicator_%s_%s" % [kind, "on" if selected else "off"]
	indicator.configure(kind, selected, accent)
	return indicator


func runtime_texture(asset_id: String) -> Texture2D:
	if _runtime_texture_cache.has(asset_id):
		return _runtime_texture_cache[asset_id] as Texture2D
	var texture := VisualAssetCatalogScript.load_texture("runtime", asset_id)
	_runtime_texture_cache[asset_id] = texture
	return texture


func runtime_frame_style(asset_id: String, margins: Rect2, content_margin: int) -> StyleBoxTexture:
	var key := "%s:%s" % [asset_id, content_margin]
	if _runtime_frame_style_cache.has(key):
		return _runtime_frame_style_cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	style.texture = runtime_texture(asset_id)
	style.texture_margin_left = margins.position.x
	style.texture_margin_top = margins.position.y
	style.texture_margin_right = margins.size.x
	style.texture_margin_bottom = margins.size.y
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_runtime_frame_style_cache[key] = style
	return style


func cached_illustrated_box_style(margin: int) -> StyleBoxTexture:
	if _illustrated_style_cache.has(margin):
		return _illustrated_style_cache[margin] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	style.texture = ILLUSTRATED_PANEL_TEXTURE
	style.texture_margin_left = ILLUSTRATED_PANEL_TEXTURE_MARGINS.position.x
	style.texture_margin_top = ILLUSTRATED_PANEL_TEXTURE_MARGINS.position.y
	style.texture_margin_right = ILLUSTRATED_PANEL_TEXTURE_MARGINS.size.x
	style.texture_margin_bottom = ILLUSTRATED_PANEL_TEXTURE_MARGINS.size.y
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_illustrated_style_cache[margin] = style
	return style


func cached_supporting_frame_style(margin: int) -> StyleBoxTexture:
	if _supporting_frame_style_cache.has(margin):
		return _supporting_frame_style_cache[margin] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	style.texture = SUPPORTING_PANEL_TEXTURE
	style.texture_margin_left = SUPPORTING_PANEL_TEXTURE_MARGINS.position.x
	style.texture_margin_top = SUPPORTING_PANEL_TEXTURE_MARGINS.position.y
	style.texture_margin_right = SUPPORTING_PANEL_TEXTURE_MARGINS.size.x
	style.texture_margin_bottom = SUPPORTING_PANEL_TEXTURE_MARGINS.size.y
	var horizontal_safe_margin := maxf(float(margin), 40.0)
	var vertical_safe_margin := maxf(float(margin), 36.0)
	style.content_margin_left = horizontal_safe_margin
	style.content_margin_top = vertical_safe_margin
	style.content_margin_right = horizontal_safe_margin
	style.content_margin_bottom = vertical_safe_margin
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_supporting_frame_style_cache[margin] = style
	return style


func box_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func support_box_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := box_style(color, radius)
	style.border_color = STEEL_EDGE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style


func cached_support_box_style(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var key := "%s:%d:%d" % [color.to_html(true), radius, margin]
	if _support_style_cache.has(key):
		return _support_style_cache[key] as StyleBoxFlat
	var style := support_box_style(color, radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	_support_style_cache[key] = style
	return style


func button_box_style(fill: Color, accent: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var key := "%s:%s:%d:%d" % [fill.to_html(true), accent.to_html(true), radius, border_width]
	if _button_style_cache.has(key):
		return _button_style_cache[key] as StyleBoxFlat
	var style := box_style(fill, radius)
	style.border_color = accent
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 12
	style.content_margin_right = 12
	_button_style_cache[key] = style
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
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
	button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	button.add_theme_color_override("font_color", color if outline else DEEP)
	button.add_theme_color_override("font_hover_color", INK if outline else DEEP)
	button.add_theme_color_override("font_pressed_color", INK if outline else DEEP)
	button.add_theme_color_override("font_focus_color", INK if outline else DEEP)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.22))
	var normal_fill := Color("#09152be8") if outline else color
	var normal_border := color if outline else color.darkened(0.48)
	button.add_theme_stylebox_override("normal", button_box_style(normal_fill, normal_border, 12, 2))
	var hover_fill := Color("#172b4d") if outline else color.lightened(0.08)
	button.add_theme_stylebox_override("hover", button_box_style(hover_fill, color.lightened(0.12), 12, 2))
	var pressed_fill := Color("#071126") if outline else color.darkened(0.13)
	button.add_theme_stylebox_override("pressed", button_box_style(pressed_fill, color, 12, 2))
	button.add_theme_stylebox_override("focus", button_box_style(Color("#16284d"), GOLD, 12, 3))
	button.add_theme_stylebox_override("disabled", button_box_style(Color("#091126cc"), STEEL_EDGE.darkened(0.2), 12, 1))
	return button


## Rebuild-only components. Existing screens keep their current measurements
## until they are deliberately migrated; new/rebuilt screens must use these
## helpers so 450x800 readability is enforced at the component boundary.
func scene_title(text_value: String) -> Label:
	var result := label(text_value, UIDesignSystem.FONT_SCREEN_TITLE, INK)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


func readable_body(text_value: String, color: Color = INK) -> Label:
	var result := label(text_value, UIDesignSystem.FONT_BODY, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


func readable_caption(text_value: String, color: Color = MUTED) -> Label:
	var result := label(text_value, UIDesignSystem.FONT_CAPTION, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


func primary_action(text_value: String, color: Color) -> Button:
	var button := action_button(text_value, color)
	button.custom_minimum_size.y = UIDesignSystem.PRIMARY_ACTION_HEIGHT
	button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_EMPHASIS)
	return button


func secondary_action(text_value: String, color: Color) -> Button:
	var button := action_button(text_value, color, true)
	button.custom_minimum_size.y = UIDesignSystem.SECONDARY_ACTION_HEIGHT
	button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_BODY)
	return button


func focal_scene_panel(child: Control) -> PanelContainer:
	var result := illustrated_panel(child, UIDesignSystem.FOCAL_PANEL_PADDING)
	result.custom_minimum_size.y = UIDesignSystem.FOCAL_PANEL_MIN_HEIGHT
	return result


func character_portrait(character_id: String, dimension: float, equipment_profile: Dictionary = {}) -> Control:
	var result: Control = PortraitScript.new()
	result.character_id = character_id
	result.equipment_profile = equipment_profile.duplicate(true)
	result.custom_minimum_size = Vector2(dimension, dimension)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


func class_icon(class_id: String, dimension: float) -> Control:
	var icon: Control = ClassIconScript.new()
	var color := {"warrant_breaker": CORAL, "orbit_gunslinger": GOLD, "contract_hacker": CYAN}.get(class_id, CYAN) as Color
	icon.configure(class_id, color, dimension)
	return icon


func framed_portrait(character_id: String, dimension: float, equipment_profile: Dictionary = {}, relationship := "allied") -> Control:
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(dimension, dimension)
	stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var use_supplied_frame := UIDesignSystem.physical_pixels(dimension) >= 106.0
	var inset := dimension * 0.10 if use_supplied_frame else 4.0
	var portrait := character_portrait(character_id, dimension - inset * 2.0, equipment_profile)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = inset
	portrait.offset_top = inset
	portrait.offset_right = -inset
	portrait.offset_bottom = -inset
	stack.add_child(portrait)
	if use_supplied_frame:
		var frame := TextureRect.new()
		frame.name = "SuppliedPortraitFrame_%s" % relationship
		frame.texture = runtime_texture("portrait_%s" % relationship if relationship in ["allied", "boss", "hostile", "neutral"] else "portrait_neutral")
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(frame)
	else:
		var fallback_frame: Control = PortraitFrameScript.new()
		fallback_frame.name = "ProceduralPortraitFrame"
		fallback_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback_frame.configure(CYAN)
		stack.add_child(fallback_frame)
	return stack


func equipment_icon(item: Dictionary, dimension: float) -> Control:
	var use_supplied_frame := UIDesignSystem.physical_pixels(dimension) >= 72.0
	var icon: Control = EquipmentIconScript.new()
	icon.item = item.duplicate(true)
	icon.draw_outer_frame = not use_supplied_frame
	if not use_supplied_frame:
		icon.custom_minimum_size = Vector2(dimension, dimension)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return icon
	var stack := Control.new()
	stack.name = "SuppliedRarityFrame_%s" % str(item.get("rarity", "Comum"))
	stack.custom_minimum_size = Vector2(dimension, dimension)
	stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := dimension * 0.14
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset
	stack.add_child(icon)
	var rarity_frame := TextureRect.new()
	rarity_frame.texture = runtime_texture(rarity_frame_asset_id(str(item.get("rarity", "Comum"))))
	rarity_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rarity_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rarity_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rarity_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(rarity_frame)
	return stack


func rarity_frame_asset_id(rarity: String) -> String:
	match rarity:
		"Épico", "Epic": return "rarity_tier_4"
		"Raro", "Rare": return "rarity_tier_3"
		"Incomum", "Uncommon": return "rarity_tier_2"
		_: return "rarity_tier_1"


func transport_icon(transport: Dictionary, dimension: float) -> Control:
	var result: Control = TransportIconScript.new()
	result.transport_id = str(transport.get("id", ""))
	var raw_color := str(transport.get("color", "#55e5ff"))
	result.accent = Color(raw_color) if Color.html_is_valid(raw_color) else CYAN
	result.custom_minimum_size = Vector2(dimension, dimension)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


func stat_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), PANEL, 12, 11)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	var title_label := label(title, UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(title_label)
	var value_label := label(value, UIDesignSystem.FONT_BODY, color, HORIZONTAL_ALIGNMENT_CENTER)
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(value_label)
	return chip


func metric_chip(title: String, value: String, color: Color) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0a1025"), 9, 7)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	var title_label := label(title, UIDesignSystem.FONT_CAPTION, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(title_label)
	var value_label := label(value, UIDesignSystem.FONT_BODY, color, HORIZONTAL_ALIGNMENT_CENTER)
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(value_label)
	return chip


func equipment_chip(item: Dictionary) -> PanelContainer:
	var chip := panel(VBoxContainer.new(), Color("#0d1530"), 12, 10)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := chip.get_child(0) as VBoxContainer
	var slot_label := label(slot_name(str(item.slot)).to_upper(), UIDesignSystem.FONT_CAPTION, MUTED)
	slot_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(slot_label)
	var item_label := label("%s  ·  +%d" % [EquipmentPresentationScript.localized_item_field(item, "name"), int(item.power)], UIDesignSystem.FONT_BODY, INK)
	item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(item_label)
	if int(item.get("integrity_upgrades", 0)) > 0:
		var integrity_label := label(UILocaleRulesScript.text("EQUIPMENT_INTEGRITY", "REFORÇO +%d VIDA", [int(item.integrity_upgrades) * CoreRules.INTEGRITY_HEALTH_PER_LEVEL]), UIDesignSystem.FONT_CAPTION, CYAN)
		integrity_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(integrity_label)
	return chip


func slot_name(slot: String) -> String:
	return CoreRules.equipment_slot_name(slot)
