class_name HubDestinationIcon
extends Control

var destination := "arsenal"
var accent := Color("#58d9ff")


func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(destination_id: String, destination_color: Color) -> void:
	destination = destination_id
	accent = destination_color
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 20.0, Color("#071126e8"))
	draw_arc(center, 19.0, 0.0, TAU, 32, accent, 2.0, true)
	match destination:
		"contracts":
			var warrant := Rect2(center + Vector2(-11, -14), Vector2(22, 28))
			draw_rect(warrant, accent.darkened(0.52), true)
			draw_rect(warrant, accent, false, 2.0)
			draw_line(center + Vector2(-6, -7), center + Vector2(6, -7), accent.lightened(0.3), 2.0, true)
			draw_line(center + Vector2(-6, -1), center + Vector2(3, -1), accent.lightened(0.3), 2.0, true)
			draw_circle(center + Vector2(6, 8), 3.5, accent)
		"arsenal":
			draw_line(center + Vector2(-11, 10), center + Vector2(10, -11), accent, 4.0, true)
			draw_line(center + Vector2(-8, -9), center + Vector2(11, 10), accent.lightened(0.28), 3.0, true)
			draw_circle(center + Vector2(-10, 12), 3.0, accent.darkened(0.2))
			draw_line(center + Vector2(8, -13), center + Vector2(13, -8), accent, 2.0, true)
		"market":
			var tag := PackedVector2Array([
				center + Vector2(-13, -8), center + Vector2(4, -8),
				center + Vector2(13, 0), center + Vector2(4, 9),
				center + Vector2(-13, 9),
			])
			draw_colored_polygon(tag, accent.darkened(0.48))
			draw_polyline(PackedVector2Array([tag[0], tag[1], tag[2], tag[3], tag[4], tag[0]]), accent, 2.0, true)
			draw_circle(center + Vector2(-7, 0), 2.4, accent.lightened(0.35))
		"hangar":
			var ship := PackedVector2Array([
				center + Vector2(-14, 6), center + Vector2(-5, -7),
				center + Vector2(10, -3), center + Vector2(15, 5),
				center + Vector2(2, 10),
			])
			draw_colored_polygon(ship, accent.darkened(0.5))
			draw_polyline(PackedVector2Array([ship[0], ship[1], ship[2], ship[3], ship[4], ship[0]]), accent, 2.0, true)
			draw_line(center + Vector2(-6, 11), center + Vector2(-11, 16), accent.lightened(0.3), 2.0, true)
			draw_line(center + Vector2(3, 11), center + Vector2(0, 17), accent.lightened(0.3), 2.0, true)
		"galaxy":
			draw_circle(center, 6.0, accent.darkened(0.2))
			draw_arc(center, 14.0, -0.35, PI + 0.35, 24, accent, 2.4, true)
			draw_arc(center, 14.0, PI - 0.35, TAU + 0.35, 24, accent.lightened(0.3), 1.5, true)
			draw_circle(center + Vector2(13, -5), 2.5, Color("#f4f2ff"))
		"career":
			draw_arc(center, 12.0, 0.0, TAU, 24, accent, 2.2, true)
			draw_line(center + Vector2(-11, 14), center + Vector2(-5, 7), accent, 4.0, true)
			draw_line(center + Vector2(11, 14), center + Vector2(5, 7), accent, 4.0, true)
			draw_line(center + Vector2(-7, 2), center + Vector2(-1, 8), accent.lightened(0.35), 2.4, true)
			draw_line(center + Vector2(-1, 8), center + Vector2(8, -6), accent.lightened(0.35), 2.4, true)
		"daily":
			var calendar := Rect2(center + Vector2(-12, -10), Vector2(24, 22))
			draw_rect(calendar, accent.darkened(0.52), true)
			draw_rect(calendar, accent, false, 2.0)
			draw_line(center + Vector2(-12, -4), center + Vector2(12, -4), accent, 2.0, true)
			draw_line(center + Vector2(-6, -14), center + Vector2(-6, -7), accent.lightened(0.3), 2.5, true)
			draw_line(center + Vector2(6, -14), center + Vector2(6, -7), accent.lightened(0.3), 2.5, true)
			draw_line(center + Vector2(-6, 4), center + Vector2(-1, 9), accent.lightened(0.35), 2.5, true)
			draw_line(center + Vector2(-1, 9), center + Vector2(8, 0), accent.lightened(0.35), 2.5, true)
		"hunter":
			draw_circle(center + Vector2(0, -7), 6.5, accent.darkened(0.25))
			draw_arc(center + Vector2(0, 9), 11.5, PI, TAU, 20, accent, 3.0, true)
			draw_line(center + Vector2(-9, -2), center + Vector2(9, -2), accent, 2.0, true)
			draw_circle(center + Vector2(-3, -7), 1.2, Color("#f4f2ff"))
			draw_circle(center + Vector2(3, -7), 1.2, Color("#f4f2ff"))
		"menu":
			for offset in [Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8), Vector2(8, 8)]:
				draw_rect(Rect2(center + offset - Vector2(4, 4), Vector2(8, 8)), accent.darkened(0.3), true)
				draw_rect(Rect2(center + offset - Vector2(4, 4), Vector2(8, 8)), accent, false, 1.5)
		"settings":
			draw_arc(center, 9.0, 0.0, TAU, 20, accent, 3.0, true)
			draw_circle(center, 3.0, accent.lightened(0.35))
			for angle in range(0, 360, 45):
				var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
				draw_line(center + direction * 11.0, center + direction * 16.0, accent, 3.0, true)
