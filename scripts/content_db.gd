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
		"attacks": ["Tapa Tentacular", "Cuspe de Formulário", "Raio Mal Estacionado"],
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
		"attacks": ["Decreto Explosivo", "Imposto de Impacto", "Brasão-Bomba"],
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
		"attacks": ["Vácuo Executivo", "Taxa de Respiração", "Sucção Premium"],
	},
]

const PLAYER_ATTACKS := [
	"Ricochete de Plasma",
	"Cobrança à Queima-Roupa",
	"Disparo Quase Calculado",
	"Cláusula de Perfuração",
]

const CONTRACT_APPROACHES := [
	{
		"id": "quiet_net",
		"name": "Rede Silenciosa",
		"tag": "SEGURO · +XP",
		"description": "Cerque o alvo, desligue as saídas e finja que tudo estava planejado.",
		"duration_mult": 1.35,
		"power_mult": 0.92,
		"defense_mult": 0.85,
		"health_mult": 1.0,
		"credits_mult": 0.90,
		"xp_mult": 1.25,
		"color": "#55e5ff",
	},
	{
		"id": "hot_hatch",
		"name": "Entrada pela Escotilha",
		"tag": "RÁPIDO · +CRÉDITOS",
		"description": "Chegue antes do plano, chute a porta errada e cobre taxa de urgência.",
		"duration_mult": 0.55,
		"power_mult": 1.12,
		"defense_mult": 1.0,
		"health_mult": 1.08,
		"credits_mult": 1.35,
		"xp_mult": 1.0,
		"color": "#ff6f7d",
	},
	{
		"id": "premium_warrant",
		"name": "Mandado Corporativo",
		"tag": "LUCRO · ALTO RISCO",
		"description": "A corporação paga muito mais, desde que o alvo possa revidar muito mais.",
		"duration_mult": 1.0,
		"power_mult": 1.18,
		"defense_mult": 1.12,
		"health_mult": 1.12,
		"credits_mult": 1.65,
		"xp_mult": 0.85,
		"color": "#ffc857",
	},
]

const ITEM_CATALOG := {
	"weapon": [
		{"name": "Desatomizador de Bolso", "description": "Desmonta átomos, garantias e conversas constrangedoras."},
		{"name": "Canhão de Recibos", "description": "A prova de compra chega antes do projétil."},
		{"name": "Pistola Quase Legal", "description": "Legal em pelo menos duas luas e meia."},
		{"name": "Zapper de Plasma Torto", "description": "O tiro faz curva. Às vezes até na direção certa."},
	],
	"armor": [
		{"name": "Casaco Antilaser Usado", "description": "As marcas de queimadura comprovam que já funcionou."},
		{"name": "Colete de Espuma Cósmica", "description": "Confortável, protetor e estranhamente efervescente."},
		{"name": "Armadura Fiscal", "description": "Deduz parte do dano no próximo ano galáctico."},
		{"name": "Poncho de Titânio", "description": "Elegância de fronteira com nove quilos por ombro."},
	],
}


static func available_bounties(reputation: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target in TARGETS:
		if int(target.rank) <= reputation:
			result.append(target.duplicate(true))
	return result


static func contract_approaches() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for approach in CONTRACT_APPROACHES:
		result.append(approach.duplicate(true))
	return result


static func apply_approach(bounty: Dictionary, approach: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	result["approach"] = approach.duplicate(true)
	result["duration"] = maxi(1, ceili(float(bounty.duration) * float(approach.duration_mult)))
	result["power"] = maxi(1, roundi(float(bounty.power) * float(approach.power_mult)))
	result["defense"] = maxi(0, roundi(float(bounty.defense) * float(approach.defense_mult)))
	result["health"] = maxi(1, roundi(float(bounty.health) * float(approach.health_mult)))
	result["credits"] = maxi(1, roundi(float(bounty.credits) * float(approach.credits_mult)))
	result["xp"] = maxi(1, roundi(float(bounty.xp) * float(approach.xp_mult)))
	return result


static func generate_loot(target: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var slot := "weapon" if rng.randf() < 0.58 else "armor"
	var catalog: Array = ITEM_CATALOG[slot]
	var definition: Dictionary = catalog[rng.randi_range(0, catalog.size() - 1)]
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
		"name": definition.name,
		"description": definition.description,
		"slot": slot,
		"power": maxi(1, base_power + bonus),
		"rarity": rarity,
		"color": rarity_color,
	}


static func player_attack(rng: RandomNumberGenerator) -> String:
	return PLAYER_ATTACKS[rng.randi_range(0, PLAYER_ATTACKS.size() - 1)]


static func target_attack(target: Dictionary, rng: RandomNumberGenerator) -> String:
	var attacks: Array = target.get("attacks", ["Golpe Suspeito"])
	return attacks[rng.randi_range(0, attacks.size() - 1)]
