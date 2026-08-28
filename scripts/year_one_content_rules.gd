class_name YearOneContentRules
extends RefCounted

const DAYS := 365
const DAILY_HUNTS := 5
const TOTAL_HUNTS := DAYS * DAILY_HUNTS
const TARGETS_PER_PLANET := 4
const FIRST_REGULAR_EXPANSION_LEVEL := 30
const REGULAR_PLANET_INTERVAL := 10
const PROJECTED_YEAR_END_LEVEL := 302


static func required_unlock_levels() -> Array[int]:
	var levels: Array[int] = [1, 4, 8, 13, 19]
	for level in range(FIRST_REGULAR_EXPANSION_LEVEL, PROJECTED_YEAR_END_LEVEL + 1, REGULAR_PLANET_INTERVAL):
		levels.append(level)
	return levels


static func required_planet_count() -> int:
	return required_unlock_levels().size()


static func required_target_count() -> int:
	return required_planet_count() * TARGETS_PER_PLANET
