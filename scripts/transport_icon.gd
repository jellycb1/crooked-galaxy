class_name TransportIcon
extends Control

var transport_id := ""
var accent := Color("#55e5ff")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	var ink := Color("#071024")
	draw_circle(Vector2(0.50, 0.50), 0.45, Color(accent, 0.10))
	draw_arc(Vector2(0.50, 0.50), 0.43, -2.55, 0.55, 28, Color(accent, 0.38), 0.025, true)
	match transport_id:
		"licensed_junkbox":
			draw_junkbox(ink)
		"cloned_warp_taxi":
			draw_taxi(ink)
		"repo_interceptor":
			draw_interceptor(ink)
		"executive_escape_yacht":
			draw_yacht(ink)
		_:
			draw_empty(ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_junkbox(ink: Color) -> void:
	var hull := PackedVector2Array([Vector2(0.13, 0.41), Vector2(0.27, 0.29), Vector2(0.72, 0.32), Vector2(0.88, 0.47), Vector2(0.77, 0.68), Vector2(0.25, 0.71), Vector2(0.11, 0.59)])
	filled_polygon(hull, accent.darkened(0.20), ink)
	filled_polygon([Vector2(0.34, 0.30), Vector2(0.42, 0.18), Vector2(0.66, 0.20), Vector2(0.73, 0.33)], Color("#26385d"), ink)
	for x in [0.34, 0.52, 0.70]:
		draw_circle(Vector2(x, 0.49), 0.055, Color("#b9f7ff"))
		draw_arc(Vector2(x, 0.49), 0.055, 0.0, TAU, 14, ink, 0.018, true)
	draw_line(Vector2(0.18, 0.67), Vector2(0.10, 0.82), ink, 0.045, true)
	draw_line(Vector2(0.79, 0.66), Vector2(0.86, 0.79), ink, 0.045, true)
	draw_line(Vector2(0.29, 0.28), Vector2(0.22, 0.18), accent, 0.035, true)
	draw_circle(Vector2(0.21, 0.16), 0.035, Color("#ff6f7d"))


func draw_taxi(ink: Color) -> void:
	filled_polygon([Vector2(0.10, 0.48), Vector2(0.25, 0.34), Vector2(0.73, 0.32), Vector2(0.91, 0.47), Vector2(0.78, 0.65), Vector2(0.23, 0.68)], accent.darkened(0.28), ink)
	filled_polygon([Vector2(0.30, 0.35), Vector2(0.39, 0.21), Vector2(0.65, 0.20), Vector2(0.74, 0.34)], Color("#b9f7ff"), ink)
	filled_polygon([Vector2(0.42, 0.20), Vector2(0.46, 0.11), Vector2(0.61, 0.11), Vector2(0.65, 0.20)], Color("#ffc857"), ink)
	for x in [0.24, 0.78]:
		draw_circle(Vector2(x, 0.67), 0.10, ink)
		draw_circle(Vector2(x, 0.67), 0.055, accent)
	draw_line(Vector2(0.16, 0.50), Vector2(0.83, 0.48), Color("#ffc857"), 0.038, true)


func draw_interceptor(ink: Color) -> void:
	filled_polygon([Vector2(0.08, 0.53), Vector2(0.42, 0.30), Vector2(0.88, 0.16), Vector2(0.74, 0.50), Vector2(0.91, 0.78), Vector2(0.42, 0.66)], accent.darkened(0.20), ink)
	filled_polygon([Vector2(0.39, 0.43), Vector2(0.69, 0.30), Vector2(0.62, 0.51), Vector2(0.70, 0.64), Vector2(0.39, 0.57)], Color("#f8e7b0"), ink)
	draw_line(Vector2(0.19, 0.49), Vector2(0.08, 0.31), ink, 0.050, true)
	draw_line(Vector2(0.19, 0.58), Vector2(0.07, 0.74), ink, 0.050, true)
	draw_line(Vector2(0.09, 0.31), Vector2(0.18, 0.25), Color("#ff6f7d"), 0.030, true)
	draw_line(Vector2(0.08, 0.74), Vector2(0.17, 0.80), Color("#55e5ff"), 0.030, true)
	draw_circle(Vector2(0.34, 0.54), 0.045, Color("#071024"))


func draw_yacht(ink: Color) -> void:
	filled_polygon([Vector2(0.08, 0.57), Vector2(0.30, 0.44), Vector2(0.70, 0.28), Vector2(0.92, 0.35), Vector2(0.76, 0.61), Vector2(0.35, 0.72), Vector2(0.14, 0.67)], accent.darkened(0.25), ink)
	filled_polygon([Vector2(0.35, 0.44), Vector2(0.49, 0.24), Vector2(0.72, 0.28), Vector2(0.66, 0.43)], Color("#eadcff"), ink)
	filled_polygon([Vector2(0.30, 0.66), Vector2(0.43, 0.81), Vector2(0.61, 0.65)], accent, ink)
	draw_line(Vector2(0.17, 0.58), Vector2(0.77, 0.43), Color("#ffc857"), 0.032, true)
	for x in [0.40, 0.53, 0.66]:
		draw_circle(Vector2(x, 0.54 - (x - 0.40) * 0.24), 0.035, Color("#55e5ff"))
	draw_arc(Vector2(0.84, 0.54), 0.17, -1.5, 1.6, 18, accent.lightened(0.18), 0.045, true)


func draw_empty(ink: Color) -> void:
	draw_line(Vector2(0.25, 0.50), Vector2(0.75, 0.50), ink, 0.08, true)
	draw_line(Vector2(0.50, 0.25), Vector2(0.50, 0.75), accent, 0.05, true)


func filled_polygon(points: Array[Vector2], fill: Color, outline: Color) -> void:
	var polygon := PackedVector2Array(points)
	draw_colored_polygon(polygon, fill)
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, outline, 0.032, true)
