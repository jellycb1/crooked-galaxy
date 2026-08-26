extends SceneTree

const Timing = preload("res://scripts/hunt_timing_rules.gd")

var failures := 0


func _init() -> void:
	check(not Timing.interval_is_valid(0.0, 10.0) and not Timing.interval_is_valid(10.0, 10.0), "invalid intervals are rejected")
	check(Timing.interval_is_valid(10.0, 110.0), "positive wall-clock interval is accepted")
	check(is_equal_approx(Timing.progress(60.0, 10.0, 110.0), 0.5), "progress derives only from absolute timestamps")
	check(is_equal_approx(Timing.remaining(60.0, 110.0), 50.0) and Timing.remaining(120.0, 110.0) == 0.0, "remaining time is nonnegative")
	check(not Timing.is_complete(109.9, 110.0) and Timing.is_complete(110.0, 110.0), "deadline completes exactly once it matures")
	check(Timing.extend_deadline(110.0, 12.0) == 122.0 and Timing.extend_deadline(110.0, -12.0) == 110.0, "only explicit positive detours extend the deadline")
	var valid := Timing.repaired_interval(50.0, 10.0, 110.0, 999.0)
	check(not bool(valid.repaired) and float(valid.started_at) == 10.0 and float(valid.ends_at) == 110.0, "valid active deadline survives reconciliation unchanged")
	var future := Timing.repaired_interval(50.0, 80.0, 180.0, 999.0)
	check(bool(future.repaired) and float(future.started_at) == 50.0 and float(future.ends_at) == 150.0, "future clock shift preserves saved duration")
	var invalid := Timing.repaired_interval(50.0, -1.0, -2.0, 300.0)
	check(bool(invalid.repaired) and float(invalid.started_at) == 50.0 and float(invalid.ends_at) == 350.0, "invalid interval restarts from canonical duration")
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: asynchronous hunt timing rules are deterministic")
		quit(0)
	else:
		printerr("FAIL: %d hunt timing issue(s)" % failures)
		quit(1)
