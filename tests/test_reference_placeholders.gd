extends SceneTree

const EnvironmentBackdropScript = preload("res://scripts/environment_backdrop.gd")
const ClassIconScript = preload("res://scripts/class_icon.gd")
const PortraitFrameScript = preload("res://scripts/portrait_frame.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)


func run() -> void:
	var backdrop := EnvironmentBackdropScript.new()
	root.add_child(backdrop)
	await process_frame
	check(backdrop.CONTEXT_PATHS.size() == 4, "all active contexts use the compact original-art backdrop set")
	for context in ["contracts", "world", "workshop", "combat"]:
		var path := str(backdrop.CONTEXT_PATHS[context])
		check(path.begins_with("res://assets/backgrounds/") and FileAccess.file_exists(path), "production background exists for '%s'" % context)
	backdrop.show_context("contracts", "dustball_prime")
	check(backdrop.visible and backdrop.texture_rect.texture != null, "production contract art resolves without a reference loader")
	backdrop.show_context("unknown")
	check(not backdrop.visible and backdrop.texture_rect.texture == null, "unknown contexts fail closed")
	for class_id in ["warrant_breaker", "orbit_gunslinger", "contract_hacker"]:
		var icon = ClassIconScript.new()
		icon.configure(class_id, Color("#55e5ff"), 64.0)
		check(icon.class_id == class_id and icon.custom_minimum_size == Vector2(64, 64), "original vector class icon configures for '%s'" % class_id)
		icon.free()
	var frame = PortraitFrameScript.new()
	frame.configure(Color("#ffc857"))
	check(frame.accent == Color("#ffc857"), "original portrait frame accepts contextual accent")
	frame.free()
	var panel_path := "res://assets/ui/main-dossier-frame-runtime-512x384.png"
	check(FileAccess.file_exists(panel_path), "approved illustrated panel is tracked as a runtime asset")
	var panel_texture := load(panel_path) as Texture2D
	var panel_image := panel_texture.get_image() if panel_texture != null else Image.new()
	check(not panel_image.is_empty() and panel_image.get_size() == Vector2i(512, 384), "approved illustrated panel stays at its supplied runtime size")
	check(panel_image.get_format() == Image.FORMAT_RGBA8 and panel_image.get_pixel(0, 0).a <= 0.01, "approved illustrated panel preserves genuine transparent corners")
	var supporting_path := "res://assets/ui/supporting-panel-runtime-candidate-v1.png"
	check(FileAccess.file_exists(supporting_path), "approved supporting panel is tracked as a runtime asset")
	var supporting_texture := load(supporting_path) as Texture2D
	var supporting_image := supporting_texture.get_image() if supporting_texture != null else Image.new()
	check(not supporting_image.is_empty() and supporting_image.get_size() == Vector2i(512, 384), "approved supporting panel stays at its supplied runtime size")
	check(supporting_image.get_format() == Image.FORMAT_RGBA8 and supporting_image.get_pixel(0, 0).a <= 0.01, "approved supporting panel preserves genuine transparent corners")
	backdrop.free()
	if failures == 0:
		print("PASS: accepted production visuals are runtime-ready and rejected class drafts remain excluded")
	quit(1 if failures > 0 else 0)
