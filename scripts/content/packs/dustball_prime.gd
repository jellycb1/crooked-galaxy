class_name DustballPrimeContent
extends RefCounted

const PLANET := {
	"id": "dustball_prime",
	"name": "Dustball Prime",
	"unlock_level": 1,
	"travel_duration": 300.0,
	"subtitle": "A poeira entra em tudo. Inclusive nos contratos.",
	"description": "Um deserto de cartórios tortos, saloons orbitais e poeira suficientemente fina para entrar em qualquer cláusula.",
	"accent": "#ffc857",
	"completion_text": "O prefeito foi afastado do cargo, da delegacia e do próprio cartório. A papelada continua foragida.",
}

const TARGET_GLOOP := {
	"id": "gloop", "planet_id": "dustball_prime", "name": "Gloop, o Inconveniente",
	"title": "Ladrão de estacionamento orbital", "description": "Roubou 43 naves. Nenhuma era a nave certa.", "emoji": "👽",
	"power": 11, "defense": 4, "health": 70, "duration": 5, "credits": 38, "xp": 42, "rank": 0, "chapter_tier": 0,
	"attacks": ["Tapa Tentacular", "Cuspe de Formulário", "Raio Mal Estacionado"],
}

const TARGET_BARON_BOOM := {
	"id": "baron_boom", "planet_id": "dustball_prime", "name": "Barão Boom",
	"title": "Nobreza autoproclamada e explosiva", "description": "Assina todos os documentos com dinamite. Até recibos.", "emoji": "💥",
	"power": 16, "defense": 6, "health": 96, "duration": 7, "credits": 58, "xp": 62, "rank": 1, "chapter_tier": 1,
	"attacks": ["Decreto Explosivo", "Imposto de Impacto", "Brasão-Bomba"],
}

const TARGET_MADAME_VACUUM := {
	"id": "madame_vacuum", "planet_id": "dustball_prime", "name": "Madame Vácuo",
	"title": "Contrabandista de oxigênio premium", "description": "Vende ar engarrafado e cobra pela tampa separadamente.", "emoji": "🪐",
	"power": 23, "defense": 9, "health": 128, "duration": 9, "credits": 88, "xp": 90, "rank": 2, "chapter_tier": 2,
	"attacks": ["Vácuo Executivo", "Taxa de Respiração", "Sucção Premium"],
}

const TARGET_MAYOR_GOLD_DUST := {
	"id": "mayor_gold_dust", "planet_id": "dustball_prime", "name": "Prefeito Pó-de-Ouro",
	"title": "Prefeito, xerife e dono do cartório", "description": "Emitiu o próprio mandado, carimbou como inocente e cobrou a taxa de leitura.", "emoji": "⭐",
	"power": 28, "defense": 11, "health": 160, "duration": 12, "credits": 138, "xp": 132, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Veto de Plasma", "Carimbo de Emergência", "Imposto sobre Esquiva"],
}

const TARGETS := [TARGET_GLOOP, TARGET_BARON_BOOM, TARGET_MADAME_VACUUM, TARGET_MAYOR_GOLD_DUST]

const EVENT_TOLL_DRONE := {
	"id": "toll_drone", "planet_id": "dustball_prime", "symbol": "D-7", "title": "Pedágio de Drone D-7",
	"description": "Um drone municipal bloqueia a rota. O adesivo diz: “totalmente oficial”.", "color": "#55e5ff",
	"choices": [
		{"id": "bribe", "name": "PAGAR 8 CRÉDITOS", "effect_text": "O drone entrega os pontos fracos: -18% defesa do alvo.", "credit_cost": 8, "defense_mult": 0.82, "result": "D-7 aceitou a taxa administrativa e marcou a armadura defeituosa."},
		{"id": "detour", "name": "PEGAR O DESVIO", "effect_text": "+45s de caça, mas o alvo perde 12% de vida.", "duration_add": 45.0, "health_mult": 0.88, "result": "O desvio terminou atrás do alvo. Pela primeira vez, uma placa ajudou."},
		{"id": "ram", "name": "FURAR O BLOQUEIO", "effect_text": "+12% poder inimigo, mas +18% créditos.", "power_mult": 1.12, "credits_mult": 1.18, "result": "O drone enviou a placa da nave ao alvo e uma multa ao contratante."},
	],
}

const EVENT_BOUNTY_STREAMER := {
	"id": "bounty_streamer", "planet_id": "dustball_prime", "symbol": "LIVE", "title": "Influencer de Caçada",
	"description": "Uma repórter transmite sua perseguição ao vivo para onze espectadores e um bot.", "color": "#d789ff",
	"choices": [
		{"id": "interview", "name": "DAR ENTREVISTA", "effect_text": "+22% XP, mas o alvo ganha 8% de poder.", "xp_mult": 1.22, "power_mult": 1.08, "result": "A entrevista viralizou entre os onze espectadores. O alvo também assistiu."},
		{"id": "jam_signal", "name": "CORTAR O SINAL · 6 CR", "effect_text": "Emboscada preservada: -8% poder do alvo.", "credit_cost": 6, "power_mult": 0.92, "result": "A transmissão caiu no melhor momento. Sua emboscada não."},
		{"id": "wave", "name": "MANDAR UM JOINHA", "effect_text": "+30s de caça e +8% créditos pela publicidade.", "duration_add": 30.0, "credits_mult": 1.08, "result": "O joinha virou patrocínio. Ninguém sabe por quê."},
	],
}

const EVENTS := [EVENT_TOLL_DRONE, EVENT_BOUNTY_STREAMER]

const ITEMS := {
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

const PACK := {
	"id": "dustball_prime",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": {},
}
