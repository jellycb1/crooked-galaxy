class_name MonetizationRules
extends RefCounted

const PREMIUM_CURRENCY_ID := "warp_chips"
const MARKET_REFRESH_COSTS := [1, 5, 20]
const MAX_MARKET_REFRESHES_PER_DAY := 3
const FREE_DAILY_HUNT_CHIPS := 1
const DAILY_HUNT_FUEL := 100
const HUNT_FUEL_REFILL_AMOUNT := 20
const HUNT_FUEL_REFILL_COSTS := [1, 5, 20]
const MAX_HUNT_FUEL_REFILLS_PER_DAY := 3
const SECONDS_PER_DAY := 86400.0


static func utc_day_id(unix_time := -1.0) -> int:
	var resolved := Time.get_unix_time_from_system() if float(unix_time) < 0.0 else float(unix_time)
	return floori(maxf(0.0, resolved) / SECONDS_PER_DAY)


static func market_refresh_count(player: Dictionary) -> int:
	return clampi(int(player.get("market_refresh_count", player.get("market_cycle", 0))), 0, MAX_MARKET_REFRESHES_PER_DAY)


static func can_refresh_market(player: Dictionary) -> bool:
	return market_refresh_count(player) < MAX_MARKET_REFRESHES_PER_DAY


static func market_refresh_cost(player: Dictionary) -> int:
	var count := market_refresh_count(player)
	return int(MARKET_REFRESH_COSTS[count]) if count < MARKET_REFRESH_COSTS.size() else 0


static func daily_state_is_current(player: Dictionary, unix_time := -1.0) -> bool:
	return int(player.get("economy_day", -1)) == utc_day_id(unix_time)


static func first_hunt_chip_available(player: Dictionary, unix_time := -1.0) -> bool:
	return int(player.get("daily_hunt_chip_day", -1)) != utc_day_id(unix_time)


static func mission_fuel_cost(mission: Dictionary) -> int:
	if not bool(mission.get("mission_offer", false)) or bool(mission.get("challenge", false)):
		return 0
	var base_seconds := maxf(0.0, float(mission.get("base_travel_duration", mission.get("travel_duration", 0.0))))
	# Every unlocked destination must remain playable from the free daily reserve.
	# Long routes retain their real wait, but never become a premium fuel gate.
	return clampi(ceili(base_seconds / 60.0), 1, DAILY_HUNT_FUEL)


static func hunt_fuel_remaining(player: Dictionary) -> int:
	return clampi(int(player.get("hunt_fuel", DAILY_HUNT_FUEL)), 0, maximum_hunt_fuel(player))


static func hunt_fuel_refill_count(player: Dictionary) -> int:
	return clampi(int(player.get("hunt_fuel_refill_count", 0)), 0, MAX_HUNT_FUEL_REFILLS_PER_DAY)


static func maximum_hunt_fuel(player: Dictionary) -> int:
	return DAILY_HUNT_FUEL + hunt_fuel_refill_count(player) * HUNT_FUEL_REFILL_AMOUNT


static func can_start_mission(player: Dictionary, mission: Dictionary) -> bool:
	return hunt_fuel_remaining(player) >= mission_fuel_cost(mission)


static func can_refill_hunt_fuel(player: Dictionary) -> bool:
	return hunt_fuel_refill_count(player) < MAX_HUNT_FUEL_REFILLS_PER_DAY


static func hunt_fuel_refill_cost(player: Dictionary) -> int:
	var count := hunt_fuel_refill_count(player)
	return int(HUNT_FUEL_REFILL_COSTS[count]) if count < HUNT_FUEL_REFILL_COSTS.size() else 0
