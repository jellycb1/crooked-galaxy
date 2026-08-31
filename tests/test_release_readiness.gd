extends SceneTree

const Readiness = preload("res://scripts/release_readiness_rules.gd")
const Catalog = preload("res://scripts/visual_asset_catalog.gd")

var failures := 0


func _init() -> void:
	var errors := Readiness.validation_errors()
	check(errors.is_empty(), "the level 1-30 mechanical scope remains internally complete: %s" % "; ".join(errors))
	var scope := Readiness.production_slice_summary()
	check(int(scope.classes) == 3, "slice contains the three launch classes")
	check(int(scope.species) == 8, "slice contains the eight cosmetic launch species")
	check(int(scope.planets) == 6, "slice contains six worlds")
	check(int(scope.targets) == 24, "slice contains twenty-four targets")
	check(int(scope.incidents) == 12, "slice contains twelve incidents")
	check(int(scope.transports) == 4, "slice contains all four transports")
	check(int(scope.rift_stages) == 6, "slice contains the first six Rift encounters")

	var records := Catalog.production_slice_required_records()
	var summary := Catalog.readiness_summary(records)
	check(records.size() == 151, "visual gate tracks exactly 151 final art deliveries")
	check(count_group(records, "classes") == 3, "visual gate tracks three class identities")
	check(count_group(records, "species") == 96, "visual gate tracks the modular species kit")
	check(count_group(records, "targets") == 24, "visual gate tracks only level 1-30 targets")
	check(count_group(records, "planets") == 18, "visual gate tracks three deliveries for each slice world")
	check(count_group(records, "transports") == 4, "visual gate tracks all launch transports")
	check(count_group(records, "rift") == 6, "visual gate tracks only the first six Rift enemies")
	check(int(summary.available) + int(summary.missing) == 151, "visual readiness cannot hide an unclassified delivery")
	check(Catalog.technical_errors(records).is_empty(), "available slice art loads and respects its mobile budget")

	var annual_paths := {}
	for entry in Catalog.current_required_records():
		annual_paths[str(entry.path)] = true
	for entry in records:
		check(annual_paths.has(str(entry.path)), "slice delivery belongs to the annual catalog: %s" % str(entry.path))

	if failures == 0:
		print("PASS: level 1-30 release scope is measurable and mechanically complete")
	quit(1 if failures > 0 else 0)


func count_group(records: Array[Dictionary], group: String) -> int:
	var count := 0
	for entry in records:
		if str(entry.get("group", "")) == group:
			count += 1
	return count


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
