extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")


func _init() -> void:
	var records := Catalog.current_required_records()
	var summary := Catalog.readiness_summary(records)
	print("CROOKED GALAXY — VISUAL ASSET READINESS")
	print("Required: %d | Available: %d | Missing: %d" % [int(summary.required), int(summary.available), int(summary.missing)])
	var group_names: Array = summary.groups.keys()
	group_names.sort()
	for group_name in group_names:
		var group: Dictionary = summary.groups[group_name]
		print("%-14s %3d/%3d available | %3d missing" % [str(group_name), int(group.available), int(group.required), int(group.missing)])
	if "--missing" in OS.get_cmdline_user_args():
		print("\nMISSING DELIVERY PATHS")
		for entry in Catalog.missing_records(records):
			print("[%s] %s" % [str(entry.group), str(entry.path)])
	quit(0)
