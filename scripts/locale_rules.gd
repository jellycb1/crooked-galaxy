class_name LocaleRules
extends RefCounted

const DEFAULT_ID := "pt"
const DEFINITIONS := [
	{"id": "pt", "name": "Português", "native_name": "Português", "selectable": true},
	{"id": "en", "name": "Inglês", "native_name": "English", "selectable": false},
]


static func is_valid(locale_id: String) -> bool:
	return not get_definition(locale_id).is_empty()


static func is_selectable(locale_id: String) -> bool:
	return bool(get_definition(locale_id).get("selectable", false))


static func get_definition(locale_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.id) == locale_id:
			return definition.duplicate(true)
	return {}


static func locale_name_for(locale_id: String) -> String:
	return str(get_definition(locale_id).get("native_name", "IDIOMA INDISPONÍVEL"))
