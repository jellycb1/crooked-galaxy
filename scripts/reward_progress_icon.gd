class_name RewardProgressIcon
extends Control

var kind := "mastery"
var accent := Color("#b8f45d")


func configure(icon_kind: String, icon_accent: Color) -> void:
	kind = icon_kind
	accent = icon_accent
	queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(34, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 15.0, Color("#081127"))
	draw_arc(center, 14.0, 0.0, TAU, 28, accent.darkened(0.1), 2.0, true)
	match kind:
		"streak":
			for offset in [-5.0, 2.0]:
				var points := PackedVector2Array([
					center + Vector2(offset - 4.0, -7.0),
					center + Vector2(offset + 3.0, 0.0),
					center + Vector2(offset - 4.0, 7.0),
				])
				draw_polyline(points, accent, 2.4, true)
		"warrant":
			draw_rect(Rect2(center + Vector2(-7, -9), Vector2(14, 18)), accent, false, 2.0)
			draw_line(center + Vector2(-4, -4), center + Vector2(4, -4), accent, 1.7, true)
			draw_line(center + Vector2(-4, 1), center + Vector2(4, 1), accent, 1.7, true)
			draw_circle(center + Vector2(0, 6), 1.8, accent)
		"daily":
			draw_rect(Rect2(center + Vector2(-8, -7), Vector2(16, 15)), accent, false, 2.0)
			draw_line(center + Vector2(-8, -2), center + Vector2(8, -2), accent, 1.7, true)
			draw_line(center + Vector2(-4, -10), center + Vector2(-4, -5), accent, 2.0, true)
			draw_line(center + Vector2(4, -10), center + Vector2(4, -5), accent, 2.0, true)
			draw_line(center + Vector2(-4, 3), center + Vector2(-1, 6), accent, 1.7, true)
			draw_line(center + Vector2(-1, 6), center + Vector2(5, 0), accent, 1.7, true)
		_:
			draw_circle(center, 7.0, accent, false, 2.0)
			draw_circle(center, 2.5, accent)
			draw_line(center + Vector2(-11, 0), center + Vector2(-6, 0), accent, 2.0, true)
			draw_line(center + Vector2(6, 0), center + Vector2(11, 0), accent, 2.0, true)
			draw_line(center + Vector2(0, -11), center + Vector2(0, -6), accent, 2.0, true)
			draw_line(center + Vector2(0, 6), center + Vector2(0, 11), accent, 2.0, true)
