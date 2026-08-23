extends Control

var character_id := "hunter"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	match character_id:
		"gloop":
			draw_gloop()
		"baron_boom":
			draw_baron()
		"madame_vacuum":
			draw_madame()
		"mayor_gold_dust":
			draw_mayor()
		_:
			draw_hunter()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_frame(background: Color, rim: Color) -> void:
	filled_polygon([
		Vector2(0.08, 0.025), Vector2(0.92, 0.025), Vector2(0.975, 0.08), Vector2(0.975, 0.92),
		Vector2(0.92, 0.975), Vector2(0.08, 0.975), Vector2(0.025, 0.92), Vector2(0.025, 0.08),
	], background, rim)
	draw_circle(Vector2(0.76, 0.20), 0.22, Color(rim, 0.10))
	draw_line(Vector2(0.06, 0.84), Vector2(0.94, 0.84), Color(rim, 0.24), 0.018, true)


func draw_hunter() -> void:
	var ink := Color("#091127")
	var cyan := Color("#55e5ff")
	var gold := Color("#ffc857")
	draw_frame(Color("#13284a"), cyan)
	# Shoulders and helmet.
	filled_polygon([Vector2(0.12, 0.94), Vector2(0.20, 0.72), Vector2(0.38, 0.64), Vector2(0.62, 0.64), Vector2(0.80, 0.72), Vector2(0.88, 0.94)], Color("#273357"), ink)
	outlined_circle(Vector2(0.50, 0.50), 0.31, Color("#d7d6c9"), ink, 0.032)
	# Crooked space-western hat.
	filled_polygon([Vector2(0.20, 0.30), Vector2(0.81, 0.25), Vector2(0.75, 0.36), Vector2(0.23, 0.38)], Color("#9a552b"), ink)
	filled_polygon([Vector2(0.34, 0.29), Vector2(0.38, 0.10), Vector2(0.65, 0.08), Vector2(0.72, 0.28)], Color("#b96a35"), ink)
	draw_line(Vector2(0.38, 0.25), Vector2(0.69, 0.23), gold, 0.035, true)
	# Visor and face read at tiny sizes.
	filled_polygon([Vector2(0.24, 0.43), Vector2(0.76, 0.39), Vector2(0.70, 0.62), Vector2(0.30, 0.64)], Color("#173952"), ink)
	draw_line(Vector2(0.31, 0.47), Vector2(0.64, 0.44), Color(0.70, 0.97, 1.0, 0.75), 0.035, true)
	draw_circle(Vector2(0.37, 0.54), 0.035, cyan)
	draw_circle(Vector2(0.62, 0.52), 0.035, cyan)
	draw_line(Vector2(0.43, 0.70), Vector2(0.61, 0.68), ink, 0.025, true)
	# Antenna keeps the silhouette distinctive.
	draw_line(Vector2(0.72, 0.17), Vector2(0.84, 0.08), ink, 0.025, true)
	outlined_circle(Vector2(0.86, 0.065), 0.035, Color("#ff6f7d"), ink, 0.018)


func draw_gloop() -> void:
	var ink := Color("#071426")
	var green := Color("#8de35e")
	var lime := Color("#c8ff75")
	draw_frame(Color("#173b48"), green)
	# Tentacles behind a pear-shaped head.
	for x in [0.26, 0.39, 0.61, 0.74]:
		draw_line(Vector2(0.50, 0.73), Vector2(x, 0.93), ink, 0.085, true)
		draw_line(Vector2(0.50, 0.72), Vector2(x, 0.92), green, 0.050, true)
	outlined_ellipse(Vector2(0.50, 0.53), Vector2(0.34, 0.39), green, ink, 0.030)
	# Three eyes make Gloop identifiable without detail.
	for eye in [Vector2(0.34, 0.43), Vector2(0.50, 0.36), Vector2(0.66, 0.43)]:
		outlined_circle(eye, 0.095, Color("#f3f0db"), ink, 0.024)
		draw_circle(eye + Vector2(0.012, 0.01), 0.037, Color("#25233f"))
		draw_circle(eye - Vector2(0.005, 0.01), 0.012, lime)
	draw_arc(Vector2(0.50, 0.58), 0.15, 0.18, PI - 0.18, 24, ink, 0.030, true)
	draw_circle(Vector2(0.36, 0.65), 0.025, Color(0.24, 0.55, 0.28, 0.7))
	draw_circle(Vector2(0.65, 0.64), 0.018, Color(0.24, 0.55, 0.28, 0.7))


func draw_baron() -> void:
	var ink := Color("#1b0b20")
	var coral := Color("#ff6f57")
	var gold := Color("#ffc857")
	draw_frame(Color("#4a1d35"), coral)
	filled_polygon([Vector2(0.16, 0.94), Vector2(0.25, 0.69), Vector2(0.75, 0.69), Vector2(0.85, 0.94)], Color("#6e2440"), ink)
	outlined_circle(Vector2(0.50, 0.50), 0.31, coral, ink, 0.035)
	# Fuse, crown and monocle communicate his ridiculous nobility.
	draw_line(Vector2(0.55, 0.20), Vector2(0.62, 0.07), ink, 0.032, true)
	draw_line(Vector2(0.62, 0.07), Vector2(0.72, 0.13), gold, 0.028, true)
	filled_polygon([Vector2(0.27, 0.28), Vector2(0.30, 0.12), Vector2(0.42, 0.22), Vector2(0.51, 0.08), Vector2(0.60, 0.22), Vector2(0.72, 0.12), Vector2(0.73, 0.30)], gold, ink)
	for eye in [Vector2(0.38, 0.45), Vector2(0.62, 0.45)]:
		outlined_circle(eye, 0.065, Color("#f4e9d5"), ink, 0.022)
		draw_circle(eye, 0.025, ink)
	draw_arc(Vector2(0.62, 0.45), 0.105, 0.0, TAU, 28, gold, 0.022, true)
	draw_line(Vector2(0.70, 0.52), Vector2(0.75, 0.69), gold, 0.018, true)
	filled_polygon([Vector2(0.50, 0.60), Vector2(0.34, 0.55), Vector2(0.27, 0.66), Vector2(0.47, 0.68)], Color("#301126"), ink)
	filled_polygon([Vector2(0.50, 0.60), Vector2(0.66, 0.55), Vector2(0.73, 0.66), Vector2(0.53, 0.68)], Color("#301126"), ink)


