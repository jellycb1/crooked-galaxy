extends SceneTree

const CoreRules = preload("res://scripts/core_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")
const TransportRules = preload("res://scripts/transport_rules.gd")
const MonetizationRules = preload("res://scripts/monetization_rules.gd")
const YearOne = preload("res://scripts/year_one_content_rules.gd")
const XP_MILESTONES := [4, 8, 13, 19, 30, 50, 100, 200, 300, 320, 500]


func _init() -> void:
	var current_catalog := simulate_until_level(30)
	var launch_catalog := simulate_until_level(YearOne.FINAL_YEAR_ONE_PLANET_LEVEL)
	print("Crooked Galaxy year-one pacing audit · standard offers · no transport")
	print("  current final discovery · level 30 · %d hunts · %.1f route hours" % [int(current_catalog.hunts), float(current_catalog.elapsed_seconds) / 3600.0])
	print("  launch final discovery · level %d · %d hunts · %.1f route hours" % [YearOne.FINAL_YEAR_ONE_PLANET_LEVEL, int(launch_catalog.hunts), float(launch_catalog.elapsed_seconds) / 3600.0])
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
	print("Fuel-limited year · current six-planet catalog")
	for daily_fuel in [MonetizationRules.DAILY_HUNT_FUEL, MonetizationRules.DAILY_HUNT_FUEL + MonetizationRules.HUNT_FUEL_REFILL_AMOUNT * MonetizationRules.MAX_HUNT_FUEL_REFILLS_PER_DAY]:
		for strategy in ["standard", "cheapest"]:
			var fuel_year := simulate_fuel_days(YearOne.DAYS, strategy, daily_fuel)
			print("  fuel %3d · %-8s · %d hunts · %.1f/day · level %d · %.1f fuel/day · L30 D%s · L100 D%s · L300 D%s · L320 D%s · L500 D%s" % [
				daily_fuel,
				strategy,
				int(fuel_year.hunts),
				float(fuel_year.hunts) / float(YearOne.DAYS),
				int(fuel_year.level),
				float(fuel_year.fuel_spent) / float(YearOne.DAYS),
				milestone_day_text(fuel_year, 30),
				milestone_day_text(fuel_year, 100),
				milestone_day_text(fuel_year, 300),
				milestone_day_text(fuel_year, 320),
				milestone_day_text(fuel_year, 500),
			])
	print("Candidate long-tail XP curves · +coefficient × (level-1)^2 XP required")
	for coefficient in [0.05, 0.10, 0.20, 0.40, 0.60, 0.80, 1.00]:
		var free_standard := simulate_fuel_days(YearOne.DAYS, "standard", MonetizationRules.DAILY_HUNT_FUEL, coefficient)
		var free_cheapest := simulate_fuel_days(YearOne.DAYS, "cheapest", MonetizationRules.DAILY_HUNT_FUEL, coefficient)
		var paid_standard := simulate_fuel_days(YearOne.DAYS, "standard", 160, coefficient)
		var paid_cheapest := simulate_fuel_days(YearOne.DAYS, "cheapest", 160, coefficient)
		print("  q=%0.2f · free standard L%d · free cheap L%d · 160 standard L%d · 160 cheap L%d" % [
			coefficient,
			int(free_standard.level),
			int(free_cheapest.level),
			int(paid_standard.level),
			int(paid_cheapest.level),
		])
		if coefficient >= 0.60:
			print("           milestones · free standard 30/%s 100/%s 300/%s · free cheap 30/%s 100/%s 300/%s · 160 standard 30/%s 100/%s 300/%s · 160 cheap 30/%s 100/%s 300/%s" % [
				milestone_day_text(free_standard, 30), milestone_day_text(free_standard, 100), milestone_day_text(free_standard, 300),
				milestone_day_text(free_cheapest, 30), milestone_day_text(free_cheapest, 100), milestone_day_text(free_cheapest, 300),
				milestone_day_text(paid_standard, 30), milestone_day_text(paid_standard, 100), milestone_day_text(paid_standard, 300),
				milestone_day_text(paid_cheapest, 30), milestone_day_text(paid_cheapest, 100), milestone_day_text(paid_cheapest, 300),
			])
		if is_equal_approx(coefficient, 0.80):
			print("           q=0.80 free-standard unlock days · L4/%s L8/%s L13/%s L19/%s L30/%s L50/%s L100/%s L200/%s L300/%s" % [
				milestone_day_text(free_standard, 4), milestone_day_text(free_standard, 8), milestone_day_text(free_standard, 13),
				milestone_day_text(free_standard, 19), milestone_day_text(free_standard, 30), milestone_day_text(free_standard, 50),
				milestone_day_text(free_standard, 100), milestone_day_text(free_standard, 200), milestone_day_text(free_standard, 300),
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


static func simulate_fuel_days(days: int, strategy: String, daily_fuel: int, quadratic_xp_coefficient := -1.0) -> Dictionary:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var hunts := 0
	var fuel_spent := 0
	var milestone_days := {}
	for day_index in maxi(0, days):
		var remaining := maxi(0, daily_fuel)
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
			if quadratic_xp_coefficient < 0.0:
				CoreRules.apply_xp(player, int(selected.xp))
			else:
				apply_projected_xp(player, int(selected.xp), quadratic_xp_coefficient)
			hunts += 1
			for milestone in XP_MILESTONES:
				if int(player.level) >= milestone and not milestone_days.has(milestone):
					milestone_days[milestone] = day_index + 1
	return {"hunts": hunts, "level": int(player.level), "fuel_spent": fuel_spent, "milestone_days": milestone_days}


static func milestone_day_text(result: Dictionary, level: int) -> String:
	return str(result.milestone_days.get(level, "—"))


static func projected_xp_needed(level: int, quadratic_coefficient: float) -> int:
	var offset := maxi(0, level - 1)
	return 80 + offset * 45 + roundi(quadratic_coefficient * float(offset * offset))


static func apply_projected_xp(player: Dictionary, amount: int, quadratic_coefficient: float) -> void:
	player.xp = int(player.get("xp", 0)) + maxi(0, amount)
	while int(player.xp) >= projected_xp_needed(int(player.level), quadratic_coefficient):
		player.xp = int(player.xp) - projected_xp_needed(int(player.level), quadratic_coefficient)
		player.level = int(player.level) + 1
