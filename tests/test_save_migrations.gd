extends SceneTree

const SaveMigrations = preload("res://scripts/save_migrations.gd")

var failures := 0


func _init() -> void:
	var version_one := {
		"version": 1,
		"player": {
			"credits": 77,
			"weapon": {"name": "Blaster antigo"},
			"armor": {"name": "Colete antigo"},
		},
	}
	var migrated := SaveMigrations.migrate(version_one)
	check(int(migrated.version) == SaveMigrations.CURRENT_VERSION, "version one reaches the current schema")
	check(int(migrated.player.credits) == 77, "existing player data survives the migration chain")
	check(migrated.player.claimed_milestones is Array, "version two career fields are initialized")
	check(migrated.player.locked_item_ids is Array, "version three protection fields are initialized")
	check(migrated.player.equipment_loadouts.size() == 2, "both loadout slots are initialized")
	check(str(migrated.player.weapon.id) == "migrated_weapon", "legacy weapons receive stable ids")
	check(str(migrated.player.armor.id) == "migrated_armor", "legacy armor receives stable ids")
	check(int(migrated.player.capture_streak) == 0 and int(migrated.player.best_capture_streak) == 0, "streak fields are initialized")
	check(not bool(migrated.player.reduced_motion), "motion preference defaults to full during migration")
	check(migrated.player.attributes.size() == 5 and int(migrated.player.attributes.cunning) == 10, "legacy saves receive all five neutral attributes")
	check(int(migrated.player.stat_points) == 0, "a level-one legacy hunter receives no unearned retroactive points")
	check(not version_one.player.has("claimed_milestones"), "migration does not mutate its source payload")

	var existing_ids := {
		"version": 2,
		"player": {
			"weapon": {"id": "kept_weapon"},
			"armor": {"id": "kept_armor"},
		},
	}
	var migrated_ids := SaveMigrations.migrate(existing_ids)
	check(str(migrated_ids.player.weapon.id) == "kept_weapon", "migration preserves existing weapon ids")
	check(str(migrated_ids.player.armor.id) == "kept_armor", "migration preserves existing armor ids")

	var established_v5 := {"version": 5, "player": {"level": 4, "credits": 91}}
	var established_v6 := SaveMigrations.migrate(established_v5)
	check(int(established_v6.player.stat_points) == 6, "established hunters receive two retroactive points for every completed level")
	check(int(established_v6.player.attributes.strength) == 10, "retroactive migration preserves neutral unspent attributes")

	var current := {"version": SaveMigrations.CURRENT_VERSION, "player": {"credits": 5}}
	var current_copy := SaveMigrations.migrate(current)
	current_copy.player.credits = 9
	check(int(current.player.credits) == 5, "current-version payloads are returned as deep copies")
	check(SaveMigrations.migrate({"version": 0}).is_empty(), "unversioned saves are rejected")
	check(SaveMigrations.migrate({"version": SaveMigrations.CURRENT_VERSION + 1}).is_empty(), "future saves are rejected")

	if failures == 0:
		print("PASS: save migrations are deterministic and non-destructive")
		quit(0)
	else:
		printerr("FAIL: %d save migration test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
