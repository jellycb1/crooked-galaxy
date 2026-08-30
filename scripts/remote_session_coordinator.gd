class_name RemoteSessionCoordinator
extends RefCounted

const AdapterScript = preload("res://scripts/nakama_backend_adapter.gd")
const CacheStoreScript = preload("res://scripts/profile_cache_store.gd")
const Sync = preload("res://scripts/profile_sync_rules.gd")
const CutoverArchive = preload("res://scripts/local_save_cutover_archive.gd")
const Protocol = preload("res://scripts/backend_protocol_rules.gd")

const STATE_INERT := "inert"
const STATE_CONFIGURED := "configured"
const STATE_AUTHENTICATED := "authenticated"
const STATE_READY := "authoritative_ready"
const STATE_OFFLINE_CACHE := "offline_read_only"

var _adapter = null
var _cache_store = null
var _state := STATE_INERT
var _account_id := ""
var _clock_sample: Dictionary = {}
var _character_snapshot: Dictionary = {}
var _economy_snapshot: Dictionary = {}
var _build_snapshot: Dictionary = {}
var _configuration_summary: Dictionary = {}
var _pending_cutover_offer := Sync.MIGRATION_NONE


func _init(adapter_override = null) -> void:
	_adapter = adapter_override if adapter_override != null else AdapterScript.new()


func state() -> String:
	return _state


func account_id() -> String:
	return _account_id


func character_snapshot() -> Dictionary:
	return _character_snapshot.duplicate(true)


func safe_summary() -> Dictionary:
	return {
		"state": _state,
		"account_id": _account_id,
		"configuration": _configuration_summary.duplicate(true),
		"server_revision": int(_character_snapshot.get("revision", -1)),
		"clock_round_trip_ms": int(_clock_sample.get("round_trip_ms", -1)),
		"read_only": _state == STATE_OFFLINE_CACHE,
		"authority_unit_ready": not _economy_snapshot.is_empty() and not _build_snapshot.is_empty(),
		"economic_mutations_allowed": _state == STATE_READY and not _economy_snapshot.is_empty() and not _build_snapshot.is_empty(),
	}


func connect_explicit_test(configuration: Dictionary, device_id: String) -> Dictionary:
	reset_runtime()
	if not _adapter.configure(configuration):
		return _failure("configuration_rejected")
	_configuration_summary = _adapter.configuration_summary()
	var environment := str(_configuration_summary.get("environment", ""))
	if environment not in ["local", "staging"]:
		return _fail_and_reset("explicit_test_environment_required")
	_state = STATE_CONFIGURED
	var authentication: Dictionary = await _adapter.authenticate_development(device_id) if environment == "local" \
		else await _adapter.authenticate_staging_test(device_id)
	if not bool(authentication.get("ok", false)) or str(authentication.get("authority", "")) != "server":
		return _fail_and_reset("authentication_failed")
	_account_id = str(authentication.get("account_id", ""))
	if _account_id.is_empty() or _account_id != str(_adapter.account_id()):
		return _fail_and_reset("authentication_ownership_failed")
	_state = STATE_AUTHENTICATED
	_clock_sample = await _adapter.sample_server_clock()
	if not bool(_clock_sample.get("ok", false)) or str(_clock_sample.get("authority", "")) != "server":
		return _fail_and_reset("clock_failed")
	var snapshot: Dictionary = await _adapter.get_character()
	if not bool(snapshot.get("ok", false)):
		return _fail_and_reset("snapshot_failed")
	if snapshot.get("exists", true) == false:
		return {
			"ok": true,
			"character_exists": false,
			"account_id": _account_id,
			"clock": _clock_sample.duplicate(true),
			"configuration": _configuration_summary.duplicate(true),
		}
	if not accept_authoritative_snapshot(snapshot):
		return _fail_and_reset("ownership_failed")
	return _connection_result(true)


func create_explicit_test_character(idempotency_key: String, hunter_name: String, class_id: String, species_id: String, appearance: Dictionary) -> Dictionary:
	if _state != STATE_AUTHENTICATED:
		return _failure("authenticated_session_required")
	var snapshot: Dictionary = await _adapter.create_character(idempotency_key, hunter_name, class_id, species_id, appearance)
	if not accept_authoritative_snapshot(snapshot):
		return _failure("character_creation_failed")
	return snapshot


func refresh_authoritative_character() -> Dictionary:
	if _state not in [STATE_AUTHENTICATED, STATE_READY]:
		return _failure("authenticated_session_required")
	var snapshot: Dictionary = await _adapter.get_character()
	if not accept_authoritative_snapshot(snapshot):
		return _failure("authoritative_refetch_failed")
	return snapshot


func accept_authoritative_snapshot(snapshot: Dictionary) -> bool:
	if _state not in [STATE_AUTHENTICATED, STATE_READY] or not bool(snapshot.get("ok", false)):
		return false
	var canonical := Protocol.canonical_character_snapshot(snapshot, _account_id, _account_id)
	if canonical.is_empty():
		return false
	canonical.ok = true
	canonical.exists = true
	_character_snapshot = canonical
	_economy_snapshot = {}
	_build_snapshot = {}
	_state = STATE_READY
	return true


