class_name HuntChoiceIcon
extends Control

var kind := "tactical"
var accent := Color("#ffc857")


func _ready() -> void:
	custom_minimum_size = Vector2(54, 54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(choice_kind: String, choice_accent: Color) -> void:
	kind = choice_kind
	accent = choice_accent
	tooltip_text = {
		"tactical": "Vantagem tática",
		"detour": "Rota alternativa",
		"risk": "Risco premiado",
	}.get(kind, "Decisão de caçada")
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 23.0, Color("#091126cc"))
	draw_arc(center, 22.0, 0.0, TAU, 32, accent, 2.0, true)
	match kind:
		"tactical":
			var shield := PackedVector2Array([
				center + Vector2(-12, -12), center + Vector2(12, -12),
				center + Vector2(10, 5), center + Vector2(0, 15),
				center + Vector2(-10, 5),
			])
			draw_colored_polygon(shield, accent.darkened(0.45))
			draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[0]]), accent, 2.0, true)
			draw_line(center + Vector2(-6, 0), center + Vector2(-1, 5), accent.lightened(0.35), 2.4, true)
			draw_line(center + Vector2(-1, 5), center + Vector2(7, -5), accent.lightened(0.35), 2.4, true)
		"detour":
			var route := PackedVector2Array([
				center + Vector2(-14, 11), center + Vector2(-5, 3),
				center + Vector2(-5, -8), center + Vector2(8, -8),
			])
			draw_polyline(route, accent, 3.0, true)
			draw_circle(route[0], 3.5, accent.lightened(0.25))
			draw_line(center + Vector2(8, -8), center + Vector2(3, -13), accent, 2.5, true)
			draw_line(center + Vector2(8, -8), center + Vector2(3, -3), accent, 2.5, true)
			draw_arc(center + Vector2(9, 9), 6.0, 0.0, TAU, 20, Color("#f4f2ff"), 1.6, true)
			draw_line(center + Vector2(9, 9), center + Vector2(9, 5), Color("#f4f2ff"), 1.4, true)
			draw_line(center + Vector2(9, 9), center + Vector2(12, 11), Color("#f4f2ff"), 1.4, true)
		"risk":
			var bolt := PackedVector2Array([
				center + Vector2(2, -16), center + Vector2(-10, 2),
				center + Vector2(-2, 2), center + Vector2(-6, 16),
				center + Vector2(11, -5), center + Vector2(3, -5),
			])
			draw_colored_polygon(bolt, accent)
			draw_polyline(PackedVector2Array([bolt[0], bolt[1], bolt[2], bolt[3], bolt[4], bolt[5], bolt[0]]), accent.lightened(0.25), 1.5, true)

