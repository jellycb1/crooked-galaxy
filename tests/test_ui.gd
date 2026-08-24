extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("run_smoke_test")


func run_smoke_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	state.pending_loot = {}

	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.content.get_child_count() >= 4, "bounty board renders")
	check(scene.find_child("NextWarrantProgress", true, false) != null, "board keeps the next-warrant objective above the contract list")

	var bounty: Dictionary = ContentDB.TARGETS[0].duplicate(true)
	state.player.captures_by_target = {"gloop": 3}
	state.player.capture_streak = 2
	scene.render()
	await process_frame
	check(scene.find_child("BountyMastery_gloop", true, false) != null, "bounty cards expose target mastery progress")
	check(scene.find_child("MasteryRoute_gloop", true, false) != null, "bounty board preserves the career mastery recommendation")
	state.select_bounty(bounty)
	await process_frame
	check(scene.find_child("BriefingScroll", true, false) != null, "contract briefing renders")
	check(scene.find_child("BriefingMastery", true, false) != null, "briefing explains mastery loot bonuses")
	check(scene.find_children("RecommendedApproach_*", "Label", true, false).size() == 1, "briefing renders exactly one dynamic recommendation")
	check(scene.find_children("ApproachStreak_*", "Label", true, false).size() == 3, "briefing marks every displayed payment as already streak-adjusted")
	check(scene.find_child("ApproachScrapReward_premium_warrant", true, false) != null, "briefing exposes the corporate workshop reward before commitment")
	state.choose_approach("quiet_net")
	await process_frame
	check(scene.find_child("HuntProgress", true, false) != null, "hunt screen renders")
	state.hunt_event = ContentDB.HUNT_EVENTS[0].duplicate(true)
	state.hunt_event_triggered = true
	state.hunt_elapsed_before_event = 3.0
	state.hunt_remaining_after_event = 3.0
	state.phase = state.Phase.HUNT_EVENT
	scene.render()
	await process_frame
	check(scene.find_child("HuntEventChoices", true, false) != null, "mid-hunt incident renders")
	state.resolve_hunt_event("detour")
	await process_frame

	state.begin_combat()
	await process_frame
	check(state.player_hp > 0 and state.enemy_hp > 0, "combat screen initializes")
	state.combat_step()
	scene.render()
	await process_frame
	check(state.combat_events.size() == 2, "combat action cards render")

	state.finish_combat(true)
	await process_frame
	check(state.phase == state.Phase.VICTORY, "victory screen renders before loot")
	check(not state.pending_loot.is_empty(), "reward screen receives an item")
	check(scene.find_child("CombatSummaryVictory", true, false) != null, "victory explains aggregate combat performance")

	state.open_reward()
	await process_frame
	check(scene.find_child("RewardMastery", true, false) != null, "reward screen confirms applied target mastery")
	check(scene.find_child("RewardMasteryProgress", true, false) != null, "reward screen counts the pending capture toward the next mastery")
	check(scene.find_child("RewardWarrantProgress", true, false) != null, "reward screen previews progress toward the next warrant")
	check(scene.find_child("ClaimAndRepeat", true, false) != null, "reward screen offers another contract immediately")
	check(scene.find_child("ClaimAndBoard", true, false) != null, "reward screen preserves the board return path")
	state.player.captures_by_planet = {ContentDB.PLANET.id: 2}
	state.player.captures_by_target = {"gloop": 2}
	scene.render()
	await process_frame
	check(scene.find_child("RewardWarrantUnlock", true, false) != null, "third capture previews the newly unlocked warrant")
	check(scene.find_child("ClaimAndRepeat", true, false) == null, "unlock reward directs the first visit back to the expanded board")
	var unlock_claim := scene.find_child("ClaimAndUnlock", true, false) as Button
	check(unlock_claim != null and unlock_claim.text.contains("NOVO MANDADO"), "unlock reward CTA names its destination")
	state.player.captures_by_planet = {}
	scene.render()
	await process_frame
	state.claim_reward(true)
	state.phase = state.Phase.REWARD
	state.current_bounty = bounty.duplicate(true)
	state.pending_loot = {"id": "ui_instant_scrap", "name": "Zapper Cansado", "slot": "weapon", "power": 0, "rarity": "Comum", "color": "#b9c2d9"}
	scene.render()
	await process_frame
	check(scene.find_child("RecycleAndRepeat", true, false) != null, "inferior common rewards offer immediate recycling")
	state.claim_reward(false, true, true)
	state.phase = state.Phase.BOARD
	state.player.scrap = 18
	state.player.inventory.append({"id": "ui_spare", "name": "Peça Obsoleta", "description": "Serve melhor desmontada.", "slot": "armor", "power": 6, "rarity": "Comum", "color": "#b9c2d9"})
	state.player.inventory.append({"id": "ui_inferior", "name": "Peça Arquivada", "description": "Já perdeu a discussão.", "slot": "weapon", "power": 1, "rarity": "Comum", "color": "#b9c2d9"})
	scene.view_mode = "arsenal"
	scene.render()
	await process_frame
	check(scene.find_child("InventoryScroll", true, false) != null, "arsenal screen renders")
	check(state.player.inventory.size() == 4, "arsenal receives claimed, replaced starter, spare, and inferior loot")
	check(scene.find_child("Upgrade_weapon", true, false) != null, "workshop renders equipment upgrades")
	check(scene.find_child("Reinforce_weapon", true, false) != null, "workshop renders integrity reinforcement")
	check(scene.find_child("LoadoutToolbar", true, false) != null, "arsenal renders equipment loadouts")
	check(scene.find_child("SaveLoadout_0", true, false) != null, "arsenal can save the hunt loadout")
	check(scene.find_child("Scrap_ui_spare", true, false) != null, "workshop renders recycling for spare loot")
	check(scene.find_child("Lock_ui_spare", true, false) != null, "inventory renders manual item protection")
	check(scene.find_child("InventoryFilter_weapon", true, false) != null, "arsenal renders slot filters")
	check(scene.find_child("InventorySort", true, false) != null, "arsenal renders inventory sorting")
	var bulk_recycle := scene.find_child("RecycleInferior", true, false) as Button
	check(bulk_recycle != null and not bulk_recycle.disabled, "arsenal enables safe bulk recycling when inferior items exist")
	var weapon_filter := scene.find_child("InventoryFilter_weapon", true, false) as Button
	weapon_filter.pressed.emit()
	await process_frame
	check(scene.inventory_filter == "weapon", "weapon filter updates arsenal state")
	check(scene.find_child("Scrap_ui_spare", true, false) == null, "weapon filter hides armor inventory cards")
	check(scene.find_child("Scrap_ui_inferior", true, false) != null, "weapon filter keeps weapon inventory cards")
	var sort_button := scene.find_child("InventorySort", true, false) as Button
	sort_button.pressed.emit()
	await process_frame
	check(scene.inventory_sort == "rarity", "sort control toggles from power to rarity")

	state.phase = state.Phase.CHAPTER_COMPLETE
	state.chapter_completion = {
		"planet": ContentDB.PLANET.duplicate(true),
		"target": ContentDB.TARGETS[3].duplicate(true),
		"total_captures": 10,
		"credits": ContentDB.TARGETS[3].credits,
	}
	scene.render()
	await process_frame
	check(scene.find_child("ChapterComplete", true, false) != null, "planet completion screen renders")

	state.phase = state.Phase.BOARD
	state.player.completed_planets = [ContentDB.PLANET.id]
	state.player.current_planet_id = ContentDB.PLANET.id
	state.player.reputation = 3
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(scene.find_child("GalaxyRoutes", true, false) != null, "galaxy map renders unlocked routes")
	scene.view_mode = "board"
	check(state.travel_to_planet("congelaria_sa"), "UI state can travel to an unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_auditor_frost", true, false) != null, "second planet bounty board renders")
	state.player.completed_planets.append("congelaria_sa")
	check(state.travel_to_planet("micelia_404"), "UI state can enter the third unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_landlord_spore", true, false) != null, "third planet bounty board renders")
	state.player.completed_planets.append("micelia_404")
	check(state.travel_to_planet("ferro_velho_omega"), "UI state can enter the fourth unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_bolt_collector", true, false) != null, "fourth planet bounty board renders")
	state.player.completed_planets.append("ferro_velho_omega")
	check(state.travel_to_planet("cassino_quasar"), "UI state can enter the fifth unlocked planet")
	await process_frame
	check(scene.find_child("BountyCard_dealer_comet", true, false) != null, "fifth planet bounty board renders")
	scene.view_mode = "galaxy"
	scene.render()
	await process_frame
	check(scene.find_child("GalaxyPlanetProgress_cassino_quasar", true, false) != null, "galaxy map names the active fifth-chapter objective")
	state.afk_report = {"minutes": 95, "credits": 380, "scrap": 6, "capped": false}
	scene.view_mode = "board"
	scene.render()
	await process_frame
	check(scene.find_child("AfkReturnBanner", true, false) != null, "AFK return report renders on the bounty board")
	state.afk_report = {}
	state.player.wins = 1
	state.player.captures_by_target = {"gloop": 1}
	scene.view_mode = "career"
	scene.render()
	await process_frame
	check(scene.find_child("CareerSummary", true, false) != null, "career summary renders")
	check(scene.find_child("CareerScroll", true, false) != null, "career planet and milestone list renders")
	check(scene.find_child("CareerProgressJump", true, false) != null and scene.find_child("CareerArchiveJump", true, false) != null, "career exposes progress and archive shortcuts")
	check(scene.find_child("ClaimAllMilestones", true, false) != null, "career renders a bulk claim action")
	check(scene.find_child("ClaimMilestone_first_warrant", true, false) != null, "career renders a claim action for completed milestones")
	check(scene.find_child("CareerTarget_gloop", true, false) != null, "career renders the wanted archive")
	check(scene.find_child("MasteryDirective", true, false) != null and scene.find_child("MasteryDirectiveAction", true, false) != null, "career turns repeat progress into a direct next action")

	scene.view_mode = "board"
	state.phase = state.Phase.BOARD
	state.player.current_planet_id = ContentDB.PLANET.id
	state.current_bounty = ContentDB.TARGETS[1].duplicate(true)
	state.player.capture_streak = 4
	state.begin_combat()
	state.combat_summary.rounds = 6
	state.combat_summary.damage_dealt = 84
	state.combat_summary.damage_taken = 83
	state.player_hp = 0
	state.enemy_hp = 12
	state.finish_combat(false)
	await process_frame
	check(scene.find_child("CombatSummaryDefeat", true, false) != null, "board keeps a concise defeat diagnosis before the next contract")
	var streak_loss := scene.find_child("DefeatStreakLoss", true, false) as Label
	check(streak_loss != null and streak_loss.text.contains("×4") and streak_loss.text.contains("×1"), "defeat diagnosis explains the streak reset and restart")
	var defeat_workshop := scene.find_child("DefeatWorkshopAction", true, false) as Button
	check(defeat_workshop != null, "defeat diagnosis offers an immediate workshop recovery route")
	defeat_workshop.pressed.emit()
	await process_frame
	check(scene.view_mode == "arsenal", "defeat recovery route opens the field-test workshop")
	var revenge_target := scene.find_child("FieldReadinessTarget", true, false) as Label
	check(revenge_target != null and revenge_target.text.contains("REVANCHE: BARÃO BOOM"), "real defeat state preserves the failed warrant through its persisted combat report")

	scene.free()
	await process_frame
	# Let the dummy audio driver release active playback handles before shutdown.
	await create_timer(0.5).timeout
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: all primary UI phases render")
		quit(0)
	else:
		printerr("FAIL: %d UI smoke test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
