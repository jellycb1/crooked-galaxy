extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")
const Intake = preload("res://scripts/asset_intake_rules.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var candidate_root := argument_value(args, "--candidate-root=")
	var selected_batch := argument_value(args, "--batch=")
	if candidate_root.is_empty():
		printerr("Provide --candidate-root=<folder> pointing to a folder that mirrors res://assets/.")
		quit(2)
		return
	if selected_batch.is_empty():
		selected_batch = "style_lock"
	if not selected_batch in Catalog.PRODUCTION_BATCH_ORDER:
		printerr("Unknown batch '%s'. Expected one of: %s" % [selected_batch, ", ".join(Catalog.PRODUCTION_BATCH_ORDER)])
		quit(2)
		return

	var root_path := candidate_root.simplify_path()
	var manifest: Array[Dictionary] = []
	var metadata_by_path := {}
	var present := 0
	for entry in Catalog.production_delivery_manifest():
		if str(entry.batch) != selected_batch:
			continue
		manifest.append(entry)
		var relative_path := str(entry.path).trim_prefix("res://assets/")
		var candidate_path := root_path.path_join(relative_path)
		if not FileAccess.file_exists(candidate_path):
			continue
		present += 1
		var image := Image.load_from_file(candidate_path)
		metadata_by_path[str(entry.path)] = image_metadata(image)

	var require_complete := "--require-complete" in args
	var errors := Intake.candidate_batch_errors(manifest, metadata_by_path, require_complete)
	print("CROOKED GALAXY — EXTERNAL ASSET CANDIDATE PREFLIGHT")
	print("Batch: %s | Found: %d/%d | Candidate root: %s" % [selected_batch, present, manifest.size(), root_path])
	if not require_complete and present < manifest.size():
		print("INCOMPLETE: %d expected files are not present; use --require-complete for a blocking batch check." % (manifest.size() - present))
	for entry in manifest:
		var status := "FOUND" if metadata_by_path.has(str(entry.path)) else "MISSING"
		print("%-7s %s" % [status, str(entry.path)])
	for error in errors:
		printerr("FAIL: %s" % error)
	if errors.is_empty():
		print("PASS: present candidates satisfy the automated file and canvas contract.")
		print("Manual style evidence and integrated 450x800 review are still required before acceptance.")
	quit(0 if errors.is_empty() else 1)


func argument_value(args: PackedStringArray, prefix: String) -> String:
	for argument in args:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func image_metadata(image: Image) -> Dictionary:
	if image == null or image.is_empty():
		return {"readable": false}
	return {
		"readable": true,
		"width": image.get_width(),
		"height": image.get_height(),
		"has_transparency": image.detect_alpha() != Image.ALPHA_NONE,
	}
