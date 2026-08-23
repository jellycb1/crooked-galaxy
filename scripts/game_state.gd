extends Node

signal changed
signal combat_event(message: String)

enum Phase { BOARD, HUNT, COMBAT, REWARD, VICTORY, BRIEFING, HUNT_EVENT, CHAPTER_COMPLETE }

const SAVE_PATH := "user://crooked_galaxy_save.json"

var player: Dictionary
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
var last_combat_won := false
var rng := RandomNumberGenerator.new()
var persistence_enabled := true
var save_path := SAVE_PATH
var last_notice := ""
var chapter_completion: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	load_game()


func default_player() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"credits": 25,
		"scrap": 0,
		"reputation": 0,
		"wins": 0,
		"base_power": 10,
		"sound_enabled": true,
		"captures_by_target": {},
		"captures_by_planet": {},
		"completed_planets": [],
		"current_planet_id": "dustball_prime",
		"weapon": {"name": "Zapper de Treino", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"armor": {"name": "Jaqueta Espacial Duvidosa", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"inventory": [],
	}


func select_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	current_bounty = bounty.duplicate(true)
	offered_approaches = ContentDB.contract_approaches()
	phase = Phase.BRIEFING
	save_game()
	changed.emit()


func travel_to_planet(planet_id: String) -> bool:
	if phase != Phase.BOARD:
		return false
	var completed: Array = player.get("completed_planets", [])
	if not ContentDB.is_planet_unlocked(planet_id, completed):
		return false
	var planet := ContentDB.get_planet(planet_id)
	player.current_planet_id = str(planet.id)
	last_notice = "Rota confirmada: %s. O combustível será explicado na fatura." % str(planet.name)
	save_game()
	changed.emit()
	return true


func planet_capture_count(planet_id: String) -> int:
	var captures: Dictionary = player.get("captures_by_planet", {})
	return int(captures.get(planet_id, 0))


func planet_tier(planet_id: String) -> int:
	return mini(3, floori(float(planet_capture_count(planet_id)) / 3.0))


func choose_approach(approach_id: String) -> void:
	if phase != Phase.BRIEFING:
		return
	for approach in offered_approaches:
		if str(approach.id) == approach_id:
			current_bounty = ContentDB.apply_approach(current_bounty, approach)
			offered_approaches = []
			start_hunt()
			return


func start_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	current_bounty = bounty.duplicate(true)
	offered_approaches = []
	start_hunt()


func start_hunt() -> void:
	phase = Phase.HUNT
	hunt_started_at = Time.get_unix_time_from_system()
	hunt_ends_at = hunt_started_at + float(current_bounty.duration)
	hunt_event = ContentDB.random_hunt_event(rng)
	hunt_event_triggered = false
	hunt_elapsed_before_event = 0.0
	hunt_remaining_after_event = 0.0
	save_game()
	changed.emit()


func cancel_briefing() -> void:
	if phase != Phase.BRIEFING:
		return
	phase = Phase.BOARD
	current_bounty = {}
	offered_approaches = []
	save_game()
	changed.emit()


func hunt_progress() -> float:
	if phase != Phase.HUNT:
		return 0.0
	var duration := maxf(0.1, hunt_ends_at - hunt_started_at)
	return clampf(1.0 - (hunt_ends_at - Time.get_unix_time_from_system()) / duration, 0.0, 1.0)


func update_hunt() -> bool:
	if phase != Phase.HUNT:
		return false
	var now := Time.get_unix_time_from_system()
	if now >= hunt_ends_at:
		begin_combat()
		return true
	if not hunt_event_triggered and hunt_progress() >= 0.45:
		hunt_event_triggered = true
		hunt_elapsed_before_event = maxf(0.0, now - hunt_started_at)
		hunt_remaining_after_event = maxf(0.1, hunt_ends_at - now)
		phase = Phase.HUNT_EVENT
		save_game()
		changed.emit()
		return true
	return false


func can_afford_hunt_choice(choice: Dictionary) -> bool:
	return int(player.credits) >= int(choice.get("credit_cost", 0))


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
		hunt_started_at = now - hunt_elapsed_before_event
		hunt_ends_at = now + hunt_remaining_after_event + duration_add
		phase = Phase.HUNT
		save_game()
		changed.emit()
		return true
	return false


func begin_combat() -> void:
	phase = Phase.COMBAT
	player_hp = CoreRules.max_health(player)
	enemy_hp = int(current_bounty.health)
	combat_round = 0
	combat_events = []
	last_combat_won = false
	save_game()
	changed.emit()


func combat_step() -> Dictionary:
	if phase != Phase.COMBAT:
		return {}
	combat_round += 1
	var round_events: Array[Dictionary] = []
	var player_roll := rng.randf()
	var player_damage := CoreRules.damage_roll(CoreRules.player_power(player), int(current_bounty.defense), player_roll)
	var player_event := {
		"actor": "player",
		"action": ContentDB.player_attack(rng),
		"damage": player_damage,
		"quality": combat_quality(player_roll),
	}
	round_events.append(player_event)
	enemy_hp = maxi(0, enemy_hp - player_damage)
	var message := "%s causa %d de dano." % [player_event.action, player_damage]
	if enemy_hp <= 0:
		combat_events = round_events
		finish_combat(true)
		return {"message": message, "finished": true, "won": true}

	var enemy_roll := rng.randf()
	var enemy_damage := CoreRules.damage_roll(int(current_bounty.power), int(player.get("armor", {}).get("power", 0)) + 3, enemy_roll)
	var enemy_event := {
		"actor": "enemy",
		"action": ContentDB.target_attack(current_bounty, rng),
		"damage": enemy_damage,
		"quality": combat_quality(enemy_roll),
	}
	round_events.append(enemy_event)
	player_hp = maxi(0, player_hp - enemy_damage)
	message += "  %s responde com %d." % [enemy_event.action, enemy_damage]
	combat_events = round_events
	if player_hp <= 0:
		finish_combat(false)
		return {"message": message, "finished": true, "won": false}
	combat_event.emit(message)
	return {"message": message, "finished": false}


func finish_combat(won: bool) -> void:
	last_combat_won = won
	if won:
		pending_loot = ContentDB.generate_loot(current_bounty, rng)
		phase = Phase.VICTORY
	else:
		phase = Phase.BOARD
		last_notice = "%s escapou. Seu equipamento precisa de argumentos melhores." % str(current_bounty.name)
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


func claim_reward(equip_item: bool) -> Dictionary:
	if phase != Phase.REWARD or pending_loot.is_empty():
		return {}
	var summary := {
		"credits": int(current_bounty.credits),
		"xp": int(current_bounty.xp),
		"levels": 0,
		"rank_up": false,
		"chapter_tier_up": false,
		"chapter_complete": false,
	}
	var completed_bounty := current_bounty.duplicate(true)
	var completed_planet_id := str(completed_bounty.get("planet_id", ContentDB.PLANET.id))
	var old_chapter_tier := planet_tier(completed_planet_id)
	player.credits = int(player.credits) + summary.credits
	summary.levels = CoreRules.apply_xp(player, summary.xp)
	player.wins = int(player.wins) + 1
	var captures: Dictionary = player.get("captures_by_target", {})
	var target_id := str(completed_bounty.get("id", "unknown"))
	captures[target_id] = int(captures.get(target_id, 0)) + 1
	player.captures_by_target = captures
	var planet_captures: Dictionary = player.get("captures_by_planet", {})
	planet_captures[completed_planet_id] = int(planet_captures.get(completed_planet_id, 0)) + 1
	player.captures_by_planet = planet_captures
	summary.chapter_tier_up = planet_tier(completed_planet_id) > old_chapter_tier
	var old_reputation := int(player.reputation)
	var highest_rank := 0
	for target in ContentDB.TARGETS:
		highest_rank = maxi(highest_rank, int(target.rank))
	player.reputation = mini(floori(float(player.wins) / 3.0), highest_rank)
	summary.rank_up = int(player.reputation) > old_reputation
	player.inventory.append(pending_loot.duplicate(true))
	if equip_item:
		equip(pending_loot)
	var notice_parts := ["+%d créditos" % int(summary.credits), "+%d XP" % int(summary.xp)]
	if int(summary.levels) > 0:
		notice_parts.append("Nível +%d" % int(summary.levels))
	if bool(summary.rank_up):
		notice_parts.append("Novo contrato liberado")
	elif bool(summary.chapter_tier_up):
		notice_parts.append("Novo mandado planetário")
	var completed_planets: Array = player.get("completed_planets", [])
	var completed_planet := ContentDB.get_planet(completed_planet_id)
	var first_boss_capture := bool(completed_bounty.get("boss", false)) and not completed_planets.has(completed_planet_id)
	if first_boss_capture:
		completed_planets.append(completed_planet_id)
		player.completed_planets = completed_planets
		summary.chapter_complete = true
		chapter_completion = {
			"planet": completed_planet,
			"target": completed_bounty,
			"total_captures": planet_capture_count(completed_planet_id),
			"credits": int(summary.credits),
			"xp": int(summary.xp),
		}
	last_notice = "Contrato pago: " + " · ".join(notice_parts)
	phase = Phase.CHAPTER_COMPLETE if first_boss_capture else Phase.BOARD
	current_bounty = {}
	pending_loot = {}
	offered_approaches = []
	hunt_event = {}
	save_game()
	changed.emit()
	return summary


func continue_after_chapter() -> void:
	if phase != Phase.CHAPTER_COMPLETE:
		return
	var completed_planet: Dictionary = chapter_completion.get("planet", ContentDB.PLANET)
	phase = Phase.BOARD
	chapter_completion = {}
	last_notice = "%s pacificada. Contratos reabertos para melhorar equipamento e recordes." % str(completed_planet.name)
	save_game()
	changed.emit()


func equip(item: Dictionary) -> void:
	var slot := str(item.get("slot", ""))
	if slot == "weapon" or slot == "armor":
		player[slot] = item.duplicate(true)


func equip_from_inventory(item_id: String) -> void:
	if phase != Phase.BOARD:
		return
	for item in player.inventory:
		if str(item.get("id", "")) == item_id:
			equip(item)
			last_notice = "%s equipado. Poder total: %d." % [str(item.name), CoreRules.player_power(player)]
			save_game()
			changed.emit()
			return


func scrap_item(item_id: String) -> bool:
	if phase != Phase.BOARD:
		return false
	for slot in ["weapon", "armor"]:
		if str(player.get(slot, {}).get("id", "")) == item_id:
			return false
	for item_index in player.inventory.size():
		var item: Dictionary = player.inventory[item_index]
		if str(item.get("id", "")) != item_id:
			continue
		var value := CoreRules.salvage_value(item)
		player.inventory.remove_at(item_index)
		player.scrap = int(player.get("scrap", 0)) + value
		last_notice = "%s reciclado: +%d sucata." % [str(item.name), value]
		save_game()
		changed.emit()
		return true
	return false


func upgrade_equipped(slot: String) -> bool:
	if phase != Phase.BOARD or (slot != "weapon" and slot != "armor"):
		return false
	var item: Dictionary = player[slot]
	var cost := CoreRules.equipment_upgrade_cost(item)
	if int(player.get("scrap", 0)) < cost:
		return false
	player.scrap = int(player.scrap) - cost
	item = item.duplicate(true)
	item.power = int(item.power) + 1
	player[slot] = item
	var item_id := str(item.get("id", ""))
	if not item_id.is_empty():
		for inventory_item in player.inventory:
			if str(inventory_item.get("id", "")) == item_id:
				inventory_item.power = int(item.power)
				break
	last_notice = "%s calibrado para +%d poder." % [str(item.name), int(item.power)]
	save_game()
	changed.emit()
	return true


func toggle_sound() -> void:
	player.sound_enabled = not bool(player.get("sound_enabled", true))
	save_game()
	changed.emit()


func abandon_bounty() -> void:
	if phase == Phase.HUNT or phase == Phase.HUNT_EVENT:
		phase = Phase.BOARD
		current_bounty = {}
		offered_approaches = []
		hunt_event = {}
		save_game()
		changed.emit()


func reset_progress() -> void:
	player = default_player()
	phase = Phase.BOARD
	current_bounty = {}
	pending_loot = {}
	offered_approaches = []
	hunt_event = {}
	chapter_completion = {}
	last_notice = "Progresso reiniciado. Hora de construir uma nova reputação."
	save_game()
	changed.emit()


func save_game() -> void:
	if not persistence_enabled:
		return
	var payload := {
		"version": 1,
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
		"chapter_completion": chapter_completion,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func load_game() -> void:
	player = default_player()
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		return
	var loaded_player = parsed.get("player", {})
	if loaded_player is Dictionary:
		for key in player:
			if loaded_player.has(key):
				player[key] = loaded_player[key]
		# Saves created before per-planet progression inherit their existing Dustball victories.
		if not loaded_player.has("captures_by_planet") and int(player.wins) > 0:
			player.captures_by_planet = {ContentDB.PLANET.id: int(player.wins)}
	phase = int(parsed.get("phase", Phase.BOARD))
	current_bounty = parsed.get("current_bounty", {})
	var loaded_approaches = parsed.get("offered_approaches", [])
	offered_approaches.assign(loaded_approaches if loaded_approaches is Array else [])
	pending_loot = parsed.get("pending_loot", {})
	hunt_started_at = float(parsed.get("hunt_started_at", 0.0))
	hunt_ends_at = float(parsed.get("hunt_ends_at", 0.0))
	hunt_event = parsed.get("hunt_event", {})
	hunt_event_triggered = bool(parsed.get("hunt_event_triggered", false))
	hunt_elapsed_before_event = float(parsed.get("hunt_elapsed_before_event", 0.0))
	hunt_remaining_after_event = float(parsed.get("hunt_remaining_after_event", 0.0))
	player_hp = int(parsed.get("player_hp", 0))
	enemy_hp = int(parsed.get("enemy_hp", 0))
	combat_round = int(parsed.get("combat_round", 0))
	var loaded_events = parsed.get("combat_events", [])
	combat_events.assign(loaded_events if loaded_events is Array else [])
	chapter_completion = parsed.get("chapter_completion", {})
	if phase == Phase.HUNT and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat()
	elif phase == Phase.COMBAT:
		# Combat resumes safely from its saved health values.
		player_hp = maxi(1, player_hp)
		enemy_hp = maxi(1, enemy_hp)
