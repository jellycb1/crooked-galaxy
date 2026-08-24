class_name EquipmentIcon
extends Control

var item: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	var ink := Color("#071024")
	var rarity := rarity_color(str(item.get("rarity", "Comum")))
	var origin_color := planet_color(str(item.get("origin_planet_id", "")))
	var frame := PackedVector2Array([Vector2(0.12, 0.03), Vector2(0.88, 0.03), Vector2(0.97, 0.12), Vector2(0.97, 0.88), Vector2(0.88, 0.97), Vector2(0.12, 0.97), Vector2(0.03, 0.88), Vector2(0.03, 0.12)])
	draw_colored_polygon(frame, Color(origin_color, 0.16))
	var closed := frame.duplicate()
	closed.append(frame[0])
	draw_polyline(closed, rarity, 0.045, true)
	if str(item.get("slot", "weapon")) == "armor":
		draw_armor(ink, rarity, origin_color)
	else:
		draw_weapon(ink, rarity, origin_color)
	var investment := mini(5, int(item.get("power_upgrades", 0)) + int(item.get("integrity_upgrades", 0)))
	for pip in investment:
		draw_circle(Vector2(0.29 + float(pip) * 0.105, 0.88), 0.027, rarity)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_weapon(ink: Color, rarity: Color, origin_color: Color) -> void:
	var body := PackedVector2Array([Vector2(0.16, 0.42), Vector2(0.68, 0.31), Vector2(0.86, 0.39), Vector2(0.70, 0.53), Vector2(0.49, 0.54), Vector2(0.40, 0.75), Vector2(0.25, 0.72), Vector2(0.29, 0.52), Vector2(0.16, 0.52)])
	draw_colored_polygon(body, origin_color.darkened(0.28))
	var closed := body.duplicate()
	closed.append(body[0])
	draw_polyline(closed, ink, 0.045, true)
	draw_line(Vector2(0.24, 0.46), Vector2(0.72, 0.40), rarity, 0.055, true)
	draw_circle(Vector2(0.59, 0.46), 0.075, ink)
	draw_circle(Vector2(0.59, 0.46), 0.045, rarity)


func draw_armor(ink: Color, rarity: Color, origin_color: Color) -> void:
	var chest := PackedVector2Array([Vector2(0.31, 0.22), Vector2(0.50, 0.31), Vector2(0.69, 0.22), Vector2(0.82, 0.38), Vector2(0.71, 0.78), Vector2(0.50, 0.88), Vector2(0.29, 0.78), Vector2(0.18, 0.38)])
	draw_colored_polygon(chest, origin_color.darkened(0.28))
	var closed := chest.duplicate()
	closed.append(chest[0])
	draw_polyline(closed, ink, 0.045, true)
	draw_line(Vector2(0.50, 0.33), Vector2(0.50, 0.78), rarity, 0.045, true)
	draw_line(Vector2(0.28, 0.43), Vector2(0.72, 0.43), rarity, 0.035, true)
	draw_circle(Vector2(0.50, 0.55), 0.075, ink)
	draw_circle(Vector2(0.50, 0.55), 0.040, rarity)


func rarity_color(rarity: String) -> Color:
	match rarity:
		"Épico":
			return Color("#d789ff")
		"Raro":
			return Color("#58d9ff")
		_:
			return Color("#b9c2d9")


func planet_color(planet_id: String) -> Color:
	match planet_id:
		"dustball_prime": return Color("#ffc857")
		"congelaria_sa": return Color("#72f1dd")
		"micelia_404": return Color("#c7f464")
		"ferro_velho_omega": return Color("#ff9f43")
		"cassino_quasar": return Color("#ff75d8")
		_: return Color("#55e5ff")
