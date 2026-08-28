extends SceneTree

const CoreRules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")
const YearOne = preload("res://scripts/year_one_content_rules.gd")


func _init() -> void:
	var current_catalog := simulate_until_level(30)
	var launch_catalog := simulate_until_level(300)
	print("Crooked Galaxy year-one pacing audit · standard offers · no transport")
	print("  current final discovery · level 30 · %d hunts · %.1f route hours" % [int(current_catalog.hunts), float(current_catalog.elapsed_seconds) / 3600.0])
	print("  launch final discovery · level 300 · %d hunts · %.1f route hours" % [int(launch_catalog.hunts), float(launch_catalog.elapsed_seconds) / 3600.0])
	for daily_hunts in YearOne.PACING_AUDIT_DAILY_HUNTS:
		var year_result := simulate_hunts(YearOne.DAYS * int(daily_hunts))
		print("  %2d/day · current catalog day %3d · launch catalog day %3d · year-end level %d · %.1f route hours/day" % [
			int(daily_hunts),
			YearOne.days_for_hunts(int(current_catalog.hunts), int(daily_hunts)),
			YearOne.days_for_hunts(int(launch_catalog.hunts), int(daily_hunts)),
			int(year_result.level),
			float(year_result.elapsed_seconds) / 3600.0 / float(YearOne.DAYS),
		])
	print("  NOTE · five hunts/day is a reference profile, not an enforced limit")
	print("Fuel-limited year · 100 free units/day · current six-planet catalog")
	for strategy in ["standard", "cheapest"]:
		var fuel_year := simulate_fuel_days(YearOne.DAYS, strategy)
		print("  %-8s · %d hunts · %.1f/day · level %d · %.1f fuel/day" % [
			strategy,
			int(fuel_year.hunts),
			float(fuel_year.hunts) / float(YearOne.DAYS),
			int(fuel_year.level),
			float(fuel_year.fuel_spent) / float(YearOne.DAYS),
		])
	quit(0)


static func simulate_until_level(target_level: int) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var hunts := 0
	var elapsed_seconds := 0.0
	while int(player.level) < target_level:
		var standard: Dictionary = MissionRules.board_offers(player)[1]
		elapsed_seconds += TransportRules.effective_mission_duration(player, standard)
		player.wins = int(player.wins) + 1
		CoreRules.apply_xp(player, int(standard.xp))
		hunts += 1
	return {"hunts": hunts, "level": int(player.level), "elapsed_seconds": elapsed_seconds}


static func simulate_hunts(total_hunts: int) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var elapsed_seconds := 0.0
	for _hunt in maxi(0, total_hunts):
		var standard: Dictionary = MissionRules.board_offers(player)[1]
		elapsed_seconds += TransportRules.effective_mission_duration(player, standard)
		player.wins = int(player.wins) + 1
		CoreRules.apply_xp(player, int(standard.xp))
	return {"hunts": maxi(0, total_hunts), "level": int(player.level), "elapsed_seconds": elapsed_seconds}


static func simulate_fuel_days(days: int, strategy: String) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var hunts := 0
	var fuel_spent := 0
	for _day in maxi(0, days):
		var remaining := MonetizationRules.DAILY_HUNT_FUEL
		while remaining > 0:
			var offers := MissionRules.board_offers(player)
			var selected: Dictionary = {}
			if strategy == "cheapest":
				for offer in offers:
					var cost := MonetizationRules.mission_fuel_cost(offer)
					if cost <= remaining and (selected.is_empty() or cost < MonetizationRules.mission_fuel_cost(selected)):
						selected = offer
			elif offers.size() > 1 and MonetizationRules.mission_fuel_cost(offers[1]) <= remaining:
				selected = offers[1]
			if selected.is_empty():
				break
			var cost := MonetizationRules.mission_fuel_cost(selected)
			remaining -= cost
			fuel_spent += cost
			player.wins = int(player.wins) + 1
			CoreRules.apply_xp(player, int(selected.xp))
			hunts += 1
	return {"hunts": hunts, "level": int(player.level), "fuel_spent": fuel_spent}
