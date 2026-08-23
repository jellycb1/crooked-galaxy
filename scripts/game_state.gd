extends Node

signal changed
signal combat_event(message: String)

enum Phase { BOARD, HUNT, COMBAT, REWARD }

const SAVE_PATH := "user://crooked_galaxy_save.json"

var player: Dictionary
var phase: int = Phase.BOARD
var current_bounty: Dictionary = {}
var pending_loot: Dictionary = {}
var hunt_started_at := 0.0
var hunt_ends_at := 0.0
var player_hp := 0
var enemy_hp := 0
var combat_round := 0
var last_combat_won := false
var rng := RandomNumberGenerator.new()
var persistence_enabled := true
var last_notice := ""


func _ready() -> void:
	rng.randomize()
	load_game()


func default_player() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"credits": 25,
		"reputation": 0,
		"wins": 0,
		"base_power": 10,
		"weapon": {"name": "Zapper de Treino", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"armor": {"name": "Jaqueta Espacial Duvidosa", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"},
		"inventory": [],
	}


func start_bounty(bounty: Dictionary) -> void:
	if phase != Phase.BOARD:
		return
	last_notice = ""
	current_bounty = bounty.duplicate(true)
	phase = Phase.HUNT
	hunt_started_at = Time.get_unix_time_from_system()
	hunt_ends_at = hunt_started_at + float(current_bounty.duration)
	save_game()
	changed.emit()


func hunt_progress() -> float:
	if phase != Phase.HUNT:
		return 0.0
	var duration := maxf(0.1, hunt_ends_at - hunt_started_at)
	return clampf(1.0 - (hunt_ends_at - Time.get_unix_time_from_system()) / duration, 0.0, 1.0)


func update_hunt() -> bool:
	if phase == Phase.HUNT and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat()
		return true
	return false


func begin_combat() -> void:
	phase = Phase.COMBAT
	player_hp = CoreRules.max_health(player)
	enemy_hp = int(current_bounty.health)
	combat_round = 0
	last_combat_won = false
	save_game()
	changed.emit()


func combat_step() -> Dictionary:
	if phase != Phase.COMBAT:
		return {}
	combat_round += 1
	var player_damage := CoreRules.damage_roll(
		CoreRules.player_power(player), int(current_bounty.defense), rng.randf()
	)
	enemy_hp = maxi(0, enemy_hp - player_damage)
	var message := "Você causa %d de dano." % player_damage
	if enemy_hp <= 0:
		finish_combat(true)
		return {"message": message, "finished": true, "won": true}

	var enemy_damage := CoreRules.damage_roll(
		int(current_bounty.power), int(player.get("armor", {}).get("power", 0)) + 3, rng.randf()
	)
	player_hp = maxi(0, player_hp - enemy_damage)
	message += "  %s revida com %d." % [current_bounty.name, enemy_damage]
	if player_hp <= 0:
		finish_combat(false)
		return {"message": message, "finished": true, "won": false}
	combat_event.emit(message)
	return {"message": message, "finished": false}


func finish_combat(won: bool) -> void:
	last_combat_won = won
	if won:
		pending_loot = ContentDB.generate_loot(current_bounty, rng)
		phase = Phase.REWARD
	else:
		phase = Phase.BOARD
		current_bounty = {}
		pending_loot = {}
	save_game()
	changed.emit()


func claim_reward(equip_item: bool) -> Dictionary:
	if phase != Phase.REWARD or pending_loot.is_empty():
		return {}
	var summary := {
		"credits": int(current_bounty.credits),
		"xp": int(current_bounty.xp),
		"levels": 0,
		"rank_up": false,
	}
	player.credits = int(player.credits) + summary.credits
	summary.levels = CoreRules.apply_xp(player, summary.xp)
	player.wins = int(player.wins) + 1
	var old_reputation := int(player.reputation)
	player.reputation = floori(float(player.wins) / 3.0)
	summary.rank_up = int(player.reputation) > old_reputation
	player.inventory.append(pending_loot.duplicate(true))
	if equip_item:
		equip(pending_loot)
	var notice_parts := ["+%d créditos" % int(summary.credits), "+%d XP" % int(summary.xp)]
	if int(summary.levels) > 0:
		notice_parts.append("Nível +%d" % int(summary.levels))
	if bool(summary.rank_up):
		notice_parts.append("Novo contrato liberado")
	last_notice = "Contrato pago: " + " · ".join(notice_parts)
	phase = Phase.BOARD
	current_bounty = {}
	pending_loot = {}
	save_game()
	changed.emit()
	return summary


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


func abandon_bounty() -> void:
	if phase == Phase.HUNT:
		phase = Phase.BOARD
		current_bounty = {}
		save_game()
		changed.emit()


func reset_progress() -> void:
	player = default_player()
	phase = Phase.BOARD
	current_bounty = {}
	pending_loot = {}
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
		"pending_loot": pending_loot,
		"hunt_started_at": hunt_started_at,
		"hunt_ends_at": hunt_ends_at,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"combat_round": combat_round,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func load_game() -> void:
	player = default_player()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	phase = int(parsed.get("phase", Phase.BOARD))
	current_bounty = parsed.get("current_bounty", {})
	pending_loot = parsed.get("pending_loot", {})
	hunt_started_at = float(parsed.get("hunt_started_at", 0.0))
	hunt_ends_at = float(parsed.get("hunt_ends_at", 0.0))
	player_hp = int(parsed.get("player_hp", 0))
	enemy_hp = int(parsed.get("enemy_hp", 0))
	combat_round = int(parsed.get("combat_round", 0))
	if phase == Phase.HUNT and Time.get_unix_time_from_system() >= hunt_ends_at:
		begin_combat()
	elif phase == Phase.COMBAT:
		# Combat resumes safely from its saved health values.
		player_hp = maxi(1, player_hp)
		enemy_hp = maxi(1, enemy_hp)
