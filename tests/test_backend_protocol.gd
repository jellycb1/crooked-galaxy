extends SceneTree

const Protocol = preload("res://scripts/backend_protocol_rules.gd")
const Service = preload("res://scripts/account_service.gd")
const Servers = preload("res://scripts/server_rules.gd")

var failures := 0
var now_ms := 1788000000000


func _init() -> void:
	test_honest_unconfigured_boundary()
	test_authenticated_session_boundary()
	test_authoritative_clock()
	test_character_snapshot()
	test_idempotent_commands_and_receipts()
	test_retry_policy()
	if failures == 0:
		print("PASS: provider-neutral backend protocol preserves authority, secrets, revisions, and idempotency")
		quit(0)
	else:
		printerr("FAIL: %d backend-protocol issue(s)" % failures)
		quit(1)


func test_honest_unconfigured_boundary() -> void:
	var service = Service.new()
	check(not service.backend_available() and not service.supports_remote_sessions() and not service.server_clock_available(), "local adapter advertises no remote session or clock")
	check(not Servers.account_backend_available(Servers.DEFAULT_ID) and not Servers.clock_backend_available(Servers.DEFAULT_ID) and not Servers.profile_backend_available(Servers.DEFAULT_ID) and not Servers.economy_backend_available(Servers.DEFAULT_ID), "International 1 keeps every remote foundation flag disabled")
	check(not Servers.agency_backend_available(Servers.DEFAULT_ID), "Agency availability remains gated behind its server authority")
	var server := Servers.get_definition(Servers.DEFAULT_ID)
	check(str(server.backend_provider) == "nakama" and str(server.backend_environment) == "offline", "International 1 records the selected provider without claiming a deployment")


func test_authenticated_session_boundary() -> void:
	var response := valid_session_response()
	var summary := Protocol.canonical_session_summary(response, now_ms)
	check(not summary.is_empty() and str(summary.account_id) == "account_42" and str(summary.active_character_id) == "hunter_7", "valid authenticated response binds account, shard, and active character")
	check(not summary.has("access_token") and not summary.has("refresh_token"), "persistable session summary strips all bearer credentials")
	check(Protocol.extract_bearer_credential(response, now_ms) == "0123456789abcdef0123456789abcdef", "valid bearer credential can be extracted for memory-only transport use")

	var foreign_shard := response.duplicate(true)
	foreign_shard.shard_id = "regional_2"
	check(Protocol.canonical_session_summary(foreign_shard, now_ms).is_empty(), "session from another shard is rejected")
	var foreign_character := response.duplicate(true)
	foreign_character.active_character_id = "hunter_8"
	check(Protocol.canonical_session_summary(foreign_character, now_ms).is_empty(), "active character must appear in the account ownership list")
	var expired := response.duplicate(true)
	expired.expires_at_unix_ms = now_ms
	check(Protocol.canonical_session_summary(expired, now_ms).is_empty(), "expired session cannot be accepted")
	var long_lived := response.duplicate(true)
	long_lived.expires_at_unix_ms = int(long_lived.issued_at_unix_ms) + Protocol.MAX_SESSION_LIFETIME_MS + 1
	check(Protocol.canonical_session_summary(long_lived, now_ms).is_empty(), "unbounded server session lifetime is rejected")


func test_authoritative_clock() -> void:
	var sample := Protocol.canonical_clock_sample({"api_version": 1, "authority": "server", "server_unix_ms": now_ms + 250}, now_ms, now_ms + 100)
	check(int(sample.server_offset_ms) == 200 and int(sample.uncertainty_ms) == 50 and int(sample.round_trip_ms) == 100, "clock sample uses the request midpoint and reports uncertainty")
	check(Protocol.canonical_clock_sample({"api_version": 1, "authority": "server", "server_unix_ms": now_ms}, now_ms + 10, now_ms).is_empty(), "clock rejects reversed client timestamps")
	check(Protocol.canonical_clock_sample({"api_version": 1, "authority": "server", "server_unix_ms": now_ms}, now_ms, now_ms + Protocol.MAX_CLOCK_ROUND_TRIP_MS + 1).is_empty(), "clock rejects stale high-latency samples")


func test_character_snapshot() -> void:
	var response := {
		"api_version": 1,
		"authority": "server",
		"shard_id": "international_1",
		"account_id": "account_42",
		"character_id": "hunter_7",
		"revision": 19,
		"server_unix_ms": now_ms,
		"profile": {"character_id": "hunter_7", "level": 31, "credits": 8900},
	}
	var snapshot := Protocol.canonical_character_snapshot(response, "account_42", "hunter_7")
	check(not snapshot.is_empty() and int(snapshot.revision) == 19 and int(snapshot.profile.level) == 31, "matching server snapshot preserves its authoritative revision")
	check(Protocol.canonical_character_snapshot(response, "account_42", "hunter_8").is_empty(), "foreign character snapshot is rejected")
	var leaked := response.duplicate(true)
	leaked.profile.inventory = [{"access_token": "must_not_enter_profile"}]
	check(Protocol.canonical_character_snapshot(leaked, "account_42", "hunter_7").is_empty(), "nested credentials cannot enter a profile snapshot")


