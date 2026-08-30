class_name NakamaBackendAdapter
extends RefCounted

const Deployment = preload("res://scripts/backend_deployment_rules.gd")
const Protocol = preload("res://scripts/backend_protocol_rules.gd")

const CLOCK_RPC := "cg_clock"
const SESSION_RPC := "cg_session"
const CHARACTER_GET_RPC := "cg_character_get"
const CHARACTER_CREATE_RPC := "cg_character_create"
const CHARACTER_COMMIT_RPC := "cg_character_commit"
const DEVELOPMENT_PROVIDER := "nakama_device"
const DEFAULT_TIMEOUT_SECONDS := 5

var _configuration: Dictionary = {}
var _client = null
var _session = null


func configure(configuration: Dictionary) -> bool:
	clear_runtime()
	var canonical := Deployment.canonicalize_endpoint(configuration)
	if canonical.is_empty() or not Deployment.secret_safe_for_client(canonical):
		return false
	_configuration = canonical
	return true


func is_configured() -> bool:
	return not _configuration.is_empty() and bool(_configuration.get("configured", false))


func configuration_summary() -> Dictionary:
	if not is_configured():
		return {}
	return {
		"provider_id": str(_configuration.provider_id),
		"environment": str(_configuration.environment),
		"host": str(_configuration.host),
		"port": int(_configuration.port),
		"ssl": bool(_configuration.ssl),
	}


func has_authenticated_session() -> bool:
	return _session != null and not _session.is_exception() and bool(_session.valid) and not bool(_session.expired)


func authenticate_development(device_id: String, username := "") -> Dictionary:
	if not is_configured() or str(_configuration.environment) != Deployment.ENV_LOCAL:
		return _failure("local_endpoint_required")
	return await _authenticate_test_device(device_id, username)


func authenticate_staging_test(device_id: String, username := "") -> Dictionary:
	if not is_configured() or str(_configuration.environment) != Deployment.ENV_STAGING:
		return _failure("staging_endpoint_required")
	return await _authenticate_test_device(device_id, username)


func _authenticate_test_device(device_id: String, username: String) -> Dictionary:
	if not _valid_development_identifier(device_id, 16, 128):
		return _failure("invalid_device_id")
	if not username.is_empty() and not _valid_development_identifier(username, 3, 32):
		return _failure("invalid_username")
	var singleton := _nakama_singleton()
	if singleton == null:
		return _failure("nakama_addon_unavailable")
	var scheme := "https" if bool(_configuration.ssl) else "http"
	_client = singleton.create_client(
		str(_configuration.client_key),
		str(_configuration.host),
		int(_configuration.port),
		scheme,
		DEFAULT_TIMEOUT_SECONDS,
		NakamaLogger.LOG_LEVEL.ERROR
	)
	var requested_username: Variant = null if username.is_empty() else username
	var result = await _client.authenticate_device_async(device_id, requested_username, true)
	if result == null or result.is_exception() or not bool(result.valid) or bool(result.expired):
		_session = null
		return _failure("authentication_failed")
	_session = result
	return {
		"ok": true,
		"provider_id": DEVELOPMENT_PROVIDER if str(_configuration.environment) == Deployment.ENV_LOCAL else "nakama_staging_device",
		"account_id": str(_session.user_id),
		"username": str(_session.username),
		"created": bool(_session.created),
		"expires_at_unix_ms": int(_session.expire_time) * 1000,
		"authority": "server",
	}


func sample_server_clock() -> Dictionary:
	if not has_authenticated_session() or _client == null:
		return _failure("authenticated_session_required")
	var client_sent_unix_ms := _now_unix_ms()
	var response = await _client.rpc_async(_session, CLOCK_RPC, JSON.stringify({}))
	var client_received_unix_ms := _now_unix_ms()
	if response == null or response.is_exception():
		return _failure("clock_rpc_failed")
	var envelope = JSON.parse_string(str(response.payload))
	if not envelope is Dictionary or str(envelope.get("shard_id", "")) != Protocol.DEFAULT_SHARD_ID:
		return _failure("invalid_clock_envelope")
	var sample := Protocol.canonical_clock_sample(envelope, client_sent_unix_ms, client_received_unix_ms)
	if sample.is_empty():
		return _failure("invalid_clock_sample")
	sample.ok = true
	sample.api_version = int(envelope.api_version)
	sample.shard_id = str(envelope.shard_id)
	return sample


