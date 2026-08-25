extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_mobile_audit")


func run_mobile_audit() -> void:
	check_android_first_project_profile()
	var state = root.get_node_or_null("GameState")
	if state == null:
		check(false, "autoload is available for mobile audit")
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.player.weapon.origin_planet_id = "dustball_prime"
	state.player.armor.origin_planet_id = "dustball_prime"
	state.player.owned_transport_ids = ["licensed_junkbox"]
	state.player.active_transport_id = "licensed_junkbox"
	state.player.inventory = [
		{"id": "mobile_weapon", "name": "Desatomizador de Bolso", "description": "Desmonta átomos, garantias e conversas constrangedoras.", "slot": "weapon", "power": 4, "rarity": "Raro", "color": "#58d9ff", "origin_planet_id": "dustball_prime"},
		{"id": "mobile_armor", "name": "Casaco Antilaser Usado", "description": "As marcas de queimadura comprovam que já funcionou.", "slot": "armor", "power": 4, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"},
	]
	for index in 28:
		var fixture_slot := "weapon" if index % 2 == 0 else "armor"
		var catalog_item: Dictionary = ContentDB.item_catalog_for("dustball_prime", fixture_slot)[index % 4]
		state.player.inventory.append({"id": "mobile_page_%02d" % index, "name": str(catalog_item.name), "description": str(catalog_item.description), "slot": fixture_slot, "power": index + 2, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"})
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	TranslationServer.set_locale("en")
	scene.render()
	await process_frame
	check((scene.find_child("PrimaryNav_contracts", true, false) as Button).text == "WARRANTS" and (scene.find_child("PrimaryNav_hunter", true, false) as Button).text == "CLASS" and find_label_with_text(scene, "LEVEL 1") != null and find_label_with_text(scene, "CREDITS") != null and find_label_with_text(scene, "WINS") != null and find_label_with_text(scene, "INTERNAL PLACEHOLDER · REPLACE") != null, "English catalog covers persistent header resources, reference watermark, and context-sensitive primary navigation")
	(scene.find_child("PrimaryNav_menu", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "FRONTIER MENU") != null and find_label_with_text(scene, "MARKET") != null and find_label_with_text(scene, "LICENSED FLYING JUNKBOX") != null and find_label_with_text(scene, "CURRENT POSITION") != null, "English catalog covers the complete Frontier Menu and localized current transport")
	(scene.find_child("BoardSettingsAction", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "SETTINGS") != null and find_label_with_text(scene, "GAME EXPERIENCE") != null and find_label_with_text(scene, "AUDIO") != null and (scene.find_child("SoundPreferenceAction", true, false) as Button).text == "ON" and (scene.find_child("ResetProgressAction", true, false) as Button).text == "RESET LOCAL PROGRESS", "English catalog covers device preferences and the explicit local-test reset")
	var player_before_english_commerce: Dictionary = state.player.duplicate(true)
	state.player.credits = 20000
	state.player.completed_planets = ["dustball_prime"]
	scene.view_mode = "market"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "CROOKED MARKET") != null and find_label_with_text(scene, "BALANCE · ◈ 20000 CREDITS") != null and (scene.find_child("MarketRefresh", true, false) as Button).text.begins_with("REFRESH") and (scene.find_child("MarketHangarAction", true, false) as Button).text == "VIEW HANGAR", "English market covers balance, refresh, permanent spending alternative, and navigation")
	var first_market_offer: Dictionary = state.market_offers()[0]
	state.buy_market_offer(str(first_market_offer.id))
	await process_frame
	check(state.last_notice.begins_with("Market:") and state.last_notice.contains("credits and") and find_label_with_text(scene, state.last_notice) != null, "English market purchase localizes item identity and keeps its receipt visible")
	scene.view_mode = "hangar"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "QUESTIONABLE HANGAR") != null and find_label_with_text(scene, "LICENSED FLYING JUNKBOX") != null and find_label_with_text(scene, "The door closes when gravity cooperates.") != null and (scene.find_child("HangarMarketAction", true, false) as Button).text == "VIEW MARKET", "English hangar covers permanent transport identity, tagline, timing, and commerce route")
	var cloned_taxi_action := scene.find_child("HangarAction_cloned_warp_taxi", true, false) as Button
	check(cloned_taxi_action != null and cloned_taxi_action.text.begins_with("BUY"), "English hangar exposes an unlocked transport purchase")
	if cloned_taxi_action != null:
		cloned_taxi_action.pressed.emit()
	await process_frame
	check(state.last_notice.begins_with("Hangar: CLONED WARP TAXI bought") and find_label_with_text(scene, state.last_notice) != null, "English hangar purchase keeps the active-transport receipt visible")
	state.player = player_before_english_commerce
	state.last_notice = ""
	state.last_notice_context = ""
	var player_before_english_galaxy: Dictionary = state.player.duplicate(true)
	state.player.completed_planets = ["dustball_prime"]
	state.player.captures_by_planet = {"dustball_prime": 7}
	state.player.captures_by_target = {"mirage_moxie": 1}
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "GALACTIC MAP") != null and find_label_with_text(scene, "Planets are chapters. Fuel is an accounting opinion.") != null and find_label_with_text(scene, "IN TRANSIT · LICENSED FLYING JUNKBOX") != null and find_label_with_text(scene, "-10% from the base time of every hunt") != null and (scene.find_child("GalaxyHangarAction", true, false) as Button).text == "OPEN HANGAR", "English galaxy header covers navigation and active transport timing")
	check(find_label_with_text(scene, "DUSTBALL PRIME") != null and find_label_with_text(scene, "FREEZERIA INC.") != null and find_label_with_text(scene, "MYCELIA 404") != null and find_label_with_text(scene, "CHAPTER COMPLETE · 7 CAPTURES") != null and find_label_with_text(scene, "IN ORBIT") != null and find_label_with_text(scene, "LOCKED") != null, "English galaxy cards cover localized planet identity, chapter progress, and route state")
	var travel_action := scene.find_child("GalaxyTravel_congelaria_sa", true, false) as Button
	check(travel_action != null and travel_action.text == "TRAVEL", "English galaxy exposes the next unlocked route as a localized action")
	if travel_action != null:
		travel_action.pressed.emit()
	await process_frame
	var expected_travel_notice := "Route confirmed: Freezeria Inc. — fuel will be explained on the invoice."
	check(state.last_notice == expected_travel_notice, "English travel transaction localizes the canonical planet identity (received: %s)" % state.last_notice)
	check(find_label_with_text(scene, expected_travel_notice) != null, "English travel receipt remains visible after returning to the board")
	state.player = player_before_english_galaxy
	state.last_notice = ""
	state.last_notice_context = ""
	var player_before_english_hunter: Dictionary = state.player.duplicate(true)
	state.player.class_id = "orbit_gunslinger"
	state.player.species_id = "nebular_nomad"
	state.player.hunter_name = "Nova"
	state.player.stat_points = 2
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "HUNTER") != null and find_label_with_text(scene, "EQUIPMENT · STATS · ATTRIBUTES") != null and find_label_with_text(scene, "NEBULAR NOMAD · LEVEL 1") != null and find_label_with_text(scene, "ORBIT GUNSLINGER") != null and find_label_with_text(scene, "AVAILABLE POINTS") != null, "English catalog covers hunter identity, equipment overview, and spendable status points")
	check(["STRENGTH", "VITALITY", "DEXTERITY", "INTELLIGENCE", "CUNNING"].all(func(attribute_name): return find_label_with_text(scene, attribute_name) != null) and find_label_with_text(scene, "UNIVERSAL BONUS") != null, "English hunter sheet covers all five attributes and their live mechanical effects")
	(scene.find_child("ChooseClassAction", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "HUNTER CLASS") != null and find_label_with_text(scene, "PROVISIONAL ARCHETYPES · FREE SWITCHING") != null and find_label_with_text(scene, "WARRANT BREAKER") != null and find_label_with_text(scene, "CONTRACT HACKER") != null and find_label_with_text(scene, "CONTRACT STYLE") != null and (scene.find_child("ConfirmClass", true, false) as Button).text == "CONFIRM CLASS", "English catalog covers the complete three-class comparison and confirmation surface")
	scene.view_mode = "arsenal"
	scene.arsenal_section = "equipped"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "ARSENAL") != null and find_label_with_text(scene, "BUILD AND UPGRADES") != null and find_label_with_text(scene, "WORKSHOP") != null and find_label_with_text(scene, "UNIVERSAL SHEET") != null and find_label_with_text(scene, "FIELD TEST") != null and find_label_with_text(scene, "Training Zapper") != null and find_label_with_text(scene, "Questionable Space Jacket") != null, "English equipped arsenal covers starter gear, universal slots, workshop economy, and field-test guidance")
	(scene.find_child("ArsenalTab_inventory", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "BACKPACK · 30 ITEMS") != null and (scene.find_child("InventoryFilter_all", true, false) as Button).text == "ALL" and (scene.find_child("InventorySort", true, false) as Button).text.contains("SORT") and find_label_with_text(scene, "Pocket Deatomizer") != null and find_label_with_text(scene, "COMMON · WEAPON") != null, "English backpack covers catalog identity, rarity, slots, filters, sorting, paging, and item comparison")
	state.equip_from_inventory("mobile_weapon")
	await process_frame
	scene.arsenal_section = "equipped"
	scene.render()
	await process_frame
	check(state.last_notice.begins_with("Pocket Deatomizer equipped.") and find_label_with_text(scene, "WORKSHOP LOG · Pocket Deatomizer equipped.") != null, "English workshop transaction remains localized after equipping an inventory item")
	state.player = player_before_english_hunter
	state.last_notice = ""
	state.last_notice_context = ""
	state.phase = state.Phase.BOARD
	scene.view_mode = "settings"
	scene.render()
	await process_frame
	for target in ContentDB.TARGETS:
		for field in ["NAME", "TITLE", "DESCRIPTION"]:
			var key := "TARGET_%s_%s" % [str(target.id).to_upper(), field]
			check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for approach in ContentDB.contract_approaches():
		for field in ["NAME", "TAG", "DESCRIPTION"]:
			var key := "APPROACH_%s_%s" % [str(approach.id).to_upper(), field]
			check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for event in ContentDB.HUNT_EVENTS:
		for field in ["TITLE", "DESCRIPTION"]:
			var key := "HUNT_EVENT_%s_%s" % [str(event.id).to_upper(), field]
			check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
		for choice in event.get("choices", []):
			for field in ["NAME", "EFFECT_TEXT", "RESULT"]:
				var key := "HUNT_EVENT_%s_CHOICE_%s_%s" % [str(event.id).to_upper(), str(choice.id).to_upper(), field]
				check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for attack_index in ContentDB.PLAYER_ATTACKS.size():
		var key := "COMBAT_PLAYER_ATTACK_%d" % attack_index
		check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for target in ContentDB.TARGETS:
		for attack_index in target.get("attacks", []).size():
			var key := "TARGET_%s_ATTACK_%d" % [str(target.id).to_upper(), attack_index]
			check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for planet in ContentDB.PLANETS:
		for slot in CoreRules.EQUIPMENT_SLOTS:
			var catalog := ContentDB.item_catalog_for(str(planet.id), slot)
			for item_index in catalog.size():
				for field in ["NAME", "DESCRIPTION"]:
					var key := "ITEM_%s_%s_%d_%s" % [str(planet.id).to_upper(), slot.to_upper(), item_index, field]
					check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	for traits in ContentDB.ITEM_TRAITS.values():
		for trait_data in traits:
			for field in ["NAME", "DESCRIPTION"]:
				var key := "ITEM_TRAIT_%s_%s" % [str(trait_data.id).to_upper(), field]
				check(str(TranslationServer.translate(key)) != key, "English catalog resolves %s" % key)
	scene.view_mode = "board"
	scene.board_section = "bounties"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "WANTED BOARD") != null and find_label_with_text(scene, "Gloop the Inconvenient") != null and find_label_with_text(scene, "Orbital parking thief") != null and (scene.find_child("BountyAction_gloop", true, false) as Button).text == "ANALYZE APPROACHES", "English catalog covers the wanted board, target dossier, and primary action")
	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	check(find_label_with_text(scene, "CONTRACT BRIEFING") != null and find_label_with_text(scene, "SILENT NET") != null and find_label_with_text(scene, "Surround the target, shut down the exits, and pretend it was all planned.") != null and (scene.find_child("ChooseApproach_premium_warrant", true, false) as Button).text == "CHOOSE · CORPORATE WARRANT", "English catalog covers all contract briefing decisions")
	state.choose_approach("hot_hatch")
	await process_frame
	check(find_label_with_text(scene, "HUNT IN PROGRESS") != null and find_label_with_text(scene, "HOT HATCH ENTRY") != null and scene.find_child("HuntAbandonAction", true, false) != null and (scene.find_child("HuntAbandonAction", true, false) as Button).text == "ABANDON CONTRACT", "English catalog remains coherent after committing a live hunt")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_elapsed_before_event = 2.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "HUNT INCIDENT") != null and find_label_with_text(scene, "D-7 Drone Toll") != null and find_label_with_text(scene, "The drone reveals weak points: -18% target defense.") != null and (scene.find_child("HuntChoice_detour", true, false) as Button).text == "CHOOSE", "English catalog covers the complete live incident decision")
	(scene.find_child("HuntChoice_detour", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "The detour ended behind the target. For once, a road sign helped.") != null, "English incident result survives the committed choice and resumed hunt")
	state.begin_combat()
	state.combat_step()
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "AUTOMATIC ENCOUNTER") != null and find_label_with_text(scene, "RELATIVE HEALTH") != null and find_label_with_text(scene, "LAST ROUND") != null and (scene.find_child("CombatSpeedAction", true, false) as Button).text == "SPEED · 1×", "English catalog covers automatic combat chrome, live pressure, and round report")
	var action_labels := scene.find_children("*", "Label", true, false).filter(func(candidate): return str((candidate as Label).text).contains("DAMAGE"))
	check(not action_labels.is_empty(), "English combat events localize damage quality and preserve numeric evidence")
	state.enemy_hp = 1
	state.combat_step()
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "WARRANT EXECUTED") != null and find_label_with_text(scene, "TARGET CAPTURED") != null and find_label_with_text(scene, "WARRANT REPORT") != null and (scene.find_child("OpenRewardAction", true, false) as Button).text == "OPEN REWARD", "English catalog covers the complete victory handoff into reward")
	var captured_item: Dictionary = state.pending_loot.duplicate(true)
	var captured_catalog: Array = ContentDB.item_catalog_for(str(captured_item.origin_planet_id), str(captured_item.slot))
	var captured_item_index := -1
	for item_index in captured_catalog.size():
		if str(captured_catalog[item_index].name) == str(captured_item.name):
			captured_item_index = item_index
			break
	var captured_item_key: String = "ITEM_%s_%s_%d_NAME" % [str(captured_item.origin_planet_id).to_upper(), str(captured_item.slot).to_upper(), captured_item_index]
	var captured_item_name: String = str(TranslationServer.translate(captured_item_key))
	var captured_upgrade: bool = CoreRules.is_upgrade_for_player(state.player, captured_item)
	var player_before_reward: Dictionary = state.player.duplicate(true)
	(scene.find_child("OpenRewardAction", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "REWARD CAPTURED") != null and find_label_with_text(scene, captured_item_name) != null and find_label_with_text(scene, "RECEIPT") != null, "English reward identifies the captured catalog item and complete transaction receipt")
	check((scene.find_child("ClaimAndRepeat", true, false) as Button).text == ("EQUIP AND REPEAT" if captured_upgrade else "STORE AND REPEAT") and (scene.find_child("ClaimAndBoard", true, false) as Button).text == ("EQUIP AND RETURN TO BOARD" if captured_upgrade else "STORE AND RETURN TO BOARD"), "English reward exposes clear equip-or-store continuation decisions")
	(scene.find_child("ClaimAndBoard", true, false) as Button).pressed.emit()
	await process_frame
	check(state.phase == state.Phase.BOARD and state.last_notice.begins_with("Contract paid:") and find_label_with_text(scene, "Contract paid:") != null and find_label_with_text(scene, "Contrato pago:") == null, "English transaction remains localized through the return to the wanted board")
	state.player = player_before_reward
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	state.pending_loot = {}
	state.combat_events.clear()
	state.last_notice = ""
	state.last_notice_context = ""
	scene.render()
	await process_frame
	await process_frame
	TranslationServer.set_locale("pt")
	scene.view_mode = "board"
	scene.board_section = "bounties"
	scene.render()
	await process_frame
	check_touch_targets(scene, "bounty board")
	var header_character := scene.find_child("HeaderCharacterAction", true, false) as Button
	check(header_character != null and header_character.size.y >= 48.0, "header character card remains a mobile touch target")
	check(scene.find_child("BountyScroll", true, false) != null and scene.find_child("BoardHubGrid", true, false) == null, "bounty board opens directly on contracts without competing destination actions")
	check(scene.find_children("PrimaryNav_*", "Button", true, false).size() == 5, "board exposes a stable five-destination game navigation dock")
	check(["contracts", "arsenal", "hunter", "galaxy", "menu"].all(func(destination):
		var icon := scene.find_child("PrimaryNavIcon_%s" % destination, true, false) as Control
		return icon != null and icon.is_visible_in_tree() and icon.size.x >= 40.0
	), "all five primary destinations retain visible icon identity")
	var stable_contract_icon := scene.find_child("PrimaryNavIcon_contracts", true, false) as Control
	var stable_contract_icon_id := stable_contract_icon.get_instance_id() if stable_contract_icon != null else 0
	var menu_action := scene.find_child("PrimaryNav_menu", true, false) as Button
	check(menu_action != null and menu_action.size.y >= 48.0, "primary menu remains a mobile touch target")
	if menu_action != null:
		menu_action.pressed.emit()
		await process_frame
	var board_hub_grid := scene.find_child("BoardHubGrid", true, false) as GridContainer
	check(board_hub_grid != null and board_hub_grid.columns == 2 and board_hub_grid.get_child_count() == 5, "secondary menu uses a readable two-column mobile grid for five destinations")
	check(scene.find_children("PrimaryNav_*", "Button", true, false).size() == 5 and scene.find_children("PrimaryNavIcon_*", "Control", true, false).size() == 5, "rapid menu navigation replaces the dock atomically without stale or missing items")
	var updated_contract_icon := scene.find_child("PrimaryNavIcon_contracts", true, false) as Control
	check(updated_contract_icon != null and updated_contract_icon.get_instance_id() == stable_contract_icon_id, "primary navigation updates selection in place instead of rebuilding mobile CanvasItems")
	check(scene.find_children("BoardHubIcon_*", "Control", true, false).size() == 5, "every secondary service has a scalable navigation icon")
	check(scene.find_children("BoardHubTitle_*", "Label", true, false).size() == 5 and scene.find_children("BoardHubDetail_*", "Label", true, false).size() == 5, "secondary services pair readable location names with concise functional descriptions")
	var settings_action := scene.find_child("BoardSettingsAction", true, false) as Button
	check(settings_action != null, "settings live in the secondary menu instead of the equipment inventory")
	if settings_action != null:
		settings_action.pressed.emit()
		await process_frame
	check(scene.view_mode == "settings" and scene.find_child("SettingsPanel", true, false) != null, "settings open as a dedicated game surface")
	check(scene.find_child("ArsenalSectionTabs", true, false) == null, "dedicated settings do not inherit arsenal navigation")
	check(scene.android_back_action() == "menu", "Android Back returns dedicated settings to the service menu")
	scene.open_frontier_menu()
	await process_frame
	check_touch_targets(scene, "frontier menu")
	check(scene.android_back_action() == "board_bounties", "Android Back returns the menu to the primary contract view")
	scene.handle_android_back_request()
	await process_frame
	var build_version := scene.find_child("BuildVersion", true, false) as Label
	check(build_version != null and build_version.text.ends_with("v%s" % str(ProjectSettings.get_setting("application/config/version"))) and build_version.text.contains("INT-1"), "installed build version and active server remain visible in the compact header")
	check(scene.hunt_timer.is_stopped(), "high-frequency hunt refresh stays asleep on the bounty board")
	check(scene.android_back_action() == "quit" and scene.find_child("BountyScroll", true, false) != null, "Android Back exits only from the root contract view")

	scene.view_mode = "arsenal"
	scene.arsenal_section = "inventory"
	scene.render()
	await process_frame
	check_touch_targets(scene, "arsenal")
	check(scene.android_back_action() == "board", "Android Back routes secondary hubs to the bounty board")
	scene.handle_android_back_request()
	await process_frame
	check(scene.view_mode == "board" and state.phase == state.Phase.BOARD, "Android Back performs safe hub navigation without exiting")
	state.player.credits = 99999
	scene.view_mode = "market"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "planet market")
	check(scene.find_child("MarketScroll", true, false) != null and scene.find_children("MarketOffer_*", "PanelContainer", true, false).size() == 3, "all three market offers remain reachable in the portrait scroller")
	var market_hangar_action := scene.find_child("MarketHangarAction", true, false) as Button
	check(market_hangar_action != null, "market keeps the transport alternative one touch away")
	check(scene.android_back_action() == "menu", "Android Back routes the market to its secondary menu parent")
	if market_hangar_action != null:
		market_hangar_action.pressed.emit()
	await process_frame
	await process_frame
	check(scene.view_mode == "hangar", "market alternative action opens the hangar without returning through the board")
	check_touch_targets(scene, "transport hangar")
	check(scene.find_child("HangarScroll", true, false) != null and scene.find_children("HangarTransport_*", "PanelContainer", true, false).size() == 4, "all four transports remain reachable in the portrait scroller")
	check(scene.find_children("HangarTransportIcon_*", "Control", true, false).size() == 4, "hangar silhouettes remain visible at the mobile card size")
	var hangar_market_action := scene.find_child("HangarMarketAction", true, false) as Button
	check(hangar_market_action != null, "hangar keeps the combat alternative one touch away")
	check(scene.android_back_action() == "menu", "Android Back routes the hangar to its secondary menu parent")
	if hangar_market_action != null:
		hangar_market_action.pressed.emit()
	await process_frame
	check(scene.view_mode == "market", "hangar alternative action opens the market without returning through the board")
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check_touch_targets(scene, "transport galaxy status")
	check(scene.find_child("GalaxyTransportIcon", true, false) != null and scene.find_child("GalaxyHangarAction", true, false) != null, "galaxy map carries the active transport identity and hangar route")
	check(scene.find_children("GalaxyPlanetIcon_*", "Control", true, false).size() == ContentDB.PLANETS.size(), "galaxy route icons remain present on the mobile map")
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	await process_frame
	var inventory_scroll := scene.find_child("InventoryScroll", true, false) as ScrollContainer
	check(inventory_scroll != null and inventory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "arsenal disables horizontal scrolling")
	check(inventory_scroll != null and inventory_scroll.size.y >= 48.0, "arsenal reserves a complete touch row for the inventory on mobile (actual %.1f)" % (inventory_scroll.size.y if inventory_scroll != null else -1.0))
	check(scene.find_children("InventoryItem_*", "PanelContainer", true, false).size() == 12, "mobile arsenal instantiates only one bounded inventory page")
	var next_inventory_page := scene.find_child("InventoryPageNext", true, false) as Button
	check(next_inventory_page != null and next_inventory_page.custom_minimum_size.y >= 48.0, "inventory pager preserves a complete mobile touch target")
	if next_inventory_page != null:
		next_inventory_page.pressed.emit()
		await process_frame
	check(scene.inventory_page == 1 and (scene.find_child("InventoryPageStatus", true, false) as Label).text == "2 / 3", "mobile inventory navigation advances one page without touching the save")

	scene.view_mode = "career"
	scene.render()
	await process_frame
	check_touch_targets(scene, "career navigation")
	state.player.completed_planets = ["dustball_prime"]
	state.player.challenge_floor = 0
	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "Fenda anomaly dossier")
	check(scene.find_child("ChallengeScroll", true, false) != null and scene.find_child("ChallengeAnomalyRule", true, false) != null, "Fenda anomaly explanation remains reachable in the portrait scroller")

	state.player.stat_points = 2
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "attributes")
	check(scene.find_child("AttributeScroll", true, false) != null and scene.find_children("AttributeAdd_*", "Button", true, false).size() == 5, "all five attributes remain reachable in the portrait scroller")

	scene.view_mode = "classes"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "class selection")
	check(scene.find_child("ClassSelectorList", true, false) != null and scene.find_children("ClassSelect_*", "Button", true, false).size() == 3, "all initial classes remain directly reachable in the portrait layout")

	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	var contract_dock := scene.find_child("PrimaryNavigationDock", true, false) as Control
	check(contract_dock != null and not contract_dock.is_visible_in_tree(), "contract-owned phases hide the free-navigation dock")
	check_touch_targets(scene, "contract briefing")
	check(scene.find_child("BriefingTransportIcon", true, false) != null, "contract briefing carries the active transport silhouette")
	var briefing_scroll := scene.find_child("BriefingScroll", true, false) as ScrollContainer
	var final_route_action := scene.find_child("ChooseApproach_premium_warrant", true, false) as Button
	check(briefing_scroll != null and final_route_action != null and final_route_action.global_position.y + final_route_action.size.y <= briefing_scroll.global_position.y + briefing_scroll.size.y + 0.5, "all three route decisions fit in the initial mobile briefing viewport")
	check(scene.android_back_action() == "cancel_briefing", "Android Back maps an uncommitted briefing to its safe cancel action")
	scene.handle_android_back_request()
	await process_frame
	check(state.phase == state.Phase.BOARD, "Android Back cancels a briefing before any route is committed")
	state.select_bounty(ContentDB.TARGETS[0])
	await process_frame
	state.choose_approach("quiet_net")
	await process_frame
	check(contract_dock != null and not contract_dock.is_visible_in_tree(), "active hunt keeps the navigation dock unavailable")
	check(scene.find_child("HuntTransportIcon", true, false) != null, "active hunt carries the transport silhouette and timing identity")
	check(not scene.hunt_timer.is_stopped(), "hunt refresh wakes only for the timed hunt phase")
	check(scene.android_back_action() == "guard_contract", "Android Back cannot accidentally abandon an active timed contract")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(scene.hunt_timer.is_stopped(), "hunt refresh sleeps again while an incident awaits input")
	check_touch_targets(scene, "hunt incident")

	state.player = state.default_player()
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	state.pending_loot = {"id": "mobile_first_reward", "name": "Zapper de Bolso", "slot": "weapon", "power": 3, "rarity": "Comum", "color": "#b9c2d9", "origin_planet_id": "dustball_prime"}
	scene.render()
	await process_frame
	check_reward_action_in_viewport(scene, "ClaimAndRepeat", "first reward repeat")
	check_reward_action_in_viewport(scene, "ClaimAndBoard", "first reward board route")

	state.player.captures_by_target = {"gloop": 2}
	state.player.captures_by_planet = {"dustball_prime": 2}
	state.pending_loot = {"id": "mobile_threshold_reward", "name": "Colete de Limiar", "slot": "armor", "power": 5, "rarity": "Raro", "color": "#58d9ff", "origin_planet_id": "dustball_prime"}
	scene.render()
	await process_frame
	check_reward_action_in_viewport(scene, "ClaimAndWorkshop", "combined reward workshop route")
	check_reward_action_in_viewport(scene, "ClaimAndUnlock", "combined reward warrant route")

	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	finish()


