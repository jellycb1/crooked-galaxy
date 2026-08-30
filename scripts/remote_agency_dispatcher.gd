class_name RemoteAgencyDispatcher
extends RefCounted

const Protocol = preload("res://scripts/backend_protocol_rules.gd")
const AgencyRemote = preload("res://scripts/remote_agency_rules.gd")

const STATE_INERT := "inert"
const STATE_READY := "ready"
const STATE_STALE := "stale"

var _adapter = null
var _account_id := ""
var _state := STATE_INERT
var _revision := -1
var _snapshot: Dictionary = {}
var _pending_command: Dictionary = {}


func _init(adapter_override = null, account_id_override := "") -> void:
	_adapter = adapter_override
	_account_id = account_id_override


func state() -> String:
	return _state


func revision() -> int:
	return _revision


func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func safe_summary() -> Dictionary:
	return {"state": _state, "revision": _revision, "membership_state": str(_snapshot.get("membership_state", "unknown")),
		"pending": not _pending_command.is_empty(), "mutations_allowed": _state == STATE_READY and _pending_command.is_empty()}


func bootstrap(expected_revision := -1) -> Dictionary:
	if _adapter == null or _account_id.is_empty() or str(_adapter.account_id()) != _account_id:
		return _failure("owned_authenticated_adapter_required")
	_pending_command = {}
	return await _refresh(expected_revision)


func dispatch(command_id: String, idempotency_key: String, operation: String, agency_id: String) -> Dictionary:
	if _state != STATE_READY or not _pending_command.is_empty():
		return _failure("ready_agency_runtime_required")
	if operation not in [AgencyRemote.OP_APPLY, AgencyRemote.OP_LEAVE]:
		return _failure("invalid_agency_operation")
	var command := Protocol.make_command(command_id, idempotency_key, operation, _account_id, _account_id, _revision, {"agency_id": agency_id})
	if command.is_empty():
		return _failure("invalid_agency_command")
	_pending_command = command
	return await _submit_pending()


func dispatch_create(command_id: String, idempotency_key: String, name: String, recruitment_mode: String, preferred_locale: String) -> Dictionary:
	if _state != STATE_READY or not _pending_command.is_empty():
		return _failure("ready_agency_runtime_required")
	var command := Protocol.make_command(command_id, idempotency_key, AgencyRemote.OP_CREATE, _account_id, _account_id, _revision,
		{"name": name, "recruitment_mode": recruitment_mode, "preferred_locale": preferred_locale})
	if command.is_empty():
		return _failure("invalid_agency_create_command")
	_pending_command = command
	return await _submit_pending()


func retry_pending() -> Dictionary:
	if _pending_command.is_empty():
		return _failure("no_pending_command")
	return await _submit_pending()


func close() -> Dictionary:
	if not _pending_command.is_empty():
		return _failure("pending_command_must_be_resolved")
	_state = STATE_INERT
	_revision = -1
	_snapshot = {}
	_account_id = ""
	_adapter = null
	return {"ok": true, "closed": true}


func _submit_pending() -> Dictionary:
	var command := _pending_command.duplicate(true)
	var response: Dictionary = await _route(command)
	if not bool(response.get("ok", false)):
		return {"ok": false, "error_code": "command_outcome_unknown", "pending": true, "action": Protocol.ACTION_RETRY_SAME_COMMAND}
	var receipt := Protocol.canonical_command_receipt(response, command)
	if receipt.is_empty():
		_state = STATE_STALE
		return _failure("invalid_agency_receipt")
	var action := Protocol.action_for_receipt(receipt)
	_pending_command = {}
	var refreshed: Dictionary = await _refresh(int(receipt.server_revision))
	if not bool(refreshed.get("ok", false)):
		_state = STATE_STALE
		return _failure("agency_receipt_refresh_failed")
	return {"ok": true, "status": str(receipt.status), "action": action, "receipt": receipt, "revision": _revision, "pending": false}


func _route(command: Dictionary) -> Dictionary:
	if str(command.operation) == AgencyRemote.OP_CREATE:
		return await _adapter.create_agency(str(command.command_id), str(command.idempotency_key), int(command.expected_revision),
			str(command.payload.name), str(command.payload.recruitment_mode), str(command.payload.preferred_locale))
	if str(command.operation) == AgencyRemote.OP_APPLY:
		return await _adapter.apply_to_agency(str(command.command_id), str(command.idempotency_key), int(command.expected_revision), str(command.payload.agency_id))
	return await _adapter.leave_agency(str(command.command_id), str(command.idempotency_key), int(command.expected_revision), str(command.payload.agency_id))


func _refresh(expected_revision := -1) -> Dictionary:
	var response: Dictionary = await _adapter.get_agency_membership()
	var canonical := AgencyRemote.canonical_membership_snapshot(response, _account_id, _account_id)
	if canonical.is_empty() or (expected_revision >= 0 and int(canonical.revision) != expected_revision):
		_state = STATE_STALE
		return _failure("invalid_agency_snapshot")
	canonical.ok = true
	_snapshot = canonical
	_revision = int(canonical.revision)
	_state = STATE_READY
	return {"ok": true, "revision": _revision, "snapshot": snapshot()}


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