func get_character() -> Dictionary:
	var envelope := await _rpc_dictionary(CHARACTER_GET_RPC, {})
	if envelope.is_empty():
		return _failure("character_get_failed")
	if envelope.get("exists", true) == false:
		if str(envelope.get("account_id", "")) != account_id() or str(envelope.get("authority", "")) != "server":
			return _failure("invalid_missing_character_envelope")
		return {"ok": true, "exists": false, "account_id": account_id(), "authority": "server"}
	var canonical := Protocol.canonical_character_snapshot(envelope, account_id(), account_id())
	if canonical.is_empty():
		return _failure("invalid_character_snapshot")
	canonical.ok = true
	canonical.exists = true
	return canonical


func get_session_summary() -> Dictionary:
	var envelope := await _rpc_dictionary(SESSION_RPC, {})
	if envelope.is_empty():
		return _failure("session_summary_failed")
	var canonical := Protocol.canonical_session_summary(envelope, _now_unix_ms())
	if canonical.is_empty() or str(canonical.get("account_id", "")) != account_id():
		return _failure("invalid_session_summary")
	canonical.ok = true
	return canonical


func create_character(idempotency_key: String, hunter_name: String, class_id: String, species_id: String, appearance: Dictionary) -> Dictionary:
	var envelope := await _rpc_dictionary(CHARACTER_CREATE_RPC, {
		"idempotency_key": idempotency_key,
		"hunter_name": hunter_name,
		"class_id": class_id,
		"species_id": species_id,
		"appearance": appearance,
	})
	if envelope.is_empty():
		return _failure("character_create_failed")
	var canonical := Protocol.canonical_character_snapshot(envelope, account_id(), account_id())
	if canonical.is_empty():
		return _failure("invalid_created_character")
	canonical.ok = true
	canonical.created = bool(envelope.get("created", false))
	canonical.idempotent_replay = bool(envelope.get("idempotent_replay", false))
	return canonical


func commit_profile(command_id: String, idempotency_key: String, expected_revision: int, hunter_name: String, appearance: Dictionary) -> Dictionary:
	if not has_authenticated_session():
		return _failure("authenticated_session_required")
	var command := Protocol.make_command(command_id, idempotency_key, "profile_commit", account_id(), account_id(), expected_revision, {
		"hunter_name": hunter_name,
		"appearance": appearance,
	})
	if command.is_empty():
		return _failure("invalid_profile_command")
	var envelope := await _rpc_dictionary(CHARACTER_COMMIT_RPC, command)
	if envelope.is_empty():
		return _failure("character_commit_failed")
	var receipt := Protocol.canonical_command_receipt(envelope, command)
	if receipt.is_empty():
		return _failure("invalid_profile_receipt")
	var snapshot_envelope = envelope.get("snapshot", {})
	if snapshot_envelope is Dictionary and not snapshot_envelope.is_empty():
		var canonical_snapshot := Protocol.canonical_character_snapshot(snapshot_envelope, account_id(), account_id())
		if canonical_snapshot.is_empty():
			return _failure("invalid_commit_snapshot")
		receipt.snapshot = canonical_snapshot
	receipt.ok = true
	return receipt


func account_id() -> String:
	return str(_session.user_id) if has_authenticated_session() else ""


func clear_runtime() -> void:
	_session = null
	_client = null
	_configuration = {}


func _nakama_singleton() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not main_loop is SceneTree:
		return null
	return main_loop.root.get_node_or_null("Nakama")


static func _now_unix_ms() -> int:
	return int(round(Time.get_unix_time_from_system() * 1000.0))


func _rpc_dictionary(rpc_id: String, payload: Dictionary) -> Dictionary:
	if not has_authenticated_session() or _client == null:
		return {}
	var response = await _client.rpc_async(_session, rpc_id, JSON.stringify(payload))
	if response == null or response.is_exception():
		return {}
	var parsed = JSON.parse_string(str(response.payload))
	return parsed if parsed is Dictionary else {}


static func _valid_development_identifier(value: String, minimum: int, maximum: int) -> bool:
	if value.length() < minimum or value.length() > maximum:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var allowed := (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code in [45, 95]
		if not allowed:
			return false
	return true


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}
