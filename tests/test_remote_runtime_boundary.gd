extends SceneTree

const Boundary = preload("res://scripts/remote_runtime_boundary.gd")
const DispatcherTest = preload("res://tests/test_remote_command_dispatcher.gd")
const Sync = preload("res://scripts/profile_sync_rules.gd")

var failures := 0
var now_ms := 2000000000000


class FakeRuntimeAdapter extends DispatcherTest.FakeAdapter:
	var configured := false
	var authenticated := false

	func configure(configuration: Dictionary) -> bool:
		configured = bool(configuration.get("accepted", false))
		return configured

	func configuration_summary() -> Dictionary:
		return {"provider_id": "nakama", "environment": "staging", "host": "safe.example", "port": 443, "ssl": true}

	func authenticate_staging_test(_device_id: String) -> Dictionary:
		authenticated = configured
		return {"ok": authenticated, "authority": "server", "account_id": owned_account}

	func authenticate_development(device_id: String) -> Dictionary:
		return authenticate_staging_test(device_id)

	func sample_server_clock() -> Dictionary:
		return {"ok": true, "authority": "server", "server_unix_ms": 2000000000000, "round_trip_ms": 20}

	func clear_runtime() -> void:
		configured = false
		authenticated = false


func _init() -> void:
	var adapter = FakeRuntimeAdapter.new()
	var boundary = Boundary.new(adapter)
	var connection: Dictionary = await boundary.connect_explicit_test({"accepted": true}, "device_0000000001")
	check(bool(connection.get("ok", false)) and boundary.revision() == 4, "explicit session adopts the owned character before command bootstrap")
	var boot: Dictionary = await boundary.bootstrap_authoritative_commands(4)
	check(bool(boot.get("ok", false)) and boundary.safe_summary().mutations_allowed and boundary.revision() == 4,
		"one runtime boundary bootstraps the complete revision-locked authority unit")
	var committed: Dictionary = await boundary.dispatch("profile_1", "profile_idem_1", "profile_commit",
		{"hunter_name": "Vector", "appearance": {"palette": "cool"}})
	check(bool(committed.get("ok", false)) and boundary.revision() == 5 and str(boundary.character_snapshot().profile.hunter_name) == "Vector",
		"known command receipts refresh and adopt all authority views through one boundary")
	var cache_path := "res://.godot/runtime_boundary_%s.json" % OS.get_process_id()
	cleanup_cache(cache_path)
	var offline: Dictionary = boundary.cache_and_disconnect(cache_path, now_ms)
	check(bool(offline.get("read_only", false)) and int(offline.get("revision", -1)) == 5 and not offline.has("hunt_board"),
		"ordered disconnect closes mutations before exposing the composite read-only cache")
	check(boundary.safe_summary().read_only and not boundary.safe_summary().mutations_allowed and boundary.safe_summary().command_state == "inert",
		"offline runtime summary cannot retain a command path")
	var remote := adapter.make_character(6)
	check(boundary.reconnect_action(offline, remote) == Sync.ACTION_USE_REMOTE, "uncontested reconnect selects the newer owned server snapshot")
	boundary.clear_cache()

	var uncertain_adapter = FakeRuntimeAdapter.new()
	var uncertain_boundary = Boundary.new(uncertain_adapter)
	await uncertain_boundary.connect_explicit_test({"accepted": true}, "device_0000000002")
	await uncertain_boundary.bootstrap_authoritative_commands(4)
	uncertain_adapter.transport_failures = 1
	var uncertain: Dictionary = await uncertain_boundary.dispatch("hunt_1", "hunt_idem_1", "hunt_resolve", {"hunt_id": "hunt_1"})
	check(not bool(uncertain.get("ok", false)) and uncertain_boundary.safe_summary().pending, "unknown transport outcome remains explicit in the unified boundary")
	check(not bool(uncertain_boundary.cache_and_disconnect(cache_path, now_ms).get("ok", false)) and uncertain_boundary.safe_summary().pending,
		"cache-and-disconnect cannot erase an uncertain command")
	check(not bool(uncertain_boundary.reset_runtime().get("ok", false)) and uncertain_boundary.safe_summary().pending,
		"runtime reset also refuses silent command loss")
	uncertain_adapter.transport_failures = 0
	check(bool((await uncertain_boundary.retry_pending()).get("ok", false)), "the exact pending identity can recover through the same boundary")
	check(bool((await uncertain_boundary.reset_runtime()).get("ok", false)) and uncertain_boundary.safe_summary().session_state == "inert",
		"clean runtime reset zeroizes session and command state after uncertainty is resolved")

	var abandoned_adapter = FakeRuntimeAdapter.new()
	var abandoned_boundary = Boundary.new(abandoned_adapter)
	await abandoned_boundary.connect_explicit_test({"accepted": true}, "device_0000000003")
	await abandoned_boundary.bootstrap_authoritative_commands(4)
	abandoned_adapter.transport_failures = 1
	await abandoned_boundary.dispatch("hunt_2", "hunt_idem_2", "hunt_resolve", {"hunt_id": "hunt_2"})
	var abandoned: Dictionary = abandoned_boundary.abandon_pending_for_disconnect()
	check(bool(abandoned.get("abandoned", false)) and str(abandoned.command.command_id) == "hunt_2", "explicit abandonment returns the unresolved identity for diagnostics")
	check(not bool(abandoned_boundary.cache_and_disconnect(cache_path, now_ms).get("ok", false)),
		"a diagnostically abandoned outcome can be reset but never cached as fresh authority")
	check(bool(abandoned_boundary.reset_runtime().get("ok", false)), "stale abandoned runtime can zeroize after refusing offline authority")
	cleanup_cache(cache_path)

	if failures == 0:
		print("PASS: unified remote runtime orders authority adoption, command closure, cache, and reconnect safely")
		quit(0)
	else:
		printerr("FAIL: %d remote-runtime issue(s)" % failures)
		quit(1)


func cleanup_cache(path: String) -> void:
	for member in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(member):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(member))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
