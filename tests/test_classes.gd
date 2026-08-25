extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Classes = preload("res://scripts/class_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_classes_test")


func run_classes_test() -> void:
	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for the class test")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	check(Classes.DEFINITIONS.size() == 3, "the first class roster has three focused archetypes")
	check(Classes.DEFINITIONS.all(func(definition): return bool(definition.get("prototype", false))), "the complete initial trio is explicitly marked as replaceable prototype content")
	var primaries := Classes.DEFINITIONS.map(func(definition): return str(definition.primary_attribute))
	check(primaries == ["strength", "dexterity", "intelligence"], "the roster specializes the three offensive attributes without consuming vitality or cunning")
	check(str(state.player.class_id).is_empty() and Classes.specialization_power(state.player, Rules.BASE_ATTRIBUTE_VALUE) == 0, "new hunters remain safely unassigned until the player chooses")

	for definition in Classes.DEFINITIONS:
		check(definition.get("effects", {}) is Dictionary and not Classes.specialization_text(definition).is_empty(), "%s owns data-driven effects and a derived player-facing description" % str(definition.name))
		check(not str(definition.get("preferred_approach", "")).is_empty() and float(definition.get("approach_affinity", 1.0)) > 1.0, "%s declares a data-driven contract style" % str(definition.name))
		var unassigned: Dictionary = state.default_player()
		var specialized: Dictionary = unassigned.duplicate(true)
		var primary := str(definition.primary_attribute)
		unassigned.attributes[primary] = 12
		specialized.attributes[primary] = 12
		specialized.class_id = str(definition.id)
		check(Rules.player_power(specialized) == Rules.player_power(unassigned) + 1, "%s gains the documented primary-stat specialization" % str(definition.name))

	var neutral_intelligence: Dictionary = state.default_player()
	neutral_intelligence.attributes.intelligence = 12
	var hacker: Dictionary = neutral_intelligence.duplicate(true)
	hacker.class_id = "contract_hacker"
	check(Rules.player_opening_damage(hacker) == Rules.player_opening_damage(neutral_intelligence) + 4, "contract hacker combines base invasion and intelligence scaling into four opening damage")
	check(int(Classes.DEFINITIONS[2].effects.base_opening_damage) == 2 and int(Classes.DEFINITIONS[2].effects.opening_damage_per_primary_point) == 1 and Classes.specialization_opening_damage(hacker, Rules.BASE_ATTRIBUTE_VALUE) == 4, "invasion comes from the class effect definition instead of an ID-specific combat branch")
	var hacker_preview := Classes.specialization_preview(Classes.DEFINITIONS[2], neutral_intelligence.attributes, Rules.BASE_ATTRIBUTE_VALUE)
	check(int(hacker_preview.power) == 1 and int(hacker_preview.opening_damage) == 4, "a class can preview its exact bonus without mutating or selecting it")
	check(str(neutral_intelligence.class_id).is_empty(), "class preview leaves the inspected player unassigned")
	var breaker: Dictionary = state.default_player()
	breaker.attributes.strength = 12
	breaker.class_id = "warrant_breaker"
	var gunslinger: Dictionary = state.default_player()
	gunslinger.attributes.dexterity = 12
	gunslinger.class_id = "orbit_gunslinger"
	var neutral_strength := breaker.duplicate(true)
	neutral_strength.class_id = ""
	var neutral_dexterity := gunslinger.duplicate(true)
	neutral_dexterity.class_id = ""
	check(Rules.player_damage_reduction(breaker) == Rules.player_damage_reduction(neutral_strength) + 2, "warrant breaker absorbs base and strength-scaled damage on every enemy hit")
	check(is_equal_approx(Rules.player_attack_roll(gunslinger, 0.5), Rules.player_attack_roll(neutral_dexterity, 0.5) + 0.01), "orbital gunslinger adds persistent base and dexterity-scaled precision")
	check(Classes.combat_identity_text(breaker, Rules.BASE_ATTRIBUTE_VALUE).contains("CASCO DURO") and Classes.combat_identity_text(gunslinger, Rules.BASE_ATTRIBUTE_VALUE).contains("MIRA ORBITAL") and Classes.combat_identity_text(hacker, Rules.BASE_ATTRIBUTE_VALUE).contains("INVASÃO"), "every prototype class exposes a distinct active combat identity")

	var breaker_combat = StateScript.new()
	breaker_combat.persistence_enabled = false
	breaker_combat.player = breaker.duplicate(true)
	breaker_combat.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	breaker_combat.current_bounty.health = 999
	breaker_combat.begin_combat()
	breaker_combat.combat_step()
	check(str(breaker_combat.combat_events[1].get("effect", "")).contains("CASCO DURO -2"), "breaker mitigation is named on the enemy turn that it changes")
	breaker_combat.free()
	var gunslinger_combat = StateScript.new()
	gunslinger_combat.persistence_enabled = false
	gunslinger_combat.player = gunslinger.duplicate(true)
	gunslinger_combat.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	gunslinger_combat.current_bounty.health = 999
	gunslinger_combat.begin_combat()
	gunslinger_combat.combat_step()
	check(str(gunslinger_combat.combat_events[0].get("effect", "")).contains("MIRA ORBITAL +1.0%"), "gunslinger precision is named on every player turn that it changes")
	gunslinger_combat.free()
	var hacker_combat = StateScript.new()
	hacker_combat.persistence_enabled = false
	hacker_combat.player = hacker.duplicate(true)
	hacker_combat.current_bounty = ContentDB.TARGETS[0].duplicate(true)
	hacker_combat.current_bounty.health = 999
	hacker_combat.begin_combat()
	hacker_combat.combat_step()
	check(str(hacker_combat.combat_events[0].get("effect", "")).contains("INVASÃO +4"), "hacker invasion is named on the opening turn that it changes")
	hacker_combat.free()
	var sanitized_class_events: Dictionary = state.sanitize_loaded_combat_events([
		{"actor": "player", "action": ContentDB.PLAYER_ATTACKS[0], "damage": 12, "quality": "ACERTO", "effect": "EMBOSCADA +1 · INVASÃO +4"},
		{"actor": "enemy", "action": str(ContentDB.TARGETS[0].attacks[0]), "damage": 5, "quality": "ACERTO", "effect": "CASCO DURO -2"},
	])
	check(sanitized_class_events.events.size() == 2 and str(sanitized_class_events.events[0].effect).contains("INVASÃO") and str(sanitized_class_events.events[1].effect).contains("CASCO DURO"), "interrupted combat preserves only recognized class-effect evidence")
	var baron_profile := {"level": 1, "base_power": 10, "weapon": {"power": 6}, "armor": {"power": 1}}
	for key in ["attributes", "class_id"]:
		baron_profile[key] = hacker[key]
	var hacker_odds := Rules.bounty_odds(baron_profile, ContentDB.TARGETS[1])
	for key in ["attributes", "class_id"]:
		baron_profile[key] = breaker[key]
	var breaker_odds := Rules.bounty_odds(baron_profile, ContentDB.TARGETS[1])
	for key in ["attributes", "class_id"]:
		baron_profile[key] = gunslinger[key]
	var gunslinger_odds := Rules.bounty_odds(baron_profile, ContentDB.TARGETS[1])
	check(hacker_odds >= 0.65 and hacker_odds <= breaker_odds and hacker_odds > gunslinger_odds, "opening specialization closes the early hacker gap without overtaking the strength specialist")

	check(not state.select_class("totally_real_class"), "unknown classes cannot enter the save")
	check(state.select_class("warrant_breaker") and str(state.player.class_id) == "warrant_breaker", "a valid board selection commits immediately")
	check(state.select_class("contract_hacker") and str(state.player.class_id) == "contract_hacker", "early-access reclassification remains free and reversible")
	state.phase = state.Phase.BRIEFING
	check(not state.select_class("orbit_gunslinger") and str(state.player.class_id) == "contract_hacker", "class changes cannot alter a committed contract")

	state.phase = state.Phase.BOARD
	state.player = state.default_player()
	state.player.attributes.strength = 12
	state.player.attributes.dexterity = 13
	state.player.attributes.intelligence = 12
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.board_section = "destinations"
	scene.render()
	await process_frame
	var board_class_action := scene.find_child("PrimaryNav_hunter", true, false) as Button
	check(board_class_action != null and board_class_action.text == "CLASSE" and scene.find_child("PrimaryNavBadge_hunter", true, false) != null, "the primary navigation makes an unassigned class a concise pending action")
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	check(scene.find_child("HunterClassSummary", true, false) != null and scene.find_child("ChooseClassAction", true, false) != null, "the attribute profile exposes its class summary")
	scene.view_mode = "classes"
	scene.render()
	await process_frame
	check(scene.find_children("Class_*", "PanelContainer", true, false).size() == 3, "the class screen renders every initial archetype")
	check(find_label_with_text(scene, "ARQUÉTIPOS PROVISÓRIOS") != null, "the selector clearly identifies the current roster as provisional")
	check(scene.find_child("ClassDetail", true, false) != null and scene.find_child("ClassRouteProfile_warrant_breaker", true, false) != null, "the focused class sheet explains both build and contract identity")
	var breaker_impact := scene.find_child("ClassImpact_warrant_breaker", true, false) as Label
	check(breaker_impact != null and breaker_impact.text.contains("-2 DANO/GOLPE"), "breaker sheet previews its live per-hit mitigation")
	var first_class := scene.find_child("ClassSelect_warrant_breaker", true, false) as Button
	check(first_class != null and not first_class.disabled and first_class.text == "ESCOLHER", "the default preview can still be explicitly drafted by an unassigned hunter")
	var hacker_select := scene.find_child("ClassSelect_contract_hacker", true, false) as Button
	hacker_select.pressed.emit()
	await process_frame
	var hacker_impact := scene.find_child("ClassImpact_contract_hacker", true, false) as Label
	check(hacker_impact != null and hacker_impact.text.contains("+1 PODER") and hacker_impact.text.contains("+4 ABERTURA"), "the focused sheet previews its exact effect on the hunter's current build")
	var select := scene.find_child("ClassSelect_orbit_gunslinger", true, false) as Button
	check(select != null and not select.disabled, "an archetype can be drafted from its mobile action")
	if select != null:
		select.pressed.emit()
		await process_frame
	check(scene.class_draft == "orbit_gunslinger" and str(state.player.class_id).is_empty(), "class selection remains a reversible draft before confirmation")
	var gunslinger_impact := scene.find_child("ClassImpact_orbit_gunslinger", true, false) as Label
	check(gunslinger_impact != null and gunslinger_impact.text.contains("% MIRA"), "gunslinger sheet previews its live persistent precision")
	var confirm := scene.find_child("ConfirmClass", true, false) as Button
	check(confirm != null and not confirm.disabled, "a changed class draft enables explicit confirmation")
	if confirm != null:
		confirm.pressed.emit()
		await process_frame
	check(str(state.player.class_id) == "orbit_gunslinger" and scene.class_draft.is_empty(), "confirmation commits the class and clears transient navigation state")
	scene.view_mode = "attributes"
	scene.render()
	await process_frame
	var hunter_class_mechanic := scene.find_child("HunterClassMechanic", true, false) as Label
	check(hunter_class_mechanic != null and hunter_class_mechanic.text.contains("MIRA ORBITAL") and hunter_class_mechanic.text.contains("PRECISÃO"), "hunter sheet keeps the active class mechanic visible beside identity")
	check(scene.android_back_action() == "board", "Android Back treats the class selector as a safe secondary hub")

	scene.free()
	await process_frame
	finish()


func finish() -> void:
	if failures == 0:
		print("PASS: thematic classes specialize attributes and commit safely")
		quit(0)
	else:
		printerr("FAIL: %d class system test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func find_label_with_text(node: Node, fragment: String) -> Label:
	for candidate in node.find_children("*", "Label", true, false):
		if fragment in str((candidate as Label).text):
			return candidate as Label
	return null
