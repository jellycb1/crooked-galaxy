class_name ReferencePlaceholderBackdrop
extends Control

const SOURCE_ROOT := "res://References/Shakes and Fidget Assets/StreamingAssets/"
const CONTEXT_PATHS := {
	"contracts": SOURCE_ROOT + "tavern/tavern_back.png",
	"world": SOURCE_ROOT + "town/bg_town_day.png",
	"workshop": SOURCE_ROOT + "locations/bg_fort_0.png",
	"combat": SOURCE_ROOT + "locations/location_battle_0.png",
}

var texture_rect: TextureRect
var scrim: ColorRect
var notice: Label
var texture_cache: Dictionary = {}


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
	notice.text = "PLACEHOLDER INTERNO · NÃO EXPORTÁVEL"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice.add_theme_font_size_override("font_size", 10)
	notice.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25, 0.78))
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notice)

	visible = false


func show_context(context: String) -> void:
	if not local_placeholders_allowed() or not CONTEXT_PATHS.has(context):
		visible = false
		return
	var source_path := str(CONTEXT_PATHS[context])
	var texture := load_local_texture(source_path)
	if texture == null:
		visible = false
		return
	texture_rect.texture = texture
	scrim.color = Color(0.015, 0.025, 0.075, 0.76 if context == "world" or context == "workshop" else (0.58 if context == "combat" else 0.66))
	visible = true


func local_placeholders_allowed() -> bool:
	return OS.has_feature("editor") and DisplayServer.get_name() != "headless"


func load_local_texture(source_path: String) -> Texture2D:
	if texture_cache.has(source_path):
		return texture_cache[source_path] as Texture2D
	var absolute_path := ProjectSettings.globalize_path(source_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	if image.load(absolute_path) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	texture_cache[source_path] = texture
	return texture
