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
var last_notice_context := ""
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
	last_notice_context = ""
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
	last_notice = "%d marcos resgatados: +%d créditos · +%d sucata." % [ready.size(), credits, scrap]
	last_notice_context = "career"
	save_game()
	changed.emit()
	return {"count": ready.size(), "credits": credits, "scrap": scrap}


func choose_approach(approach_id: String, tested_context: Dictionary = {}) -> void:
	if phase != Phase.BRIEFING:
		return
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
			start_hunt()
			return


func start_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	last_notice_context = ""
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
		"field_test_context": current_bounty.get("field_test_context", {}).duplicate(true),
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
		var lost_streak := int(player.get("capture_streak", 0))
		combat_summary.lost_streak = lost_streak
		player.capture_streak = 0
		phase = Phase.BOARD
		last_notice = "%s escapou. Seu equipamento precisa de argumentos melhores.%s" % [str(current_bounty.name), " Embalo ×%d perdido." % lost_streak if lost_streak > 0 else ""]
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
		"incident_cost": maxi(0, int(current_bounty.get("hunt_event_credit_cost", 0))),
		"net_contract_credits": int(reward.credits) - maxi(0, int(current_bounty.get("hunt_event_credit_cost", 0))),
		"streak": new_streak,
		"scrap": 0,
		"contract_scrap": 0,
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
		"loot_name": str(pending_loot.get("name", "Loot sem etiqueta")),
		"loot_action": "recycled" if recycle_item else ("equipped" if equip_item else "stored"),
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
	if int(summary.incident_cost) > 0:
		notice_parts.append("Incidente já pago: saldo +%d créditos" % int(summary.net_contract_credits))
	if int(summary.contract_scrap) > 0:
		notice_parts.append("Mandado corporativo: +%d sucata" % int(summary.contract_scrap))
	if int(summary.recycled_scrap) > 0:
		notice_parts.append("%s reciclado: +%d sucata" % [str(summary.loot_name), int(summary.recycled_scrap)])
	elif str(summary.loot_action) == "equipped":
		notice_parts.append("%s equipado" % str(summary.loot_name))
	else:
		notice_parts.append("%s guardado" % str(summary.loot_name))
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
	last_notice_context = "reward_%s" % str(summary.loot_action)
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
	last_notice_context = "chapter"
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
		last_notice = "%s reciclado: +%d sucata." % [str(item.name), value]
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
	last_notice_context = "workshop"
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
	last_notice_context = "workshop"
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
		last_notice = "Loadout incompleto. Uma das peças provavelmente virou história de oficina."
		last_notice_context = "workshop"
		changed.emit()
		return false
	equip(weapon)
	equip(armor)
	last_notice = "Loadout %s equipado. Poder %d · Vida %d." % [loadout_name(index), CoreRules.player_power(player), CoreRules.max_health(player)]
	last_notice_context = "workshop"
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
	last_notice_context = "workshop"
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


