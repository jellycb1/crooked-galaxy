extends SceneTree

const Species = preload("res://scripts/species_rules.gd")
const Locales = preload("res://scripts/locale_rules.gd")

var failures := 0
var state
var test_save_path := ""


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	state = root.get_node_or_null("GameState")
	check(state != null, "autoload is available for onboarding")
	if state == null:
		finish()
		return
	test_save_path = "res://.godot/onboarding_test_%d.json" % Time.get_ticks_usec()
	state.save_path = test_save_path
	state.persistence_enabled = true
	state.save_recovery_required = false
	state.save_warning = ""
	state.account = {}
	state.player = state.default_player()
	state.phase = state.Phase.BOARD
	state.current_bounty = {}
	check(Species.DEFINITIONS.size() == 8 and Species.DEFINITIONS.all(func(definition): return not bool(definition.prototype)), "the initial species roster exposes eight finalized visual identities")
	check(Species.DEFINITIONS.map(func(definition): return str(definition.id)).all(func(species_id): return Species.is_valid(species_id)), "every displayed species is accepted by identity validation")
	check(state.requires_onboarding() and state.onboarding_step() == "login", "a new local profile cannot bypass login")
	state.select_bounty(ContentDB.TARGETS[0])
	check(state.phase == state.Phase.BOARD and state.current_bounty.is_empty(), "state-level bounty entry is blocked before identity completion")

	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	TranslationServer.set_locale("en")
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "SIGN IN") != null and find_label_with_text(scene, "FIRST WORLD") != null and (scene.find_child("OnboardingLoginAction", true, false) as Button).text == "ENTER INTERNATIONAL 1", "English catalog renders the complete login and server surface")
	check(Locales.text("ONB_NOTICE_SESSION", "", ["International 1"]) == "Local session started on International 1. No online connection was simulated.", "English catalog includes onboarding transaction feedback")
	state.account = {"mode": "local_test", "session_id": "locale_preview", "locale_id": "pt", "server_id": "international_1"}
	scene.class_draft = "warrant_breaker"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "CHOOSE YOUR CLASS") != null and find_label_with_text(scene, "WARRANT BREAKER") != null and find_label_with_text(scene, "Hard Shell") != null and (scene.find_child("OnboardingClassConfirm", true, false) as Button).text == "CONFIRM CLASS", "English catalog covers class chrome, content, and exact specialization")
	state.player.class_id = "contract_hacker"
	scene.class_draft = ""
	scene.species_draft = "scraproot"
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "CHOOSE YOUR SPECIES") != null and find_label_with_text(scene, "Scraproot") != null and find_label_with_text(scene, "BOTANICAL · GRAFTED") != null and (scene.find_child("OnboardingSpeciesConfirm", true, false) as Button).text == "CONFIRM SPECIES", "English catalog covers all cosmetic-origin selector layers")
	state.player.species_id = "synthetic"
	state.player.appearance = {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	scene.species_draft = ""
	scene.render()
	await process_frame
	check(find_label_with_text(scene, "HUNTER NAME") != null and find_label_with_text(scene, "CLASS · CONTRACT HACKER") != null and find_label_with_text(scene, "SPECIES · Synthetic") != null and (scene.find_child("OnboardingNameConfirm", true, false) as Button).text == "ENTER THE GALAXY", "English catalog covers final identity review and entry")
	TranslationServer.set_locale("pt")
	state.account = {}
	state.player = state.default_player()
	scene.class_draft = ""
	scene.species_draft = ""
	scene.render()
	await process_frame
	check(scene.find_child("OnboardingLoginAction", true, false) != null and scene.find_child("HeaderResourceStrip", true, false) == null, "login replaces the game shell instead of overlaying it")
	check(state.begin_local_session("en", "international_1") and str(state.account.locale_id) == "en", "complete English catalog can start a persistent international session")
	state.account = {}
	TranslationServer.set_locale("pt")
	scene.locale_draft = "pt"
	scene.render()
	await process_frame
	check(not state.begin_local_session("pt", "unknown_world") and state.account.is_empty(), "an unknown server cannot create a local account identity")
	var portuguese := scene.find_child("OnboardingLanguage_pt", true, false) as Button
	var english := scene.find_child("OnboardingLanguage_en", true, false) as Button
	check(portuguese != null and portuguese.disabled and english != null and not english.disabled and not english.text.contains("EM TRADUÇÃO"), "login offers both complete languages and marks only the active one selected")
	check(scene.find_child("OnboardingServer_international_1", true, false) != null and scene.find_child("OnboardingServerSelected", true, false) != null, "login binds the first account world to International 1")
	check_onboarding_touch_targets(scene, "login")
	var login := scene.find_child("OnboardingLoginAction", true, false) as Button
	login.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "class" and str(state.account.server_id) == "international_1" and str(state.account.locale_id) == "pt" and TranslationServer.get_locale().begins_with("pt") and not state.account.has("password"), "local login applies language and stores server identity without credentials")
	check(scene.find_children("OnboardingClass_*", "PanelContainer", true, false).size() == 3, "mandatory class step shows the complete initial trio")
	check(scene.find_child("OnboardingClassPreview", true, false) != null and scene.find_child("OnboardingClassPreviewName", true, false) != null, "class choice owns a live archetype preview before confirmation")
	scene.class_draft = "orbit_gunslinger"
	scene.render()
	check(scene.find_child("OnboardingClassPreviewIcon", true, false) != null, "the Orbit Gunslinger preview uses its deliberate vector emblem while replacement art is unapproved")
	for class_id in ["warrant_breaker", "contract_hacker"]:
		scene.class_draft = class_id
		scene.render()
		check(scene.find_child("OnboardingClassPreviewIcon", true, false) != null, "initial class '%s' keeps a consistent vector-emblem fallback" % class_id)
	scene.class_draft = ""
	scene.render()
	check_onboarding_touch_targets(scene, "class")
	var class_confirm := scene.find_child("OnboardingClassConfirm", true, false) as Button
	var class_scroll := scene.find_child("OnboardingScroll", true, false) as ScrollContainer
	check(class_confirm != null and class_confirm.get_parent() != class_scroll.get_child(0), "class confirmation stays fixed outside its visual roster")
	check(class_confirm != null and class_confirm.disabled, "class confirmation requires an explicit choice")
	var class_action := scene.find_child("OnboardingClassAction_contract_hacker", true, false) as Button
	class_action.pressed.emit()
	await process_frame
	class_confirm = scene.find_child("OnboardingClassConfirm", true, false) as Button
	var class_preview_name := scene.find_child("OnboardingClassPreviewName", true, false) as Label
	var class_specialization := scene.find_child("OnboardingClassSpecialization", true, false) as Label
	check(class_confirm != null and not class_confirm.disabled and str(state.player.class_id).is_empty() and class_preview_name.text == "HACKER DE CONTRATOS", "class focus updates its preview but remains a draft until confirmation")
	check(class_specialization != null and class_specialization.text.contains("Invasão") and find_label_with_text(scene, "IDENTIDADE DE CLASSE") != null, "mandatory class choice explains its active mechanic and finalized identity")
	class_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "species" and str(state.player.class_id) == "contract_hacker", "confirmed class advances exactly to species")
	check(scene.find_children("OnboardingSpecies_*", "PanelContainer", true, false).size() == 8, "species step exposes all eight visual origins")
	check(scene.find_children("OnboardingSpeciesIcon_*", "Control", true, false).size() == 8, "every initial species has an original scalable emblem")
	check(scene.find_child("OnboardingSpeciesPreviewPortrait", true, false) != null and scene.find_child("OnboardingSpeciesPreviewName", true, false) != null, "species choice previews the assembled hunter before confirmation")
	var species_scroll := scene.find_child("OnboardingScroll", true, false) as ScrollContainer
	var fixed_species_confirm := scene.find_child("OnboardingSpeciesConfirm", true, false) as Button
	check(fixed_species_confirm != null and fixed_species_confirm.get_parent() != species_scroll.get_child(0), "species confirmation stays outside the long scrolling roster")
	check_onboarding_touch_targets(scene, "species")
	await process_frame
	await process_frame
	# Constrain the harness to exercise the same overflow path used by smaller or
	# enlarged-text Android layouts; the default 720x1280 test viewport fits it.
	(species_scroll.get_child(0) as Control).custom_minimum_size.y = 1600
	await process_frame
	species_scroll.scroll_vertical = 160
	await process_frame
	(scene.find_child("OnboardingSpeciesAction_scraproot", true, false) as Button).pressed.emit()
	species_scroll = scene.find_child("OnboardingScroll", true, false) as ScrollContainer
	(species_scroll.get_child(0) as Control).custom_minimum_size.y = 1600
	await process_frame
	await process_frame
	await process_frame
	check(str(scene.species_draft) == "scraproot" and species_scroll.scroll_vertical >= 120, "selecting a lower species preserves roster position while updating the preview (draft %s, scroll %d, remembered %d, generation %d)" % [str(scene.species_draft), species_scroll.scroll_vertical, int(scene.onboarding_scroll_position), int(scene.render_generation)])
	var species_action := scene.find_child("OnboardingSpeciesAction_synthetic", true, false) as Button
	species_action.pressed.emit()
	await process_frame
	var species_confirm := scene.find_child("OnboardingSpeciesConfirm", true, false) as Button
	check(species_confirm != null and not species_confirm.disabled and str(state.player.species_id).is_empty(), "species focus remains a draft until confirmation")
	species_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "appearance" and str(state.player.species_id) == "synthetic", "confirmed species advances exactly to cosmetic customization")
	check(scene.find_child("OnboardingAppearancePreview", true, false) != null and scene.find_child("OnboardingAppearanceNext_palette", true, false) != null, "appearance step exposes a live portrait and touch-friendly cosmetic selectors")
	(scene.find_child("OnboardingAppearanceNext_palette", true, false) as Button).pressed.emit()
	await process_frame
	check(str(scene.appearance_draft.palette) == "warm", "appearance selectors update the reversible live draft")
	(scene.find_child("OnboardingAppearanceConfirm", true, false) as Button).pressed.emit()
	await process_frame
	check(state.onboarding_step() == "name" and str(state.player.appearance.palette) == "warm", "appearance confirmation persists the cosmetic recipe before naming")
	check(scene.find_child("OnboardingHunterPortrait", true, false) != null and scene.find_child("OnboardingChangeClass", true, false) != null and scene.find_child("OnboardingChangeSpecies", true, false) != null and scene.find_child("OnboardingChangeAppearance", true, false) != null, "final identity review shows the hunter and all correction routes")
	var change_class := scene.find_child("OnboardingChangeClass", true, false) as Button
	change_class.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "class" and str(state.player.species_id) == "synthetic", "class correction retains the already confirmed species")
	(scene.find_child("OnboardingClassAction_contract_hacker", true, false) as Button).pressed.emit()
	await process_frame
	(scene.find_child("OnboardingClassConfirm", true, false) as Button).pressed.emit()
	await process_frame
	var change_species := scene.find_child("OnboardingChangeSpecies", true, false) as Button
	change_species.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "species" and str(state.player.class_id) == "contract_hacker", "species correction retains the already confirmed class")
	(scene.find_child("OnboardingSpeciesAction_synthetic", true, false) as Button).pressed.emit()
	await process_frame
	(scene.find_child("OnboardingSpeciesConfirm", true, false) as Button).pressed.emit()
	await process_frame
	check(state.onboarding_step() == "appearance", "corrected species returns through visual customization")
	(scene.find_child("OnboardingAppearanceConfirm", true, false) as Button).pressed.emit()
	await process_frame
	check(state.onboarding_step() == "name", "corrected class, species, and appearance return to final naming")
	var name_input := scene.find_child("OnboardingNameInput", true, false) as LineEdit
	var name_confirm := scene.find_child("OnboardingNameConfirm", true, false) as Button
	check(name_input != null and name_confirm != null and name_confirm.disabled, "empty hunter names cannot finish creation")
	check_onboarding_touch_targets(scene, "name")
	name_input.text = "  Nova   Vex  "
	name_input.text_changed.emit(name_input.text)
	await process_frame
	check(not name_confirm.disabled, "a valid mobile name enables explicit entry")
	name_confirm.pressed.emit()
	await process_frame
	check(state.onboarding_step() == "complete" and str(state.player.hunter_name) == "Nova Vex", "completion stores the normalized hunter name")
	check(scene.find_child("HeaderResourceStrip", true, false) != null and scene.find_child("PrimaryNavigationDock", true, false) != null, "completed identity enters the real game shell")
	check(scene.find_child("OnboardingScroll", true, false) == null, "onboarding is removed after completion")

	var persisted: Dictionary = state.read_save_dictionary(test_save_path)
	check(str(persisted.account.mode) == "local_test" and str(persisted.account.server_id) == "international_1" and str(persisted.account.locale_id) == "pt" and str(persisted.player.class_id) == "contract_hacker" and str(persisted.player.species_id) == "synthetic" and str(persisted.player.hunter_name) == "Nova Vex" and str(persisted.player.appearance.palette) == "native", "server, locale, and every confirmed character stage survive interruption")
	check(str(persisted.account.provider_id) == "local_device" and str(persisted.account.authority) == "device" and str(persisted.account.sync_state) == "local_only" and str(persisted.account.active_character_id) == str(persisted.player.character_id), "fresh onboarding persists honest local authority and character ownership")
	scene.queue_free()
	await process_frame
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func find_label_with_text(scene: Node, expected: String) -> Label:
	for candidate in scene.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label.text.contains(expected):
			return label
	return null


func check_onboarding_touch_targets(scene: Control, step: String) -> void:
	for candidate in scene.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button.visible:
			check(button.custom_minimum_size.y >= 48.0, "%s action '%s' remains a mobile touch target" % [step, str(button.name)])


func finish() -> void:
	state.persistence_enabled = false
	for path in [test_save_path, "%s.tmp" % test_save_path, "%s.bak" % test_save_path]:
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("PASS: mandatory onboarding gates and persists hunter identity")
		quit(0)
	else:
		printerr("FAIL: %d onboarding issue(s)" % failures)
		quit(1)
