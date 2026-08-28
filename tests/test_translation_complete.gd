extends SceneTree

const Challenge = preload("res://scripts/challenge_rules.gd")
const Core = preload("res://scripts/core_rules.gd")
const Locales = preload("res://scripts/locale_rules.gd")
const State = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var pt_keys := po_keys("res://locales/crooked.pt.po")
	var en_keys := po_keys("res://locales/crooked.en.po")
	check(pt_keys.size() == en_keys.size() and pt_keys.size() >= 1190, "PT and EN catalogs expose the same complete key count")
	check(unique_count(pt_keys) == pt_keys.size() and unique_count(en_keys) == en_keys.size(), "neither catalog contains duplicate keys")
	check(pt_keys.all(func(key): return en_keys.has(key)), "PT and EN catalogs have exact key parity")
	check(po_empty_values("res://locales/crooked.pt.po") == 0 and po_empty_values("res://locales/crooked.en.po") == 0, "neither catalog contains an empty translation")
	check(Locales.DEFINITIONS.all(func(locale): return bool(locale.selectable)), "both documented languages are selectable")
	var runtime_keys := literal_runtime_keys()
	check(runtime_keys.size() >= 586, "completeness guard discovers the complete literal runtime-key surface")
	for runtime_key in runtime_keys:
		check(pt_keys.has(runtime_key) and en_keys.has(runtime_key), "literal runtime key exists in both catalogs: %s" % runtime_key)
	var locale_save := "res://.godot/translation_locale_%s.json" % OS.get_process_id()
	var locale_state = State.new()
	locale_state.save_path = locale_save
	locale_state.persistence_enabled = true
	locale_state.save_recovery_required = false
	locale_state.account = {"mode": "local_test", "session_id": "locale_persistence", "locale_id": "pt", "server_id": "international_1"}
	locale_state.player = locale_state.default_player()
	check(locale_state.set_locale("en"), "language selection commits through the normal save transaction")
	var restored_locale = State.new()
	restored_locale.save_path = locale_save
	restored_locale.persistence_enabled = true
	restored_locale.load_game()
	check(str(restored_locale.account.get("locale_id", "")) == "en" and TranslationServer.get_locale().begins_with("en"), "English language selection survives a complete save/load cycle")
	locale_state.free()
	restored_locale.free()
	for path in [locale_save, "%s.tmp" % locale_save, "%s.bak" % locale_save]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	TranslationServer.set_locale("en")
	for planet in ContentDB.PLANETS:
		for field in ["name", "subtitle", "description", "completion_text"]:
			check_catalog_key(pt_keys, en_keys, Locales.content_key("planet", str(planet.id), field), "planet %s" % field)
		check_translation(Locales.content_key("planet", str(planet.id), "name"), "planet name")
		check_translation(Locales.content_key("planet", str(planet.id), "completion_text"), "chapter finale")
	for target in ContentDB.TARGETS:
		for field in ["name", "title", "description"]:
			check_catalog_key(pt_keys, en_keys, Locales.content_key("target", str(target.id), field), "target %s" % field)
		for attack_index in target.get("attacks", []).size():
			check_catalog_key(pt_keys, en_keys, "TARGET_%s_ATTACK_%d" % [str(target.id).to_upper(), attack_index], "target attack")
	for event in ContentDB.HUNT_EVENTS:
		for field in ["title", "description"]:
			check_catalog_key(pt_keys, en_keys, Locales.content_key("hunt_event", str(event.id), field), "hunt event %s" % field)
		for choice in event.get("choices", []):
			for field in ["name", "effect_text", "result"]:
				var event_key := "HUNT_EVENT_%s_CHOICE_%s_%s" % [str(event.id).to_upper(), str(choice.id).to_upper(), field.to_upper()]
				check_catalog_key(pt_keys, en_keys, event_key, "hunt event choice %s" % field)
	for planet in ContentDB.PLANETS:
		for slot in Core.EQUIPMENT_SLOTS:
			var catalog := ContentDB.item_catalog_for(str(planet.id), slot)
			for item_index in catalog.size():
				for field in ["name", "description"]:
					var item_key := "ITEM_%s_%s_%d_%s" % [str(planet.id).to_upper(), slot.to_upper(), item_index, field.to_upper()]
					check_catalog_key(pt_keys, en_keys, item_key, "planet item %s" % field)
	for stage in Challenge.STAGES:
		for field in ["name", "title", "description"]:
			check_translation(Locales.content_key("rift_stage", str(stage.id), field), "Rift stage %s" % field)
		for attack_index in 3:
			check_translation("RIFT_STAGE_%s_ATTACK_%d" % [str(stage.id).to_upper(), attack_index], "Rift attack")
		for field in ["name", "description"]:
			check_translation("RIFT_REWARD_%s_%s" % [str(stage.id).to_upper(), field.to_upper()], "Rift reward %s" % field)
	for anomaly_id in Challenge.ANOMALY_PROFILES:
		for field in ["name", "description", "favored_axis"]:
			check_translation("RIFT_ANOMALY_%s_%s" % [str(anomaly_id).to_upper(), field.to_upper()], "Rift anomaly %s" % field)

	var state = root.get_node_or_null("GameState")
	check(state != null, "autoload exists for bilingual rendering audit")
	if state == null:
		finish()
		return
	state.persistence_enabled = false
	state.account = {"mode": "local_test", "session_id": "translation_audit", "locale_id": "en", "server_id": "international_1"}
	state.player = state.default_player()
	state.player.class_id = "orbit_gunslinger"
	state.player.species_id = "starworn"
	state.player.appearance = {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}
	state.player.hunter_name = "Nova"
	state.player.completed_planets = ["dustball_prime"]
	state.player.level = Challenge.UNLOCK_LEVEL
	state.player.challenge_floor = 0
	state.phase = state.Phase.BOARD
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	scene.view_mode = "challenges"
	scene.render()
	await process_frame
	check(has_label(scene, "CLANDESTINE RIFT") and has_label(scene, "Customs of the Dead Universe") and has_label(scene, "FLOOR 1 · ILLEGAL SCREENING") and has_label(scene, "Dead Customs Drone") and has_label(scene, "VOLATILE CHAMBER") and has_label(scene, "SEALED REWARD") and not has_label(scene, "Broken Seal Rig"), "English Rift dossier localizes the reality and current enemy while keeping the reward concealed")
	var enter := scene.find_child("ChallengeEnterAction", true, false) as Button
	check(enter != null and enter.text == "ENTER THE RIFT · ENEMY 1/12", "English Rift daily entry action is localized")

	state.current_bounty = Challenge.stage_at(0)
	state.pending_loot = Challenge.reward_for(state.current_bounty, ContentDB.ITEM_TRAITS)
	state.phase = state.Phase.REWARD
	scene.render()
	await process_frame
	check(has_label(scene, "ARTIFACT RECOVERED") and has_label(scene, "Broken Seal Rig") and has_label(scene, "RIFT RECEIPT"), "English Rift reward and transaction receipt render without fallback")

	for planet_index in ContentDB.PLANETS.size():
		var planet: Dictionary = ContentDB.PLANETS[planet_index]
		var targets: Array = ContentDB.TARGETS.filter(func(target): return str(target.get("planet_id", ContentDB.PLANET.id)) == str(planet.id))
		var boss: Dictionary = targets[targets.size() - 1]
		state.chapter_completion = {"planet": planet.duplicate(true), "target": boss.duplicate(true), "total_captures": 10, "credits": int(boss.credits), "xp": int(boss.xp)}
		state.phase = state.Phase.CHAPTER_COMPLETE
		scene.render()
		await process_frame
		var planet_name := str(TranslationServer.translate(Locales.content_key("planet", str(planet.id), "name")))
		var boss_name := str(TranslationServer.translate(Locales.content_key("target", str(boss.id), "name")))
		var finale := str(TranslationServer.translate(Locales.content_key("planet", str(planet.id), "completion_text")))
		check(has_label(scene, "CHAPTER COMPLETE") and has_label(scene, planet_name) and has_label(scene, boss_name) and has_label(scene, finale), "English chapter finale %d renders all dynamic content" % (planet_index + 1))

	state.phase = state.Phase.BOARD
	state.chapter_completion = {}
	scene.view_mode = "settings"
	scene.render()
	await process_frame
	check(scene.find_child("SettingsLanguage_pt", true, false) != null and scene.find_child("SettingsLanguage_en", true, false) != null, "settings exposes both language choices")
	check(state.set_locale("pt") and str(state.account.locale_id) == "pt" and TranslationServer.get_locale().begins_with("pt"), "settings switches session and account to Portuguese")
	await process_frame
	check(has_label(scene, "AJUSTES") and state.last_notice == "Idioma alterado para Português.", "language switch immediately rerenders Portuguese and localizes its receipt")
	check(state.set_locale("en") and str(state.account.locale_id) == "en" and TranslationServer.get_locale().begins_with("en"), "settings switches session and account back to English")
	await process_frame
	check(has_label(scene, "SETTINGS") and state.last_notice == "Language changed to English.", "language switch immediately rerenders English and localizes its receipt")

	scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	TranslationServer.set_locale("pt")
	finish()


