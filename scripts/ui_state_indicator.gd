class_name UIStateIndicator
extends Control

const DEEP := Color("#071126")
const MUTED := Color("#60708f")

var indicator_kind := "checkbox"
var selected := false
var accent := Color("#55e5ff")


func configure(kind: String, is_selected: bool, color: Color) -> void:
	indicator_kind = kind if kind in ["checkbox", "radio", "toggle"] else "checkbox"
	selected = is_selected
	accent = color
	custom_minimum_size = Vector2(44, 28) if indicator_kind == "toggle" else Vector2(28, 28)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	match indicator_kind:
		"radio":
			draw_circle(Vector2(14, 14), 10.0, accent if selected else MUTED)
			draw_circle(Vector2(14, 14), 7.0, DEEP)
			if selected:
				draw_circle(Vector2(14, 14), 4.0, accent)
		"toggle":
			var track := StyleBoxFlat.new()
			track.bg_color = accent.darkened(0.34) if selected else Color("#26334d")
			track.border_color = accent if selected else MUTED
			track.set_border_width_all(2)
			track.set_corner_radius_all(12)
			draw_style_box(track, Rect2(1, 3, 42, 22))
			draw_circle(Vector2(32 if selected else 12, 14), 7.0, Color("#f4f2ff") if selected else Color("#9da8c8"))
		_:
			var box := StyleBoxFlat.new()
			box.bg_color = accent.darkened(0.5) if selected else DEEP
			box.border_color = accent if selected else MUTED
			box.set_border_width_all(2)
			box.set_corner_radius_all(5)
			draw_style_box(box, Rect2(3, 3, 22, 22))
			if selected:
				draw_polyline(PackedVector2Array([Vector2(7, 14), Vector2(12, 19), Vector2(22, 9)]), Color("#f4f2ff"), 3.0, true)
