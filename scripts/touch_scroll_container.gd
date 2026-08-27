class_name TouchScrollContainer
extends ScrollContainer

var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _last_touch_position := Vector2.ZERO
var _is_dragging := false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index < 0 and get_global_rect().has_point(touch.position):
				_touch_index = touch.index
				_touch_origin = touch.position
				_last_touch_position = touch.position
				_is_dragging = false
		elif touch.index == _touch_index:
			if _is_dragging:
				get_viewport().set_input_as_handled()
			reset_touch_drag()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		if not _is_dragging and drag.position.distance_to(_touch_origin) >= float(scroll_deadzone):
			_is_dragging = true
		if _is_dragging:
			var movement := drag.position - _last_touch_position
			scroll_vertical -= roundi(movement.y)
			get_viewport().set_input_as_handled()
		_last_touch_position = drag.position


func reset_touch_drag() -> void:
	_touch_index = -1
	_touch_origin = Vector2.ZERO
	_last_touch_position = Vector2.ZERO
	_is_dragging = false
