class_name AccountRules
extends RefCounted

const LOCAL_MODE := "local_test"
const LEGACY_LOCAL_MODE := "legacy_local"
const LOCAL_PROVIDER_ID := "local_device"
const LOCAL_ACCOUNT_ID := "local_account_primary"
const LOCAL_SESSION_ID := "local_primary"
const LOCAL_CHARACTER_ID := "local_character_primary"

const SESSION_LOCAL_READY := "local_ready"
const SESSION_AUTHENTICATED := "authenticated"
const SESSION_EXPIRED := "expired"

const SYNC_LOCAL_ONLY := "local_only"
const SYNC_OFFLINE_CACHED := "offline_cached"
const SYNC_SYNCHRONIZED := "synchronized"
const SYNC_CONFLICT := "conflict"

const RESOLUTION_LOCAL_ONLY := "local_only"
const RESOLUTION_SYNCHRONIZED := "synchronized"
const RESOLUTION_UPLOAD_LOCAL := "upload_local"
const RESOLUTION_DOWNLOAD_REMOTE := "download_remote"
const RESOLUTION_MANUAL_CONFLICT := "manual_conflict"
const RESOLUTION_REJECT_FOREIGN := "reject_foreign_character"


static func create_local_account(locale_id: String, server_id: String, character_id := LOCAL_CHARACTER_ID) -> Dictionary:
	return {
		"mode": LOCAL_MODE,
		"provider_id": LOCAL_PROVIDER_ID,
		"account_id": LOCAL_ACCOUNT_ID,
		"session_id": LOCAL_SESSION_ID,
		"session_state": SESSION_LOCAL_READY,
		"server_id": server_id,
		"locale_id": locale_id,
		"active_character_id": character_id,
		"owned_character_ids": [character_id],
		"authority": "device",
		"sync_state": SYNC_LOCAL_ONLY,
		"local_revision": 0,
		"last_server_revision": 0,
	}


static func canonicalize_local_account(loaded: Dictionary, character_id: String) -> Dictionary:
	if loaded.is_empty():
		return {}
	var mode := str(loaded.get("mode", ""))
	if mode != LOCAL_MODE and mode != LEGACY_LOCAL_MODE:
		return {}
	var canonical_character_id := character_id if not character_id.is_empty() else str(loaded.get("active_character_id", LOCAL_CHARACTER_ID))
	if canonical_character_id.is_empty():
		canonical_character_id = LOCAL_CHARACTER_ID
	if loaded.has("provider_id") and str(loaded.provider_id) != LOCAL_PROVIDER_ID:
		return {}
	if loaded.has("session_state") and str(loaded.session_state) != SESSION_LOCAL_READY:
		return {}
	if loaded.has("authority") and str(loaded.authority) != "device":
		return {}
	if loaded.has("sync_state") and str(loaded.sync_state) != SYNC_LOCAL_ONLY:
		return {}
	if loaded.has("active_character_id") and str(loaded.active_character_id) != canonical_character_id:
		return {}
	if loaded.has("owned_character_ids") and (not loaded.owned_character_ids is Array or not loaded.owned_character_ids.has(canonical_character_id)):
		return {}
	if int(loaded.get("local_revision", 0)) < 0 or int(loaded.get("last_server_revision", 0)) < 0:
		return {}
	var result := create_local_account(str(loaded.get("locale_id", "")), str(loaded.get("server_id", "")), canonical_character_id)
	result.mode = mode
	result.session_id = str(loaded.get("session_id", LOCAL_SESSION_ID))
	result.account_id = str(loaded.get("account_id", LOCAL_ACCOUNT_ID))
	result.local_revision = maxi(0, int(loaded.get("local_revision", 0)))
	result.last_server_revision = maxi(0, int(loaded.get("last_server_revision", 0)))
	return result


static func is_local_session_ready(account: Dictionary) -> bool:
	var mode := str(account.get("mode", ""))
	return (mode == LOCAL_MODE or mode == LEGACY_LOCAL_MODE) \
		and str(account.get("session_id", "")).length() > 0 \
		and str(account.get("session_id", "")).length() <= 64 \
		and str(account.get("session_state", SESSION_LOCAL_READY)) == SESSION_LOCAL_READY


static func owns_character(account: Dictionary, character_id: String) -> bool:
	if character_id.is_empty():
		return false
	var owned = account.get("owned_character_ids", [])
	return owned is Array and owned.has(character_id) and str(account.get("active_character_id", "")) == character_id


static func account_for_local_commit(account: Dictionary) -> Dictionary:
	if account.is_empty():
		return {}
	var committed := account.duplicate(true)
	committed.local_revision = maxi(0, int(committed.get("local_revision", 0))) + 1
	committed.sync_state = SYNC_LOCAL_ONLY
	committed.authority = "device"
	return committed


static func progress_resolution(character_id: String, remote_character_id: String, local_revision: int, remote_revision: int, last_server_revision: int, has_pending_local_changes: bool, remote_available: bool) -> String:
	if not remote_available:
		return RESOLUTION_LOCAL_ONLY
	if character_id.is_empty() or remote_character_id != character_id:
		return RESOLUTION_REJECT_FOREIGN
	if has_pending_local_changes and remote_revision > last_server_revision:
		return RESOLUTION_MANUAL_CONFLICT
	if remote_revision > local_revision:
		return RESOLUTION_DOWNLOAD_REMOTE
	if local_revision > remote_revision:
		return RESOLUTION_UPLOAD_LOCAL
	return RESOLUTION_SYNCHRONIZED
