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
	backdrop.free()
	if failures == 0:
		print("PASS: production visuals are original, runtime-ready, and reference-free")
	quit(1 if failures > 0 else 0)
