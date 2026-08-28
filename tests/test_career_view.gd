extends SceneTree

const FactoryScript = preload("res://scripts/ui_factory.gd")
const StateScript = preload("res://scripts/game_state.gd")
const CareerViewScript = preload("res://scripts/career_view.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = false
	state.player = state.default_player()
	state.player.wins = 3
	state.player.captures_by_target = {"gloop": 2, "baron_boom": 1}
	state.player.captures_by_planet = {"dustball_prime": 3}
	var host = FactoryScript.new()
	root.add_child(host)
	var content := VBoxContainer.new()
	host.add_child(content)
	CareerViewScript.build(host, content, state)

	var career_summary := host.find_child("CareerSummary", true, false) as PanelContainer
	check(career_summary != null, "isolated career builds its summary")
	check(career_summary != null and career_summary.get_theme_stylebox("panel") is StyleBoxTexture, "career identity uses one illustrated summary above compact ledgers")
	check(career_summary.find_children("*", "Label", true, false).all(func(summary_label): return (summary_label as Label).get_theme_font_size("font_size") >= 18), "career summary remains readable on the physical Android target")
	check(host.find_child("CareerXpProgress", true, false) != null, "career summary makes next-level progress visual")
	check(host.find_children("CareerPlanetIcon_*", "Control", true, false).size() == Content.PLANETS.size(), "career gives every destination a stable visual identity")
	check(host.find_child("CareerClaimReceipt", true, false) == null, "career does not mislabel unrelated state as a milestone receipt")
	check(host.find_child("CareerScroll", true, false) != null, "isolated career builds its archive scroller")
	check(host.find_child("CareerProgressJump", true, false) != null, "career provides a direct route back to progression")
	check(host.find_child("CareerArchiveJump", true, false) != null, "career provides a direct route to the wanted archive")
	var locked_challenge := host.find_child("CareerChallengeProgress", true, false) as PanelContainer
	check(locked_challenge != null and find_text(locked_challenge).contains("NÍVEL %d" % ChallengeRules.UNLOCK_LEVEL), "career introduces the parallel ladder at its truthful unlock condition")
	check(host.find_child("CareerChallengeAction", true, false) == null, "locked challenge progress does not expose a dead route")
	check(host.find_child("MasteryDirective", true, false) != null, "isolated career turns archive data into a repeat objective")
	var mastery_action := host.find_child("MasteryDirectiveAction", true, false) as Button
	check(mastery_action != null and mastery_action.text == "ESCOLHER\nROTA", "mastery objective truthfully links to route selection")
	check(host.find_child("CareerTarget_gloop", true, false) == null, "progress section does not build the offscreen wanted archive")
	mastery_action.pressed.emit()
	check(state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "gloop" and bool(state.current_bounty.get("mission_offer", false)), "mastery directive opens a level-banded target briefing without re-entering chapter progression")
	state.cancel_briefing()
	var dustball_archive := CareerViewScript.ordered_archive_targets(state)
	check(dustball_archive.size() == Content.TARGETS.size(), "active-first archive preserves all wanted records")
	check(str(dustball_archive[0].id) == "gloop", "career archive starts with the active planet")
	var archived_ids := {}
	for target in dustball_archive:
		archived_ids[str(target.id)] = true
	check(archived_ids.size() == Content.TARGETS.size(), "active-first archive does not duplicate wanted records")
	var archive_jump := host.find_child("CareerArchiveJump", true, false) as Button
	check(not archive_jump.pressed.get_connections().is_empty(), "wanted archive tab is wired to replace the long career ledger")
	host.career_section = "archive"
	clear_children(content)
	CareerViewScript.build(host, content, state)
	check(host.find_child("CareerTarget_gloop", true, false) != null and host.find_child("CareerPlanet_dustball_prime", true, false) == null, "wanted section builds records without hidden progression cards")
	var archive_target_action := host.find_child("CareerTargetAction_gloop", true, false) as Button
	check(archive_target_action != null and archive_target_action.text == "ABRIR", "available archive records link back to their contract")
	check(host.find_child("CareerTargetAction_baron_boom", true, false) != null, "discovered-world records can generate a current level-banded contract")
	archive_target_action.pressed.emit()
	check(state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "gloop" and bool(state.current_bounty.get("mission_offer", false)), "archive record opens a scaled mission snapshot rather than the legacy canonical enemy")
	state.cancel_briefing()
	state.player.completed_planets = ["dustball_prime"]
	state.player.current_planet_id = "congelaria_sa"
	state.player.level = 19
	host.career_section = "progress"
	clear_children(content)
	CareerViewScript.build(host, content, state)
	var challenge_card := host.find_child("CareerChallengeProgress", true, false) as PanelContainer
	check(challenge_card != null and find_text(challenge_card).contains("PRÓXIMO: DRONE DA ALFÂNDEGA MORTA"), "career names the next independent challenge after unlock")
	check(host.find_child("CareerChallengeBar", true, false) != null, "career makes rift completion readable as a stable progress track")
	var challenge_action := host.find_child("CareerChallengeAction", true, false) as Button
	check(challenge_action != null and challenge_action.text == "ABRIR", "career provides a direct route into the unlocked rift")
	state.player.challenge_floor = 6
	clear_children(content)
	CareerViewScript.build(host, content, state)
	check(find_text(host.find_child("CareerChallengeProgress", true, false)).contains("DISPOSITIVOS"), "career identifies gadget floors as their own reward sector")
	state.player.challenge_floor = 9
	clear_children(content)
	CareerViewScript.build(host, content, state)
	check(find_text(host.find_child("CareerChallengeProgress", true, false)).contains("RELÍQUIAS"), "career identifies relic floors as their own reward sector")
	state.player.challenge_floor = ChallengeRules.STAGES.size()
	clear_children(content)
	CareerViewScript.build(host, content, state)
	var completed_challenge := host.find_child("CareerChallengeProgress", true, false)
	check(find_text(completed_challenge).contains("12/12 ANDARES") and find_text(completed_challenge).contains("COMPLETA"), "career renders the complete twelve-floor archive without a stale sector")
	check(host.find_child("CareerChallengeAction", true, false) == null, "completed Rift removes its entry action")
	state.player.challenge_floor = 0
	clear_children(content)
	CareerViewScript.build(host, content, state)
	challenge_action = host.find_child("CareerChallengeAction", true, false) as Button
	challenge_action.pressed.emit()
	check(host.view_mode == "challenges", "career challenge route opens the independent ladder")
	check(str(CareerViewScript.ordered_archive_targets(state)[0].id) == "auditor_frost", "changing planets moves that chapter's warrants to the front without filtering history")
	host.career_section = "archive"
	clear_children(content)
	CareerViewScript.build(host, content, state)
	var cross_planet_action := host.find_child("CareerTargetAction_auditor_frost", true, false) as Button
	check(cross_planet_action != null, "archive exposes targets on unlocked completed routes")
	cross_planet_action.pressed.emit()
	check(str(state.player.current_planet_id) == "congelaria_sa" and state.phase == state.Phase.BRIEFING and str(state.current_bounty.id) == "auditor_frost", "archive action travels to another planet and opens the selected briefing")
	state.cancel_briefing()
	state.last_notice = "2 marcos resgatados: +110 créditos · +2 sucata."
	state.last_notice_context = "career"
	clear_children(content)
	CareerViewScript.build(host, content, state)
	var receipt := host.find_child("CareerClaimReceipt", true, false) as PanelContainer
	check(receipt != null, "career renders its own exact milestone receipt")
	check(find_text(receipt).contains("+110 créditos") and find_text(receipt).contains("+2 sucata"), "career receipt preserves aggregate currency values")

	host.free()
	state.free()
	if failures == 0:
		print("PASS: isolated career renderer is valid")
		quit(0)
	else:
		printerr("FAIL: %d career renderer test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func find_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += str(node.text) + "\n"
	for child in node.get_children():
		result += find_text(child)
	return result


func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()