func draw_madame() -> void:
	var ink := Color("#080c22")
	var violet := Color("#b36cff")
	var cyan := Color("#64ebff")
	draw_frame(Color("#2e2151"), violet)
	# Vacuum hoses and a severe orbital collar.
	draw_arc(Vector2(0.50, 0.69), 0.34, 0.08, PI - 0.08, 40, ink, 0.115, true)
	draw_arc(Vector2(0.50, 0.69), 0.34, 0.08, PI - 0.08, 40, violet, 0.067, true)
	outlined_circle(Vector2(0.50, 0.47), 0.31, Color("#8050bb"), ink, 0.035)
	outlined_circle(Vector2(0.50, 0.48), 0.225, Color("#191933"), cyan, 0.024)
	# Asymmetric eyes and breathing valve.
	outlined_circle(Vector2(0.42, 0.44), 0.072, Color("#e9f6f0"), ink, 0.020)
	outlined_circle(Vector2(0.59, 0.42), 0.055, Color("#e9f6f0"), ink, 0.020)
	draw_circle(Vector2(0.43, 0.45), 0.025, violet)
	draw_circle(Vector2(0.59, 0.43), 0.021, violet)
	filled_polygon([Vector2(0.40, 0.58), Vector2(0.60, 0.56), Vector2(0.65, 0.68), Vector2(0.50, 0.74), Vector2(0.35, 0.68)], Color("#3c4164"), ink)
	draw_circle(Vector2(0.50, 0.64), 0.055, cyan)
	draw_circle(Vector2(0.50, 0.64), 0.023, ink)
	draw_line(Vector2(0.28, 0.29), Vector2(0.18, 0.15), violet, 0.034, true)
	draw_line(Vector2(0.72, 0.29), Vector2(0.82, 0.12), violet, 0.034, true)


func draw_mayor() -> void:
	var ink := Color("#160d19")
	var gold := Color("#ffc857")
	var rust := Color("#b9583f")
	draw_frame(Color("#56352b"), gold)
	# A broad coat, badge, hat and mechanical moustache give the chapter boss a civic-western silhouette.
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.19, 0.68), Vector2(0.81, 0.68), Vector2(0.90, 0.96)], rust, ink)
	outlined_ellipse(Vector2(0.50, 0.50), Vector2(0.31, 0.34), Color("#d69a66"), ink, 0.035)
	filled_polygon([Vector2(0.15, 0.30), Vector2(0.85, 0.27), Vector2(0.77, 0.38), Vector2(0.21, 0.39)], Color("#6e3327"), ink)
	filled_polygon([Vector2(0.31, 0.30), Vector2(0.36, 0.09), Vector2(0.68, 0.08), Vector2(0.75, 0.31)], Color("#8d4630"), ink)
	draw_line(Vector2(0.35, 0.27), Vector2(0.72, 0.26), gold, 0.035, true)
	for eye in [Vector2(0.38, 0.47), Vector2(0.62, 0.47)]:
		outlined_circle(eye, 0.063, Color("#f5ead8"), ink, 0.021)
		draw_circle(eye + Vector2(0.012, 0.0), 0.024, ink)
	# A deliberately over-engineered brass moustache.
	filled_polygon([Vector2(0.50, 0.61), Vector2(0.42, 0.56), Vector2(0.25, 0.60), Vector2(0.34, 0.70), Vector2(0.50, 0.65)], gold, ink)
	filled_polygon([Vector2(0.50, 0.61), Vector2(0.58, 0.56), Vector2(0.75, 0.60), Vector2(0.66, 0.70), Vector2(0.50, 0.65)], gold, ink)
	# Crooked seven-point badge: official enough from a distance.
	filled_polygon([Vector2(0.72, 0.72), Vector2(0.76, 0.79), Vector2(0.84, 0.78), Vector2(0.80, 0.85), Vector2(0.84, 0.92), Vector2(0.75, 0.90), Vector2(0.69, 0.95), Vector2(0.68, 0.86), Vector2(0.61, 0.81), Vector2(0.70, 0.79)], gold, ink)


func outlined_circle(center: Vector2, radius: float, fill: Color, outline: Color, width: float) -> void:
	draw_circle(center, radius, outline)
	draw_circle(center, maxf(0.0, radius - width), fill)


func outlined_ellipse(center: Vector2, radii: Vector2, fill: Color, outline: Color, width: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for point_index in 40:
		var angle := TAU * float(point_index) / 40.0
		outer.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		inner.append(center + Vector2(cos(angle) * (radii.x - width), sin(angle) * (radii.y - width)))
	draw_colored_polygon(outer, outline)
	draw_colored_polygon(inner, fill)


func filled_polygon(points: Array[Vector2], fill: Color, outline: Color) -> void:
	var polygon := PackedVector2Array(points)
	draw_colored_polygon(polygon, fill)
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, outline, 0.025, true)
