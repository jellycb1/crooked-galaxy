extends SceneTree

const ManifestRules = preload("res://scripts/backend_content_manifest_rules.gd")
const OUTPUT_PATH := "res://backend/src/generated_content.ts"


func _init() -> void:
	var expected := ManifestRules.render_typescript()
	var check_only := "--check" in OS.get_cmdline_user_args()
	if check_only:
		var existing := FileAccess.get_file_as_string(OUTPUT_PATH)
		if existing != expected:
			printerr("FAIL: backend content manifest is stale; run the generator.")
			quit(1)
			return
		print("PASS: generated backend content manifest matches the canonical Godot catalog")
		quit(0)
		return
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("FAIL: cannot write %s" % OUTPUT_PATH)
		quit(1)
		return
	file.store_string(expected)
	file.close()
	print("WROTE: %s" % OUTPUT_PATH)
	quit(0)
