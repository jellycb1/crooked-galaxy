class_name CrookedGameState
extends Node

const SaveMigrationRules = preload("res://scripts/save_migrations.gd")
const CareerRules = preload("res://scripts/career_rules.gd")

signal changed
signal combat_event(message: String)

enum Phase { BOARD, HUNT, COMBAT, REWARD, VICTORY, BRIEFING, HUNT_EVENT, CHAPTER_COMPLETE }

const SAVE_PATH := "user://crooked_galaxy_save.json"
const SAVE_VERSION := SaveMigrationRules.CURRENT_VERSION

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
var combat_summary: Dictionary = {}
var last_combat_won := false
var rng := RandomNumberGenerator.new()
var persistence_enabled := true
var save_path := SAVE_PATH
var last_notice := ""
var chapter_completion: Dictionary = {}
var afk_report: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	load_game()


func default_player() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"credits": 25,
		"scrap": 0,
		"scrap_recycled_total": 0,
		"afk_credits_earned": 0,
		"afk_scrap_earned": 0,
		"claimed_milestones": [],
		"career_credits_claimed": 0,
		"career_scrap_claimed": 0,
		"capture_streak": 0,
		"best_capture_streak": 0,
		"locked_item_ids": [],
		"equipment_loadouts": [{"weapon_id": "", "armor_id": ""}, {"weapon_id": "", "armor_id": ""}],
		"last_seen_unix": Time.get_unix_time_from_system(),
		"reputation": 0,
		"wins": 0,
		"base_power": 10,
		"sound_enabled": true,
		"captures_by_target": {},
		"captures_by_planet": {},
		"completed_planets": [],
		"current_planet_id": "dustball_prime",
		"weapon": {"id": "starter_weapon", "name": "Zapper de Treino", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"armor": {"id": "starter_armor", "name": "Jaqueta Espacial Duvidosa", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"inventory": [],
	}


func select_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	combat_summary = {}
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
	return CoreRules.planet_tier_from_captures(planet_capture_count(planet_id))


func apply_offline_progress(now_unix: float) -> Dictionary:
	var last_seen := float(player.get("last_seen_unix", now_unix))
	var elapsed := maxf(0.0, now_unix - last_seen)
	var rewards := CoreRules.offline_patrol_rewards(elapsed, player.get("completed_planets", []).size(), int(player.get("wins", 0)))
	player.last_seen_unix = now_unix
	if int(rewards.credits) <= 0 and int(rewards.scrap) <= 0:
		afk_report = {}
		return rewards
	player.credits = int(player.credits) + int(rewards.credits)
	player.scrap = int(player.get("scrap", 0)) + int(rewards.scrap)
	player.afk_credits_earned = int(player.get("afk_credits_earned", 0)) + int(rewards.credits)
	player.afk_scrap_earned = int(player.get("afk_scrap_earned", 0)) + int(rewards.scrap)
	afk_report = rewards.duplicate(true)
	return rewards


func dismiss_afk_report() -> void:
	if afk_report.is_empty():
		return
	afk_report = {}
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
		last_notice = "Marco resgatado: %s. +%d créditos%s" % [str(milestone.name), credits, " · +%d sucata" % scrap if scrap > 0 else ""]
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
	last_notice = "%d marcos resgatados: +%d créditos · +%d sucata." % [ready.size(), credits, scrap]
	save_game()
	changed.emit()
	return {"count": ready.size(), "credits": credits, "scrap": scrap}


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
	hunt_event = ContentDB.random_hunt_event(rng, str(current_bounty.get("planet_id", ContentDB.PLANET.id)))
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
	combat_summary = {
		"target_id": str(current_bounty.get("id", "")),
		"target_name": str(current_bounty.get("name", "Alvo sem recibo")),
		"rounds": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"damage_prevented": 0,
		"critical_hits": 0,
		"opening_bonus": CoreRules.player_opening_damage(player),
		"kit_origin": CoreRules.equipment_set_origin(player),
		"target_max_health": int(current_bounty.health),
	}
	last_combat_won = false
	save_game()
	changed.emit()


func combat_step() -> Dictionary:
	if phase != Phase.COMBAT:
		return {}
	combat_round += 1
	var round_events: Array[Dictionary] = []
	var player_roll := rng.randf()
	var player_damage := CoreRules.player_attack_damage(player, int(current_bounty.defense), player_roll, combat_round)
	var player_event := {
		"actor": "player",
		"action": ContentDB.player_attack(rng),
		"damage": player_damage,
		"quality": combat_quality(player_roll),
	}
	var opening_bonus := CoreRules.player_opening_damage(player) if combat_round == 1 else 0
	if opening_bonus > 0:
		player_event.effect = "EMBOSCADA +%d" % opening_bonus
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

	var enemy_roll := rng.randf()
	var enemy_breakdown := CoreRules.enemy_attack_breakdown(player, int(current_bounty.power), enemy_roll)
	var enemy_damage := int(enemy_breakdown.damage)
	var enemy_event := {
		"actor": "enemy",
		"action": ContentDB.target_attack(current_bounty, rng),
		"damage": enemy_damage,
		"quality": combat_quality(enemy_roll),
	}
	var damage_reduction := CoreRules.player_damage_reduction(player)
	if damage_reduction > 0:
		enemy_event.effect = "AMORTECEDOR -%d" % damage_reduction
	round_events.append(enemy_event)
	combat_summary.damage_taken = int(combat_summary.get("damage_taken", 0)) + mini(player_hp, enemy_damage)
	combat_summary.damage_prevented = int(combat_summary.get("damage_prevented", 0)) + int(enemy_breakdown.prevented)
	player_hp = maxi(0, player_hp - enemy_damage)
	message += "  %s responde com %d." % [enemy_event.action, enemy_damage]
	combat_events = round_events
	if player_hp <= 0:
		finish_combat(false)
		return {"message": message, "finished": true, "won": false}
	save_game()
	combat_event.emit(message)
	return {"message": message, "finished": false}


func finish_combat(won: bool) -> void:
	last_combat_won = won
	combat_summary.won = won
	combat_summary.player_hp_remaining = player_hp
	combat_summary.enemy_hp_remaining = enemy_hp
	if won:
		var target_id := str(current_bounty.get("id", ""))
		var target_captures := int(player.get("captures_by_target", {}).get(target_id, 0))
		pending_loot = ContentDB.generate_loot(current_bounty, rng, CoreRules.target_mastery_level(target_captures))
		phase = Phase.VICTORY
	else:
		player.capture_streak = 0
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


func can_recycle_reward(item: Dictionary) -> bool:
	var slot := str(item.get("slot", ""))
	if slot != "weapon" and slot != "armor":
		return false
	return not item.has("trait") and not CoreRules.has_workshop_investment(item) and not CoreRules.is_upgrade_for_player(player, item)


func claim_reward(equip_item: bool, repeat_contract := false, recycle_item := false) -> Dictionary:
	if phase != Phase.REWARD or pending_loot.is_empty():
		return {}
	if recycle_item and not can_recycle_reward(pending_loot):
		return {}
	var new_streak := int(player.get("capture_streak", 0)) + 1
	var reward := CoreRules.bounty_streak_reward(int(current_bounty.credits), new_streak)
	var summary := {
		"credits": int(reward.credits),
		"base_credits": int(reward.base_credits),
		"streak_bonus": int(reward.bonus_credits),
		"streak_bonus_percent": int(reward.bonus_percent),
		"streak": new_streak,
		"scrap": 0,
		"recycled_scrap": 0,
		"mastery_scrap": 0,
		"recycled": false,
		"xp": int(current_bounty.xp),
		"levels": 0,
		"rank_up": false,
		"chapter_tier_up": false,
		"chapter_complete": false,
		"target_mastery_up": false,
		"target_mastery": 0,
	}
	var completed_bounty := current_bounty.duplicate(true)
	var completed_planet_id := str(completed_bounty.get("planet_id", ContentDB.PLANET.id))
	var old_chapter_tier := planet_tier(completed_planet_id)
	player.credits = int(player.credits) + summary.credits
	player.capture_streak = new_streak
	player.best_capture_streak = maxi(int(player.get("best_capture_streak", 0)), new_streak)
	summary.levels = CoreRules.apply_xp(player, summary.xp)
	player.wins = int(player.wins) + 1
	var captures: Dictionary = player.get("captures_by_target", {})
	var target_id := str(completed_bounty.get("id", "unknown"))
	var old_target_mastery := CoreRules.target_mastery_level(int(captures.get(target_id, 0)))
	captures[target_id] = int(captures.get(target_id, 0)) + 1
	player.captures_by_target = captures
	summary.target_mastery = CoreRules.target_mastery_level(int(captures[target_id]))
	summary.target_mastery_up = int(summary.target_mastery) > old_target_mastery
	if bool(summary.target_mastery_up):
		summary.mastery_scrap = CoreRules.target_mastery_scrap_reward(int(summary.target_mastery))
		summary.scrap = int(summary.scrap) + int(summary.mastery_scrap)
		player.scrap = int(player.get("scrap", 0)) + int(summary.mastery_scrap)
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
	var notice_parts := ["+%d créditos" % int(summary.credits), "+%d XP" % int(summary.xp)]
	if int(summary.recycled_scrap) > 0:
		notice_parts.append("Loot reciclado: +%d sucata" % int(summary.recycled_scrap))
	if int(summary.streak_bonus) > 0:
		notice_parts.append("Embalo ×%d: +%d" % [new_streak, int(summary.streak_bonus)])
	if int(summary.levels) > 0:
		notice_parts.append("Nível +%d" % int(summary.levels))
	if bool(summary.rank_up):
		notice_parts.append("Novo contrato liberado")
	elif bool(summary.chapter_tier_up):
		notice_parts.append("Novo mandado planetário")
	if bool(summary.target_mastery_up):
		notice_parts.append("Perícia com alvo %d: +%d sucata" % [int(summary.target_mastery), int(summary.mastery_scrap)])
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
	phase = Phase.CHAPTER_COMPLETE if first_boss_capture else (Phase.BRIEFING if repeat_contract else Phase.BOARD)
	current_bounty = ContentDB.get_target(target_id) if repeat_contract and not first_boss_capture else {}
	pending_loot = {}
	offered_approaches.clear()
	if repeat_contract and not first_boss_capture:
		offered_approaches.assign(ContentDB.contract_approaches())
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
			last_notice = "%s equipado. Poder total: %d." % [str(item.name), CoreRules.player_power(player)]
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
		last_notice = "%s reciclado: +%d sucata." % [str(item.name), value]
		save_game()
		changed.emit()
		return true
	return false


func inferior_recycle_preview() -> Dictionary:
	var count := 0
	var scrap := 0
	for item in player.get("inventory", []):
		var slot := str(item.get("slot", ""))
		if slot != "weapon" and slot != "armor":
			continue
		if is_item_protected(str(item.get("id", ""))):
			continue
		if item.has("trait"):
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
		var is_inferior: bool = (slot == "weapon" or slot == "armor") and not item.has("trait") and not CoreRules.has_workshop_investment(item) and not CoreRules.is_upgrade_for_player(player, item)
		if is_equipped or not is_inferior:
			retained.append(item)
	player.inventory = retained
	player.scrap = int(player.get("scrap", 0)) + int(preview.scrap)
	player.scrap_recycled_total = int(player.get("scrap_recycled_total", 0)) + int(preview.scrap)
	last_notice = "%d peças inferiores recicladas: +%d sucata." % [int(preview.count), int(preview.scrap)]
	save_game()
	changed.emit()
	return preview


func is_item_protected(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for slot in ["weapon", "armor"]:
		if str(player.get(slot, {}).get("id", "")) == item_id:
			return true
	if player.get("locked_item_ids", []).has(item_id):
		return true
	for loadout in player.get("equipment_loadouts", []):
		if str(loadout.get("weapon_id", "")) == item_id or str(loadout.get("armor_id", "")) == item_id:
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
		last_notice = "Proteção removida. A oficina voltou a olhar para essa peça com interesse."
	else:
		locked.append(item_id)
		last_notice = "Peça protegida contra reciclagem manual e em massa."
	player.locked_item_ids = locked
	save_game()
	changed.emit()
	return true


func save_equipment_loadout(index: int) -> bool:
	var loadouts: Array = player.get("equipment_loadouts", [])
	if phase != Phase.BOARD or index < 0 or index >= loadouts.size():
		return false
	loadouts[index] = {
		"weapon_id": str(player.get("weapon", {}).get("id", "")),
		"armor_id": str(player.get("armor", {}).get("id", "")),
	}
	player.equipment_loadouts = loadouts
	last_notice = "Loadout %s arquivado. As peças foram protegidas." % loadout_name(index)
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
		last_notice = "Loadout incompleto. Uma das peças provavelmente virou história de oficina."
		changed.emit()
		return false
	equip(weapon)
	equip(armor)
	last_notice = "Loadout %s equipado. Poder %d · Vida %d." % [loadout_name(index), CoreRules.player_power(player), CoreRules.max_health(player)]
	save_game()
	changed.emit()
	return true


func inventory_item_by_id(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	for slot in ["weapon", "armor"]:
		var equipped: Dictionary = player.get(slot, {})
		if str(equipped.get("id", "")) == item_id:
			return equipped.duplicate(true)
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == item_id:
			return item.duplicate(true)
	return {}


func loadout_name(index: int) -> String:
	return "CAÇA" if index == 0 else "RESERVA"


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
	item.power_upgrades = int(item.get("power_upgrades", 0)) + 1
	player[slot] = item
	sync_item_to_inventory(item)
	last_notice = "%s calibrado para +%d poder." % [str(item.name), int(item.power)]
	save_game()
	changed.emit()
	return true


func reinforce_equipped(slot: String) -> bool:
	if phase != Phase.BOARD or (slot != "weapon" and slot != "armor"):
		return false
	var item: Dictionary = player[slot]
	if not CoreRules.can_upgrade_integrity(item):
		return false
	var cost := CoreRules.equipment_integrity_upgrade_cost(item)
	if int(player.get("scrap", 0)) < cost:
		return false
	player.scrap = int(player.scrap) - cost
	item = item.duplicate(true)
	item.integrity_upgrades = int(item.get("integrity_upgrades", 0)) + 1
	player[slot] = item
	sync_item_to_inventory(item)
	last_notice = "%s reforçado: +%d vida total." % [str(item.name), int(item.integrity_upgrades) * CoreRules.INTEGRITY_HEALTH_PER_LEVEL]
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


func abandon_bounty() -> void:
	if phase == Phase.HUNT or phase == Phase.HUNT_EVENT:
		var lost_streak := int(player.get("capture_streak", 0))
		player.capture_streak = 0
		phase = Phase.BOARD
		current_bounty = {}
		offered_approaches = []
		hunt_event = {}
		last_notice = "Contrato abandonado%s. O embalo foi perdido." % (" após %d capturas" % lost_streak if lost_streak > 0 else "")
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
	afk_report = {}
	combat_summary = {}
	last_notice = "Progresso reiniciado. Hora de construir uma nova reputação."
	save_game()
	changed.emit()


func save_game() -> void:
	if not persistence_enabled:
		return
	player.last_seen_unix = Time.get_unix_time_from_system()
	var payload := {
		"version": SAVE_VERSION,
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
	if not parsed is Dictionary:
		return
	var requires_migration_save := int(parsed.get("version", 0)) < SAVE_VERSION
	parsed = migrate_save_payload(parsed)
	if parsed.is_empty():
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
	var loaded_summary = parsed.get("combat_summary", {})
	combat_summary = loaded_summary if loaded_summary is Dictionary else {}
	chapter_completion = parsed.get("chapter_completion", {})
	var offline_rewards := apply_offline_progress(Time.get_unix_time_from_system())
	if int(offline_rewards.credits) > 0 or int(offline_rewards.scrap) > 0:
		# Persist immediately so an abrupt close cannot claim the same patrol twice.
		save_game()
	if phase == Phase.HUNT and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat()
	elif phase == Phase.COMBAT:
		# Combat resumes safely from its saved health values.
		player_hp = maxi(1, player_hp)
		enemy_hp = maxi(1, enemy_hp)
	if requires_migration_save:
		save_game()


func migrate_save_payload(payload: Dictionary) -> Dictionary:
	return SaveMigrationRules.migrate(payload)
