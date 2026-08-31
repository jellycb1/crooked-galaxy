extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")
const Intake = preload("res://scripts/asset_intake_rules.gd")

var failures := 0


func _init() -> void:
	check(Intake.metadata_errors("species_base", 1024, 1024, true).is_empty(), "species base accepts the shared transparent canvas")
	check(not Intake.metadata_errors("species_eyes", 900, 1024, true).is_empty(), "species layers reject canvas drift")
	check(not Intake.metadata_errors("species_feature", 1024, 1024, false).is_empty(), "species layers reject baked opaque backgrounds")
	check(Intake.metadata_errors("planet_habitat", 720, 1280, false).is_empty(), "habitat accepts the exact opaque 9:16 canvas")
	check(not Intake.metadata_errors("planet_habitat", 720, 1280, true).is_empty(), "habitat rejects transparent holes")
	check(Intake.metadata_errors("planet_arena", 720, 1280, true).is_empty(), "arena accepts the aligned transparent overlay canvas")
	check(not Intake.metadata_errors("planet_icon", 500, 500, true).is_empty(), "planet medal rejects non-contract canvas")
	check(Intake.metadata_errors("planet_icon", 512, 512, true).is_empty(), "planet medal accepts its exact transparent square")
	check(not Intake.metadata_errors("class_promo", 1200, 900, true).is_empty(), "class promotion rejects oversized imports")
	check(Intake.metadata_errors("target_portrait", 800, 1024, true).is_empty(), "target accepts a transparent portrait within budget")

	var pilot: Array[Dictionary] = []
	for entry in Catalog.production_delivery_manifest():
		if str(entry.batch) == "style_lock":
			pilot.append(entry)
	var missing_errors := Intake.candidate_batch_errors(pilot, {}, true)
	check(missing_errors.size() == 17, "strict pilot preflight reports every missing delivery")
	check(Intake.candidate_batch_errors(pilot, {}, false).is_empty(), "incremental preflight permits a partial external work folder")
	var unreadable := {str(pilot[0].path): {"readable": false}}
	check(Intake.candidate_batch_errors(pilot, unreadable, false).size() == 1, "present corrupt PNG fails even in incremental mode")

	if failures == 0:
		print("PASS: external asset intake preflight enforces canvas, alpha, budget and completeness")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
