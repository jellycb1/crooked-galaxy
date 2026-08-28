extends Control

var events: Array[Dictionary] = []
var planet_id := "dustball_prime"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var frozen := planet_id == "congelaria_sa"
	var fungal := planet_id == "micelia_404"
	var scrapyard := planet_id == "ferro_velho_omega"
	var casino := planet_id == "cassino_quasar"
	var aerial := planet_id == "aeropolis_penhora"
	var abyssal := planet_id == "arquivo_abissal_n9"
	var sky_top := Color("#0a5964") if abyssal else (Color("#315b80") if aerial else (Color("#5a1b58") if casino else (Color("#4a3028") if scrapyard else (Color("#244537") if fungal else (Color("#123f59") if frozen else Color("#1b3156"))))))
	var sky_bottom := Color("#041827") if abyssal else (Color("#18294d") if aerial else (Color("#28143f") if casino else (Color("#35202d") if scrapyard else (Color("#38244b") if fungal else (Color("#1c3150") if frozen else Color("#341d50"))))))
	var ridge_color := Color("#0c3039") if abyssal else (Color("#273a58") if aerial else (Color("#25102d") if casino else (Color("#211819") if scrapyard else (Color("#152b25") if fungal else (Color("#10283b") if frozen else Color("#131a31"))))))
	var ground_color := Color("#03131d") if abyssal else (Color("#111b35") if aerial else (Color("#100615") if casino else (Color("#100a0c") if scrapyard else (Color("#08150f") if fungal else (Color("#06131d") if frozen else Color("#0a1025"))))))
	var primary_glow := Color(0.22, 0.85, 0.77, 0.18) if abyssal else (Color(0.56, 0.83, 1.0, 0.20) if aerial else (Color(1.0, 0.46, 0.85, 0.20) if casino else (Color(1.0, 0.62, 0.26, 0.18) if scrapyard else (Color(0.78, 0.96, 0.39, 0.16) if fungal else (Color(0.45, 0.95, 0.88, 0.16) if frozen else Color(0.96, 0.71, 0.31, 0.16))))))
	var horizon := size.y * 0.64
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101a3a"))
	for band in 10:
		var band_height := horizon / 10.0
		var shade := sky_top.lerp(sky_bottom, float(band) / 9.0)
		draw_rect(Rect2(0, band * band_height, size.x, band_height + 1.0), shade)

	# A shared crooked skyline takes on the materials and atmosphere of each chapter.
	draw_circle(Vector2(size.x * 0.78, size.y * 0.20), 42.0, primary_glow)
	draw_circle(Vector2(size.x * 0.18, size.y * 0.27), 19.0, Color(0.35, 0.90, 1.0, 0.18))
	var ridge := PackedVector2Array([
		Vector2(0, horizon), Vector2(size.x * 0.12, horizon - 38), Vector2(size.x * 0.26, horizon - 15),
		Vector2(size.x * 0.42, horizon - 62), Vector2(size.x * 0.58, horizon - 20),
		Vector2(size.x * 0.76, horizon - 48), Vector2(size.x, horizon - 8), Vector2(size.x, horizon),
	])
	draw_colored_polygon(ridge, ridge_color)
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), ground_color)
	draw_arc(Vector2(size.x * 0.24, horizon + 76), 94.0, PI, TAU, 32, Color(0.24, 0.75, 0.83, 0.13), 3.0, true)
	draw_arc(Vector2(size.x * 0.76, horizon + 76), 94.0, PI, TAU, 32, Color(0.93, 0.33, 0.47, 0.13), 3.0, true)
	if abyssal:
		for x in [0.12, 0.30, 0.52, 0.74, 0.90]:
			var stem := Vector2(size.x * x, horizon)
			draw_line(stem, stem + Vector2(-4, -34), Color(0.20, 0.74, 0.60, 0.18), 5.0, true)
			draw_circle(stem + Vector2(-4, -36), 7.0, Color(0.28, 0.94, 0.78, 0.13))
		for bubble_index in 9:
			var bubble := Vector2(size.x * (0.08 + float((bubble_index * 37) % 86) / 100.0), horizon * (0.18 + float((bubble_index * 29) % 64) / 100.0))
			draw_arc(bubble, 3.0 + float(bubble_index % 3), 0.0, TAU, 14, Color(0.72, 1.0, 0.96, 0.16), 1.5, true)
	elif aerial:
		for x in [0.14, 0.36, 0.62, 0.84]:
			var cloud_center := Vector2(size.x * x, horizon - 22 - 11 * int(x * 10) % 3)
			draw_circle(cloud_center, 15.0, Color(0.72, 0.90, 1.0, 0.13))
			draw_circle(cloud_center + Vector2(13, 4), 10.0, Color(0.72, 0.90, 1.0, 0.11))
		for x in [0.28, 0.72]:
			var start := Vector2(size.x * x, horizon - 42)
			draw_polyline(PackedVector2Array([start, start + Vector2(-8, 16), start + Vector2(2, 14), start + Vector2(-5, 32)]), Color(1.0, 0.90, 0.43, 0.20), 3.0, true)
	elif casino:
		for x in [0.12, 0.32, 0.56, 0.80]:
			var sign_center := Vector2(size.x * x, horizon - 30)
			draw_arc(sign_center, 15.0, 0.0, TAU, 20, Color(1.0, 0.46, 0.85, 0.18), 4.0, true)
			draw_circle(sign_center, 4.0, Color(1.0, 0.82, 0.32, 0.22))
	elif scrapyard:
		for x in [0.14, 0.36, 0.62, 0.84]:
			draw_line(Vector2(size.x * x, horizon), Vector2(size.x * (x + 0.07), horizon - 42), Color(1.0, 0.62, 0.26, 0.13), 7.0, true)
	elif fungal:
		for x in [0.16, 0.42, 0.72]:
			draw_circle(Vector2(size.x * x, horizon - 13), 13.0, Color(1.0, 0.46, 0.78, 0.13))
	elif frozen:
		for x in [0.20, 0.50, 0.78]:
			draw_line(Vector2(size.x * x, horizon), Vector2(size.x * (x + 0.05), horizon - 48), Color(0.45, 0.95, 0.88, 0.14), 8.0, true)

	for event in events:
		var from_left := str(event.get("actor", "")) == "player"
		var from_y := 150.0 if from_left else 178.0
		var to_y := 108.0 if from_left else 132.0
		var from := Vector2(size.x * (0.30 if from_left else 0.70), from_y)
		var to := Vector2(size.x * (0.70 if from_left else 0.30), to_y)
		var color := Color("#55e5ff") if from_left else Color("#ff6f7d")
		var critical := str(event.get("quality", "")) == "CRÍTICO"
		draw_line(from, to, color, 7.0 if critical else 4.0, true)
		draw_line(from - Vector2(34 if from_left else -34, 10), to, Color(color, 0.25), 2.0, true)
		draw_circle(to, 21.0 if critical else 13.0, Color(color, 0.30))
		draw_circle(to, 7.0, color)
