extends SceneTree

const Adapter = preload("res://scripts/nakama_backend_adapter.gd")

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
	adapter.clear_runtime()
	check(not adapter.has_authenticated_session(), "memory-only session is discarded after the integration proof")
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: official Nakama Godot client authenticated and sampled authoritative UTC end to end")
		quit(0)
	else:
		printerr("FAIL: %d local Nakama integration issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
