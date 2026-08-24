class_name AttributeIcon
extends Control

const COLORS := {
	"strength": Color("#ffbd59"),
	"vitality": Color("#8ee66b"),
	"dexterity": Color("#58d9ff"),
	"intelligence": Color("#a88cff"),
	"cunning": Color("#ff79bc"),
}

var attribute_id := "strength"


func configure(id: String) -> void:
	attribute_id = id
	custom_minimum_size = Vector2(36, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = id.capitalize()
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var color: Color = COLORS.get(attribute_id, Color.WHITE)
	draw_circle(center, 14.0, Color(0.015, 0.03, 0.09, 0.94))
	draw_arc(center, 14.0, 0.0, TAU, 28, color.darkened(0.1), 1.5, true)
	match attribute_id:
		"strength":
			draw_line(center - Vector2(8, 0), center + Vector2(8, 0), color, 3.0, true)
			draw_line(center - Vector2(8, 5), center - Vector2(8, -5), color, 3.5, true)
			draw_line(center + Vector2(8, 5), center + Vector2(8, -5), color, 3.5, true)
		"vitality":
			var heart := PackedVector2Array([
				center + Vector2(0, 9), center + Vector2(-9, 0), center + Vector2(-7, -6),
				center + Vector2(-2, -8), center, center + Vector2(2, -8),
				center + Vector2(7, -6), center + Vector2(9, 0),
			])
			draw_colored_polygon(heart, color)
		"dexterity":
			draw_arc(center, 8.0, 0.0, TAU, 24, color, 2.0, true)
			draw_circle(center, 2.6, color)
			draw_line(center - Vector2(12, 0), center - Vector2(6, 0), color, 1.5, true)
			draw_line(center + Vector2(6, 0), center + Vector2(12, 0), color, 1.5, true)
			draw_line(center - Vector2(0, 12), center - Vector2(0, 6), color, 1.5, true)
			draw_line(center + Vector2(0, 6), center + Vector2(0, 12), color, 1.5, true)
		"intelligence":
			draw_circle(center, 6.5, color.darkened(0.25))
			for angle in range(0, 360, 60):
				var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
				draw_line(center + direction * 6.0, center + direction * 11.0, color, 1.8, true)
				draw_circle(center + direction * 11.0, 1.8, color)
			draw_circle(center, 2.3, Color("#e8e2ff"))
		"cunning":
			var eye := PackedVector2Array([
				center - Vector2(11, 0), center - Vector2(5, 6), center + Vector2(5, -6),
				center + Vector2(11, 0), center + Vector2(5, 6), center - Vector2(5, -6), center - Vector2(11, 0),
			])
			draw_polyline(eye, color, 2.0, true)
			draw_circle(center, 3.5, color)
			draw_circle(center + Vector2(1, -1), 1.2, Color("#fff2fb"))
