class_name RiftPortalVisual
extends Control

## Non-production, code-native fallback for validating the Rift unlock flow.
## Final portal rings, key and distortion layers remain external art deliveries.

signal stabilized

var progress := 0.0
var accent := Color("#d789ff")
var reduced_motion := false
var _duration := 2.8
var _emitted := false


func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func configure(color: Color, reduce_motion: bool) -> void:
	accent = color
	reduced_motion = reduce_motion
	_duration = 0.35 if reduced_motion else 2.8
	queue_redraw()


func complete_immediately() -> void:
	progress = 1.0
	set_process(false)
	queue_redraw()
	_emit_stabilized()


func _process(delta: float) -> void:
	progress = minf(1.0, progress + delta / _duration)
	queue_redraw()
	if progress >= 1.0:
		set_process(false)
		_emit_stabilized()


func _emit_stabilized() -> void:
	if _emitted:
		return
	_emitted = true
	stabilized.emit()


func _draw() -> void:
	var center := size * Vector2(0.5, 0.52)
	var radius := minf(size.x * 0.28, size.y * 0.38)
	var eased := smoothstep(0.0, 1.0, progress)
	var opening := clampf((progress - 0.28) / 0.72, 0.0, 1.0)
	var pulse := 0.0 if reduced_motion else sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5
	draw_circle(center, radius * opening, Color(accent, 0.05 + opening * 0.16))
	for ring_index in 3:
		var ring_progress := clampf(progress * 1.55 - float(ring_index) * 0.16, 0.0, 1.0)
		var ring_radius := radius + 13.0 + float(ring_index) * 12.0
		var rotation := float(ring_index + 1) * (eased * (0.75 if ring_index % 2 == 0 else -0.55))
		draw_arc(center, ring_radius, rotation - PI * 0.82, rotation - PI * 0.82 + TAU * ring_progress * 0.78, 48, Color(accent.lightened(float(ring_index) * 0.10), 0.48 + ring_progress * 0.42), 3.0 - float(ring_index) * 0.45, true)
	for segment in 8:
		var segment_progress := clampf(progress * 1.7 - float(segment) * 0.075, 0.0, 1.0)
		if segment_progress <= 0.0:
			continue
		var angle := float(segment) / 8.0 * TAU - PI * 0.5
		var direction := Vector2(cos(angle), sin(angle))
		var inner := center + direction * (radius + 3.0)
		var outer := center + direction * (radius + 17.0 + segment_progress * 4.0)
		draw_line(inner, outer, Color("#ffc857").lerp(accent, 0.45), 3.0, true)
	if opening > 0.0:
		var core_radius := radius * (0.18 + opening * 0.62)
		draw_circle(center, core_radius, Color("#071126").lerp(accent.darkened(0.72), opening * 0.42))
		draw_arc(center, core_radius * (0.76 + pulse * 0.04), 0.0, TAU, 56, Color(accent, 0.55 + pulse * 0.20), 2.0, true)
		for ray in 6:
			var angle := float(ray) / 6.0 * TAU + eased
			var start := center + Vector2(cos(angle), sin(angle)) * core_radius * 0.28
			var finish := center + Vector2(cos(angle + opening * 0.22), sin(angle + opening * 0.22)) * core_radius * 0.70
			draw_line(start, finish, Color(accent, 0.18 + opening * 0.24), 1.5, true)
	var key_y := lerpf(size.y * 0.12, center.y, clampf(progress / 0.32, 0.0, 1.0))
	if progress < 0.46:
		var key_alpha := 1.0 - clampf((progress - 0.32) / 0.14, 0.0, 1.0)
		var key_center := Vector2(center.x, key_y)
		draw_circle(key_center, 9.0, Color("#ffc857", key_alpha))
		draw_line(key_center + Vector2(0, 8), key_center + Vector2(0, 34), Color("#ffc857", key_alpha), 6.0, true)
		draw_line(key_center + Vector2(0, 25), key_center + Vector2(10, 25), Color("#ffc857", key_alpha), 5.0, true)
