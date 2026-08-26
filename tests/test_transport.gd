extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const HangarViewScript = preload("res://scripts/hangar_view.gd")
const SpendingGuidanceScript = preload("res://scripts/spending_guidance.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	check(TransportRulesScript.DEFINITIONS.size() == 4, "hangar exposes the bounded four-transport launch roster")
	check(is_equal_approx(TransportRulesScript.effective_hunt_duration(state.player, 20.0), 20.0), "a hunter without transport keeps the canonical hunt duration")
	check(TransportRulesScript.is_unlocked(state.player, TransportRulesScript.DEFINITIONS[0]), "starter transport is visible before chapter completion")
	check(not TransportRulesScript.is_unlocked(state.player, TransportRulesScript.DEFINITIONS[1]), "second transport remains chapter-gated")
	var default_market_summary := SpendingGuidanceScript.market_upgrade_summary(state.player, state.market_offers())
	check(int(default_market_summary.count) >= 0 and int(default_market_summary.cheapest_price) >= 0, "combat alternative projection is bounded and side-effect free")
	var no_upgrade_summary := SpendingGuidanceScript.market_upgrade_summary(state.player, [{"item": state.player.weapon.duplicate(true), "price": 100, "purchased": false}])
	check(int(no_upgrade_summary.count) == 0 and int(no_upgrade_summary.cheapest_price) == 0, "combat guidance does not advertise equal equipment as an upgrade")

	state.player.credits = 499
	check(not state.acquire_or_equip_transport("licensed_junkbox"), "underfunded transport purchase is rejected")
	check(int(state.player.credits) == 499 and state.player.owned_transport_ids.is_empty(), "rejected purchase leaves wallet and ownership atomic")
	state.player.credits = 500
	check(state.acquire_or_equip_transport("licensed_junkbox"), "funded starter transport purchase succeeds")
	check(int(state.player.credits) == 0 and state.player.owned_transport_ids == ["licensed_junkbox"] and str(state.player.active_transport_id) == "licensed_junkbox", "purchase charges once, records ownership, and equips immediately")
	check(is_equal_approx(TransportRulesScript.effective_hunt_duration(state.player, 20.0), 18.0), "active starter transport removes exactly ten percent from the base hunt")
	var charged_wallet := int(state.player.credits)
	check(state.acquire_or_equip_transport("licensed_junkbox") and int(state.player.credits) == charged_wallet, "equipping an owned transport never charges twice")
	state.phase = state.Phase.HUNT
	check(not state.acquire_or_equip_transport("licensed_junkbox"), "hangar selection cannot mutate an active contract")
	state.phase = state.Phase.BOARD
	state.player.credits = 99999
	check(not state.acquire_or_equip_transport("cloned_warp_taxi"), "locked transport cannot be purchased early")
	state.player.completed_planets = ["dustball_prime"]
	state.player.level = 4
	check(state.acquire_or_equip_transport("cloned_warp_taxi"), "hunter level unlocks the next transport")
	check(is_equal_approx(TransportRulesScript.effective_hunt_duration(state.player, 20.0), 16.0), "equipped warp taxi removes exactly twenty percent")
	state.player.level = 13
	check(state.acquire_or_equip_transport("executive_escape_yacht"), "mature hunter can acquire the fastest transport")
	check(is_equal_approx(TransportRulesScript.effective_hunt_duration(state.player, 20.0), 10.0), "executive yacht removes exactly fifty percent from travel-compatible legacy timers")
	state.acquire_or_equip_transport("cloned_warp_taxi")

	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.current_bounty.duration = 20
	state.start_hunt()
	check(absf((state.hunt_ends_at - state.hunt_started_at) - 16.0) < 0.05, "starting a hunt persists the already-discounted effective interval")
	state.phase = state.Phase.HUNT_EVENT
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_elapsed_before_event = 5.0
	state.hunt_remaining_after_event = 4.0
	var deadline_before_resolution: float = state.hunt_ends_at
	check(state.resolve_hunt_event("detour"), "duration incident resolves during a transported hunt")
	check(absf(state.hunt_ends_at - deadline_before_resolution - 45.0) < 0.05, "incident delay extends the live deadline additively rather than pausing or receiving a second speed discount")

	var malformed := state.default_player()
	malformed.owned_transport_ids = ["licensed_junkbox", "executive_escape_yacht", "licensed_junkbox", "counterfeit_ship"]
	malformed.active_transport_id = "executive_escape_yacht"
	var repaired: Dictionary = state.sanitize_loaded_player(malformed)
	check(bool(repaired.repaired) and repaired.player.owned_transport_ids == ["licensed_junkbox"], "save sanitizer preserves only unique, known, unlocked transport ownership")
	check(str(repaired.player.active_transport_id).is_empty(), "save sanitizer clears an active transport that is not safely owned")

	var transport_save := "res://.godot/crooked_galaxy_transport_test_%s.json" % OS.get_process_id()
	remove_save_family(transport_save)
	var persisted = StateScript.new()
	persisted.save_path = transport_save
	persisted.player = persisted.default_player()
	persisted.player.credits = 700
	check(persisted.acquire_or_equip_transport("licensed_junkbox"), "transport purchase commits through the normal save transaction")
	var restored = StateScript.new()
	restored.save_path = transport_save
	restored.load_game()
	check(int(restored.player.credits) == 200 and restored.player.owned_transport_ids == ["licensed_junkbox"] and str(restored.player.active_transport_id) == "licensed_junkbox", "forced-close reload preserves wallet, ownership, and equipped transport together")
	persisted.free()
	restored.free()
	remove_save_family(transport_save)

	state.phase = state.Phase.BOARD
	state.player = state.default_player()
	state.player.credits = 99999
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	HangarViewScript.build(host, content, state)
	check(host.find_child("HangarScroll", true, false) != null, "hangar renderer provides a portrait-safe scroller")
	check(host.find_children("HangarTransport_*", "PanelContainer", true, false).size() == 4, "hangar renders every launch transport once")
	check(host.find_children("HangarTransportIcon_*", "Control", true, false).size() == 4, "every launch transport renders an original scalable silhouette")
	check(host.find_children("HangarAction_*", "Button", true, false).size() == 4, "every transport owns an explicit transaction action")
	var market_action := host.find_child("HangarMarketAction", true, false) as Button
	check(market_action != null and market_action.custom_minimum_size.y >= 48.0, "hangar exposes a touch-safe route to the combat equipment alternative")
	for button in host.find_children("HangarAction_*", "Button", true, false):
		check((button as Button).custom_minimum_size.y >= 48.0, "transport action preserves an Android-first touch target")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: permanent transport economy, timing, persistence, and UI are valid")
		quit(0)
	else:
		printerr("FAIL: %d transport test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func remove_save_family(path: String) -> void:
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
