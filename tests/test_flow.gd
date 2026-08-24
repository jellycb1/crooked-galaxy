extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")
const RewardScript = preload("res://scripts/reward_view.gd")
const ArsenalScript = preload("res://scripts/arsenal_view.gd")

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
	check(bool(state.combat_summary.won) and int(state.combat_summary.rounds) == 1 and int(state.combat_summary.damage_dealt) == 1, "victory retains an exact aggregate combat summary")
	check(not state.pending_loot.is_empty(), "victory generates loot")
	state.open_reward()
	check(state.phase == state.Phase.REWARD, "capture beat opens the reward phase")

	var credits_before := int(state.player.credits)
	var claimed_item: Dictionary = state.pending_loot.duplicate(true)
	var summary := state.claim_reward(true)
	check(state.phase == state.Phase.BOARD, "claiming returns to the bounty board")
	check(int(state.player.credits) == credits_before + int(active_bounty.credits), "modified credits are awarded")
	check(int(summary.xp) == int(active_bounty.xp), "modified XP reward is reported")
	check(state.player.inventory.size() == 2, "loot and replaced starter gear are retained in inventory")
	check(int(state.player.wins) == 1, "victory progression is retained")
	check(str(state.player[str(claimed_item.slot)].id) == str(claimed_item.id), "claimed upgrade is equipped")
	check(str(summary.loot_action) == "equipped" and str(summary.loot_name) == str(claimed_item.name), "reward summary records the applied loot decision")
	check(state.last_notice.contains("%s equipado" % str(claimed_item.name)), "equipped loot decision survives the screen transition")
	check(int(state.player.reputation) == 0, "rank requires three captures")
	var projection_state = StateScript.new()
	projection_state.persistence_enabled = false
	projection_state.player = projection_state.default_player()
	projection_state.player.wins = 2
	projection_state.player.xp = CoreRules.xp_needed(1) - int(Content.TARGETS[0].xp) + 1
	projection_state.player.captures_by_target = {"gloop": 2}
	projection_state.player.captures_by_planet = {"dustball_prime": 2}
	projection_state.phase = projection_state.Phase.REWARD
	projection_state.current_bounty = Content.TARGETS[0].duplicate(true)
	projection_state.pending_loot = {"id": "projected_upgrade", "name": "Prova de Continuidade", "slot": "weapon", "power": 8, "rarity": "Raro", "color": "#58d9ff"}
	var projected_target := Content.target_for_planet_tier("dustball_prime", 1)
	var reward_impact := RewardScript.warrant_impact(projection_state.player, projection_state.pending_loot, projected_target, true, int(projection_state.current_bounty.xp))
	check(int(reward_impact.levels_gained) == 1, "reward projection includes a level crossed by the pending XP")
	projection_state.claim_reward(true)
	var claimed_readiness := ArsenalScript.field_readiness(projection_state)
	check(str(claimed_readiness.target.id) == str(projected_target.id) and str(claimed_readiness.approach.id) == str(reward_impact.approach_id), "post-claim field test keeps the reward's projected target and fixed route")
	check(is_equal_approx(float(claimed_readiness.current_odds), float(reward_impact.projected_odds)), "post-claim field test exactly confirms the reward's projected odds after XP and equipment")
	projection_state.free()
	var streak_state = StateScript.new()
	streak_state.persistence_enabled = false
	streak_state.player = streak_state.default_player()
	streak_state.player.capture_streak = 1
	streak_state.phase = streak_state.Phase.REWARD
	streak_state.current_bounty = Content.TARGETS[0].duplicate(true)
	streak_state.pending_loot = {"id": "streak_loot", "name": "Troféu de Embalo", "slot": "weapon", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	var streak_credits_before := int(streak_state.player.credits)
	var streak_summary := streak_state.claim_reward(false)
	check(int(streak_summary.streak) == 2 and int(streak_state.player.capture_streak) == 2, "consecutive reward advances the capture streak")
	check(str(streak_summary.loot_action) == "stored" and streak_state.last_notice.contains("Troféu de Embalo guardado"), "stored loot decision survives in the contract record")
	check(int(streak_summary.streak_bonus) > 0 and int(streak_state.player.credits) == streak_credits_before + int(streak_summary.credits), "consecutive reward pays the visible streak bonus")
	streak_state.phase = streak_state.Phase.REWARD
	streak_state.current_bounty = Content.apply_approach(Content.TARGETS[0], Content.contract_approaches()[2])
	streak_state.pending_loot = {"id": "repeat_loot", "name": "Recibo Repetido", "slot": "armor", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	streak_state.claim_reward(false, true)
	check(streak_state.phase == streak_state.Phase.BRIEFING and streak_state.offered_approaches.size() == 3, "repeat reward returns directly to approach selection")
	check(not streak_state.current_bounty.has("approach") and int(streak_state.current_bounty.credits) == int(Content.TARGETS[0].credits), "repeat reward restores the unmodified contract")
	var repeated_quiet := Content.apply_approach(streak_state.current_bounty, Content.contract_approaches()[0])
	var repeated_premium := Content.apply_approach(streak_state.current_bounty, Content.contract_approaches()[2])
	var next_quiet_reward := CoreRules.bounty_streak_reward(int(repeated_quiet.credits), int(streak_state.player.capture_streak) + 1)
	var next_premium_reward := CoreRules.bounty_streak_reward(int(repeated_premium.credits), int(streak_state.player.capture_streak) + 1)
	check(int(next_quiet_reward.bonus_percent) == int(next_premium_reward.bonus_percent) and int(next_quiet_reward.bonus_credits) != int(next_premium_reward.bonus_credits), "repeat briefing preserves the advertised streak percentage while approach choice changes exact credits")
	streak_state.choose_approach("quiet_net")
	streak_state.abandon_bounty()
	check(int(streak_state.player.capture_streak) == 0, "abandoning a hunt breaks the capture streak")
	streak_state.free()
	var recycle_reward_state = StateScript.new()
	recycle_reward_state.persistence_enabled = false
	recycle_reward_state.player = recycle_reward_state.default_player()
	recycle_reward_state.phase = recycle_reward_state.Phase.REWARD
	recycle_reward_state.current_bounty = Content.TARGETS[0].duplicate(true)
	recycle_reward_state.pending_loot = {"id": "instant_scrap", "name": "Zapper Pior", "slot": "weapon", "power": 0, "rarity": "Comum", "color": "#b9c2d9"}
	var instant_scrap_value := CoreRules.salvage_value(recycle_reward_state.pending_loot)
	var instant_result := recycle_reward_state.claim_reward(false, true, true)
	check(bool(instant_result.recycled) and int(instant_result.scrap) == instant_scrap_value, "reward can report immediate recycling")
	check(str(instant_result.loot_action) == "recycled" and recycle_reward_state.last_notice.contains("Zapper Pior reciclado"), "recycled loot decision names the item in the persistent record")
	check(recycle_reward_state.phase == recycle_reward_state.Phase.BRIEFING, "recycled reward can continue directly to the next briefing")
	check(not recycle_reward_state.player.inventory.any(func(item): return str(item.get("id", "")) == "instant_scrap"), "immediately recycled loot never enters inventory")
	check(int(recycle_reward_state.player.scrap) == instant_scrap_value and int(recycle_reward_state.player.scrap_recycled_total) == instant_scrap_value, "immediate recycling funds the workshop and career total")
	recycle_reward_state.phase = recycle_reward_state.Phase.REWARD
	recycle_reward_state.current_bounty = Content.TARGETS[0].duplicate(true)
	recycle_reward_state.pending_loot = {"id": "protected_trait", "name": "Achado Modificado", "slot": "weapon", "power": 0, "rarity": "Raro", "color": "#58d9ff", "trait": {"power_bonus": 0, "health_bonus": 0}}
	check(recycle_reward_state.claim_reward(false, false, true).is_empty(), "immediate recycling rejects modified rewards at the state boundary")
	check(recycle_reward_state.phase == recycle_reward_state.Phase.REWARD and str(recycle_reward_state.pending_loot.id) == "protected_trait", "rejected recycling leaves the special reward untouched")
	recycle_reward_state.pending_loot = {"id": "protected_investment", "name": "Peça Trabalhada", "slot": "weapon", "power": 0, "rarity": "Comum", "color": "#b9c2d9", "power_upgrades": 1}
	check(recycle_reward_state.claim_reward(false, false, true).is_empty(), "immediate recycling rejects workshop-invested rewards")
	recycle_reward_state.player.weapon.origin_planet_id = "dustball_prime"
	recycle_reward_state.pending_loot = {"id": "kit_armor", "name": "Colete Coordenado", "slot": "armor", "origin_planet_id": "dustball_prime", "power": 0, "rarity": "Comum", "color": "#b9c2d9"}
	check(CoreRules.is_upgrade_for_player(recycle_reward_state.player, recycle_reward_state.pending_loot), "matching-origin reward can improve the build despite lower base power")
	check(recycle_reward_state.claim_reward(false, false, true).is_empty(), "immediate recycling preserves a common item that completes a planetary kit")
	recycle_reward_state.free()
	var mastery_state = StateScript.new()
	mastery_state.persistence_enabled = false
	mastery_state.player = mastery_state.default_player()
	mastery_state.player.captures_by_target = {"gloop": 2}
	mastery_state.phase = mastery_state.Phase.REWARD
	mastery_state.current_bounty = Content.TARGETS[0].duplicate(true)
	mastery_state.pending_loot = {"id": "mastery_loot", "name": "Prova de Perícia", "slot": "armor", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	var mastery_summary := mastery_state.claim_reward(false)
	check(bool(mastery_summary.target_mastery_up) and int(mastery_summary.target_mastery) == 1, "third target capture reports a mastery increase")
	check(int(mastery_summary.mastery_scrap) == 6 and int(mastery_state.player.scrap) == 6, "mastery increase funds an immediate workshop decision")
	check(str(mastery_state.last_notice).contains("Perícia com alvo 1: +6 sucata"), "mastery increase survives as exact board feedback")
	mastery_state.free()
	var corporate_state = StateScript.new()
	corporate_state.persistence_enabled = false
	corporate_state.player = corporate_state.default_player()
	corporate_state.phase = corporate_state.Phase.REWARD
	corporate_state.current_bounty = Content.apply_approach(Content.TARGETS[0], Content.CONTRACT_APPROACHES[2])
	corporate_state.pending_loot = {"id": "corporate_loot", "name": "Recibo Corporativo", "slot": "armor", "power": 2, "rarity": "Comum", "color": "#b9c2d9"}
	var corporate_summary := corporate_state.claim_reward(false)
	check(int(corporate_summary.contract_scrap) == 2 and int(corporate_summary.scrap) == 2 and int(corporate_state.player.scrap) == 2, "corporate victory pays workshop scrap exactly once")
	check(str(corporate_state.last_notice).contains("Mandado corporativo: +2 sucata"), "corporate workshop reward survives as exact board feedback")
	corporate_state.free()
	var tactical_state = StateScript.new()
	tactical_state.persistence_enabled = false
	tactical_state.player = tactical_state.default_player()
	tactical_state.player.weapon.trait = {"opening_damage_bonus": 5}
	tactical_state.player.armor.trait = {"damage_reduction": 2}
	tactical_state.current_bounty = Content.TARGETS[0].duplicate(true)
	tactical_state.current_bounty.health = 999
	tactical_state.begin_combat()
	var tactical_step := tactical_state.combat_step()
	check(not bool(tactical_step.finished) and tactical_state.combat_events.size() == 2, "tactical traits keep the alternating combat flow")
	check(str(tactical_state.combat_events[0].get("effect", "")) == "EMBOSCADA +5", "opening-shot trait is recorded in the combat event")
	check(str(tactical_state.combat_events[1].get("effect", "")) == "AMORTECEDOR -2", "damage-reduction trait is recorded in the combat event")
	check(int(tactical_state.combat_summary.opening_bonus) == 5 and int(tactical_state.combat_summary.damage_prevented) == 2, "combat summary accumulates tactical contribution across the round")
	tactical_state.free()
	check(not state.scrap_item(str(claimed_item.id)), "equipped item cannot be recycled")
	var spare := {"id": "spare_epic", "name": "Sucata de Teste", "description": "Feita para sumir.", "slot": "armor", "power": 12, "rarity": "Épico", "color": "#d789ff"}
	state.player.inventory.append(spare)
	check(state.scrap_item("spare_epic"), "unequipped loot can be recycled")
	check(int(state.player.scrap) == 16, "recycling grants deterministic scrap")
	check(int(state.player.scrap_recycled_total) == 16, "career tracks lifetime recycled scrap")
	var equipped_power := int(state.player[str(claimed_item.slot)].power)
	var upgrade_cost := CoreRules.equipment_upgrade_cost(state.player[str(claimed_item.slot)])
	check(state.upgrade_equipped(str(claimed_item.slot)), "scrap upgrades equipped gear")
	check(int(state.player.scrap) == 16 - upgrade_cost, "workshop charges the visible upgrade cost")
	check(int(state.player[str(claimed_item.slot)].power) == equipped_power + 1, "workshop adds one equipment power")
	check(int(state.player[str(claimed_item.slot)].power_upgrades) == 1, "power calibration count stays on equipped gear")
	check(int(state.inventory_item_by_id(str(claimed_item.id)).get("power_upgrades", 0)) == 1, "power calibration is synchronized to the inventory copy")
	state.player.scrap = 100
	var health_before_reinforcement := CoreRules.max_health(state.player)
	var reinforce_cost := CoreRules.equipment_integrity_upgrade_cost(state.player[str(claimed_item.slot)])
	check(state.reinforce_equipped(str(claimed_item.slot)), "workshop can reinforce equipped integrity")
	check(int(state.player.scrap) == 100 - reinforce_cost, "integrity reinforcement charges its visible cost")
	check(CoreRules.max_health(state.player) == health_before_reinforcement + CoreRules.INTEGRITY_HEALTH_PER_LEVEL, "integrity reinforcement raises maximum health")
	check(int(state.player[str(claimed_item.slot)].integrity_upgrades) == 1, "reinforcement level stays on equipped gear")
	var reinforced_inventory_item := state.inventory_item_by_id(str(claimed_item.id))
	check(int(reinforced_inventory_item.get("integrity_upgrades", 0)) == 1, "reinforcement is synchronized to the inventory copy")
	var reinforcement_cap_state = StateScript.new()
	reinforcement_cap_state.persistence_enabled = false
	reinforcement_cap_state.player = reinforcement_cap_state.default_player()
	reinforcement_cap_state.player.scrap = 100
	reinforcement_cap_state.player.weapon.integrity_upgrades = CoreRules.MAX_INTEGRITY_UPGRADES
	check(not reinforcement_cap_state.reinforce_equipped("weapon") and int(reinforcement_cap_state.player.scrap) == 100, "workshop rejects reinforcement beyond the cap without charging scrap")
	reinforcement_cap_state.free()
	var milestones := state.career_milestones()
	check(milestones.size() == 8, "career exposes eight derived milestones")
	check(bool(milestones[0].complete), "first capture completes its career milestone")
	var credits_before_milestone := int(state.player.credits)
	check(state.career_rewards_ready() == 1, "completed career milestone advertises a pending reward")
	check(state.claim_career_milestone("first_warrant"), "completed career reward can be claimed")
	check(int(state.player.credits) == credits_before_milestone + 40, "career reward grants its listed credits")
	check(state.player.claimed_milestones.has("first_warrant"), "claimed milestone is retained by stable id")
	check(not state.claim_career_milestone("first_warrant"), "career reward cannot be claimed twice")
	var career_state = StateScript.new()
	career_state.persistence_enabled = false
	career_state.player = career_state.default_player()
	career_state.player.wins = 12
	career_state.player.captures_by_target = {"gloop": 3}
	career_state.player.completed_planets = ["dustball_prime", "congelaria_sa", "micelia_404", "ferro_velho_omega", "cassino_quasar"]
	career_state.player.scrap_recycled_total = 25
	career_state.player.best_capture_streak = 5
	var all_credits_before := int(career_state.player.credits)
	var all_scrap_before := int(career_state.player.scrap)
	var all_rewards := career_state.claim_all_career_milestones()
	check(int(all_rewards.count) == 8 and career_state.player.claimed_milestones.size() == 8, "claim all collects every ready career milestone")
	check(int(career_state.player.credits) == all_credits_before + int(all_rewards.credits) and int(career_state.player.scrap) == all_scrap_before + int(all_rewards.scrap), "claim all applies aggregate currencies once")
	check(int(career_state.claim_all_career_milestones().count) == 0, "claim all is idempotent after collection")
	career_state.free()
	var bulk_scrap_before := int(state.player.scrap)
	var recycled_before := int(state.player.scrap_recycled_total)
	state.player.inventory.append({"id": "bulk_low_weapon", "name": "Zapper Cansado", "slot": "weapon", "power": maxi(1, int(state.player.weapon.power) - 1), "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "bulk_low_armor", "name": "Colete Amassado", "slot": "armor", "power": maxi(1, int(state.player.armor.power) - 1), "rarity": "Raro", "color": "#58d9ff"})
	state.player.inventory.append({"id": "bulk_upgrade", "name": "Canhão Futuro", "slot": "weapon", "power": int(state.player.weapon.power) + 5, "rarity": "Épico", "color": "#d789ff"})
	state.player.inventory.append({"id": "bulk_trait_upgrade", "name": "Zapper Modificado", "slot": "weapon", "power": maxi(1, int(state.player.weapon.power) - 1), "rarity": "Raro", "color": "#58d9ff", "trait": {"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0}})
	var bulk_preview := state.inferior_recycle_preview()
	check(int(bulk_preview.count) == 3, "bulk recycling selects non-upgrades including replaced starter gear")
	var bulk_result := state.recycle_inferior_inventory()
	check(int(bulk_result.count) == 3, "bulk recycling removes every previewed inferior item")
	check(int(state.player.scrap) == bulk_scrap_before + int(bulk_result.scrap), "bulk recycling grants the previewed scrap")
	check(int(state.player.scrap_recycled_total) == recycled_before + int(bulk_result.scrap), "bulk recycling contributes to lifetime progress")
	check(state.player.inventory.any(func(item): return str(item.get("id", "")) == "bulk_upgrade"), "bulk recycling preserves upgrades")
	check(state.player.inventory.any(func(item): return str(item.get("id", "")) == "bulk_trait_upgrade"), "bulk recycling preserves lower-base items with superior modifications")
	state.player.inventory.append({"id": "bulk_trait_keepsake", "name": "Parafuso Sentimental", "slot": "armor", "power": 1, "rarity": "Raro", "color": "#58d9ff", "trait": {"id": "keepsake", "name": "VALOR SENTIMENTAL", "description": "Mecanicamente questionável.", "power_bonus": 0, "health_bonus": 0}})
	state.player.inventory.append({"id": "bulk_invested_keepsake", "name": "Zapper Calibrado Antigo", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9", "power_upgrades": 1, "integrity_upgrades": 1})
	check(int(state.inferior_recycle_preview().count) == 0, "bulk recycling excludes modified gear regardless of current score")
	check(state.recycle_inferior_inventory().count == 0, "bulk recycling leaves a modified keepsake untouched")
	check(state.player.inventory.any(func(item): return str(item.get("id", "")) == "bulk_trait_keepsake"), "modified keepsake remains in inventory")
	check(state.player.inventory.any(func(item): return str(item.get("id", "")) == "bulk_invested_keepsake"), "bulk recycling preserves workshop-invested gear")
	var loadout_items := [
		{"id": "loadout_a_weapon", "name": "Arma A", "slot": "weapon", "power": 8, "rarity": "Comum", "color": "#b9c2d9"},
		{"id": "loadout_a_armor", "name": "Armadura A", "slot": "armor", "power": 7, "rarity": "Comum", "color": "#b9c2d9"},
		{"id": "loadout_b_weapon", "name": "Arma B", "slot": "weapon", "power": 10, "rarity": "Raro", "color": "#58d9ff"},
		{"id": "loadout_b_armor", "name": "Armadura B", "slot": "armor", "power": 9, "rarity": "Raro", "color": "#58d9ff"},
	]
	state.player.inventory.append_array(loadout_items)
	state.equip(loadout_items[0])
	state.equip(loadout_items[1])
	check(state.save_equipment_loadout(0), "current equipment can be saved as the hunt loadout")
	state.equip(loadout_items[2])
	state.equip(loadout_items[3])
	check(state.save_equipment_loadout(1), "alternate equipment can be saved as the reserve loadout")
	check(not state.scrap_item("loadout_a_weapon"), "loadout equipment is protected from manual recycling")
	check(state.apply_equipment_loadout(0), "saved hunt loadout can be restored")
	check(str(state.player.weapon.id) == "loadout_a_weapon" and str(state.player.armor.id) == "loadout_a_armor", "loadout restores both equipment slots")
	state.player.inventory.append({"id": "manual_lock", "name": "Lembrança", "slot": "armor", "power": 1, "rarity": "Comum", "color": "#b9c2d9"})
	check(state.toggle_item_lock("manual_lock"), "inventory item can be manually protected")
	check(not state.scrap_item("manual_lock"), "manual protection blocks recycling")
	check(state.toggle_item_lock("manual_lock"), "manual protection can be removed")
	check(state.scrap_item("manual_lock"), "unprotected inventory item can be recycled")
	check(state.player.inventory.any(func(item): return str(item.get("id", "")) == str(claimed_item.id)), "bulk recycling preserves equipped items")

	state.start_bounty(Content.TARGETS[0].duplicate(true))
	state.hunt_event = Content.HUNT_EVENTS[0].duplicate(true)
	state.player.capture_streak = 4
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
	var paid_event_contract: Dictionary = state.current_bounty.duplicate(true)
	var paid_event_reward: Dictionary = CoreRules.bounty_streak_reward(int(paid_event_contract.credits), int(state.player.capture_streak) + 1)
	check(int(paid_event_reward.credits) - 8 == 38 and int(paid_event_reward.bonus_percent) == 20, "paid incident net preview combines the charged cost with the active ×5 payout")
	check(state.current_bounty.defense == 3, "event consequence modifies the target")
	check(state.current_bounty.has("hunt_event_result"), "event result is retained for feedback")
	check(int(state.current_bounty.get("hunt_event_credit_cost", 0)) == 8, "paid incident cost remains attached to the live contract receipt")
	state.begin_combat()
	state.enemy_hp = 9999
	state.player_hp = 1
	var defeat := state.combat_step()
	check(bool(defeat.get("finished", false)) and not bool(defeat.get("won", true)), "defeat is detected")
	check(state.phase == state.Phase.BOARD, "defeat returns to the bounty board")
	check(not state.last_notice.is_empty(), "defeat explains what happened")
	check(int(state.player.capture_streak) == 0, "defeat resets the capture streak")
	check(int(state.combat_summary.get("lost_streak", 0)) == 4 and state.last_notice.contains("Embalo ×4 perdido"), "defeat persists and names the exact lost streak")
	state.select_bounty(Content.TARGETS[0])
	state.cancel_briefing()
	check(state.phase == state.Phase.BOARD and state.current_bounty.is_empty(), "briefing can be cancelled safely")

	var recovery_state = StateScript.new()
	recovery_state.persistence_enabled = false
	recovery_state.player = recovery_state.default_player()
	recovery_state.player.captures_by_target = {"gloop": 2}
	recovery_state.player.captures_by_planet = {Content.PLANET.id: 2}
	recovery_state.player.capture_streak = 4
	recovery_state.select_bounty(Content.TARGETS[0])
	recovery_state.choose_approach("quiet_net")
	recovery_state.begin_combat()
	recovery_state.enemy_hp = 12
	recovery_state.player_hp = 0
	recovery_state.finish_combat(false)
	check(int(recovery_state.player.capture_streak) == 0 and int(recovery_state.combat_summary.lost_streak) == 4, "recovery scenario begins from a persisted streak loss")
	recovery_state.select_bounty(Content.TARGETS[0])
	recovery_state.choose_approach("quiet_net")
	recovery_state.begin_combat()
	recovery_state.enemy_hp = 0
	recovery_state.finish_combat(true)
	recovery_state.open_reward()
	var recovery_summary := recovery_state.claim_reward(false)
	check(int(recovery_summary.streak) == 1 and int(recovery_summary.streak_bonus) == 0, "first recovered capture restarts streak at one without phantom bonus")
	check(bool(recovery_summary.target_mastery_up) and int(recovery_summary.target_mastery) == 1 and int(recovery_summary.mastery_scrap) == 6, "recovered third capture still grants the exact mastery threshold funding")
	check(int(recovery_state.player.captures_by_target.gloop) == 3 and recovery_state.planet_tier(Content.PLANET.id) == 1, "recovered threshold capture advances the sequential warrant")
	recovery_state.free()

	var receipt_state = StateScript.new()
	receipt_state.persistence_enabled = false
	receipt_state.player = receipt_state.default_player()
	receipt_state.player.capture_streak = 4
	receipt_state.select_bounty(Content.TARGETS[0])
	receipt_state.choose_approach("quiet_net")
	receipt_state.hunt_event = Content.HUNT_EVENTS[0].duplicate(true)
	receipt_state.phase = receipt_state.Phase.HUNT_EVENT
	var receipt_credits_before := int(receipt_state.player.credits)
	var projected_paid_contract := Content.apply_hunt_choice(receipt_state.current_bounty, receipt_state.hunt_event.choices[0])
	var projected_paid_reward := CoreRules.bounty_streak_reward(int(projected_paid_contract.credits), 5)
	check(receipt_state.resolve_hunt_event("bribe"), "receipt scenario accepts the paid incident")
	receipt_state.begin_combat()
	receipt_state.enemy_hp = 0
	receipt_state.finish_combat(true)
	receipt_state.open_reward()
	var receipt_summary := receipt_state.claim_reward(false)
	check(int(receipt_summary.credits) == int(projected_paid_reward.credits) and int(receipt_summary.incident_cost) == 8 and int(receipt_summary.net_contract_credits) == int(projected_paid_reward.credits) - 8, "reward receipt matches the incident projection exactly")
	check(int(receipt_state.player.credits) == receipt_credits_before + int(receipt_summary.net_contract_credits), "wallet delta from pre-choice to reward equals the displayed net contract gain")
	receipt_state.free()
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
	check(chapter_state.planet_tier(Content.PLANET.id) == 3, "completed planets remain at maximum tier for legacy-compatible careers")
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
	frozen_state.continue_after_chapter()
	check(frozen_state.travel_to_planet("micelia_404"), "second chapter opens travel to Micelia")
	check(str(frozen_state.player.current_planet_id) == "micelia_404", "third planet becomes the active destination")
	frozen_state.player.wins = 29
	frozen_state.player.captures_by_planet.micelia_404 = 9
	frozen_state.phase = frozen_state.Phase.REWARD
	frozen_state.current_bounty = Content.TARGETS[11].duplicate(true)
	frozen_state.pending_loot = {
		"id": "mycelia_test_loot", "name": "Nó da Rede", "description": "Pensa em parcelas.",
		"slot": "weapon", "power": 31, "rarity": "Épico", "color": "#d789ff",
	}
	var fungal_summary := frozen_state.claim_reward(true)
	check(frozen_state.phase == frozen_state.Phase.CHAPTER_COMPLETE, "Micelia boss opens the reusable chapter finale")
	check(bool(fungal_summary.chapter_complete), "third planet reports chapter completion")
	check(frozen_state.player.completed_planets.has("micelia_404"), "third completed planet persists in progression")
	check(frozen_state.planet_capture_count("micelia_404") == 10, "fungal capture counter completes its chapter")
	frozen_state.continue_after_chapter()
	check(frozen_state.travel_to_planet("ferro_velho_omega"), "third chapter opens travel to Ferro-Velho Omega")
	frozen_state.player.wins = 39
	frozen_state.player.captures_by_planet.ferro_velho_omega = 9
	frozen_state.phase = frozen_state.Phase.REWARD
	frozen_state.current_bounty = Content.TARGETS[15].duplicate(true)
	frozen_state.pending_loot = {
		"id": "omega_test_loot", "name": "Coroa de Compactador", "description": "Ainda mastiga.",
		"slot": "armor", "power": 48, "rarity": "Épico", "color": "#d789ff",
	}
	var scrapyard_summary := frozen_state.claim_reward(true)
	check(frozen_state.phase == frozen_state.Phase.CHAPTER_COMPLETE, "Ferro-Velho boss opens the chapter finale")
	check(bool(scrapyard_summary.chapter_complete), "fourth planet reports chapter completion")
	check(frozen_state.player.completed_planets.has("ferro_velho_omega"), "fourth completed planet persists in progression")
	check(frozen_state.planet_capture_count("ferro_velho_omega") == 10, "scrapyard capture counter completes its chapter")
	check(bool(frozen_state.career_milestones()[4].complete), "fourth planet completes the apocalypse mechanic milestone")
	frozen_state.continue_after_chapter()
	check(frozen_state.travel_to_planet("cassino_quasar"), "fourth chapter opens travel to Cassino Quasar")
	frozen_state.player.wins = 49
	frozen_state.player.captures_by_planet.cassino_quasar = 9
	frozen_state.phase = frozen_state.Phase.REWARD
	frozen_state.current_bounty = Content.TARGETS[19].duplicate(true)
	frozen_state.pending_loot = {
		"id": "quasar_test_loot", "name": "Ficha da Casa", "description": "Recusa troco.",
		"slot": "weapon", "power": 62, "rarity": "Épico", "color": "#d789ff",
	}
	var casino_summary := frozen_state.claim_reward(true)
	check(frozen_state.phase == frozen_state.Phase.CHAPTER_COMPLETE and bool(casino_summary.chapter_complete), "Cassino Quasar boss completes the fifth chapter")
	check(frozen_state.player.completed_planets.has("cassino_quasar") and frozen_state.planet_capture_count("cassino_quasar") == 10, "fifth planet completion persists with its own capture counter")
	check(bool(frozen_state.career_milestones()[5].complete), "fifth planet completes the house-breaker milestone")
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
