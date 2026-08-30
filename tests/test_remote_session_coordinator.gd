extends SceneTree

const Coordinator = preload("res://scripts/remote_session_coordinator.gd")
const Sync = preload("res://scripts/profile_sync_rules.gd")

var failures := 0
var now_ms := 2000000000000


class FakeAdapter extends RefCounted:
	var configured := false
	var authenticated := false
	var environment := "staging"
	var snapshot: Dictionary = {}

	func configure(configuration: Dictionary) -> bool:
		configured = bool(configuration.get("accepted", false))
		environment = str(configuration.get("environment", "staging"))
		return configured

	func configuration_summary() -> Dictionary:
		return {"provider_id": "nakama", "environment": environment, "host": "safe.example", "port": 443, "ssl": true}

	func authenticate_development(_device_id: String) -> Dictionary:
		return _authenticate()

	func authenticate_staging_test(_device_id: String) -> Dictionary:
		return _authenticate()

	func _authenticate() -> Dictionary:
		authenticated = configured
		return {"ok": authenticated, "authority": "server", "account_id": "account_1"}

	func account_id() -> String:
		return "account_1" if authenticated else ""

	func sample_server_clock() -> Dictionary:
		return {"ok": true, "authority": "server", "server_unix_ms": 2000000000000, "round_trip_ms": 40}

	func get_character() -> Dictionary:
		return snapshot.duplicate(true)

	func create_character(_key: String, _name: String, _class_id: String, _species_id: String, _appearance: Dictionary) -> Dictionary:
		snapshot = make_snapshot(0)
		return snapshot.duplicate(true)

	func clear_runtime() -> void:
		configured = false
		authenticated = false

	func make_snapshot(revision: int) -> Dictionary:
		return {
			"ok": true, "exists": true, "api_version": 1, "authority": "server", "shard_id": "international_1",
			"account_id": "account_1", "character_id": "account_1", "revision": revision, "server_unix_ms": 2000000000000,
			"profile": {"character_id": "account_1", "hunter_name": "Nova", "level": 1, "xp": 0, "credits": 25, "warp_chips": 0, "scrap": 0},
		}


func _init() -> void:
	var rejected_adapter = FakeAdapter.new()
	var rejected = Coordinator.new(rejected_adapter)
	var rejected_connection: Dictionary = await rejected.connect_explicit_test({}, "device_0000000001")
	check(not bool(rejected_connection.get("ok", false)) and rejected.state() == Coordinator.STATE_INERT, "coordinator begins inert and rejects absent configuration")

	var production_adapter = FakeAdapter.new()
	var production = Coordinator.new(production_adapter)
	var production_connection: Dictionary = await production.connect_explicit_test({"accepted": true, "environment": "production"}, "device_0000000001")
	check(not bool(production_connection.get("ok", false)) and production.state() == Coordinator.STATE_INERT, "explicit test coordinator cannot become a production activation path")

	var adapter = FakeAdapter.new()
	adapter.snapshot = {"ok": true, "exists": false, "account_id": "account_1", "authority": "server"}
	var coordinator = Coordinator.new(adapter)
	var connection: Dictionary = await coordinator.connect_explicit_test({"accepted": true, "environment": "staging"}, "device_0000000001")
	check(bool(connection.get("ok", false)) and not bool(connection.get("character_exists", true)) and coordinator.state() == Coordinator.STATE_AUTHENTICATED, "missing remote character remains an authenticated explicit-test state")
	var created: Dictionary = await coordinator.create_explicit_test_character("create_1", "Nova", "orbit_gunslinger", "synthetic", {})
	check(bool(created.get("ok", false)) and coordinator.state() == Coordinator.STATE_READY, "explicit creation adopts only the owned authoritative snapshot")
	var forged := created.duplicate(true)
	forged.profile.access_token = "must_not_cross_the_boundary"
	check(not coordinator.accept_authoritative_snapshot(forged) and int(coordinator.character_snapshot().revision) == 0, "coordinator independently rejects nested credentials without replacing server truth")
	var safe := coordinator.safe_summary()
	check(not safe.configuration.has("client_key") and bool(safe.economic_mutations_allowed), "coordinator summary is credential-free and mutations require live authority")

	var local_player := {"character_id": "local_character", "level": 8, "xp": 420, "wins": 12}
	check(coordinator.prepare_local_cutover(local_player, false) == Sync.MIGRATION_CUTOVER_REQUIRED, "established local progress requires the archival cutover")
	var run_id := "%d" % OS.get_process_id()
	var save_path := "res://.godot/coordinator_cutover_%s.json" % run_id
	var archive_root := "res://.godot/coordinator_archives_%s" % run_id
	var cache_path := "res://.godot/coordinator_cache_%s.json" % run_id
	cleanup(save_path, archive_root, cache_path)
	write_file(save_path, '{"version":26,"player":{"level":8}}')
	var ambiguous := coordinator.archive_local_cutover("merge", save_path, archive_root)
	check(not bool(ambiguous.get("ok", false)) and FileAccess.file_exists(save_path), "ambiguous migration cannot archive, delete, or import local progress")
	var archived := coordinator.archive_local_cutover(Sync.MIGRATION_ARCHIVE_AND_START_REMOTE, save_path, archive_root)
	check(bool(archived.get("ok", false)) and FileAccess.file_exists(save_path), "confirmed cutover archives while preserving the active local source")

	var offline: Dictionary = coordinator.cache_and_disconnect(cache_path, now_ms)
	check(bool(offline.get("ok", false)) and bool(offline.get("read_only", false)) and coordinator.state() == Coordinator.STATE_OFFLINE_CACHE, "disconnect reopens only a read-only server cache")
	check(not bool(coordinator.safe_summary().economic_mutations_allowed), "offline coordinator cannot advertise economic mutations")
	var remote_next := adapter.make_snapshot(1)
	check(coordinator.reconnect_action(offline, remote_next) == Sync.ACTION_USE_REMOTE, "uncontested newer server revision replaces the read-only cache")
	var foreign := remote_next.duplicate(true)
	foreign.account_id = "foreign_account"
	check(coordinator.reconnect_action(offline, foreign) == Sync.ACTION_REJECT_REMOTE, "reconnect rejects foreign ownership")
	coordinator.clear_cache()
	cleanup(save_path, archive_root, cache_path)

	if failures == 0:
		print("PASS: remote session coordinator is explicit, archival, read-only offline, and fail-closed")
		quit(0)
	else:
		printerr("FAIL: %d remote-session coordinator issue(s)" % failures)
		quit(1)


func write_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file = null


func cleanup(save_path: String, archive_root: String, cache_path: String) -> void:
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path, cache_path, "%s.tmp" % cache_path, "%s.bak" % cache_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var archive_path := "%s/offline-%d" % [archive_root, now_ms]
	for file_name in ["primary.json", "staging.json", "backup.json", "manifest.json", "manifest.json.partial"]:
		var path := "%s/%s" % [archive_path, file_name]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_root))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
