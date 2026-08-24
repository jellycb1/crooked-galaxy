extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

var failures := 0
var test_save := "res://.godot/crooked_galaxy_afk_persistence_%s.json" % OS.get_process_id()


func _init() -> void:
	audit_boundaries()
	audit_recovery_return()
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	if failures == 0:
		print("PASS: AFK settlement is bounded, monotonic, and atomic")
		quit(0)
	else:
		printerr("FAIL: %d AFK persistence issue(s)" % failures)
		quit(1)


func audit_boundaries() -> void:
	var cases := [
		{"name": "zero", "elapsed": 0.0, "credits": 0, "scrap": 0, "minutes": 0, "capped": false},
		{"name": "below minimum", "elapsed": 299.0, "credits": 0, "scrap": 0, "minutes": 0, "capped": false},
		{"name": "minimum", "elapsed": 300.0, "credits": 15, "scrap": 0, "minutes": 5, "capped": false},
		{"name": "exact cap", "elapsed": 28800.0, "credits": 1440, "scrap": 32, "minutes": 480, "capped": false},
		{"name": "over cap", "elapsed": 28801.0, "credits": 1440, "scrap": 32, "minutes": 480, "capped": true},
	]
	for test_case in cases:
		var state := eligible_state()
		state.player.last_seen_unix = 1000.0
		var result := state.apply_offline_progress(1000.0 + float(test_case.elapsed))
		check(int(result.minutes) == int(test_case.minutes), "%s records exact paid minutes" % str(test_case.name))
		check(int(result.credits) == int(test_case.credits) and int(result.scrap) == int(test_case.scrap), "%s applies exact wallet payout" % str(test_case.name))
		check(bool(result.capped) == bool(test_case.capped), "%s reports cap state exactly" % str(test_case.name))
		check(int(state.player.credits) == int(test_case.credits) and int(state.player.scrap) == int(test_case.scrap), "%s mutates currency exactly once" % str(test_case.name))
		check(int(state.player.afk_credits_earned) == int(test_case.credits) and int(state.player.afk_scrap_earned) == int(test_case.scrap), "%s mutates lifetime totals exactly once" % str(test_case.name))
		var duplicate := state.apply_offline_progress(1000.0 + float(test_case.elapsed))
		check(int(duplicate.credits) == 0 and int(duplicate.scrap) == 0, "%s rejects immediate duplicate settlement" % str(test_case.name))
		check(int(state.player.credits) == int(test_case.credits) and int(state.player.scrap) == int(test_case.scrap), "%s duplicate settlement is side-effect free" % str(test_case.name))
		state.free()

	var rollback := eligible_state()
	rollback.player.last_seen_unix = 2000.0
	var rollback_result := rollback.apply_offline_progress(1000.0)
	check(int(rollback_result.credits) == 0 and int(rollback_result.scrap) == 0, "clock rollback grants no patrol")
	check(float(rollback.player.last_seen_unix) == 2000.0, "clock rollback cannot move the settlement watermark backwards")
	rollback.free()

	var no_wins := eligible_state()
	no_wins.player.wins = 0
	no_wins.player.last_seen_unix = 1000.0
	var locked_result := no_wins.apply_offline_progress(1000.0 + 28801.0)
	check(int(locked_result.credits) == 0 and int(locked_result.scrap) == 0 and no_wins.afk_report.is_empty(), "patrol remains locked before the first capture even beyond the cap")
	no_wins.free()


func audit_recovery_return() -> void:
	var source := eligible_state()
	source.persistence_enabled = true
	source.save_path = test_save
	source.save_game()
	var file := FileAccess.open(test_save, FileAccess.READ)
	var payload = JSON.parse_string(file.get_as_text())
	file = null
	payload.player.last_seen_unix = Time.get_unix_time_from_system() - 3700.0
	payload.player.capture_streak = -1
	file = FileAccess.open(test_save, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file = null
	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	check(not restored.afk_report.is_empty() and int(restored.afk_report.credits) > 0, "eligible repaired return retains its AFK payout")
	check(restored.last_notice_context == "system_recovery", "save recovery remains visible beside the AFK payout")
	var paid_credits := int(restored.player.credits)
	var paid_scrap := int(restored.player.scrap)
	restored.dismiss_afk_report(true)
	check(restored.afk_report.is_empty() and restored.last_notice.is_empty() and restored.last_notice_context.is_empty(), "combined return acknowledgement clears both transient reports")
	var immediate = StateScript.new()
	immediate.save_path = test_save
	immediate.load_game()
	check(int(immediate.player.credits) == paid_credits and int(immediate.player.scrap) == paid_scrap, "repaired AFK payout persists exactly once")
	check(immediate.afk_report.is_empty() and immediate.last_notice_context != "system_recovery", "immediate reload repeats neither payout nor recovery")
	immediate.free()
	restored.free()
	source.free()


func eligible_state() -> StateScript:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.wins = 5
	state.player.completed_planets = ["dustball_prime", "congelaria_sa"]
	state.player.credits = 0
	state.player.scrap = 0
	return state


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
