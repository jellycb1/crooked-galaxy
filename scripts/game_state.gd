class_name CrookedGameState
extends Node

const SaveMigrationRules = preload("res://scripts/save_migrations.gd")
const CareerRules = preload("res://scripts/career_rules.gd")
const ClassRules = preload("res://scripts/class_rules.gd")
const EnemyProfileRules = preload("res://scripts/enemy_profile_rules.gd")
const SpeciesRulesScript = preload("res://scripts/species_rules.gd")
const AppearanceRulesScript = preload("res://scripts/appearance_rules.gd")
const ServerRulesScript = preload("res://scripts/server_rules.gd")
const LocaleRulesScript = preload("res://scripts/locale_rules.gd")
const MarketRulesScript = preload("res://scripts/market_rules.gd")
const MonetizationRulesScript = preload("res://scripts/monetization_rules.gd")
const EquipmentGenerationRulesScript = preload("res://scripts/equipment_generation_rules.gd")
const CollectionRulesScript = preload("res://scripts/collection_rules.gd")
const DailyObjectiveRulesScript = preload("res://scripts/daily_objective_rules.gd")
const WeeklyOperationRulesScript = preload("res://scripts/weekly_operation_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const ChallengeRulesScript = preload("res://scripts/challenge_rules.gd")
const AccountRulesScript = preload("res://scripts/account_rules.gd")
const AccountServiceScript = preload("res://scripts/account_service.gd")
const HuntTimingRulesScript = preload("res://scripts/hunt_timing_rules.gd")
const AttributePackageRulesScript = preload("res://scripts/attribute_package_rules.gd")

signal changed
signal combat_event(message: String)

enum Phase { BOARD, HUNT, COMBAT, REWARD, VICTORY, BRIEFING, HUNT_EVENT, CHAPTER_COMPLETE }

const SAVE_PATH := "user://crooked_galaxy_save.json"
const SAVE_VERSION := SaveMigrationRules.CURRENT_VERSION
const COMBAT_CHECKPOINT_INTERVAL := 5

var player: Dictionary
var account: Dictionary = {}
var phase: int = Phase.BOARD
var current_bounty: Dictionary = {}
var offered_approaches: Array[Dictionary] = []
var pending_loot: Dictionary = {}
var hunt_started_at := 0.0
var hunt_ends_at := 0.0
var hunt_event: Dictionary = {}
var hunt_event_triggered := false
var hunt_elapsed_before_event := 0.0
var hunt_remaining_after_event := 0.0
var player_hp := 0
var enemy_hp := 0
var combat_round := 0
var combat_events: Array[Dictionary] = []
var combat_summary: Dictionary = {}
var last_combat_won := false
var rng := RandomNumberGenerator.new()
var persistence_enabled := true
var save_path := SAVE_PATH
var last_notice := ""
var last_notice_context := ""
var chapter_completion: Dictionary = {}
var afk_report: Dictionary = {}
var save_warning := ""
var save_recovery_required := false
var onboarding_gate_enabled := false
var mission_ready_feedback_pending := false
var account_service = AccountServiceScript.new()
var _market_offer_cache_key := ""
var _market_offer_cache: Array[Dictionary] = []


func _ready() -> void:
	onboarding_gate_enabled = true
	TranslationServer.set_locale(LocaleRulesScript.DEFAULT_ID)
	rng.randomize()
	if OS.get_cmdline_user_args().has("--smoke-test"):
		persistence_enabled = false
		player = default_player()
		return
	load_game()


func default_player() -> Dictionary:
	var today := MonetizationRulesScript.utc_day_id()
	return {
		"character_id": "",
		"class_id": "",
		"species_id": "",
		"appearance": {},
		"hunter_name": "",
		"level": 1,
		"xp": 0,
		"credits": 25,
		"warp_chips": 0,
		"scrap": 0,
		"scrap_recycled_total": 0,
		"afk_credits_earned": 0,
		"afk_scrap_earned": 0,
		"claimed_milestones": [],
		"career_credits_claimed": 0,
		"career_scrap_claimed": 0,
		"capture_streak": 0,
		"best_capture_streak": 0,
		"market_cycle": 0,
		"market_refresh_count": 0,
		"economy_day": today,
		"hunt_fuel": MonetizationRulesScript.DAILY_HUNT_FUEL,
		"hunt_fuel_refill_count": 0,
		"daily_hunt_chip_day": -1,
		"discovered_item_variant_ids": [],
		"claimed_collection_milestones": [],
		"daily_hunts_completed": 0,
		"claimed_daily_objectives": [],
		"weekly_cycle_id": WeeklyOperationRulesScript.utc_week_id(),
		"weekly_hunts_completed": 0,
		"claimed_weekly_objectives": [],
		"weekly_special_target_id": "",
		"weekly_special_completed": false,
		"weekly_route_planet_ids": [],
		"weekly_route_captures": {},
		"weekly_route_claimed": false,
		"market_purchased_offer_ids": [],
		"owned_transport_ids": [],
		"active_transport_id": "",
		"locked_item_ids": [],
		"equipment_loadouts": [default_loadout(), default_loadout()],
		"last_seen_unix": Time.get_unix_time_from_system(),
		"reputation": 0,
		"wins": 0,
		"challenge_floor": 0,
		"rift_reality_keys": [],
		"rift_reality_progress": {},
		"selected_rift_reality_id": ChallengeRulesScript.FIRST_REALITY_ID,
		"rift_entry_day": -1,
		"rift_key_hunt_progress": {},
		"base_power": 10,
		"attributes": CoreRules.default_attributes(),
		"stat_points": 0,
		"sound_enabled": true,
		"reduced_motion": false,
		"captures_by_target": {},
		"captures_by_planet": {},
		"completed_planets": [],
		"seen_planet_ids": ["dustball_prime"],
		"current_planet_id": "dustball_prime",
		"weapon": {"id": "starter_weapon", "name": "Zapper de Treino", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"helmet": {},
		"armor": {"id": "starter_armor", "name": "Jaqueta Espacial Duvidosa", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"gloves": {},
		"boots": {},
		"rig": {},
		"implant": {},
		"gadget": {},
		"relic": {},
		"inventory": [],
	}


func onboarding_step() -> String:
	if not account_session_ready():
		return "login"
	var class_id := str(player.get("class_id", ""))
	if class_id.is_empty() or not ClassRules.is_valid(class_id):
		return "class"
	if not SpeciesRulesScript.is_valid(str(player.get("species_id", ""))):
		return "species"
	if not AppearanceRulesScript.is_complete(player.get("appearance", {})):
		return "appearance"
	if normalized_hunter_name(str(player.get("hunter_name", ""))).is_empty():
		return "name"
	return "complete"


func requires_onboarding() -> bool:
	# Isolated tests and capture fixtures disable persistence deliberately and
	# construct partial profiles. Production sessions always keep the gate active.
	return onboarding_gate_enabled and persistence_enabled and onboarding_step() != "complete"


func account_session_ready() -> bool:
	var server_id := str(account.get("server_id", ""))
	var locale_id := str(account.get("locale_id", ""))
	return account_service.session_ready(account) and ServerRulesScript.is_valid(server_id) and LocaleRulesScript.is_selectable(locale_id)


func begin_local_session(locale_id := LocaleRulesScript.DEFAULT_ID, server_id := ServerRulesScript.DEFAULT_ID) -> bool:
	if account_session_ready():
		return true
	if not LocaleRulesScript.is_selectable(str(locale_id)) or not ServerRulesScript.is_valid(str(server_id)):
		return false
	if str(player.get("character_id", "")).is_empty():
		player.character_id = AccountRulesScript.LOCAL_CHARACTER_ID
	account = account_service.create_session(str(locale_id), str(server_id), str(player.character_id))
	TranslationServer.set_locale(str(locale_id))
	last_notice = LocaleRulesScript.text("ONB_NOTICE_SESSION", "Sessão local iniciada em %s. Nenhuma conexão online foi simulada.", [ServerRulesScript.server_name_for(str(server_id))])
	last_notice_context = "onboarding"
	var saved := save_game()
	changed.emit()
	return saved


func set_locale(locale_id: String) -> bool:
	if not account_session_ready() or not LocaleRulesScript.is_selectable(locale_id):
		return false
	account.locale_id = locale_id
	TranslationServer.set_locale(locale_id)
	last_notice = LocaleRulesScript.text("SETTINGS_LANGUAGE_NOTICE", "Idioma alterado para %s.", [LocaleRulesScript.locale_name_for(locale_id)])
	last_notice_context = "settings"
	var saved := save_game()
	changed.emit()
	return saved


func select_species(species_id: String) -> bool:
	var class_id := str(player.get("class_id", ""))
	if not account_session_ready() or class_id.is_empty() or not ClassRules.is_valid(class_id) or not SpeciesRulesScript.is_valid(species_id):
		return false
	player.species_id = species_id
	player.appearance = {}
	last_notice = LocaleRulesScript.text("ONB_NOTICE_SPECIES", "Raça confirmada: %s.", [SpeciesRulesScript.species_name_for(species_id)])
	last_notice_context = "onboarding"
	var saved := save_game()
	changed.emit()
	return saved


func confirm_appearance(appearance: Dictionary) -> bool:
	if not SpeciesRulesScript.is_valid(str(player.get("species_id", ""))) or not AppearanceRulesScript.is_complete(appearance):
		return false
	player.appearance = AppearanceRulesScript.sanitize(appearance)
	last_notice = LocaleRulesScript.text("ONB_NOTICE_APPEARANCE", "Aparência confirmada.")
	last_notice_context = "onboarding"
	var saved := save_game()
	changed.emit()
	return saved


func normalized_hunter_name(raw_name: String) -> String:
	var clean := raw_name.strip_edges()
	while clean.contains("  "):
		clean = clean.replace("  ", " ")
	if clean.length() < 3 or clean.length() > 20:
		return ""
	for index in clean.length():
		var codepoint := clean.unicode_at(index)
		if codepoint < 32 or clean[index] == "<" or clean[index] == ">":
			return ""
	return clean


func set_hunter_name(raw_name: String) -> bool:
	if not SpeciesRulesScript.is_valid(str(player.get("species_id", ""))) or not AppearanceRulesScript.is_complete(player.get("appearance", {})):
		return false
	var clean := normalized_hunter_name(raw_name)
	if clean.is_empty():
		return false
	player.hunter_name = clean
	last_notice = LocaleRulesScript.text("ONB_NOTICE_NAME", "Caçador registrado: %s.", [clean])
	last_notice_context = "onboarding_complete"
	var saved := save_game()
	changed.emit()
	return saved


func reopen_onboarding_choice(choice: String) -> bool:
	if onboarding_step() != "name":
		return false
	match choice:
		"class":
			player.class_id = ""
		"species":
			player.species_id = ""
			player.appearance = {}
		"appearance":
			player.appearance = {}
		_:
			return false
	var notice_key := {"class": "ONB_NOTICE_REOPEN_CLASS", "species": "ONB_NOTICE_REOPEN_SPECIES", "appearance": "ONB_NOTICE_REOPEN_APPEARANCE"}.get(choice, "ONB_NOTICE_REOPEN_SPECIES") as String
	var notice_fallback := {"class": "Registro reaberto para corrigir a classe.", "species": "Registro reaberto para corrigir a raça.", "appearance": "Registro reaberto para corrigir a aparência."}.get(choice, "Registro reaberto.") as String
	last_notice = LocaleRulesScript.text(notice_key, notice_fallback)
	last_notice_context = "onboarding"
	var saved := save_game()
	changed.emit()
	return saved


func default_loadout() -> Dictionary:
	var loadout := {}
	for slot in CoreRules.EQUIPMENT_SLOTS:
		loadout["%s_id" % slot] = ""
	return loadout


func select_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD or requires_onboarding():
		return
	last_notice = ""
	last_notice_context = ""
	combat_summary = {}
	combat_events = []
	current_bounty = bounty.duplicate(true)
	if bool(current_bounty.get("mission_offer", false)):
		player.current_planet_id = str(current_bounty.get("planet_id", ContentDB.PLANET.id))
	offered_approaches = ContentDB.contract_approaches()
	phase = Phase.BRIEFING
	save_game()
	changed.emit()


func normalize_rift_foundation() -> bool:
	var changed_state := false
	var keys: Array = player.get("rift_reality_keys", []).duplicate()
	for key_id in ChallengeRulesScript.initial_key_ids(player):
		if not keys.has(key_id):
			keys.append(key_id)
			changed_state = true
	player.rift_reality_keys = keys
	var progress_by_reality: Dictionary = player.get("rift_reality_progress", {}).duplicate(true)
	if keys.has(str(ChallengeRulesScript.REALITIES[0].key_id)) and not progress_by_reality.has(ChallengeRulesScript.FIRST_REALITY_ID):
		progress_by_reality[ChallengeRulesScript.FIRST_REALITY_ID] = clampi(int(player.get("challenge_floor", 0)), 0, ChallengeRulesScript.STAGES.size())
		changed_state = true
	player.rift_reality_progress = progress_by_reality
	var selected := ChallengeRulesScript.selected_reality_id(player)
	if str(player.get("selected_rift_reality_id", "")) != selected:
		player.selected_rift_reality_id = selected
		changed_state = true
	return changed_state


func rift_status(unix_time := -1.0) -> Dictionary:
	if normalize_rift_foundation():
		save_game()
	var reality_id := ChallengeRulesScript.selected_reality_id(player)
	var reality := ChallengeRulesScript.reality_definition(reality_id)
	return {
		"unlocked": ChallengeRulesScript.is_unlocked(player),
		"reality_id": reality_id,
		"reality": reality,
		"progress": ChallengeRulesScript.progress(player, reality_id),
		"entry_available": ChallengeRulesScript.entry_available(player, unix_time),
		"entry_day": int(player.get("rift_entry_day", -1)),
	}


func select_rift_reality(reality_id: String) -> bool:
	if phase != Phase.BOARD or not ChallengeRulesScript.has_reality_key(player, reality_id):
		return false
	if str(player.get("selected_rift_reality_id", "")) == reality_id:
		return true
	player.selected_rift_reality_id = reality_id
	last_notice = ""
	last_notice_context = ""
	save_game()
	changed.emit()
	return true


func start_challenge(stage_id: String, unix_time := -1.0) -> bool:
	if phase != Phase.BOARD or requires_onboarding() or not ChallengeRulesScript.is_unlocked(player):
		return false
	normalize_rift_foundation()
	if not ChallengeRulesScript.entry_available(player, unix_time):
		last_notice = LocaleRulesScript.text("RIFT_NOTICE_ENTRY_USED", "A entrada diária já foi consumida. A Fenda estabiliza novamente à meia-noite UTC.")
		last_notice_context = "challenge_entry_used"
		save_game()
		changed.emit()
		return false
	var stage := ChallengeRulesScript.get_stage(stage_id)
	var reality_id := str(stage.get("reality_id", ""))
	if stage.is_empty() or not ChallengeRulesScript.has_reality_key(player, reality_id) or int(stage.get("challenge_index", -1)) != ChallengeRulesScript.progress(player, reality_id):
		return false
	last_notice = ""
	last_notice_context = ""
	combat_summary = {}
	combat_events = []
	current_bounty = stage
	player.selected_rift_reality_id = reality_id
	player.rift_entry_day = MonetizationRulesScript.utc_day_id(unix_time)
	offered_approaches = []
	hunt_event = {}
	begin_combat()
	return true


func travel_to_planet(planet_id: String) -> bool:
	if phase != Phase.BOARD:
		return false
	if not MissionRulesScript.is_planet_available(planet_id, int(player.get("level", 1))):
		return false
	var planet := ContentDB.get_planet(planet_id)
	player.current_planet_id = str(planet.id)
	var planet_name := LocaleRulesScript.text(LocaleRulesScript.content_key("planet", str(planet.id), "name"), str(planet.name))
	last_notice = LocaleRulesScript.text("TRAVEL_NOTICE_ROUTE_CONFIRMED", "Rota confirmada: %s — o combustível será explicado na fatura.", [planet_name])
	last_notice_context = "travel"
	save_game()
	changed.emit()
	return true


func planet_capture_count(planet_id: String) -> int:
	var captures: Dictionary = player.get("captures_by_planet", {})
	return int(captures.get(planet_id, 0))


func planet_tier(planet_id: String) -> int:
	if player.get("completed_planets", []).has(planet_id):
		return 3
	return ContentDB.planet_tier_from_target_captures(planet_id, player.get("captures_by_target", {}))


func market_offers() -> Array[Dictionary]:
	if normalize_daily_economy():
		save_game()
	var cache_key := "%s:%d:%d:%d:%s" % [
		str(player.get("current_planet_id", ContentDB.PLANET.id)),
		int(player.get("level", 1)),
		int(player.get("market_cycle", 0)),
		int(player.get("economy_day", -1)),
		",".join(Array(player.get("market_purchased_offer_ids", [])).map(func(id): return str(id))),
	]
	if cache_key != _market_offer_cache_key:
		_market_offer_cache.assign(MarketRulesScript.offers(player))
		_market_offer_cache_key = cache_key
	return _market_offer_cache.duplicate(true)


func normalize_daily_economy(unix_time := -1.0) -> bool:
	var today := MonetizationRulesScript.utc_day_id(unix_time)
	if int(player.get("economy_day", -1)) == today:
		return false
	player.economy_day = today
	player.market_cycle = 0
	player.market_refresh_count = 0
	player.market_purchased_offer_ids = []
	player.hunt_fuel = MonetizationRulesScript.DAILY_HUNT_FUEL
	player.hunt_fuel_refill_count = 0
	player.daily_hunts_completed = 0
	player.claimed_daily_objectives = []
	return true


func normalize_weekly_operations(unix_time := -1.0) -> bool:
	var week_id := WeeklyOperationRulesScript.utc_week_id(unix_time)
	var changed_state := false
	if int(player.get("weekly_cycle_id", -1)) != week_id:
		player.weekly_cycle_id = week_id
		player.weekly_hunts_completed = 0
		player.claimed_weekly_objectives = []
		player.weekly_special_target_id = ""
		player.weekly_special_completed = false
		player.weekly_route_planet_ids = []
		player.weekly_route_captures = {}
		player.weekly_route_claimed = false
		changed_state = true
	if str(player.get("weekly_special_target_id", "")).is_empty():
		player.weekly_special_target_id = WeeklyOperationRulesScript.rotating_target_id(player, week_id)
		changed_state = true
	if player.get("weekly_route_planet_ids", []).is_empty():
		player.weekly_route_planet_ids = WeeklyOperationRulesScript.rotating_planet_ids(player, week_id)
		player.weekly_route_captures = {}
		player.weekly_route_claimed = false
		changed_state = true
	return changed_state


func hunt_fuel_status(unix_time := -1.0) -> Dictionary:
	if normalize_daily_economy(unix_time):
		save_game()
	return {
		"remaining": MonetizationRulesScript.hunt_fuel_remaining(player),
		"daily_reserve": MonetizationRulesScript.DAILY_HUNT_FUEL,
		"refill_count": MonetizationRulesScript.hunt_fuel_refill_count(player),
		"refill_limit": MonetizationRulesScript.MAX_HUNT_FUEL_REFILLS_PER_DAY,
		"refill_amount": MonetizationRulesScript.HUNT_FUEL_REFILL_AMOUNT,
		"refill_cost": MonetizationRulesScript.hunt_fuel_refill_cost(player),
		"can_refill": MonetizationRulesScript.can_refill_hunt_fuel(player),
	}


func refill_hunt_fuel(expected_cost := -1) -> bool:
	if phase not in [Phase.BOARD, Phase.BRIEFING]:
		return false
	var day_changed := normalize_daily_economy()
	var cost := MonetizationRulesScript.hunt_fuel_refill_cost(player)
	# Never charge a price different from the one shown in the confirmation. A
	# midnight rollover refreshes the offer instead of silently changing it.
	if int(expected_cost) >= 0 and cost != int(expected_cost):
		if day_changed:
			save_game()
		changed.emit()
		return false
	if cost <= 0 or not MonetizationRulesScript.can_refill_hunt_fuel(player) or int(player.get("warp_chips", 0)) < cost:
		return false
	player.warp_chips = int(player.get("warp_chips", 0)) - cost
	player.hunt_fuel_refill_count = MonetizationRulesScript.hunt_fuel_refill_count(player) + 1
	player.hunt_fuel = MonetizationRulesScript.hunt_fuel_remaining(player) + MonetizationRulesScript.HUNT_FUEL_REFILL_AMOUNT
	last_notice = LocaleRulesScript.text("FUEL_NOTICE_REFILLED", "Reserva reabastecida: +%d combustível por %d Fichas de Dobra.", [MonetizationRulesScript.HUNT_FUEL_REFILL_AMOUNT, cost])
	last_notice_context = "fuel"
	save_game()
	changed.emit()
	return true


func register_item_discovery(item: Dictionary) -> bool:
	var collection_id := EquipmentGenerationRulesScript.collection_id(item)
	if collection_id.is_empty():
		return false
	var discovered: Array = player.get("discovered_item_variant_ids", [])
	if discovered.has(collection_id):
		return false
	discovered.append(collection_id)
	player.discovered_item_variant_ids = discovered
	return true


func item_collection_progress() -> Dictionary:
	return {
		"discovered": player.get("discovered_item_variant_ids", []).size(),
		"total": ContentDB.procedural_collection_total(),
	}


func collection_milestones() -> Array[Dictionary]:
	return CollectionRulesScript.milestones(player, ContentDB.procedural_collection_total())


func collection_rewards_ready() -> int:
	return CollectionRulesScript.rewards_ready(player, ContentDB.procedural_collection_total()).size()


func claim_collection_milestone(milestone_id: String) -> bool:
	for milestone in collection_milestones():
		if str(milestone.id) != milestone_id or not bool(milestone.complete) or bool(milestone.claimed):
			continue
		var claimed: Array = player.get("claimed_collection_milestones", []).duplicate()
		claimed.append(milestone_id)
		var warp_chips := int(milestone.warp_chips)
		player.claimed_collection_milestones = claimed
		player.warp_chips = int(player.get("warp_chips", 0)) + warp_chips
		last_notice = LocaleRulesScript.text("COLLECTION_NOTICE_CLAIMED", "Marco de séries resgatado: +%d Fichas de Dobra.", [warp_chips])
		last_notice_context = "collection"
		save_game()
		changed.emit()
		return true
	return false


func claim_all_collection_milestones() -> Dictionary:
	var ready := CollectionRulesScript.rewards_ready(player, ContentDB.procedural_collection_total())
	if ready.is_empty():
		return {"count": 0, "warp_chips": 0}
	var claimed: Array = player.get("claimed_collection_milestones", []).duplicate()
	var warp_chips := 0
	for milestone in ready:
		claimed.append(str(milestone.id))
		warp_chips += int(milestone.warp_chips)
	player.claimed_collection_milestones = claimed
	player.warp_chips = int(player.get("warp_chips", 0)) + warp_chips
	last_notice = LocaleRulesScript.text("COLLECTION_NOTICE_ALL_CLAIMED", "%d marcos de séries resgatados: +%d Fichas de Dobra.", [ready.size(), warp_chips])
	last_notice_context = "collection"
	save_game()
	changed.emit()
	return {"count": ready.size(), "warp_chips": warp_chips}


func daily_objectives() -> Array[Dictionary]:
	if normalize_daily_economy():
		save_game()
	return DailyObjectiveRulesScript.objectives(player)


func daily_rewards_ready() -> int:
	if normalize_daily_economy():
		save_game()
	return DailyObjectiveRulesScript.rewards_ready(player).size()


func claim_daily_objective(objective_id: String) -> bool:
	for objective in daily_objectives():
		if str(objective.id) != objective_id or not bool(objective.complete) or bool(objective.claimed):
			continue
		var claimed: Array = player.get("claimed_daily_objectives", []).duplicate()
		claimed.append(objective_id)
		player.claimed_daily_objectives = claimed
		player.credits = int(player.get("credits", 0)) + int(objective.credits)
		player.scrap = int(player.get("scrap", 0)) + int(objective.scrap)
		last_notice = LocaleRulesScript.text("DAILY_NOTICE_CLAIMED", "Objetivo diário resgatado: +%d créditos · +%d sucata.", [int(objective.credits), int(objective.scrap)])
		last_notice_context = "daily"
		save_game()
		changed.emit()
		return true
	return false


func claim_all_daily_objectives() -> Dictionary:
	if normalize_daily_economy():
		save_game()
	var ready := DailyObjectiveRulesScript.rewards_ready(player)
	if ready.is_empty():
		return {"count": 0, "credits": 0, "scrap": 0}
	var claimed: Array = player.get("claimed_daily_objectives", []).duplicate()
	var credits := 0
	var scrap := 0
	for objective in ready:
		claimed.append(str(objective.id))
		credits += int(objective.credits)
		scrap += int(objective.scrap)
	player.claimed_daily_objectives = claimed
	player.credits = int(player.get("credits", 0)) + credits
	player.scrap = int(player.get("scrap", 0)) + scrap
	last_notice = LocaleRulesScript.text("DAILY_NOTICE_ALL_CLAIMED", "%d objetivos diários resgatados: +%d créditos · +%d sucata.", [ready.size(), credits, scrap])
	last_notice_context = "daily"
	save_game()
	changed.emit()
	return {"count": ready.size(), "credits": credits, "scrap": scrap}


func weekly_objectives() -> Array[Dictionary]:
	if normalize_weekly_operations():
		save_game()
	return WeeklyOperationRulesScript.objectives(player)


func weekly_rewards_ready() -> int:
	if normalize_weekly_operations():
		save_game()
	return WeeklyOperationRulesScript.rewards_ready(player).size() + (1 if WeeklyOperationRulesScript.route_reward_ready(player) else 0)


func weekly_route_status() -> Dictionary:
	if normalize_weekly_operations():
		save_game()
	return WeeklyOperationRulesScript.route_status(player)


func claim_weekly_route() -> bool:
	var status := weekly_route_status()
	if not bool(status.complete) or bool(status.claimed):
		return false
	player.weekly_route_claimed = true
	player.credits = int(player.get("credits", 0)) + int(status.credits)
	player.scrap = int(player.get("scrap", 0)) + int(status.scrap)
	last_notice = LocaleRulesScript.text("WEEKLY_ROUTE_NOTICE_CLAIMED", "Circuito da Rede resgatado: +%d créditos · +%d sucata.", [int(status.credits), int(status.scrap)])
	last_notice_context = "weekly"
	save_game()
	changed.emit()
	return true


func weekly_special_status() -> Dictionary:
	if normalize_weekly_operations():
		save_game()
	var target_id := str(player.get("weekly_special_target_id", ""))
	return {
		"week_id": int(player.get("weekly_cycle_id", -1)),
		"target": ContentDB.get_target(target_id),
		"contract": WeeklyOperationRulesScript.special_contract(player, target_id, int(player.get("weekly_cycle_id", -1))),
		"completed": bool(player.get("weekly_special_completed", false)),
	}


func start_weekly_special() -> bool:
	if phase != Phase.BOARD or requires_onboarding():
		return false
	var status := weekly_special_status()
	if bool(status.completed) or status.contract.is_empty():
		return false
	select_bounty(status.contract)
	return phase == Phase.BRIEFING


func claim_weekly_objective(objective_id: String) -> bool:
	for objective in weekly_objectives():
		if str(objective.id) != objective_id or not bool(objective.complete) or bool(objective.claimed):
			continue
		var claimed: Array = player.get("claimed_weekly_objectives", []).duplicate()
		claimed.append(objective_id)
		player.claimed_weekly_objectives = claimed
		player.credits = int(player.get("credits", 0)) + int(objective.credits)
		player.scrap = int(player.get("scrap", 0)) + int(objective.scrap)
		last_notice = LocaleRulesScript.text("WEEKLY_NOTICE_CLAIMED", "Objetivo semanal resgatado: +%d créditos · +%d sucata.", [int(objective.credits), int(objective.scrap)])
		last_notice_context = "weekly"
		save_game()
		changed.emit()
		return true
	return false


func claim_all_weekly_objectives() -> Dictionary:
	if normalize_weekly_operations():
		save_game()
	var ready := WeeklyOperationRulesScript.rewards_ready(player)
	var route := WeeklyOperationRulesScript.route_status(player)
	var route_ready := bool(route.complete) and not bool(route.claimed)
	if ready.is_empty() and not route_ready:
		return {"count": 0, "credits": 0, "scrap": 0}
	var claimed: Array = player.get("claimed_weekly_objectives", []).duplicate()
	var credits := 0
	var scrap := 0
	for objective in ready:
		claimed.append(str(objective.id))
		credits += int(objective.credits)
		scrap += int(objective.scrap)
	if route_ready:
		player.weekly_route_claimed = true
		credits += int(route.credits)
		scrap += int(route.scrap)
	player.claimed_weekly_objectives = claimed
	player.credits = int(player.get("credits", 0)) + credits
	player.scrap = int(player.get("scrap", 0)) + scrap
	var payment_count := ready.size() + (1 if route_ready else 0)
	last_notice = LocaleRulesScript.text("WEEKLY_NOTICE_ALL_PAYMENTS_CLAIMED", "%d pagamentos semanais resgatados: +%d créditos · +%d sucata.", [payment_count, credits, scrap])
	last_notice_context = "weekly"
	save_game()
	changed.emit()
	return {"count": payment_count, "credits": credits, "scrap": scrap}


func buy_market_offer(offer_id: String) -> bool:
	if phase != Phase.BOARD or offer_id.is_empty() or player.get("market_purchased_offer_ids", []).has(offer_id):
		return false
	var selected: Dictionary = {}
	for offer in market_offers():
		if str(offer.id) == offer_id:
			selected = offer
			break
	if selected.is_empty():
		return false
	var price := int(selected.price)
	if price <= 0 or int(player.credits) < price:
		return false
	var item: Dictionary = selected.item.duplicate(true)
	var equipped := CoreRules.is_upgrade_for_player(player, item)
	player.credits = int(player.credits) - price
	player.market_purchased_offer_ids.append(offer_id)
	var collection_new := register_item_discovery(item)
	if equipped:
		equip(item)
	else:
		player.inventory.append(item)
	var item_name := localized_item_field(item, "name")
	last_notice = LocaleRulesScript.text("MARKET_NOTICE_EQUIPPED", "Mercado: %s comprado por %d créditos e equipado.", [item_name, price]) if equipped else LocaleRulesScript.text("MARKET_NOTICE_STORED", "Mercado: %s comprado por %d créditos e guardado.", [item_name, price])
	if collection_new:
		last_notice += " " + LocaleRulesScript.text("ITEM_COLLECTION_NEW", "Nova série adicionada à coleção.")
	last_notice_context = "market"
	# A stored purchase changes wallet/inventory presentation but not the combat
	# build. Retain expensive deterministic estimates unless the item auto-equips.
	if equipped:
		CoreRules.clear_bounty_odds_cache()
	save_game()
	changed.emit()
	return true


func refresh_market() -> bool:
	if phase != Phase.BOARD:
		return false
	normalize_daily_economy()
	var cost := MarketRulesScript.refresh_cost(player)
	if cost <= 0 or not MonetizationRulesScript.can_refresh_market(player) or int(player.get("warp_chips", 0)) < cost:
		return false
	player.warp_chips = int(player.get("warp_chips", 0)) - cost
	player.market_cycle = int(player.get("market_cycle", 0)) + 1
	player.market_refresh_count = int(player.get("market_refresh_count", 0)) + 1
	player.market_purchased_offer_ids = []
	last_notice = LocaleRulesScript.text("MARKET_NOTICE_REFRESHED", "Mercado renovado por %d Fichas de Dobra. A procedência continua confidencial.", [cost])
	last_notice_context = "market"
	save_game()
	changed.emit()
	return true


func acquire_or_equip_transport(transport_id: String) -> bool:
	if phase != Phase.BOARD:
		return false
	var transport := TransportRulesScript.definition(transport_id)
	if transport.is_empty() or not TransportRulesScript.is_unlocked(player, transport):
		return false
	var owned: Array = player.get("owned_transport_ids", [])
	if not owned.has(transport_id):
		var price := int(transport.price)
		if price <= 0 or int(player.credits) < price:
			return false
		player.credits = int(player.credits) - price
		owned.append(transport_id)
		player.owned_transport_ids = owned
		var transport_name := LocaleRulesScript.text(LocaleRulesScript.content_key("transport", transport_id, "name"), str(transport.name))
		last_notice = LocaleRulesScript.text("HANGAR_NOTICE_PURCHASED", "Hangar: %s comprado por %d créditos e definido como transporte ativo.", [transport_name, price])
	else:
		var transport_name := LocaleRulesScript.text(LocaleRulesScript.content_key("transport", transport_id, "name"), str(transport.name))
		last_notice = LocaleRulesScript.text("HANGAR_NOTICE_EQUIPPED", "Hangar: %s agora responde pelos seus atrasos.", [transport_name])
	player.active_transport_id = transport_id
	last_notice_context = "hangar"
	save_game()
	changed.emit()
	return true


func apply_offline_progress(now_unix: float) -> Dictionary:
	var last_seen := float(player.get("last_seen_unix", now_unix))
	var elapsed := maxf(0.0, now_unix - last_seen)
	var rewards := CoreRules.offline_patrol_rewards(elapsed, MissionRulesScript.available_planet_count(int(player.get("level", 1))), int(player.get("wins", 0)))
	# A clock rollback must not move the settlement watermark backwards and turn
	# the same interval into a future patrol payout when the clock catches up.
	player.last_seen_unix = maxf(last_seen, now_unix)
	if int(rewards.credits) <= 0 and int(rewards.scrap) <= 0:
		afk_report = {}
		return rewards
	player.credits = int(player.credits) + int(rewards.credits)
	player.scrap = int(player.get("scrap", 0)) + int(rewards.scrap)
	player.afk_credits_earned = int(player.get("afk_credits_earned", 0)) + int(rewards.credits)
	player.afk_scrap_earned = int(player.get("afk_scrap_earned", 0)) + int(rewards.scrap)
	afk_report = rewards.duplicate(true)
	return rewards


func dismiss_afk_report(clear_system_recovery := false) -> void:
	if afk_report.is_empty():
		return
	afk_report = {}
	if clear_system_recovery and last_notice_context == "system_recovery":
		last_notice = ""
		last_notice_context = ""
	changed.emit()


func dismiss_notice(expected_context := "") -> void:
	if last_notice.is_empty() or (not expected_context.is_empty() and last_notice_context != expected_context):
		return
	last_notice = ""
	last_notice_context = ""
	changed.emit()


func career_milestones() -> Array[Dictionary]:
	return CareerRules.milestones(player)


func career_rewards_ready() -> int:
	return CareerRules.rewards_ready(player).size()


func claim_career_milestone(milestone_id: String) -> bool:
	for milestone in career_milestones():
		if str(milestone.id) != milestone_id or not bool(milestone.complete) or bool(milestone.claimed):
			continue
		var credits := int(milestone.credits)
		var scrap := int(milestone.scrap)
		var claimed: Array = player.get("claimed_milestones", [])
		claimed.append(milestone_id)
		player.claimed_milestones = claimed
		player.credits = int(player.credits) + credits
		player.scrap = int(player.get("scrap", 0)) + scrap
		player.career_credits_claimed = int(player.get("career_credits_claimed", 0)) + credits
		player.career_scrap_claimed = int(player.get("career_scrap_claimed", 0)) + scrap
		var scrap_text := LocaleRulesScript.text("CAREER_NOTICE_SCRAP", " · +%d sucata", [scrap]) if scrap > 0 else ""
		last_notice = LocaleRulesScript.text("CAREER_NOTICE_CLAIMED", "Marco resgatado: %s. +%d créditos%s", [str(milestone.name), credits, scrap_text])
		last_notice_context = "career"
		save_game()
		changed.emit()
		return true
	return false


func claim_all_career_milestones() -> Dictionary:
	var ready := CareerRules.rewards_ready(player)
	if ready.is_empty():
		return {"count": 0, "credits": 0, "scrap": 0}
	var claimed: Array = player.get("claimed_milestones", []).duplicate()
	var credits := 0
	var scrap := 0
	for milestone in ready:
		claimed.append(str(milestone.id))
		credits += int(milestone.credits)
		scrap += int(milestone.scrap)
	player.claimed_milestones = claimed
	player.credits = int(player.credits) + credits
	player.scrap = int(player.get("scrap", 0)) + scrap
	player.career_credits_claimed = int(player.get("career_credits_claimed", 0)) + credits
	player.career_scrap_claimed = int(player.get("career_scrap_claimed", 0)) + scrap
	last_notice = LocaleRulesScript.text("CAREER_NOTICE_ALL_CLAIMED", "%d marcos resgatados: +%d créditos · +%d sucata.", [ready.size(), credits, scrap])
	last_notice_context = "career"
	save_game()
	changed.emit()
	return {"count": ready.size(), "credits": credits, "scrap": scrap}


func choose_approach(approach_id: String, tested_context: Dictionary = {}) -> bool:
	if phase != Phase.BRIEFING:
		return false
	normalize_daily_economy()
	var fuel_cost := MonetizationRulesScript.mission_fuel_cost(current_bounty)
	if not MonetizationRulesScript.can_start_mission(player, current_bounty):
		last_notice = LocaleRulesScript.text("FUEL_NOTICE_INSUFFICIENT", "Combustível insuficiente: esta rota exige %d e restam %d.", [fuel_cost, MonetizationRulesScript.hunt_fuel_remaining(player)])
		last_notice_context = "fuel"
		save_game()
		changed.emit()
		return false
	for approach in offered_approaches:
		if str(approach.id) == approach_id:
			current_bounty = ContentDB.apply_approach(current_bounty, approach)
			if str(tested_context.get("target_id", "")) == str(current_bounty.get("id", "")) and not str(tested_context.get("approach_id", "")).is_empty():
				current_bounty.field_test_context = {
					"tested_approach_id": str(tested_context.approach_id),
					"tested_approach_name": str(tested_context.get("approach_name", "CONTRATO BASE")),
					"tested_odds": float(tested_context.get("odds", 0.0)),
					"chosen_approach_id": approach_id,
					"chosen_approach_name": str(approach.name),
					"overridden": str(tested_context.approach_id) != approach_id,
				}
			offered_approaches = []
			return start_hunt()
	return false


func start_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	last_notice_context = ""
	combat_summary = {}
	combat_events = []
	current_bounty = bounty.duplicate(true)
	offered_approaches = []
	start_hunt()


func start_hunt() -> bool:
	if phase not in [Phase.BOARD, Phase.BRIEFING] or current_bounty.is_empty():
		return false
	normalize_daily_economy()
	var fuel_cost := MonetizationRulesScript.mission_fuel_cost(current_bounty)
	if fuel_cost > 0:
		var remaining := MonetizationRulesScript.hunt_fuel_remaining(player)
		if remaining < fuel_cost:
			last_notice = LocaleRulesScript.text("FUEL_NOTICE_INSUFFICIENT", "Combustível insuficiente: esta rota exige %d e restam %d.", [fuel_cost, remaining])
			last_notice_context = "fuel"
			save_game()
			changed.emit()
			return false
		player.hunt_fuel = remaining - fuel_cost
	phase = Phase.HUNT
	hunt_started_at = Time.get_unix_time_from_system()
	hunt_ends_at = hunt_started_at + TransportRulesScript.effective_mission_duration(player, current_bounty)
	hunt_event = ContentDB.random_hunt_event(rng, str(current_bounty.get("planet_id", ContentDB.PLANET.id)))
	hunt_event_triggered = false
	hunt_elapsed_before_event = 0.0
	hunt_remaining_after_event = 0.0
	save_game()
	changed.emit()
	return true


func cancel_briefing() -> void:
	if phase != Phase.BRIEFING:
		return
	phase = Phase.BOARD
	current_bounty = {}
	offered_approaches = []
	save_game()
	changed.emit()


func hunt_progress(now := -1.0) -> float:
	if phase != Phase.HUNT and phase != Phase.HUNT_EVENT:
		return 0.0
	var sampled_now: float = Time.get_unix_time_from_system() if now < 0.0 else now
	return HuntTimingRulesScript.progress(sampled_now, hunt_started_at, hunt_ends_at)


func update_hunt(now := -1.0) -> bool:
	if phase != Phase.HUNT and phase != Phase.HUNT_EVENT:
		return false
	var sampled_now: float = Time.get_unix_time_from_system() if now < 0.0 else now
	if HuntTimingRulesScript.is_complete(sampled_now, hunt_ends_at):
		begin_combat(true)
		return true
	if phase == Phase.HUNT and not hunt_event_triggered and hunt_progress(sampled_now) >= 0.45:
		hunt_event_triggered = true
		hunt_elapsed_before_event = maxf(0.0, sampled_now - hunt_started_at)
		hunt_remaining_after_event = maxf(0.1, HuntTimingRulesScript.remaining(sampled_now, hunt_ends_at))
		phase = Phase.HUNT_EVENT
		save_game()
		changed.emit()
		return true
	return false


func can_afford_hunt_choice(choice: Dictionary) -> bool:
	return int(player.credits) >= int(choice.get("credit_cost", 0))


func ignore_hunt_event() -> bool:
	if phase != Phase.HUNT_EVENT:
		return false
	hunt_event = {}
	var now := Time.get_unix_time_from_system()
	if HuntTimingRulesScript.is_complete(now, hunt_ends_at):
		begin_combat(true)
		return true
	phase = Phase.HUNT
	hunt_remaining_after_event = HuntTimingRulesScript.remaining(now, hunt_ends_at)
	save_game()
	changed.emit()
	return true


func resolve_hunt_event(choice_id: String) -> bool:
	if phase != Phase.HUNT_EVENT:
		return false
	var choices: Array = hunt_event.get("choices", [])
	for choice in choices:
		if str(choice.get("id", "")) != choice_id:
			continue
		if not can_afford_hunt_choice(choice):
			return false
		player.credits = int(player.credits) - int(choice.get("credit_cost", 0))
		current_bounty = ContentDB.apply_hunt_choice(current_bounty, choice)
		var duration_add := float(choice.get("duration_add", 0.0))
		var now := Time.get_unix_time_from_system()
		if not HuntTimingRulesScript.interval_is_valid(hunt_started_at, hunt_ends_at):
			# Compatibility for old paused-event saves and isolated fixtures. New
			# incidents always retain their original wall-clock deadline.
			hunt_started_at = now - maxf(0.0, hunt_elapsed_before_event)
			hunt_ends_at = now + maxf(0.1, hunt_remaining_after_event)
		# Incidents never pause the authoritative mission clock. A voluntary
		# detour extends the existing deadline, while time spent deciding is real.
		hunt_ends_at = HuntTimingRulesScript.extend_deadline(hunt_ends_at, duration_add)
		hunt_remaining_after_event = HuntTimingRulesScript.remaining(now, hunt_ends_at)
		if HuntTimingRulesScript.is_complete(now, hunt_ends_at):
			begin_combat(true)
			return true
		phase = Phase.HUNT
		save_game()
		changed.emit()
		return true
	return false


func begin_combat(arrived_from_hunt := false) -> void:
	phase = Phase.COMBAT
	player_hp = CoreRules.max_health(player)
	enemy_hp = int(current_bounty.health)
	combat_round = 0
	combat_events = []
	combat_summary = {
		"target_id": str(current_bounty.get("id", "")),
		"target_name": str(current_bounty.get("name", "Alvo sem recibo")),
		"class_id": str(player.get("class_id", "")),
		"rounds": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"damage_prevented": 0,
		"critical_hits": 0,
		"opening_bonus": CoreRules.player_opening_damage(player),
		"counter_damage": 0,
		"follow_up_damage": 0,
		"dodges": 0,
		"defense_bypassed": 0,
		"target_max_health": int(current_bounty.health),
	}
	if arrived_from_hunt:
		combat_summary.arrived_from_hunt = true
	mission_ready_feedback_pending = arrived_from_hunt
	var kit_origin := CoreRules.equipment_set_origin(player)
	if not kit_origin.is_empty():
		combat_summary.kit_origin = kit_origin
	var field_test_context: Dictionary = current_bounty.get("field_test_context", {})
	if not field_test_context.is_empty():
		combat_summary.field_test_context = field_test_context.duplicate(true)
	last_combat_won = false
	save_game()
	changed.emit()


func consume_mission_ready_feedback() -> bool:
	if not mission_ready_feedback_pending:
		return false
	mission_ready_feedback_pending = false
	return true


func combat_step() -> Dictionary:
	if phase != Phase.COMBAT:
		return {}
	combat_round += 1
	var round_events: Array[Dictionary] = []
	var player_roll := rng.randf()
	var opening_multiplier := EnemyProfileRules.modifier(current_bounty, "opening_damage_multiplier", 1.0)
	var roll_bonus_multiplier := EnemyProfileRules.modifier(current_bounty, "attack_roll_bonus_multiplier", 1.0)
	var defense_bypass_multiplier := EnemyProfileRules.modifier(current_bounty, "defense_bypass_multiplier", 1.0)
	var player_damage := CoreRules.player_attack_damage(player, int(current_bounty.defense), player_roll, combat_round, opening_multiplier, roll_bonus_multiplier, defense_bypass_multiplier)
	var player_event := {
		"actor": "player",
		"action": ContentDB.player_attack(rng),
		"damage": player_damage,
		"quality": combat_quality(CoreRules.player_attack_roll(player, player_roll, roll_bonus_multiplier)),
	}
	var opening_bonus := CoreRules.player_opening_damage(player) if combat_round == 1 else 0
	var player_effects: Array[String] = []
	var class_opening_bonus := ClassRules.specialization_opening_damage(player, CoreRules.BASE_ATTRIBUTE_VALUE) if combat_round == 1 else 0
	var non_class_opening_bonus := maxi(0, opening_bonus - class_opening_bonus)
	if non_class_opening_bonus > 0:
		player_effects.append("EMBOSCADA +%d" % non_class_opening_bonus)
	if class_opening_bonus > 0:
		player_effects.append("INVASÃO +%d" % class_opening_bonus)
	var opening_amplified := roundi(float(opening_bonus) * maxf(0.0, opening_multiplier - 1.0)) if combat_round == 1 else 0
	var opening_dampened := roundi(float(opening_bonus) * maxf(0.0, 1.0 - opening_multiplier)) if combat_round == 1 else 0
	if opening_amplified > 0:
		player_effects.append("INSTABILIDADE +%d" % opening_amplified)
	elif opening_dampened > 0:
		player_effects.append("INTERFERÊNCIA -%d" % opening_dampened)
	var class_roll_bonus := ClassRules.specialization_attack_roll_bonus(player, CoreRules.BASE_ATTRIBUTE_VALUE)
	if class_roll_bonus > 0.0:
		player_effects.append("MIRA ORBITAL +%.1f%%" % (class_roll_bonus * roll_bonus_multiplier * 100.0))
	var defense_bypass := mini(int(current_bounty.defense), roundi(float(CoreRules.player_defense_bypass(player)) * defense_bypass_multiplier))
	if defense_bypass > 0:
		player_effects.append("SOBRECARGA -%d DEFESA" % defense_bypass)
		combat_summary.defense_bypassed = int(combat_summary.get("defense_bypassed", 0)) + defense_bypass
	if not player_effects.is_empty():
		player_event.effect = " · ".join(player_effects)
	round_events.append(player_event)
	combat_summary.rounds = combat_round
	combat_summary.damage_dealt = int(combat_summary.get("damage_dealt", 0)) + mini(enemy_hp, player_damage)
	if str(player_event.quality) == "CRÍTICO":
		combat_summary.critical_hits = int(combat_summary.get("critical_hits", 0)) + 1
	enemy_hp = maxi(0, enemy_hp - player_damage)
	var message := "%s causa %d de dano." % [player_event.action, player_damage]
	if enemy_hp <= 0:
		combat_events = round_events
		finish_combat(true)
		return {"message": message, "finished": true, "won": true}
	var adjusted_player_roll := CoreRules.player_attack_roll(player, player_roll, roll_bonus_multiplier)
	var follow_up_damage := CoreRules.player_follow_up_damage(player, adjusted_player_roll, player_damage)
	if follow_up_damage > 0:
		var applied_follow_up := mini(enemy_hp, follow_up_damage)
		var follow_up_event := {"actor": "player", "action": str(player_event.action), "damage": follow_up_damage, "quality": "ACERTO", "effect": "RAJADA TÁTICA +%d" % follow_up_damage}
		round_events.append(follow_up_event)
		combat_summary.damage_dealt = int(combat_summary.get("damage_dealt", 0)) + applied_follow_up
		combat_summary.follow_up_damage = int(combat_summary.get("follow_up_damage", 0)) + applied_follow_up
		enemy_hp = maxi(0, enemy_hp - follow_up_damage)
		message += "  Rajada tática causa %d." % follow_up_damage
		if enemy_hp <= 0:
			combat_events = round_events
			finish_combat(true)
			return {"message": message, "finished": true, "won": true}

	var enemy_roll := rng.randf()
	var enemy_breakdown := CoreRules.enemy_attack_breakdown(player, int(current_bounty.power), enemy_roll, EnemyProfileRules.modifier(current_bounty, "damage_reduction_piercing", 0.0))
	var enemy_damage := int(enemy_breakdown.damage)
	var enemy_event := {
		"actor": "enemy",
		"action": ContentDB.target_attack(current_bounty, rng),
		"damage": enemy_damage,
		"quality": combat_quality(enemy_roll),
	}
	var damage_reduction := CoreRules.player_damage_reduction(player)
	var dodged := bool(enemy_breakdown.get("dodged", false))
	var reduction_pierced := 0 if dodged else maxi(0, damage_reduction - int(enemy_breakdown.get("effective_reduction", damage_reduction)))
	var enemy_effects: Array[String] = []
	if dodged:
		enemy_effects.append("EVASÃO TÁTICA")
		combat_summary.dodges = int(combat_summary.get("dodges", 0)) + 1
	var class_damage_reduction := ClassRules.specialization_damage_reduction(player, CoreRules.BASE_ATTRIBUTE_VALUE)
	var non_class_damage_reduction := maxi(0, damage_reduction - class_damage_reduction)
	if non_class_damage_reduction > 0 and not dodged:
		enemy_effects.append("AMORTECEDOR -%d" % non_class_damage_reduction)
	if class_damage_reduction > 0 and not dodged:
		enemy_effects.append("CASCO DURO -%d" % class_damage_reduction)
	if reduction_pierced > 0:
		enemy_effects.append("RUPTURA +%d" % reduction_pierced)
	if not enemy_effects.is_empty():
		enemy_event.effect = " · ".join(enemy_effects)
	round_events.append(enemy_event)
	combat_summary.damage_taken = int(combat_summary.get("damage_taken", 0)) + mini(player_hp, enemy_damage)
	combat_summary.damage_prevented = int(combat_summary.get("damage_prevented", 0)) + int(enemy_breakdown.prevented)
	player_hp = maxi(0, player_hp - enemy_damage)
	message += "  %s responde com %d." % [enemy_event.action, enemy_damage]
	if player_hp > 0:
		var counter_damage := roundi(float(CoreRules.player_counter_damage(player, combat_round)) * EnemyProfileRules.modifier(current_bounty, "counter_damage_multiplier", 1.0))
		if counter_damage > 0:
			var applied_counter := mini(enemy_hp, counter_damage)
			var counter_event := {"actor": "player", "action": str(player_event.action), "damage": counter_damage, "quality": "ACERTO", "effect": "CONTRA-ATAQUE +%d" % counter_damage}
			round_events.append(counter_event)
			combat_summary.damage_dealt = int(combat_summary.get("damage_dealt", 0)) + applied_counter
			combat_summary.counter_damage = int(combat_summary.get("counter_damage", 0)) + applied_counter
			enemy_hp = maxi(0, enemy_hp - counter_damage)
			message += "  Contra-ataque causa %d." % counter_damage
			if enemy_hp <= 0:
				combat_events = round_events
				finish_combat(true)
				return {"message": message, "finished": true, "won": true}
	combat_events = round_events
	if player_hp <= 0:
		finish_combat(false)
		return {"message": message, "finished": true, "won": false}
	# Combat can advance close to three rounds per second at 2x speed. Writing the
	# complete JSON save on every round stalls some Android storage controllers.
	# Phase changes, application pause, and quit still save immediately; this
	# checkpoint only bounds recovery after an abrupt process kill.
	if combat_round % COMBAT_CHECKPOINT_INTERVAL == 0:
		save_game()
	combat_event.emit(message)
	return {"message": message, "finished": false}


func finish_combat(won: bool) -> void:
	last_combat_won = won
	combat_summary.won = won
	combat_summary.player_hp_remaining = player_hp
	combat_summary.enemy_hp_remaining = enemy_hp
	if won:
		if bool(current_bounty.get("challenge", false)):
			pending_loot = ChallengeRulesScript.reward_for(current_bounty, ContentDB.ITEM_TRAITS)
		else:
			var target_id := str(current_bounty.get("id", ""))
			var target_captures := int(player.get("captures_by_target", {}).get(target_id, 0))
			pending_loot = ContentDB.generate_loot(current_bounty, rng, CoreRules.target_mastery_level(target_captures))
		phase = Phase.VICTORY
	else:
		var challenge_defeat := bool(current_bounty.get("challenge", false))
		var lost_streak := 0 if challenge_defeat else int(player.get("capture_streak", 0))
		if lost_streak > 0:
			combat_summary.lost_streak = lost_streak
			player.capture_streak = 0
		phase = Phase.BOARD
		if challenge_defeat:
			last_notice = LocaleRulesScript.text("RIFT_NOTICE_DEFEAT", "A Fenda rejeitou a incursão. O andar permanece aberto e o embalo dos mandados foi preservado.")
			last_notice_context = "challenge_defeat"
		else:
			var escaped_name := localized_content_field("target", current_bounty, "name")
			var streak_suffix := LocaleRulesScript.text("DEFEAT_STREAK_LOST", " Embalo ×%d perdido.", [lost_streak]) if lost_streak > 0 else ""
			last_notice = LocaleRulesScript.text("DEFEAT_NOTICE", "%s escapou. Seu equipamento precisa de argumentos melhores.%s", [escaped_name, streak_suffix])
			last_notice_context = "defeat"
		current_bounty = {}
		pending_loot = {}
		offered_approaches = []
		hunt_event = {}
	save_game()
	changed.emit()


func open_reward() -> void:
	if phase != Phase.VICTORY:
		return
	phase = Phase.REWARD
	save_game()
	changed.emit()


func combat_quality(roll: float) -> String:
	if roll >= 0.9:
		return "CRÍTICO"
	if roll <= 0.12:
		return "DE RASPÃO"
	return "ACERTO"


func can_recycle_reward(item: Dictionary) -> bool:
	var slot := str(item.get("slot", ""))
	if not CoreRules.is_equipment_slot(slot):
		return false
	return not CoreRules.has_intrinsic_modifier(item) and not CoreRules.has_workshop_investment(item) and not CoreRules.is_upgrade_for_player(player, item)


func localized_item_field(item: Dictionary, field: String) -> String:
	var instance_id := str(item.get("id", ""))
	var item_id := str(item.get("localization_reward_id", instance_id if instance_id.contains("__") else item.get("base_reward_id", instance_id)))
	if str(item.get("challenge_origin", "")) == "fenda_clandestina":
		return LocaleRulesScript.text("RIFT_REWARD_%s_%s" % [item_id.trim_suffix("_reward").to_upper(), field.to_upper()], str(item.get(field, "")))
	if item_id == "starter_weapon" or item_id == "starter_armor":
		return LocaleRulesScript.text("ITEM_%s_%s" % [item_id.to_upper(), field.to_upper()], str(item.get(field, "")))
	var planet_id := str(item.get("origin_planet_id", ContentDB.PLANET.id))
	var slot := str(item.get("slot", "weapon"))
	var catalog := ContentDB.item_catalog_for(planet_id, slot)
	for index in catalog.size():
		if str(catalog[index].get("name", "")) == str(item.get("name", "")):
			var key := "ITEM_%s_%s_%d_%s" % [planet_id.to_upper(), slot.to_upper(), index, field.to_upper()]
			return LocaleRulesScript.text(key, str(item.get(field, "")))
	return str(item.get(field, ""))


func localized_content_field(prefix: String, definition: Dictionary, field: String) -> String:
	if definition.is_empty():
		return ""
	var localized_prefix := "rift_stage" if prefix == "target" and bool(definition.get("challenge", false)) else prefix
	var content_id := str(definition.get("localization_stage_id", definition.get("id", ""))) if localized_prefix == "rift_stage" else str(definition.get("id", ""))
	return LocaleRulesScript.text(LocaleRulesScript.content_key(localized_prefix, content_id, field), str(definition.get(field, "")))


func claim_reward(equip_item: bool, repeat_contract := false, recycle_item := false) -> Dictionary:
	if phase != Phase.REWARD or pending_loot.is_empty():
		return {}
	if recycle_item and not can_recycle_reward(pending_loot):
		return {}
	if bool(current_bounty.get("challenge", false)):
		return claim_challenge_reward(equip_item, recycle_item)
	var new_streak := int(player.get("capture_streak", 0)) + 1
	var level_before_reward := int(player.get("level", 1))
	var reward := CoreRules.bounty_streak_reward(int(current_bounty.credits), new_streak)
	var summary := {
		"credits": int(reward.credits),
		"base_credits": int(reward.base_credits),
		"streak_bonus": int(reward.bonus_credits),
		"streak_bonus_percent": int(reward.bonus_percent),
		"incident_cost": maxi(0, int(current_bounty.get("hunt_event_credit_cost", 0))),
		"net_contract_credits": int(reward.credits) - maxi(0, int(current_bounty.get("hunt_event_credit_cost", 0))),
		"streak": new_streak,
		"scrap": 0,
		"contract_scrap": 0,
		"recycled_scrap": 0,
		"mastery_scrap": 0,
		"recycled": false,
		"xp": int(current_bounty.xp),
		"warp_chips": 0,
		"collection_new": false,
		"levels": 0,
		"new_planets": [],
		"rank_up": false,
		"chapter_tier_up": false,
		"chapter_complete": false,
		"weekly_special_complete": false,
		"target_mastery_up": false,
		"target_mastery": 0,
		"loot_name": localized_item_field(pending_loot, "name"),
		"loot_action": "recycled" if recycle_item else ("equipped" if equip_item else "stored"),
	}
	var completed_bounty := current_bounty.duplicate(true)
	# The Black Warrant is deliberately one contract per weekly cycle. The normal
	# reward screen may offer a repeat shortcut, but this mission always returns
	# to Operations after payment.
	if bool(completed_bounty.get("weekly_special", false)):
		repeat_contract = false
	var network_mission := bool(completed_bounty.get("mission_offer", false))
	var completed_planet_id := str(completed_bounty.get("planet_id", ContentDB.PLANET.id))
	var old_chapter_tier := 0 if network_mission else planet_tier(completed_planet_id)
	player.credits = int(player.credits) + summary.credits
	summary.collection_new = register_item_discovery(pending_loot)
	normalize_daily_economy()
	player.daily_hunts_completed = int(player.get("daily_hunts_completed", 0)) + 1
	normalize_weekly_operations()
	player.weekly_hunts_completed = int(player.get("weekly_hunts_completed", 0)) + 1
	if network_mission:
		WeeklyOperationRulesScript.record_route_capture(player, completed_planet_id)
	if bool(completed_bounty.get("weekly_special", false)) and int(completed_bounty.get("weekly_cycle_id", -1)) == int(player.get("weekly_cycle_id", -2)):
		player.weekly_special_completed = true
		summary.weekly_special_complete = true
	var reward_day := MonetizationRulesScript.utc_day_id()
	if MonetizationRulesScript.first_hunt_chip_available(player, float(reward_day) * MonetizationRulesScript.SECONDS_PER_DAY):
		player.daily_hunt_chip_day = reward_day
		player.warp_chips = int(player.get("warp_chips", 0)) + MonetizationRulesScript.FREE_DAILY_HUNT_CHIPS
		summary.warp_chips = MonetizationRulesScript.FREE_DAILY_HUNT_CHIPS
	player.capture_streak = new_streak
	player.best_capture_streak = maxi(int(player.get("best_capture_streak", 0)), new_streak)
	summary.levels = CoreRules.apply_xp(player, summary.xp)
	summary.new_planets = MissionRulesScript.newly_available_planets(level_before_reward, int(player.get("level", 1)))
	player.wins = int(player.wins) + 1
	var rift_key_reality := ChallengeRulesScript.record_eligible_hunt_for_key(player)
	if not rift_key_reality.is_empty():
		summary.rift_key_id = str(rift_key_reality.key_id)
		summary.rift_reality_id = str(rift_key_reality.id)
		summary.rift_reality_name = LocaleRulesScript.text(LocaleRulesScript.content_key("rift_reality", str(rift_key_reality.id), "name"), str(rift_key_reality.name))
	var captures: Dictionary = player.get("captures_by_target", {})
	var target_id := str(completed_bounty.get("id", "unknown"))
	var old_target_mastery := CoreRules.target_mastery_level(int(captures.get(target_id, 0)))
	captures[target_id] = int(captures.get(target_id, 0)) + 1
	player.captures_by_target = captures
	summary.target_mastery = CoreRules.target_mastery_level(int(captures[target_id]))
	summary.target_mastery_up = int(summary.target_mastery) > old_target_mastery
	summary.contract_scrap = maxi(0, int(completed_bounty.get("scrap_reward", 0)))
	if int(summary.contract_scrap) > 0:
		summary.scrap = int(summary.scrap) + int(summary.contract_scrap)
		player.scrap = int(player.get("scrap", 0)) + int(summary.contract_scrap)
	if bool(summary.target_mastery_up):
		summary.mastery_scrap = CoreRules.target_mastery_scrap_reward(int(summary.target_mastery))
		summary.scrap = int(summary.scrap) + int(summary.mastery_scrap)
		player.scrap = int(player.get("scrap", 0)) + int(summary.mastery_scrap)
	var planet_captures: Dictionary = player.get("captures_by_planet", {})
	planet_captures[completed_planet_id] = int(planet_captures.get(completed_planet_id, 0)) + 1
	player.captures_by_planet = planet_captures
	summary.chapter_tier_up = not network_mission and planet_tier(completed_planet_id) > old_chapter_tier
	var old_reputation := int(player.reputation)
	var highest_rank := ContentDB.highest_target_rank()
	player.reputation = mini(floori(float(player.wins) / 3.0), highest_rank)
	summary.rank_up = int(player.reputation) > old_reputation
	if recycle_item:
		summary.recycled_scrap = CoreRules.salvage_value(pending_loot)
		summary.scrap = int(summary.scrap) + int(summary.recycled_scrap)
		summary.recycled = true
		player.scrap = int(player.get("scrap", 0)) + int(summary.recycled_scrap)
		player.scrap_recycled_total = int(player.get("scrap_recycled_total", 0)) + int(summary.recycled_scrap)
	else:
		player.inventory.append(pending_loot.duplicate(true))
		if equip_item:
			equip(pending_loot)
	var notice_parts := [
		LocaleRulesScript.text("REWARD_NOTICE_CREDITS", "+%d créditos", [int(summary.credits)]),
		LocaleRulesScript.text("REWARD_NOTICE_XP", "+%d XP", [int(summary.xp)]),
	]
	if int(summary.warp_chips) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_DAILY_WARP_CHIP", "Primeira missão do dia: +%d Ficha de Dobra", [int(summary.warp_chips)]))
	if not str(summary.get("rift_key_id", "")).is_empty():
		notice_parts.append(LocaleRulesScript.text("RIFT_KEY_DISCOVERED_NOTICE", "Chave da Fenda encontrada: %s", [str(summary.rift_reality_name)]))
	if bool(summary.collection_new):
		notice_parts.append(LocaleRulesScript.text("ITEM_COLLECTION_NEW", "Nova série adicionada à coleção."))
	if int(summary.incident_cost) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_INCIDENT", "Incidente já pago: saldo +%d créditos", [int(summary.net_contract_credits)]))
	if int(summary.contract_scrap) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_WARRANT_SCRAP", "Mandado corporativo: +%d sucata", [int(summary.contract_scrap)]))
	if bool(summary.weekly_special_complete):
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_WEEKLY_SPECIAL", "Mandado Negro semanal concluído"))
	if int(summary.recycled_scrap) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_RECYCLED", "%s reciclado: +%d sucata", [str(summary.loot_name), int(summary.recycled_scrap)]))
	elif str(summary.loot_action) == "equipped":
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_EQUIPPED", "%s equipado", [str(summary.loot_name)]))
	else:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_STORED", "%s guardado", [str(summary.loot_name)]))
	if int(summary.streak_bonus) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_MOMENTUM", "Embalo ×%d: +%d", [new_streak, int(summary.streak_bonus)]))
	elif new_streak == 1:
		var next_streak := CoreRules.bounty_streak_reward(int(completed_bounty.credits), 2)
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_MOMENTUM_START", "Embalo ×1 iniciado: próxima captura +%d%%", [int(next_streak.bonus_percent)]))
	if int(summary.levels) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_LEVEL", "Nível +%d", [int(summary.levels)]))
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_ATTRIBUTE_POINTS", "+%d pontos de atributo", [int(summary.levels) * CoreRules.ATTRIBUTE_POINTS_PER_LEVEL]))
	if not summary.new_planets.is_empty():
		var planet_names: Array[String] = []
		for planet in summary.new_planets:
			planet_names.append(localized_content_field("planet", planet, "name"))
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_PLANET_UNLOCKED", "Novo destino na rede: %s", [", ".join(planet_names)]))
	if bool(summary.rank_up):
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_NETWORK_RANK", "Reputação da rede aumentada") if network_mission else LocaleRulesScript.text("REWARD_NOTICE_CONTRACT_UNLOCKED", "Novo contrato liberado"))
	elif bool(summary.chapter_tier_up):
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_WARRANT_UNLOCKED", "Novo mandado planetário"))
	if bool(summary.target_mastery_up):
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_MASTERY", "Perícia com alvo %d: +%d sucata", [int(summary.target_mastery), int(summary.mastery_scrap)]))
	var completed_planets: Array = player.get("completed_planets", [])
	var completed_planet := ContentDB.get_planet(completed_planet_id)
	var first_boss_capture := bool(completed_bounty.get("boss", false)) and not completed_planets.has(completed_planet_id)
	if first_boss_capture:
		completed_planets.append(completed_planet_id)
		player.completed_planets = completed_planets
		summary.chapter_complete = true
		chapter_completion = {
			"planet": completed_planet,
			"target": ContentDB.get_target(target_id),
			"total_captures": planet_capture_count(completed_planet_id),
			"credits": int(summary.credits),
			"xp": int(summary.xp),
		}
	last_notice = LocaleRulesScript.text("REWARD_NOTICE_PAID", "Contrato pago: %s", [" · ".join(notice_parts)])
	last_notice_context = "reward_%s" % str(summary.loot_action)
	phase = Phase.CHAPTER_COMPLETE if first_boss_capture else (Phase.BRIEFING if repeat_contract else Phase.BOARD)
	if repeat_contract and not first_boss_capture:
		current_bounty = MissionRulesScript.canonical_offer(completed_bounty) if bool(completed_bounty.get("mission_offer", false)) else ContentDB.get_target(target_id)
	else:
		current_bounty = {}
	pending_loot = {}
	combat_events.clear()
	combat_summary = {}
	offered_approaches.clear()
	if repeat_contract and not first_boss_capture:
		offered_approaches.assign(ContentDB.contract_approaches())
	hunt_event = {}
	save_game()
	changed.emit()
	return summary


func unseen_planets() -> Array[Dictionary]:
	var seen: Array = player.get("seen_planet_ids", [])
	return MissionRulesScript.available_planets(int(player.get("level", 1))).filter(
		func(planet): return not seen.has(str(planet.id))
	)


func acknowledge_planet(planet_id: String) -> bool:
	if not MissionRulesScript.is_planet_available(planet_id, int(player.get("level", 1))):
		return false
	var seen: Array = player.get("seen_planet_ids", []).duplicate()
	if seen.has(planet_id):
		return true
	seen.append(planet_id)
	player.seen_planet_ids = seen
	last_notice = LocaleRulesScript.text("GALAXY_DISCOVERY_RECORDED", "Destino registado: %s já integra a sua rede de mandados.", [localized_content_field("planet", ContentDB.get_planet(planet_id), "name")])
	last_notice_context = "galaxy"
	var saved := save_game()
	changed.emit()
	return saved


func claim_challenge_reward(equip_item: bool, recycle_item: bool) -> Dictionary:
	var completed_stage := current_bounty.duplicate(true)
	var item := pending_loot.duplicate(true)
	var stage_index := int(completed_stage.get("challenge_index", -1))
	var reality_id := str(completed_stage.get("reality_id", ChallengeRulesScript.FIRST_REALITY_ID))
	if stage_index != ChallengeRulesScript.progress(player, reality_id):
		return {}
	var summary := {
		"challenge": true,
		"credits": maxi(0, int(completed_stage.get("credits", 0))),
		"xp": maxi(0, int(completed_stage.get("xp", 0))),
		"levels": 0,
		"scrap": 0,
		"recycled": recycle_item,
		"loot_name": localized_item_field(item, "name"),
		"loot_action": "recycled" if recycle_item else ("equipped" if equip_item else "stored"),
		"challenge_floor": stage_index + 1,
		"reality_id": reality_id,
	}
	player.credits = int(player.credits) + int(summary.credits)
	summary.levels = CoreRules.apply_xp(player, int(summary.xp))
	if recycle_item:
		summary.scrap = CoreRules.salvage_value(item)
		player.scrap = int(player.get("scrap", 0)) + int(summary.scrap)
		player.scrap_recycled_total = int(player.get("scrap_recycled_total", 0)) + int(summary.scrap)
	else:
		player.inventory.append(item)
		if equip_item:
			equip(item)
	var progress_by_reality: Dictionary = player.get("rift_reality_progress", {}).duplicate(true)
	progress_by_reality[reality_id] = stage_index + 1
	player.rift_reality_progress = progress_by_reality
	if reality_id == ChallengeRulesScript.FIRST_REALITY_ID:
		player.challenge_floor = stage_index + 1
	var notice_parts := [LocaleRulesScript.text("RIFT_NOTICE_FLOOR_CLEAR", "andar %d limpo", [stage_index + 1]), LocaleRulesScript.text("RIFT_NOTICE_CREDITS", "+%d créditos", [int(summary.credits)]), "+%d XP" % int(summary.xp)]
	if recycle_item:
		notice_parts.append(LocaleRulesScript.text("RIFT_NOTICE_RECYCLED", "%s reciclado: +%d sucata", [str(summary.loot_name), int(summary.scrap)]))
	elif equip_item:
		notice_parts.append(LocaleRulesScript.text("RIFT_NOTICE_EQUIPPED", "%s equipado", [str(summary.loot_name)]))
	else:
		notice_parts.append(LocaleRulesScript.text("RIFT_NOTICE_STORED", "%s guardado", [str(summary.loot_name)]))
	if int(summary.levels) > 0:
		notice_parts.append(LocaleRulesScript.text("REWARD_NOTICE_LEVEL", "Nível +%d", [int(summary.levels)]))
	last_notice = LocaleRulesScript.text("RIFT_NOTICE_UPDATED", "Fenda atualizada: %s", [" · ".join(notice_parts)])
	last_notice_context = "challenge_reward"
	phase = Phase.BOARD
	current_bounty = {}
	pending_loot = {}
	combat_events.clear()
	combat_summary = {}
	offered_approaches.clear()
	hunt_event = {}
	CoreRules.clear_bounty_odds_cache()
	save_game()
	changed.emit()
	return summary


func continue_after_chapter() -> void:
	if phase != Phase.CHAPTER_COMPLETE:
		return
	var completed_planet: Dictionary = chapter_completion.get("planet", ContentDB.PLANET)
	phase = Phase.BOARD
	chapter_completion = {}
	last_notice = LocaleRulesScript.text("CHAPTER_COMPLETE_NOTICE", "%s pacificada. Contratos reabertos para melhorar equipamento e recordes.", [localized_content_field("planet", completed_planet, "name")])
	last_notice_context = "chapter"
	save_game()
	changed.emit()


func equip(item: Dictionary) -> void:
	var slot := str(item.get("slot", ""))
	if CoreRules.is_equipment_slot(slot):
		var previous: Dictionary = player.get(slot, {})
		var previous_id := str(previous.get("id", ""))
		var new_id := str(item.get("id", ""))
		if not previous_id.is_empty() and previous_id != new_id:
			var already_stored := false
			for inventory_item in player.get("inventory", []):
				if str(inventory_item.get("id", "")) == previous_id:
					already_stored = true
					break
			if not already_stored:
				player.inventory.append(previous.duplicate(true))
		player[slot] = item.duplicate(true)


func equip_from_inventory(item_id: String) -> void:
	if phase != Phase.BOARD:
		return
	for item in player.inventory:
		if str(item.get("id", "")) == item_id:
			equip(item)
			last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_EQUIPPED", "%s equipado. Poder total: %d.", [localized_item_field(item, "name"), CoreRules.player_power(player)])
			last_notice_context = "workshop"
			save_game()
			changed.emit()
			return


func scrap_item(item_id: String) -> bool:
	if phase != Phase.BOARD:
		return false
	if is_item_protected(item_id):
		return false
	for item_index in player.inventory.size():
		var item: Dictionary = player.inventory[item_index]
		if str(item.get("id", "")) != item_id:
			continue
		var value := CoreRules.salvage_value(item)
		player.inventory.remove_at(item_index)
		player.scrap = int(player.get("scrap", 0)) + value
		player.scrap_recycled_total = int(player.get("scrap_recycled_total", 0)) + value
		last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_RECYCLED", "%s reciclado: +%d sucata.", [localized_item_field(item, "name"), value])
		last_notice_context = "workshop"
		save_game()
		changed.emit()
		return true
	return false


func inferior_recycle_preview() -> Dictionary:
	var count := 0
	var scrap := 0
	for item in player.get("inventory", []):
		var slot := str(item.get("slot", ""))
		if not CoreRules.is_equipment_slot(slot):
			continue
		if is_item_protected(str(item.get("id", ""))):
			continue
		if CoreRules.has_intrinsic_modifier(item):
			continue
		if CoreRules.has_workshop_investment(item):
			continue
		if not CoreRules.is_upgrade_for_player(player, item):
			count += 1
			scrap += CoreRules.salvage_value(item)
	return {"count": count, "scrap": scrap}


func recycle_inferior_inventory() -> Dictionary:
	if phase != Phase.BOARD:
		return {"count": 0, "scrap": 0}
	var preview := inferior_recycle_preview()
	if int(preview.count) <= 0:
		return preview
	var retained: Array = []
	for item in player.get("inventory", []):
		var slot := str(item.get("slot", ""))
		var is_equipped: bool = is_item_protected(str(item.get("id", "")))
		var is_inferior: bool = CoreRules.is_equipment_slot(slot) and not CoreRules.has_intrinsic_modifier(item) and not CoreRules.has_workshop_investment(item) and not CoreRules.is_upgrade_for_player(player, item)
		if is_equipped or not is_inferior:
			retained.append(item)
	player.inventory = retained
	player.scrap = int(player.get("scrap", 0)) + int(preview.scrap)
	player.scrap_recycled_total = int(player.get("scrap_recycled_total", 0)) + int(preview.scrap)
	last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_BULK_RECYCLED", "%d peças inferiores recicladas: +%d sucata.", [int(preview.count), int(preview.scrap)])
	last_notice_context = "workshop"
	save_game()
	changed.emit()
	return preview


func is_item_protected(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for slot in CoreRules.EQUIPMENT_SLOTS:
		if str(player.get(slot, {}).get("id", "")) == item_id:
			return true
	if player.get("locked_item_ids", []).has(item_id):
		return true
	for loadout in player.get("equipment_loadouts", []):
		for slot in CoreRules.EQUIPMENT_SLOTS:
			if str(loadout.get("%s_id" % slot, "")) == item_id:
				return true
	return false


func toggle_item_lock(item_id: String) -> bool:
	if phase != Phase.BOARD or item_id.is_empty():
		return false
	var exists := false
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == item_id:
			exists = true
			break
	if not exists:
		return false
	var locked: Array = player.get("locked_item_ids", [])
	if locked.has(item_id):
		locked.erase(item_id)
		last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_UNLOCKED", "Proteção removida. A oficina voltou a olhar para essa peça com interesse.")
	else:
		locked.append(item_id)
		last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_PROTECTED", "Peça protegida contra reciclagem manual e em massa.")
	last_notice_context = "workshop"
	player.locked_item_ids = locked
	save_game()
	changed.emit()
	return true


func save_equipment_loadout(index: int) -> bool:
	var loadouts: Array = player.get("equipment_loadouts", [])
	if phase != Phase.BOARD or index < 0 or index >= loadouts.size():
		return false
	var snapshot := default_loadout()
	for slot in CoreRules.EQUIPMENT_SLOTS:
		snapshot["%s_id" % slot] = str(player.get(slot, {}).get("id", ""))
	loadouts[index] = snapshot
	player.equipment_loadouts = loadouts
	last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_LOADOUT_SAVED", "Loadout %s arquivado. As peças foram protegidas.", [loadout_name(index)])
	last_notice_context = "workshop"
	save_game()
	changed.emit()
	return true


func apply_equipment_loadout(index: int) -> bool:
	var loadouts: Array = player.get("equipment_loadouts", [])
	if phase != Phase.BOARD or index < 0 or index >= loadouts.size():
		return false
	var loadout: Dictionary = loadouts[index]
	var weapon := inventory_item_by_id(str(loadout.get("weapon_id", "")))
	var armor := inventory_item_by_id(str(loadout.get("armor_id", "")))
	if weapon.is_empty() or armor.is_empty():
		last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_LOADOUT_INCOMPLETE", "Loadout incompleto. Uma das peças provavelmente virou história de oficina.")
		last_notice_context = "workshop"
		changed.emit()
		return false
	for slot in CoreRules.EQUIPMENT_SLOTS:
		var item_id := str(loadout.get("%s_id" % slot, ""))
		if not item_id.is_empty():
			var item := inventory_item_by_id(item_id)
			if not item.is_empty() and str(item.get("slot", "")) == slot:
				equip(item)
	last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_LOADOUT_EQUIPPED", "Loadout %s equipado. Poder %d · Vida %d.", [loadout_name(index), CoreRules.player_power(player), CoreRules.max_health(player)])
	last_notice_context = "workshop"
	save_game()
	changed.emit()
	return true


func inventory_item_by_id(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	for slot in CoreRules.EQUIPMENT_SLOTS:
		var equipped: Dictionary = player.get(slot, {})
		if str(equipped.get("id", "")) == item_id:
			return equipped.duplicate(true)
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == item_id:
			return item.duplicate(true)
	return {}


func loadout_name(index: int) -> String:
	return LocaleRulesScript.text("LOADOUT_HUNT", "CAÇA") if index == 0 else LocaleRulesScript.text("LOADOUT_RESERVE", "RESERVA")


func upgrade_equipped(slot: String) -> bool:
	if phase != Phase.BOARD or not CoreRules.is_equipment_slot(slot) or player.get(slot, {}).is_empty():
		return false
	var item: Dictionary = player[slot]
	var scrap_cost := CoreRules.equipment_upgrade_cost(item)
	var credit_cost := CoreRules.equipment_upgrade_credit_cost(item)
	if int(player.get("scrap", 0)) < scrap_cost or int(player.get("credits", 0)) < credit_cost:
		return false
	player.scrap = int(player.scrap) - scrap_cost
	player.credits = int(player.credits) - credit_cost
	item = item.duplicate(true)
	item.power = int(item.power) + 1
	item.power_upgrades = int(item.get("power_upgrades", 0)) + 1
	player[slot] = item
	sync_item_to_inventory(item)
	last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_CALIBRATED", "%s calibrado para +%d poder. Serviço: %d créditos e %d sucata.", [localized_item_field(item, "name"), int(item.power), credit_cost, scrap_cost])
	last_notice_context = "workshop"
	save_game()
	changed.emit()
	return true


func reinforce_equipped(slot: String) -> bool:
	if phase != Phase.BOARD or not CoreRules.is_equipment_slot(slot) or player.get(slot, {}).is_empty():
		return false
	var item: Dictionary = player[slot]
	if not CoreRules.can_upgrade_integrity(item):
		return false
	var scrap_cost := CoreRules.equipment_integrity_upgrade_cost(item)
	var credit_cost := CoreRules.equipment_integrity_credit_cost(item)
	if int(player.get("scrap", 0)) < scrap_cost or int(player.get("credits", 0)) < credit_cost:
		return false
	player.scrap = int(player.scrap) - scrap_cost
	player.credits = int(player.credits) - credit_cost
	item = item.duplicate(true)
	item.integrity_upgrades = int(item.get("integrity_upgrades", 0)) + 1
	player[slot] = item
	sync_item_to_inventory(item)
	last_notice = LocaleRulesScript.text("WORKSHOP_NOTICE_REINFORCED", "%s reforçado: +%d vida total. Serviço: %d créditos e %d sucata.", [localized_item_field(item, "name"), int(item.integrity_upgrades) * CoreRules.INTEGRITY_HEALTH_PER_LEVEL, credit_cost, scrap_cost])
	last_notice_context = "workshop"
	save_game()
	changed.emit()
	return true


func sync_item_to_inventory(item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	if item_id.is_empty():
		return
	for item_index in player.inventory.size():
		if str(player.inventory[item_index].get("id", "")) == item_id:
			player.inventory[item_index] = item.duplicate(true)
			return


func toggle_sound() -> void:
	player.sound_enabled = not bool(player.get("sound_enabled", true))
	save_game()
	changed.emit()


func toggle_reduced_motion() -> void:
	player.reduced_motion = not bool(player.get("reduced_motion", false))
	save_game()
	changed.emit()


func allocate_attribute_points(allocations: Dictionary) -> bool:
	if phase != Phase.BOARD or allocations.is_empty():
		return false
	var total := 0
	for attribute_id in allocations:
		if not CoreRules.ATTRIBUTE_KEYS.has(str(attribute_id)):
			return false
		var amount = allocations[attribute_id]
		if not (amount is int or amount is float) or int(amount) <= 0 or float(amount) != float(int(amount)):
			return false
		total += int(amount)
	if total <= 0 or total > int(player.get("stat_points", 0)):
		return false
	var attributes: Dictionary = player.get("attributes", CoreRules.default_attributes()).duplicate(true)
	for attribute_id in allocations:
		attributes[str(attribute_id)] = int(attributes.get(str(attribute_id), CoreRules.BASE_ATTRIBUTE_VALUE)) + int(allocations[attribute_id])
	player.attributes = attributes
	player.stat_points = int(player.get("stat_points", 0)) - total
	last_notice = LocaleRulesScript.text("ATTRIBUTE_NOTICE_CONFIRMED_PLURAL" if total != 1 else "ATTRIBUTE_NOTICE_CONFIRMED_SINGULAR", "%d pontos de atributo confirmados." if total != 1 else "%d ponto de atributo confirmado.", [total])
	last_notice_context = "attributes"
	save_game()
	changed.emit()
	return true


func select_class(class_id: String) -> bool:
	if phase != Phase.BOARD or class_id.is_empty() or not ClassRules.is_valid(class_id):
		return false
	player.class_id = class_id
	last_notice = LocaleRulesScript.text("ONB_NOTICE_CLASS", "Classe confirmada: %s. Especialização recalculada.", [ClassRules.class_name_for(class_id)])
	last_notice_context = "class"
	CoreRules.clear_bounty_odds_cache()
	save_game()
	changed.emit()
	return true


func abandon_bounty() -> void:
	if phase == Phase.HUNT or phase == Phase.HUNT_EVENT:
		var lost_streak := int(player.get("capture_streak", 0))
		player.capture_streak = 0
		phase = Phase.BOARD
		current_bounty = {}
		offered_approaches = []
		hunt_event = {}
		var captures_suffix := LocaleRulesScript.text("ABANDON_CAPTURE_SUFFIX", " após %d capturas", [lost_streak]) if lost_streak > 0 else ""
		last_notice = LocaleRulesScript.text("ABANDON_NOTICE", "Contrato abandonado%s. O embalo foi perdido.", [captures_suffix])
		last_notice_context = "contract"
		save_game()
		changed.emit()


func reset_progress() -> void:
	save_recovery_required = false
	mission_ready_feedback_pending = false
	account = {}
	player = default_player()
	phase = Phase.BOARD
	current_bounty = {}
	pending_loot = {}
	offered_approaches = []
	hunt_event = {}
	chapter_completion = {}
	afk_report = {}
	combat_summary = {}
	last_notice = LocaleRulesScript.text("RESET_NOTICE", "Progresso reiniciado. Hora de construir uma nova reputação.")
	last_notice_context = "system"
	save_game()
	changed.emit()


func save_game() -> bool:
	if not persistence_enabled:
		return true
	if save_recovery_required:
		return false
	player.last_seen_unix = maxf(float(player.get("last_seen_unix", 0.0)), Time.get_unix_time_from_system())
	if not account.is_empty() and str(player.get("character_id", "")).is_empty():
		player.character_id = AccountRulesScript.LOCAL_CHARACTER_ID
	var canonical_account := account_service.canonicalize_account(account, str(player.get("character_id", ""))) if not account.is_empty() else {}
	if not account.is_empty() and (canonical_account.is_empty() or not account_service.session_ready(canonical_account) or not account_service.owns_character(canonical_account, str(player.character_id))):
		save_warning = LocaleRulesScript.text("SAVE_WARNING_ACCOUNT", "PROGRESSO AINDA NÃO SALVO · o vínculo local entre conta e personagem é inválido. Mantenha o jogo aberto e tente novamente.")
		return false
	var committed_account := account_service.prepare_local_commit(canonical_account)
	var payload := {
		"version": SAVE_VERSION,
		"account": committed_account,
		"player": player,
		"phase": int(phase),
		"current_bounty": current_bounty,
		"offered_approaches": offered_approaches,
		"pending_loot": pending_loot,
		"hunt_started_at": hunt_started_at,
		"hunt_ends_at": hunt_ends_at,
		"hunt_event": hunt_event,
		"hunt_event_triggered": hunt_event_triggered,
		"hunt_elapsed_before_event": hunt_elapsed_before_event,
		"hunt_remaining_after_event": hunt_remaining_after_event,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"combat_round": combat_round,
		"combat_events": combat_events,
		"combat_summary": combat_summary,
		"chapter_completion": chapter_completion,
	}
	var staging_path := "%s.tmp" % save_path
	var backup_path := "%s.bak" % save_path
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		save_warning = LocaleRulesScript.text("SAVE_WARNING_STORAGE", "PROGRESSO AINDA NÃO SALVO · armazenamento local indisponível. Mantenha o jogo aberto e tente novamente.")
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	if file.get_error() != OK:
		save_warning = LocaleRulesScript.text("SAVE_WARNING_WRITE", "PROGRESSO AINDA NÃO SALVO · falha ao gravar no armazenamento local. Mantenha o jogo aberto e tente novamente.")
		return false
	file = null
	var primary_absolute := ProjectSettings.globalize_path(save_path)
	var staging_absolute := ProjectSettings.globalize_path(staging_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_absolute)
		if DirAccess.rename_absolute(primary_absolute, backup_absolute) != OK:
			save_warning = LocaleRulesScript.text("SAVE_WARNING_PREPARE", "PROGRESSO AINDA NÃO SALVO · não foi possível preparar a substituição segura. Mantenha o jogo aberto e tente novamente.")
			return false
	if DirAccess.rename_absolute(staging_absolute, primary_absolute) != OK:
		if not FileAccess.file_exists(save_path) and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, primary_absolute)
		save_warning = LocaleRulesScript.text("SAVE_WARNING_COMMIT", "PROGRESSO AINDA NÃO SALVO · não foi possível concluir a substituição segura. Mantenha o jogo aberto e tente novamente.")
		return false
	# The backup mirrors the latest committed transaction. A corrupt primary can
	# therefore never resurrect a claimed reward or paid incident from one save ago.
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	DirAccess.copy_absolute(primary_absolute, backup_absolute)
	account = committed_account
	save_warning = ""
	return true


func retry_save() -> bool:
	var saved := save_game()
	changed.emit()
	return saved


func start_fresh_after_corruption() -> bool:
	if not save_recovery_required:
		return false
	var source_paths: Array[String] = []
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		if FileAccess.file_exists(path):
			source_paths.append(path)
	var quarantine_id := int(Time.get_unix_time_from_system() * 1000.0)
	var suffix := ".corrupt.%d" % quarantine_id
	while source_paths.any(func(path): return FileAccess.file_exists("%s%s" % [path, suffix])):
		quarantine_id += 1
		suffix = ".corrupt.%d" % quarantine_id
	for path in source_paths:
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path("%s%s" % [path, suffix]))
		if copy_error != OK:
			save_warning = LocaleRulesScript.text("SAVE_WARNING_QUARANTINE", "SAVE DANIFICADO PRESERVADO · não foi possível criar a cópia de segurança para iniciar novamente.")
			changed.emit()
			return false
	for path in source_paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	reset_progress()
	if save_warning.is_empty():
		prune_corrupt_artifacts(2)
	return save_warning.is_empty()


func prune_corrupt_artifacts(keep_per_source: int) -> void:
	for source_path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		var absolute_source := ProjectSettings.globalize_path(source_path)
		var directory_path := absolute_source.get_base_dir()
		var prefix := "%s.corrupt." % absolute_source.get_file()
		var directory := DirAccess.open(directory_path)
		if directory == null:
			continue
		var matches: Array[String] = []
		for filename in directory.get_files():
			if filename.begins_with(prefix):
				matches.append(filename)
		matches.sort()
		while matches.size() > maxi(0, keep_per_source):
			DirAccess.remove_absolute(directory_path.path_join(matches.pop_front()))


func load_game() -> void:
	last_notice = ""
	last_notice_context = ""
	afk_report = {}
	save_warning = ""
	save_recovery_required = false
	mission_ready_feedback_pending = false
	player = default_player()
	account = {}
	phase = Phase.BOARD
	current_bounty = {}
	offered_approaches = []
	pending_loot = {}
	hunt_event = {}
	chapter_completion = {}
	combat_events = []
	combat_summary = {}
	var save_family_exists := FileAccess.file_exists(save_path) or FileAccess.file_exists("%s.tmp" % save_path) or FileAccess.file_exists("%s.bak" % save_path)
	# A fully flushed staging file means promotion was interrupted or blocked; it
	# is newer than both committed copies and must win recovery precedence.
	var parsed: Dictionary = read_save_dictionary("%s.tmp" % save_path)
	var recovered_from_copy := not parsed.is_empty()
	if parsed.is_empty():
		parsed = read_save_dictionary(save_path)
	if parsed.is_empty():
		parsed = read_save_dictionary("%s.bak" % save_path)
		recovered_from_copy = not parsed.is_empty()
	if parsed.is_empty():
		if save_family_exists:
			save_recovery_required = true
			save_warning = LocaleRulesScript.text("SAVE_WARNING_CORRUPT", "SAVE LOCAL DANIFICADO · nenhuma cópia íntegra foi encontrada. O arquivo original será preservado antes de iniciar um novo progresso.")
		return
	if recovered_from_copy and FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var requires_migration_save := int(parsed.get("version", 0)) < SAVE_VERSION
	parsed = migrate_save_payload(parsed)
	if parsed.is_empty():
		return
	var loaded_account = parsed.get("account", {})
	var loaded_player = parsed.get("player", {})
	var player_repaired := false
	if loaded_player is Dictionary:
		var sanitized_player := sanitize_loaded_player(loaded_player)
		player = sanitized_player.player
		player_repaired = bool(sanitized_player.repaired)
		# Saves created before per-planet progression inherit their existing Dustball victories.
		if not loaded_player.has("captures_by_planet") and int(player.wins) > 0:
			player.captures_by_planet = {ContentDB.PLANET.id: int(player.wins)}
	else:
		player_repaired = true
	account = sanitize_loaded_account(loaded_account, str(player.get("character_id", "")))
	if account_session_ready():
		TranslationServer.set_locale(str(account.locale_id))
	var phase_payload_repaired := false
	phase = int(parsed.get("phase", Phase.BOARD))
	var loaded_bounty = parsed.get("current_bounty", {})
	current_bounty = {}
	if loaded_bounty is Dictionary:
		var bounty_result := canonicalize_loaded_bounty(loaded_bounty)
		current_bounty = bounty_result.bounty
		phase_payload_repaired = bool(bounty_result.repaired)
	else:
		phase_payload_repaired = true
	var loaded_approaches = parsed.get("offered_approaches", [])
	offered_approaches.clear()
	if loaded_approaches is Array and not loaded_approaches.is_empty():
		offered_approaches.assign(ContentDB.contract_approaches())
		if not payloads_equivalent(loaded_approaches, offered_approaches):
			phase_payload_repaired = true
	elif not loaded_approaches is Array:
		phase_payload_repaired = true
	var loaded_loot = parsed.get("pending_loot", {})
	pending_loot = loaded_loot.duplicate(true) if loaded_loot is Dictionary else {}
	if not loaded_loot is Dictionary:
		phase_payload_repaired = true
	elif not pending_loot.is_empty():
		if loaded_equipment_is_safe(pending_loot, str(pending_loot.get("slot", ""))):
			phase_payload_repaired = sanitize_loaded_equipment(pending_loot) or phase_payload_repaired
		else:
			pending_loot = {}
			phase_payload_repaired = true
	hunt_started_at = float(parsed.get("hunt_started_at", 0.0))
	hunt_ends_at = float(parsed.get("hunt_ends_at", 0.0))
	var loaded_hunt_event = parsed.get("hunt_event", {})
	hunt_event = {}
	if loaded_hunt_event is Dictionary and not loaded_hunt_event.is_empty():
		for definition in ContentDB.HUNT_EVENTS:
			if str(definition.id) == str(loaded_hunt_event.get("id", "")):
				hunt_event = definition.duplicate(true)
				break
		if hunt_event.is_empty() or not payloads_equivalent(hunt_event, loaded_hunt_event):
			phase_payload_repaired = true
	elif not loaded_hunt_event is Dictionary:
		phase_payload_repaired = true
	hunt_event_triggered = bool(parsed.get("hunt_event_triggered", false))
	hunt_elapsed_before_event = float(parsed.get("hunt_elapsed_before_event", 0.0))
	hunt_remaining_after_event = float(parsed.get("hunt_remaining_after_event", 0.0))
	player_hp = int(parsed.get("player_hp", 0))
	enemy_hp = int(parsed.get("enemy_hp", 0))
	combat_round = int(parsed.get("combat_round", 0))
	var loaded_events = parsed.get("combat_events", [])
	var event_result := sanitize_loaded_combat_events(loaded_events)
	combat_events.assign(event_result.events)
	phase_payload_repaired = bool(event_result.repaired) or phase_payload_repaired
	var loaded_summary = parsed.get("combat_summary", {})
	combat_summary = {}
	if loaded_summary is Dictionary and not loaded_summary.is_empty():
		var summary_result := canonicalize_loaded_combat_summary(loaded_summary)
		combat_summary = summary_result.summary
		phase_payload_repaired = bool(summary_result.repaired) or phase_payload_repaired
	elif not loaded_summary is Dictionary:
		phase_payload_repaired = true
	var loaded_chapter = parsed.get("chapter_completion", {})
	chapter_completion = {}
	if loaded_chapter is Dictionary and not loaded_chapter.is_empty():
		var chapter_result := canonicalize_loaded_chapter(loaded_chapter)
		chapter_completion = chapter_result.chapter
		phase_payload_repaired = bool(chapter_result.repaired) or phase_payload_repaired
	elif not loaded_chapter is Dictionary:
		phase_payload_repaired = true
	var repaired_phase_state := reconcile_loaded_phase()
	var repaired_phase := player_repaired or phase_payload_repaired or repaired_phase_state
	var offline_rewards := apply_offline_progress(Time.get_unix_time_from_system())
	if int(offline_rewards.credits) > 0 or int(offline_rewards.scrap) > 0:
		# Persist immediately so an abrupt close cannot claim the same patrol twice.
		save_game()
	if (phase == Phase.HUNT or phase == Phase.HUNT_EVENT) and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat(true)
	elif phase == Phase.COMBAT:
		# Combat resumes safely from its saved health values.
		player_hp = maxi(1, player_hp)
		enemy_hp = maxi(1, enemy_hp)
	if recovered_from_copy:
		last_notice = LocaleRulesScript.text("SAVE_NOTICE_RESTORED", "SAVE RECUPERADO: a última cópia íntegra foi restaurada sem repetir transações.")
		last_notice_context = "system_recovery"
	elif requires_migration_save:
		last_notice = LocaleRulesScript.text("SAVE_NOTICE_MIGRATED", "SAVE ATUALIZADO: progresso legado preservado e registros ausentes reconstruídos.")
		last_notice_context = "system_recovery"
	elif repaired_phase:
		last_notice = LocaleRulesScript.text("SAVE_NOTICE_REPAIRED", "SAVE RECUPERADO: progresso válido preservado; registros inconsistentes foram isolados.")
		last_notice_context = "system_recovery"
	if recovered_from_copy or requires_migration_save or repaired_phase:
		save_game()


func read_save_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		file = null
		return {}
	var parsed = parser.data
	file = null
	return parsed if parsed is Dictionary else {}


func sanitize_loaded_player(loaded: Dictionary) -> Dictionary:
	var sanitized := default_player()
	var repaired := false
	for key in sanitized:
		if not loaded.has(key):
			repaired = true
			continue
		var incoming = loaded[key]
		var expected = sanitized[key]
		var compatible := typeof(incoming) == typeof(expected)
		if (expected is int or expected is float) and (incoming is int or incoming is float):
			compatible = true
		if compatible:
			sanitized[key] = int(incoming) if expected is int else (float(incoming) if expected is float else incoming)
		else:
			repaired = true
	for slot in CoreRules.EQUIPMENT_SLOTS:
		var fallback: Dictionary = default_player()[slot]
		var loaded_item = loaded.get(slot, {})
		if fallback.is_empty() and loaded_item is Dictionary and loaded_item.is_empty():
			sanitized[slot] = {}
			continue
		if loaded_item is Dictionary:
			var item := fallback.duplicate(true)
			for key in loaded_item:
				item[key] = loaded_item[key]
			item.slot = slot
			if not loaded_equipment_is_safe(item, slot):
				sanitized[slot] = fallback
				repaired = true
			else:
				repaired = sanitize_loaded_equipment(item) or repaired
				sanitized[slot] = item
		else:
			sanitized[slot] = fallback
			repaired = true
	var clean_inventory: Array = []
	var loaded_inventory = loaded.get("inventory", [])
	if loaded_inventory is Array:
		for entry in loaded_inventory:
			if entry is Dictionary and loaded_equipment_is_safe(entry, str(entry.get("slot", ""))):
				var clean_entry: Dictionary = entry.duplicate(true)
				repaired = sanitize_loaded_equipment(clean_entry) or repaired
				clean_inventory.append(clean_entry)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.inventory = clean_inventory
	var clean_loadouts := [default_loadout(), default_loadout()]
	var loaded_loadouts = loaded.get("equipment_loadouts", [])
	if loaded_loadouts is Array:
		for index in mini(2, loaded_loadouts.size()):
			if loaded_loadouts[index] is Dictionary:
				for slot in CoreRules.EQUIPMENT_SLOTS:
					var id_key := "%s_id" % slot
					clean_loadouts[index][id_key] = str(loaded_loadouts[index].get(id_key, ""))
			else:
				repaired = true
		if loaded_loadouts.size() != 2:
			repaired = true
	else:
		repaired = true
	sanitized.equipment_loadouts = clean_loadouts
	for key in ["xp", "credits", "warp_chips", "scrap", "scrap_recycled_total", "afk_credits_earned", "afk_scrap_earned", "career_credits_claimed", "career_scrap_claimed", "capture_streak", "best_capture_streak", "reputation", "wins", "stat_points", "challenge_floor"]:
		if int(sanitized[key]) < 0:
			sanitized[key] = 0
			repaired = true
	for key in ["level", "base_power"]:
		if int(sanitized[key]) < 1:
			sanitized[key] = 1
			repaired = true
	var clean_challenge_floor := clampi(int(sanitized.get("challenge_floor", 0)), 0, ChallengeRulesScript.STAGES.size())
	if clean_challenge_floor != int(sanitized.get("challenge_floor", 0)):
		sanitized.challenge_floor = clean_challenge_floor
		repaired = true
	var clean_attributes := CoreRules.default_attributes()
	var loaded_attributes = loaded.get("attributes", {})
	if loaded_attributes is Dictionary:
		for attribute_id in CoreRules.ATTRIBUTE_KEYS:
			if not loaded_attributes.has(attribute_id):
				repaired = true
				continue
			var value = loaded_attributes.get(attribute_id, CoreRules.BASE_ATTRIBUTE_VALUE)
			if not (value is int or value is float) or float(value) != float(int(value)) or int(value) < CoreRules.BASE_ATTRIBUTE_VALUE:
				repaired = true
				continue
			clean_attributes[attribute_id] = int(value)
		if loaded_attributes.size() != CoreRules.ATTRIBUTE_KEYS.size():
			repaired = true
	else:
		repaired = true
	sanitized.attributes = clean_attributes
	var market_cycle = sanitized.get("market_cycle", 0)
	if not (market_cycle is int or market_cycle is float) or float(market_cycle) != float(int(market_cycle)) or int(market_cycle) < 0 or int(market_cycle) > 1000000:
		sanitized.market_cycle = clampi(int(market_cycle) if market_cycle is int or market_cycle is float else 0, 0, 1000000)
		repaired = true
	var market_refresh_count := clampi(int(sanitized.get("market_refresh_count", 0)), 0, MonetizationRulesScript.MAX_MARKET_REFRESHES_PER_DAY)
	if market_refresh_count != int(sanitized.get("market_refresh_count", 0)):
		sanitized.market_refresh_count = market_refresh_count
		repaired = true
	var fuel_refills := clampi(int(sanitized.get("hunt_fuel_refill_count", 0)), 0, MonetizationRulesScript.MAX_HUNT_FUEL_REFILLS_PER_DAY)
	if fuel_refills != int(sanitized.get("hunt_fuel_refill_count", 0)):
		sanitized.hunt_fuel_refill_count = fuel_refills
		repaired = true
	var maximum_fuel := MonetizationRulesScript.DAILY_HUNT_FUEL + fuel_refills * MonetizationRulesScript.HUNT_FUEL_REFILL_AMOUNT
	var fuel_remaining := clampi(int(sanitized.get("hunt_fuel", MonetizationRulesScript.DAILY_HUNT_FUEL)), 0, maximum_fuel)
	if fuel_remaining != int(sanitized.get("hunt_fuel", MonetizationRulesScript.DAILY_HUNT_FUEL)):
		sanitized.hunt_fuel = fuel_remaining
		repaired = true
	for day_key in ["economy_day", "daily_hunt_chip_day", "rift_entry_day"]:
		var day_value = sanitized.get(day_key, -1)
		if not (day_value is int or day_value is float) or float(day_value) != float(int(day_value)) or int(day_value) < -1:
			sanitized[day_key] = -1
			repaired = true
	var valid_rift_keys: Array[String] = []
	for reality in ChallengeRulesScript.REALITIES:
		valid_rift_keys.append(str(reality.key_id))
	var clean_rift_keys: Array = []
	var loaded_rift_keys = sanitized.get("rift_reality_keys", [])
	if loaded_rift_keys is Array:
		for key_id in loaded_rift_keys:
			var resolved_key := str(key_id)
			if valid_rift_keys.has(resolved_key) and not clean_rift_keys.has(resolved_key):
				clean_rift_keys.append(resolved_key)
			else:
				repaired = true
	else:
		repaired = true
	for key_id in ChallengeRulesScript.initial_key_ids(sanitized):
		if not clean_rift_keys.has(key_id):
			clean_rift_keys.append(key_id)
			# The first key is derived directly from hunter level. Treating this
			# normalization as corruption would show a false recovery warning when
			# an established save crosses the unlock boundary outside the Rift UI.
	sanitized.rift_reality_keys = clean_rift_keys
	var clean_rift_progress := {}
	var loaded_rift_progress = sanitized.get("rift_reality_progress", {})
	if loaded_rift_progress is Dictionary:
		for reality in ChallengeRulesScript.REALITIES:
			var reality_id := str(reality.id)
			if not clean_rift_keys.has(str(reality.key_id)):
				continue
			var legacy_floor := int(sanitized.challenge_floor) if reality_id == ChallengeRulesScript.FIRST_REALITY_ID else 0
			var clean_floor := clampi(int(loaded_rift_progress.get(reality_id, legacy_floor)), 0, reality.stages.size())
			clean_rift_progress[reality_id] = clean_floor
			if loaded_rift_progress.has(reality_id) and clean_floor != int(loaded_rift_progress[reality_id]):
				repaired = true
		for reality_id in loaded_rift_progress:
			if not ChallengeRulesScript.reality_ids().has(str(reality_id)):
				repaired = true
	else:
		repaired = true
	sanitized.rift_reality_progress = clean_rift_progress
	if clean_rift_progress.has(ChallengeRulesScript.FIRST_REALITY_ID):
		sanitized.challenge_floor = int(clean_rift_progress[ChallengeRulesScript.FIRST_REALITY_ID])
	var selected_reality := str(sanitized.get("selected_rift_reality_id", ChallengeRulesScript.FIRST_REALITY_ID))
	var selected_requires_repair := not ChallengeRulesScript.reality_ids().has(selected_reality)
	selected_requires_repair = selected_requires_repair or (not ChallengeRulesScript.has_reality_key(sanitized, selected_reality) and (selected_reality != ChallengeRulesScript.FIRST_REALITY_ID or ChallengeRulesScript.is_unlocked(sanitized)))
	if selected_requires_repair:
		sanitized.selected_rift_reality_id = ChallengeRulesScript.FIRST_REALITY_ID
		repaired = true
	var clean_key_hunt_progress := {}
	var loaded_key_hunt_progress = sanitized.get("rift_key_hunt_progress", {})
	if loaded_key_hunt_progress is Dictionary:
		for reality_id in loaded_key_hunt_progress:
			if ChallengeRulesScript.reality_ids().has(str(reality_id)):
				clean_key_hunt_progress[str(reality_id)] = clampi(int(loaded_key_hunt_progress[reality_id]), 0, 1000)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.rift_key_hunt_progress = clean_key_hunt_progress
	if not MarketRulesScript.purchase_records_are_safe(sanitized.get("market_purchased_offer_ids", [])):
		sanitized.market_purchased_offer_ids = []
		repaired = true
	var known_collection_ids := {}
	for collection_id in ContentDB.procedural_collection_ids():
		known_collection_ids[collection_id] = true
	var clean_discoveries: Array = []
	var loaded_discoveries = sanitized.get("discovered_item_variant_ids", [])
	if loaded_discoveries is Array:
		for collection_id in loaded_discoveries:
			var id := str(collection_id)
			if known_collection_ids.has(id) and not clean_discoveries.has(id):
				clean_discoveries.append(id)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.discovered_item_variant_ids = clean_discoveries
	var valid_collection_milestones := CollectionRulesScript.valid_milestone_ids(ContentDB.procedural_collection_total())
	var clean_collection_claims: Array = []
	var loaded_collection_claims = sanitized.get("claimed_collection_milestones", [])
	if loaded_collection_claims is Array:
		for milestone_id in loaded_collection_claims:
			var id := str(milestone_id)
			if valid_collection_milestones.has(id) and not clean_collection_claims.has(id):
				clean_collection_claims.append(id)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.claimed_collection_milestones = clean_collection_claims
	var daily_hunts := clampi(int(sanitized.get("daily_hunts_completed", 0)), 0, 1000)
	if daily_hunts != int(sanitized.get("daily_hunts_completed", 0)):
		sanitized.daily_hunts_completed = daily_hunts
		repaired = true
	var clean_daily_claims: Array = []
	var loaded_daily_claims = sanitized.get("claimed_daily_objectives", [])
	if loaded_daily_claims is Array:
		for objective_id in loaded_daily_claims:
			var id := str(objective_id)
			if DailyObjectiveRulesScript.valid_claim_ids().has(id) and not clean_daily_claims.has(id):
				clean_daily_claims.append(id)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.claimed_daily_objectives = clean_daily_claims
	var weekly_hunts := clampi(int(sanitized.get("weekly_hunts_completed", 0)), 0, 10000)
	if weekly_hunts != int(sanitized.get("weekly_hunts_completed", 0)):
		sanitized.weekly_hunts_completed = weekly_hunts
		repaired = true
	var clean_weekly_claims: Array = []
	var loaded_weekly_claims = sanitized.get("claimed_weekly_objectives", [])
	if loaded_weekly_claims is Array:
		for objective_id in loaded_weekly_claims:
			var id := str(objective_id)
			if WeeklyOperationRulesScript.valid_claim_ids().has(id) and not clean_weekly_claims.has(id):
				clean_weekly_claims.append(id)
			else:
				repaired = true
	else:
		repaired = true
	sanitized.claimed_weekly_objectives = clean_weekly_claims
	var loaded_weekly_cycle = sanitized.get("weekly_cycle_id", -1)
	if not (loaded_weekly_cycle is int or loaded_weekly_cycle is float) or int(loaded_weekly_cycle) < -1:
		sanitized.weekly_cycle_id = -1
		repaired = true
	if not sanitized.get("weekly_special_completed", false) is bool:
		sanitized.weekly_special_completed = false
		repaired = true
	var expected_route_ids := WeeklyOperationRulesScript.rotating_planet_ids(sanitized, int(sanitized.get("weekly_cycle_id", -1)))
	var clean_route_ids: Array = []
	var loaded_route_ids = sanitized.get("weekly_route_planet_ids", [])
	if loaded_route_ids is Array:
		for route_id in loaded_route_ids:
			var id := str(route_id)
			if expected_route_ids.has(id) and not clean_route_ids.has(id):
				clean_route_ids.append(id)
			else:
				repaired = true
	else:
		repaired = true
	if not clean_route_ids.is_empty() and clean_route_ids != expected_route_ids:
		clean_route_ids = expected_route_ids
		repaired = true
	sanitized.weekly_route_planet_ids = clean_route_ids
	var clean_route_captures := {}
	var loaded_route_captures = sanitized.get("weekly_route_captures", {})
	if loaded_route_captures is Dictionary:
		for route_id_value in loaded_route_captures:
			var route_id := str(route_id_value)
			var value = loaded_route_captures[route_id_value]
			if not clean_route_ids.has(route_id) or not (value is int or value is float):
				repaired = true
				continue
			var count := clampi(int(value), 0, WeeklyOperationRulesScript.ROUTE_PLANET_QUOTA)
			if count != int(value) or count <= 0:
				repaired = true
				continue
			clean_route_captures[route_id] = count
	else:
		repaired = true
	sanitized.weekly_route_captures = clean_route_captures
	if not sanitized.get("weekly_route_claimed", false) is bool:
		sanitized.weekly_route_claimed = false
		repaired = true
	var loaded_weekly_target := str(sanitized.get("weekly_special_target_id", ""))
	var valid_weekly_targets := WeeklyOperationRulesScript.eligible_special_targets(sanitized).map(func(entry): return str(entry.id))
	if not loaded_weekly_target.is_empty() and not valid_weekly_targets.has(loaded_weekly_target):
		sanitized.weekly_special_target_id = ""
		repaired = true
	if not ClassRules.is_valid(str(sanitized.get("class_id", ""))):
		sanitized.class_id = ""
		repaired = true
	var species_id := str(sanitized.get("species_id", ""))
	if not species_id.is_empty() and not SpeciesRulesScript.is_valid(species_id):
		sanitized.species_id = ""
		repaired = true
	var clean_appearance := AppearanceRulesScript.sanitize(sanitized.get("appearance", {}))
	if AppearanceRulesScript.is_complete(sanitized.get("appearance", {})):
		sanitized.appearance = clean_appearance
	elif not str(sanitized.get("hunter_name", "")).is_empty() and SpeciesRulesScript.is_valid(str(sanitized.get("species_id", ""))):
		sanitized.appearance = clean_appearance
		repaired = true
	else:
		sanitized.appearance = {}
	var clean_hunter_name := normalized_hunter_name(str(sanitized.get("hunter_name", "")))
	if clean_hunter_name != str(sanitized.get("hunter_name", "")):
		sanitized.hunter_name = clean_hunter_name
		repaired = true
	if int(sanitized.best_capture_streak) < int(sanitized.capture_streak):
		sanitized.best_capture_streak = int(sanitized.capture_streak)
		repaired = true
	var known_target_ids := {}
	for target in ContentDB.TARGETS:
		known_target_ids[str(target.id)] = true
	var known_planet_ids := {}
	for planet in ContentDB.PLANETS:
		known_planet_ids[str(planet.id)] = true
	for key in ["captures_by_target", "captures_by_planet"]:
		var clean_counts := {}
		var known_ids: Dictionary = known_target_ids if key == "captures_by_target" else known_planet_ids
		for record_id in sanitized[key]:
			var value = sanitized[key][record_id]
			if not known_ids.has(str(record_id)) or not (value is int or value is float):
				repaired = true
				continue
			clean_counts[str(record_id)] = maxi(0, int(value))
			if int(value) < 0:
				repaired = true
		sanitized[key] = clean_counts
	var clean_completed: Array = []
	for planet in ContentDB.PLANETS:
		if sanitized.completed_planets.has(str(planet.id)):
			clean_completed.append(str(planet.id))
	if clean_completed.size() != sanitized.completed_planets.size():
		repaired = true
	sanitized.completed_planets = clean_completed
	var clean_seen: Array = []
	var loaded_seen = sanitized.get("seen_planet_ids", [])
	if loaded_seen is Array:
		for planet in ContentDB.PLANETS:
			var planet_id := str(planet.id)
			if loaded_seen.has(planet_id) and MissionRulesScript.is_planet_available(planet_id, int(sanitized.get("level", 1))):
				clean_seen.append(planet_id)
		if clean_seen.size() != loaded_seen.size():
			repaired = true
	else:
		repaired = true
	if not clean_seen.has(str(ContentDB.PLANET.id)):
		clean_seen.push_front(str(ContentDB.PLANET.id))
		repaired = true
	sanitized.seen_planet_ids = clean_seen
	if int(sanitized.challenge_floor) > 0 and not ChallengeRulesScript.is_unlocked(sanitized):
		sanitized.challenge_floor = 0
		repaired = true
	var current_planet_id := str(sanitized.current_planet_id)
	if not known_planet_ids.has(current_planet_id) or not MissionRulesScript.is_planet_available(current_planet_id, int(sanitized.get("level", 1))):
		current_planet_id = str(ContentDB.PLANET.id)
		for planet in ContentDB.PLANETS:
			if MissionRulesScript.is_planet_available(str(planet.id), int(sanitized.get("level", 1))):
				current_planet_id = str(planet.id)
		sanitized.current_planet_id = current_planet_id
		repaired = true
	var clean_transport_ids: Array = []
	var loaded_transport_ids = sanitized.get("owned_transport_ids", [])
	if loaded_transport_ids is Array:
		for transport in TransportRulesScript.DEFINITIONS:
			var transport_id := str(transport.id)
			if loaded_transport_ids.has(transport_id) and TransportRulesScript.is_unlocked(sanitized, transport):
				clean_transport_ids.append(transport_id)
		if clean_transport_ids.size() != loaded_transport_ids.size():
			repaired = true
	else:
		repaired = true
	sanitized.owned_transport_ids = clean_transport_ids
	var active_transport_id := str(sanitized.get("active_transport_id", ""))
	if not active_transport_id.is_empty() and not clean_transport_ids.has(active_transport_id):
		sanitized.active_transport_id = ""
		repaired = true
	var known_milestone_ids := {}
	for milestone in CareerRules.milestones(sanitized):
		known_milestone_ids[str(milestone.id)] = true
	var clean_claimed: Array = []
	for milestone_id in sanitized.claimed_milestones:
		if known_milestone_ids.has(str(milestone_id)) and not clean_claimed.has(str(milestone_id)):
			clean_claimed.append(str(milestone_id))
		else:
			repaired = true
	sanitized.claimed_milestones = clean_claimed
	var owned_item_ids := {}
	for slot in CoreRules.EQUIPMENT_SLOTS:
		var equipped_id := str(sanitized.get(slot, {}).get("id", ""))
		if not equipped_id.is_empty():
			owned_item_ids[equipped_id] = true
	for item in sanitized.inventory:
		owned_item_ids[str(item.id)] = true
	var clean_locked_ids: Array = []
	for item_id in sanitized.locked_item_ids:
		if owned_item_ids.has(str(item_id)) and not clean_locked_ids.has(str(item_id)):
			clean_locked_ids.append(str(item_id))
		else:
			repaired = true
	sanitized.locked_item_ids = clean_locked_ids
	for loadout in sanitized.equipment_loadouts:
		for slot in CoreRules.EQUIPMENT_SLOTS:
			var id_key := "%s_id" % slot
			if not str(loadout[id_key]).is_empty() and not owned_item_ids.has(str(loadout[id_key])):
				loadout[id_key] = ""
				repaired = true
	return {"player": sanitized, "repaired": repaired}


func sanitize_loaded_account(loaded, character_id := "") -> Dictionary:
	if not loaded is Dictionary:
		return {}
	var canonical := account_service.canonicalize_account(loaded, character_id)
	if canonical.is_empty() or not account_service.session_ready(canonical):
		return {}
	if str(canonical.get("provider_id", "")) != AccountRulesScript.LOCAL_PROVIDER_ID or str(canonical.get("account_id", "")).is_empty() or str(canonical.get("account_id", "")).length() > 64:
		return {}
	if not ServerRulesScript.is_valid(str(canonical.get("server_id", ""))) or not LocaleRulesScript.is_selectable(str(canonical.get("locale_id", ""))):
		return {}
	if not account_service.owns_character(canonical, character_id):
		return {}
	return canonical


func canonicalize_loaded_bounty(loaded: Dictionary) -> Dictionary:
	if loaded.is_empty():
		return {"bounty": {}, "repaired": false}
	var canonical_target := MissionRulesScript.canonical_offer(loaded) if bool(loaded.get("mission_offer", false)) else (ChallengeRulesScript.get_stage(str(loaded.get("id", ""))) if bool(loaded.get("challenge", false)) else {})
	for target in ContentDB.TARGETS:
		if not canonical_target.is_empty():
			break
		if str(target.id) == str(loaded.get("id", "")):
			canonical_target = target.duplicate(true)
			break
	if canonical_target.is_empty():
		return {"bounty": {}, "repaired": true}
	var bounty: Dictionary = canonical_target
	var loaded_approach = loaded.get("approach", {})
	if loaded_approach is Dictionary and not loaded_approach.is_empty():
		var canonical_approach := ContentDB.canonical_loaded_approach(loaded_approach)
		if not canonical_approach.is_empty():
			bounty = ContentDB.apply_approach(bounty, canonical_approach)
	var choice_id := str(loaded.get("hunt_event_choice_id", ""))
	var result_text := str(loaded.get("hunt_event_result", ""))
	if not choice_id.is_empty() or not result_text.is_empty():
		for event in ContentDB.HUNT_EVENTS:
			for choice in event.choices:
				if (not choice_id.is_empty() and str(choice.id) == choice_id) or (choice_id.is_empty() and str(choice.result) == result_text):
					bounty = ContentDB.apply_hunt_choice(bounty, choice)
					choice_id = str(choice.id)
					break
			if str(bounty.get("hunt_event_choice_id", "")) == choice_id and not choice_id.is_empty():
				break
	var loaded_field_context = loaded.get("field_test_context", {})
	if loaded_field_context is Dictionary and not loaded_field_context.is_empty():
		var clean_field_context := canonicalize_loaded_field_context(loaded_field_context)
		if not clean_field_context.is_empty():
			bounty.field_test_context = clean_field_context
	return {"bounty": bounty, "repaired": not payloads_equivalent(bounty, loaded)}


func canonicalize_loaded_field_context(loaded: Dictionary) -> Dictionary:
	var tested_approach := ContentDB.contract_approaches().filter(func(approach): return str(approach.id) == str(loaded.get("tested_approach_id", "")))
	var chosen_approach := ContentDB.contract_approaches().filter(func(approach): return str(approach.id) == str(loaded.get("chosen_approach_id", "")))
	if tested_approach.is_empty() or chosen_approach.is_empty():
		return {}
	return {
		"tested_approach_id": str(tested_approach[0].id),
		"tested_approach_name": str(tested_approach[0].name),
		"tested_odds": clampf(float(loaded.get("tested_odds", 0.0)), 0.0, 1.0),
		"chosen_approach_id": str(chosen_approach[0].id),
		"chosen_approach_name": str(chosen_approach[0].name),
		"overridden": str(tested_approach[0].id) != str(chosen_approach[0].id),
	}


func canonicalize_loaded_combat_summary(loaded: Dictionary) -> Dictionary:
	var target := ContentDB.TARGETS.filter(func(definition): return str(definition.id) == str(loaded.get("target_id", "")))
	if target.is_empty():
		var challenge_target := ChallengeRulesScript.get_stage(str(loaded.get("target_id", "")))
		if not challenge_target.is_empty():
			target = [challenge_target]
	if target.is_empty():
		return {"summary": {}, "repaired": true}
	var definition: Dictionary = target[0]
	var target_max := int(current_bounty.get("health", definition.health)) if str(current_bounty.get("id", "")) == str(definition.id) else int(definition.health)
	var summary := {
		"target_id": str(definition.id),
		"target_name": str(definition.name),
		"class_id": str(loaded.get("class_id", player.get("class_id", ""))) if ClassRules.is_valid(str(loaded.get("class_id", player.get("class_id", "")))) else str(player.get("class_id", "")),
		"rounds": maxi(0, int(loaded.get("rounds", 0))),
		"damage_dealt": maxi(0, int(loaded.get("damage_dealt", 0))),
		"damage_taken": maxi(0, int(loaded.get("damage_taken", 0))),
		"damage_prevented": maxi(0, int(loaded.get("damage_prevented", 0))),
		"critical_hits": maxi(0, int(loaded.get("critical_hits", 0))),
		"opening_bonus": maxi(0, int(loaded.get("opening_bonus", 0))),
		"counter_damage": maxi(0, int(loaded.get("counter_damage", 0))),
		"follow_up_damage": maxi(0, int(loaded.get("follow_up_damage", 0))),
		"dodges": maxi(0, int(loaded.get("dodges", 0))),
		"defense_bypassed": maxi(0, int(loaded.get("defense_bypassed", 0))),
		"target_max_health": target_max,
	}
	if bool(loaded.get("arrived_from_hunt", false)):
		summary.arrived_from_hunt = true
	var kit_origin := str(loaded.get("kit_origin", ""))
	if ContentDB.PLANETS.any(func(planet): return str(planet.id) == kit_origin):
		summary.kit_origin = kit_origin
	if loaded.has("won"):
		summary.won = bool(loaded.won)
		summary.player_hp_remaining = clampi(int(loaded.get("player_hp_remaining", 0)), 0, CoreRules.max_health(player))
		summary.enemy_hp_remaining = clampi(int(loaded.get("enemy_hp_remaining", 0)), 0, target_max)
	if int(loaded.get("lost_streak", 0)) > 0:
		summary.lost_streak = maxi(0, int(loaded.lost_streak))
	var field_context = loaded.get("field_test_context", {})
	if field_context is Dictionary and not field_context.is_empty():
		var clean_field_context := canonicalize_loaded_field_context(field_context)
		if not clean_field_context.is_empty():
			summary.field_test_context = clean_field_context
	return {"summary": summary, "repaired": not payloads_equivalent(summary, loaded)}


func canonicalize_loaded_chapter(loaded: Dictionary) -> Dictionary:
	var loaded_planet = loaded.get("planet", {})
	var loaded_target = loaded.get("target", {})
	if not loaded_planet is Dictionary or not loaded_target is Dictionary:
		return {"chapter": {}, "repaired": true}
	var planet := ContentDB.PLANETS.filter(func(definition): return str(definition.id) == str(loaded_planet.get("id", "")))
	var target := ContentDB.TARGETS.filter(func(definition): return str(definition.id) == str(loaded_target.get("id", "")) and bool(definition.get("boss", false)))
	if planet.is_empty() or target.is_empty() or str(target[0].planet_id) != str(planet[0].id):
		return {"chapter": {}, "repaired": true}
	var chapter := {
		"planet": planet[0].duplicate(true),
		"target": target[0].duplicate(true),
		"total_captures": maxi(0, int(loaded.get("total_captures", player.get("wins", 0)))),
		"credits": maxi(0, int(loaded.get("credits", 0))),
		"xp": maxi(0, int(loaded.get("xp", 0))),
	}
	return {"chapter": chapter, "repaired": not payloads_equivalent(chapter, loaded)}


func sanitize_loaded_combat_events(loaded) -> Dictionary:
	if not loaded is Array:
		return {"events": [], "repaired": true}
	var player_actions := {}
	for action in ContentDB.PLAYER_ATTACKS:
		player_actions[str(action)] = true
	var enemy_actions := {}
	for target in ContentDB.TARGETS:
		for action in target.attacks:
			enemy_actions[str(action)] = true
	for target in ChallengeRulesScript.STAGES:
		for action in target.attacks:
			enemy_actions[str(action)] = true
	var events: Array[Dictionary] = []
	var repaired := false
	for loaded_event in loaded:
		if not loaded_event is Dictionary:
			repaired = true
			continue
		var actor := str(loaded_event.get("actor", ""))
		var action := str(loaded_event.get("action", ""))
		var action_is_known := (actor == "player" and player_actions.has(action)) or (actor == "enemy" and enemy_actions.has(action))
		if not action_is_known:
			repaired = true
			continue
		var quality := str(loaded_event.get("quality", "ACERTO"))
		if quality != "CRÍTICO" and quality != "DE RASPÃO" and quality != "ACERTO":
			quality = "ACERTO"
			repaired = true
		var event := {"actor": actor, "action": action, "damage": maxi(0, int(loaded_event.get("damage", 0))), "quality": quality}
		if int(loaded_event.get("damage", 0)) < 0:
			repaired = true
		var effect := str(loaded_event.get("effect", ""))
		var effect_parts := effect.split(" · ", false)
		var effect_is_safe := effect.length() <= 96
		for part in effect_parts:
			if not part.begins_with("EMBOSCADA +") and not part.begins_with("AMORTECEDOR -") and not part.begins_with("INVASÃO +") and not part.begins_with("MIRA ORBITAL +") and not part.begins_with("CASCO DURO -") and not part.begins_with("RUPTURA +") and not part.begins_with("INSTABILIDADE +") and not part.begins_with("INTERFERÊNCIA -") and not part.begins_with("SOBRECARGA -") and not part.begins_with("RAJADA ORBITAL +") and not part.begins_with("RAJADA TÁTICA +") and not part.begins_with("CONTRA-ATAQUE +") and part != "EVASÃO ORBITAL" and part != "EVASÃO TÁTICA":
				effect_is_safe = false
				break
		if not effect.is_empty() and effect_is_safe:
			event.effect = effect
		elif not effect.is_empty():
			repaired = true
		events.append(event)
		if not payloads_equivalent(event, loaded_event):
			repaired = true
	return {"events": events, "repaired": repaired}


func loaded_equipment_is_safe(item: Dictionary, expected_slot: String) -> bool:
	if not CoreRules.is_equipment_slot(expected_slot):
		return false
	if str(item.get("slot", "")) != expected_slot or str(item.get("id", "")).is_empty() or str(item.get("name", "")).is_empty():
		return false
	if not (item.get("power", 0) is int or item.get("power", 0) is float):
		return false
	if str(item.get("rarity", "")).is_empty() or str(item.get("color", "")).is_empty():
		return false
	return (not item.has("trait") or item.trait is Dictionary) and (not item.has("attribute_package_id") or item.attribute_package_id is String)


func sanitize_loaded_equipment(item: Dictionary) -> bool:
	var repaired := false
	if int(item.power) < 0:
		item.power = 0
		repaired = true
	for key in ["power_upgrades", "integrity_upgrades"]:
		if item.has(key) and not (item[key] is int or item[key] is float):
			item[key] = 0
			repaired = true
		elif int(item.get(key, 0)) < 0:
			item[key] = 0
			repaired = true
	if int(item.get("integrity_upgrades", 0)) > CoreRules.MAX_INTEGRITY_UPGRADES:
		item.integrity_upgrades = CoreRules.MAX_INTEGRITY_UPGRADES
		repaired = true
	var rarity_colors := {"Comum": "#b9c2d9", "Raro": "#58d9ff", "Épico": "#d789ff"}
	var rarity := str(item.get("rarity", "Comum"))
	if not rarity_colors.has(rarity):
		rarity = "Comum"
		item.rarity = rarity
		repaired = true
	if str(item.get("color", "")) != str(rarity_colors[rarity]):
		item.color = str(rarity_colors[rarity])
		repaired = true
	if item.has("origin_planet_id"):
		var origin_is_known := ContentDB.PLANETS.any(func(planet): return str(planet.id) == str(item.origin_planet_id))
		if not origin_is_known:
			item.erase("origin_planet_id")
			repaired = true
	if item.has("template_id") and (not (item.template_id is String) or str(item.template_id).is_empty() or str(item.template_id).length() > 96):
		item.erase("template_id")
		repaired = true
	if item.has("item_level"):
		var clean_item_level := clampi(int(item.item_level), 1, 1000000)
		if not (item.item_level is int or item.item_level is float) or clean_item_level != int(item.item_level):
			item.item_level = clean_item_level
			repaired = true
	if item.has("quality"):
		var clean_quality := clampi(int(item.quality), EquipmentGenerationRulesScript.MIN_QUALITY, EquipmentGenerationRulesScript.MAX_QUALITY)
		if not (item.quality is int or item.quality is float) or clean_quality != int(item.quality):
			item.quality = clean_quality
			repaired = true
	if item.has("variant_id") and not EquipmentGenerationRulesScript.variant_is_valid(str(item.variant_id)):
		item.variant_id = "standard"
		repaired = true
	if item.has("generation_seed") and not (item.generation_seed is int or item.generation_seed is float):
		item.generation_seed = 0
		repaired = true
	if item.has("trait"):
		var canonical_trait := {}
		var trait_id := str(item.trait.get("id", ""))
		for definition in ContentDB.ITEM_TRAITS.get(str(item.slot), []):
			if str(definition.id) == trait_id:
				canonical_trait = definition.duplicate(true)
				break
		if canonical_trait.is_empty():
			item.erase("trait")
			repaired = true
		elif not payloads_equivalent(item.trait, canonical_trait):
			item.trait = canonical_trait
			repaired = true
	if item.has("attribute_package_id"):
		var package_id := str(item.attribute_package_id)
		if not AttributePackageRulesScript.is_valid(package_id, str(item.slot)) or item.has("trait"):
			item.erase("attribute_package_id")
			repaired = true
	return repaired


func payloads_equivalent(left, right) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key in left:
			if not right.has(key) or not payloads_equivalent(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index in left.size():
			if not payloads_equivalent(left[index], right[index]):
				return false
		return true
	return left == right


func reconcile_loaded_phase() -> bool:
	var repaired := false
	if phase < Phase.BOARD or phase > Phase.CHAPTER_COMPLETE:
		phase = Phase.BOARD
		repaired = true
	if phase == Phase.BRIEFING and not current_bounty.is_empty() and offered_approaches.is_empty():
		offered_approaches.assign(ContentDB.contract_approaches())
		repaired = true
	var phase_has_required_state := true
	match phase:
		Phase.BRIEFING, Phase.HUNT, Phase.COMBAT:
			phase_has_required_state = not current_bounty.is_empty()
		Phase.HUNT_EVENT:
			phase_has_required_state = not current_bounty.is_empty() and not hunt_event.is_empty()
		Phase.VICTORY, Phase.REWARD:
			phase_has_required_state = not current_bounty.is_empty() and not pending_loot.is_empty()
		Phase.CHAPTER_COMPLETE:
			phase_has_required_state = not chapter_completion.is_empty()
	if phase_has_required_state:
		if phase == Phase.HUNT or phase == Phase.HUNT_EVENT:
			var now := Time.get_unix_time_from_system()
			var interval := HuntTimingRulesScript.repaired_interval(now, hunt_started_at, hunt_ends_at, TransportRulesScript.effective_mission_duration(player, current_bounty))
			hunt_started_at = float(interval.started_at)
			hunt_ends_at = float(interval.ends_at)
			repaired = bool(interval.repaired) or repaired
		if phase == Phase.HUNT_EVENT:
			if hunt_elapsed_before_event < 0.0 or hunt_remaining_after_event < 0.0:
				hunt_elapsed_before_event = maxf(0.0, hunt_elapsed_before_event)
				hunt_remaining_after_event = maxf(0.0, hunt_remaining_after_event)
				repaired = true
		if phase == Phase.COMBAT:
			var clean_player_hp := clampi(player_hp, 1, CoreRules.max_health(player))
			var clean_enemy_hp := clampi(enemy_hp, 1, int(current_bounty.health))
			var clean_round := maxi(0, combat_round)
			if clean_player_hp != player_hp or clean_enemy_hp != enemy_hp or clean_round != combat_round:
				player_hp = clean_player_hp
				enemy_hp = clean_enemy_hp
				combat_round = clean_round
				repaired = true
		return repaired
	phase = Phase.BOARD
	current_bounty = {}
	offered_approaches.clear()
	pending_loot = {}
	hunt_event = {}
	chapter_completion = {}
	combat_events.clear()
	combat_summary = {}
	player_hp = 0
	enemy_hp = 0
	combat_round = 0
	return true


func migrate_save_payload(payload: Dictionary) -> Dictionary:
	return SaveMigrationRules.migrate(payload)
