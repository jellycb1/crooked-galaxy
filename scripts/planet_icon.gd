class_name PlanetIcon
extends Control

var planet_id := "dustball"
var accent := Color("#ffcb58")
var unlocked := true
var current := false


func _ready() -> void:
	custom_minimum_size = Vector2(58, 58)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(data: Dictionary, is_unlocked: bool, is_current: bool) -> void:
	planet_id = str(data.get("id", "dustball"))
	accent = Color(str(data.get("accent", "#ffcb58")))
	unlocked = is_unlocked
	current = is_current
	tooltip_text = "%s · %s" % [str(data.get("name", "Planeta")), "rota disponível" if unlocked else "rota bloqueada"]
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var color := accent if unlocked else accent.darkened(0.58)
	if current:
		draw_arc(center, radius + 8.0, 0.0, TAU, 40, Color("#82f6e8"), 2.0, true)
		draw_circle(center + Vector2(radius + 8.0, 0), 2.6, Color("#82f6e8"))
	draw_circle(center + Vector2(2, 3), radius + 1.0, Color(0.01, 0.02, 0.06, 0.72))
	draw_circle(center, radius, color.darkened(0.34))
	draw_arc(center, radius, 0.0, TAU, 32, color, 2.0, true)
	match planet_id:
		"dustball":
			draw_circle(center - Vector2(6, 4), 4.0, color.darkened(0.52))
			draw_circle(center + Vector2(7, 5), 2.6, color.lightened(0.18))
			draw_arc(center + Vector2(-2, 1), radius * 0.7, 0.18, 2.75, 16, color.lightened(0.12), 2.0, true)
		"congelaria":
			draw_line(center - Vector2(radius - 3, 3), center + Vector2(radius - 3, -5), color.lightened(0.3), 2.0, true)
			draw_line(center - Vector2(9, -9), center + Vector2(5, 11), Color("#d8ffff"), 2.0, true)
			draw_line(center - Vector2(7, 7), center + Vector2(8, -8), Color("#d8ffff"), 1.5, true)
		"micelia":
			for offset in [Vector2(-8, -4), Vector2(4, -8), Vector2(8, 6)]:
				draw_circle(center + offset, 4.2, color.lightened(0.22))
				draw_line(center + offset + Vector2(0, 3), center + offset + Vector2(0, 8), color.darkened(0.22), 2.0, true)
		"omega":
			draw_arc(center, radius * 0.58, 0.0, TAU, 10, color.lightened(0.2), 3.0, true)
			draw_circle(center, 4.0, Color("#081126"))
			for angle in range(0, 360, 45):
				var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
				draw_line(center + direction * 9.0, center + direction * 14.0, color.lightened(0.22), 3.0, true)
		"quasar":
			var ring := PackedVector2Array()
			for index in range(33):
				var angle := TAU * float(index) / 32.0
				ring.append(center + Vector2(cos(angle) * (radius + 6.0), sin(angle) * 6.0).rotated(-0.32))
			draw_polyline(ring, color.lightened(0.22), 2.5, true)
			draw_circle(center - Vector2(5, 5), 3.0, Color("#ffe86b"))
	if not unlocked:
		var lock_center := center + Vector2(radius * 0.55, radius * 0.55)
		draw_rect(Rect2(lock_center - Vector2(5, 2), Vector2(10, 8)), Color("#0b1228"), true)
		draw_arc(lock_center - Vector2(0, 2), 4.0, PI, TAU, 12, Color("#9aa5ba"), 1.6, true)
