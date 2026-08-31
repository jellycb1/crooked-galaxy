extends SceneTree

const TouchScroll = preload("res://scripts/touch_scroll_container.gd")

var failures := 0
var host: Control
var scroller: TouchScrollContainer


func _init() -> void:
	call_deferred("run")


func run() -> void:
	host = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	scroller = TouchScroll.new()
	scroller.position = Vector2(20, 20)
	scroller.size = Vector2(410, 500)
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	host.add_child(scroller)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(410, 1500)
	scroller.add_child(list)
	var action := Button.new()
	action.custom_minimum_size = Vector2(400, 80)
	list.add_child(action)
	await process_frame
	await process_frame

	check(scroller.get_v_scroll_bar().modulate.a == 0.0 and scroller.get_v_scroll_bar().mouse_filter == Control.MOUSE_FILTER_IGNORE, "touch lists hide their scroll rail without leaving an input blocker")
	check(action.mouse_filter == Control.MOUSE_FILTER_PASS, "interactive descendants remain touchable inside a finger-scroll list")

	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = Vector2(220, 360)
	down.pressed = true
	scroller._input(down)
	var horizontal := InputEventScreenDrag.new()
	horizontal.index = 0
	horizontal.position = Vector2(330, 365)
	scroller._input(horizontal)
	check(scroller.scroll_vertical == 0 and not scroller.is_processing(), "a horizontal gesture is not stolen by the vertical list")
	var horizontal_up := InputEventScreenTouch.new()
	horizontal_up.index = 0
	horizontal_up.position = horizontal.position
	horizontal_up.pressed = false
	scroller._input(horizontal_up)

	down.position = Vector2(220, 400)
	scroller._input(down)
	var vertical := InputEventScreenDrag.new()
	vertical.index = 0
	vertical.position = Vector2(218, 270)
	scroller._input(vertical)
	check(scroller.scroll_vertical >= 120, "an upward finger drag moves a tall list without a visible scrollbar")
	var dragged_position := scroller.scroll_vertical
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = vertical.position
	up.pressed = false
	scroller._input(up)
	check(scroller.is_processing(), "a decisive vertical drag starts bounded kinetic scrolling")
	scroller._process(0.05)
	check(scroller.scroll_vertical > dragged_position, "kinetic scrolling continues in the release direction")

	down.position = Vector2(220, 300)
	scroller._input(down)
	check(not scroller.is_processing(), "a new touch stops kinetic movement immediately")
	scroller.reset_touch_drag()
	check(not scroller.is_processing(), "resetting a recycled list clears all kinetic work")

	host.queue_free()
	if failures == 0:
		print("PASS: touch scrolling is rail-free, axis-aware, and kinetic")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
