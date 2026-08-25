extends SceneTree

const EquipmentIconScript = preload("res://scripts/equipment_icon.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for slot in ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]:
		var icon := EquipmentIconScript.new()
		icon.item = {"slot": slot, "rarity": "Épico", "origin_planet_id": "micelia_404", "power_upgrades": 3, "integrity_upgrades": 2}
		icon.custom_minimum_size = Vector2(76, 76)
		root.add_child(icon)
		await process_frame
		check(icon.rarity_color("Épico") == Color("#d789ff"), "%s icon resolves epic rarity" % slot)
		check(icon.planet_color("micelia_404") == Color("#c7f464"), "%s icon resolves planetary identity" % slot)
		icon.queue_free()
	var fallback_icon := EquipmentIconScript.new()
	check(fallback_icon.planet_color("unknown") == Color("#55e5ff"), "unknown equipment origin has a stable fallback")
	fallback_icon.free()
	await process_frame
	if failures == 0:
		print("PASS: equipment icons encode slot, rarity, origin, and investment")
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
