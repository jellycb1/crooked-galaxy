extends SceneTree

const OUTPUT_PATH := "res://builds/ui_board.png"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var state = root.get_node_or_null("GameState")
	if state:
		state.persistence_enabled = false
		state.player = state.default_player()
		state.phase = state.Phase.BOARD
		state.current_bounty = {}
		state.pending_loot = {}
		state.last_notice = ""
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
