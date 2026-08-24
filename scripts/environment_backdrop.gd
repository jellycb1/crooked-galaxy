class_name EnvironmentBackdrop
extends Control

const CONTEXT_PATHS := {
	"contracts": "res://assets/backgrounds/bounty_office.png",
	"world": "res://assets/backgrounds/frontier_spaceport.png",
	"workshop": "res://assets/backgrounds/arsenal_workshop.png",
	"combat": "res://assets/backgrounds/frontier_arena.png",
}

var texture_rect: TextureRect
var scrim: ColorRect
var loaded_context := ""


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
	scrim.color = Color(0.015, 0.025, 0.075, 0.60)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	visible = false


func show_context(context: String) -> void:
	if not CONTEXT_PATHS.has(context):
		texture_rect.texture = null
		loaded_context = ""
		visible = false
		return
	if context != loaded_context:
		var texture := ResourceLoader.load(str(CONTEXT_PATHS[context]), "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		if texture == null:
			texture_rect.texture = null
			loaded_context = ""
			visible = false
			return
		texture_rect.texture = texture
		loaded_context = context
	scrim.color = Color(0.015, 0.025, 0.075, 0.72 if context == "world" or context == "workshop" else (0.52 if context == "combat" else 0.60))
	visible = true
