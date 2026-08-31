class_name TouchScrollContainer
extends ScrollContainer

const VERTICAL_GESTURE_BIAS := 1.15
const INERTIA_START_SPEED := 120.0
const INERTIA_STOP_SPEED := 18.0
const INERTIA_DECAY := 7.0
const MAX_INERTIA_SPEED := 4200.0
const RELEASE_INERTIA_TIMEOUT_USEC := 140000

var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _last_touch_position := Vector2.ZERO
var _is_dragging := false
var _gesture_rejected := false
var _last_drag_usec := 0
var _velocity_y := 0.0
var _inertia_position := 0.0


func _ready() -> void:
	_hide_scroll_rails()
	set_process(false)
	visibility_changed.connect(reset_touch_drag)
	# Most lists are assembled before their first frame, but defer once so cards
	# added immediately after the scroller also participate in finger dragging.
	call_deferred("_prepare_touch_descendants")


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index < 0 and get_global_rect().has_point(touch.position):
				stop_inertia()
				_touch_index = touch.index
				_touch_origin = touch.position
				_last_touch_position = touch.position
				_is_dragging = false
				_gesture_rejected = false
				_last_drag_usec = Time.get_ticks_usec()
		elif touch.index == _touch_index:
			if _is_dragging:
				get_viewport().set_input_as_handled()
				start_inertia()
			reset_touch_pointer()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index or _gesture_rejected:
			return
		if not _is_dragging:
			var gesture := drag.position - _touch_origin
			if gesture.length() < float(scroll_deadzone):
				return
			if absf(gesture.y) < absf(gesture.x) * VERTICAL_GESTURE_BIAS:
				_gesture_rejected = true
				return
			_is_dragging = true
			_inertia_position = float(scroll_vertical)
		if _is_dragging:
			var movement := drag.position - _last_touch_position
			var now_usec := Time.get_ticks_usec()
			var elapsed := maxf(float(now_usec - _last_drag_usec) / 1000000.0, 0.001)
			var sampled_velocity := clampf(movement.y / elapsed, -MAX_INERTIA_SPEED, MAX_INERTIA_SPEED)
			_velocity_y = lerpf(_velocity_y, sampled_velocity, 0.72)
			_inertia_position = clampf(_inertia_position - movement.y, 0.0, maximum_scroll())
			scroll_vertical = roundi(_inertia_position)
			get_viewport().set_input_as_handled()
		_last_touch_position = drag.position
		_last_drag_usec = Time.get_ticks_usec()


func reset_touch_drag() -> void:
	stop_inertia()
	reset_touch_pointer()


func reset_touch_pointer() -> void:
	_touch_index = -1
	_touch_origin = Vector2.ZERO
	_last_touch_position = Vector2.ZERO
	_is_dragging = false
	_gesture_rejected = false
	_last_drag_usec = 0


func start_inertia() -> void:
	_inertia_position = float(scroll_vertical)
	var release_delay := Time.get_ticks_usec() - _last_drag_usec
	if release_delay > RELEASE_INERTIA_TIMEOUT_USEC or absf(_velocity_y) < INERTIA_START_SPEED or maximum_scroll() <= 0.0:
		stop_inertia()
		return
	set_process(true)


func stop_inertia() -> void:
	_velocity_y = 0.0
	_inertia_position = float(scroll_vertical)
	set_process(false)


func maximum_scroll() -> float:
	var bar := get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)


func _process(delta: float) -> void:
	if not is_visible_in_tree() or absf(_velocity_y) < INERTIA_STOP_SPEED:
		stop_inertia()
		return
	var maximum := maximum_scroll()
	var previous := _inertia_position
	_inertia_position = clampf(_inertia_position - _velocity_y * delta, 0.0, maximum)
	scroll_vertical = roundi(_inertia_position)
	if is_equal_approx(_inertia_position, previous) or _inertia_position <= 0.0 or _inertia_position >= maximum:
		stop_inertia()
		return
	_velocity_y *= exp(-INERTIA_DECAY * delta)


func _hide_scroll_rails() -> void:
	for bar in [get_v_scroll_bar(), get_h_scroll_bar()]:
		bar.modulate = Color.TRANSPARENT
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2.ZERO


func _prepare_touch_descendants() -> void:
	_prepare_control_tree(self)


func _prepare_control_tree(root: Control) -> void:
	for child in root.get_children():
		if not child is Control or child is ScrollBar:
			continue
		var control := child as Control
		if child is Container or child is BaseButton:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		elif not child is LineEdit and not child is TextEdit and not child is Slider:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if control.get_child_count() > 0:
			_prepare_control_tree(control)
