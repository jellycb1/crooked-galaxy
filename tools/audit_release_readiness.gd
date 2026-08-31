extends SceneTree

const Readiness = preload("res://scripts/release_readiness_rules.gd")
const Catalog = preload("res://scripts/visual_asset_catalog.gd")


func _init() -> void:
	var errors := Readiness.validation_errors()
	var scope := Readiness.production_slice_summary()
	var records := Catalog.production_slice_required_records()
	var visual := Catalog.readiness_summary(records)
	var technical_errors := Catalog.technical_errors(records)
	var require_visual := "--require-visual" in OS.get_cmdline_user_args()

	print("CROOKED GALAXY — LEVEL 1-30 RELEASE READINESS")
	print("Mechanical scope: %d classes | %d species | %d planets | %d targets | %d incidents | %d transports | %d Rift encounters" % [
		int(scope.classes), int(scope.species), int(scope.planets), int(scope.targets),
		int(scope.incidents), int(scope.transports), int(scope.rift_stages),
	])
	print("Mechanical contract: %s" % ("PASS" if errors.is_empty() else "FAIL"))
	print("Final visual deliveries: %d/%d available | %d missing" % [int(visual.available), int(visual.required), int(visual.missing)])
	print("Available-asset technical gate: %s" % ("PASS" if technical_errors.is_empty() else "FAIL"))
	var group_names: Array = visual.groups.keys()
	group_names.sort()
	for group_name in group_names:
		var group: Dictionary = visual.groups[group_name]
		print("%-12s %3d/%3d available | %3d missing" % [str(group_name), int(group.available), int(group.required), int(group.missing)])

	for error in errors:
		printerr("FAIL: %s" % error)
	for error in technical_errors:
		printerr("FAIL: %s" % error)
	if "--missing" in OS.get_cmdline_user_args():
		print("\nMISSING LEVEL 1-30 DELIVERY PATHS")
		for entry in Catalog.missing_records(records):
			print("[%s] %s" % [str(entry.group), str(entry.path)])
	var strict_visual_failure := require_visual and int(visual.missing) > 0
	if strict_visual_failure:
		printerr("FAIL: strict visual gate requires all 151 level 1-30 deliveries")
	quit(0 if errors.is_empty() and technical_errors.is_empty() and not strict_visual_failure else 1)
