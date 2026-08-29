class_name BackendProtocolRules
extends RefCounted

const API_VERSION := 1
const DEFAULT_SHARD_ID := "international_1"
const MAX_UNIX_MS := 4102444800000
const MAX_CLOCK_ROUND_TRIP_MS := 30000
const MAX_SESSION_LIFETIME_MS := 2592000000

const RECEIPT_ACCEPTED := "accepted"
const RECEIPT_DUPLICATE := "duplicate"
const RECEIPT_CONFLICT := "conflict"
const RECEIPT_REJECTED := "rejected"

const ACTION_COMPLETE := "complete"
const ACTION_RETRY_SAME_COMMAND := "retry_same_command"
const ACTION_REFRESH_AND_RETRY := "refresh_session_and_retry_same_command"
const ACTION_FETCH_SNAPSHOT := "fetch_authoritative_snapshot"
const ACTION_STOP := "stop"

const ALLOWED_OPERATIONS := {
	"profile_commit": true,
	"agency_apply": true,
	"agency_leave": true,
	"agency_contribute_intel": true,
	"agency_capture_attempt": true,
	"agency_claim_reward": true,
}

const SECRET_KEYS := {
	"access_token": true,
	"refresh_token": true,
	"password": true,
	"credential": true,
	"authorization": true,
}


static func canonical_session_summary(response: Dictionary, now_unix_ms: int) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION:
		return {}
	if str(response.get("authority", "")) != "server" or str(response.get("session_state", "")) != "authenticated":
		return {}
	if str(response.get("shard_id", "")) != DEFAULT_SHARD_ID:
		return {}
	var provider_id := str(response.get("provider_id", ""))
	var account_id := str(response.get("account_id", ""))
	var session_id := str(response.get("session_id", ""))
	var active_character_id := str(response.get("active_character_id", ""))
	if not _valid_identifier(provider_id) or not _valid_identifier(account_id) or not _valid_identifier(session_id) or not _valid_identifier(active_character_id):
		return {}
	var owned = response.get("owned_character_ids", [])
	if not owned is Array or owned.is_empty() or not owned.has(active_character_id):
		return {}
	var canonical_owned: Array[String] = []
	for value in owned:
		var character_id := str(value)
		if not _valid_identifier(character_id) or canonical_owned.has(character_id):
			return {}
		canonical_owned.append(character_id)
	var issued_at := int(response.get("issued_at_unix_ms", -1))
	var expires_at := int(response.get("expires_at_unix_ms", -1))
	if not _valid_unix_ms(now_unix_ms) or not _valid_unix_ms(issued_at) or not _valid_unix_ms(expires_at):
		return {}
	if issued_at > now_unix_ms or expires_at <= now_unix_ms or expires_at <= issued_at or expires_at - issued_at > MAX_SESSION_LIFETIME_MS:
		return {}
	return {
		"api_version": API_VERSION,
		"provider_id": provider_id,
		"account_id": account_id,
		"session_id": session_id,
		"session_state": "authenticated",
		"shard_id": DEFAULT_SHARD_ID,
		"active_character_id": active_character_id,
		"owned_character_ids": canonical_owned,
		"authority": "server",
		"issued_at_unix_ms": issued_at,
		"expires_at_unix_ms": expires_at,
	}


static func extract_bearer_credential(response: Dictionary, now_unix_ms: int) -> String:
	if canonical_session_summary(response, now_unix_ms).is_empty():
		return ""
	var token := str(response.get("access_token", ""))
	if token.length() < 16 or token.length() > 4096 or token.contains("\n") or token.contains("\r"):
		return ""
	return token


static func canonical_clock_sample(response: Dictionary, client_sent_unix_ms: int, client_received_unix_ms: int) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server":
		return {}
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	if not _valid_unix_ms(server_unix_ms) or not _valid_unix_ms(client_sent_unix_ms) or not _valid_unix_ms(client_received_unix_ms):
		return {}
	if client_received_unix_ms < client_sent_unix_ms:
		return {}
	var round_trip_ms := client_received_unix_ms - client_sent_unix_ms
	if round_trip_ms > MAX_CLOCK_ROUND_TRIP_MS:
		return {}
	var midpoint_ms := client_sent_unix_ms + round_trip_ms / 2
	return {
		"server_offset_ms": server_unix_ms - midpoint_ms,
		"uncertainty_ms": (round_trip_ms + 1) / 2,
		"round_trip_ms": round_trip_ms,
		"sampled_at_client_unix_ms": client_received_unix_ms,
		"authority": "server",
	}


