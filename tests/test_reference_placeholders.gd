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
	check(backdrop.CONTEXT_PATHS.size() == 4, "all documented composition placeholders keep an explicit context mapping")
	for context in ["contracts", "world", "workshop", "combat"]:
		check(FileAccess.file_exists(str(backdrop.CONTEXT_PATHS[context])), "documented local placeholder exists for '%s'" % context)
	check(not backdrop.local_placeholders_allowed(), "headless validation never decodes visual placeholders")
	for context in ["contracts", "world", "workshop", "combat", "unknown"]:
		backdrop.show_context(context)
		check(not backdrop.visible, "headless context '%s' keeps the placeholder hidden" % context)
	check(backdrop.texture_cache.is_empty(), "headless validation does not read local reference images")
	backdrop.queue_free()
	if failures == 0:
		print("PASS: reference placeholders are mapped, documented, and headless-safe")
	quit(1 if failures > 0 else 0)
