extends SceneTree

const Catalog = preload("res://scripts/visual_asset_catalog.gd")

const CONTRACTS := {
	"confirmation_modal": Vector2i(512, 384),
	"success_receipt": Vector2i(512, 384),
	"tooltip_frame": Vector2i(384, 192),
	"selected_tab": Vector2i(384, 96),
	"plain_divider": Vector2i(512, 64),
	"slider_handle": Vector2i(96, 96),
	"rarity_tier_1": Vector2i(256, 256),
	"rarity_tier_2": Vector2i(256, 256),
	"rarity_tier_3": Vector2i(256, 256),
	"rarity_tier_4": Vector2i(256, 256),
	"portrait_allied": Vector2i(256, 256),
	"portrait_boss": Vector2i(256, 256),
	"portrait_hostile": Vector2i(256, 256),
	"portrait_neutral": Vector2i(256, 256),
}

var failures := 0


func _init() -> void:
	var raw_bytes := 0
	for asset_id in CONTRACTS:
		var texture := Catalog.load_texture("runtime", asset_id)
		check(texture != null, "runtime UI texture resolves: %s" % asset_id)
		if texture == null:
			continue
		var image := texture.get_image()
		check(not image.is_empty() and image.get_size() == CONTRACTS[asset_id], "runtime UI canvas stays canonical: %s" % asset_id)
		check(image.get_format() == Image.FORMAT_RGBA8, "runtime UI texture preserves RGBA8 alpha: %s" % asset_id)
		check(image.get_pixel(0, 0).a <= 0.01, "runtime UI texture preserves a transparent outer corner: %s" % asset_id)
		raw_bytes += image.get_width() * image.get_height() * 4
	check(raw_bytes <= 5 * 1024 * 1024, "complete specialized UI family stays below the five-MiB decoded budget")
	if failures == 0:
		print("PASS: supplied runtime UI assets preserve size, alpha and mobile memory contracts")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
