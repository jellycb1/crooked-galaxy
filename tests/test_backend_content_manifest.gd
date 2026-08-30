extends SceneTree

const ManifestRules = preload("res://scripts/backend_content_manifest_rules.gd")
const OUTPUT_PATH := "res://backend/src/generated_content.ts"


func _init() -> void:
	var manifest := ManifestRules.manifest()
	var failures := 0
	if int(manifest.get("schema_version", 0)) != 1:
		failures += 1
	if manifest.planets.size() != 35 or manifest.targets.size() != 140:
		failures += 1
	if manifest.approaches.map(func(value): return str(value.id)) != ["quiet_net", "hot_hatch", "premium_warrant"]:
		failures += 1
	if manifest.classes.map(func(value): return str(value.id)) != ["warrant_breaker", "orbit_gunslinger", "contract_hacker"]:
		failures += 1
	if str(manifest.get("content_hash", "")).length() != 64:
		failures += 1
	if JSON.stringify(manifest.enemy_profiles).contains("title") or JSON.stringify(manifest.enemy_profiles).contains("summary"):
		failures += 1
	if not manifest.planets.all(func(planet): return planet.target_ids.size() == 4):
		failures += 1
	if FileAccess.get_file_as_string(OUTPUT_PATH) != ManifestRules.render_typescript():
		failures += 1
	if failures == 0:
		print("PASS: backend manifest shares all planets, targets, approaches, classes, and combat profiles with Godot")
		quit(0)
	else:
		printerr("FAIL: %d backend content manifest contract(s) failed" % failures)
		quit(1)
