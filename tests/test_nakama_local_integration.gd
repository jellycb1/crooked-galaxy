extends SceneTree

const Adapter = preload("res://scripts/nakama_backend_adapter.gd")
const AgencyDispatcher = preload("res://scripts/remote_agency_dispatcher.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_integration")


func run_integration() -> void:
	var client_key := OS.get_environment("CG_LOCAL_NAKAMA_SERVER_KEY")
	check(client_key.length() >= 16, "local client key was injected into the test process")
	if failures > 0:
		finish()
		return
	var adapter = Adapter.new()
	check(adapter.configure({
		"provider_id": "nakama",
		"environment": "local",
		"host": "127.0.0.1",
		"port": 7350,
		"ssl": false,
		"client_key": client_key,
	}), "local Nakama endpoint passed the deployment boundary")
	var authentication: Dictionary = await adapter.authenticate_development("cg-godot-smoke-00000001", "cg_godot_smoke")
	check(bool(authentication.get("ok", false)), "official Godot client authenticated a development device session")
	check(str(authentication.get("account_id", "")).length() > 0 and str(authentication.get("authority", "")) == "server", "authentication returned a sanitized server account identity")
	check(not authentication.has("token") and not authentication.has("access_token") and not authentication.has("refresh_token"), "authentication result contains no bearer credential")
	var clock: Dictionary = await adapter.sample_server_clock()
	check(bool(clock.get("ok", false)) and int(clock.get("api_version", 0)) == 1, "Godot client invoked protocol-v1 clock RPC")
	check(str(clock.get("shard_id", "")) == "international_1" and str(clock.get("authority", "")) == "server", "clock binds the canonical shard and server authority")
	check(int(clock.get("round_trip_ms", -1)) >= 0 and int(clock.get("round_trip_ms", 30001)) <= 30000, "clock round trip satisfies the protocol latency bound")
	var before_character: Dictionary = await adapter.get_character()
	check(bool(before_character.get("ok", false)), "Godot client fetched the account character boundary")
	var creation: Dictionary = await adapter.create_character(
		"godot-create-00000001",
		"Godot Trace",
		"contract_hacker",
		"synthetic",
		{"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	)
	check(bool(creation.get("ok", false)), "Godot client created or idempotently recovered the mandatory character")
	check(str(creation.get("account_id", "")) == str(authentication.get("account_id", "")) and str(creation.get("character_id", "")) == str(authentication.get("account_id", "")), "authoritative character ownership matches the authenticated account")
	check(int(creation.get("revision", -1)) >= 0 and int(creation.get("profile", {}).get("credits", -1)) == 25, "Godot accepted the server-owned launch baseline")
	var replay: Dictionary = await adapter.create_character(
		"godot-create-00000001",
		"Godot Trace",
		"contract_hacker",
		"synthetic",
		{"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	)
	check(bool(replay.get("ok", false)) and bool(replay.get("idempotent_replay", false)), "Godot creation retry recovered the same server character")
	var session_summary: Dictionary = await adapter.get_session_summary()
	check(bool(session_summary.get("ok", false)) and str(session_summary.get("session_state", "")) == "authenticated", "Godot canonicalized the authenticated post-creation session")
	check(str(session_summary.get("active_character_id", "")) == str(authentication.get("account_id", "")) and session_summary.get("owned_character_ids", []).size() == 1, "session binds exactly the account-owned active character")
	var agency_dispatcher = AgencyDispatcher.new(adapter, str(authentication.get("account_id", "")))
	var agency_bootstrap: Dictionary = await agency_dispatcher.bootstrap()
	check(bool(agency_bootstrap.get("ok", false)), "Godot canonicalized independent server-owned Agency membership")
	if str(agency_dispatcher.snapshot().get("membership_state", "")) == "none":
		var agency_nonce := str(int(Time.get_unix_time_from_system() * 1000.0))
		var agency_created: Dictionary = await agency_dispatcher.dispatch_create("godot-agency-%s" % agency_nonce,
			"godot-agency-receipt-%s" % agency_nonce, "Godot Recovery", "application", "multi")
		check(bool(agency_created.get("ok", false)) and str(agency_dispatcher.snapshot().get("role_id", "")) == "director",
			"Godot created an Agency and refetched its sole-Director membership")
	else:
		check(str(agency_dispatcher.snapshot().get("membership_state", "")) == "member" and str(agency_dispatcher.snapshot().get("role_id", "")) == "director",
			"repeat integration recovered the existing owned Agency without creating another")
	var agency_directory: Dictionary = await adapter.get_agency_directory("")
	check(bool(agency_directory.get("ok", false)) and agency_directory.get("agencies", []).size() <= 25,
		"Godot canonicalized a bounded roster-free Agency directory page")
	var target_agency_id := str(agency_dispatcher.snapshot().get("agency_id", ""))
	var applicant_adapter = Adapter.new()
	check(applicant_adapter.configure({
		"provider_id": "nakama",
		"environment": "local",
		"host": "127.0.0.1",
		"port": 7350,
		"ssl": false,
		"client_key": client_key,
	}), "second Godot adapter accepted the same explicit local deployment boundary")
	var applicant_auth: Dictionary = await applicant_adapter.authenticate_development("cg-godot-applicant-00000001", "cg_godot_applicant")
	check(bool(applicant_auth.get("ok", false)), "second official Godot client authenticated an Agency applicant")
	var applicant_creation: Dictionary = await applicant_adapter.create_character(
		"godot-applicant-create-00000001",
		"Godot Applicant",
		"orbit_gunslinger",
		"terran",
		{"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	)
	check(bool(applicant_creation.get("ok", false)), "Agency applicant created or recovered an owned character")
	var applicant_dispatcher = AgencyDispatcher.new(applicant_adapter, str(applicant_auth.get("account_id", "")))
	var applicant_bootstrap: Dictionary = await applicant_dispatcher.bootstrap()
	check(bool(applicant_bootstrap.get("ok", false)), "Agency applicant bootstrapped independent membership")
	if str(applicant_dispatcher.snapshot().get("membership_state", "")) == "none":
		var apply_nonce := str(int(Time.get_unix_time_from_system() * 1000.0))
		var applied: Dictionary = await applicant_dispatcher.dispatch("godot-apply-%s" % apply_nonce,
			"godot-apply-receipt-%s" % apply_nonce, "agency_apply", target_agency_id)
		check(bool(applied.get("ok", false)) and str(applicant_dispatcher.snapshot().get("membership_state", "")) == "application_pending",
			"Godot submitted an exact application and refetched its roster-free pending state")
	else:
		check(str(applicant_dispatcher.snapshot().get("membership_state", "")) == "application_pending" \
			and str(applicant_dispatcher.snapshot().get("agency_id", "")) == target_agency_id,
			"repeat integration recovered the existing pending application without resubmitting it")
	check(bool(applicant_dispatcher.close().get("ok", false)), "applicant Agency runtime zeroized after the proof")
	applicant_adapter.clear_runtime()
	check(bool(agency_dispatcher.close().get("ok", false)) and agency_dispatcher.snapshot().is_empty(),
		"Agency presentation zeroized without clearing the shared authenticated adapter")
	var initial_revision := int(replay.get("revision", -1))
	var nonce := str(int(Time.get_unix_time_from_system() * 1000.0))
	var commit: Dictionary = await adapter.commit_profile(
		"godot-commit-%s" % nonce,
		"godot-receipt-%s" % nonce,
		initial_revision,
		"Godot Vector",
		{"palette": "cool", "eyes": "narrow", "feature": "bold", "marking": "stripe"}
	)
	check(bool(commit.get("ok", false)) and str(commit.get("status", "")) == "accepted", "Godot profile command was accepted")
	check(int(commit.get("server_revision", -1)) == initial_revision + 1 and int(commit.get("snapshot", {}).get("profile", {}).get("credits", -1)) == 25, "accepted commit advanced one revision without client-authored progression")
	var duplicate: Dictionary = await adapter.commit_profile(
		"godot-commit-%s" % nonce,
		"godot-receipt-%s" % nonce,
		initial_revision,
		"Godot Vector",
		{"palette": "cool", "eyes": "narrow", "feature": "bold", "marking": "stripe"}
	)
	check(bool(duplicate.get("ok", false)) and str(duplicate.get("status", "")) == "duplicate", "Godot retried an accepted command idempotently")
	var conflict: Dictionary = await adapter.commit_profile(
		"godot-stale-%s" % nonce,
		"godot-stale-receipt-%s" % nonce,
		initial_revision,
		"Godot Vector",
		{"palette": "cool", "eyes": "narrow", "feature": "bold", "marking": "stripe"}
	)
	check(bool(conflict.get("ok", false)) and str(conflict.get("status", "")) == "conflict", "Godot receives an explicit conflict for stale profile state")
	var final_character: Dictionary = await adapter.get_character()
	check(bool(final_character.get("ok", false)) and int(final_character.get("revision", -1)) == initial_revision + 1, "Godot refetched the final authoritative character snapshot")
	adapter.clear_runtime()
	check(not adapter.has_authenticated_session(), "memory-only session is discarded after the integration proof")
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: official Nakama Godot clients authenticated, created/discovered an Agency, submitted/recovered an application, and proved authoritative command state")
		quit(0)
	else:
		printerr("FAIL: %d local Nakama integration issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
