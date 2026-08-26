class_name EnemyProfileRules
extends RefCounted

const DEFINITIONS := {
	"training": {
		"title": "ALVO DE FRONTEIRA",
		"summary": "Sem contramedidas especiais. Compare Poder, vida e risco da rota.",
		"response": "QUALQUER BUILD COERENTE",
	},
	"plated": {
		"title": "BLINDAGEM IMPROVISADA",
		"summary": "Amortece 15% da abertura, mas amplifica ferramentas que ignoram defesa.",
		"response": "PODER SUSTENTADO · SOBRECARGA",
		"opening_damage_multiplier": 0.85,
		"defense_bypass_multiplier": 1.5,
	},
	"reckless": {
		"title": "PRESSÃO IMPRUDENTE",
		"summary": "Perfura 15% da mitigação e deixa espaço para retaliações.",
		"response": "VIDA · ESQUIVA · CONTRA-ATAQUE",
		"damage_reduction_piercing": 0.15,
		"counter_damage_multiplier": 1.5,
	},
	"elusive": {
		"title": "ASSINATURA EVASIVA",
		"summary": "Interfere com 30% dos bônus de mira; dano garantido ganha valor.",
		"response": "ABERTURA · PODER BRUTO",
		"attack_roll_bonus_multiplier": 0.70,
	},
	"elite": {
		"title": "MANDADO DE ELITE",
		"summary": "Sem fraqueza única. Exige uma build completa e uma rota consciente.",
		"response": "BUILD MISTA · KIT PLANETÁRIO",
	},
}


static func profile_id_for(target: Dictionary) -> String:
	if bool(target.get("challenge", false)):
		return ""
	if str(target.get("planet_id", "dustball_prime")) == "dustball_prime":
		return "training"
	if bool(target.get("boss", false)):
		return "elite"
	match int(target.get("chapter_tier", 0)):
		0: return "plated"
		1: return "reckless"
		2: return "elusive"
		_: return "elite"


static func profile_for(target: Dictionary) -> Dictionary:
	return DEFINITIONS.get(profile_id_for(target), {}).duplicate(true)


static func modifier(target: Dictionary, key: String, fallback: float) -> float:
	if target.has(key):
		return float(target.get(key, fallback))
	return float(profile_for(target).get(key, fallback))