func po_keys(path: String) -> Array[String]:
	var result: Array[String] = []
	var regex := RegEx.new()
	regex.compile("(?m)^msgid \\\"(.+)\\\"$")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	for match in regex.search_all(file.get_as_text()):
		result.append(match.get_string(1))
	result.sort()
	return result


func po_empty_values(path: String) -> int:
	var regex := RegEx.new()
	regex.compile("(?m)^msgstr \\\"\\\"$")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 1
	return maxi(0, regex.search_all(file.get_as_text()).size() - 1)


func unique_count(values: Array[String]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()


func literal_runtime_keys() -> Array[String]:
	var keys := {}
	var regex := RegEx.new()
	regex.compile("(?:\\bt|\\btext|\\blocal_text|LocaleRules(?:Script)?\\.text)\\(\\s*\\\"([A-Z][A-Z0-9_]+)\\\"")
	for filename in DirAccess.get_files_at("res://scripts"):
		if not filename.ends_with(".gd"):
			continue
		var file := FileAccess.open("res://scripts/%s" % filename, FileAccess.READ)
		if file == null:
			continue
		for match in regex.search_all(file.get_as_text()):
			keys[match.get_string(1)] = true
	var result: Array[String] = []
	result.assign(keys.keys())
	result.sort()
	return result


func check_translation(key: String, context: String) -> void:
	var translated := str(TranslationServer.translate(key))
	check(translated != key and not translated.is_empty(), "%s has English text: %s" % [context, key])


func check_catalog_key(pt_keys: Array[String], en_keys: Array[String], key: String, context: String) -> void:
	check(pt_keys.has(key) and en_keys.has(key), "%s exists in both catalogs: %s" % [context, key])


func has_label(scene: Node, expected: String) -> bool:
	for candidate in scene.find_children("*", "Label", true, false):
		if str((candidate as Label).text).contains(expected):
			return true
	return false


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: PT/EN catalogs, Rift, finales, and language switching are complete")
		quit(0)
	else:
		printerr("FAIL: %d translation completeness issue(s)" % failures)
		quit(1)
