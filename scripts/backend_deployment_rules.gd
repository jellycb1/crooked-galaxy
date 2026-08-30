class_name BackendDeploymentRules
extends RefCounted

const PROVIDER_ID := "nakama"
const SERVER_VERSION := "3.40.0"
const GODOT_CLIENT_VERSION := "3.4.0"
const RUNTIME_TYPES_VERSION := "1.47.0"

const ENV_OFFLINE := "offline"
const ENV_LOCAL := "local"
const ENV_STAGING := "staging"
const ENV_PRODUCTION := "production"

const STAGING_PROBE_ARGUMENT := "--staging-boot-probe"
const ANDROID_STAGING_PROBE_PATH := "user://crooked_galaxy_android_staging_probe.json"
const ANDROID_STAGING_PROBE_MODE := "android_staging_probe_v1"
const ANDROID_STAGING_PROBE_SCHEMA := 1
const ANDROID_STAGING_PROBE_MAX_LIFETIME_SECONDS := 600

const CAP_ACCOUNT := "account"
const CAP_CLOCK := "clock"
const CAP_PROFILE := "profile"
const CAP_ECONOMY := "economy"
const CAP_AGENCY := "agency"
const CAP_BILLING := "billing"

const RELEASE_GATE_PHYSICAL_TLS := "physical_android_tls_verified"
const RELEASE_GATE_PHYSICAL_LIFECYCLE := "physical_android_lifecycle_verified"
const RELEASE_GATE_REAL_SAVE_CUTOVER := "real_save_cutover_verified"
const RELEASE_GATE_NORMAL_LOGIN := "normal_login_flow_verified"
const RELEASE_GATE_ACTIVATION_APPROVED := "deliberate_activation_approved"
const RELEASE_GATE_PHYSICAL_HUNT := "physical_authoritative_hunt_verified"
const RELEASE_GATE_PHYSICAL_BUILD := "physical_build_mutations_verified"
const RELEASE_GATE_AGENCY_FLOW := "agency_client_flow_verified"
const RELEASE_GATE_AGENCY_APPROVED := "agency_activation_approved"
const RELEASE_GATE_BILLING_FLOW := "billing_platform_flow_verified"
const RELEASE_GATE_BILLING_APPROVED := "billing_activation_approved"


static func current_client_configuration() -> Dictionary:
	return {
		"provider_id": PROVIDER_ID,
		"environment": ENV_OFFLINE,
		"configured": false,
		"host": "",
		"port": 0,
		"ssl": false,
		"client_key": "",
	}


static func staging_probe_requested() -> bool:
	return OS.get_cmdline_user_args().has(STAGING_PROBE_ARGUMENT) or (
		OS.get_name() == "Android" and FileAccess.file_exists(ANDROID_STAGING_PROBE_PATH)
	)


static func canonicalize_android_staging_probe(payload: Dictionary, now_unix: int) -> Dictionary:
	if int(payload.get("schema", 0)) != ANDROID_STAGING_PROBE_SCHEMA or str(payload.get("mode", "")) != ANDROID_STAGING_PROBE_MODE:
		return {}
	var expires_at_unix := int(payload.get("expires_at_unix", 0))
	if expires_at_unix <= now_unix or expires_at_unix > now_unix + ANDROID_STAGING_PROBE_MAX_LIFETIME_SECONDS:
		return {}
	var device_id := str(payload.get("device_id", "")).strip_edges().to_lower()
	if device_id.length() < 16 or device_id.length() > 128:
		return {}
	for character in device_id:
		if "abcdefghijklmnopqrstuvwxyz0123456789_-".find(character) < 0:
			return {}
	var configuration := canonicalize_endpoint({
		"provider_id": PROVIDER_ID,
		"environment": ENV_STAGING,
		"host": str(payload.get("host", "")),
		"port": 443,
		"ssl": true,
		"client_key": str(payload.get("client_key", "")),
	})
	if configuration.is_empty():
		return {}
	return {"configuration": configuration, "device_id": device_id}


static func canonicalize_endpoint(configuration: Dictionary) -> Dictionary:
	var environment := str(configuration.get("environment", ""))
	if environment not in [ENV_LOCAL, ENV_STAGING, ENV_PRODUCTION]:
		return {}
	if str(configuration.get("provider_id", "")) != PROVIDER_ID:
		return {}
	var host := str(configuration.get("host", "")).strip_edges().to_lower()
	var port := int(configuration.get("port", 0))
	var use_ssl := bool(configuration.get("ssl", false))
	var client_key := str(configuration.get("client_key", ""))
	if not _valid_host(host) or port < 1 or port > 65535 or client_key.length() < 16 or client_key.length() > 128:
		return {}
	var loopback := host in ["127.0.0.1", "localhost", "::1"]
	if environment == ENV_LOCAL:
		if not loopback or use_ssl:
			return {}
	else:
		if loopback or not use_ssl or port != 443:
			return {}
	return {
		"provider_id": PROVIDER_ID,
		"environment": environment,
		"configured": true,
		"host": host,
		"port": port,
		"ssl": use_ssl,
		"client_key": client_key,
	}


