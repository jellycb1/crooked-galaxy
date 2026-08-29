extends SceneTree

const Deployment = preload("res://scripts/backend_deployment_rules.gd")

var failures := 0


func _init() -> void:
	var current := Deployment.current_client_configuration()
	check(str(current.provider_id) == "nakama" and str(current.environment) == "offline" and not bool(current.configured), "current APK names the selected provider without claiming an endpoint")
	check(Deployment.SERVER_VERSION == "3.40.0" and Deployment.GODOT_CLIENT_VERSION == "3.4.0" and Deployment.RUNTIME_TYPES_VERSION == "1.47.0", "reviewed server, Godot client, and runtime types remain pinned")

	var local := Deployment.canonicalize_endpoint({
		"provider_id": "nakama", "environment": "local", "host": "127.0.0.1", "port": 7350, "ssl": false, "client_key": "local_public_key_1234",
	})
	check(not local.is_empty() and bool(local.configured), "loopback development endpoint is accepted without pretending to use TLS")
	check(Deployment.canonicalize_endpoint({"provider_id": "nakama", "environment": "local", "host": "192.168.1.5", "port": 7350, "ssl": false, "client_key": "local_public_key_1234"}).is_empty(), "insecure LAN endpoint cannot masquerade as loopback development")
	var staging := Deployment.canonicalize_endpoint({
		"provider_id": "nakama", "environment": "staging", "host": "staging.crookedgalaxy.example", "port": 443, "ssl": true, "client_key": "staging_public_key_1234",
	})
	check(not staging.is_empty(), "remote staging endpoint requires TLS on port 443")
	check(Deployment.canonicalize_endpoint({"provider_id": "nakama", "environment": "production", "host": "game.example", "port": 7350, "ssl": false, "client_key": "production_public_key"}).is_empty(), "production cannot use cleartext or the development port")
	check(Deployment.canonicalize_endpoint({"provider_id": "supabase", "environment": "staging", "host": "game.example", "port": 443, "ssl": true, "client_key": "staging_public_key_1234"}).is_empty(), "unreviewed backend provider cannot be enabled by configuration")

	var no_evidence := Deployment.capability_activation({})
	check(not no_evidence.account and not no_evidence.clock and not no_evidence.profile and not no_evidence.agency and not no_evidence.billing, "no capability activates from configuration alone")
	var profile_evidence := {
		"authenticated_session": true,
		"ownership_verified": true,
		"server_clock_verified": true,
		"snapshot_verified": true,
		"idempotent_commit_verified": true,
		"conflict_recovery_verified": true,
	}
	var profile_ready := Deployment.capability_activation(profile_evidence)
	check(profile_ready.account and profile_ready.clock and profile_ready.profile and not profile_ready.agency and not profile_ready.billing, "profile authority activates only after every preceding proof")
	var all_evidence := profile_evidence.duplicate(true)
	all_evidence.agency_storage_verified = true
	all_evidence.agency_authority_verified = true
	all_evidence.store_receipt_validation_verified = true
	all_evidence.wallet_replay_protection_verified = true
	all_evidence.refund_path_verified = true
	var all_ready := Deployment.capability_activation(all_evidence)
	check(all_ready.agency and all_ready.billing, "Agency and billing each require their independent end-to-end evidence")
	check(not Deployment.secret_safe_for_client({"host": "game.example", "google_credentials_json": "secret"}), "server OAuth credentials are forbidden from client configuration")
	check(Deployment.secret_safe_for_client(staging), "canonical client endpoint contains no server secret")

	if failures == 0:
		print("PASS: Nakama deployment choice, endpoint safety, and staged capability activation are explicit")
		quit(0)
	else:
		printerr("FAIL: %d backend-deployment issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
