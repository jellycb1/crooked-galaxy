class_name SpaceBackdrop
extends Control

var stars: Array[Dictionary] = []
var planet_id := "dustball_prime":
	set(value):
		planet_id = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 40404
	for index in 72:
		stars.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"radius": rng.randf_range(0.6, 1.8),
			"alpha": rng.randf_range(0.16, 0.58),
			"cyan": index % 7 == 0,
		})
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var frozen := planet_id == "congelaria_sa"
	var top := Color("#0e4359") if frozen else Color("#12264c")
	var bottom := Color("#04121d") if frozen else Color("#050817")
	var bands := 28
	for band in bands:
		var from_y := size.y * float(band) / float(bands)
		var to_y := size.y * float(band + 1) / float(bands)
		var color := top.lerp(bottom, float(band) / float(bands - 1))
		draw_rect(Rect2(0, from_y, size.x, to_y - from_y + 1.0), color)

	# Soft, deliberately off-center nebula shapes.
	draw_circle(Vector2(size.x * 0.06, size.y * 0.32), size.x * 0.33, Color(0.25, 0.92, 0.82, 0.045) if frozen else Color(0.14, 0.56, 0.72, 0.035))
	draw_circle(Vector2(size.x * 0.92, size.y * 0.48), size.x * 0.42, Color(0.52, 0.20, 0.68, 0.028))

	for star in stars:
		var position := Vector2(float(star.x) * size.x, float(star.y) * size.y)
		var star_color := Color(0.38, 0.91, 1.0, float(star.alpha)) if bool(star.cyan) else Color(0.88, 0.91, 1.0, float(star.alpha))
		draw_circle(position, float(star.radius), star_color)

	# A distant crooked planet and ring, kept subtle behind the interface.
	var planet_center := Vector2(size.x + 48.0, size.y * 0.48)
	var planet_radius := size.x * 0.21
	draw_arc(planet_center, planet_radius * 1.48, -2.8, 0.2, 80, Color(0.33, 0.65, 0.85, 0.10), 5.0, true)
	draw_circle(planet_center, planet_radius, Color(0.18, 0.22, 0.47, 0.13))
	draw_arc(planet_center, planet_radius, 0.0, TAU, 80, Color(0.40, 0.72, 0.90, 0.10), 2.0, true)
	if frozen:
		for offset in [-0.55, -0.15, 0.3]:
			draw_line(Vector2(size.x * (0.15 + offset * 0.08), size.y), Vector2(size.x * (0.42 + offset * 0.08), size.y * 0.78), Color(0.45, 0.95, 0.88, 0.055), 12.0, true)
