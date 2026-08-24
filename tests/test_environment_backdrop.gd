extends SceneTree

const EnvironmentBackdropScript = preload("res://scripts/environment_backdrop.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var backdrop := EnvironmentBackdropScript.new()
	root.add_child(backdrop)
	await process_frame
	backdrop.show_context("contracts")
	check(backdrop.visible, "original contract environment is available in exported and headless builds")
	check(backdrop.loaded_context == "contracts", "environment loads only the requested contract context")
	check(backdrop.texture_rect.texture != null, "contract environment resolves its imported texture")
	check(maxi(backdrop.texture_rect.texture.get_width(), backdrop.texture_rect.texture.get_height()) <= 1280, "contract environment stays within the Android-first texture budget")
	backdrop.show_context("world")
	check(backdrop.visible and backdrop.texture_rect.texture != null, "original galaxy and career environment is runtime-ready")
	check(maxi(backdrop.texture_rect.texture.get_width(), backdrop.texture_rect.texture.get_height()) <= 1280, "galaxy environment stays within the Android-first texture budget")
	backdrop.show_context("workshop")
	check(backdrop.visible and backdrop.texture_rect.texture != null, "original arsenal environment is runtime-ready")
	check(maxi(backdrop.texture_rect.texture.get_width(), backdrop.texture_rect.texture.get_height()) <= 1280, "arsenal environment stays within the Android-first texture budget")
	backdrop.show_context("combat")
	check(backdrop.visible and backdrop.texture_rect.texture != null, "original combat environment is runtime-ready")
	check(maxi(backdrop.texture_rect.texture.get_width(), backdrop.texture_rect.texture.get_height()) <= 1280, "combat environment stays within the Android-first texture budget")
	backdrop.show_context("unknown")
	check(not backdrop.visible and backdrop.texture_rect.texture == null and backdrop.loaded_context.is_empty(), "unknown contexts release the prior texture and fail closed")
	backdrop.queue_free()
	if failures == 0:
		print("PASS: original environment backgrounds are runtime-ready")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
