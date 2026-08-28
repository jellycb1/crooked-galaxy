class_name MosteiroGravidadeReversaContent
extends RefCounted

const PLANET := {
	"id": "mosteiro_gravidade_reversa",
	"name": "Mosteiro da Gravidade Reversa",
	"unlock_level": 140,
	"travel_duration": 4080.0,
	"subtitle": "Para alcançar a iluminação, caia para cima.",
	"description": "Um asteroide oco onde claustros pendem do teto, sinos sobem quando tocados e monges contabilizam cada grama de culpa antes de autorizar uma peregrinação.",
	"accent": "#b899ff",
	"unlock_after": "tribunal_clones_nao_autorizados",
	"completion_text": "O Oráculo do Peso Negativo perdeu o trono suspenso. O mosteiro voltou a cair na direção errada, que por tradição local é considerada a certa.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_CEILING_NOVICE := {
	"id": "ceiling_novice", "planet_id": "mosteiro_gravidade_reversa", "name": "Noviço do Teto",
	"title": "Ainda confunde ascensão com queda", "description": "Corre pelos arcos invertidos, solta móveis sobre peregrinos e culpa a orientação espiritual por cada colisão.", "emoji": "↑",
	"power": 946, "loot_power": 891, "defense": 428, "health": 12520, "duration": 468, "credits": 128100, "xp": 86950, "rank": 3, "chapter_tier": 0,
	"attacks": ["Queda Ascendente", "Banco do Claustro", "Tropeção Zenital"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_LOWER_ABBOT := {
	"id": "lower_abbot", "planet_id": "mosteiro_gravidade_reversa", "name": "Abade de Baixo",
	"title": "Governa o ponto mais alto visto ao contrário", "description": "Emite decretos de cabeça para baixo, excomunga objetos pesados e cobra dízimo por cada aterragem autorizada.", "emoji": "⇵",
	"power": 973, "loot_power": 916, "defense": 440, "health": 12920, "duration": 482, "credits": 140950, "xp": 95700, "rank": 3, "chapter_tier": 1,
	"attacks": ["Decreto Invertido", "Dízimo de Aterragem", "Excomunhão Gravitacional"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ANTIGRAVITY_PILGRIM := {
	"id": "antigravity_pilgrim", "planet_id": "mosteiro_gravidade_reversa", "name": "Peregrina Antigravitacional",
	"title": "Deu a volta ao mundo sem tocar no chão", "description": "Transporta relíquias flutuantes, abre atalhos pelo vazio central e transforma qualquer perseguição numa procissão orbital.", "emoji": "↻",
	"power": 1000, "loot_power": 941, "defense": 453, "health": 13330, "duration": 497, "credits": 155050, "xp": 105300, "rank": 3, "chapter_tier": 2,
	"attacks": ["Procissão Orbital", "Relíquia Flutuante", "Atalho pelo Vazio"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_NEGATIVE_WEIGHT_ORACLE := {
	"id": "negative_weight_oracle", "planet_id": "mosteiro_gravidade_reversa", "name": "Oráculo do Peso Negativo",
	"title": "Prevê quanto deixará de pesar", "description": "Ocupa um trono preso por correntes ao céu interior, vende absolvições de massa e remove o peso de qualquer argumento inconveniente.", "emoji": "−g",
	"power": 1058, "loot_power": 996, "defense": 480, "health": 14620, "duration": 516, "credits": 171500, "xp": 116450, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Profecia Sem Peso", "Absolvição de Massa", "Trono de Gravidade Negativa"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_CEILING_NOVICE, TARGET_LOWER_ABBOT, TARGET_ANTIGRAVITY_PILGRIM, TARGET_NEGATIVE_WEIGHT_ORACLE]

const EVENT_ASCENDING_BELL_PROCESSION := {
	"id": "ascending_bell_procession", "planet_id": "mosteiro_gravidade_reversa", "symbol": "SINO ↑", "title": "Procissão dos Sinos Ascendentes",
	"description": "Uma centena de sinos soltos sobe pelo corredor central, arrastando monges e cabos de cerimónia na direção do teto.", "color": "#b899ff",
	"choices": [
		{"id": "buy_blessed_anchor", "name": "COMPRAR ÂNCORA ABENÇOADA · 71 CR", "effect_text": "A âncora abre a passagem inferior: -22% defesa inimiga.", "credit_cost": 71, "defense_mult": 0.78, "result": "A bênção expirava ao tocar no chão, que felizmente não estava disponível."},
		{"id": "ring_every_bell", "name": "TOCAR TODOS OS SINOS", "effect_text": "+105s de caça e +22% XP em acústica ascendente.", "duration_add": 105.0, "xp_mult": 1.22, "result": "A última badalada chegou primeiro e apresentou uma reclamação sobre a ordem."},
		{"id": "cut_procession_cables", "name": "CORTAR OS CABOS DA PROCISSÃO", "effect_text": "+13% poder inimigo, mas +25% créditos em metal litúrgico.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os sinos ficaram livres. A procissão passou a incluir todos os que estavam por baixo."},
	],
}

const EVENT_WEIGHT_CONFESSION := {
	"id": "weight_confession", "planet_id": "mosteiro_gravidade_reversa", "symbol": "CULPA: −KG", "title": "Confissão de Peso",
	"description": "Uma balança espiritual bloqueia a nave e exige que a tripulação declare toda a massa adquirida desde o último pecado orbital.", "color": "#69d8ff",
	"choices": [
		{"id": "buy_mass_absolution", "name": "COMPRAR ABSOLVIÇÃO DE MASSA · 72 CR", "effect_text": "A absolvição enfraquece a sentença: -15% poder inimigo.", "credit_cost": 72, "power_mult": 0.85, "result": "A culpa foi removida. A taxa administrativa continuou surpreendentemente pesada."},
		{"id": "audit_spiritual_ballast", "name": "AUDITAR O LASTRO ESPIRITUAL", "effect_text": "+95s de caça e +20% XP em contabilidade metafísica.", "duration_add": 95.0, "xp_mult": 1.20, "result": "O relatório concluiu que metade do peso pertencia a pecados de outra nave."},
		{"id": "steal_counterweight_relics", "name": "ROUBAR RELÍQUIAS DE CONTRAPESO", "effect_text": "+12% vida inimiga, mas +23% créditos em antiguidades suspensas.", "health_mult": 1.12, "credits_mult": 1.23, "result": "As relíquias saíram sem peso. Os guardiões compensaram trazendo o dobro da raiva."},
	],
}

const EVENTS := [EVENT_ASCENDING_BELL_PROCESSION, EVENT_WEIGHT_CONFESSION]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Queda Ascendente", "description": "Dispara para baixo e acerta no teto antes de aceitar a contradição."},
		{"name": "Rifle de Decreto Invertido", "description": "Publica cada projétil de cabeça para baixo e com efeito imediato."},
		{"name": "Lança-Relíquias Orbitais", "description": "Mantém munições em peregrinação até encontrarem um alvo."},
		{"name": "Emissor de Peso Negativo", "description": "Remove massa do impacto até o inimigo cair na direção errada."},
	],
	"armor": [
		{"name": "Hábito do Noviço do Teto", "description": "Tem bolsos em ambas as orientações e joelheiras onde ninguém esperava."},
		{"name": "Manto do Abade de Baixo", "description": "Permanece solene mesmo quando o utilizador está preso ao teto."},
		{"name": "Traje de Peregrinação Orbital", "description": "Transforma cada impacto numa etapa oficialmente reconhecida da viagem."},
		{"name": "Armadura do Oráculo Sem Peso", "description": "Protege com placas que recusam participar na gravidade local."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Implante de Orientação Zenital", "description": "Decide qual teto será tratado como chão durante emergências."},
		{"name": "Nódulo de Dízimo Gravitacional", "description": "Reserva uma fração de cada movimento para a administração do mosteiro."},
		{"name": "Arquivo de Peregrinação Orbital", "description": "Recorda atalhos que apenas existem enquanto ninguém olha para baixo."},
		{"name": "Sinapse de Peso Negativo", "description": "Alivia pensamentos pesados e projéteis ainda mais pesados."},
	],
}

const PACK := {
	"id": "mosteiro_gravidade_reversa",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
