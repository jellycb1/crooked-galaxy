class_name SaveMigrations
extends RefCounted

const CURRENT_VERSION := 15
const BASE_ATTRIBUTE_VALUE := 10
const ATTRIBUTE_POINTS_PER_LEVEL := 2


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
			5:
				migrated = migrate_v5_to_v6(migrated)
				version = 6
			6:
				migrated = migrate_v6_to_v7(migrated)
				version = 7
			7:
				migrated = migrate_v7_to_v8(migrated)
				version = 8
			8:
				migrated = migrate_v8_to_v9(migrated)
				version = 9
			9:
				migrated = migrate_v9_to_v10(migrated)
				version = 10
			10:
				migrated = migrate_v10_to_v11(migrated)
				version = 11
			11:
				migrated = migrate_v11_to_v12(migrated)
				version = 12
			12:
				migrated = migrate_v12_to_v13(migrated)
				version = 13
			13:
				migrated = migrate_v13_to_v14(migrated)
				version = 14
			14:
				migrated = migrate_v14_to_v15(migrated)
				version = 15
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


static func migrate_v5_to_v6(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("attributes"):
		player.attributes = {
			"strength": BASE_ATTRIBUTE_VALUE,
			"vitality": BASE_ATTRIBUTE_VALUE,
			"dexterity": BASE_ATTRIBUTE_VALUE,
			"intelligence": BASE_ATTRIBUTE_VALUE,
			"cunning": BASE_ATTRIBUTE_VALUE,
		}
	if not player.has("stat_points"):
		player.stat_points = maxi(0, int(player.get("level", 1)) - 1) * ATTRIBUTE_POINTS_PER_LEVEL
	migrated.player = player
	return migrated


static func migrate_v6_to_v7(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("class_id"):
		player.class_id = ""
	migrated.player = player
	return migrated


static func migrate_v7_to_v8(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("market_cycle"):
		player.market_cycle = 0
	if not player.has("market_purchased_offer_ids"):
		player.market_purchased_offer_ids = []
	migrated.player = player
	return migrated


static func migrate_v8_to_v9(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("owned_transport_ids"):
		player.owned_transport_ids = []
	if not player.has("active_transport_id"):
		player.active_transport_id = ""
	migrated.player = player
	return migrated


static func migrate_v9_to_v10(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	var slots := ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]
	for slot in slots:
		if not player.has(slot):
			player[slot] = {}
	var loadouts = player.get("equipment_loadouts", [])
	if loadouts is Array:
		for index in loadouts.size():
			if not loadouts[index] is Dictionary:
				continue
			for slot in slots:
				var id_key := "%s_id" % slot
				if not loadouts[index].has(id_key):
					loadouts[index][id_key] = ""
		player.equipment_loadouts = loadouts
	migrated.player = player
	return migrated


static func migrate_v10_to_v11(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("challenge_floor"):
		player.challenge_floor = 0
	migrated.player = player
	return migrated


static func migrate_v11_to_v12(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	if not player.has("species_id"):
		player.species_id = ""
	if not player.has("hunter_name"):
		player.hunter_name = ""
	migrated.player = player
	# Existing local saves already represent a returning session. Preserve that
	# fact without silently completing any missing character choice.
	if not migrated.has("account"):
		migrated.account = {"mode": "legacy_local", "session_id": "legacy_primary"}
	return migrated


static func migrate_v12_to_v13(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var account = migrated.get("account", {})
	# Preserve established and interrupted character creation. An empty account
	# must still visit login; a real returning local session joins the first shard.
	if account is Dictionary and not account.is_empty():
		if not account.has("server_id"):
			account.server_id = "international_1"
		if not account.has("locale_id"):
			account.locale_id = "pt"
		migrated.account = account
	return migrated


static func migrate_v13_to_v14(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var account = migrated.get("account", {})
	var player: Dictionary = migrated.get("player", {})
	# An interrupted fresh login remains identity-free. Established local profiles
	# receive stable device-owned IDs without inventing credentials or server state.
	if account is Dictionary and not account.is_empty():
		var character_id := str(player.get("character_id", "local_character_primary"))
		if character_id.is_empty():
			character_id = "local_character_primary"
		player.character_id = character_id
		account.provider_id = "local_device"
		account.account_id = str(account.get("account_id", "local_account_primary"))
		account.session_state = "local_ready"
		account.active_character_id = character_id
		account.owned_character_ids = [character_id]
		account.authority = "device"
		account.sync_state = "local_only"
		account.local_revision = maxi(0, int(account.get("local_revision", 0)))
		account.last_server_revision = 0
		migrated.account = account
		migrated.player = player
	return migrated


static func migrate_v14_to_v15(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var player: Dictionary = migrated.get("player", {})
	var legacy_species := {
		"patched_terran": "terran",
		"discontinued_synthetic": "synthetic",
		"nebular_nomad": "starworn",
		"cellar_mycelian": "fungoid",
		"tankborn_abyssal": "abyssal",
		"rusted_ferrite": "mothari",
		"catalog_chimera": "scraproot",
		"unstable_luminar": "glitchlight",
	}
	var old_id := str(player.get("species_id", ""))
	player.species_id = str(legacy_species.get(old_id, old_id))
	# Established hunters receive the neutral preset and never get forced back
	# through onboarding. Interrupted creation still visits customization.
	if not str(player.get("hunter_name", "")).is_empty():
		player.appearance = {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	elif not player.has("appearance"):
		player.appearance = {}
	migrated.player = player
	return migrated
