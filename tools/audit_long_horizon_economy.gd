extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const CoreRulesScript = preload("res://scripts/core_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")


func _init() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	print("Crooked Galaxy long-horizon economy audit")
	for level in [1, 4, 8, 13, 19, 30, 50, 75, 100]:
		player.level = level
		player.xp = 0
		player.wins = maxi(0, level * 2)
		player.current_planet_id = str(MissionRulesScript.available_planets(level)[-1].id)
		var contract: Dictionary = MissionRulesScript.board_offers(player)[1]
		var payout: Dictionary = CoreRulesScript.bounty_streak_reward(int(contract.credits), 1)
		var offers: Array[Dictionary] = MarketRulesScript.offers(player)
		var prices: Array = offers.map(func(offer): return int(offer.price))
		var cheapest: int = int(prices.min()) if not prices.is_empty() else 0
		var ratio: float = float(payout.credits) / float(maxi(1, cheapest))
		print("  L%d · contract %d cr · cheapest stock %d cr · reward/stock %.2f · refresh %d cr" % [level, int(payout.credits), cheapest, ratio, MarketRulesScript.refresh_cost(player)])
	print("Standard-contract career · buys each transport ASAP, no AFK rewards or streak loss")
	player = state.default_player()
	var wallet := int(player.credits)
	var reported_transports := {}
	for _capture in 200:
		var contract: Dictionary = MissionRulesScript.board_offers(player)[1]
		var payout: Dictionary = CoreRulesScript.bounty_streak_reward(int(contract.credits), int(player.get("capture_streak", 0)) + 1)
		wallet += int(payout.credits)
		player.credits = wallet
		player.capture_streak = int(player.get("capture_streak", 0)) + 1
		player.wins = int(player.wins) + 1
		CoreRulesScript.apply_xp(player, int(contract.xp))
		for transport in TransportRulesScript.DEFINITIONS:
			var transport_id := str(transport.id)
			if reported_transports.has(transport_id) or int(player.level) < int(transport.required_level) or wallet < int(transport.price):
				continue
			reported_transports[transport_id] = true
			wallet -= int(transport.price)
			player.credits = wallet
			print("  %s bought · win %d · level %d · wallet after %d" % [transport_id, int(player.wins), int(player.level), wallet])
	print("  after 200 wins · level %d · wallet %d" % [int(player.level), wallet])
	state.free()
	quit(0)