static func canonical_character_snapshot(response: Dictionary, expected_account_id: String, expected_character_id: String) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION:
		return {}
	if str(response.get("authority", "")) != "server" or str(response.get("shard_id", "")) != DEFAULT_SHARD_ID:
		return {}
	if not _valid_identifier(expected_account_id) or not _valid_identifier(expected_character_id):
		return {}
	if str(response.get("account_id", "")) != expected_account_id or str(response.get("character_id", "")) != expected_character_id:
		return {}
	var revision := int(response.get("revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var profile = response.get("profile", null)
	if revision < 0 or not _valid_unix_ms(server_unix_ms) or not profile is Dictionary:
		return {}
	if str(profile.get("character_id", "")) != expected_character_id or _contains_secret(profile):
		return {}
	return {
		"api_version": API_VERSION,
		"authority": "server",
		"shard_id": DEFAULT_SHARD_ID,
		"account_id": expected_account_id,
		"character_id": expected_character_id,
		"revision": revision,
		"server_unix_ms": server_unix_ms,
		"profile": profile.duplicate(true),
	}


static func make_command(command_id: String, idempotency_key: String, operation: String, session_id: String, character_id: String, expected_revision: int, payload: Dictionary) -> Dictionary:
	if not _valid_identifier(command_id) or not _valid_identifier(idempotency_key) or not _valid_identifier(session_id) or not _valid_identifier(character_id):
		return {}
	if not ALLOWED_OPERATIONS.has(operation) or expected_revision < 0 or _contains_secret(payload):
		return {}
	return {
		"api_version": API_VERSION,
		"command_id": command_id,
		"idempotency_key": idempotency_key,
		"operation": operation,
		"session_id": session_id,
		"shard_id": DEFAULT_SHARD_ID,
		"character_id": character_id,
		"expected_revision": expected_revision,
		"payload": payload.duplicate(true),
	}


static func canonical_command_receipt(response: Dictionary, command: Dictionary) -> Dictionary:
	if command.is_empty() or int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server":
		return {}
	if str(response.get("command_id", "")) != str(command.get("command_id", "")) \
		or str(response.get("idempotency_key", "")) != str(command.get("idempotency_key", "")) \
		or str(response.get("operation", "")) != str(command.get("operation", "")) \
		or str(response.get("shard_id", "")) != str(command.get("shard_id", "")) \
		or str(response.get("character_id", "")) != str(command.get("character_id", "")):
		return {}
	var status := str(response.get("status", ""))
	if status not in [RECEIPT_ACCEPTED, RECEIPT_DUPLICATE, RECEIPT_CONFLICT, RECEIPT_REJECTED]:
		return {}
	var expected_revision := int(command.get("expected_revision", -1))
	var server_revision := int(response.get("server_revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	if expected_revision < 0 or server_revision < 0 or not _valid_unix_ms(server_unix_ms):
		return {}
	if status in [RECEIPT_ACCEPTED, RECEIPT_DUPLICATE] and server_revision <= expected_revision:
		return {}
	if status == RECEIPT_CONFLICT and server_revision < expected_revision:
		return {}
	var reason_code := str(response.get("reason_code", ""))
	if not reason_code.is_empty() and not _valid_identifier(reason_code):
		return {}
	return {
		"api_version": API_VERSION,
		"authority": "server",
		"command_id": str(command.command_id),
		"idempotency_key": str(command.idempotency_key),
		"operation": str(command.operation),
		"shard_id": str(command.shard_id),
		"character_id": str(command.character_id),
		"status": status,
		"server_revision": server_revision,
		"server_unix_ms": server_unix_ms,
		"reason_code": reason_code,
	}


static func action_for_receipt(receipt: Dictionary) -> String:
	match str(receipt.get("status", "")):
		RECEIPT_ACCEPTED, RECEIPT_DUPLICATE:
			return ACTION_COMPLETE
		RECEIPT_CONFLICT:
			return ACTION_FETCH_SNAPSHOT
		RECEIPT_REJECTED:
			return ACTION_STOP
	return ACTION_STOP


static func action_for_transport(http_status: int, transport_failed: bool) -> String:
	if transport_failed or http_status == 408 or http_status == 429 or http_status >= 500:
		return ACTION_RETRY_SAME_COMMAND
	if http_status == 401:
		return ACTION_REFRESH_AND_RETRY
	if http_status == 409:
		return ACTION_FETCH_SNAPSHOT
	return ACTION_STOP


static func _valid_identifier(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var allowed := (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code in [45, 46, 95]
		if not allowed:
			return false
	return true


static func _valid_unix_ms(value: int) -> bool:
	return value >= 0 and value <= MAX_UNIX_MS


static func _contains_secret(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			var normalized_key := str(key).to_lower()
			if SECRET_KEYS.has(normalized_key) or normalized_key in ["bearer_token", "api_key", "client_secret"]:
				return true
			if _contains_secret(value[key]):
				return true
	elif value is Array:
		for entry in value:
			if _contains_secret(entry):
				return true
	return false
