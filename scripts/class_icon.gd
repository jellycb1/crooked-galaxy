class_name ClassIcon
extends Control

var class_id := ""
var accent := Color("#55e5ff")


func configure(next_class_id: String, next_accent: Color, dimension: float) -> void:
	class_id = next_class_id
	accent = next_accent
	custom_minimum_size = Vector2(dimension, dimension)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	var ink := Color("#071126")
	draw_circle(Vector2(0.5, 0.5), 0.45, Color("#101d3a"))
	draw_arc(Vector2(0.5, 0.5), 0.42, 0.0, TAU, 40, Color(accent, 0.86), 0.04, true)
	match class_id:
		"warrant_breaker":
			# Heavy breach hammer over a reinforced warrant plate.
			draw_colored_polygon(PackedVector2Array([Vector2(0.28, 0.25), Vector2(0.70, 0.20), Vector2(0.76, 0.39), Vector2(0.34, 0.44)]), accent)
			draw_polyline(PackedVector2Array([Vector2(0.38, 0.39), Vector2(0.68, 0.76)]), ink, 0.09, true)
			draw_line(Vector2(0.38, 0.39), Vector2(0.68, 0.76), Color("#d9a064"), 0.045, true)
			draw_arc(Vector2(0.50, 0.55), 0.27, 0.15, PI - 0.15, 18, accent, 0.035, true)
		"orbit_gunslinger":
			# Twin sidearms align on an orbital targeting ring.
			draw_arc(Vector2(0.5, 0.5), 0.24, 0.0, TAU, 32, accent, 0.035, true)
			draw_line(Vector2(0.20, 0.50), Vector2(0.80, 0.50), Color(accent, 0.58), 0.022, true)
			draw_line(Vector2(0.50, 0.20), Vector2(0.50, 0.80), Color(accent, 0.58), 0.022, true)
			for mirror in [-1.0, 1.0]:
				var x: float = 0.5 + mirror * 0.16
				draw_colored_polygon(PackedVector2Array([Vector2(x - 0.07, 0.38), Vector2(x + 0.07, 0.38), Vector2(x + 0.06, 0.57), Vector2(x - 0.04, 0.57)]), accent)
				draw_line(Vector2(x, 0.56), Vector2(x + mirror * 0.05, 0.72), ink, 0.055, true)
		"contract_hacker":
			# Broken contract seal connected as a compact circuit.
			var diamond := PackedVector2Array([Vector2(0.50, 0.20), Vector2(0.76, 0.48), Vector2(0.50, 0.78), Vector2(0.24, 0.48), Vector2(0.50, 0.20)])
			draw_polyline(diamond, accent, 0.055, true)
			draw_line(Vector2(0.35, 0.48), Vector2(0.65, 0.48), accent, 0.04, true)
			draw_line(Vector2(0.50, 0.33), Vector2(0.50, 0.64), accent, 0.04, true)
			for point in [Vector2(0.50, 0.20), Vector2(0.76, 0.48), Vector2(0.50, 0.78), Vector2(0.24, 0.48)]:
				draw_circle(point, 0.045, Color("#eafcff"))
			draw_line(Vector2(0.39, 0.61), Vector2(0.61, 0.37), ink, 0.05, true)
		_:
			draw_circle(Vector2(0.5, 0.5), 0.12, accent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
