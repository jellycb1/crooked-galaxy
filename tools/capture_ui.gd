extends SceneTree

const OUTPUT_DIR := "res://builds"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var state = root.get_node_or_null("GameState")
	if state:
		state.persistence_enabled = false
		state.player = state.default_player()
		state.phase = state.Phase.BOARD
		state.current_bounty = {}
		state.pending_loot = {}
		state.last_notice = ""
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if save_frame("ui_board.png") != OK:
		quit(1)
		return
	var board_credits := int(state.player.credits)
	var board_scrap := int(state.player.scrap)
	state.player.wins = 1
	state.player.captures_by_target = {"gloop": 1}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 1}
	state.player.credits = board_credits + 380
	state.player.scrap = board_scrap + 6
	state.afk_report = {"minutes": 95, "credits": 380, "scrap": 6, "capped": false}
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_afk_return.png") != OK:
		quit(1)
		return
	state.afk_report = {}
	state.player.wins = 0
	state.player.captures_by_target = {}
	state.player.captures_by_planet = {}
	state.player.credits = board_credits
	state.player.scrap = board_scrap
	scene.render()
	await process_frame
	await process_frame

	var bounty: Dictionary = ContentDB.TARGETS[0].duplicate(true)
	state.player.weapon.origin_planet_id = "dustball_prime"
	state.player.armor.origin_planet_id = "dustball_prime"
	state.player.captures_by_target = {"gloop": 6}
	state.select_bounty(bounty)
	await process_frame
	await process_frame
	if save_frame("ui_briefing.png") != OK:
		quit(1)
		return
	state.choose_approach("quiet_net")
	await process_frame
	await process_frame
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_hunt_event.png") != OK:
		quit(1)
		return
	state.resolve_hunt_event("detour")
	await process_frame
	await process_frame
	state.begin_combat()
	state.player_hp -= 21
	state.enemy_hp -= 34
	state.combat_round = 4
	state.combat_events.assign([
		{"actor": "player", "action": "Ricochete de Plasma", "damage": 14, "quality": "CRÍTICO", "effect": "EMBOSCADA +5"},
		{"actor": "enemy", "action": "Tapa Tentacular", "damage": 8, "quality": "ACERTO", "effect": "AMORTECEDOR -2"},
	])
	scene.last_combat_message = "Ricochete de Plasma causa 14. Tapa Tentacular responde com 8."
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_combat.png") != OK:
		quit(1)
		return

	state.combat_summary.rounds = 4
	state.combat_summary.damage_dealt = 70
	state.combat_summary.damage_taken = 21
	state.combat_summary.damage_prevented = 8
	state.combat_summary.critical_hits = 1
	state.enemy_hp = 0
	state.finish_combat(true)
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_victory.png") != OK:
		quit(1)
		return

	state.open_reward()
	state.player.capture_streak = 3
	state.player.best_capture_streak = 3
	state.pending_loot.rarity = "Raro"
	state.pending_loot.color = "#58d9ff"
	state.pending_loot.trait = {"id": "ambush_capacitor", "name": "CAPACITOR DE EMBOSCADA", "description": "+5 dano no primeiro disparo.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 5}
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.42).timeout
	if save_frame("ui_reward.png") != OK:
		quit(1)
		return
	var regular_reward_bounty: Dictionary = state.current_bounty.duplicate(true)
	state.current_bounty = ContentDB.apply_approach(ContentDB.get_target(str(regular_reward_bounty.id)), ContentDB.CONTRACT_APPROACHES[2])
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_reward_corporate.png") != OK:
		quit(1)
		return
	state.current_bounty = regular_reward_bounty
	state.player.captures_by_target = {"gloop": 2}
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_reward_mastery_unlock.png") != OK:
		quit(1)
		return
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_reward_unlock.png") != OK:
		quit(1)
		return
	state.player.captures_by_target = {"gloop": 6}
	state.player.captures_by_planet = {}
	var featured_loot: Dictionary = state.pending_loot.duplicate(true)
	state.pending_loot = {"id": "capture_instant_scrap", "name": "Zapper de Garantia Vencida", "description": "Já veio tecnicamente reciclado.", "slot": "weapon", "power": 0, "rarity": "Comum", "color": "#b9c2d9"}
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.42).timeout
	if save_frame("ui_reward_recycle.png") != OK:
		quit(1)
		return
	state.pending_loot = featured_loot
	state.claim_reward(true)
	state.player.scrap = 18
	state.player.inventory.append({"id": "capture_spare", "name": "Colete Fiscal Vencido", "description": "A proteção expirou no trimestre passado.", "slot": "armor", "origin_planet_id": "dustball_prime", "power": 5, "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "capture_old_weapon", "name": "Zapper de Gaveta", "description": "Dispara melhor quando a gaveta está aberta.", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "capture_old_armor", "name": "Colete Pré-Amassado", "description": "Economiza o trabalho do primeiro impacto.", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "capture_upgrade_weapon", "name": "Carabina de Cláusula Curta", "description": "O contrato termina antes do carregador.", "slot": "weapon", "origin_planet_id": "congelaria_sa", "power": 7, "rarity": "Raro", "color": "#58d9ff", "trait": {"id": "argument_amplifier", "name": "AMPLIFICADOR DE ARGUMENTO", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6}})
	state.player.inventory.append({"id": "capture_alt_armor", "name": "Colete de Turno Noturno", "description": "Protege melhor depois do expediente.", "slot": "armor", "origin_planet_id": "congelaria_sa", "power": 6, "rarity": "Raro", "color": "#58d9ff", "trait": {"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "power_bonus": 0, "health_bonus": 14}})
	state.save_equipment_loadout(0)
	state.equip_from_inventory("capture_upgrade_weapon")
	state.equip_from_inventory("capture_alt_armor")
	state.player.weapon.integrity_upgrades = 2
	state.player.weapon.power_upgrades = 2
	state.player.armor.integrity_upgrades = 1
	state.player.armor.power_upgrades = 1
	state.sync_item_to_inventory(state.player.weapon)
	state.sync_item_to_inventory(state.player.armor)
	state.save_equipment_loadout(1)
	state.apply_equipment_loadout(0)
	state.player.captures_by_target = {"gloop": 3}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 3}
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_arsenal.png") != OK:
		quit(1)
		return
	scene.inventory_filter = "weapon"
	scene.inventory_sort = "rarity"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_arsenal_filtered.png") != OK:
		quit(1)
		return
	state.player.current_planet_id = "ferro_velho_omega"
	state.player.level = 16
	state.player.base_power = 40
	state.player.scrap = 50
	state.player.weapon = {"id": "capture_omega_weapon", "name": "Prensa Portátil", "slot": "weapon", "power": 56, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "ferro_velho_omega", "integrity_upgrades": 3, "trait": {"id": "illegal_servos", "name": "SERVOS NÃO DECLARADOS", "description": "+2 poder.", "power_bonus": 2}}
	state.player.armor = {"id": "capture_omega_armor", "name": "Chassi Executivo", "slot": "armor", "power": 49, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "ferro_velho_omega", "integrity_upgrades": 3, "trait": {"id": "argument_amplifier", "name": "AMPLIFICADOR DE ARGUMENTO", "description": "+1 poder e +8 integridade.", "power_bonus": 1, "health_bonus": 8}}
	state.player.inventory = [state.player.weapon.duplicate(true), state.player.armor.duplicate(true)]
	state.player.captures_by_target = {"bolt_collector": 3, "doctor_patchwork": 3, "crane_king": 3}
	state.player.captures_by_planet = {"ferro_velho_omega": 9}
	scene.inventory_filter = "all"
	scene.inventory_sort = "power"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_arsenal_omega_boss.png") != OK:
		quit(1)
		return
	scene.inventory_filter = "all"
	scene.inventory_sort = "power"
	state.player.wins = 10
	state.player.reputation = 3
	state.player.level = 4
	state.player.base_power = 16
	state.player.weapon = {"name": "Canhão de Recibos", "slot": "weapon", "power": 15, "rarity": "Raro", "color": "#58d9ff"}
	state.player.armor = {"name": "Poncho de Titânio", "slot": "armor", "power": 11, "rarity": "Raro", "color": "#58d9ff"}
	state.player.current_planet_id = ContentDB.PLANET.id
	state.player.completed_planets = [ContentDB.PLANET.id]
	state.player.captures_by_target = {"gloop": 4, "baron_boom": 3, "madame_vacuum": 3, "mayor_gold_dust": 1}
	state.player.captures_by_planet = {ContentDB.PLANET.id: 10}
	state.chapter_completion = {
		"planet": ContentDB.PLANET.duplicate(true),
		"target": ContentDB.TARGETS[3].duplicate(true),
		"total_captures": 10,
		"credits": ContentDB.TARGETS[3].credits,
		"xp": ContentDB.TARGETS[3].xp,
	}
	state.phase = state.Phase.CHAPTER_COMPLETE
	scene.view_mode = "board"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_chapter_complete.png") != OK:
		quit(1)
		return
	state.continue_after_chapter()
	await process_frame
	await process_frame
	var bounty_scroll := scene.content.find_child("BountyScroll", true, false) as ScrollContainer
	if bounty_scroll:
		await create_timer(0.1).timeout
		var scroll_bar := bounty_scroll.get_v_scroll_bar()
		bounty_scroll.scroll_vertical = maxi(0, roundi(scroll_bar.max_value - scroll_bar.page))
		await process_frame
		await process_frame
	else:
		printerr("Failed to locate BountyScroll for boss capture")
		quit(1)
		return
	if save_frame("ui_boss_board.png") != OK:
		quit(1)
		return
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	await process_frame
	if save_frame("ui_galaxy_map.png") != OK:
		quit(1)
		return
	scene.view_mode = "board"
	state.travel_to_planet("congelaria_sa")
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_congelaria_board.png") != OK:
		quit(1)
		return
	state.start_bounty(ContentDB.TARGETS[4].duplicate(true))
	state.hunt_event = ContentDB.HUNT_EVENTS[2].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 6.0
	state.hunt_remaining_after_event = 7.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_congelaria_event.png") != OK:
		quit(1)
		return
	state.abandon_bounty()
	await process_frame
	await process_frame
	state.player.wins = 19
	state.player.captures_by_planet.congelaria_sa = 9
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[7].duplicate(true)
	state.pending_loot = {"id": "kelvin_capture", "name": "Termostato Executivo", "description": "A temperatura ideal exige senha de diretoria.", "slot": "armor", "power": 18, "rarity": "Épico", "color": "#d789ff"}
	state.claim_reward(true)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_congelaria_complete.png") != OK:
		quit(1)
		return
	state.continue_after_chapter()
	await process_frame
	await process_frame
	state.player.level = 6
	state.player.base_power = 20
	state.player.weapon = {"name": "Carabina Criogênica Reversa", "slot": "weapon", "power": 21, "rarity": "Raro", "color": "#58d9ff"}
	state.player.armor = {"name": "Terno de Fibra Glacial", "slot": "armor", "power": 17, "rarity": "Raro", "color": "#58d9ff"}
	state.travel_to_planet("micelia_404")
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_micelia_board.png") != OK:
		quit(1)
		return
	state.player.wins = 29
	state.player.captures_by_planet.micelia_404 = 9
	state.player.level = 11
	state.player.base_power = 30
	state.player.weapon = {"name": "Canhão de Compostagem Rápida", "slot": "weapon", "power": 36, "rarity": "Épico", "color": "#d789ff"}
	state.player.armor = {"name": "Poncho de Folha Carnívora", "slot": "armor", "power": 30, "rarity": "Épico", "color": "#d789ff"}
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[11].duplicate(true)
	state.pending_loot = {"id": "mycelia_capture", "name": "Nó da Rede Planetária", "description": "Processa pensamentos, boletos e fotossíntese simultaneamente.", "slot": "weapon", "power": 42, "rarity": "Épico", "color": "#d789ff"}
	state.claim_reward(true)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_micelia_complete.png") != OK:
		quit(1)
		return
	state.continue_after_chapter()
	await process_frame
	await process_frame
	state.player.level = 14
	state.player.base_power = 36
	state.player.weapon = {"name": "Carabina de Rebite Quântico", "slot": "weapon", "power": 45, "rarity": "Épico", "color": "#d789ff", "trait": {"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0}}
	state.player.armor = {"name": "Armadura de Para-Choques", "slot": "armor", "power": 38, "rarity": "Raro", "color": "#58d9ff", "trait": {"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "power_bonus": 0, "health_bonus": 14}}
	state.travel_to_planet("ferro_velho_omega")
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_omega_board.png") != OK:
		quit(1)
		return
	state.select_bounty(ContentDB.TARGETS[12])
	state.choose_approach("quiet_net")
	state.hunt_event = ContentDB.HUNT_EVENTS[6].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 4.0
	state.hunt_remaining_after_event = 4.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_omega_event.png") != OK:
		quit(1)
		return
	state.resolve_hunt_event("follow_debris")
	state.begin_combat()
	scene.render()
	scene.on_combat_timer()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_omega_combat.png") != OK:
		quit(1)
		return
	state.combat_summary.rounds = 6
	state.combat_summary.damage_dealt = 128
	state.combat_summary.damage_taken = CoreRules.max_health(state.player)
	state.combat_summary.damage_prevented = 10
	state.player_hp = 0
	state.enemy_hp = 37
	state.finish_combat(false)
	scene.view_mode = "board"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_defeat_report.png") != OK:
		quit(1)
		return
	var defeat_workshop := scene.find_child("DefeatWorkshopAction", true, false) as Button
	if defeat_workshop:
		defeat_workshop.pressed.emit()
		await process_frame
		await process_frame
		await create_timer(0.12).timeout
	else:
		printerr("Failed to locate defeat workshop route for capture")
		quit(1)
		return
	if save_frame("ui_defeat_workshop.png") != OK:
		quit(1)
		return
	var recommended_upgrade: Button = null
	for candidate in scene.find_children("*", "Button", true, false):
		var candidate_button := candidate as Button
		if str(candidate_button.text).begins_with("★"):
			recommended_upgrade = candidate_button
			break
	if recommended_upgrade:
		recommended_upgrade.pressed.emit()
		await process_frame
		await process_frame
		await create_timer(0.12).timeout
	else:
		printerr("Failed to locate recommended revenge upgrade for capture")
		quit(1)
		return
	if save_frame("ui_defeat_workshop_upgraded.png") != OK:
		quit(1)
		return
	scene.view_mode = "board"
	state.player.wins = 39
	state.player.captures_by_planet.ferro_velho_omega = 9
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[15].duplicate(true)
	state.pending_loot = {"id": "omega_capture", "name": "Núcleo do Compactador", "description": "Ainda classifica continentes como peças pequenas.", "slot": "armor", "power": 49, "rarity": "Épico", "color": "#d789ff", "trait": {"id": "illegal_servos", "name": "SERVOS NÃO DECLARADOS", "description": "+1 poder e +8 integridade.", "power_bonus": 1, "health_bonus": 8}}
	state.claim_reward(true)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_omega_complete.png") != OK:
		quit(1)
		return
	state.continue_after_chapter()
	state.player.level = 18
	state.player.base_power = 44
	state.player.weapon = {"name": "Revólver de Roleta Orbital", "slot": "weapon", "power": 62, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "cassino_quasar", "trait": {"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2}}
	state.player.armor = {"name": "Smoking Antiazar", "slot": "armor", "power": 54, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "cassino_quasar", "trait": {"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "health_bonus": 14}}
	state.travel_to_planet("cassino_quasar")
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_quasar_board.png") != OK:
		quit(1)
		return
	state.select_bounty(ContentDB.TARGETS[16])
	state.choose_approach("quiet_net")
	state.hunt_event = ContentDB.HUNT_EVENTS[8].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 5.0
	state.hunt_remaining_after_event = 5.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.12).timeout
	if save_frame("ui_quasar_event.png") != OK:
		quit(1)
		return
	state.player.wins = 49
	state.player.captures_by_planet.cassino_quasar = 9
	state.phase = state.Phase.REWARD
	state.current_bounty = ContentDB.TARGETS[19].duplicate(true)
	state.pending_loot = {"id": "quasar_capture", "name": "Chave do Cofre Improvável", "description": "Abre todas as portas, desde que nenhuma seja a certa.", "slot": "weapon", "origin_planet_id": "cassino_quasar", "power": 64, "rarity": "Épico", "color": "#d789ff", "trait": {"id": "ambush_capacitor", "name": "CAPACITOR DE EMBOSCADA", "description": "+5 dano no primeiro disparo.", "opening_damage_bonus": 5}}
	state.claim_reward(true)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	if save_frame("ui_quasar_complete.png") != OK:
		quit(1)
		return
	state.player.afk_credits_earned = 1460
	state.player.afk_scrap_earned = 28
	state.player.scrap_recycled_total = 42
	state.player.claimed_milestones = ["first_warrant"]
	state.player.career_credits_claimed = 40
	state.continue_after_chapter()
	await process_frame
	await process_frame
	scene.view_mode = "career"
	scene.render()
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	await process_frame
	if save_frame("ui_career.png") != OK:
		quit(1)
		return
	var archive_jump := scene.find_child("CareerArchiveJump", true, false) as Button
	if archive_jump:
		archive_jump.pressed.emit()
		await process_frame
		await process_frame
		await create_timer(0.12).timeout
	else:
		printerr("Failed to locate wanted archive jump for capture")
		quit(1)
		return
	if save_frame("ui_wanted_archive.png") != OK:
		quit(1)
		return
	scene.free()
	await process_frame
	await create_timer(0.5).timeout
	print("Captured primary UI, reward/mastery/warrant-unlock decisions, defeat recovery and upgrade, AFK return, career, wanted archive, arsenal filters, galaxy, incidents, five finales, and planet boards to %s" % OUTPUT_DIR)
	quit(0)


func save_frame(filename: String) -> Error:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("Failed to capture %s: %s" % [path, error_string(error)])
	return error
