class_name TouchTooltipLayer
extends CanvasLayer

const Catalog = preload("res://scripts/visual_asset_catalog.gd")

const HOLD_SECONDS := 0.55
const MOVE_CANCEL_DISTANCE := 18.0
const TOOLTIP_MIN_SIZE := Vector2(420, 176)
const SCREEN_MARGIN := 24.0

var _timer: Timer
var _blocker: Control
var _panel: PanelContainer
var _label: Label
var _pending_control: WeakRef
var _press_position := Vector2.ZERO


func _ready() -> void:
	layer = 80
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = HOLD_SECONDS
	_timer.timeout.connect(_show_pending)
	add_child(_timer)
	_blocker = Control.new()
	_blocker.name = "TouchTooltipDismissLayer"
	_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.gui_input.connect(_on_blocker_input)
	_blocker.hide()
	add_child(_blocker)
	_panel = PanelContainer.new()
	_panel.name = "TouchTooltipPanel"
	_panel.custom_minimum_size = TOOLTIP_MIN_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = Catalog.load_texture("runtime", "tooltip_frame")
	style.texture_margin_left = 64
	style.texture_margin_right = 40
	style.texture_margin_top = 36
	style.texture_margin_bottom = 48
	style.content_margin_left = 54
	style.content_margin_right = 36
	style.content_margin_top = 30
	style.content_margin_bottom = 44
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_panel.add_theme_stylebox_override("panel", style)
	_blocker.add_child(_panel)
	_label = Label.new()
	_label.name = "TouchTooltipText"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 21)
	_label.add_theme_color_override("font_color", Color("#f4f2ff"))
	_panel.add_child(_label)


func bind_scope(scope: Node) -> void:
	if scope == null:
		return
	var controls: Array[Node] = []
	if scope is Control:
		controls.append(scope)
	controls.append_array(scope.find_children("*", "Control", true, false))
	for node in controls:
		var control := node as Control
		if control == null or control.tooltip_text.strip_edges().is_empty() or control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if bool(control.get_meta("touch_tooltip_bound", false)):
			continue
		control.set_meta("touch_tooltip_bound", true)
		control.gui_input.connect(_on_control_input.bind(control))


func dismiss() -> void:
	_timer.stop()
	_pending_control = null
	if _blocker != null:
		_blocker.hide()


func _on_control_input(event: InputEvent, control: Control) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_position = event.position
			_pending_control = weakref(control)
			_timer.start()
		else:
			_timer.stop()
			_pending_control = null
	elif event is InputEventScreenDrag and event.position.distance_to(_press_position) > MOVE_CANCEL_DISTANCE:
		_timer.stop()
		_pending_control = null


func _show_pending() -> void:
	var control := _pending_control.get_ref() as Control if _pending_control != null else null
	_pending_control = null
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return
	var text := control.tooltip_text.strip_edges()
	if text.is_empty():
		return
	_label.text = text
	_blocker.show()
	_panel.reset_size()
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size
	var desired := Vector2(control.global_position.x, control.global_position.y + control.size.y + 12.0)
	if desired.y + _panel.size.y > viewport_size.y - SCREEN_MARGIN:
		desired.y = control.global_position.y - _panel.size.y - 12.0
	desired.x = clampf(desired.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.x - _panel.size.x - SCREEN_MARGIN))
	desired.y = clampf(desired.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.y - _panel.size.y - SCREEN_MARGIN))
	_panel.position = desired


func _on_blocker_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		dismiss()