func accept_authoritative_unit(character_snapshot: Dictionary, economy_snapshot: Dictionary, build_snapshot: Dictionary) -> bool:
	if _state != STATE_READY:
		return false
	var unit := Sync.canonical_authority_unit(character_snapshot, economy_snapshot, build_snapshot, _account_id, _account_id)
	if unit.is_empty():
		return false
	_character_snapshot = unit.character
	_economy_snapshot = unit.economy
	_build_snapshot = unit.build
	return true


func prepare_local_cutover(local_player: Dictionary, already_decided: bool) -> String:
	if _state != STATE_READY:
		_pending_cutover_offer = Sync.MIGRATION_NONE
		return _pending_cutover_offer
	_pending_cutover_offer = Sync.migration_offer(local_player, _character_snapshot, already_decided)
	return _pending_cutover_offer


func archive_local_cutover(choice: String, save_path: String, archive_root := CutoverArchive.DEFAULT_ARCHIVE_ROOT) -> Dictionary:
	if _state != STATE_READY or Sync.canonical_migration_choice(choice, _pending_cutover_offer) != Sync.MIGRATION_ARCHIVE_AND_START_REMOTE:
		return _failure("cutover_confirmation_required")
	var created_at := maxi(int(Time.get_unix_time_from_system() * 1000.0), int(_character_snapshot.get("server_unix_ms", 0)))
	var result := CutoverArchive.create(save_path, created_at, archive_root)
	var manifest = result.get("manifest", null)
	if not manifest is Dictionary or str(manifest.get("authority", "")) != "local_archive_only" \
		or bool(manifest.get("may_seed_server_progress", true)) or manifest.get("files", []).is_empty() \
		or not FileAccess.file_exists(save_path):
		return _failure("cutover_archive_failed")
	_pending_cutover_offer = Sync.MIGRATION_NONE
	var accepted := result.duplicate(true)
	accepted.ok = true
	return accepted


func cache_and_disconnect(cache_path: String, now_unix_ms := -1) -> Dictionary:
	if _state != STATE_READY or cache_path.is_empty() or _economy_snapshot.is_empty() or _build_snapshot.is_empty():
		return _failure("complete_authoritative_unit_required")
	var cached_at := now_unix_ms
	if cached_at < 0:
		var latest_server_time := maxi(int(_character_snapshot.get("server_unix_ms", 0)),
			maxi(int(_economy_snapshot.get("server_unix_ms", 0)), int(_build_snapshot.get("server_unix_ms", 0))))
		cached_at = maxi(int(Time.get_unix_time_from_system() * 1000.0), latest_server_time)
	_cache_store = CacheStoreScript.new()
	_cache_store.cache_path = cache_path
	_cache_store.clear()
	if not _cache_store.write_authority_unit(_character_snapshot, _economy_snapshot, _build_snapshot, _account_id, _account_id, cached_at):
		_cache_store.clear()
		_cache_store = null
		return _failure("cache_write_failed")
	_adapter.clear_runtime()
	_configuration_summary = {}
	_clock_sample = {}
	_state = STATE_OFFLINE_CACHE
	var offline: Dictionary = _cache_store.load_authority_unit(_account_id, _account_id, cached_at)
	if not bool(offline.get("read_only", false)) or bool(offline.get("economic_mutations_allowed", true)):
		_cache_store.clear()
		return _failure("cache_open_failed")
	offline.ok = true
	return offline


func reconnect_action(offline_cache: Dictionary, remote_snapshot: Dictionary, pending_commands: Array = []) -> String:
	if not bool(offline_cache.get("read_only", false)) or bool(offline_cache.get("economic_mutations_allowed", true)):
		return Sync.ACTION_REJECT_REMOTE
	var cached = offline_cache.get("snapshot", null)
	if not cached is Dictionary:
		return Sync.ACTION_REJECT_REMOTE
	var account := str(cached.get("account_id", ""))
	var character := str(cached.get("character_id", ""))
	var remote_owned := not account.is_empty() and account == str(remote_snapshot.get("account_id", "")) \
		and character == str(remote_snapshot.get("character_id", ""))
	return Sync.reconnect_action(int(cached.get("revision", -1)), int(remote_snapshot.get("revision", -1)), pending_commands, remote_owned)


func clear_cache() -> void:
	if _cache_store != null:
		_cache_store.clear()
		_cache_store = null


func reset_runtime() -> void:
	if _adapter != null:
		_adapter.clear_runtime()
	_state = STATE_INERT
	_account_id = ""
	_clock_sample = {}
	_character_snapshot = {}
	_economy_snapshot = {}
	_build_snapshot = {}
	_configuration_summary = {}
	_pending_cutover_offer = Sync.MIGRATION_NONE


func _connection_result(character_exists: bool) -> Dictionary:
	return {
		"ok": true,
		"character_exists": character_exists,
		"account_id": _account_id,
		"clock": _clock_sample.duplicate(true),
		"snapshot": _character_snapshot.duplicate(true),
		"configuration": _configuration_summary.duplicate(true),
	}


func _fail_and_reset(code: String) -> Dictionary:
	reset_runtime()
	return _failure(code)


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
