class_name StagingClientProbe
extends RefCounted

const Adapter = preload("res://scripts/nakama_backend_adapter.gd")
const Coordinator = preload("res://scripts/remote_session_coordinator.gd")


func run(configuration: Dictionary, device_id: String, cache_path: String) -> Dictionary:
	var adapter = Adapter.new()
	var coordinator = Coordinator.new(adapter)
	var connection: Dictionary = await coordinator.connect_explicit_test(configuration, device_id)
	if not bool(connection.get("ok", false)):
		return _failure("authentication_failed")
	var account_id := str(connection.get("account_id", ""))
	var clock: Dictionary = connection.get("clock", {})
	var snapshot: Dictionary = connection.get("snapshot", {})
	if not bool(connection.get("character_exists", false)):
		snapshot = await coordinator.create_explicit_test_character(
			"staging-probe-create-v1",
			"Staging Trace",
			"orbit_gunslinger",
			"synthetic",
			{"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
		)
	if not bool(snapshot.get("ok", false)) or str(snapshot.get("account_id", "")) != account_id:
		return _failure("ownership_failed")
	if int(snapshot.get("revision", -1)) != 0 or not _prove_archival_cutover(coordinator, device_id):
		return _failure("archive_cutover_failed")

	var initial_revision := int(snapshot.get("revision", -1))
	var nonce := str(int(Time.get_unix_time_from_system() * 1000.0))
	var command_id := "staging-probe-commit-%s" % nonce
	var receipt_id := "staging-probe-receipt-%s" % nonce
	var appearance := {"palette": "cool", "eyes": "narrow", "feature": "bold", "marking": "stripe"}
	var commit: Dictionary = await adapter.commit_profile(command_id, receipt_id, initial_revision, "Staging Vector", appearance)
	if not bool(commit.get("ok", false)) or str(commit.get("status", "")) != "accepted":
		return _failure("commit_failed")
	var duplicate: Dictionary = await adapter.commit_profile(command_id, receipt_id, initial_revision, "Staging Vector", appearance)
	if not bool(duplicate.get("ok", false)) or str(duplicate.get("status", "")) != "duplicate":
		return _failure("idempotency_failed")
	var conflict: Dictionary = await adapter.commit_profile(
		"staging-probe-stale-%s" % nonce,
		"staging-probe-stale-receipt-%s" % nonce,
		initial_revision,
		"Staging Vector",
		appearance
	)
	if not bool(conflict.get("ok", false)) or str(conflict.get("status", "")) != "conflict":
		return _failure("conflict_failed")
	var profile_after_commit: Dictionary = await adapter.get_character()
	if not bool(profile_after_commit.get("ok", false)) or int(profile_after_commit.get("revision", -1)) != initial_revision + 1:
		return _failure("authoritative_refetch_failed")
	var hunt_evidence: Dictionary = await _prove_authoritative_hunt(adapter, nonce, int(profile_after_commit.revision))
	if not bool(hunt_evidence.get("ok", false)):
		return hunt_evidence
	var authoritative: Dictionary = await adapter.get_character()
	if not bool(authoritative.get("ok", false)) or int(authoritative.get("revision", -1)) != int(hunt_evidence.get("final_revision", -2)):
		return _failure("post_hunt_profile_refetch_failed")
	if not coordinator.accept_authoritative_snapshot(authoritative):
		return _failure("coordinator_snapshot_failed")

	var cached_at := maxi(int(Time.get_unix_time_from_system() * 1000.0), int(authoritative.get("server_unix_ms", 0)))
	var offline: Dictionary = coordinator.cache_and_disconnect(cache_path, cached_at)
	if not bool(offline.get("read_only", false)) or bool(offline.get("economic_mutations_allowed", true)):
		return _failure("cache_open_failed")

	var reconnect_adapter = Adapter.new()
	var reconnect_coordinator = Coordinator.new(reconnect_adapter)
	var reconnect_connection: Dictionary = await reconnect_coordinator.connect_explicit_test(configuration, device_id)
	var remote: Dictionary = reconnect_connection.get("snapshot", {}) if bool(reconnect_connection.get("ok", false)) else {}
	var reconnect_action := coordinator.reconnect_action(offline, remote)
	coordinator.clear_cache()
	reconnect_coordinator.reset_runtime()
	if reconnect_action != "use_remote_snapshot":
		return _failure("reconnect_failed")
	var evidence := {
		"ok": true,
		"account_id": account_id,
		"revision": int(remote.get("revision", -1)),
		"round_trip_ms": int(clock.get("round_trip_ms", -1)),
		"authenticated_session": true,
		"ownership_verified": true,
		"server_clock_verified": true,
		"snapshot_verified": true,
		"idempotent_commit_verified": true,
		"conflict_recovery_verified": true,
		"read_only_cache_verified": true,
		"reconnect_verified": true,
		"archive_cutover_verified": true,
		"economy_snapshot_verified": true,
		"build_snapshot_verified": true,
		"hunt_board_verified": true,
		"hunt_accept_replay_verified": true,
		"hunt_acceptance_verified": true,
		"hunt_deadline_verified": true,
		"hunt_resolve_replay_verified": true,
		"reward_claim_verified": true,
		"reward_receipt_verified": true,
		"economy_replay_protection_verified": true,
		"inventory_equip_verified": true,
		"equipped_item_protection_verified": true,
		"content_hash": str(hunt_evidence.get("content_hash", "")),
		"hunt_duration_seconds": int(hunt_evidence.get("hunt_duration_seconds", 0)),
	}
	adapter = null
	coordinator = null
	reconnect_adapter = null
	reconnect_coordinator = null
	return evidence


func _prove_authoritative_hunt(adapter, nonce: String, expected_revision: int) -> Dictionary:
	var economy: Dictionary = await adapter.get_economy()
	var build: Dictionary = await adapter.get_build()
	var board: Dictionary = await adapter.get_hunt_board()
	if not bool(economy.get("ok", false)) or not bool(build.get("ok", false)) or not bool(board.get("ok", false)):
		return _failure("authoritative_economy_reads_failed")
	if int(economy.revision) != expected_revision or int(build.revision) != expected_revision or int(board.revision) != expected_revision:
		return _failure("economy_revision_mismatch")
	if board.offers.is_empty():
		return _failure("empty_hunt_board")
	var offer: Dictionary = board.offers[0]
	var approach_id := "quiet_net" if offer.approach_ids.has("quiet_net") else str(offer.approach_ids[0])
	var accept_command := "staging-hunt-accept-%s" % nonce
	var accept_key := "staging-hunt-accept-receipt-%s" % nonce
	var accepted: Dictionary = await adapter.accept_hunt(accept_command, accept_key, expected_revision, str(board.board_id), str(offer.offer_id), str(offer.target_id), approach_id)
	if not _receipt_with_snapshot(accepted, "accepted", expected_revision + 1, "economy"):
		return _failure("hunt_accept_failed")
	var duplicate: Dictionary = await adapter.accept_hunt(accept_command, accept_key, expected_revision, str(board.board_id), str(offer.offer_id), str(offer.target_id), approach_id)
	if not _receipt_with_snapshot(duplicate, "duplicate", expected_revision + 1, "economy"):
		return _failure("hunt_accept_replay_failed")
	var active: Dictionary = accepted.snapshot.economy.active_hunt
	if active.is_empty() or str(active.get("approach_id", "")) != approach_id:
		return _failure("active_hunt_snapshot_failed")
	var hunt_id := str(active.hunt_id)
	var early: Dictionary = await adapter.resolve_hunt("staging-hunt-early-%s" % nonce, "staging-hunt-early-receipt-%s" % nonce, expected_revision + 1, hunt_id)
	if not _receipt_with_snapshot(early, "rejected", expected_revision + 1, "economy") or str(early.get("reason_code", "")) != "hunt_not_ready":
		return _failure("hunt_deadline_not_enforced")
	var resolves_at := int(active.resolves_at_unix_ms)
	var accepted_at := int(active.accepted_at_unix_ms)
	await _wait_until_unix_ms(resolves_at + 750)
	var resolve_command := "staging-hunt-resolve-%s" % nonce
	var resolve_key := "staging-hunt-resolve-receipt-%s" % nonce
	var resolved: Dictionary = await adapter.resolve_hunt(resolve_command, resolve_key, expected_revision + 1, hunt_id)
	if not _receipt_with_snapshot(resolved, "accepted", expected_revision + 2, "economy"):
		return _failure("hunt_resolve_failed")
	var pending: Dictionary = resolved.snapshot.economy.pending_reward
	if pending.is_empty() or str(pending.get("hunt_id", "")) != hunt_id:
		return _failure("starter_hunt_did_not_win")
	var resolve_duplicate: Dictionary = await adapter.resolve_hunt(resolve_command, resolve_key, expected_revision + 1, hunt_id)
	if not _receipt_with_snapshot(resolve_duplicate, "duplicate", expected_revision + 2, "economy"):
		return _failure("hunt_resolve_replay_failed")
	var claim: Dictionary = await adapter.claim_reward("staging-reward-claim-%s" % nonce, "staging-reward-claim-receipt-%s" % nonce,
		expected_revision + 2, hunt_id, str(pending.reward_id), "store")
	if not _receipt_with_snapshot(claim, "accepted", expected_revision + 3, "economy") or not claim.snapshot.economy.pending_reward.is_empty():
		return _failure("reward_claim_failed")
	var rewarded_build: Dictionary = await adapter.get_build()
	if not bool(rewarded_build.get("ok", false)) or int(rewarded_build.revision) != expected_revision + 3 or rewarded_build.build.inventory.size() != 1:
		return _failure("reward_inventory_failed")
	var item_id := str(rewarded_build.build.inventory[0].id)
	var equipped: Dictionary = await adapter.equip_item("staging-equip-%s" % nonce, "staging-equip-receipt-%s" % nonce, expected_revision + 3, item_id)
	if not _receipt_with_snapshot(equipped, "accepted", expected_revision + 4, "build"):
		return _failure("inventory_equip_failed")
	var protected: Dictionary = await adapter.recycle_item("staging-recycle-protected-%s" % nonce, "staging-recycle-protected-receipt-%s" % nonce, expected_revision + 4, item_id)
	if not _receipt_with_snapshot(protected, "rejected", expected_revision + 4, "build") or str(protected.get("reason_code", "")) != "item_equipped":
		return _failure("equipped_item_protection_failed")
	return {"ok": true, "final_revision": expected_revision + 4, "content_hash": str(board.content_hash),
		"hunt_duration_seconds": int(ceil(float(resolves_at - accepted_at) / 1000.0))}


static func _receipt_with_snapshot(receipt: Dictionary, status: String, revision: int, snapshot_kind: String) -> bool:
	if not bool(receipt.get("ok", false)) or str(receipt.get("status", "")) != status or int(receipt.get("server_revision", -1)) != revision:
		return false
	var snapshot = receipt.get("snapshot", null)
	return snapshot is Dictionary and int(snapshot.get("revision", -1)) == revision and snapshot.has(snapshot_kind)


static func _wait_until_unix_ms(deadline_unix_ms: int) -> void:
	while int(Time.get_unix_time_from_system() * 1000.0) < deadline_unix_ms:
		var remaining_ms := deadline_unix_ms - int(Time.get_unix_time_from_system() * 1000.0)
		var wait_seconds := minf(2.0, maxf(0.05, float(remaining_ms) / 1000.0))
		await (Engine.get_main_loop() as SceneTree).create_timer(wait_seconds).timeout


static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error_code": code}


static func _prove_archival_cutover(coordinator, device_id: String) -> bool:
	var local_profile := {"character_id": "offline_hunter", "level": 8, "xp": 420, "wins": 12}
	if coordinator.prepare_local_cutover(local_profile, false) != "archive_local_start_remote_required":
		return false
	var save_path := "user://staging_cutover_%s.json" % device_id
	var archive_root := "user://staging_cutover_archives_%s" % device_id
	_cleanup_cutover(save_path, archive_root)
	var members := {
		save_path: JSON.stringify({"version": 26, "player": local_profile}),
		"%s.tmp" % save_path: JSON.stringify({"interrupted": true, "player": local_profile}),
		"%s.bak" % save_path: JSON.stringify({"version": 26, "player": {"character_id": "offline_hunter", "level": 7}}),
	}
	for path in members:
		var file := FileAccess.open(str(path), FileAccess.WRITE)
		if file == null:
			_cleanup_cutover(save_path, archive_root)
			return false
		file.store_string(str(members[path]))
		file.flush()
		file = null
	var source_hash := FileAccess.get_sha256(save_path)
	var result: Dictionary = coordinator.archive_local_cutover("archive_local_start_remote", save_path, archive_root)
	var manifest: Dictionary = result.get("manifest", {})
	var archive_path := str(result.get("archive_path", ""))
	var valid: bool = not result.is_empty() \
		and str(manifest.get("authority", "")) == "local_archive_only" \
		and not bool(manifest.get("may_seed_server_progress", true)) \
		and manifest.get("files", []).size() == 3 \
		and FileAccess.file_exists(save_path) \
		and FileAccess.get_sha256("%s/primary.json" % archive_path) == source_hash
	_cleanup_cutover(save_path, archive_root, archive_path)
	return valid


static func _cleanup_cutover(save_path: String, archive_root: String, archive_path := "") -> void:
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not archive_path.is_empty():
		for file_name in ["primary.json", "staging.json", "backup.json", "manifest.json", "manifest.json.partial"]:
			var member_path := "%s/%s" % [archive_path, file_name]
			if FileAccess.file_exists(member_path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(member_path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_root))
