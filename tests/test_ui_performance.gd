extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")

const BUILD_ITERATIONS := 120
const BUILD_BUDGET_USEC := 450000

var failures := 0


func _init() -> void:
	var factory = FactoryScript.new()
	root.add_child(factory)
	build_representative_controls(factory, 2)
	var warm_cache_sizes := cache_sizes(factory)
	var started := Time.get_ticks_usec()
	build_representative_controls(factory, BUILD_ITERATIONS)
	var elapsed := Time.get_ticks_usec() - started
	var final_cache_sizes := cache_sizes(factory)
	check(final_cache_sizes == warm_cache_sizes, "repeated UI rebuilds stop allocating style resources after warm-up")
	check(elapsed <= BUILD_BUDGET_USEC, "%d representative cached rebuilds remain within the mobile allocation budget (%d us)" % [BUILD_ITERATIONS, elapsed])
	check(factory._flat_style_cache.size() <= 20, "plain and button base fills remain a small bounded cache")
	check(factory._button_style_cache.size() <= 20, "button states remain a small bounded cache")
	factory.free()
	if failures == 0:
		print("PASS: UI style caches stabilize and %d representative rebuilds complete in %d us" % [BUILD_ITERATIONS, elapsed])
	quit(1 if failures > 0 else 0)


func build_representative_controls(factory, iterations: int) -> void:
	for index in iterations:
		var accent: Color = factory.CYAN if index % 2 == 0 else factory.GOLD
		var panel: Control = factory.panel(VBoxContainer.new(), factory.PANEL, 12, 10)
		var illustrated: Control = factory.illustrated_panel(VBoxContainer.new(), 22)
		var supporting: Control = factory.supporting_panel(VBoxContainer.new(), factory.PANEL_LIGHT, 24)
		var primary: Control = factory.primary_action("ACTION", accent)
		var secondary: Control = factory.secondary_action("DETAILS", accent)
		panel.free()
		illustrated.free()
		supporting.free()
		primary.free()
		secondary.free()


func cache_sizes(factory) -> Array[int]:
	return [
		factory._flat_style_cache.size(),
		factory._support_style_cache.size(),
		factory._illustrated_style_cache.size(),
		factory._supporting_frame_style_cache.size(),
		factory._button_style_cache.size(),
	]


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
