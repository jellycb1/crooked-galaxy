extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.rng.seed = 7331

	var bounty: Dictionary = Content.TARGETS[0].duplicate(true)
	bounty.health = 1
	state.select_bounty(bounty)
	check(state.phase == state.Phase.BRIEFING, "selecting a target opens the briefing")
	check(state.offered_approaches.size() == 3, "briefing offers three approaches")
	state.choose_approach("quiet_net")
	check(state.phase == state.Phase.HUNT, "choosing an approach starts a hunt")
	check(str(state.current_bounty.approach.id) == "quiet_net", "approach is attached to the contract")
	var active_bounty: Dictionary = state.current_bounty.duplicate(true)

	state.hunt_ends_at = 0.0
	state.update_hunt()
	check(state.phase == state.Phase.COMBAT, "elapsed hunt starts combat")
	check(state.player_hp > 0 and state.enemy_hp == 1, "combat initializes health")

	var result: Dictionary = state.combat_step()
	check(bool(result.get("won", false)), "winning combat is detected")
	check(state.phase == state.Phase.VICTORY, "victory opens the capture beat")
	check(state.combat_events.size() == 1, "combat records the finishing action")
	check(not state.pending_loot.is_empty(), "victory generates loot")
	state.open_reward()
	check(state.phase == state.Phase.REWARD, "capture beat opens the reward phase")

	var credits_before := int(state.player.credits)
	var claimed_item: Dictionary = state.pending_loot.duplicate(true)
	var summary := state.claim_reward(true)
	check(state.phase == state.Phase.BOARD, "claiming returns to the bounty board")
	check(int(state.player.credits) == credits_before + int(active_bounty.credits), "modified credits are awarded")
	check(int(summary.xp) == int(active_bounty.xp), "modified XP reward is reported")
	check(state.player.inventory.size() == 1, "loot is retained in inventory")
	check(int(state.player.wins) == 1, "victory progression is retained")
	check(str(state.player[str(claimed_item.slot)].id) == str(claimed_item.id), "claimed upgrade is equipped")
	check(not state.last_notice.is_empty(), "reward feedback survives the screen transition")
	check(int(state.player.reputation) == 0, "rank requires three captures")
	check(not state.scrap_item(str(claimed_item.id)), "equipped item cannot be recycled")
	var spare := {"id": "spare_epic", "name": "Sucata de Teste", "description": "Feita para sumir.", "slot": "armor", "power": 12, "rarity": "Épico", "color": "#d789ff"}
	state.player.inventory.append(spare)
	check(state.scrap_item("spare_epic"), "unequipped loot can be recycled")
	check(int(state.player.scrap) == 16, "recycling grants deterministic scrap")
	var equipped_power := int(state.player[str(claimed_item.slot)].power)
	var upgrade_cost := CoreRules.equipment_upgrade_cost(state.player[str(claimed_item.slot)])
	check(state.upgrade_equipped(str(claimed_item.slot)), "scrap upgrades equipped gear")
	check(int(state.player.scrap) == 16 - upgrade_cost, "workshop charges the visible upgrade cost")
	check(int(state.player[str(claimed_item.slot)].power) == equipped_power + 1, "workshop adds one equipment power")

	state.start_bounty(Content.TARGETS[0].duplicate(true))
	state.hunt_event = Content.HUNT_EVENTS[0].duplicate(true)
	var event_time := Time.get_unix_time_from_system()
	state.hunt_started_at = event_time - 3.0
	state.hunt_ends_at = event_time + 3.0
	check(state.update_hunt(), "mid-hunt threshold opens an incident")
	check(state.phase == state.Phase.HUNT_EVENT, "hunt pauses for the incident")
	var credits_for_event := int(state.player.credits)
	state.player.credits = 0
	check(not state.resolve_hunt_event("bribe"), "unaffordable event choice is rejected")
	state.player.credits = credits_for_event
	check(state.resolve_hunt_event("bribe"), "affordable event choice resolves")
	check(state.phase == state.Phase.HUNT, "hunt resumes after the incident")
	check(int(state.player.credits) == credits_for_event - 8, "event cost is charged")
	check(state.current_bounty.defense == 3, "event consequence modifies the target")
	check(state.current_bounty.has("hunt_event_result"), "event result is retained for feedback")
	state.begin_combat()
	state.enemy_hp = 9999
	state.player_hp = 1
	var defeat := state.combat_step()
	check(bool(defeat.get("finished", false)) and not bool(defeat.get("won", true)), "defeat is detected")
	check(state.phase == state.Phase.BOARD, "defeat returns to the bounty board")
	check(not state.last_notice.is_empty(), "defeat explains what happened")
	state.select_bounty(Content.TARGETS[0])
	state.cancel_briefing()
	check(state.phase == state.Phase.BOARD and state.current_bounty.is_empty(), "briefing can be cancelled safely")
	state.toggle_sound()
	check(not bool(state.player.sound_enabled), "audio preference can be disabled")
	check(not state.travel_to_planet("congelaria_sa"), "travel rejects locked planets")

	var chapter_state = StateScript.new()
	chapter_state.persistence_enabled = false
	chapter_state.player = chapter_state.default_player()
	chapter_state.player.wins = 9
	chapter_state.player.reputation = 3
	chapter_state.phase = chapter_state.Phase.REWARD
	chapter_state.current_bounty = Content.TARGETS[3].duplicate(true)
	chapter_state.pending_loot = {
		"id": "chapter_test_loot", "name": "Distintivo Apreendido", "description": "Prova A.",
		"slot": "armor", "power": 12, "rarity": "Raro", "color": "#58d9ff",
	}
	var chapter_summary := chapter_state.claim_reward(true)
	check(chapter_state.phase == chapter_state.Phase.CHAPTER_COMPLETE, "first boss capture opens the chapter finale")
	check(bool(chapter_summary.chapter_complete), "boss reward reports chapter completion")
	check(int(chapter_state.player.captures_by_target.mayor_gold_dust) == 1, "captures are tracked per target")
	check(chapter_state.player.completed_planets.has(Content.PLANET.id), "completed planet is retained in progression")
	check(str(chapter_state.chapter_completion.target.id) == "mayor_gold_dust", "chapter finale retains the defeated boss")
	chapter_state.continue_after_chapter()
	check(chapter_state.phase == chapter_state.Phase.BOARD, "chapter finale returns to repeatable bounties")
	check(chapter_state.travel_to_planet("congelaria_sa"), "chapter completion opens travel to the next planet")
	check(str(chapter_state.player.current_planet_id) == "congelaria_sa", "travel updates the active planet")
	chapter_state.phase = chapter_state.Phase.REWARD
	chapter_state.current_bounty = Content.TARGETS[3].duplicate(true)
	chapter_state.pending_loot = {
		"id": "repeat_boss_loot", "name": "Carimbo Reincidente", "description": "Prova B.",
		"slot": "weapon", "power": 13, "rarity": "Comum", "color": "#b9c2d9",
	}
	var repeat_summary := chapter_state.claim_reward(false)
	check(chapter_state.phase == chapter_state.Phase.BOARD, "repeat boss capture skips the one-time finale")
	check(not bool(repeat_summary.chapter_complete), "planet completion is awarded only once")
	check(int(chapter_state.player.captures_by_target.mayor_gold_dust) == 2, "repeat captures increment the target record")
	check(int(chapter_state.player.reputation) == 3, "reputation stays capped at the highest available rank")
	chapter_state.free()

	var frozen_state = StateScript.new()
	frozen_state.persistence_enabled = false
	frozen_state.player = frozen_state.default_player()
	frozen_state.player.reputation = 3
	frozen_state.player.wins = 19
	frozen_state.player.completed_planets = [Content.PLANET.id]
	frozen_state.player.current_planet_id = "congelaria_sa"
	frozen_state.player.captures_by_planet = {Content.PLANET.id: 10, "congelaria_sa": 9}
	frozen_state.phase = frozen_state.Phase.REWARD
	frozen_state.current_bounty = Content.TARGETS[7].duplicate(true)
	frozen_state.pending_loot = {
		"id": "kelvin_test_loot", "name": "Termostato Executivo", "description": "Ainda bloqueado.",
		"slot": "armor", "power": 18, "rarity": "Épico", "color": "#d789ff",
	}
	var frozen_summary := frozen_state.claim_reward(true)
	check(frozen_state.phase == frozen_state.Phase.CHAPTER_COMPLETE, "Congelaria boss opens the reusable chapter finale")
	check(bool(frozen_summary.chapter_complete), "second planet reports chapter completion")
	check(frozen_state.player.completed_planets.has("congelaria_sa"), "second completed planet persists in progression")
	check(frozen_state.planet_capture_count("congelaria_sa") == 10, "planet capture counter advances independently")
	check(str(frozen_state.chapter_completion.planet.id) == "congelaria_sa", "finale resolves the correct planet metadata")
	frozen_state.free()

	state.free()
	if failures == 0:
		print("PASS: complete bounty flow")
		quit(0)
	else:
		printerr("FAIL: %d flow test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
