extends SceneTree

const OUTPUT_PATH := "res://builds/ui_board.png"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds"))
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error == OK:
		print("Captured UI to %s" % OUTPUT_PATH)
		quit(0)
	else:
		printerr("Failed to capture UI: %s" % error_string(error))
		quit(1)