func abandon_bounty() -> void:
	if phase == Phase.HUNT or phase == Phase.HUNT_EVENT:
		var lost_streak := int(player.get("capture_streak", 0))
		player.capture_streak = 0
		phase = Phase.BOARD
		current_bounty = {}
		offered_approaches = []
		hunt_event = {}
		last_notice = "Contrato abandonado%s. O embalo foi perdido." % (" após %d capturas" % lost_streak if lost_streak > 0 else "")
		last_notice_context = "contract"
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
	last_notice_context = "system"
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
	last_notice = ""
	last_notice_context = ""
	afk_report = {}
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
	combat_events.assign(loaded_events if loaded_events is Array else [])
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
	if phase == Phase.HUNT and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat()
	elif phase == Phase.COMBAT:
		# Combat resumes safely from its saved health values.
		player_hp = maxi(1, player_hp)
		enemy_hp = maxi(1, enemy_hp)
	if requires_migration_save:
		last_notice = "SAVE ATUALIZADO: progresso legado preservado e registros ausentes reconstruídos."
		last_notice_context = "system_recovery"
	elif repaired_phase:
		last_notice = "SAVE RECUPERADO: progresso válido preservado; registros inconsistentes foram isolados."
		last_notice_context = "system_recovery"
	if requires_migration_save or repaired_phase:
		save_game()


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
	for slot in ["weapon", "armor"]:
		var fallback: Dictionary = default_player()[slot]
		var loaded_item = loaded.get(slot, {})
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
	var clean_loadouts := [{"weapon_id": "", "armor_id": ""}, {"weapon_id": "", "armor_id": ""}]
	var loaded_loadouts = loaded.get("equipment_loadouts", [])
	if loaded_loadouts is Array:
		for index in mini(2, loaded_loadouts.size()):
			if loaded_loadouts[index] is Dictionary:
				clean_loadouts[index] = {
					"weapon_id": str(loaded_loadouts[index].get("weapon_id", "")),
					"armor_id": str(loaded_loadouts[index].get("armor_id", "")),
				}
			else:
				repaired = true
		if loaded_loadouts.size() != 2:
			repaired = true
	else:
		repaired = true
	sanitized.equipment_loadouts = clean_loadouts
	for key in ["xp", "credits", "scrap", "scrap_recycled_total", "afk_credits_earned", "afk_scrap_earned", "career_credits_claimed", "career_scrap_claimed", "capture_streak", "best_capture_streak", "reputation", "wins"]:
		if int(sanitized[key]) < 0:
			sanitized[key] = 0
			repaired = true
	for key in ["level", "base_power"]:
		if int(sanitized[key]) < 1:
			sanitized[key] = 1
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
	var current_planet_id := str(sanitized.current_planet_id)
	if not known_planet_ids.has(current_planet_id) or not ContentDB.is_planet_unlocked(current_planet_id, clean_completed):
		current_planet_id = str(ContentDB.PLANET.id)
		for planet in ContentDB.PLANETS:
			if ContentDB.is_planet_unlocked(str(planet.id), clean_completed):
				current_planet_id = str(planet.id)
		sanitized.current_planet_id = current_planet_id
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
	var owned_item_ids := {str(sanitized.weapon.id): true, str(sanitized.armor.id): true}
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
		for slot in ["weapon", "armor"]:
			var id_key := "%s_id" % slot
			if not str(loadout[id_key]).is_empty() and not owned_item_ids.has(str(loadout[id_key])):
				loadout[id_key] = ""
				repaired = true
	return {"player": sanitized, "repaired": repaired}


func canonicalize_loaded_bounty(loaded: Dictionary) -> Dictionary:
	if loaded.is_empty():
		return {"bounty": {}, "repaired": false}
	var canonical_target := {}
	for target in ContentDB.TARGETS:
		if str(target.id) == str(loaded.get("id", "")):
			canonical_target = target.duplicate(true)
			break
	if canonical_target.is_empty():
		return {"bounty": {}, "repaired": true}
	var bounty: Dictionary = canonical_target
	var loaded_approach = loaded.get("approach", {})
	if loaded_approach is Dictionary and not loaded_approach.is_empty():
		for approach in ContentDB.contract_approaches():
			if str(approach.id) == str(loaded_approach.get("id", "")):
				bounty = ContentDB.apply_approach(bounty, approach)
				break
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
		return {"summary": {}, "repaired": true}
	var definition: Dictionary = target[0]
	var target_max := int(current_bounty.get("health", definition.health)) if str(current_bounty.get("id", "")) == str(definition.id) else int(definition.health)
	var summary := {
		"target_id": str(definition.id),
		"target_name": str(definition.name),
		"rounds": maxi(0, int(loaded.get("rounds", 0))),
		"damage_dealt": maxi(0, int(loaded.get("damage_dealt", 0))),
		"damage_taken": maxi(0, int(loaded.get("damage_taken", 0))),
		"damage_prevented": maxi(0, int(loaded.get("damage_prevented", 0))),
		"critical_hits": maxi(0, int(loaded.get("critical_hits", 0))),
		"opening_bonus": maxi(0, int(loaded.get("opening_bonus", 0))),
		"target_max_health": target_max,
	}
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


func loaded_equipment_is_safe(item: Dictionary, expected_slot: String) -> bool:
	if expected_slot != "weapon" and expected_slot != "armor":
		return false
	if str(item.get("slot", "")) != expected_slot or str(item.get("id", "")).is_empty() or str(item.get("name", "")).is_empty():
		return false
	if not (item.get("power", 0) is int or item.get("power", 0) is float):
		return false
	if str(item.get("rarity", "")).is_empty() or str(item.get("color", "")).is_empty():
		return false
	return not item.has("trait") or item.trait is Dictionary


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
	if item.has("trait"):
		var canonical_trait := {}
		var trait_id := str(item.trait.get("id", ""))
		for definition in ContentDB.ITEM_TRAITS[str(item.slot)]:
			if str(definition.id) == trait_id:
				canonical_trait = definition.duplicate(true)
				break
		if canonical_trait.is_empty():
			item.erase("trait")
			repaired = true
		elif not payloads_equivalent(item.trait, canonical_trait):
			item.trait = canonical_trait
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
