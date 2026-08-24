extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var test_save := "res://.godot/crooked_galaxy_test_save_%s.json" % OS.get_process_id()
var legacy_save := "res://.godot/crooked_galaxy_legacy_save_%s.json" % OS.get_process_id()
var damaged_save := "res://.godot/crooked_galaxy_damaged_save_%s.json" % OS.get_process_id()

var failures := 0


func _init() -> void:
	var source = StateScript.new()
	source.save_path = test_save
	source.player = source.default_player()
	source.player.credits = 123
	source.player.scrap = 27
	source.player.scrap_recycled_total = 31
	source.player.afk_credits_earned = 220
	source.player.afk_scrap_earned = 8
	source.player.claimed_milestones = ["first_warrant"]
	source.player.career_credits_claimed = 40
	source.player.capture_streak = 4
	source.player.best_capture_streak = 7
	source.player.weapon.integrity_upgrades = 2
	source.player.weapon.power_upgrades = 3
	source.player.weapon.origin_planet_id = "dustball_prime"
	source.player.armor.origin_planet_id = "dustball_prime"
	source.player.locked_item_ids = ["starter_weapon"]
	source.player.equipment_loadouts = [{"weapon_id": "starter_weapon", "armor_id": "starter_armor"}, {"weapon_id": "", "armor_id": ""}]
	source.phase = source.Phase.VICTORY
	source.current_bounty = ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[2])
	source.pending_loot = {
		"id": "test_loot",
		"name": "Zapper de Teste",
		"description": "Existe apenas durante o teste.",
		"slot": "weapon",
		"origin_planet_id": "dustball_prime",
		"power": 7,
		"rarity": "Raro",
		"color": "#58d9ff",
	}
	source.combat_events.assign([
		{"actor": "player", "action": "Teste de Impacto", "damage": 17, "quality": "CRÍTICO"},
	])
	source.combat_summary = {"won": true, "rounds": 4, "damage_dealt": 70, "damage_taken": 22, "damage_prevented": 8, "target_id": "gloop", "target_name": "Alvo Forjado", "enemy_hp_remaining": 9999, "kit_origin": "invented_planet"}
	source.save_game()
	var saved_file := FileAccess.open(test_save, FileAccess.READ)
	var saved_payload = JSON.parse_string(saved_file.get_as_text())
	check(int(saved_payload.get("version", 0)) == StateScript.SAVE_VERSION, "new saves use the current schema version")

	var restored = StateScript.new()
	restored.save_path = test_save
	restored.load_game()
	check(int(restored.player.credits) == 123, "player data survives save and load")
	check(int(restored.player.scrap) == 27, "workshop currency survives save and load")
	check(int(restored.player.scrap_recycled_total) == 31, "lifetime recycling survives save and load")
	check(int(restored.player.afk_credits_earned) == 220 and int(restored.player.afk_scrap_earned) == 8, "AFK career totals survive save and load")
	check(restored.player.claimed_milestones.has("first_warrant"), "claimed career rewards survive save and load")
	check(int(restored.player.career_credits_claimed) == 40, "career reward totals survive save and load")
	check(int(restored.player.capture_streak) == 4 and int(restored.player.best_capture_streak) == 7, "capture streaks survive save and load")
	check(int(restored.player.weapon.integrity_upgrades) == 2, "equipment reinforcement survives save and load")
	check(int(restored.player.weapon.power_upgrades) == 3, "power calibration history survives save and load")
	check(CoreRules.equipment_set_origin(restored.player) == "dustball_prime", "planetary kit origin survives save and load")
	check(restored.player.locked_item_ids.has("starter_weapon"), "protected equipment ids survive save and load")
	check(str(restored.player.equipment_loadouts[0].weapon_id) == "starter_weapon", "equipment loadouts survive save and load")
	check(restored.phase == restored.Phase.VICTORY, "capture phase survives save and load")
	check(int(restored.current_bounty.get("scrap_reward", 0)) == 2 and int(restored.current_bounty.get("loot_power", 0)) == int(ContentDB.TARGETS[0].power), "corporate reward and canonical loot tier survive an interrupted capture")
	check(str(restored.pending_loot.id) == "test_loot", "pending reward survives save and load")
	check(str(restored.pending_loot.origin_planet_id) == "dustball_prime", "pending reward preserves its planet of origin")
	check(restored.combat_events.size() == 1, "finishing action survives save and load")
	check(str(restored.combat_events[0].action) == "Teste de Impacto", "action data is restored")
	check(int(restored.combat_summary.rounds) == 4 and int(restored.combat_summary.damage_prevented) == 8, "aggregate combat evidence survives save and load")
	check(str(restored.combat_summary.target_name) == str(ContentDB.TARGETS[0].name) and int(restored.combat_summary.enemy_hp_remaining) <= int(restored.combat_summary.target_max_health), "combat evidence restores canonical target identity and bounded remaining health")
	check(not restored.combat_summary.has("kit_origin"), "combat evidence cannot retain an unknown planetary kit")

	source.phase = source.Phase.BOARD
	source.current_bounty = {}
	source.pending_loot = {}
	source.select_bounty(ContentDB.TARGETS[0])
	var restored_briefing = StateScript.new()
	restored_briefing.save_path = test_save
	restored_briefing.last_notice = "Contrato pago: recibo antigo equipado"
	restored_briefing.last_notice_context = "reward_equipped"
	restored_briefing.afk_report = {"credits": 999, "scrap": 999}
	restored_briefing.load_game()
	check(restored_briefing.phase == restored_briefing.Phase.BRIEFING, "briefing phase survives save and load")
	check(restored_briefing.offered_approaches.size() == 3, "approach choices survive save and load")
	check(restored_briefing.last_notice.is_empty() and restored_briefing.last_notice_context.is_empty(), "loading cannot inherit a transient receipt from the previous runtime")
	check(int(restored_briefing.afk_report.get("credits", 0)) != 999, "loading replaces stale AFK feedback instead of merging it into the save")

	source.choose_approach("quiet_net", {"target_id": "gloop", "approach_id": "quiet_net", "approach_name": "Rede Silenciosa", "odds": 0.74})
	source.hunt_event = ContentDB.HUNT_EVENTS[1].duplicate(true)
	source.hunt_event_triggered = true
	source.hunt_elapsed_before_event = 4.0
	source.hunt_remaining_after_event = 5.0
	source.phase = source.Phase.HUNT_EVENT
	source.save_game()
	var restored_event = StateScript.new()
	restored_event.save_path = test_save
	restored_event.load_game()
	check(restored_event.phase == restored_event.Phase.HUNT_EVENT, "mid-hunt incident survives save and load")
	check(str(restored_event.hunt_event.id) == "bounty_streamer", "incident content is restored")
	check(is_equal_approx(restored_event.hunt_remaining_after_event, 5.0), "paused hunt time is restored")
	check(not bool(restored_event.current_bounty.field_test_context.overridden) and str(restored_event.current_bounty.field_test_context.tested_approach_id) == "quiet_net", "confirmed field-test route survives an interrupted hunt")

	source.player.completed_planets = [ContentDB.PLANET.id]
	source.player.current_planet_id = "congelaria_sa"
	source.player.captures_by_target = {"mayor_gold_dust": 1}
	source.player.captures_by_planet = {ContentDB.PLANET.id: 10, "congelaria_sa": 4}
	var forged_chapter_planet: Dictionary = ContentDB.PLANET.duplicate(true)
	forged_chapter_planet.name = "Planeta Forjado"
	var forged_chapter_target: Dictionary = ContentDB.TARGETS[3].duplicate(true)
	forged_chapter_target.name = "Chefe Forjado"
	source.chapter_completion = {"planet": forged_chapter_planet, "target": forged_chapter_target, "total_captures": -12, "credits": -100, "xp": -20}
	source.phase = source.Phase.CHAPTER_COMPLETE
	source.save_game()
	var restored_chapter = StateScript.new()
	restored_chapter.save_path = test_save
	restored_chapter.load_game()
	check(restored_chapter.phase == restored_chapter.Phase.CHAPTER_COMPLETE, "chapter finale survives save and load")
	check(restored_chapter.player.completed_planets.has(ContentDB.PLANET.id), "planet completion survives save and load")
	check(str(restored_chapter.player.current_planet_id) == "congelaria_sa", "active travel destination survives save and load")
	check(int(restored_chapter.player.captures_by_target.mayor_gold_dust) == 1, "per-target captures survive save and load")
	check(int(restored_chapter.player.captures_by_planet.congelaria_sa) == 4, "per-planet chapter progress survives save and load")
	check(str(restored_chapter.chapter_completion.target.id) == "mayor_gold_dust", "chapter summary survives save and load")
	check(str(restored_chapter.chapter_completion.planet.name) == str(ContentDB.PLANET.name) and str(restored_chapter.chapter_completion.target.name) == str(ContentDB.TARGETS[3].name), "chapter evidence restores canonical planet and boss identity")
	check(int(restored_chapter.chapter_completion.total_captures) == 0 and int(restored_chapter.chapter_completion.credits) == 0, "chapter evidence clamps impossible negative totals")

	var offline = StateScript.new()
	offline.persistence_enabled = false
	offline.player = offline.default_player()
	offline.player.wins = 5
	offline.player.completed_planets = [ContentDB.PLANET.id, "congelaria_sa"]
	offline.player.credits = 0
	offline.player.scrap = 0
	offline.player.last_seen_unix = 100.0
	var patrol := offline.apply_offline_progress(3700.0)
	check(int(patrol.credits) == 180 and int(offline.player.credits) == 180, "one-hour patrol credits are applied")
	check(int(patrol.scrap) == 4 and int(offline.player.scrap) == 4, "one-hour patrol scrap is applied")
	check(not offline.afk_report.is_empty(), "offline return creates a visible report")
	offline.dismiss_afk_report()
	check(offline.afk_report.is_empty(), "AFK report can be dismissed")

	var legacy_player := source.default_player()
	legacy_player.erase("claimed_milestones")
	legacy_player.erase("career_credits_claimed")
	legacy_player.erase("career_scrap_claimed")
	legacy_player.credits = 77
	legacy_player.wins = 2
	legacy_player.last_seen_unix = Time.get_unix_time_from_system()
	var legacy_file := FileAccess.open(legacy_save, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"version": 1, "player": legacy_player, "phase": source.Phase.BOARD}))
	legacy_file = null
	var migrated = StateScript.new()
	migrated.save_path = legacy_save
	migrated.load_game()
	check(int(migrated.player.credits) == 77, "version one player data survives migration")
	check(migrated.player.claimed_milestones is Array, "migration adds claimed career milestones")
	check(int(migrated.player.career_credits_claimed) == 0, "migration initializes career reward totals")
	check(migrated.player.locked_item_ids is Array and migrated.player.equipment_loadouts.size() == 2, "migration initializes protection and loadouts")
	check(not str(migrated.player.weapon.id).is_empty() and not str(migrated.player.armor.id).is_empty(), "migration assigns stable ids to legacy equipped gear")
	check(migrated.last_notice_context == "system_recovery" and migrated.last_notice.begins_with("SAVE ATUALIZADO"), "legacy migration leaves a concise player-facing recovery notice")
	var migrated_file := FileAccess.open(legacy_save, FileAccess.READ)
	var migrated_payload = JSON.parse_string(migrated_file.get_as_text())
	check(int(migrated_payload.get("version", 0)) == StateScript.SAVE_VERSION, "successful migration is persisted immediately")
	check(migrated.migrate_save_payload({"version": StateScript.SAVE_VERSION + 1}).is_empty(), "future save versions are rejected safely")

	var damaged_file := FileAccess.open(damaged_save, FileAccess.WRITE)
	damaged_file.store_string(JSON.stringify({
		"version": StateScript.SAVE_VERSION,
		"player": {
			"credits": 88,
			"scrap": -5,
			"level": 0,
			"base_power": -20,
			"capture_streak": 4,
			"best_capture_streak": 1,
			"wins": 2,
			"current_planet_id": "planet_that_never_existed",
			"completed_planets": ["planet_that_never_existed", "dustball_prime", "dustball_prime"],
			"claimed_milestones": ["invented_milestone", "first_warrant", "first_warrant"],
			"locked_item_ids": ["missing_item"],
			"weapon": ["not an item"],
			"armor": {"id": "", "name": "", "slot": "armor", "power": "broken"},
			"inventory": [
				"not an item",
				{"id": "", "slot": "weapon"},
				{"id": "nested_bad", "name": "Peça Adulterada", "slot": "weapon", "power": 5, "rarity": "Mítico", "color": "not-a-color", "origin_planet_id": "invented_planet", "trait": {"id": "ambush_capacitor", "name": "CAPACITOR FORJADO", "description": "+999", "opening_damage_bonus": 999}},
			],
			"equipment_loadouts": [{"weapon_id": "missing"}],
			"captures_by_target": {"invented_target": 99, "gloop": -3},
			"captures_by_planet": {"invented_planet": 99, "dustball_prime": 2},
		},
		"phase": source.Phase.REWARD,
		"current_bounty": "missing contract object",
		"pending_loot": ["missing loot object"],
		"hunt_event": "missing incident object",
		"chapter_completion": 17,
	}))
	damaged_file = null
	var repaired = StateScript.new()
	repaired.save_path = damaged_save
	repaired.load_game()
	check(repaired.phase == repaired.Phase.BOARD and repaired.current_bounty.is_empty() and repaired.pending_loot.is_empty(), "damaged interrupted phase falls back safely to the board")
	check(int(repaired.player.credits) == 88 and int(repaired.player.wins) == 2, "phase repair preserves valid player progression")
	check(repaired.player.weapon is Dictionary and not str(repaired.player.weapon.id).is_empty() and repaired.player.armor is Dictionary, "damaged equipment falls back to usable starter items")
	check(repaired.player.inventory is Array and repaired.player.inventory.size() == 1 and repaired.player.captures_by_target is Dictionary, "damaged compound player fields retain only structurally usable inventory")
	var repaired_item: Dictionary = repaired.player.inventory[0]
	check(str(repaired_item.rarity) == "Comum" and str(repaired_item.color) == "#b9c2d9" and not repaired_item.has("origin_planet_id"), "unknown rarity, color, and origin return to canonical item presentation")
	check(str(repaired_item.trait.name) == "CAPACITOR DE EMBOSCADA" and int(repaired_item.trait.opening_damage_bonus) == 5, "known trait ids restore canonical modifiers instead of accepting forged nested values")
	check(repaired.player.equipment_loadouts.size() == 2 and repaired.player.equipment_loadouts.all(func(loadout): return loadout is Dictionary), "damaged loadouts normalize to two usable slots")
	check(int(repaired.player.scrap) == 0 and int(repaired.player.level) == 1 and int(repaired.player.base_power) == 1, "impossible negative progression values are clamped to canonical lower bounds")
	check(int(repaired.player.capture_streak) == 4 and int(repaired.player.best_capture_streak) == 4, "best streak remains coherent with the active streak after repair")
	check(str(repaired.player.current_planet_id) == "congelaria_sa" and repaired.player.completed_planets == ["dustball_prime"], "unknown and duplicate planet ids repair to the latest unlocked canonical route")
	check(repaired.player.captures_by_target == {"gloop": 0} and repaired.player.captures_by_planet == {"dustball_prime": 2}, "unknown capture records cannot affect progression or career milestones")
	check(repaired.player.claimed_milestones == ["first_warrant"] and repaired.player.locked_item_ids.is_empty(), "unknown and duplicate milestone or item ids are removed")
	check(str(repaired.player.equipment_loadouts[0].weapon_id).is_empty(), "loadouts cannot retain references to missing inventory")
	check(repaired.last_notice_context == "system_recovery" and repaired.last_notice.contains("progresso válido preservado"), "damaged save repair explains the recovery without exposing implementation details")
	var repaired_file := FileAccess.open(damaged_save, FileAccess.READ)
	var repaired_payload = JSON.parse_string(repaired_file.get_as_text())
	check(int(repaired_payload.phase) == repaired.Phase.BOARD and repaired_payload.current_bounty is Dictionary, "phase repair is persisted so the same damaged save cannot recur")
	var forged_contract := ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[0])
	forged_contract = ContentDB.apply_hunt_choice(forged_contract, ContentDB.HUNT_EVENTS[0].choices[0])
	forged_contract.power = 999
	forged_contract.credits = 9999
	forged_contract.approach.power_mult = 99.0
	var forged_event: Dictionary = ContentDB.HUNT_EVENTS[0].duplicate(true)
	forged_event.choices[0].credit_mult = 99.0
	repaired_file = FileAccess.open(damaged_save, FileAccess.WRITE)
	repaired_file.store_string(JSON.stringify({
		"version": StateScript.SAVE_VERSION,
		"player": source.default_player(),
		"phase": source.Phase.REWARD,
		"current_bounty": forged_contract,
		"pending_loot": {"id": "pending_forged", "name": "Loot Adulterado", "slot": "weapon", "power": 6, "rarity": "Épico", "color": "#d789ff", "origin_planet_id": "invented_planet", "trait": {"id": "ambush_capacitor", "name": "FORJADO", "description": "+999", "opening_damage_bonus": 999}},
		"hunt_event": forged_event,
	}))
	repaired_file = null
	repaired.load_game()
	check(repaired.phase == repaired.Phase.REWARD and str(repaired.pending_loot.id) == "pending_forged", "usable pending loot preserves the interrupted reward decision during nested repair")
	check(int(repaired.pending_loot.trait.opening_damage_bonus) == 5 and not repaired.pending_loot.has("origin_planet_id"), "pending loot receives the same canonical trait and origin repair as owned equipment")
	var expected_contract := ContentDB.apply_hunt_choice(ContentDB.apply_approach(ContentDB.TARGETS[0], ContentDB.CONTRACT_APPROACHES[0]), ContentDB.HUNT_EVENTS[0].choices[0])
	check(int(repaired.current_bounty.power) == int(expected_contract.power) and int(repaired.current_bounty.credits) == int(expected_contract.credits), "loaded contract economics are rebuilt from canonical target, approach, and incident choice")
	check(float(repaired.current_bounty.approach.power_mult) == float(ContentDB.CONTRACT_APPROACHES[0].power_mult) and repaired.payloads_equivalent(repaired.hunt_event, ContentDB.HUNT_EVENTS[0]), "nested approach and incident catalogs cannot retain forged multipliers")
	repaired_file = FileAccess.open(damaged_save, FileAccess.WRITE)
	repaired_file.store_string(JSON.stringify({
		"version": StateScript.SAVE_VERSION,
		"player": source.default_player(),
		"phase": source.Phase.BRIEFING,
		"current_bounty": ContentDB.TARGETS[0],
		"offered_approaches": [],
	}))
	repaired_file = null
	repaired.load_game()
	check(repaired.phase == repaired.Phase.BRIEFING and repaired.offered_approaches.size() == 3, "valid interrupted briefing reconstructs missing route choices instead of discarding the contract")

	source.free()
	restored.free()
	restored_briefing.free()
	restored_event.free()
	restored_chapter.free()
	offline.free()
	migrated.free()
	repaired.free()
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	if FileAccess.file_exists(legacy_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_save))
	if FileAccess.file_exists(damaged_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(damaged_save))
	if failures == 0:
		print("PASS: save and load preserve an interrupted reward flow")
		quit(0)
	else:
		printerr("FAIL: %d persistence test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