func test_idempotent_commands_and_receipts() -> void:
	var command := Protocol.make_command("cmd_1001", "idem_1001", "agency_contribute_intel", "session_44", "hunter_7", 19, {
		"agency_id": "agency_orbit_9",
		"warrant_id": "warrant_42",
		"event_id": "hunt_888",
	})
	check(not command.is_empty() and int(command.expected_revision) == 19 and str(command.shard_id) == "international_1", "Agency command carries shard, character, revision, and stable idempotency")
	var secret_command := Protocol.make_command("cmd_1002", "idem_1002", "profile_commit", "session_44", "hunter_7", 19, {"nested": {"refresh_token": "leak"}})
	check(secret_command.is_empty(), "commands reject credentials even when nested in payloads")
	check(Protocol.make_command("cmd_1003", "idem_1003", "unknown_operation", "session_44", "hunter_7", 19, {}).is_empty(), "unregistered remote operations are rejected")
	var create_agency := Protocol.make_command("cmd_1004", "idem_1004", "agency_create", "session_44", "hunter_7", 0,
		{"name": "Orion Recovery", "recruitment_mode": "application", "preferred_locale": "multi"})
	check(not create_agency.is_empty() and not create_agency.payload.has("agency_id"), "Agency creation sends only reviewed profile intent and leaves identity to the server")
	check(Protocol.make_command("cmd_1005", "idem_1005", "agency_create", "session_44", "hunter_7", 0,
		{"name": "Orion Recovery", "recruitment_mode": "application", "preferred_locale": "multi", "prestige": 999}).is_empty(),
		"Agency creation cannot author identity, prestige, roster, or extra state")

	var accepted_response := valid_receipt_for(command, Protocol.RECEIPT_ACCEPTED, 20)
	var accepted := Protocol.canonical_command_receipt(accepted_response, command)
	check(not accepted.is_empty() and Protocol.action_for_receipt(accepted) == Protocol.ACTION_COMPLETE, "accepted command completes only with a newer server revision")
	var duplicate_response := valid_receipt_for(command, Protocol.RECEIPT_DUPLICATE, 20)
	check(Protocol.action_for_receipt(Protocol.canonical_command_receipt(duplicate_response, command)) == Protocol.ACTION_COMPLETE, "duplicate receipt resolves the original idempotent command without replay")
	var conflict_response := valid_receipt_for(command, Protocol.RECEIPT_CONFLICT, 24)
	check(Protocol.action_for_receipt(Protocol.canonical_command_receipt(conflict_response, command)) == Protocol.ACTION_FETCH_SNAPSHOT, "revision conflict requires an authoritative snapshot")
	var stale_accept := valid_receipt_for(command, Protocol.RECEIPT_ACCEPTED, 19)
	check(Protocol.canonical_command_receipt(stale_accept, command).is_empty(), "accepted mutation cannot retain the expected revision")
	var wrong_id := accepted_response.duplicate(true)
	wrong_id.idempotency_key = "idem_other"
	check(Protocol.canonical_command_receipt(wrong_id, command).is_empty(), "receipt cannot acknowledge a different idempotency key")


func test_retry_policy() -> void:
	check(Protocol.action_for_transport(0, true) == Protocol.ACTION_RETRY_SAME_COMMAND, "transport failure retries the same command identity")
	check(Protocol.action_for_transport(429, false) == Protocol.ACTION_RETRY_SAME_COMMAND and Protocol.action_for_transport(503, false) == Protocol.ACTION_RETRY_SAME_COMMAND, "rate limits and server failures preserve the original idempotency key")
	check(Protocol.action_for_transport(401, false) == Protocol.ACTION_REFRESH_AND_RETRY, "authentication failure refreshes then retries the same command")
	check(Protocol.action_for_transport(409, false) == Protocol.ACTION_FETCH_SNAPSHOT, "HTTP conflict fetches server truth instead of blind retry")
	check(Protocol.action_for_transport(422, false) == Protocol.ACTION_STOP, "domain rejection stops without a retry loop")


func valid_session_response() -> Dictionary:
	return {
		"api_version": 1,
		"authority": "server",
		"provider_id": "account_provider",
		"account_id": "account_42",
		"session_id": "session_44",
		"session_state": "authenticated",
		"shard_id": "international_1",
		"active_character_id": "hunter_7",
		"owned_character_ids": ["hunter_7"],
		"issued_at_unix_ms": now_ms - 1000,
		"expires_at_unix_ms": now_ms + 86400000,
		"access_token": "0123456789abcdef0123456789abcdef",
		"refresh_token": "never_persist_this",
	}


func valid_receipt_for(command: Dictionary, status: String, revision: int) -> Dictionary:
	return {
		"api_version": 1,
		"authority": "server",
		"command_id": command.command_id,
		"idempotency_key": command.idempotency_key,
		"operation": command.operation,
		"shard_id": command.shard_id,
		"character_id": command.character_id,
		"status": status,
		"server_revision": revision,
		"server_unix_ms": now_ms,
		"reason_code": "",
	}


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
