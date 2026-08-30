extends Node

const Deployment = preload("res://scripts/backend_deployment_rules.gd")
const Probe = preload("res://scripts/staging_client_probe.gd")

const PROBE_ARGUMENT := "--staging-boot-probe"


func _ready() -> void:
	if not OS.get_cmdline_user_args().has(PROBE_ARGUMENT):
		return
	call_deferred("_run_probe")


func _run_probe() -> void:
	var client_key := OS.get_environment("CG_STAGING_NAKAMA_SERVER_KEY")
	var host := OS.get_environment("CG_STAGING_NAKAMA_HOST").strip_edges().to_lower()
	var device_id := OS.get_environment("CG_STAGING_DEVICE_ID").strip_edges().to_lower()
	if device_id.is_empty():
		device_id = "cg-staging-normal-boot-0001"
	var configuration := Deployment.canonicalize_endpoint({
		"provider_id": "nakama",
		"environment": "staging",
		"host": host,
		"port": 443,
		"ssl": true,
		"client_key": client_key,
	})
	if configuration.is_empty():
		_finish({"ok": false, "error_code": "missing_or_unsafe_staging_configuration"})
		return
	var cache_path := "user://crooked_galaxy_staging_probe_cache.json"
	var probe = Probe.new()
	var result: Dictionary = await probe.run(configuration, device_id, cache_path)
	probe = null
	_finish(result)


func _finish(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		print("PASS: normal main-scene boot reached TLS staging, archival cutover, authoritative profile, read-only cache, and clean reconnect")
		call_deferred("_quit_probe", 0)
	else:
		printerr("FAIL: staging normal-boot probe: %s" % str(result.get("error_code", "unknown")))
		call_deferred("_quit_probe", 1)


func _quit_probe(exit_code: int) -> void:
	# Nakama queues completed HTTPRequest nodes for deletion; allow the normal
	# main-scene loop to drain them before the test process exits.
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(exit_code)
