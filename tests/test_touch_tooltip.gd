extends SceneTree

const TouchTooltipLayerScript = preload("res://scripts/touch_tooltip_layer.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var target := Button.new()
	target.text = "ALVO"
	target.tooltip_text = "Informação longa acessível por toque prolongado."
	target.position = Vector2(40, 40)
	target.size = Vector2(180, 72)
	root.add_child(target)
	var layer = TouchTooltipLayerScript.new()
	root.add_child(layer)
	await process_frame
	layer.bind_scope(target)
	check(bool(target.get_meta("touch_tooltip_bound", false)), "touch tooltip manager binds eligible Android controls once")
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = Vector2(60, 60)
	target.gui_input.emit(press)
	await create_timer(0.62).timeout
	var popup := layer.find_child("TouchTooltipPanel", true, false) as PanelContainer
	var label := layer.find_child("TouchTooltipText", true, false) as Label
	check(popup != null and popup.is_visible_in_tree() and label.text == target.tooltip_text, "long press reveals the supplied tooltip frame with complete text")
	layer.dismiss()
	check(not popup.is_visible_in_tree(), "tooltip dismissal clears the touch-blocking overlay")
	target.free()
	layer.free()
	if failures == 0:
		print("PASS: Android long-press tooltips are safe and readable")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
