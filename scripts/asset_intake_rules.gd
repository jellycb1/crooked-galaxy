class_name AssetIntakeRules
extends RefCounted

const Catalog = preload("res://scripts/visual_asset_catalog.gd")

const EXACT_CANVASES := {
	"species_base": Vector2i(1024, 1024),
	"species_mask": Vector2i(1024, 1024),
	"species_occlusion": Vector2i(1024, 1024),
	"species_eyes": Vector2i(1024, 1024),
	"species_feature": Vector2i(1024, 1024),
	"species_marking": Vector2i(1024, 1024),
	"planet_habitat": Vector2i(720, 1280),
	"planet_arena": Vector2i(720, 1280),
	"planet_icon": Vector2i(512, 512),
}


static func metadata_errors(kind: String, width: int, height: int, has_transparency: bool) -> Array[String]:
	var errors: Array[String] = []
	if not Catalog.DELIVERY_CONTRACTS.has(kind):
		return ["Unknown delivery kind: %s" % kind]
	if width <= 0 or height <= 0:
		return ["Image has no readable canvas"]

	var max_long_edge := int(Catalog.MAX_LONG_EDGE.get(kind, 0))
	if max_long_edge <= 0 or maxi(width, height) > max_long_edge:
		errors.append("Canvas %dx%d exceeds the %d px long-edge budget" % [width, height, max_long_edge])
	if EXACT_CANVASES.has(kind) and Vector2i(width, height) != EXACT_CANVASES[kind]:
		var expected: Vector2i = EXACT_CANVASES[kind]
		errors.append("Canvas must be exactly %dx%d, received %dx%d" % [expected.x, expected.y, width, height])

	var contract: Dictionary = Catalog.delivery_contract(kind)
	var alpha_required := bool(contract.get("alpha", false))
	if alpha_required and not has_transparency:
		errors.append("Transparent background/layer is required")
	elif not alpha_required and has_transparency:
		errors.append("Opaque artwork is required; habitat transparency is not accepted")
	return errors


static func candidate_batch_errors(manifest: Array[Dictionary], metadata_by_path: Dictionary, require_complete := false) -> Array[String]:
	var errors: Array[String] = []
	for entry in manifest:
		var path := str(entry.get("path", ""))
		if not metadata_by_path.has(path):
			if require_complete:
				errors.append("Missing required delivery: %s" % path)
			continue
		var metadata = metadata_by_path[path]
		if not metadata is Dictionary or not bool(metadata.get("readable", false)):
			errors.append("Unreadable PNG delivery: %s" % path)
			continue
		for error in metadata_errors(
			str(entry.get("kind", "")),
			int(metadata.get("width", 0)),
			int(metadata.get("height", 0)),
			bool(metadata.get("has_transparency", false))
		):
			errors.append("%s — %s" % [path, error])
	return errors