static func capability_activation(evidence: Dictionary) -> Dictionary:
	var account := bool(evidence.get("authenticated_session", false)) and bool(evidence.get("ownership_verified", false))
	var clock := account and bool(evidence.get("server_clock_verified", false))
	var profile := clock and bool(evidence.get("snapshot_verified", false)) and bool(evidence.get("idempotent_commit_verified", false)) and bool(evidence.get("conflict_recovery_verified", false))
	var economy := profile and bool(evidence.get("economy_snapshot_verified", false)) and bool(evidence.get("hunt_acceptance_verified", false)) and bool(evidence.get("reward_receipt_verified", false)) and bool(evidence.get("economy_replay_protection_verified", false))
	var agency := economy and bool(evidence.get("agency_storage_verified", false)) and bool(evidence.get("agency_authority_verified", false))
	var billing := economy and bool(evidence.get("store_receipt_validation_verified", false)) and bool(evidence.get("wallet_replay_protection_verified", false)) and bool(evidence.get("refund_path_verified", false))
	return {
		CAP_ACCOUNT: account,
		CAP_CLOCK: clock,
		CAP_PROFILE: profile,
		CAP_ECONOMY: economy,
		CAP_AGENCY: agency,
		CAP_BILLING: billing,
	}


static func normal_client_activation(evidence: Dictionary, release_gates: Dictionary) -> Dictionary:
	var technical := capability_activation(evidence)
	var common_release_ready := _all_release_gates(release_gates, [
		RELEASE_GATE_PHYSICAL_TLS,
		RELEASE_GATE_PHYSICAL_LIFECYCLE,
		RELEASE_GATE_REAL_SAVE_CUTOVER,
		RELEASE_GATE_NORMAL_LOGIN,
		RELEASE_GATE_ACTIVATION_APPROVED,
	])
	var account := bool(technical.account) and common_release_ready
	var clock := account and bool(technical.clock)
	var profile := clock and bool(technical.profile)
	var economy := profile and bool(technical.economy) and _all_release_gates(release_gates, [
		RELEASE_GATE_PHYSICAL_HUNT,
		RELEASE_GATE_PHYSICAL_BUILD,
	])
	var agency := economy and bool(technical.agency) and _all_release_gates(release_gates, [
		RELEASE_GATE_AGENCY_FLOW,
		RELEASE_GATE_AGENCY_APPROVED,
	])
	var billing := economy and bool(technical.billing) and _all_release_gates(release_gates, [
		RELEASE_GATE_BILLING_FLOW,
		RELEASE_GATE_BILLING_APPROVED,
	])
	return {
		CAP_ACCOUNT: account,
		CAP_CLOCK: clock,
		CAP_PROFILE: profile,
		CAP_ECONOMY: economy,
		CAP_AGENCY: agency,
		CAP_BILLING: billing,
	}


static func pending_normal_client_gates(evidence: Dictionary, release_gates: Dictionary) -> Array[String]:
	var pending: Array[String] = []
	var technical := capability_activation(evidence)
	for capability in [CAP_ACCOUNT, CAP_CLOCK, CAP_PROFILE, CAP_ECONOMY]:
		if not bool(technical.get(capability, false)):
			pending.append("technical_%s" % capability)
	for gate in [
		RELEASE_GATE_PHYSICAL_TLS,
		RELEASE_GATE_PHYSICAL_LIFECYCLE,
		RELEASE_GATE_REAL_SAVE_CUTOVER,
		RELEASE_GATE_NORMAL_LOGIN,
		RELEASE_GATE_ACTIVATION_APPROVED,
		RELEASE_GATE_PHYSICAL_HUNT,
		RELEASE_GATE_PHYSICAL_BUILD,
	]:
		if not bool(release_gates.get(gate, false)):
			pending.append(gate)
	return pending


static func secret_safe_for_client(configuration: Dictionary) -> bool:
	for key in configuration:
		var normalized := str(key).to_lower()
		if normalized in ["password", "database_url", "session_encryption_key", "refresh_encryption_key", "runtime_http_key", "google_credentials_json", "iap_private_key", "client_secret"]:
			return false
	return true


static func _all_release_gates(release_gates: Dictionary, required: Array) -> bool:
	for gate in required:
		if not bool(release_gates.get(str(gate), false)):
			return false
	return true


static func _valid_host(host: String) -> bool:
	if host.is_empty() or host.length() > 253 or host.contains("/") or host.contains("\\") or host.contains("@") or host.contains(" "):
		return false
	for index in host.length():
		var code := host.unicode_at(index)
		var allowed := (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code in [45, 46, 58]
		if not allowed:
			return false
	return true
