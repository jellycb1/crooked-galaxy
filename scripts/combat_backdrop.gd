extends Control

var events: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var horizon := size.y * 0.64
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101a3a"))
	for band in 10:
		var band_height := horizon / 10.0
		var shade := Color("#1b3156").lerp(Color("#341d50"), float(band) / 9.0)
		draw_rect(Rect2(0, band * band_height, size.x, band_height + 1.0), shade)

	# Dustball Prime's crooked skyline and twin moons.
	draw_circle(Vector2(size.x * 0.78, size.y * 0.20), 42.0, Color(0.96, 0.71, 0.31, 0.16))
	draw_circle(Vector2(size.x * 0.18, size.y * 0.27), 19.0, Color(0.35, 0.90, 1.0, 0.18))
	var ridge := PackedVector2Array([
		Vector2(0, horizon), Vector2(size.x * 0.12, horizon - 38), Vector2(size.x * 0.26, horizon - 15),
		Vector2(size.x * 0.42, horizon - 62), Vector2(size.x * 0.58, horizon - 20),
		Vector2(size.x * 0.76, horizon - 48), Vector2(size.x, horizon - 8), Vector2(size.x, horizon),
	])
	draw_colored_polygon(ridge, Color("#131a31"))
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color("#0a1025"))
	draw_arc(Vector2(size.x * 0.24, horizon + 76), 94.0, PI, TAU, 32, Color(0.24, 0.75, 0.83, 0.13), 3.0, true)
	draw_arc(Vector2(size.x * 0.76, horizon + 76), 94.0, PI, TAU, 32, Color(0.93, 0.33, 0.47, 0.13), 3.0, true)

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
