class_name AppearanceRules
extends RefCounted

# Stable cosmetic IDs are saved instead of translated labels. The portrait
# renderer interprets these common slots according to each species' anatomy.
const CATEGORIES := ["palette", "eyes", "feature", "marking"]
const OPTIONS := {
	"palette": ["native", "warm", "cool"],
	"eyes": ["standard", "wide", "narrow"],
	"feature": ["classic", "bold", "subtle"],
	"marking": ["clean", "stripe", "spots"],
}


static func default_appearance() -> Dictionary:
	return {"palette": "native", "eyes": "standard", "feature": "classic", "marking": "clean"}


static func is_complete(value) -> bool:
	if not value is Dictionary:
		return false
	for category in CATEGORIES:
		if not str(value.get(category, "")) in OPTIONS[category]:
			return false
	return true


static func sanitize(value) -> Dictionary:
	var clean := default_appearance()
	if value is Dictionary:
		for category in CATEGORIES:
			var option := str(value.get(category, clean[category]))
			if option in OPTIONS[category]:
				clean[category] = option
	return clean


static func cycle(value: Dictionary, category: String, direction: int) -> Dictionary:
	var clean := sanitize(value)
	if not category in CATEGORIES:
		return clean
	var options: Array = OPTIONS[category]
	var index := options.find(str(clean[category]))
	clean[category] = options[posmod(index + direction, options.size())]
	return clean
