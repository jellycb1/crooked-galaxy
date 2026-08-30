class_name RemoteRuntimeBoundary
extends RefCounted

const AdapterScript = preload("res://scripts/nakama_backend_adapter.gd")
const CoordinatorScript = preload("res://scripts/remote_session_coordinator.gd")
const DispatcherScript = preload("res://scripts/remote_command_dispatcher.gd")

var _adapter = null
var _coordinator = null
var _dispatcher = null


func _init(adapter_override = null) -> void:
	_adapter = adapter_override if adapter_override != null else AdapterScript.new()
	_coordinator = CoordinatorScript.new(_adapter)


func connect_explicit_test(configuration: Dictionary, device_id: String) -> Dictionary:
	if _dispatcher != null:
		return _failure("runtime_already_bootstrapped")
	return await _coordinator.connect_explicit_test(configuration, device_id)


func create_explicit_test_character(idempotency_key: String, hunter_name: String, class_id: String, species_id: String, appearance: Dictionary) -> Dictionary:
	if _dispatcher != null:
		return _failure("runtime_already_bootstrapped")
	return await _coordinator.create_explicit_test_character(idempotency_key, hunter_name, class_id, species_id, appearance)


func prepare_local_cutover(local_player: Dictionary, already_decided: bool) -> String:
	return _coordinator.prepare_local_cutover(local_player, already_decided)


func archive_local_cutover(choice: String, save_path: String, archive_root: String) -> Dictionary:
	return _coordinator.archive_local_cutover(choice, save_path, archive_root)


func bootstrap_authoritative_commands(expected_revision := -1) -> Dictionary:
	if _dispatcher != null:
		return _failure("runtime_already_bootstrapped")
	var account_id: String = _coordinator.account_id()
	if account_id.is_empty():
		return _failure("owned_session_required")
	_dispatcher = DispatcherScript.new(_adapter, account_id)
	var result: Dictionary = await _dispatcher.bootstrap(expected_revision)
	if not bool(result.get("ok", false)) or not _adopt_dispatcher_unit():
		_dispatcher = null
		return _failure("authoritative_bootstrap_failed")
	return result


func dispatch(command_id: String, idempotency_key: String, operation: String, payload: Dictionary) -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	var result: Dictionary = await _dispatcher.dispatch(command_id, idempotency_key, operation, payload)
	return _finalize_dispatch(result)


func retry_pending() -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	return _finalize_dispatch(await _dispatcher.retry_pending())


func abandon_pending_for_disconnect() -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	return _dispatcher.abandon_pending_for_disconnect()


func replay_last_completed_explicit_test() -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	return _finalize_dispatch(await _dispatcher.replay_last_completed_explicit_test())


func prove_conflict_explicit_test(command_id: String, idempotency_key: String, operation: String, payload: Dictionary, stale_expected_revision: int) -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	return _finalize_dispatch(await _dispatcher.prove_conflict_explicit_test(command_id, idempotency_key, operation, payload, stale_expected_revision))


func character_snapshot() -> Dictionary:
	return _dispatcher.character_snapshot() if _dispatcher != null else _coordinator.character_snapshot()


func economy_snapshot() -> Dictionary:
	return _dispatcher.economy_snapshot() if _dispatcher != null else {}


func build_snapshot() -> Dictionary:
	return _dispatcher.build_snapshot() if _dispatcher != null else {}


func hunt_board() -> Dictionary:
	return _dispatcher.hunt_board() if _dispatcher != null else {}


func revision() -> int:
	return _dispatcher.revision() if _dispatcher != null else int(_coordinator.character_snapshot().get("revision", -1))


func cache_and_disconnect(cache_path: String, now_unix_ms := -1) -> Dictionary:
	if _dispatcher == null:
		return _failure("command_runtime_required")
	if _dispatcher.state() != DispatcherScript.STATE_READY:
		return _failure("fresh_authoritative_unit_required")
	if not _adopt_dispatcher_unit():
		return _failure("complete_authoritative_unit_required")
	var closed: Dictionary = _dispatcher.close_for_disconnect()
	if not bool(closed.get("ok", false)):
		return closed
	_dispatcher = null
	return _coordinator.cache_and_disconnect(cache_path, now_unix_ms)


func reconnect_action(offline_cache: Dictionary, remote_snapshot: Dictionary) -> String:
	return _coordinator.reconnect_action(offline_cache, remote_snapshot)


func clear_cache() -> void:
	_coordinator.clear_cache()


func reset_runtime() -> Dictionary:
	if _dispatcher != null:
		var closed: Dictionary = _dispatcher.close_for_disconnect()
		if not bool(closed.get("ok", false)):
			return closed
		_dispatcher = null
	_coordinator.reset_runtime()
	return {"ok": true, "reset": true}


func safe_summary() -> Dictionary:
	var coordinator_summary: Dictionary = _coordinator.safe_summary()
	var dispatcher_summary: Dictionary = _dispatcher.safe_summary() if _dispatcher != null else {}
	return {
		"session_state": str(coordinator_summary.get("state", "inert")),
		"command_state": str(dispatcher_summary.get("state", "inert")),
		"account_id": str(coordinator_summary.get("account_id", "")),
		"revision": revision(),
		"read_only": bool(coordinator_summary.get("read_only", false)),
		"pending": bool(dispatcher_summary.get("pending", false)),
		"mutations_allowed": bool(dispatcher_summary.get("mutations_allowed", false)),
	}


func _finalize_dispatch(result: Dictionary) -> Dictionary:
	if bool(result.get("ok", false)) and not _adopt_dispatcher_unit():
		return _failure("coordinator_adoption_failed")
	return result


func _adopt_dispatcher_unit() -> bool:
	return _dispatcher != null and _dispatcher.state() == DispatcherScript.STATE_READY and _coordinator.accept_authoritative_unit(
		_dispatcher.character_snapshot(), _dispatcher.economy_snapshot(), _dispatcher.build_snapshot())


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
