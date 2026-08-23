extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
var test_save := "res://.godot/crooked_galaxy_test_save_%s.json" % OS.get_process_id()
var legacy_save := "res://.godot/crooked_galaxy_legacy_save_%s.json" % OS.get_process_id()

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
	source.player.locked_item_ids = ["test_loot"]
	source.player.equipment_loadouts = [{"weapon_id": "test_loot", "armor_id": "starter_armor"}, {"weapon_id": "", "armor_id": ""}]
	source.phase = source.Phase.VICTORY
	source.current_bounty = ContentDB.TARGETS[0].duplicate(true)
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
	source.combat_summary = {"won": true, "rounds": 4, "damage_dealt": 70, "damage_taken": 22, "damage_prevented": 8, "target_id": "gloop"}
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
	check(restored.player.locked_item_ids.has("test_loot"), "protected inventory ids survive save and load")
	check(str(restored.player.equipment_loadouts[0].weapon_id) == "test_loot", "equipment loadouts survive save and load")
	check(restored.phase == restored.Phase.VICTORY, "capture phase survives save and load")
	check(str(restored.pending_loot.id) == "test_loot", "pending reward survives save and load")
	check(str(restored.pending_loot.origin_planet_id) == "dustball_prime", "pending reward preserves its planet of origin")
	check(restored.combat_events.size() == 1, "finishing action survives save and load")
	check(str(restored.combat_events[0].action) == "Teste de Impacto", "action data is restored")
	check(int(restored.combat_summary.rounds) == 4 and int(restored.combat_summary.damage_prevented) == 8, "aggregate combat evidence survives save and load")

	source.phase = source.Phase.BOARD
	source.current_bounty = {}
	source.pending_loot = {}
	source.select_bounty(ContentDB.TARGETS[0])
	var restored_briefing = StateScript.new()
	restored_briefing.save_path = test_save
	restored_briefing.load_game()
	check(restored_briefing.phase == restored_briefing.Phase.BRIEFING, "briefing phase survives save and load")
	check(restored_briefing.offered_approaches.size() == 3, "approach choices survive save and load")

	source.choose_approach("quiet_net")
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

	source.player.completed_planets = [ContentDB.PLANET.id]
	source.player.current_planet_id = "congelaria_sa"
	source.player.captures_by_target = {"mayor_gold_dust": 1}
	source.player.captures_by_planet = {ContentDB.PLANET.id: 10, "congelaria_sa": 4}
	source.chapter_completion = {"planet": ContentDB.PLANET.duplicate(true), "target": ContentDB.TARGETS[3].duplicate(true)}
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
	var migrated_file := FileAccess.open(legacy_save, FileAccess.READ)
	var migrated_payload = JSON.parse_string(migrated_file.get_as_text())
	check(int(migrated_payload.get("version", 0)) == StateScript.SAVE_VERSION, "successful migration is persisted immediately")
	check(migrated.migrate_save_payload({"version": StateScript.SAVE_VERSION + 1}).is_empty(), "future save versions are rejected safely")

	source.free()
	restored.free()
	restored_briefing.free()
	restored_event.free()
	restored_chapter.free()
	offline.free()
	migrated.free()
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	if FileAccess.file_exists(legacy_save):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_save))
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
