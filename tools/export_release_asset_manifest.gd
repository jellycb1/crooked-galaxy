extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var selected_batch := ""
	for argument in args:
		if argument.begins_with("--batch="):
			selected_batch = argument.trim_prefix("--batch=")
	if not selected_batch.is_empty() and not selected_batch in Catalog.PRODUCTION_BATCH_ORDER:
		printerr("Unknown batch '%s'. Expected one of: %s" % [selected_batch, ", ".join(Catalog.PRODUCTION_BATCH_ORDER)])
		quit(2)
		return

	var manifest: Array[Dictionary] = []
	for entry in Catalog.production_delivery_manifest():
		if (selected_batch.is_empty() or str(entry.batch) == selected_batch) and (not "--missing" in args or not bool(entry.exists)):
			manifest.append(entry)

	if "--json" in args:
		print(JSON.stringify({"schema": 1, "slice": "levels_1_30", "count": manifest.size(), "deliveries": manifest}, "\t"))
		quit(0)
		return

	print("CROOKED GALAXY — LEVEL 1-30 ASSET DELIVERY MANIFEST")
	print("Filter: %s | Deliveries: %d" % [selected_batch if not selected_batch.is_empty() else "all batches", manifest.size()])
	var current_batch := ""
	for entry in manifest:
		if str(entry.batch) != current_batch:
			current_batch = str(entry.batch)
			print("\n[%s]" % current_batch.to_upper())
		var contract: Dictionary = entry.contract
		print("%s | set=%s | canvas=%s | display=%s | alpha=%s | anchor=%s" % [
			str(entry.path), str(entry.atomic_set), str(contract.canvas), str(contract.display),
			"yes" if bool(contract.alpha) else "no", str(contract.anchor),
		])
	quit(0)
