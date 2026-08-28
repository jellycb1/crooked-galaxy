extends SceneTree

const CollectionRules = preload("res://scripts/collection_rules.gd")

var failures := 0


func _init() -> void:
	var catalog_total := 245
	var discoveries: Array[String] = []
	for index in 25:
		discoveries.append("series_%d" % index)
	var player := {
		"discovered_item_variant_ids": discoveries,
		"claimed_collection_milestones": ["series_1"],
	}
	var milestones := CollectionRules.milestones(player, catalog_total)
	check(milestones.size() == 7, "collection exposes a bounded lifetime milestone ladder")
	check(milestones.map(func(entry): return int(entry.threshold)) == [1, 10, 25, 50, 100, 200, 245], "milestone thresholds cover discovery without daily pressure")
	check(bool(milestones[0].claimed) and bool(milestones[2].complete) and not bool(milestones[3].complete), "completion and claim state remain independent")
	var ready := CollectionRules.rewards_ready(player, catalog_total)
	check(ready.size() == 2 and str(ready[0].id) == "series_10" and str(ready[1].id) == "series_25", "only completed unclaimed rewards become claimable")
	check(milestones.reduce(func(total: int, entry: Dictionary): return total + int(entry.warp_chips), 0) == 27, "the entire catalog grants only a bounded premium lifetime total")
	check(CollectionRules.valid_milestone_ids(catalog_total) == ["series_1", "series_10", "series_25", "series_50", "series_100", "series_200", "series_245"], "save sanitization receives canonical milestone identifiers")
	var compact := CollectionRules.milestones({}, 40)
	check(compact.map(func(entry): return int(entry.threshold)) == [1, 10, 25, 40], "small catalogs receive a final completion milestone without impossible thresholds")
	var launch_catalog := CollectionRules.milestones({}, 380)
	check(launch_catalog.map(func(entry): return int(entry.threshold)) == [1, 10, 25, 50, 100, 200, 300, 350, 380], "launch catalog bridges the measured long tail before full completion")
	check(launch_catalog.reduce(func(total: int, entry: Dictionary): return total + int(entry.warp_chips), 0) == 37, "launch catalog lifetime premium supply remains explicitly bounded")
	if failures == 0:
		print("PASS: permanent series milestones are bounded and deterministic")
		quit(0)
	else:
		printerr("FAIL: %d collection rules test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
