class_name PortraitFrame
extends Control

var accent := Color("#55e5ff")


func configure(next_accent: Color) -> void:
	accent = next_accent
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	var corners := [
		PackedVector2Array([Vector2(0.06, 0.25), Vector2(0.06, 0.06), Vector2(0.25, 0.06)]),
		PackedVector2Array([Vector2(0.75, 0.06), Vector2(0.94, 0.06), Vector2(0.94, 0.25)]),
		PackedVector2Array([Vector2(0.94, 0.75), Vector2(0.94, 0.94), Vector2(0.75, 0.94)]),
		PackedVector2Array([Vector2(0.25, 0.94), Vector2(0.06, 0.94), Vector2(0.06, 0.75)]),
	]
	for corner in corners:
		draw_polyline(corner, Color("#071126"), 0.075, true)
		draw_polyline(corner, accent, 0.035, true)
	for point in [Vector2(0.06, 0.06), Vector2(0.94, 0.06), Vector2(0.94, 0.94), Vector2(0.06, 0.94)]:
		draw_circle(point, 0.025, Color("#ffc857"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
