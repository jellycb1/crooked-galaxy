class_name RemoteCommandDispatcher
extends RefCounted

const Protocol = preload("res://scripts/backend_protocol_rules.gd")
const Economy = preload("res://scripts/remote_economy_rules.gd")
const Sync = preload("res://scripts/profile_sync_rules.gd")

const STATE_INERT := "inert"
const STATE_READY := "ready"
const STATE_STALE := "stale"
const PROFILE_COMMIT := "profile_commit"

var _adapter = null
var _account_id := ""
var _state := STATE_INERT
var _revision := -1
var _character_snapshot: Dictionary = {}
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


func character_snapshot() -> Dictionary:
	return _character_snapshot.duplicate(true)


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
	if command.is_empty() or (operation not in Economy.OPERATIONS and operation != PROFILE_COMMIT):
		return _failure("invalid_remote_command")
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


func prove_conflict_explicit_test(command_id: String, idempotency_key: String, operation: String, payload: Dictionary, stale_expected_revision: int) -> Dictionary:
	if _state != STATE_READY or not _pending_command.is_empty() or stale_expected_revision < 0 or stale_expected_revision >= _revision:
		return _failure("stale_test_revision_required")
	var command := Protocol.make_command(command_id, idempotency_key, operation, _account_id, _account_id, stale_expected_revision, payload)
	if command.is_empty() or (operation not in Economy.OPERATIONS and operation != PROFILE_COMMIT):
		return _failure("invalid_remote_command")
	_pending_command = command
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


func close_for_disconnect() -> Dictionary:
	if not _pending_command.is_empty():
		return _failure("pending_command_must_be_resolved")
	_state = STATE_INERT
	_revision = -1
	_character_snapshot = {}
	_economy_snapshot = {}
	_build_snapshot = {}
	_hunt_board = {}
	_last_completed_command = {}
	_account_id = ""
	_adapter = null
	return {"ok": true, "closed": true}


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
		PROFILE_COMMIT:
			return await _adapter.commit_profile(command_id, key, expected, str(payload.hunter_name), payload.appearance)
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
	var character_response: Dictionary = await _adapter.get_character()
	var economy_response: Dictionary = await _adapter.get_economy()
	var build_response: Dictionary = await _adapter.get_build()
	var board_response: Dictionary = await _adapter.get_hunt_board()
	var canonical_character := Protocol.canonical_character_snapshot(character_response, _account_id, _account_id)
	var canonical_economy := Economy.canonical_economy_snapshot(economy_response, _account_id, _account_id)
	var canonical_build := Economy.canonical_build_snapshot(build_response, _account_id, _account_id)
	var canonical_board := Economy.canonical_hunt_board(board_response, _account_id, _account_id)
	if canonical_character.is_empty() or canonical_economy.is_empty() or canonical_build.is_empty() or canonical_board.is_empty():
		_state = STATE_STALE
		return _failure("invalid_authoritative_unit")
	var unit := Sync.canonical_authority_unit(canonical_character, canonical_economy, canonical_build, _account_id, _account_id)
	if unit.is_empty():
		_state = STATE_STALE
		return _failure("contradictory_authoritative_unit")
	canonical_character = unit.character
	canonical_economy = unit.economy
	canonical_build = unit.build
	var character_revision := int(unit.revision)
	var economy_revision := int(unit.revision)
	var build_revision := int(unit.revision)
	var board_revision := int(canonical_board.revision)
	if character_revision != economy_revision or economy_revision != build_revision or economy_revision != board_revision \
		or (expected_revision >= 0 and economy_revision != expected_revision):
		_state = STATE_STALE
		return _failure("authoritative_revision_mismatch")
	canonical_character.ok = true
	canonical_character.exists = true
	_character_snapshot = canonical_character
	_economy_snapshot = canonical_economy
	_build_snapshot = canonical_build
	_hunt_board = canonical_board
	_revision = economy_revision
	_state = STATE_READY
	return {"ok": true, "revision": _revision, "character": character_snapshot(), "economy": economy_snapshot(), "build": build_snapshot(), "hunt_board": hunt_board()}


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
