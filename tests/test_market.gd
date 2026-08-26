extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const MarketViewScript = preload("res://scripts/market_view.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const CoreRulesScript = preload("res://scripts/core_rules.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	var original: Dictionary = state.player.duplicate(true)
	var offers := state.market_offers()
	check(offers.size() == MarketRulesScript.OFFER_COUNT, "market always exposes the bounded three-offer board")
	check(offers == MarketRulesScript.offers(state.player), "market stock is deterministic for the same planet, tier, and cycle")
	check(state.player == original, "generating market stock does not mutate player state")
	var offer_ids: Array[String] = []
	var slots: Array[String] = []
	for offer in offers:
		offer_ids.append(str(offer.id))
		slots.append(str(offer.item.slot))
		check(int(offer.price) > 0, "every market offer has a positive price")
	check(offer_ids.duplicate().all(func(id): return offer_ids.count(id) == 1), "market offer ids are unique")
	check(slots.has("weapon") and slots.has("armor"), "every stock cycle includes both equipment slots")
	var first_transport := SpendingGuidanceScript.next_transport_goal(state.player)
	check(str(first_transport.id) == "licensed_junkbox", "spending guidance exposes the first permanent mobility alternative without buying it")
	state.player.owned_transport_ids = ["licensed_junkbox"]
	check(str(SpendingGuidanceScript.next_transport_goal(state.player).id) == "cloned_warp_taxi", "spending guidance advances to the nearest locked transport goal")
	state.player.owned_transport_ids = TransportRulesScript.DEFINITIONS.map(func(entry): return str(entry.id))
	check(SpendingGuidanceScript.next_transport_goal(state.player).is_empty(), "spending guidance recognizes a complete transport collection")
	state.player.owned_transport_ids = []

	state.player.captures_by_target = {"gloop": 3}
	var catchup_offers := state.market_offers()
	check(str(catchup_offers[0].item.origin_planet_id) == "dustball_prime", "market stock stays on the active planet")
	check(str(catchup_offers[0].id).contains("_0_"), "newly unlocked tier sells prior-tier catch-up gear rather than the next warrant reward")

	var chosen: Dictionary = catchup_offers[0]
	var credits_before := int(chosen.price) - 1
	state.player.credits = credits_before
	check(not state.buy_market_offer(str(chosen.id)), "underfunded purchase is rejected")
	check(int(state.player.credits) == credits_before and not state.player.market_purchased_offer_ids.has(str(chosen.id)), "rejected purchase is atomic")
	state.player.credits = int(chosen.price) + 500
	var funded_before := int(state.player.credits)
	check(state.buy_market_offer(str(chosen.id)), "funded purchase succeeds on the board")
	check(int(state.player.credits) == funded_before - int(chosen.price), "purchase removes the exact advertised price")
	check(state.player.market_purchased_offer_ids.has(str(chosen.id)), "purchase is persisted against the deterministic offer id")
	var bought_id := str(chosen.item.id)
	var owns_item := str(state.player.weapon.get("id", "")) == bought_id or str(state.player.armor.get("id", "")) == bought_id
	for item in state.player.inventory:
		owns_item = owns_item or str(item.get("id", "")) == bought_id
	check(owns_item, "purchased equipment is either equipped or stored")
	var credits_after_purchase := int(state.player.credits)
	check(not state.buy_market_offer(str(chosen.id)) and int(state.player.credits) == credits_after_purchase, "the same offer cannot be charged twice")
	var cache_state = StateScript.new()
	cache_state.persistence_enabled = false
	cache_state.player = cache_state.default_player()
	cache_state.player.weapon.power = 999
	cache_state.player.armor.power = 999
	cache_state.player.credits = 99999
	CoreRulesScript.clear_bounty_odds_cache()
	CoreRulesScript.bounty_odds(cache_state.player, ContentDB.TARGETS[0])
	var cached_estimates := CoreRulesScript.bounty_odds_cache.size()
	var stored_offer: Dictionary = cache_state.market_offers()[0]
	check(cache_state.buy_market_offer(str(stored_offer.id)) and CoreRulesScript.bounty_odds_cache.size() == cached_estimates, "a stored market purchase retains unchanged combat estimates for responsive navigation")
	cache_state.free()

	state.phase = state.Phase.HUNT
	check(not state.refresh_market(), "market cannot mutate credits during a contract")
	state.phase = state.Phase.BOARD
	var old_cycle := int(state.player.market_cycle)
	var refresh_cost := MarketRulesScript.refresh_cost(state.player)
	state.player.credits = refresh_cost + 100
	check(state.refresh_market(), "funded stock renewal succeeds on the board")
	check(int(state.player.market_cycle) == old_cycle + 1 and state.player.market_purchased_offer_ids.is_empty(), "renewal advances stock and clears only old purchase marks")
	check(int(state.player.credits) == 100, "renewal charges its exact advertised cost")
	check(str(state.market_offers()[0].id) != str(chosen.id), "renewal produces a distinct deterministic stock cycle")

	var malformed := state.default_player()
	malformed.market_cycle = 999999999
	malformed.market_purchased_offer_ids = ["not_a_market_offer"]
	var repaired: Dictionary = state.sanitize_loaded_player(malformed)
	check(bool(repaired.repaired) and int(repaired.player.market_cycle) == 1000000, "save sanitizer bounds hostile market cycles")
	check(repaired.player.market_purchased_offer_ids.is_empty(), "save sanitizer rejects malformed market purchase records")

	var market_save := "res://.godot/crooked_galaxy_market_test_%s.json" % OS.get_process_id()
	remove_save_family(market_save)
	var persisted = StateScript.new()
	persisted.save_path = market_save
	persisted.player = persisted.default_player()
	persisted.player.credits = 2000
	var persisted_offer: Dictionary = persisted.market_offers()[0]
	var persisted_price := int(persisted_offer.price)
	check(persisted.buy_market_offer(str(persisted_offer.id)), "purchase commits through the normal save transaction")
	var restored = StateScript.new()
	restored.save_path = market_save
	restored.load_game()
	check(int(restored.player.credits) == 2000 - persisted_price and restored.player.market_purchased_offer_ids.has(str(persisted_offer.id)), "forced-close reload preserves wallet and purchased offer together")
	var restored_credits := int(restored.player.credits)
	check(not restored.buy_market_offer(str(persisted_offer.id)) and int(restored.player.credits) == restored_credits, "reloaded purchase record prevents duplicate charging")
	persisted.free()
	restored.free()
	remove_save_family(market_save)

	state.player = state.default_player()
	state.player.credits = 99999
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	MarketViewScript.build(host, content, state)
	check(host.find_child("MarketScroll", true, false) != null, "market renderer provides a portrait-safe scroller")
	check(host.find_children("MarketOffer_*", "PanelContainer", true, false).size() == 3, "market renderer shows exactly one bounded offer cycle")
	check(host.find_children("MarketBuy_*", "Button", true, false).size() == 3, "every offer has a purchase action")
	var refresh := host.find_child("MarketRefresh", true, false) as Button
	check(refresh != null and refresh.custom_minimum_size.y >= 48.0, "renewal action preserves an Android-first touch target")
	var hangar_action := host.find_child("MarketHangarAction", true, false) as Button
	check(hangar_action != null and hangar_action.custom_minimum_size.y >= 48.0, "market exposes a touch-safe route to the permanent transport alternative")
	for button in host.find_children("MarketBuy_*", "Button", true, false):
		check((button as Button).custom_minimum_size.y >= 48.0, "purchase action preserves an Android-first touch target")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: deterministic planet market transactions and UI are valid")
		quit(0)
	else:
		printerr("FAIL: %d market test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func remove_save_family(path: String) -> void:
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		var absolute := ProjectSettings.globalize_path(candidate)
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(absolute)
