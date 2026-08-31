extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")

var failures := 0


func _init() -> void:
	var manifest := Catalog.production_delivery_manifest()
	check(manifest.size() == 151, "manifest covers every level 1-30 visual delivery")
	check(count_batch(manifest, "style_lock") == 17, "style-lock pilot is the complete 17-file representative set")
	check(count_batch(manifest, "identity") == 86, "identity batch completes remaining classes and species")
	check(count_batch(manifest, "worlds") == 38, "world batch completes remaining targets and planet kits")
	check(count_batch(manifest, "transports") == 4, "transport batch contains all four launch vehicles")
	check(count_batch(manifest, "rift") == 6, "Rift batch contains the first six enemies")

	var observed_paths := {}
	var previous_order := -1
	for entry in manifest:
		check(int(entry.batch_order) >= previous_order, "manifest remains ordered by production batch")
		previous_order = int(entry.batch_order)
		check(not observed_paths.has(str(entry.path)), "manifest path is unique: %s" % str(entry.path))
		observed_paths[str(entry.path)] = true
		check(not str(entry.atomic_set).is_empty(), "delivery has an atomic integration set")
		var contract: Dictionary = entry.contract
		check(not contract.is_empty(), "delivery kind has a technical contract: %s" % str(entry.kind))
		check(not str(contract.get("canvas", "")).is_empty(), "delivery contract specifies a canvas")
		check(not str(contract.get("display", "")).is_empty(), "delivery contract specifies phone presentation")
		check(contract.has("alpha"), "delivery contract specifies transparency")
		check(not str(contract.get("anchor", "")).is_empty(), "delivery contract specifies anchoring")

	var terran_sets := manifest.filter(func(entry): return str(entry.atomic_set) == "species:terran")
	check(terran_sets.size() == 12 and terran_sets.all(func(entry): return str(entry.batch) == "style_lock"), "pilot species is delivered atomically")
	var dustball_sets := manifest.filter(func(entry): return str(entry.atomic_set) == "planet:dustball_prime")
	check(dustball_sets.size() == 3 and dustball_sets.all(func(entry): return str(entry.batch) == "style_lock"), "pilot planet is delivered atomically")

	if failures == 0:
		print("PASS: release asset manifest is complete, ordered, atomic and technically specified")
	quit(1 if failures > 0 else 0)


func count_batch(manifest: Array[Dictionary], batch: String) -> int:
	return manifest.filter(func(entry): return str(entry.batch) == batch).size()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
