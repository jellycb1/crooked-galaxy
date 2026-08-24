extends SceneTree

const ReferenceBackdrop = preload("res://scripts/reference_placeholder_backdrop.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)


func run() -> void:
	var backdrop := ReferenceBackdrop.new()
	root.add_child(backdrop)
	await process_frame
	check(backdrop.CONTEXT_PATHS.size() == 5, "all documented composition placeholders keep an explicit context mapping")
	for context in ["contracts", "world", "workshop", "combat", "class_ui"]:
		check(FileAccess.file_exists(str(backdrop.CONTEXT_PATHS[context])), "documented local placeholder exists for '%s'" % context)
	check(backdrop.UI_PATHS.size() == 3, "the provisional class trio has three explicit internal icon mappings")
	for class_id in backdrop.UI_PATHS:
		check(FileAccess.file_exists(str(backdrop.UI_PATHS[class_id])), "documented local class icon exists for '%s'" % class_id)
	check(not backdrop.local_placeholders_allowed(), "headless validation never decodes visual placeholders")
	for context in ["contracts", "world", "workshop", "combat", "class_ui", "unknown"]:
		backdrop.show_context(context)
		check(not backdrop.visible, "headless context '%s' keeps the placeholder hidden" % context)
	check(backdrop.loaded_source_path.is_empty() and backdrop.texture_rect.texture == null, "headless validation does not retain a decoded reference image")
	var decoded := backdrop.load_local_texture(str(backdrop.CONTEXT_PATHS.contracts))
	check(decoded != null, "registered local PNG can be decoded by the same runtime path used in the editor")
	backdrop.texture_rect.texture = decoded
	backdrop.loaded_source_path = str(backdrop.CONTEXT_PATHS.contracts)
	backdrop.release_texture()
	check(backdrop.texture_rect.texture == null and backdrop.loaded_source_path.is_empty(), "placeholder release drops the only decoded texture reference")
	backdrop.queue_free()
	if failures == 0:
		print("PASS: reference placeholders are mapped, documented, and headless-safe")
	quit(1 if failures > 0 else 0)
