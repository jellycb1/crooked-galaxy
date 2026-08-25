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
	match str(item.get("slot", "weapon")):
		"weapon": draw_weapon(ink, rarity, origin_color)
		"helmet": draw_helmet(ink, rarity, origin_color)
		"armor": draw_armor(ink, rarity, origin_color)
		"gloves": draw_gloves(ink, rarity, origin_color)
		"boots": draw_boots(ink, rarity, origin_color)
		"rig": draw_rig(ink, rarity, origin_color)
		"implant": draw_implant(ink, rarity, origin_color)
		"gadget": draw_gadget(ink, rarity, origin_color)
		"relic": draw_relic(ink, rarity, origin_color)
		_: draw_gadget(ink, rarity, origin_color)
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


func draw_helmet(ink: Color, rarity: Color, origin_color: Color) -> void:
	draw_circle(Vector2(0.5, 0.48), 0.29, origin_color.darkened(0.28))
	draw_arc(Vector2(0.5, 0.48), 0.29, PI, TAU, 24, ink, 0.05, true)
	draw_rect(Rect2(0.22, 0.45, 0.56, 0.18), ink, true)
	draw_rect(Rect2(0.28, 0.49, 0.44, 0.08), rarity, true)
	draw_line(Vector2(0.29, 0.67), Vector2(0.71, 0.67), rarity, 0.045, true)


func draw_gloves(ink: Color, rarity: Color, origin_color: Color) -> void:
	var palm := PackedVector2Array([Vector2(0.31, 0.31), Vector2(0.41, 0.47), Vector2(0.45, 0.22), Vector2(0.53, 0.22), Vector2(0.55, 0.46), Vector2(0.62, 0.28), Vector2(0.70, 0.33), Vector2(0.66, 0.66), Vector2(0.52, 0.79), Vector2(0.31, 0.68)])
	draw_colored_polygon(palm, origin_color.darkened(0.28))
	var closed := palm.duplicate()
	closed.append(palm[0])
	draw_polyline(closed, ink, 0.045, true)
	draw_line(Vector2(0.34, 0.61), Vector2(0.65, 0.61), rarity, 0.045, true)


func draw_boots(ink: Color, rarity: Color, origin_color: Color) -> void:
	var boot := PackedVector2Array([Vector2(0.28, 0.22), Vector2(0.57, 0.22), Vector2(0.55, 0.57), Vector2(0.79, 0.67), Vector2(0.76, 0.79), Vector2(0.23, 0.79), Vector2(0.22, 0.64), Vector2(0.34, 0.55)])
	draw_colored_polygon(boot, origin_color.darkened(0.28))
	var closed := boot.duplicate()
	closed.append(boot[0])
	draw_polyline(closed, ink, 0.045, true)
	draw_line(Vector2(0.26, 0.68), Vector2(0.73, 0.68), rarity, 0.045, true)


func draw_rig(ink: Color, rarity: Color, origin_color: Color) -> void:
	draw_rect(Rect2(0.17, 0.38, 0.66, 0.23), origin_color.darkened(0.28), true)
	draw_rect(Rect2(0.17, 0.38, 0.66, 0.23), ink, false, 0.05)
	draw_rect(Rect2(0.40, 0.34, 0.20, 0.31), ink, true)
	draw_rect(Rect2(0.45, 0.40, 0.10, 0.19), rarity, true)
	draw_line(Vector2(0.23, 0.49), Vector2(0.36, 0.49), rarity, 0.04, true)
	draw_line(Vector2(0.64, 0.49), Vector2(0.77, 0.49), rarity, 0.04, true)


func draw_implant(ink: Color, rarity: Color, origin_color: Color) -> void:
	draw_circle(Vector2(0.5, 0.5), 0.25, origin_color.darkened(0.28))
	draw_arc(Vector2(0.5, 0.5), 0.25, 0.0, TAU, 28, ink, 0.05, true)
	draw_circle(Vector2(0.5, 0.5), 0.10, rarity)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var direction := Vector2.from_angle(angle)
		draw_line(Vector2(0.5, 0.5) + direction * 0.11, Vector2(0.5, 0.5) + direction * 0.34, rarity, 0.04, true)


func draw_gadget(ink: Color, rarity: Color, origin_color: Color) -> void:
	draw_rect(Rect2(0.24, 0.22, 0.52, 0.56), origin_color.darkened(0.28), true)
	draw_rect(Rect2(0.24, 0.22, 0.52, 0.56), ink, false, 0.05)
	draw_rect(Rect2(0.32, 0.31, 0.36, 0.20), rarity, true)
	draw_circle(Vector2(0.38, 0.65), 0.055, ink)
	draw_circle(Vector2(0.62, 0.65), 0.055, rarity)


func draw_relic(ink: Color, rarity: Color, origin_color: Color) -> void:
	var crystal := PackedVector2Array([Vector2(0.50, 0.16), Vector2(0.73, 0.39), Vector2(0.64, 0.76), Vector2(0.50, 0.87), Vector2(0.36, 0.76), Vector2(0.27, 0.39)])
	draw_colored_polygon(crystal, origin_color.darkened(0.20))
	var closed := crystal.duplicate()
	closed.append(crystal[0])
	draw_polyline(closed, ink, 0.05, true)
	draw_line(Vector2(0.50, 0.20), Vector2(0.50, 0.81), rarity, 0.045, true)
	draw_line(Vector2(0.30, 0.41), Vector2(0.69, 0.41), rarity, 0.035, true)


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
