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
	check(not backdrop.local_placeholders_allowed(), "headless validation never enables proprietary placeholders")
	for context in ["contracts", "world", "workshop", "combat", "unknown"]:
		backdrop.show_context(context)
		check(not backdrop.visible, "headless context '%s' keeps the placeholder hidden" % context)
	check(backdrop.texture_cache.is_empty(), "headless validation does not read local reference images")
	backdrop.queue_free()
	if failures == 0:
		print("PASS: reference placeholders remain interactive-editor-only")
	quit(1 if failures > 0 else 0)
