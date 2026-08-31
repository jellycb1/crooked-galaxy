class_name EnvironmentBackdrop
extends Control

const Catalog = preload("res://scripts/visual_asset_catalog.gd")

const CONTEXT_PATHS := {
	"contracts": "res://assets/backgrounds/bounty_office.png",
	"world": "res://assets/backgrounds/frontier_spaceport.png",
	"workshop": "res://assets/backgrounds/arsenal_workshop.png",
	"combat": "res://assets/backgrounds/frontier_arena.png",
}

var texture_rect: TextureRect
var arena_rect: TextureRect
var scrim: ColorRect
var loaded_context := ""
var loaded_planet := ""
var using_approved_planet := false
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

	arena_rect = TextureRect.new()
	arena_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arena_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	arena_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena_rect.visible = false
	add_child(arena_rect)

	scrim = ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.015, 0.025, 0.075, 0.60)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	visible = false


func show_context(context: String, planet_id := "") -> void:
	if not CONTEXT_PATHS.has(context):
		texture_rect.texture = null
		arena_rect.texture = null
		arena_rect.visible = false
		loaded_context = ""
		loaded_planet = ""
		using_approved_planet = false
		visible = false
		return
	if context == loaded_context and planet_id == loaded_planet and visible:
		return
	var supports_planet_art := context in ["contracts", "world", "combat"] and not planet_id.is_empty()
	var approved_planet := supports_planet_art and Catalog.approved_atomic_set_complete("planet_habitat", planet_id)
	if approved_planet:
		var habitat := Catalog.load_approved_texture("planet_habitat", planet_id)
		var arena := Catalog.load_approved_texture("planet_arena", planet_id) if context == "combat" else null
		if habitat != null and (context != "combat" or arena != null):
			texture_rect.texture = habitat
			arena_rect.texture = arena
			arena_rect.visible = arena != null
			using_approved_planet = true
		else:
			approved_planet = false
	if not approved_planet:
		arena_rect.texture = null
		arena_rect.visible = false
		if context != loaded_context or using_approved_planet or texture_rect.texture == null:
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
		using_approved_planet = false
	loaded_context = context
	loaded_planet = planet_id
	texture_rect.modulate = Color.WHITE if using_approved_planet else Color.WHITE.lerp(planet_tint(planet_id), 0.14)
	arena_rect.modulate = Color.WHITE
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
		"aeropolis_penhora": return Color("#8fd3ff")
		"arquivo_abissal_n9": return Color("#39d7c5")
		_: return Color.WHITE
