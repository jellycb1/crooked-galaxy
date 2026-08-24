class_name SaveMigrations
extends RefCounted

const CURRENT_VERSION := 5


static func migrate(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("version", 0))
	if version <= 0 or version > CURRENT_VERSION:
		return {}
	var migrated := payload.duplicate(true)
	while version < CURRENT_VERSION:
		match version:
			1:
				migrated = migrate_v1_to_v2(migrated)
				version = 2
			2:
				migrated = migrate_v2_to_v3(migrated)
				version = 3
			3:
				migrated = migrate_v3_to_v4(migrated)
				version = 4
			4:
				migrated = migrate_v4_to_v5(migrated)
				version = 5
			_:
				return {}
		migrated.version = version
	return migrated


static func migrate_v1_to_v2(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("claimed_milestones"):
		player.claimed_milestones = []
	if not player.has("career_credits_claimed"):
		player.career_credits_claimed = 0
	if not player.has("career_scrap_claimed"):
		player.career_scrap_claimed = 0
	migrated.player = player
	return migrated


static func migrate_v2_to_v3(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("locked_item_ids"):
		player.locked_item_ids = []
	if not player.has("equipment_loadouts"):
		player.equipment_loadouts = [{"weapon_id": "", "armor_id": ""}, {"weapon_id": "", "armor_id": ""}]
	for slot in ["weapon", "armor"]:
		var item: Dictionary = player.get(slot, {})
		if not item.has("id"):
			item.id = "migrated_%s" % slot
		player[slot] = item
	migrated.player = player
	return migrated


static func migrate_v3_to_v4(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("capture_streak"):
		player.capture_streak = 0
	if not player.has("best_capture_streak"):
		player.best_capture_streak = int(player.capture_streak)
	migrated.player = player
	return migrated


static func migrate_v4_to_v5(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("reduced_motion"):
		player.reduced_motion = false
	migrated.player = player
	return migrated
