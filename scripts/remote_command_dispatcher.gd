class_name RemoteCommandDispatcher
extends RefCounted

const Protocol = preload("res://scripts/backend_protocol_rules.gd")
const Economy = preload("res://scripts/remote_economy_rules.gd")

const STATE_INERT := "inert"
const STATE_READY := "ready"
const STATE_STALE := "stale"

var _adapter = null
var _account_id := ""
var _state := STATE_INERT
var _revision := -1
var _economy_snapshot: Dictionary = {}
var _build_snapshot: Dictionary = {}
var _hunt_board: Dictionary = {}
var _pending_command: Dictionary = {}
var _last_completed_command: Dictionary = {}


func _init(adapter_override = null, account_id_override := "") -> void:
	_adapter = adapter_override
	_account_id = account_id_override


func state() -> String:
	return _state


func revision() -> int:
	return _revision


func has_pending_command() -> bool:
	return not _pending_command.is_empty()


func economy_snapshot() -> Dictionary:
	return _economy_snapshot.duplicate(true)


func build_snapshot() -> Dictionary:
	return _build_snapshot.duplicate(true)


func hunt_board() -> Dictionary:
	return _hunt_board.duplicate(true)


func safe_summary() -> Dictionary:
	return {
		"state": _state,
		"account_id": _account_id,
		"revision": _revision,
		"pending": not _pending_command.is_empty(),
		"pending_operation": str(_pending_command.get("operation", "")),
		"mutations_allowed": _state == STATE_READY and _pending_command.is_empty(),
	}


func bootstrap(expected_revision := -1) -> Dictionary:
	if _adapter == null or _account_id.is_empty() or str(_adapter.account_id()) != _account_id:
		return _failure("owned_authenticated_adapter_required")
	_pending_command = {}
	return await _refresh_authoritative_unit(expected_revision)


func dispatch(command_id: String, idempotency_key: String, operation: String, payload: Dictionary) -> Dictionary:
	if _state != STATE_READY:
		return _failure("authoritative_unit_required")
	if not _pending_command.is_empty():
		return _failure("pending_command_must_be_resolved")
	var command := Protocol.make_command(command_id, idempotency_key, operation, _account_id, _account_id, _revision, payload)
	if command.is_empty() or operation not in Economy.OPERATIONS:
		return _failure("invalid_economy_command")
	_pending_command = command
	return await _submit_pending()


func retry_pending() -> Dictionary:
	if _pending_command.is_empty():
		return _failure("no_pending_command")
	return await _submit_pending()


func replay_last_completed_explicit_test() -> Dictionary:
	if _state != STATE_READY or not _pending_command.is_empty() or _last_completed_command.is_empty():
		return _failure("completed_command_required")
	_pending_command = _last_completed_command.duplicate(true)
	return await _submit_pending()


func abandon_pending_for_disconnect() -> Dictionary:
	if _pending_command.is_empty():
		return {"ok": true, "abandoned": false}
	var abandoned := {
		"command_id": str(_pending_command.command_id),
		"idempotency_key": str(_pending_command.idempotency_key),
		"operation": str(_pending_command.operation),
		"expected_revision": int(_pending_command.expected_revision),
	}
	_pending_command = {}
	_state = STATE_STALE
	return {"ok": true, "abandoned": true, "command": abandoned}


func _submit_pending() -> Dictionary:
	var command := _pending_command.duplicate(true)
	var response: Dictionary = await _route(command)
	if not bool(response.get("ok", false)):
		var action := Protocol.ACTION_REFRESH_AND_RETRY if str(response.get("error_code", "")) == "authenticated_session_required" \
			else Protocol.ACTION_RETRY_SAME_COMMAND
		return {
			"ok": false,
			"error_code": "command_outcome_unknown",
			"transport_error_code": str(response.get("error_code", "")),
			"action": action,
			"pending": true,
		}
	var receipt := Protocol.canonical_command_receipt(response, command)
	if receipt.is_empty():
		_state = STATE_STALE
		return _failure("invalid_authoritative_receipt")
	var action := Protocol.action_for_receipt(receipt)
	if action == Protocol.ACTION_COMPLETE:
		_last_completed_command = command.duplicate(true)
	_pending_command = {}
	var refreshed: Dictionary = await _refresh_authoritative_unit(int(receipt.server_revision))
	if not bool(refreshed.get("ok", false)):
		_state = STATE_STALE
		return {
			"ok": false,
			"error_code": "receipt_snapshot_refresh_failed",
			"receipt": receipt,
			"action": Protocol.ACTION_FETCH_SNAPSHOT,
			"pending": false,
		}
	return {
		"ok": true,
		"status": str(receipt.status),
		"action": action,
		"receipt": receipt,
		"revision": _revision,
		"pending": false,
	}


func _route(command: Dictionary) -> Dictionary:
	var operation := str(command.operation)
	var payload: Dictionary = command.payload
	var command_id := str(command.command_id)
	var key := str(command.idempotency_key)
	var expected := int(command.expected_revision)
	match operation:
		Economy.OP_HUNT_ACCEPT:
			return await _adapter.accept_hunt(command_id, key, expected, str(payload.board_id), str(payload.offer_id), str(payload.target_id), str(payload.approach_id))
		Economy.OP_HUNT_RESOLVE:
			return await _adapter.resolve_hunt(command_id, key, expected, str(payload.hunt_id))
		Economy.OP_REWARD_CLAIM:
			return await _adapter.claim_reward(command_id, key, expected, str(payload.hunt_id), str(payload.reward_id), str(payload.decision))
		Economy.OP_ATTRIBUTE_ALLOCATE:
			return await _adapter.allocate_attributes(command_id, key, expected, payload.allocations)
		Economy.OP_INVENTORY_EQUIP:
			return await _adapter.equip_item(command_id, key, expected, str(payload.item_id))
		Economy.OP_INVENTORY_RECYCLE:
			return await _adapter.recycle_item(command_id, key, expected, str(payload.item_id))
	return _failure("unsupported_operation")


func _refresh_authoritative_unit(expected_revision := -1) -> Dictionary:
	var economy_response: Dictionary = await _adapter.get_economy()
	var build_response: Dictionary = await _adapter.get_build()
	var board_response: Dictionary = await _adapter.get_hunt_board()
	var canonical_economy := Economy.canonical_economy_snapshot(economy_response, _account_id, _account_id)
	var canonical_build := Economy.canonical_build_snapshot(build_response, _account_id, _account_id)
	var canonical_board := Economy.canonical_hunt_board(board_response, _account_id, _account_id)
	if canonical_economy.is_empty() or canonical_build.is_empty() or canonical_board.is_empty():
		_state = STATE_STALE
		return _failure("invalid_authoritative_unit")
	var economy_revision := int(canonical_economy.revision)
	var build_revision := int(canonical_build.revision)
	var board_revision := int(canonical_board.revision)
	if economy_revision != build_revision or economy_revision != board_revision \
		or (expected_revision >= 0 and economy_revision != expected_revision):
		_state = STATE_STALE
		return _failure("authoritative_revision_mismatch")
	_economy_snapshot = canonical_economy
	_build_snapshot = canonical_build
	_hunt_board = canonical_board
	_revision = economy_revision
	_state = STATE_READY
	return {"ok": true, "revision": _revision, "economy": economy_snapshot(), "build": build_snapshot(), "hunt_board": hunt_board()}


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
