class_name LocaleRules
extends RefCounted

const DEFAULT_ID := "pt"
const DEFINITIONS := [
	{"id": "pt", "name": "Português", "native_name": "Português", "selectable": true},
	{"id": "en", "name": "Inglês", "native_name": "English", "selectable": true},
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


static func text(key: String, fallback: String = "", values: Array = []) -> String:
	var translated := str(TranslationServer.translate(key))
	if translated == key:
		translated = fallback if not fallback.is_empty() else key
	return translated % values if not values.is_empty() else translated


static func content_key(prefix: String, content_id: String, field: String) -> String:
	return "%s_%s_%s" % [prefix.to_upper(), content_id.to_upper(), field.to_upper()]
