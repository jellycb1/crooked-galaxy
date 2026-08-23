class_name ContentDB
extends RefCounted


const PLANET := {
	"id": "dustball_prime",
	"name": "Dustball Prime",
	"subtitle": "A poeira entra em tudo. Inclusive nos contratos.",
	"accent": "#ffc857",
	"completion_text": "O prefeito foi afastado do cargo, da delegacia e do próprio cartório. A papelada continua foragida.",
}

const PLANETS := [
	PLANET,
	{
		"id": "congelaria_sa",
		"name": "Congelária S.A.",
		"subtitle": "Tudo abaixo de zero. Inclusive o atendimento.",
		"description": "Um frigorífico planetário privatizado, com geleiras, cubículos e multas por aquecimento.",
		"accent": "#72f1dd",
		"unlock_after": "dustball_prime",
		"completion_text": "A diretoria foi descongelada de suas funções. O termostato agora aceita votos e moedas.",
	},
	{
		"id": "micelia_404",
		"name": "Micélia 404",
		"subtitle": "Tudo cresce. Principalmente as taxas.",
		"description": "Uma rede fúngica planetária onde prédios brotam, calçadas respiram e todo esporo tem cadastro.",
		"accent": "#c7f464",
		"unlock_after": "congelaria_sa",
		"completion_text": "A rede micelial trocou de administração. Os cogumelos exigem eleições úmidas.",
	},
]

