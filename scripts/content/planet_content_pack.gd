class_name PlanetContentPack
extends RefCounted

const CoreRules = preload("res://scripts/core_rules.gd")

const REQUIRED_PLANET_FIELDS := ["id", "name", "unlock_level", "travel_duration", "subtitle", "description", "accent", "completion_text"]
const REQUIRED_TARGET_FIELDS := ["id", "planet_id", "name", "title", "description", "power", "defense", "health", "duration", "credits", "xp", "rank", "chapter_tier", "attacks"]
const REQUIRED_EVENT_FIELDS := ["id", "planet_id", "symbol", "title", "description", "color", "choices"]
const REQUIRED_CHOICE_FIELDS := ["id", "name", "effect_text", "result"]


static func validation_errors(pack: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var pack_id := str(pack.get("id", ""))
	if not safe_id(pack_id):
		errors.append("pack id must use lowercase letters, digits, or underscores")
	var planet_value = pack.get("planet", {})
	if not planet_value is Dictionary:
		errors.append("planet entry must be a dictionary")
		planet_value = {}
	var planet: Dictionary = planet_value
	for field in REQUIRED_PLANET_FIELDS:
		if not planet.has(field) or str(planet.get(field, "")).is_empty():
			errors.append("planet is missing %s" % field)
	var planet_id := str(planet.get("id", ""))
	if planet_id != pack_id:
		errors.append("pack id and planet id must match")
	if int(planet.get("unlock_level", 0)) < 1:
		errors.append("planet unlock level must be positive")
	if float(planet.get("travel_duration", 0.0)) <= 0.0:
		errors.append("planet travel duration must be positive")

	var targets_value = pack.get("targets", [])
	if not targets_value is Array:
		errors.append("targets entry must be an array")
		targets_value = []
	var targets: Array = targets_value
	if targets.size() != 4:
		errors.append("planet pack must contain exactly four targets")
	var target_ids := {}
	var tier_counts := [0, 0, 0, 0]
	var boss_count := 0
	for target_value in targets:
		if not target_value is Dictionary:
			errors.append("target entry must be a dictionary")
			continue
		var target: Dictionary = target_value
		for field in REQUIRED_TARGET_FIELDS:
			if not target.has(field):
				errors.append("target %s is missing %s" % [str(target.get("id", "unknown")), field])
		var target_id := str(target.get("id", ""))
		if not safe_id(target_id) or target_ids.has(target_id):
			errors.append("target ids must be safe and unique: %s" % target_id)
		target_ids[target_id] = true
		if str(target.get("planet_id", "")) != planet_id:
			errors.append("target %s belongs to another planet" % target_id)
		var tier := int(target.get("chapter_tier", -1))
		if tier < 0 or tier > 3:
			errors.append("target %s has an invalid tier" % target_id)
		else:
			tier_counts[tier] += 1
		if int(target.get("power", 0)) <= 0 or int(target.get("health", 0)) <= 0:
			errors.append("target %s requires positive combat stats" % target_id)
		var attacks = target.get("attacks", [])
		if not attacks is Array or attacks.size() < 3:
			errors.append("target %s requires at least three attacks" % target_id)
		if bool(target.get("boss", false)):
			boss_count += 1
			if tier != 3:
				errors.append("planet boss must occupy tier three: %s" % target_id)
	if tier_counts != [1, 1, 1, 1]:
		errors.append("targets must cover tiers zero through three exactly once")
	if boss_count != 1:
		errors.append("planet pack must contain exactly one boss")

	var events_value = pack.get("events", [])
	if not events_value is Array:
		errors.append("events entry must be an array")
		events_value = []
	var events: Array = events_value
	if events.size() != 2:
		errors.append("planet pack must contain exactly two hunt events")
	var event_ids := {}
	var choice_ids := {}
	for event_value in events:
		if not event_value is Dictionary:
			errors.append("event entry must be a dictionary")
			continue
		var event: Dictionary = event_value
		for field in REQUIRED_EVENT_FIELDS:
			if not event.has(field):
				errors.append("event %s is missing %s" % [str(event.get("id", "unknown")), field])
		var event_id := str(event.get("id", ""))
		if not safe_id(event_id) or event_ids.has(event_id):
			errors.append("event ids must be safe and unique: %s" % event_id)
		event_ids[event_id] = true
		if str(event.get("planet_id", "")) != planet_id:
			errors.append("event %s belongs to another planet" % event_id)
		var choices_value = event.get("choices", [])
		if not choices_value is Array:
			errors.append("event %s choices must be an array" % event_id)
			choices_value = []
		var choices: Array = choices_value
		if choices.size() != 3:
			errors.append("event %s must contain exactly three choices" % event_id)
		for choice_value in choices:
			if not choice_value is Dictionary:
				errors.append("event %s contains a non-dictionary choice" % event_id)
				continue
			var choice: Dictionary = choice_value
			for field in REQUIRED_CHOICE_FIELDS:
				if not choice.has(field) or str(choice.get(field, "")).is_empty():
					errors.append("event %s choice is missing %s" % [event_id, field])
			var choice_id := str(choice.get("id", ""))
			if not safe_id(choice_id) or choice_ids.has(choice_id):
				errors.append("choice ids must be safe and unique: %s" % choice_id)
			choice_ids[choice_id] = true

	var items_value = pack.get("items", {})
	if not items_value is Dictionary:
		errors.append("items entry must be a dictionary")
		items_value = {}
	var items: Dictionary = items_value
	for slot in ["weapon", "armor"]:
		var catalog_value = items.get(slot, [])
		if not catalog_value is Array:
			errors.append("%s catalog must be an array" % slot)
			catalog_value = []
		var catalog: Array = catalog_value
		if catalog.size() != 4:
			errors.append("planet pack requires four %s templates" % slot)
		for item_value in catalog:
			if not item_value is Dictionary or str(item_value.get("name", "")).is_empty() or str(item_value.get("description", "")).is_empty():
				errors.append("%s templates require name and description" % slot)

	var secondary_items_value = pack.get("secondary_items", {})
	if not secondary_items_value is Dictionary:
		errors.append("secondary items entry must be a dictionary")
		secondary_items_value = {}
	var secondary_items: Dictionary = secondary_items_value
	for slot in secondary_items:
		if not CoreRules.EQUIPMENT_SLOTS.has(str(slot)) or str(slot) in ["weapon", "armor"]:
			errors.append("secondary item catalog uses an invalid slot: %s" % str(slot))
		elif not secondary_items[slot] is Array or secondary_items[slot].size() != 4:
			errors.append("secondary item catalog requires four templates: %s" % str(slot))
	return errors


static func is_valid(pack: Dictionary) -> bool:
	return validation_errors(pack).is_empty()


static func safe_id(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		var code := character.unicode_at(0)
		if not (code >= 97 and code <= 122) and not (code >= 48 and code <= 57) and character != "_":
			return false
	return true