func check_android_first_project_profile() -> void:
	check(str(ProjectSettings.get_setting("application/boot_splash/image", "")) == "res://assets/boot_splash.png", "startup uses the original Crooked Galaxy boot splash")
	var splash := load("res://assets/boot_splash.png") as Texture2D
	check(splash != null and splash.get_width() == 720 and splash.get_height() == 1280, "boot splash matches the portrait design canvas")
	check(not bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)), "Godot delegates Android Back to the safe in-game router")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 720, "project keeps the 720-unit portrait design width")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 1280, "project keeps the 1280-unit portrait design height")
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)) == 1, "handheld orientation remains portrait")
	check(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items", "mobile layout uses canvas-items stretching")
	check(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand", "modern tall screens expand beyond the 9:16 minimum instead of letterboxing")
	check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) == "gl_compatibility", "mobile renderer stays on the broad-compatibility path")
	check(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "mobile texture compression remains enabled")


func check_touch_targets(node: Node, context: String) -> void:
	var viewport_width := float((node as Control).size.x)
	for candidate in node.find_children("*", "Button", true, false):
		var button := candidate as Button
		if not button.visible or button.disabled:
			continue
		check(button.size.y >= 40.0, "%s button keeps a 40-unit touch target: %s" % [context, button.name])
		check(button.global_position.x >= -0.5 and button.global_position.x + button.size.x <= viewport_width + 0.5, "%s button stays inside the horizontal viewport: %s" % [context, button.name])


func check_reward_action_in_viewport(scene: Control, node_name: String, context: String) -> void:
	var button := scene.find_child(node_name, true, false) as Button
	check(button != null, "%s exists" % context)
	if button == null:
		return
	check(button.size.y >= 40.0, "%s keeps a 40-unit touch target" % context)
	check(button.global_position.y >= -0.5 and button.global_position.y + button.size.y <= scene.size.y + 0.5, "%s stays inside the vertical viewport" % context)


func finish() -> void:
	if failures == 0:
		print("PASS: mobile safe areas, touch targets, and scrolling are valid")
		quit(0)
	else:
		printerr("FAIL: %d mobile UI issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func find_label_with_text(scene: Node, expected: String) -> Label:
	for candidate in scene.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label.text.contains(expected):
			return label
	return null