const TARGETS := [
	{
		"id": "gloop",
		"planet_id": "dustball_prime",
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
		"chapter_tier": 0,
		"attacks": ["Tapa Tentacular", "Cuspe de Formulário", "Raio Mal Estacionado"],
	},
	{
		"id": "baron_boom",
		"planet_id": "dustball_prime",
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
		"chapter_tier": 1,
		"attacks": ["Decreto Explosivo", "Imposto de Impacto", "Brasão-Bomba"],
	},
	{
		"id": "madame_vacuum",
		"planet_id": "dustball_prime",
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
		"chapter_tier": 2,
		"attacks": ["Vácuo Executivo", "Taxa de Respiração", "Sucção Premium"],
	},
	{
		"id": "mayor_gold_dust",
		"planet_id": "dustball_prime",
		"name": "Prefeito Pó-de-Ouro",
		"title": "Prefeito, xerife e dono do cartório",
		"description": "Emitiu o próprio mandado, carimbou como inocente e cobrou a taxa de leitura.",
		"emoji": "⭐",
		"power": 28,
		"defense": 11,
		"health": 160,
		"duration": 12,
		"credits": 138,
		"xp": 132,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Veto de Plasma", "Carimbo de Emergência", "Imposto sobre Esquiva"],
	},
	{
		"id": "auditor_frost",
		"planet_id": "congelaria_sa",
		"name": "Auditor Geada",
		"title": "Fiscal de aquecedores clandestinos",
		"description": "Confiscou o último cobertor do hemisfério sul por excesso de conforto.",
		"emoji": "❄",
		"power": 28,
		"defense": 11,
		"health": 165,
		"duration": 13,
		"credits": 146,
		"xp": 140,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Auto de Infração Glacial", "Caneta Criogênica", "Juros Congelantes"],
	},
	{
		"id": "chef_coldflame",
		"planet_id": "congelaria_sa",
		"name": "Chef Brasa Fria",
		"title": "Contrabandista de sopa acima de zero",
		"description": "Serviu caldo morno sem licença térmica. Três executivos descongelaram sentimentos.",
		"emoji": "♨",
		"power": 32,
		"defense": 13,
		"health": 190,
		"duration": 15,
		"credits": 174,
		"xp": 166,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Concha de Lava", "Caldo Clandestino", "Pimenta de Reentrada"],
	},
	{
		"id": "executive_penguin",
		"planet_id": "congelaria_sa",
		"name": "Pinguim Executivo",
		"title": "Diretor de demissões em massa polar",
		"description": "Terceirizou o próprio bando e vendeu os peixes da confraternização.",
		"emoji": "▰",
		"power": 37,
		"defense": 15,
		"health": 220,
		"duration": 17,
		"credits": 208,
		"xp": 196,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Gravata Torpedo", "Reunião Sem Pauta", "Bicada de Desligamento"],
	},
	{
		"id": "director_kelvin",
		"planet_id": "congelaria_sa",
		"name": "Diretora Kelvin",
		"title": "CEO vitalícia do frio corporativo",
		"description": "Patenteou o zero absoluto e agora cobra royalties de todo termômetro.",
		"emoji": "◆",
		"power": 43,
		"defense": 18,
		"health": 260,
		"duration": 20,
		"credits": 268,
		"xp": 248,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Fusão Hostil", "Zero Absoluto Fiscal", "Sinergia Criogênica"],
	},
	{
		"id": "landlord_spore",
		"planet_id": "micelia_404",
		"name": "Síndico Esporão",
		"title": "Administrador do condomínio micelial",
		"description": "Cobrou aluguel de cada raiz e instalou catracas nas trilhas de formigas.",
		"emoji": "♣",
		"power": 44,
		"defense": 19,
		"health": 275,
		"duration": 22,
		"credits": 304,
		"xp": 282,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Boleto de Esporos", "Assembleia Venenosa", "Taxa de Umidade"],
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
		"planet_id": "dustball_prime",
		"symbol": "D-7",
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
		"planet_id": "dustball_prime",
		"symbol": "LIVE",
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
	{
		"id": "heat_inspector",
		"planet_id": "congelaria_sa",
		"symbol": "-40°",
		"title": "Fiscal de Calor",
		"description": "Um termômetro de terno detectou intenções acima da temperatura permitida.",
		"color": "#72f1dd",
		"choices": [
			{
				"id": "pay_cooling_fee", "name": "PAGAR 12 CRÉDITOS",
				"effect_text": "O fiscal congela juntas expostas: -20% defesa do alvo.",
				"credit_cost": 12, "defense_mult": 0.80,
				"result": "A taxa de resfriamento foi paga. Até os parafusos do alvo bateram os dentes.",
			},
			{
				"id": "fake_badge", "name": "FALSIFICAR UM CRACHÁ",
				"effect_text": "+2s de caça e +18% XP pela experiência corporativa.",
				"duration_add": 2.0, "xp_mult": 1.18,
				"result": "Seu novo cargo é Vice-Caçador Sênior. Ninguém pediu referências.",
			},
			{
				"id": "overclock_heater", "name": "LIGAR O AQUECEDOR",
				"effect_text": "+10% poder inimigo, mas +20% créditos por insalubridade.",
				"power_mult": 1.10, "credits_mult": 1.20,
				"result": "O aquecedor disparou alarmes, bônus de risco e uma torrada esquecida.",
			},
		],
	},
	{
		"id": "corporate_avalanche",
		"planet_id": "congelaria_sa",
		"symbol": "RACHOU",
		"title": "Avalanche Corporativa",
		"description": "A geleira foi reestruturada sem aviso prévio e metade da rota foi demitida.",
		"color": "#a97cff",
		"choices": [
			{
				"id": "melt_route", "name": "DERRETER A ROTA · 10 CR",
				"effect_text": "Atalho térmico: o alvo perde 15% de vida.",
				"credit_cost": 10, "health_mult": 0.85,
				"result": "A rota derreteu. O departamento jurídico também, mas só um pouco.",
			},
			{
				"id": "climb_shelf", "name": "ESCALAR A GELEIRA",
				"effect_text": "+3s de caça e +20% XP por treinamento não solicitado.",
				"duration_add": 3.0, "xp_mult": 1.20,
				"result": "Você escalou a nova hierarquia glacial sem uma única reunião.",
			},
			{
				"id": "surf_collapse", "name": "SURFAR O COLAPSO",
				"effect_text": "+12% poder inimigo, mas +22% créditos pelo espetáculo.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "A manobra recebeu nota dez e uma advertência de segurança.",
			},
		],
	},
	{
		"id": "spore_customs",
		"planet_id": "micelia_404",
		"symbol": "ACHOO",
		"title": "Alfândega de Esporos",
		"description": "Uma nuvem carimba cada molécula que entra. Seu pulmão está com documentação vencida.",
		"color": "#c7f464",
		"choices": [
			{
				"id": "buy_mask", "name": "COMPRAR MÁSCARA · 14 CR",
				"effect_text": "Filtros revelam o alvo entre a névoa: -20% defesa.",
				"credit_cost": 14, "defense_mult": 0.80,
				"result": "A máscara filtra esporos, desculpas e noventa por cento dos anúncios.",
			},
			{
				"id": "declare_lungs", "name": "DECLARAR OS PULMÕES",
				"effect_text": "+3s de caça e +20% XP por preencher anatomia em triplicado.",
				"duration_add": 3.0, "xp_mult": 1.20,
				"result": "Seus pulmões agora constam como bagagem de mão regulamentar.",
			},
			{
				"id": "sneeze_through", "name": "ESPIRRAR E ACELERAR",
				"effect_text": "+12% poder inimigo, mas +22% créditos por contaminação.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "O espirro abriu um túnel e fechou três restaurantes orgânicos.",
			},
		],
	},
	{
		"id": "sentient_shortcut",
		"planet_id": "micelia_404",
		"symbol": "OI?",
		"title": "Atalho Senciente",
		"description": "A trilha acordou, pediu seu nome e quer comissão sobre a recompensa.",
		"color": "#ff75c8",
		"choices": [
			{
				"id": "pay_path", "name": "PAGAR 16 CRÉDITOS",
				"effect_text": "A trilha entrega o alvo: -16% vida inimiga.",
				"credit_cost": 16, "health_mult": 0.84,
				"result": "O atalho aceitou pagamento, gorjeta e uma avaliação de cinco estrelas.",
			},
			{
				"id": "tell_story", "name": "CONTAR UMA HISTÓRIA",
				"effect_text": "+2s de caça e +18% XP pela terapia vegetal.",
				"duration_add": 2.0, "xp_mult": 1.18,
				"result": "A trilha chorou seiva e indicou uma rota emocionalmente mais curta.",
			},
			{
				"id": "step_on_it", "name": "PISAR FUNDO",
				"effect_text": "+10% poder inimigo, mas +20% créditos por danos botânicos.",
				"power_mult": 1.10, "credits_mult": 1.20,
				"result": "A trilha abriu um processo. O contratante cobriu os honorários.",
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

const PLANET_ITEM_CATALOGS := {
	"congelaria_sa": {
		"weapon": [
			{"name": "Lança-Chamas de Escritório", "description": "Aquece café, contratos e negociações hostis."},
			{"name": "Carabina Criogênica Reversa", "description": "Congela a culpa e descongela o gatilho."},
			{"name": "Grampeador Térmico", "description": "Prende folhas a três metros e criminosos a dois."},
			{"name": "Canhão de Sopa Pressurizada", "description": "O caldo é ilegal. Os croutons são perfurantes."},
		],
		"armor": [
			{"name": "Parka de Reunião Infinita", "description": "Mantém o corpo aquecido enquanto a pauta congela a alma."},
			{"name": "Colete Antitermostato", "description": "Certificado para sobreviver a três auditorias e meia."},
			{"name": "Terno de Fibra Glacial", "description": "Elegante, blindado e impossível de passar a ferro."},
			{"name": "Manta Executiva de Emergência", "description": "Dourada por fora, formulário de despesas por dentro."},
		],
	},
	"micelia_404": {
		"weapon": [
			{"name": "Escopeta de Pólen Comprimido", "description": "Dispersa alergias, suspeitos e evidências."},
			{"name": "Lâmina de Micélio Nervoso", "description": "Treme perto do perigo e de saladas."},
			{"name": "Pistola Fotossintética", "description": "Recarrega ao sol e reclama em ambientes fechados."},
			{"name": "Canhão de Compostagem Rápida", "description": "Transforma cobertura em adubo antes do impacto."},
		],
		"armor": [
			{"name": "Casaco Antimofo Ofensivo", "description": "O mofo não entra. Ele manda representantes."},
			{"name": "Colete de Casca Reforçada", "description": "Orgânico, balístico e ligeiramente crocante."},
			{"name": "Poncho de Folha Carnívora", "description": "Protege o dono e belisca estranhos sem autorização."},
			{"name": "Armadura de Cortiça Orbital", "description": "Leve, renovável e péssima perto de saca-rolhas."},
		],
	},
}


static func get_planet(planet_id: String) -> Dictionary:
	for planet in PLANETS:
		if str(planet.id) == planet_id:
			return planet.duplicate(true)
	return PLANET.duplicate(true)


static func is_planet_unlocked(planet_id: String, completed_planets: Array) -> bool:
	var planet := get_planet(planet_id)
	var requirement := str(planet.get("unlock_after", ""))
	return requirement.is_empty() or completed_planets.has(requirement)


static func available_bounties(reputation: int, planet_id := "dustball_prime", chapter_tier := -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unlocked_tier: int = reputation if chapter_tier < 0 else chapter_tier
	for target in TARGETS:
		if str(target.get("planet_id", "dustball_prime")) == planet_id and int(target.rank) <= reputation and int(target.get("chapter_tier", target.rank)) <= unlocked_tier:
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


static func random_hunt_event(rng: RandomNumberGenerator, planet_id := "dustball_prime") -> Dictionary:
	var candidates: Array[Dictionary] = []
	for event in HUNT_EVENTS:
		if str(event.get("planet_id", "dustball_prime")) == planet_id:
			candidates.append(event)
	if candidates.is_empty():
		candidates.append(HUNT_EVENTS[0])
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)


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
	var planet_id := str(target.get("planet_id", "dustball_prime"))
	var item_family: Dictionary = PLANET_ITEM_CATALOGS.get(planet_id, ITEM_CATALOG)
	var catalog: Array = item_family[slot]
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
