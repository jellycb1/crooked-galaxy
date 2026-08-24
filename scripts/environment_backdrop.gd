class_name EnvironmentBackdrop
extends Control

const CONTEXT_TEXTURES := {
	"contracts": preload("res://assets/backgrounds/bounty_office.png"),
	"world": preload("res://assets/backgrounds/frontier_spaceport.png"),
	"workshop": preload("res://assets/backgrounds/arsenal_workshop.png"),
	"combat": preload("res://assets/backgrounds/frontier_arena.png"),
}

var texture_rect: TextureRect
var scrim: ColorRect


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
	if not CONTEXT_TEXTURES.has(context):
		visible = false
		return
	texture_rect.texture = CONTEXT_TEXTURES[context]
	scrim.color = Color(0.015, 0.025, 0.075, 0.72 if context == "world" or context == "workshop" else (0.52 if context == "combat" else 0.60))
	visible = true
