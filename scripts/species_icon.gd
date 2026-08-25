class_name SpeciesIcon
extends Control

var species_id := ""
var accent := Color("#55e5ff")


func configure(next_species_id: String, next_accent: Color) -> void:
	species_id = next_species_id
	accent = next_accent
	custom_minimum_size = Vector2(58, 58)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	draw_circle(Vector2(0.5, 0.5), 0.46, Color("#071126e8"))
	draw_arc(Vector2(0.5, 0.5), 0.43, 0.0, TAU, 36, Color(accent, 0.82), 0.045, true)
	match species_id:
		"patched_terran":
			draw_terran()
		"discontinued_synthetic":
			draw_synthetic()
		"nebular_nomad":
			draw_nomad()
		_:
			draw_circle(Vector2(0.5, 0.5), 0.13, accent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_terran() -> void:
	var ink := Color("#071126")
	draw_circle(Vector2(0.5, 0.47), 0.22, Color("#d8a071"))
	draw_arc(Vector2(0.5, 0.47), 0.22, PI, TAU, 18, accent, 0.055, true)
	draw_line(Vector2(0.34, 0.44), Vector2(0.45, 0.42), ink, 0.035, true)
	draw_line(Vector2(0.55, 0.42), Vector2(0.66, 0.44), ink, 0.035, true)
	draw_line(Vector2(0.41, 0.59), Vector2(0.59, 0.59), ink, 0.028, true)
	draw_line(Vector2(0.27, 0.76), Vector2(0.73, 0.76), accent, 0.075, true)
	for x in [0.38, 0.50, 0.62]:
		draw_circle(Vector2(x, 0.76), 0.022, ink)


func draw_synthetic() -> void:
	var ink := Color("#071126")
	var points := PackedVector2Array([Vector2(0.34, 0.25), Vector2(0.66, 0.25), Vector2(0.75, 0.43), Vector2(0.67, 0.68), Vector2(0.50, 0.78), Vector2(0.33, 0.68), Vector2(0.25, 0.43)])
	draw_colored_polygon(points, Color("#6f88a8"))
	draw_polyline(PackedVector2Array(Array(points) + [points[0]]), accent, 0.04, true)
	draw_line(Vector2(0.34, 0.45), Vector2(0.66, 0.45), ink, 0.065, true)
	draw_circle(Vector2(0.40, 0.45), 0.035, accent)
	draw_circle(Vector2(0.60, 0.45), 0.035, accent)
	draw_line(Vector2(0.38, 0.62), Vector2(0.62, 0.62), ink, 0.035, true)
	draw_line(Vector2(0.50, 0.25), Vector2(0.50, 0.13), accent, 0.035, true)
	draw_circle(Vector2(0.50, 0.12), 0.035, accent)


func draw_nomad() -> void:
	var ink := Color("#071126")
	var skin := Color("#7b67a8")
	draw_circle(Vector2(0.5, 0.49), 0.23, skin)
	draw_line(Vector2(0.36, 0.31), Vector2(0.27, 0.16), accent, 0.055, true)
	draw_line(Vector2(0.64, 0.31), Vector2(0.73, 0.16), accent, 0.055, true)
	draw_circle(Vector2(0.40, 0.48), 0.045, Color("#eafcff"))
	draw_circle(Vector2(0.60, 0.48), 0.045, Color("#eafcff"))
	draw_circle(Vector2(0.50, 0.36), 0.038, accent)
	draw_line(Vector2(0.42, 0.62), Vector2(0.58, 0.62), ink, 0.028, true)
	for point in [Vector2(0.30, 0.75), Vector2(0.50, 0.80), Vector2(0.70, 0.75)]:
		draw_circle(point, 0.035, accent)
