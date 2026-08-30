class_name StagingClientProbe
extends RefCounted

const Adapter = preload("res://scripts/nakama_backend_adapter.gd")
const CacheStore = preload("res://scripts/profile_cache_store.gd")
const Sync = preload("res://scripts/profile_sync_rules.gd")
const CutoverArchive = preload("res://scripts/local_save_cutover_archive.gd")


func run(configuration: Dictionary, device_id: String, cache_path: String) -> Dictionary:
	var adapter = Adapter.new()
	if not adapter.configure(configuration):
		return _failure("configuration_rejected")
	var authentication: Dictionary = await adapter.authenticate_staging_test(device_id)
	if not bool(authentication.get("ok", false)):
		return _failure("authentication_failed")
	var account_id := str(authentication.get("account_id", ""))
	var clock: Dictionary = await adapter.sample_server_clock()
	if not bool(clock.get("ok", false)) or str(clock.get("authority", "")) != "server":
		return _failure("clock_failed")

	var snapshot: Dictionary = await adapter.get_character()
	if not bool(snapshot.get("ok", false)):
		return _failure("snapshot_failed")
	if snapshot.get("exists", true) == false:
		snapshot = await adapter.create_character(
			"staging-probe-create-v1",
			"Staging Trace",
			"contract_hacker",
			"synthetic",
			{"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
		)
	if not bool(snapshot.get("ok", false)) or str(snapshot.get("account_id", "")) != account_id:
		return _failure("ownership_failed")
	if int(snapshot.get("revision", -1)) != 0 or not _prove_archival_cutover(snapshot, device_id):
		return _failure("archive_cutover_failed")

	var initial_revision := int(snapshot.get("revision", -1))
	var nonce := str(int(Time.get_unix_time_from_system() * 1000.0))
	var command_id := "staging-probe-commit-%s" % nonce
	var receipt_id := "staging-probe-receipt-%s" % nonce
	var appearance := {"palette": "cool", "eyes": "narrow", "feature": "bold", "marking": "stripe"}
	var commit: Dictionary = await adapter.commit_profile(command_id, receipt_id, initial_revision, "Staging Vector", appearance)
	if not bool(commit.get("ok", false)) or str(commit.get("status", "")) != "accepted":
		return _failure("commit_failed")
	var duplicate: Dictionary = await adapter.commit_profile(command_id, receipt_id, initial_revision, "Staging Vector", appearance)
	if not bool(duplicate.get("ok", false)) or str(duplicate.get("status", "")) != "duplicate":
		return _failure("idempotency_failed")
	var conflict: Dictionary = await adapter.commit_profile(
		"staging-probe-stale-%s" % nonce,
		"staging-probe-stale-receipt-%s" % nonce,
		initial_revision,
		"Staging Vector",
		appearance
	)
	if not bool(conflict.get("ok", false)) or str(conflict.get("status", "")) != "conflict":
		return _failure("conflict_failed")
	var authoritative: Dictionary = await adapter.get_character()
	if not bool(authoritative.get("ok", false)) or int(authoritative.get("revision", -1)) != initial_revision + 1:
		return _failure("authoritative_refetch_failed")

	var store = CacheStore.new()
	store.cache_path = cache_path
	store.clear()
	var cached_at := maxi(int(Time.get_unix_time_from_system() * 1000.0), int(authoritative.get("server_unix_ms", 0)))
	if not store.write_snapshot(authoritative, account_id, account_id, cached_at):
		return _failure("cache_write_failed")
	adapter.clear_runtime()
	var offline: Dictionary = store.load_snapshot(account_id, account_id, cached_at)
	if not bool(offline.get("read_only", false)) or bool(offline.get("economic_mutations_allowed", true)):
		store.clear()
		return _failure("cache_open_failed")

	var reconnect = Adapter.new()
	if not reconnect.configure(configuration):
		store.clear()
		return _failure("reconnect_configuration_failed")
	var reconnect_auth: Dictionary = await reconnect.authenticate_staging_test(device_id)
	var remote: Dictionary = await reconnect.get_character() if bool(reconnect_auth.get("ok", false)) else {}
	var reconnect_action := Sync.reconnect_action(
		int(offline.get("snapshot", {}).get("revision", -1)),
		int(remote.get("revision", -1)),
		[],
		str(remote.get("account_id", "")) == account_id
	)
	store.clear()
	reconnect.clear_runtime()
	if reconnect_action != Sync.ACTION_USE_REMOTE:
		return _failure("reconnect_failed")
	var evidence := {
		"ok": true,
		"account_id": account_id,
		"revision": int(remote.get("revision", -1)),
		"round_trip_ms": int(clock.get("round_trip_ms", -1)),
		"authenticated_session": true,
		"ownership_verified": true,
		"server_clock_verified": true,
		"snapshot_verified": true,
		"idempotent_commit_verified": true,
		"conflict_recovery_verified": true,
		"read_only_cache_verified": true,
		"reconnect_verified": true,
		"archive_cutover_verified": true,
	}
	adapter = null
	store = null
	reconnect = null
	return evidence


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}


static func _prove_archival_cutover(remote_snapshot: Dictionary, device_id: String) -> bool:
	var local_profile := {"character_id": "offline_hunter", "level": 8, "xp": 420, "wins": 12}
	if Sync.migration_offer(local_profile, remote_snapshot, false) != Sync.MIGRATION_CUTOVER_REQUIRED:
		return false
	var save_path := "user://staging_cutover_%s.json" % device_id
	var archive_root := "user://staging_cutover_archives_%s" % device_id
	_cleanup_cutover(save_path, archive_root)
	var members := {
		save_path: JSON.stringify({"version": 26, "player": local_profile}),
		"%s.tmp" % save_path: JSON.stringify({"interrupted": true, "player": local_profile}),
		"%s.bak" % save_path: JSON.stringify({"version": 26, "player": {"character_id": "offline_hunter", "level": 7}}),
	}
	for path in members:
		var file := FileAccess.open(str(path), FileAccess.WRITE)
		if file == null:
			_cleanup_cutover(save_path, archive_root)
			return false
		file.store_string(str(members[path]))
		file.flush()
		file = null
	var source_hash := FileAccess.get_sha256(save_path)
	var created_at := maxi(int(Time.get_unix_time_from_system() * 1000.0), int(remote_snapshot.get("server_unix_ms", 0)))
	var result := CutoverArchive.create(save_path, created_at, archive_root)
	var manifest: Dictionary = result.get("manifest", {})
	var archive_path := str(result.get("archive_path", ""))
	var valid: bool = not result.is_empty() \
		and str(manifest.get("authority", "")) == "local_archive_only" \
		and not bool(manifest.get("may_seed_server_progress", true)) \
		and manifest.get("files", []).size() == 3 \
		and FileAccess.file_exists(save_path) \
		and FileAccess.get_sha256("%s/primary.json" % archive_path) == source_hash
	_cleanup_cutover(save_path, archive_root, archive_path)
	return valid


static func _cleanup_cutover(save_path: String, archive_root: String, archive_path := "") -> void:
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not archive_path.is_empty():
		for file_name in ["primary.json", "staging.json", "backup.json", "manifest.json", "manifest.json.partial"]:
			var member_path := "%s/%s" % [archive_path, file_name]
			if FileAccess.file_exists(member_path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(member_path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_root))
