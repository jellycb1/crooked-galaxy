class_name SpendingGuidance
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")


static func next_transport_goal(player: Dictionary) -> Dictionary:
	var locked_fallback: Dictionary = {}
	for transport in TransportRulesScript.DEFINITIONS:
		var transport_id := str(transport.id)
		if TransportRulesScript.is_owned(player, transport_id):
			continue
		if TransportRulesScript.is_unlocked(player, transport):
			return transport.duplicate(true)
		if locked_fallback.is_empty():
			locked_fallback = transport.duplicate(true)
	return locked_fallback


static func market_upgrade_summary(player: Dictionary, offers: Array[Dictionary]) -> Dictionary:
	var upgrade_count := 0
	var cheapest_price := 0
	for offer in offers:
		if bool(offer.get("purchased", false)):
			continue
		var item: Dictionary = offer.get("item", {})
		if item.is_empty() or not CoreRules.is_upgrade_for_player(player, item):
			continue
		var price := maxi(0, int(offer.get("price", 0)))
		upgrade_count += 1
		if cheapest_price == 0 or price < cheapest_price:
			cheapest_price = price
	return {
		"count": upgrade_count,
		"cheapest_price": cheapest_price,
	}
