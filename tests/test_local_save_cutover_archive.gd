extends SceneTree

const CutoverArchive = preload("res://scripts/local_save_cutover_archive.gd")

var failures := 0


func _init() -> void:
	var run_id := "%d" % OS.get_process_id()
	var save_path := "res://.godot/cutover_%s.json" % run_id
	var archive_root := "res://.godot/cutover_archives_%s" % run_id
	cleanup(save_path, archive_root)
	write_file(save_path, '{"version":26,"player":{"level":8}}')
	write_file("%s.tmp" % save_path, '{"interrupted":true}')
	write_file("%s.bak" % save_path, '{"version":26,"player":{"level":7}}')
	var original_hashes := {
		"primary": FileAccess.get_sha256(save_path),
		"staging": FileAccess.get_sha256("%s.tmp" % save_path),
		"backup": FileAccess.get_sha256("%s.bak" % save_path),
	}
	var result := CutoverArchive.create(save_path, 2000000000123, archive_root)
	check(not result.is_empty(), "complete local save family creates one archival bundle")
	var archive_path := str(result.get("archive_path", ""))
	var manifest: Dictionary = result.get("manifest", {})
	check(str(manifest.get("authority", "")) == "local_archive_only" and not bool(manifest.get("may_seed_server_progress", true)), "archive manifest can never claim server authority")
	check(manifest.get("files", []).size() == 3 and FileAccess.file_exists("%s/manifest.json" % archive_path), "manifest finalizes only after all three save-family members")
	for role in ["primary", "staging", "backup"]:
		check(FileAccess.get_sha256("%s/%s.json" % [archive_path, role]) == str(original_hashes[role]), "%s archive copy preserves its exact SHA-256" % role)
	check(FileAccess.file_exists(save_path) and FileAccess.file_exists("%s.tmp" % save_path) and FileAccess.file_exists("%s.bak" % save_path), "archival never deletes active save files before remote confirmation")
	check(CutoverArchive.create(save_path, 2000000000123, archive_root).is_empty(), "an existing archive identity cannot be overwritten")
	check(CutoverArchive.create("res://.godot/missing_cutover_%s.json" % run_id, 2000000000999, archive_root).is_empty(), "missing primary save cannot produce a misleading archive")
	cleanup(save_path, archive_root)

	if failures == 0:
		print("PASS: online cutover archives and verifies the complete local save family without deleting it")
		quit(0)
	else:
		printerr("FAIL: %d local cutover archive issue(s)" % failures)
		quit(1)


func write_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file = null


func cleanup(save_path: String, archive_root: String) -> void:
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var archive_path := "%s/offline-2000000000123" % archive_root
	for file_name in ["primary.json", "staging.json", "backup.json", "manifest.json", "manifest.json.partial"]:
		var path := "%s/%s" % [archive_path, file_name]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_root))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
