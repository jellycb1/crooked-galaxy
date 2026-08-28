extends SceneTree

const UIDesignSystem = preload("res://scripts/ui_design_system.gd")

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
	state.account = {"mode": "local_test", "session_id": "mobile_audit", "locale_id": "en", "server_id": "international_1"}
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
	check((scene.find_child("PrimaryNav_contracts", true, false) as Button).text == "WARRANTS" and (scene.find_child("PrimaryNav_hunter", true, false) as Button).text == "CLASS" and find_label_with_text(scene, "LEVEL 1") != null and find_label_with_text(scene, "CREDITS") != null and find_label_with_text(scene, "WINS") != null and find_label_with_text(scene, "INTERNAL PLACEHOLDER · REPLACE") == null, "English catalog covers persistent header resources and the reference-free primary navigation")
	(scene.find_child("PrimaryNav_menu", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "FRONTIER MENU") != null and find_label_with_text(scene, "MARKET") != null and find_label_with_text(scene, "LICENSED FLYING JUNKBOX") != null and find_label_with_text(scene, "CURRENT POSITION") != null, "English catalog covers the complete Frontier Menu and localized current transport")
	check(find_label_with_text(scene, "UNLOCKS AT LEVEL %d" % ChallengeRules.UNLOCK_LEVEL) != null, "Frontier Menu reports the canonical level-based Rift gate")
	(scene.find_child("BoardSettingsAction", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "SETTINGS") != null and find_label_with_text(scene, "GAME EXPERIENCE") != null and find_label_with_text(scene, "AUDIO") != null and (scene.find_child("SoundPreferenceAction", true, false) as Button).text == "ON" and (scene.find_child("ResetProgressAction", true, false) as Button).text == "RESET LOCAL PROGRESS", "English catalog covers device preferences and the explicit local-test reset")
	check(find_label_with_text(scene, "ACCOUNT AND SERVER") != null and find_label_with_text(scene, "LOCAL TEST PROFILE") != null and find_label_with_text(scene, "INTERNATIONAL 1 · THIS DEVICE") != null and find_label_with_text(scene, "NO REMOTE CONFLICTS") != null, "Settings exposes honest account authority, shard scope, and local-only revision state")
	var player_before_english_commerce: Dictionary = state.player.duplicate(true)
	state.player.credits = 20000
	state.player.completed_planets = ["dustball_prime"]
	state.player.level = 4
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
	var cloned_taxi_selector := scene.find_child("HangarSelect_cloned_warp_taxi", true, false) as Button
	if cloned_taxi_selector != null:
		cloned_taxi_selector.pressed.emit()
	await process_frame
	var cloned_taxi_action := scene.find_child("HangarAction_cloned_warp_taxi", true, false) as Button
	check(cloned_taxi_action != null and cloned_taxi_action.text.begins_with("BUY"), "English hangar exposes an unlocked transport purchase")
	if cloned_taxi_action != null:
		cloned_taxi_action.pressed.emit()
	await process_frame
	check(state.last_notice.begins_with("Hangar: CLONED WARP TAXI bought") and find_label_with_text(scene, state.last_notice) != null, "English hangar purchase keeps the active-transport receipt visible")
	state.player = player_before_english_commerce
	state.last_notice = ""
	state.last_notice_context = ""
	var player_before_english_career: Dictionary = state.player.duplicate(true)
	state.player.wins = 7
	state.player.level = 4
	state.player.xp = 55
	state.player.completed_planets = ["dustball_prime"]
	state.player.captures_by_planet = {"dustball_prime": 7}
	state.player.captures_by_target = {"gloop": 3, "mirage_moxie": 2}
	state.player.afk_credits_earned = 240
	state.player.afk_scrap_earned = 6
	scene.view_mode = "career"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "HUNTER CAREER") != null and find_label_with_text(scene, "LEVEL 4 HUNTER") != null and find_label_with_text(scene, "7 CAPTURES · 2/15 KNOWN WORLDS") != null and find_label_with_text(scene, "NEXT LEVEL") != null and (scene.find_child("CareerProgressJump", true, false) as Button).text == "PROGRESS" and (scene.find_child("CareerArchiveJump", true, false) as Button).text == "WANTED · 60", "English career covers hunter progression, XP, discovered worlds, and section navigation")
	check(find_label_with_text(scene, "NEXT MASTERY · GLOOP THE INCONVENIENT") != null and find_label_with_text(scene, "PLANETARY PROGRESS") != null and find_label_with_text(scene, "CLANDESTINE RIFT") != null and find_label_with_text(scene, "FIRST WARRANT") != null, "English career covers mastery direction, planetary ladder, parallel progress, and milestones")
	state.claim_career_milestone("first_warrant")
	await process_frame
	check(state.last_notice.begins_with("Milestone claimed: FIRST WARRANT.") and find_label_with_text(scene, "CAREER RECEIPT") != null and find_label_with_text(scene, state.last_notice) != null, "English career claim uses the localized milestone identity and visible transaction receipt")
	state.afk_report = {"minutes": 480, "credits": 160, "scrap": 8, "capped": true}
	state.last_notice = ""
	state.last_notice_context = ""
	scene.view_mode = "board"
	scene.board_section = "bounties"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "PATROL COMPLETE · 8h 00min") != null and find_label_with_text(scene, "+160 credits · +8 scrap · 8H CAP") != null, "English offline patrol reports duration, rewards, and the settlement cap")
	state.afk_report = {}
	state.player = player_before_english_career
	var player_before_english_galaxy: Dictionary = state.player.duplicate(true)
	state.player.completed_planets = ["dustball_prime"]
	state.player.level = 4
	state.player.captures_by_planet = {"dustball_prime": 7}
	state.player.captures_by_target = {"mirage_moxie": 1}
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "GALACTIC MAP") != null and find_label_with_text(scene, "Known worlds, distances, and incidents in the warrant network.") != null and find_label_with_text(scene, "IN TRANSIT · LICENSED FLYING JUNKBOX") != null and find_label_with_text(scene, "-10% from travel time on every contract") != null and (scene.find_child("GalaxyHangarAction", true, false) as Button).text == "OPEN HANGAR", "English galaxy header covers discovery and active transport timing")
	check(find_label_with_text(scene, "DUSTBALL PRIME") != null and find_label_with_text(scene, "FREEZERIA INC.") != null and find_label_with_text(scene, "MYCELIA 404") != null and find_label_with_text(scene, "BASE ROUTE 5min 00s · 7 RECORDED CAPTURES") != null and find_label_with_text(scene, "ON NETWORK") != null and find_label_with_text(scene, "LOCKED") != null, "English galaxy cards cover localized identity, distance, records, and level discovery")
	state.player = player_before_english_galaxy
	state.last_notice = ""
	state.last_notice_context = ""
	var player_before_english_hunter: Dictionary = state.player.duplicate(true)
	state.player.class_id = "orbit_gunslinger"
	state.player.species_id = "starworn"
	state.player.appearance = {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	state.player.hunter_name = "Nova"
	state.player.stat_points = 2
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "HUNTER") != null and find_label_with_text(scene, "EQUIPMENT · STATS · ATTRIBUTES") != null and find_label_with_text(scene, "STARWORN · LEVEL 1") != null and find_label_with_text(scene, "ORBIT GUNSLINGER") != null and (scene.find_child("HunterTab_attributes", true, false) as Button).text == "ATTRIBUTES", "English catalog covers hunter identity, equipment overview, and the dedicated attribute route")
	(scene.find_child("HunterTab_attributes", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "AVAILABLE POINTS") != null and ["STRENGTH", "VITALITY", "DEXTERITY", "INTELLIGENCE", "CUNNING"].all(func(attribute_name): return find_label_with_text(scene, attribute_name) != null) and find_label_with_text(scene, "UNIVERSAL BONUS") != null, "English attribute section covers spendable points and all five live mechanical effects")
	(scene.find_child("HunterTab_profile", true, false) as Button).pressed.emit()
	await process_frame
	(scene.find_child("ChooseClassAction", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "HUNTER CLASS") != null and find_label_with_text(scene, "INITIAL CLASSES · FREE SWITCHING") != null and find_label_with_text(scene, "WARRANT BREAKER") != null and find_label_with_text(scene, "CONTRACT HACKER") != null and find_label_with_text(scene, "CONTRACT STYLE") != null and (scene.find_child("ConfirmClass", true, false) as Button).text == "CONFIRM CLASS", "English catalog covers the complete three-class comparison and confirmation surface")
	scene.view_mode = "arsenal"
	scene.arsenal_section = "equipped"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "ARSENAL") != null and find_label_with_text(scene, "BUILD AND UPGRADES") != null and find_label_with_text(scene, "UNIVERSAL SHEET") != null and scene.find_child("UniversalSlot_weapon", true, false) != null and scene.find_child("UniversalSlot_armor", true, false) != null and (scene.find_child("ArsenalTab_workshop", true, false) as Button).text == "WORKSHOP", "English equipped arsenal focuses on universal slots while exposing the dedicated workshop")
	(scene.find_child("ArsenalTab_workshop", true, false) as Button).pressed.emit()
	await process_frame
	check(find_label_with_text(scene, "FIELD TEST") != null and scene.find_child("Upgrade_weapon", true, false) != null, "English workshop isolates field guidance and upgrade actions")
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
	state.player.warp_chips = 1
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "WANTED BOARD") != null and find_label_with_text(scene, "FUEL · 100 AVAILABLE") != null and find_label_with_text(scene, "Gloop the Inconvenient") != null and find_label_with_text(scene, "Orbital parking thief") != null and (scene.find_child("BountyAction_gloop", true, false) as Button).text == "ANALYZE APPROACHES", "English catalog covers fuel, the wanted board, target dossier, and primary action")
	(scene.find_child("HuntFuelRefill", true, false) as Button).pressed.emit()
	await process_frame
	check(scene.find_child("HuntFuelRefillConfirm", true, false) != null and int(state.player.hunt_fuel) == 100, "fuel refill requires explicit confirmation before premium spend")
	(scene.find_child("HuntFuelRefillConfirm", true, false) as Button).pressed.emit()
	await process_frame
	check(int(state.player.hunt_fuel) == 120 and int(state.player.warp_chips) == 0 and find_label_with_text(scene, "FUEL · 120 AVAILABLE") != null, "confirmed first refill updates wallet and visible reserve atomically")
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
	var english_ignore := scene.find_child("HuntEventIgnoreAction", true, false) as Button
	var english_abandon := scene.find_child("HuntAbandonAction", true, false) as Button
	var english_choice := scene.find_child("HuntChoice_detour", true, false) as Button
	check(english_ignore != null and english_ignore.text == "IGNORE · CONTINUE ROUTE" and english_ignore.custom_minimum_size.y >= 48.0, "incident exposes a localized touch-safe neutral exit")
	check(english_ignore != null and english_abandon != null and english_choice != null and english_ignore.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION and english_abandon.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION and english_choice.get_theme_font_size("font_size") >= UIDesignSystem.FONT_CAPTION, "incident decisions preserve the Android typography floor")
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
	var board_header := scene.find_child("BountyBoardHeader", true, false) as VBoxContainer
	var board_ledger := scene.find_child("HeaderResourceStrip", true, false) as PanelContainer
	var board_xp := scene.find_child("BoardXpStatus", true, false) as Label
	var safe_right := scene.get_viewport_rect().size.x - float(scene.safe_container.get_theme_constant("margin_right"))
	check(board_header != null and board_header.global_position.x + board_header.size.x <= safe_right + 0.5 and board_ledger != null and board_ledger.size.x <= board_header.size.x, "board identity and resource ledger remain inside the Android safe width")
	check(board_xp != null and board_xp.global_position.x + board_xp.size.x <= safe_right + 0.5, "board XP status remains visible inside the Android safe width")
	check(scene.find_child("BountyScroll", true, false) != null and scene.find_child("BoardHubGrid", true, false) == null, "bounty board opens directly on contracts without competing destination actions")
	check(scene.find_child("BoardTutorialOfferHint", true, false) != null and scene.find_children("BountyCard_*", "PanelContainer", true, false).size() == 1, "fresh mobile hunters see one guided dossier")
	state.player.wins = 1
	scene.render()
	await process_frame
	check(scene.find_children("BoardOfferSelector_*", "Button", true, false).size() == 3 and scene.find_children("BountyCard_*", "PanelContainer", true, false).size() == 1, "established mobile hunters compare three tickets above one dossier")
	check(scene.find_children("BoardOfferTarget_*", "Label", true, false).size() == 3 and scene.find_children("BoardOfferOdds_*", "Label", true, false).size() == 3 and scene.find_children("BoardOfferSummary_*", "Label", true, false).size() == 3, "mobile mission tickets retain target, risk, reward, and time comparison")
	check_touch_targets(scene, "compact mission selector")
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
	check(board_hub_grid != null and board_hub_grid.columns == 2 and board_hub_grid.get_child_count() == 6, "secondary menu groups six game destinations in a balanced two-column mobile grid")
	check(scene.find_children("PrimaryNav_*", "Button", true, false).size() == 5 and scene.find_children("PrimaryNavIcon_*", "Control", true, false).size() == 5, "rapid menu navigation replaces the dock atomically without stale or missing items")
	var updated_contract_icon := scene.find_child("PrimaryNavIcon_contracts", true, false) as Control
	check(updated_contract_icon != null and updated_contract_icon.get_instance_id() == stable_contract_icon_id, "primary navigation updates selection in place instead of rebuilding mobile CanvasItems")
	check(scene.find_children("BoardHubIcon_*", "Control", true, false).size() == 6, "every secondary service has a scalable navigation icon")
	check(scene.find_children("BoardHubTitle_*", "Label", true, false).size() == 6 and scene.find_children("BoardHubDetail_*", "Label", true, false).size() == 6, "secondary services pair readable location names with concise functional descriptions")
	check(scene.find_children("BoardHubTitle_*", "Label", true, false).all(func(hub_title): return (hub_title as Label).get_theme_font_size("font_size") >= 18) and scene.find_children("BoardHubDetail_*", "Label", true, false).all(func(hub_detail): return (hub_detail as Label).get_theme_font_size("font_size") >= 18), "secondary service labels meet the physical Android readability floor")
	var daily_action := scene.find_child("BoardDailyAction", true, false) as Button
	check(daily_action != null and daily_action.custom_minimum_size.y >= 48.0, "daily shift is a first-class mobile destination")
	if daily_action != null:
		daily_action.pressed.emit()
		await process_frame
	check(scene.view_mode == "daily" and scene.find_child("DailyObjectivesScroll", true, false) != null, "daily shift opens as a dedicated scrollable surface")
	check(scene.find_children("DailyObjective_*", "PanelContainer", true, false).size() == 3, "all daily objectives remain reachable in one portrait scroller")
	check(scene.android_back_action() == "menu", "Android Back returns the daily shift to the service menu")
	scene.open_frontier_menu()
	await process_frame
	var settings_action := scene.find_child("BoardSettingsAction", true, false) as Button
	check(settings_action != null, "settings live in the secondary menu instead of the equipment inventory")
	if settings_action != null:
		settings_action.pressed.emit()
		await process_frame
	check(scene.view_mode == "settings" and scene.find_child("SettingsPanel", true, false) != null, "settings open as a dedicated game surface")
	check(["SettingsExperienceDescription", "SettingsAccountDescription", "SettingsAccountRevision", "SoundPreferenceActionDescription", "MotionPreferenceActionDescription"].all(func(node_name):
		var copy := scene.find_child(node_name, true, false) as Label
		return copy != null and copy.get_theme_font_size("font_size") >= 18
	), "settings explanatory text remains readable at the 450x800 Android presentation size")
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
	check(scene.find_child("HeaderWarpChips", true, false) != null, "premium balance remains visible in the persistent resource strip outside the market")
	check(scene.hunt_timer.is_stopped(), "high-frequency hunt refresh stays asleep on the bounty board")
	check(scene.android_back_action() == "quit" and scene.find_child("BountyScroll", true, false) != null, "Android Back exits only from the root contract view")

	scene.view_mode = "arsenal"
	scene.arsenal_section = "collection"
	scene.render()
	await process_frame
	var collection_next := scene.find_child("CollectionPlanetNext", true, false) as Button
	check(collection_next != null and collection_next.custom_minimum_size.y >= 48.0, "series planet navigation preserves a complete mobile touch target")
	scene.arsenal_section = "inventory"
	scene.render()
	await process_frame
	check_touch_targets(scene, "arsenal")
	check(scene.android_back_action() == "board", "Android Back routes secondary hubs to the bounty board")
	scene.handle_android_back_request()
	await process_frame
	check(scene.view_mode == "board" and state.phase == state.Phase.BOARD, "Android Back performs safe hub navigation without exiting")
	state.player.credits = 99999
	state.player.warp_chips = 99
	scene.view_mode = "market"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "planet market")
	check(scene.find_child("MarketScroll", true, false) != null and scene.find_children("MarketOffer_*", "PanelContainer", true, false).size() == 3 and scene.find_children("MarketSelect_*", "Button", true, false).size() == 3, "all three market offers remain directly reachable above the portrait dossier")
	scene.market_scroll_position = 80
	var refresh_market := scene.find_child("MarketRefresh", true, false) as Button
	if refresh_market != null:
		refresh_market.pressed.emit()
		await process_frame
	check(scene.find_child("MarketRefreshConfirmation", true, false) != null and int(state.player.warp_chips) == 99, "first premium-renewal touch opens confirmation without spending")
	var confirm_market_refresh := scene.find_child("MarketRefreshConfirm", true, false) as Button
	if confirm_market_refresh != null:
		confirm_market_refresh.pressed.emit()
		await process_frame
		await process_frame
	check(int(state.player.warp_chips) == 98 and int(state.player.market_refresh_count) == 1, "explicit premium confirmation performs exactly one bounded renewal")
	check(scene.market_scroll_position == 0 and (scene.find_child("MarketScroll", true, false) as ScrollContainer).scroll_vertical == 0, "confirmed stock replacement intentionally returns to its first offer")
	var market_hangar_action := scene.find_child("MarketHangarAction", true, false) as Button
	check(market_hangar_action != null, "market keeps the transport alternative one touch away")
	check(scene.android_back_action() == "menu", "Android Back routes the market to its secondary menu parent")
	if market_hangar_action != null:
		market_hangar_action.pressed.emit()
	await process_frame
	await process_frame
	check(scene.view_mode == "hangar", "market alternative action opens the hangar without returning through the board")
	check_touch_targets(scene, "transport hangar")
	check(scene.find_child("HangarScroll", true, false) != null and scene.find_children("HangarTransport_*", "PanelContainer", true, false).size() == 4 and scene.find_children("HangarSelect_*", "Button", true, false).size() == 4, "all four transports remain directly reachable above the portrait dossier")
	check(scene.find_children("HangarTransportIcon_*", "Control", true, false).size() == 1, "selected hangar silhouette remains visible at the mobile card size")
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
	if inventory_scroll != null:
		inventory_scroll.scroll_vertical = 80
		await process_frame
		var remembered_inventory_position := inventory_scroll.scroll_vertical
		scene.render()
		await process_frame
		await process_frame
		await process_frame
		inventory_scroll = scene.find_child("InventoryScroll", true, false) as ScrollContainer
		check(remembered_inventory_position > 0 and inventory_scroll != null and abs(inventory_scroll.scroll_vertical - remembered_inventory_position) <= 1, "inventory transactions preserve the current page position")
	var next_inventory_page := scene.find_child("InventoryPageNext", true, false) as Button
	check(next_inventory_page != null and next_inventory_page.custom_minimum_size.y >= 48.0, "inventory pager preserves a complete mobile touch target")
	if next_inventory_page != null:
		next_inventory_page.pressed.emit()
		await process_frame
	check(scene.inventory_page == 1 and (scene.find_child("InventoryPageStatus", true, false) as Label).text == "2 / 3", "mobile inventory navigation advances one page without touching the save")
	check((scene.find_child("InventoryScroll", true, false) as ScrollContainer).scroll_vertical == 0, "changing inventory page starts at the first item")

	scene.view_mode = "career"
	scene.render()
	await process_frame
	check_touch_targets(scene, "career navigation")
	scene.career_section = "archive"
	scene.render()
	await process_frame
	check_touch_targets(scene, "career archive planet paging")
	check(scene.find_children("CareerTarget_*", "PanelContainer", true, false).size() == 4, "mobile wanted archive keeps one four-target planet page in memory")
	state.player.completed_planets = ["dustball_prime"]
	state.player.level = maxi(ChallengeRules.UNLOCK_LEVEL, int(state.player.get("level", 1)))
	state.player.challenge_floor = 0
	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "Fenda anomaly dossier")
	check(scene.find_child("ChallengeScroll", true, false) != null and scene.find_child("ChallengeAnomalyRule", true, false) != null, "Fenda anomaly explanation remains reachable in the portrait scroller")
	state.player.challenge_floor = 11
	state.player.rift_reality_progress = {ChallengeRules.FIRST_REALITY_ID: 11}
	scene.render()
	await process_frame
	await process_frame
	check(scene.find_children("ChallengeSector_*", "PanelContainer", true, false).size() == ChallengeRules.REWARD_SECTORS.size(), "late Rift progress stays compact across all four equipment sectors")
	check(scene.find_child("ChallengeCurrentDossier", true, false) != null and scene.find_child("ChallengeEnterAction", true, false) != null, "the twelfth-floor dossier and fixed action remain reachable on Android")
	state.player.challenge_floor = ChallengeRules.STAGES.size()
	state.player.rift_reality_progress = {ChallengeRules.FIRST_REALITY_ID: ChallengeRules.STAGES.size()}
	scene.render()
	await process_frame
	check(scene.find_child("ChallengeCompletePanel", true, false) != null and scene.find_child("ChallengeEnterAction", true, false) == null, "completed twelve-floor Rift has one terminal mobile state")

	state.player.stat_points = 2
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	await process_frame
	check_touch_targets(scene, "hunter profile")
	(scene.find_child("HunterTab_attributes", true, false) as Button).pressed.emit()
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
	var hunt_deadline := int(state.hunt_ends_at)
	check(contract_dock != null and contract_dock.is_visible_in_tree(), "active hunt keeps the primary navigation available")
	check((scene.find_child("PrimaryNavCaption_contracts", true, false) as Label).text == "CAÇADA" and scene.find_child("PrimaryNavBadge_contracts", true, false) != null, "navigation marks the contract destination as an active background hunt")
	check(scene.find_child("HuntTransportIcon", true, false) != null, "active hunt carries the transport silhouette and timing identity")
	check(not scene.hunt_timer.is_stopped(), "hunt refresh wakes only for the timed hunt phase")
	(scene.find_child("PrimaryNav_arsenal", true, false) as Button).pressed.emit()
	await process_frame
	check(state.phase == state.Phase.HUNT and int(state.hunt_ends_at) == hunt_deadline and scene.find_child("ArsenalSectionTabs", true, false) != null, "leaving the hunt opens another game surface without changing its persisted deadline")
	check(not scene.hunt_timer.is_stopped(), "background navigation keeps the wall-clock hunt refresh alive")
	check(scene.android_back_action() == "hunt", "Android Back from a background surface returns to the active hunt")
	scene.handle_android_back_request()
	await process_frame
	check(scene.find_child("HuntTransportIcon", true, false) != null and int(state.hunt_ends_at) == hunt_deadline, "returning to the hunt restores its progress without restarting it")
	check(scene.android_back_action() == "menu", "Android Back minimizes an active timed hunt instead of trapping or abandoning it")
	scene.handle_android_back_request()
	await process_frame
	check(state.phase == state.Phase.HUNT and int(state.hunt_ends_at) == hunt_deadline and scene.find_child("FrontierMenuMarker", true, false) != null, "minimized hunt continues behind the frontier menu")
	(scene.find_child("PrimaryNav_contracts", true, false) as Button).pressed.emit()
	await process_frame
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(not scene.hunt_timer.is_stopped(), "incident keeps the wall-clock hunt refresh active while input remains optional")
	check_touch_targets(scene, "hunt incident")
	var minimize_incident := scene.find_child("HuntMinimizeAction", true, false) as Button
	check(minimize_incident != null, "optional hunt incident has an explicit minimize action")
	minimize_incident.pressed.emit()
	await process_frame
	check(state.phase == state.Phase.HUNT_EVENT and int(state.hunt_ends_at) == hunt_deadline and scene.find_child("FrontierMenuMarker", true, false) != null and contract_dock.is_visible_in_tree(), "incident can remain pending while the player uses the rest of the game")
	(scene.find_child("PrimaryNav_contracts", true, false) as Button).pressed.emit()
	await process_frame
	check(scene.android_back_action() == "ignore_hunt_event", "Android Back closes an optional incident through the same neutral action")

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
