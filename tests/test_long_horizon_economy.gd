extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const CoreRulesScript = preload("res://scripts/core_rules.gd")

var failures := 0


func _init() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	var previous_reward := 0
	var previous_stock := 0
	for level in [1, 4, 8, 13, 19, 30, 50, 75, 100]:
		player.level = level
		player.wins = level * 2
		player.current_planet_id = str(MissionRulesScript.available_planets(level)[-1].id)
		var contract: Dictionary = MissionRulesScript.board_offers(player)[1]
		var reward := int(contract.credits)
		var prices: Array = MarketRulesScript.offers(player).map(func(offer): return int(offer.price))
		var cheapest := int(prices.min())
		var ratio := float(reward) / float(maxi(1, cheapest))
		check(reward >= previous_reward and cheapest >= previous_stock, "contract income and catch-up stock stay monotonic at level %d" % level)
		check(ratio >= 0.08 and ratio <= 2.0, "one standard warrant remains between 8%% and 200%% of catch-up stock at level %d" % level)
		check(MarketRulesScript.refresh_cost(player) < cheapest, "refresh remains a meaningful but cheaper alternative to buying stock at level %d" % level)
		previous_reward = reward
		previous_stock = cheapest

	player = state.default_player()
	var acquired_at_win := {}
	for _capture in 200:
		var contract: Dictionary = MissionRulesScript.board_offers(player)[1]
		var payout: Dictionary = CoreRulesScript.bounty_streak_reward(int(contract.credits), int(player.capture_streak) + 1)
		player.credits = int(player.credits) + int(payout.credits)
		player.capture_streak = int(player.capture_streak) + 1
		player.wins = int(player.wins) + 1
		CoreRulesScript.apply_xp(player, int(contract.xp))
		for transport in TransportRulesScript.DEFINITIONS:
			var transport_id := str(transport.id)
			if acquired_at_win.has(transport_id) or int(player.level) < int(transport.required_level) or int(player.credits) < int(transport.price):
				continue
			acquired_at_win[transport_id] = int(player.wins)
			player.credits = int(player.credits) - int(transport.price)
	check(acquired_at_win.size() == TransportRulesScript.DEFINITIONS.size(), "standard progression can buy all four transports without AFK income")
	var latest_transport_win := 0
	for win in acquired_at_win.values():
		latest_transport_win = maxi(latest_transport_win, int(win))
	check(latest_transport_win >= 60 and latest_transport_win <= 100, "the final transport remains a long goal but arrives within the current world-discovery career")
	check(int(player.level) >= 30 and int(player.level) <= 40, "two hundred standard contracts follow the intended quadratic progression")
	check(int(player.credits) < 250000, "level-thirty career wallet remains bounded before retention systems exist")
	var daily_credit_total := 0
	var daily_scrap_total := 0
	for objective in state.daily_objectives():
		daily_credit_total += int(objective.credits)
		daily_scrap_total += int(objective.scrap)
	check(daily_credit_total == 85 and daily_scrap_total == 8, "one complete daily shift has a fixed auditable economic ceiling")
	check(daily_credit_total < int(MarketRulesScript.offers(player)[0].price), "daily credits support progression without replacing late-game contract income")
	state.free()
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: level-100 economy and transport acquisition remain bounded")
		quit(0)
	else:
		printerr("FAIL: %d long-horizon economy issue(s)" % failures)
		quit(1)
