extends SceneTree

const Adapter = preload("res://scripts/nakama_backend_adapter.gd")

var failures := 0


func _init() -> void:
	var adapter = Adapter.new()
	check(not adapter.is_configured() and adapter.configuration_summary().is_empty(), "adapter starts inert and exposes no endpoint")
	check(not adapter.configure({}), "adapter rejects an absent deployment configuration")
	check(not adapter.configure({
		"provider_id": "nakama", "environment": "local", "host": "192.168.1.9", "port": 7350, "ssl": false, "client_key": "local_public_key_1234",
	}), "adapter rejects cleartext LAN configuration")
	check(adapter.configure({
		"provider_id": "nakama", "environment": "local", "host": "127.0.0.1", "port": 7350, "ssl": false, "client_key": "local_public_key_1234",
	}), "adapter accepts the canonical loopback-only development endpoint")
	var summary: Dictionary = adapter.configuration_summary()
	check(str(summary.environment) == "local" and str(summary.host) == "127.0.0.1" and int(summary.port) == 7350, "safe configuration summary preserves connection identity")
	check(not summary.has("client_key") and not summary.has("server_key") and not summary.has("password"), "configuration summary never exposes credentials")
	check(not adapter.has_authenticated_session(), "configuration alone cannot claim an authenticated session")
	for method_name in ["get_economy", "get_build", "get_hunt_board", "get_agency_membership", "get_agency_directory", "create_agency", "accept_hunt", "resolve_hunt", "claim_reward", "allocate_attributes", "equip_item", "recycle_item"]:
		check(adapter.has_method(method_name), "inert adapter exposes reviewed authority method %s" % method_name)
	check(adapter.configure({
		"provider_id": "nakama", "environment": "staging", "host": "staging-api.crookedgalaxy.com", "port": 443, "ssl": true, "client_key": "staging_public_key_1234",
	}), "adapter accepts the canonical TLS-only staging endpoint")
	adapter.clear_runtime()
	check(not adapter.is_configured() and not adapter.has_authenticated_session(), "runtime clear removes endpoint and memory-only session state")
	if failures == 0:
		print("PASS: Nakama adapter is inert by default, loopback-bounded, and credential-safe")
		quit(0)
	else:
		printerr("FAIL: %d Nakama-adapter issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
