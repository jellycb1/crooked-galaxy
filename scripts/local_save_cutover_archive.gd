class_name LocalSaveCutoverArchive
extends RefCounted

const ARCHIVE_SCHEMA := 1
const DEFAULT_ARCHIVE_ROOT := "user://offline_save_archives"


static func create(save_path: String, created_at_unix_ms: int, archive_root: String = DEFAULT_ARCHIVE_ROOT) -> Dictionary:
	if save_path.is_empty() or archive_root.is_empty() or created_at_unix_ms <= 0:
		return {}
	var sources: Array[Dictionary] = []
	for entry in [
		{"role": "primary", "path": save_path},
		{"role": "staging", "path": "%s.tmp" % save_path},
		{"role": "backup", "path": "%s.bak" % save_path},
	]:
		if FileAccess.file_exists(str(entry.path)):
			sources.append(entry)
	if sources.is_empty() or not sources.any(func(entry): return str(entry.role) == "primary"):
		return {}

	var archive_id := "offline-%d" % created_at_unix_ms
	var archive_path := "%s/%s" % [archive_root.trim_suffix("/"), archive_id]
	var archive_absolute := ProjectSettings.globalize_path(archive_path)
	if DirAccess.dir_exists_absolute(archive_absolute):
		return {}
	if DirAccess.make_dir_recursive_absolute(archive_absolute) != OK:
		return {}

	var created_paths: Array[String] = []
	var records: Array[Dictionary] = []
	for source in sources:
		var source_path := str(source.path)
		var source_hash := FileAccess.get_sha256(source_path)
		var source_size := FileAccess.get_file_as_bytes(source_path).size()
		if source_hash.is_empty() or source_size <= 0:
			_cleanup_failed_archive(created_paths, archive_absolute)
			return {}
		var file_name := "%s.json" % str(source.role)
		var final_path := "%s/%s" % [archive_path, file_name]
		var partial_path := "%s.partial" % final_path
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(partial_path)) != OK:
			_cleanup_failed_archive(created_paths, archive_absolute)
			return {}
		created_paths.append(partial_path)
		if FileAccess.get_sha256(partial_path) != source_hash:
			_cleanup_failed_archive(created_paths, archive_absolute)
			return {}
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(partial_path), ProjectSettings.globalize_path(final_path)) != OK:
			_cleanup_failed_archive(created_paths, archive_absolute)
			return {}
		created_paths[-1] = final_path
		records.append({"role": str(source.role), "file": file_name, "sha256": source_hash, "bytes": source_size})

	var manifest := {
		"archive_schema": ARCHIVE_SCHEMA,
		"archive_id": archive_id,
		"created_at_unix_ms": created_at_unix_ms,
		"authority": "local_archive_only",
		"may_seed_server_progress": false,
		"files": records,
	}
	var manifest_partial := "%s/manifest.json.partial" % archive_path
	var manifest_path := "%s/manifest.json" % archive_path
	var file := FileAccess.open(manifest_partial, FileAccess.WRITE)
	if file == null:
		_cleanup_failed_archive(created_paths, archive_absolute)
		return {}
	file.store_string(JSON.stringify(manifest))
	file.flush()
	var write_ok := file.get_error() == OK
	file = null
	if not write_ok:
		created_paths.append(manifest_partial)
		_cleanup_failed_archive(created_paths, archive_absolute)
		return {}
	created_paths.append(manifest_partial)
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(manifest_partial), ProjectSettings.globalize_path(manifest_path)) != OK:
		_cleanup_failed_archive(created_paths, archive_absolute)
		return {}
	return {"archive_path": archive_path, "manifest": manifest}


static func _cleanup_failed_archive(paths: Array[String], archive_absolute: String) -> void:
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(archive_absolute)
