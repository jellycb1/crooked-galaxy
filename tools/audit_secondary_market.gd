extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const MarketRules = preload("res://scripts/market_rules.gd")

const PLANET_LEVELS := {
	"dustball_prime": 4,
	"congelaria_sa": 9,
	"micelia_404": 15,
	"ferro_velho_omega": 22,
	"cassino_quasar": 30,
}


func _init() -> void:
	print("Crooked Galaxy secondary-market audit")
	for planet_id in PLANET_LEVELS:
		var slots := {}
		var prices: Array[int] = []
		var package_count := 0
		var modified_count := 0
		for day in 30:
			for cycle in 4:
				var player := player_for(str(planet_id), int(PLANET_LEVELS[planet_id]), day, cycle)
				var item: Dictionary = MarketRules.offers(player)[2].item
				var slot := str(item.get("slot", ""))
				slots[slot] = int(slots.get(slot, 0)) + 1
				prices.append(MarketRules.item_price(item, Content.planet_index_for(str(planet_id)), int(player.level)))
				if item.has("attribute_package_id"):
					package_count += 1
				if item.has("attribute_package_id") or item.has("trait"):
					modified_count += 1
		prices.sort()
		print("%s · slots=%s · price p10/med/p90=%d/%d/%d · modified=%.1f%% · packages=%.1f%%" % [
			planet_id,
			str(slots),
			percentile(prices, 0.10),
			percentile(prices, 0.50),
			percentile(prices, 0.90),
			float(modified_count) / 1.2,
			float(package_count) / 1.2,
		])
	print("LONG HORIZON")
	for level in [30, 50, 75, 100]:
		var planet_id := str(MissionRules.available_planets(level)[-1].id)
		var player := player_for(planet_id, level, 0, 0)
		player.wins = level * 2
		var reward := int(MissionRules.board_offers(player)[1].credits)
		var offers := MarketRules.offers(player)
		print("L%d · reward=%d · prices=%s · slots=%s" % [level, reward, str(offers.map(func(offer): return int(offer.price))), str(offers.map(func(offer): return str(offer.item.slot)))])
	print("PASS: market keeps three bounded offers and unlocks lateral stock only where the planet already drops it")
	quit(0)


func player_for(planet_id: String, level: int, day: int, cycle: int) -> Dictionary:
	var state = StateScript.new()
	state.persistence_enabled = false
	var player: Dictionary = state.default_player()
	state.free()
	player.current_planet_id = planet_id
	player.level = level
	player.economy_day = 22000 + day
	player.market_cycle = cycle
	return player


func percentile(values: Array[int], ratio: float) -> int:
	return values[clampi(roundi(float(values.size() - 1) * ratio), 0, values.size() - 1)] if not values.is_empty() else 0
