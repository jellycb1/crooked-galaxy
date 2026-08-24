class_name ReferencePlaceholderBackdrop
extends Control

const SOURCE_ROOT := "res://References/Shakes and Fidget Assets/StreamingAssets/"
const CONTEXT_PATHS := {
	"contracts": SOURCE_ROOT + "tavern/tavern_back.png",
	"world": SOURCE_ROOT + "town/bg_town_day.png",
	"workshop": SOURCE_ROOT + "locations/bg_fort_0.png",
	"combat": SOURCE_ROOT + "locations/location_battle_0.png",
	"class_ui": SOURCE_ROOT + "ui/sf_4k_UI-BG-navi.png",
	"career_ui": SOURCE_ROOT + "ui/sf_4k_UI-BG-navi-login.png",
}
const INTERNAL_CONTEXT_PATHS := {
	"contracts": "res://internal_reference_assets/contracts.png.bin",
	"world": "res://internal_reference_assets/world.png.bin",
	"workshop": "res://internal_reference_assets/workshop.png.bin",
	"combat": "res://internal_reference_assets/combat.png.bin",
	"class_ui": "res://internal_reference_assets/class_ui.png.bin",
	"career_ui": "res://internal_reference_assets/career_ui.png.bin",
}
const UI_PATHS := {
	"warrant_breaker": SOURCE_ROOT + "registration/icon_warrior_active.png",
	"orbit_gunslinger": SOURCE_ROOT + "registration/icon_hunter_active.png",
	"contract_hacker": SOURCE_ROOT + "registration/icon_mage_active.png",
	"portrait_frame": SOURCE_ROOT + "z_shared/portrait_glow_border_300.png",
	"hub_divider": SOURCE_ROOT + "ui/frame_top.png",
}
const INTERNAL_UI_PATHS := {
	"warrant_breaker": "res://internal_reference_assets/class_breaker.png.bin",
	"orbit_gunslinger": "res://internal_reference_assets/class_gunslinger.png.bin",
	"contract_hacker": "res://internal_reference_assets/class_hacker.png.bin",
	"portrait_frame": "res://internal_reference_assets/portrait_frame.png.bin",
	"hub_divider": "res://internal_reference_assets/hub_divider.png.bin",
}

var texture_rect: TextureRect
var scrim: ColorRect
var notice: Label
var loaded_source_path := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	texture_rect = TextureRect.new()
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)

	scrim = ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.015, 0.025, 0.075, 0.66)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	notice = Label.new()
	notice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	notice.offset_top = -24.0
	notice.offset_bottom = -6.0
	notice.offset_left = 8.0
	notice.offset_right = -8.0
	notice.text = "PLACEHOLDER INTERNO · SUBSTITUIR"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice.add_theme_font_size_override("font_size", 10)
	notice.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25, 0.78))
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notice)

	visible = false


func show_context(context: String) -> void:
	if not local_placeholders_allowed() or not CONTEXT_PATHS.has(context):
		release_texture()
		return
	var source_path := str(INTERNAL_CONTEXT_PATHS[context] if OS.has_feature("reference_placeholders") else CONTEXT_PATHS[context])
	if source_path == loaded_source_path and texture_rect.texture != null:
		visible = true
		return
	var texture := load_local_texture(source_path)
	if texture == null:
		release_texture()
		return
	texture_rect.texture = texture
	loaded_source_path = source_path
	scrim.color = Color(0.015, 0.025, 0.075, 0.38 if context == "class_ui" or context == "career_ui" else (0.76 if context == "world" or context == "workshop" else (0.58 if context == "combat" else 0.66)))
	visible = true


func ui_texture(key: String) -> Texture2D:
	if not local_placeholders_allowed() or not UI_PATHS.has(key):
		return null
	var source_path := str(INTERNAL_UI_PATHS[key] if OS.has_feature("reference_placeholders") else UI_PATHS[key])
	return load_local_texture(source_path)


func local_placeholders_allowed() -> bool:
	return (OS.has_feature("editor") or OS.has_feature("reference_placeholders")) and DisplayServer.get_name() != "headless"


func load_local_texture(source_path: String) -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(source_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	if source_path.ends_with(".png.bin"):
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(source_path)) != OK:
			return null
	elif image.load(absolute_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func release_texture() -> void:
	if texture_rect != null:
		texture_rect.texture = null
	loaded_source_path = ""
	visible = false
