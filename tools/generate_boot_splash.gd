extends SceneTree

const SOURCE := "res://assets/boot_splash.svg"
const OUTPUT := "res://assets/boot_splash.png"


func _init() -> void:
	call_deferred("generate")


func generate() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: boot splash generation needs a rendering display; run Godot without --headless")
		quit(2)
		return
	var source_image := Image.load_from_file(SOURCE)
	if source_image == null or source_image.is_empty() or source_image.get_width() != 720 or source_image.get_height() != 1280:
		printerr("FAIL: boot splash source must rasterize at 720x1280")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	var composition := Control.new()
	composition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(composition)
	var artwork := TextureRect.new()
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.texture = ImageTexture.create_from_image(source_image)
	composition.add_child(artwork)
	composition.add_child(centered_text("CROOKED GALAXY", 805.0, 82.0, 62, Color("#55e5ff")))
	composition.add_child(centered_text("CAÇADORES · CONTRATOS · CONFUSÃO", 890.0, 42.0, 20, Color("#b9c2d9")))
	var divider := ColorRect.new()
	divider.position = Vector2(210, 966)
	divider.size = Vector2(300, 5)
	divider.color = Color("#ffc857")
	composition.add_child(divider)
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT)
	if error != OK:
		printerr("FAIL: could not save %s (%s)" % [OUTPUT, error_string(error)])
		quit(1)
		return
	print("PASS: generated %s from tracked SVG source" % OUTPUT)
	quit()


func centered_text(text: String, y: float, height: float, font_size: int, color: Color) -> Label:
	var output := Label.new()
	output.position = Vector2(30, y)
	output.size = Vector2(660, height)
	output.text = text
	output.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	output.add_theme_font_size_override("font_size", font_size)
	output.add_theme_color_override("font_color", color)
	return output
