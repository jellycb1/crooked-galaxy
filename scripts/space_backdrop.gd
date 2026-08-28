class_name SpaceBackdrop
extends Control

var stars: Array[Dictionary] = []
var planet_id := "dustball_prime":
	set(value):
		if planet_id == value:
			return
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
	var fungal := planet_id == "micelia_404"
	var scrapyard := planet_id == "ferro_velho_omega"
	var casino := planet_id == "cassino_quasar"
	var aerial := planet_id == "aeropolis_penhora"
	var top := Color("#264d76") if aerial else (Color("#4b174f") if casino else (Color("#51352b") if scrapyard else (Color("#2d4b32") if fungal else (Color("#0e4359") if frozen else Color("#12264c")))))
	var bottom := Color("#09152f") if aerial else (Color("#13051f") if casino else (Color("#160b09") if scrapyard else (Color("#07150d") if fungal else (Color("#04121d") if frozen else Color("#050817")))))
	var bands := 28
	for band in bands:
		var from_y := size.y * float(band) / float(bands)
		var to_y := size.y * float(band + 1) / float(bands)
		var color := top.lerp(bottom, float(band) / float(bands - 1))
		draw_rect(Rect2(0, from_y, size.x, to_y - from_y + 1.0), color)

	# Soft, deliberately off-center nebula shapes.
	draw_circle(Vector2(size.x * 0.06, size.y * 0.32), size.x * 0.33, Color(0.56, 0.83, 1.0, 0.065) if aerial else (Color(1.0, 0.35, 0.82, 0.065) if casino else (Color(1.0, 0.52, 0.22, 0.055) if scrapyard else (Color(0.75, 0.96, 0.39, 0.045) if fungal else (Color(0.25, 0.92, 0.82, 0.045) if frozen else Color(0.14, 0.56, 0.72, 0.035))))))
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
	if aerial:
		for cloud_index in 11:
			var cloud_x := size.x * (0.05 + float((cloud_index * 47) % 91) / 100.0)
			var cloud_y := size.y * (0.20 + float((cloud_index * 23) % 61) / 100.0)
			draw_arc(Vector2(cloud_x, cloud_y), 7.0 + float(cloud_index % 4), 0.0, TAU, 18, Color(0.72, 0.90, 1.0, 0.11), 2.5, true)
		for bolt_index in 4:
			var bolt_start := Vector2(size.x * (0.18 + bolt_index * 0.21), size.y * (0.32 + 0.07 * (bolt_index % 2)))
			draw_polyline(PackedVector2Array([bolt_start, bolt_start + Vector2(-7, 14), bolt_start + Vector2(1, 13), bolt_start + Vector2(-5, 27)]), Color(1.0, 0.90, 0.43, 0.11), 2.0, true)
	elif casino:
		for ray_index in 10:
			var angle := TAU * float(ray_index) / 10.0
			var center := Vector2(size.x * 0.12, size.y * 0.72)
			draw_line(center, center + Vector2.from_angle(angle) * size.x * 0.24, Color(1.0, 0.46, 0.85, 0.075), 3.0, true)
		for chip_index in 8:
			var chip_x := size.x * (0.12 + float((chip_index * 43) % 79) / 100.0)
			var chip_y := size.y * (0.13 + float((chip_index * 31) % 73) / 100.0)
			draw_arc(Vector2(chip_x, chip_y), 5.0 + float(chip_index % 3), 0.0, TAU, 16, Color(0.98, 0.80, 0.30, 0.13), 2.0, true)
	elif frozen:
		for offset in [-0.55, -0.15, 0.3]:
			draw_line(Vector2(size.x * (0.15 + offset * 0.08), size.y), Vector2(size.x * (0.42 + offset * 0.08), size.y * 0.78), Color(0.45, 0.95, 0.88, 0.055), 12.0, true)
	elif fungal:
		for spore_index in 12:
			var spore_x := size.x * (0.08 + float((spore_index * 37) % 89) / 100.0)
			var spore_y := size.y * (0.18 + float((spore_index * 53) % 71) / 100.0)
			draw_circle(Vector2(spore_x, spore_y), 3.0 + float(spore_index % 3), Color(1.0, 0.46, 0.78, 0.10))
	elif scrapyard:
		for debris_index in 14:
			var debris_x := size.x * (0.04 + float((debris_index * 41) % 91) / 100.0)
			var debris_y := size.y * (0.16 + float((debris_index * 29) % 69) / 100.0)
			var debris_size := 3.0 + float(debris_index % 4)
			draw_rect(Rect2(Vector2(debris_x, debris_y), Vector2(debris_size * 2.2, debris_size)), Color(1.0, 0.62, 0.26, 0.11), true)
			draw_line(Vector2(debris_x, debris_y), Vector2(debris_x + debris_size * 3.0, debris_y - debris_size), Color(0.75, 0.80, 0.84, 0.08), 1.5, true)
