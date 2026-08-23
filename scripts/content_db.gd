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

const HUNT_EVENTS := [
	{
		"id": "toll_drone",
		"title": "Pedágio de Drone D-7",
		"description": "Um drone municipal bloqueia a rota. O adesivo diz: “totalmente oficial”.",
		"color": "#55e5ff",
		"choices": [
			{
				"id": "bribe",
				"name": "PAGAR 8 CRÉDITOS",
				"effect_text": "O drone entrega os pontos fracos: -18% defesa do alvo.",
				"credit_cost": 8,
				"defense_mult": 0.82,
				"result": "D-7 aceitou a taxa administrativa e marcou a armadura defeituosa.",
			},
			{
				"id": "detour",
				"name": "PEGAR O DESVIO",
				"effect_text": "+2s de caça, mas o alvo perde 12% de vida.",
				"duration_add": 2.0,
				"health_mult": 0.88,
				"result": "O desvio terminou atrás do alvo. Pela primeira vez, uma placa ajudou.",
			},
			{
				"id": "ram",
				"name": "FURAR O BLOQUEIO",
				"effect_text": "+12% poder inimigo, mas +18% créditos.",
				"power_mult": 1.12,
				"credits_mult": 1.18,
				"result": "O drone enviou a placa da nave ao alvo e uma multa ao contratante.",
			},
		],
	},
	{
		"id": "bounty_streamer",
		"title": "Influencer de Caçada",
		"description": "Uma repórter transmite sua perseguição ao vivo para onze espectadores e um bot.",
		"color": "#d789ff",
		"choices": [
			{
				"id": "interview",
				"name": "DAR ENTREVISTA",
				"effect_text": "+22% XP, mas o alvo ganha 8% de poder.",
				"xp_mult": 1.22,
				"power_mult": 1.08,
				"result": "A entrevista viralizou entre os onze espectadores. O alvo também assistiu.",
			},
			{
				"id": "jam_signal",
				"name": "CORTAR O SINAL · 6 CR",
				"effect_text": "Emboscada preservada: -8% poder do alvo.",
				"credit_cost": 6,
				"power_mult": 0.92,
				"result": "A transmissão caiu no melhor momento. Sua emboscada não.",
			},
			{
				"id": "wave",
				"name": "MANDAR UM JOINHA",
				"effect_text": "+1s de caça e +8% créditos pela publicidade.",
				"duration_add": 1.0,
				"credits_mult": 1.08,
				"result": "O joinha virou patrocínio. Ninguém sabe por quê.",
			},
		],
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


static func random_hunt_event(rng: RandomNumberGenerator) -> Dictionary:
	return HUNT_EVENTS[rng.randi_range(0, HUNT_EVENTS.size() - 1)].duplicate(true)


static func apply_hunt_choice(bounty: Dictionary, choice: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	for stat in ["power", "defense", "health", "credits", "xp"]:
		var multiplier_key := "%s_mult" % stat
		if choice.has(multiplier_key):
			result[stat] = maxi(1 if stat != "defense" else 0, roundi(float(result[stat]) * float(choice[multiplier_key])))
	result["hunt_event_result"] = str(choice.get("result", "A perseguição ficou ligeiramente mais estranha."))
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
