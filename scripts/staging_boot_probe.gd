extends Node

const Deployment = preload("res://scripts/backend_deployment_rules.gd")
const Probe = preload("res://scripts/staging_client_probe.gd")

func _ready() -> void:
	if not Deployment.staging_probe_requested():
		return
	call_deferred("_run_probe")


func _run_probe() -> void:
	var request := _probe_request()
	if request.is_empty():
		_finish({"ok": false, "error_code": "missing_or_unsafe_staging_configuration"})
		return
	var configuration: Dictionary = request.configuration
	var device_id := str(request.device_id)
	var cache_path := "user://crooked_galaxy_staging_probe_cache.json"
	var probe = Probe.new()
	var result: Dictionary = await probe.run(configuration, device_id, cache_path)
	probe = null
	_finish(result)


func _probe_request() -> Dictionary:
	if OS.get_cmdline_user_args().has(Deployment.STAGING_PROBE_ARGUMENT):
		var device_id := OS.get_environment("CG_STAGING_DEVICE_ID").strip_edges().to_lower()
		if device_id.is_empty():
			device_id = "cg-staging-normal-boot-0001"
		var configuration := Deployment.canonicalize_endpoint({
			"provider_id": Deployment.PROVIDER_ID,
			"environment": Deployment.ENV_STAGING,
			"host": OS.get_environment("CG_STAGING_NAKAMA_HOST"),
			"port": 443,
			"ssl": true,
			"client_key": OS.get_environment("CG_STAGING_NAKAMA_SERVER_KEY"),
		})
		if configuration.is_empty():
			return {}
		return {"configuration": configuration, "device_id": device_id}
	if OS.get_name() != "Android" or not FileAccess.file_exists(Deployment.ANDROID_STAGING_PROBE_PATH):
		return {}
	var file := FileAccess.open(Deployment.ANDROID_STAGING_PROBE_PATH, FileAccess.READ)
	var raw := "" if file == null else file.get_as_text()
	file = null
	# Treat this as a one-use mailbox. Delete before parsing or making a request so
	# a crash, relaunch, or screenshot collection cannot replay the credential.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Deployment.ANDROID_STAGING_PROBE_PATH))
	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return {}
	return Deployment.canonicalize_android_staging_probe(parsed, int(Time.get_unix_time_from_system()))


func _finish(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		print("PASS: normal main-scene boot completed TLS staging, archival cutover, authoritative hunt/reward/equipment, read-only cache, and clean reconnect")
		call_deferred("_quit_probe", 0)
	else:
		printerr("FAIL: staging normal-boot probe: %s" % str(result.get("error_code", "unknown")))
		call_deferred("_quit_probe", 1)


func _quit_probe(exit_code: int) -> void:
	# Nakama queues completed HTTPRequest nodes for deletion; allow the normal
	# main-scene loop to drain them before the test process exits.
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(exit_code)
