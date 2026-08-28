class_name MonetizationRules
extends RefCounted

const PREMIUM_CURRENCY_ID := "warp_chips"
const MARKET_REFRESH_COSTS := [1, 5, 20]
const MAX_MARKET_REFRESHES_PER_DAY := 3
const FREE_DAILY_HUNT_CHIPS := 1
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
