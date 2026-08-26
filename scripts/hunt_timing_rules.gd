class_name HuntTimingRules
extends RefCounted


static func interval_is_valid(started_at: float, ends_at: float) -> bool:
	return started_at > 0.0 and ends_at > started_at


static func progress(now: float, started_at: float, ends_at: float) -> float:
	if not interval_is_valid(started_at, ends_at):
		return 0.0
	var duration := maxf(0.1, ends_at - started_at)
	return clampf(1.0 - (ends_at - now) / duration, 0.0, 1.0)


static func remaining(now: float, ends_at: float) -> float:
	return maxf(0.0, ends_at - now)


static func is_complete(now: float, ends_at: float) -> bool:
	return now >= ends_at


static func extend_deadline(ends_at: float, duration_add: float) -> float:
	return ends_at + maxf(0.0, duration_add)


static func repaired_interval(now: float, started_at: float, ends_at: float, fallback_duration: float) -> Dictionary:
	if interval_is_valid(started_at, ends_at):
		if started_at <= now:
			return {"started_at": started_at, "ends_at": ends_at, "repaired": false}
		var saved_duration := maxf(0.1, ends_at - started_at)
		return {"started_at": now, "ends_at": now + saved_duration, "repaired": true}
	var duration := maxf(0.1, fallback_duration)
	return {"started_at": now, "ends_at": now + duration, "repaired": true}
