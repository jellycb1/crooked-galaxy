extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")
const Approvals = preload("res://scripts/production_asset_approvals.gd")

var failures := 0


func _init() -> void:
	check(Approvals.APPROVED_FILES.is_empty(), "the pending art batch starts rejected by default")
	check(Catalog.approved_file_errors().is_empty(), "the production approval registry is internally valid")
	check(Catalog.load_approved_texture("class_promo", "warrant_breaker") == null, "an unapproved class candidate cannot enter runtime")
	check(Catalog.approved_character_texture("gloop") == null, "an unapproved target candidate cannot enter runtime")
	check(not Catalog.approved_atomic_set_complete("species_base", "terran"), "a partial species set cannot replace its fallback")
	check(not Catalog.approved_atomic_set_complete("planet_habitat", "dustball_prime"), "a partial planet set cannot replace its fallback")
	check(Catalog.load_approved_texture("transport", "junkbox") == null, "an unapproved transport candidate cannot enter runtime")
	check(Catalog.rift_asset_id_for_stage("rift_customs_drone") == "dead_customs_01", "the first Rift stage resolves its authored portrait id")
	check(Catalog.rift_asset_id_for_stage("frozen_verdict__rift_customs_drone") == "frozen_verdict_01", "later Rift realities resolve their authored portrait ids")
	check(Catalog.rift_asset_id_for_stage("unknown_stage").is_empty(), "unknown Rift stages fail closed")

	if failures == 0:
		print("PASS: production art is hash-pinned, atomic and rejected by default")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
