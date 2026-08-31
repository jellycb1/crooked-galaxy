class_name CombatEffectsOverlay
extends Control

var events: Array[Dictionary] = []
var draw_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func set_events(value: Array[Dictionary]) -> void:
	events.assign(value)
	queue_redraw()


func _draw() -> void:
	draw_count += 1
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
