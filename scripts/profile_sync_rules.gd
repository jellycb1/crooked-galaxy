class_name ProfileSyncRules
extends RefCounted

const Protocol = preload("res://scripts/backend_protocol_rules.gd")
const Economy = preload("res://scripts/remote_economy_rules.gd")

const CACHE_SCHEMA := 1
const AUTHORITY_CACHE_SCHEMA := 2
const MAX_CACHE_AGE_MS := 604800000

const ACTION_USE_REMOTE := "use_remote_snapshot"
const ACTION_RETRY_PENDING := "retry_pending_commands"
const ACTION_REVIEW_CONFLICT := "review_conflict"
const ACTION_REJECT_REMOTE := "reject_remote_state"

const MIGRATION_NONE := "none"
const MIGRATION_CUTOVER_REQUIRED := "archive_local_start_remote_required"
const MIGRATION_ARCHIVE_AND_START_REMOTE := "archive_local_start_remote"


static func make_read_only_cache(snapshot: Dictionary, account_id: String, character_id: String, cached_at_unix_ms: int) -> Dictionary:
	var canonical := Protocol.canonical_character_snapshot(snapshot, account_id, character_id)
	if canonical.is_empty() or cached_at_unix_ms < int(canonical.server_unix_ms) or cached_at_unix_ms > Protocol.MAX_UNIX_MS:
		return {}
	return {
		"cache_schema": CACHE_SCHEMA,
		"account_id": account_id,
		"character_id": character_id,
		"server_revision": int(canonical.revision),
		"cached_at_unix_ms": cached_at_unix_ms,
		"snapshot": canonical,
	}


static func open_read_only_cache(cache: Dictionary, account_id: String, character_id: String, now_unix_ms: int) -> Dictionary:
	if int(cache.get("cache_schema", -1)) != CACHE_SCHEMA or str(cache.get("account_id", "")) != account_id or str(cache.get("character_id", "")) != character_id:
		return {}
	var cached_at := int(cache.get("cached_at_unix_ms", -1))
	if cached_at < 0 or now_unix_ms < cached_at or now_unix_ms - cached_at > MAX_CACHE_AGE_MS:
		return {}
	var snapshot_value = cache.get("snapshot", null)
	if not snapshot_value is Dictionary:
		return {}
	var canonical := Protocol.canonical_character_snapshot(snapshot_value, account_id, character_id)
	if canonical.is_empty() or int(cache.get("server_revision", -1)) != int(canonical.revision):
		return {}
	return {
		"state": "offline_cached",
		"authority": "cached_server",
		"read_only": true,
		"economic_mutations_allowed": false,
		"social_actions_allowed": false,
		"billing_allowed": false,
		"age_ms": now_unix_ms - cached_at,
		"snapshot": canonical,
	}


static func canonical_authority_unit(character_snapshot: Dictionary, economy_snapshot: Dictionary, build_snapshot: Dictionary, account_id: String, character_id: String) -> Dictionary:
	var character := Protocol.canonical_character_snapshot(character_snapshot, account_id, character_id)
	var economy := Economy.canonical_economy_snapshot(economy_snapshot, account_id, character_id)
	var build := Economy.canonical_build_snapshot(build_snapshot, account_id, character_id)
	if character.is_empty() or economy.is_empty() or build.is_empty():
		return {}
	var revision := int(character.revision)
	if int(economy.revision) != revision or int(build.revision) != revision:
		return {}
	var profile: Dictionary = character.profile
	var wallet: Dictionary = economy.economy
	for key in ["level", "xp", "credits", "warp_chips", "scrap"]:
		if not profile.has(key) or typeof(profile[key]) not in [TYPE_INT, TYPE_FLOAT] or int(profile[key]) != int(wallet[key]):
			return {}
	if int(build.build.inventory_revision) != int(wallet.inventory_revision) or build.build.inventory.size() != int(wallet.inventory_count):
		return {}
	return {"revision": revision, "character": character, "economy": economy, "build": build}


