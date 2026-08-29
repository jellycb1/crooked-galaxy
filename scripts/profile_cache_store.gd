class_name ProfileCacheStore
extends RefCounted

const Sync = preload("res://scripts/profile_sync_rules.gd")

var cache_path := "user://crooked_galaxy_server_cache.json"


func write_snapshot(snapshot: Dictionary, account_id: String, character_id: String, cached_at_unix_ms: int) -> bool:
	var cache := Sync.make_read_only_cache(snapshot, account_id, character_id, cached_at_unix_ms)
	if cache.is_empty():
		return false
	var staging_path := "%s.tmp" % cache_path
	var staging_absolute := ProjectSettings.globalize_path(staging_path)
	var primary_absolute := ProjectSettings.globalize_path(cache_path)
	var backup_path := "%s.bak" % cache_path
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(cache))
	file.flush()
	file.close()
	if FileAccess.file_exists(cache_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_absolute)
		if DirAccess.rename_absolute(primary_absolute, backup_absolute) != OK:
			return false
	if DirAccess.rename_absolute(staging_absolute, primary_absolute) != OK:
		if not FileAccess.file_exists(cache_path) and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, primary_absolute)
		return false
	return true


func load_snapshot(account_id: String, character_id: String, now_unix_ms: int) -> Dictionary:
	for path in ["%s.tmp" % cache_path, cache_path, "%s.bak" % cache_path]:
		var parsed := _read_dictionary(path)
		if parsed.is_empty():
			continue
		var opened := Sync.open_read_only_cache(parsed, account_id, character_id, now_unix_ms)
		if not opened.is_empty():
			return opened
	return {}


func clear() -> void:
	for path in [cache_path, "%s.tmp" % cache_path, "%s.bak" % cache_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
