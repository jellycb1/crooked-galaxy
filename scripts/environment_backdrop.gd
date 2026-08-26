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
var loaded_planet := ""
var texture_cache: Dictionary = {}
var threaded_contexts: Dictionary = {}


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


func show_context(context: String, planet_id := "") -> void:
	if not CONTEXT_PATHS.has(context):
		texture_rect.texture = null
		loaded_context = ""
		loaded_planet = ""
		visible = false
		return
	if context == loaded_context and planet_id == loaded_planet and visible:
		return
	if context != loaded_context:
		var texture := texture_cache.get(context) as Texture2D
		if texture == null:
			var path := str(CONTEXT_PATHS[context])
			if threaded_contexts.has(context):
				var status := ResourceLoader.load_threaded_get_status(path)
				if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
					texture = ResourceLoader.load_threaded_get(path) as Texture2D
				threaded_contexts.erase(context)
			if texture == null:
				texture = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if texture == null:
			texture_rect.texture = null
			loaded_context = ""
			loaded_planet = ""
			visible = false
			return
		texture_cache[context] = texture
		texture_rect.texture = texture
		loaded_context = context
	loaded_planet = planet_id
	texture_rect.modulate = Color.WHITE.lerp(planet_tint(planet_id), 0.14)
	scrim.color = Color(0.015, 0.025, 0.075, 0.72 if context == "world" or context == "workshop" else (0.52 if context == "combat" else 0.60))
	visible = true


func prefetch_context(context: String) -> void:
	if not CONTEXT_PATHS.has(context) or texture_cache.has(context) or threaded_contexts.has(context):
		return
	var path := str(CONTEXT_PATHS[context])
	if ResourceLoader.has_cached(path):
		return
	# One worker is enough for a single portrait texture and avoids stealing main
	# thread time on modest Android CPUs. show_context() consumes this exact request.
	if ResourceLoader.load_threaded_request(path, "Texture2D", false, ResourceLoader.CACHE_MODE_REUSE) == OK:
		threaded_contexts[context] = true


func planet_tint(planet_id: String) -> Color:
	match planet_id:
		"dustball_prime": return Color("#ffc857")
		"congelaria_sa": return Color("#72f1dd")
		"micelia_404": return Color("#b8f45d")
		"ferro_velho_omega": return Color("#ff9f43")
		"cassino_quasar": return Color("#ff75d8")
		_: return Color.WHITE
