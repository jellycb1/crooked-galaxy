class_name ContentDB
extends RefCounted


const PLANET := {
	"id": "dustball_prime",
	"name": "Dustball Prime",
	"subtitle": "A poeira entra em tudo. Inclusive nos contratos.",
}

const TARGETS := [
	{
		"id": "gloop",
		"name": "Gloop, o Inconveniente",
		"title": "Ladrão de estacionamento orbital",
		"description": "Roubou 43 naves. Nenhuma era a nave certa.",
		"emoji": "👽",
		"power": 11,
		"defense": 4,
		"health": 70,
		"duration": 5,
		"credits": 38,
		"xp": 42,
		"rank": 0,
	},
	{
		"id": "baron_boom",
		"name": "Barão Boom",
		"title": "Nobreza autoproclamada e explosiva",
		"description": "Assina todos os documentos com dinamite. Até recibos.",
		"emoji": "💥",
		"power": 16,
		"defense": 6,
		"health": 96,
		"duration": 7,
		"credits": 58,
		"xp": 62,
		"rank": 1,
	},
	{
		"id": "madame_vacuum",
		"name": "Madame Vácuo",
		"title": "Contrabandista de oxigênio premium",
		"description": "Vende ar engarrafado e cobra pela tampa separadamente.",
		"emoji": "🪐",
		"power": 23,
		"defense": 9,
		"health": 128,
		"duration": 9,
		"credits": 88,
		"xp": 90,
		"rank": 2,
	},
]

const ITEM_NAMES := {
	"weapon": ["Desatomizador de Bolso", "Canhão de Recibos", "Pistola Quase Legal", "Zapper de Plasma Torto"],
	"armor": ["Casaco Antilaser Usado", "Colete de Espuma Cósmica", "Armadura Fiscal", "Poncho de Titânio"],
}


static func available_bounties(reputation: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in TARGETS:
		if int(target.rank) <= reputation:
			result.append(target.duplicate(true))
	return result


static func generate_loot(target: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var slot := "weapon" if rng.randf() < 0.58 else "armor"
	var names: Array = ITEM_NAMES[slot]
	var base_power := int(target.power * rng.randf_range(0.36, 0.68))
	var rarity_roll := rng.randf()
	var rarity := "Comum"
	var rarity_color := "#b9c2d9"
	var bonus := 0
	if rarity_roll > 0.92:
		rarity = "Épico"
		rarity_color = "#d789ff"
		bonus = 5
	elif rarity_roll > 0.68:
		rarity = "Raro"
		rarity_color = "#58d9ff"
		bonus = 2
	return {
		"id": "%s_%s_%d" % [target.id, slot, rng.randi()],
		"name": names[rng.randi_range(0, names.size() - 1)],
		"slot": slot,
		"power": maxi(1, base_power + bonus),
		"rarity": rarity,
		"color": rarity_color,
	}
