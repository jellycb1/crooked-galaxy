extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_backup_%s.json" % OS.get_process_id()


func _init() -> void:
	var source = StateScript.new()
	source.save_path = test_save
	source.player = source.default_player()
	source.phase = source.Phase.REWARD
	source.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	source.pending_loot = {"id": "atomic_backup_loot", "name": "Recibo Blindado", "slot": "weapon", "power": 3, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"}
	check(source.save_game(), "reward state creates its primary save")
	var credits_before := int(source.player.credits)
	var claim := source.claim_reward(false)
	check(not claim.is_empty() and source.phase == source.Phase.BOARD, "reward transaction commits before corruption fixture")
	var claimed_credits := int(source.player.credits)
	var claimed_inventory: int = source.player.inventory.size()
	var backup := read_payload("%s.bak" % test_save)
	check(not backup.is_empty() and int(backup.phase) == source.Phase.BOARD, "backup mirrors the latest committed phase")
	check(backup.pending_loot is Dictionary and backup.pending_loot.is_empty(), "backup mirrors consumed pending loot")
	check(int(backup.player.credits) == claimed_credits and int(backup.player.captures_by_target.gloop) == 1, "backup mirrors the complete claimed transaction")

	var corrupt := FileAccess.open(test_save, FileAccess.WRITE)
	corrupt.store_string("{ interrupted replacement")
	corrupt = null
	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	check(restored.last_notice_context == "system_recovery" and restored.last_notice.contains("cópia íntegra"), "corrupt primary restores the last known good copy visibly")
	check(restored.phase == restored.Phase.BOARD and restored.pending_loot.is_empty(), "backup recovery cannot resurrect the reward decision")
	check(int(restored.player.credits) == claimed_credits and restored.player.inventory.size() == claimed_inventory, "backup recovery preserves the exact claimed wallet and inventory")
	check(int(restored.player.credits) > credits_before and int(restored.player.captures_by_target.gloop) == 1, "backup recovery preserves applied capture progression")
	var recovered_credits := int(restored.player.credits)
	check(restored.claim_reward(false).is_empty() and int(restored.player.credits) == recovered_credits, "recovered transaction rejects a duplicate reward claim")

	var immediate = StateScript.new()
	immediate.save_path = test_save
	immediate.load_game()
	check(immediate.last_notice_context != "system_recovery", "recovered primary is rewritten cleanly for the next launch")
	check(int(immediate.player.credits) == claimed_credits and immediate.pending_loot.is_empty(), "second launch repeats neither recovery nor reward")
	immediate.free()
	restored.free()
	source.free()
	cleanup_save_family()

	if failures == 0:
		print("PASS: crash-safe backup recovery cannot duplicate reward transactions")
		quit(0)
	else:
		printerr("FAIL: %d save backup issue(s)" % failures)
		quit(1)


func read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func cleanup_save_family() -> void:
	for path in [test_save, "%s.tmp" % test_save, "%s.bak" % test_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
