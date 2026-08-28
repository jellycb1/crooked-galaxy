class_name YearOneContentRules
extends RefCounted

const DAYS := 365
const DAILY_HUNTS := 5
const TOTAL_HUNTS := DAYS * DAILY_HUNTS
const TARGETS_PER_PLANET := 4
const FIRST_REGULAR_EXPANSION_LEVEL := 30
const REGULAR_PLANET_INTERVAL := 10
const REFERENCE_YEAR_END_LEVEL := 140
const PROJECTED_MAX_YEAR_END_LEVEL := 323
const FINAL_YEAR_ONE_PLANET_LEVEL := 320
const PACING_AUDIT_DAILY_HUNTS := [5, 10, 20, 40]


static func required_unlock_levels() -> Array[int]:
	var levels: Array[int] = [1, 4, 8, 13, 19]
	for level in range(FIRST_REGULAR_EXPANSION_LEVEL, FINAL_YEAR_ONE_PLANET_LEVEL + 1, REGULAR_PLANET_INTERVAL):
		levels.append(level)
	return levels


static func required_planet_count() -> int:
	return required_unlock_levels().size()


static func required_target_count() -> int:
	return required_planet_count() * TARGETS_PER_PLANET


static func days_for_hunts(total_hunts: int, daily_hunts: int) -> int:
	if total_hunts <= 0:
		return 0
	return ceili(float(total_hunts) / float(maxi(1, daily_hunts)))