static func make_read_only_authority_cache(character_snapshot: Dictionary, economy_snapshot: Dictionary, build_snapshot: Dictionary, account_id: String, character_id: String, cached_at_unix_ms: int) -> Dictionary:
	var unit := canonical_authority_unit(character_snapshot, economy_snapshot, build_snapshot, account_id, character_id)
	if unit.is_empty():
		return {}
	var latest_server_time := maxi(int(unit.character.server_unix_ms), maxi(int(unit.economy.server_unix_ms), int(unit.build.server_unix_ms)))
	if cached_at_unix_ms < latest_server_time or cached_at_unix_ms > Protocol.MAX_UNIX_MS:
		return {}
	return {
		"cache_schema": AUTHORITY_CACHE_SCHEMA,
		"account_id": account_id,
		"character_id": character_id,
		"server_revision": int(unit.revision),
		"cached_at_unix_ms": cached_at_unix_ms,
		"character_snapshot": unit.character,
		"economy_snapshot": unit.economy,
		"build_snapshot": unit.build,
	}


static func open_read_only_authority_cache(cache: Dictionary, account_id: String, character_id: String, now_unix_ms: int) -> Dictionary:
	if int(cache.get("cache_schema", -1)) != AUTHORITY_CACHE_SCHEMA or str(cache.get("account_id", "")) != account_id or str(cache.get("character_id", "")) != character_id:
		return {}
	var cached_at := int(cache.get("cached_at_unix_ms", -1))
	if cached_at < 0 or now_unix_ms < cached_at or now_unix_ms - cached_at > MAX_CACHE_AGE_MS:
		return {}
	for key in ["character_snapshot", "economy_snapshot", "build_snapshot"]:
		if not cache.get(key, null) is Dictionary:
			return {}
	var unit := canonical_authority_unit(cache.character_snapshot, cache.economy_snapshot, cache.build_snapshot, account_id, character_id)
	if unit.is_empty() or int(cache.get("server_revision", -1)) != int(unit.revision):
		return {}
	return {
		"state": "offline_cached",
		"authority": "cached_server",
		"read_only": true,
		"economic_mutations_allowed": false,
		"social_actions_allowed": false,
		"billing_allowed": false,
		"age_ms": now_unix_ms - cached_at,
		"revision": int(unit.revision),
		"snapshot": unit.character,
		"character_snapshot": unit.character,
		"economy_snapshot": unit.economy,
		"build_snapshot": unit.build,
	}


static func reconnect_action(cached_revision: int, remote_revision: int, pending_commands: Array, remote_owned: bool) -> String:
	if not remote_owned or cached_revision < 0 or remote_revision < 0 or remote_revision < cached_revision:
		return ACTION_REJECT_REMOTE
	if pending_commands.is_empty():
		return ACTION_USE_REMOTE
	if not _valid_pending_commands(pending_commands):
		return ACTION_REJECT_REMOTE
	if remote_revision == cached_revision:
		return ACTION_RETRY_PENDING
	return ACTION_REVIEW_CONFLICT


static func migration_offer(local_player: Dictionary, remote_snapshot: Dictionary, already_decided: bool) -> String:
	if already_decided or not _established_local_profile(local_player) or not _pristine_remote_profile(remote_snapshot):
		return MIGRATION_NONE
	return MIGRATION_CUTOVER_REQUIRED


static func canonical_migration_choice(choice: String, offer: String) -> String:
	if offer != MIGRATION_CUTOVER_REQUIRED:
		return MIGRATION_NONE
	if choice == MIGRATION_ARCHIVE_AND_START_REMOTE:
		return MIGRATION_ARCHIVE_AND_START_REMOTE
	return MIGRATION_NONE


static func _valid_pending_commands(commands: Array) -> bool:
	var identities := {}
	for command in commands:
		if not command is Dictionary:
			return false
		var command_id := str(command.get("command_id", ""))
		var idempotency_key := str(command.get("idempotency_key", ""))
		if command_id.is_empty() or idempotency_key.is_empty() or identities.has(idempotency_key):
			return false
		identities[idempotency_key] = command_id
	return true


static func _established_local_profile(player: Dictionary) -> bool:
	return not player.is_empty() and str(player.get("character_id", "")).length() > 0 \
		and (int(player.get("level", 1)) > 1 or int(player.get("xp", 0)) > 0 or int(player.get("wins", 0)) > 0)


static func _pristine_remote_profile(snapshot: Dictionary) -> bool:
	if str(snapshot.get("authority", "")) != "server" or int(snapshot.get("revision", -1)) != 0:
		return false
	var profile = snapshot.get("profile", null)
	return profile is Dictionary and int(profile.get("level", -1)) == 1 and int(profile.get("xp", -1)) == 0 \
		and int(profile.get("credits", -1)) == 25 and int(profile.get("warp_chips", -1)) == 0 and int(profile.get("scrap", -1)) == 0
