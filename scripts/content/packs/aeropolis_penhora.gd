class_name AeropolisPenhoraContent
extends RefCounted

const PLANET := {
	"id": "aeropolis_penhora",
	"name": "Aerópolis de Penhora",
	"unlock_level": 30,
	"travel_duration": 1440.0,
	"subtitle": "O céu é o limite. A dívida também.",
	"description": "Cidades-balão navegam um gigante gasoso onde bancos privatizaram o vento, tempestades trabalham por turno e até respirar exige fiador.",
	"accent": "#8fd3ff",
	"unlock_after": "cassino_quasar",
	"completion_text": "O Banco da Tempestade entrou em liquidação. Choveu moedas por onze minutos e formulários por três dias.",
}

const TARGET_COURIER_CUMULUS := {
	"id": "courier_cumulus", "planet_id": "aeropolis_penhora", "name": "Carteiro Cumulus",
	"title": "Contrabandista de encomendas atmosféricas", "description": "Entrega cobranças antes do vencimento e destinatários depois da tempestade.", "emoji": "☁",
	"power": 136, "loot_power": 128, "defense": 61, "health": 980, "duration": 55, "credits": 1390, "xp": 1160, "rank": 3, "chapter_tier": 0,
	"attacks": ["Entrega Expressa", "Selo de Turbulência", "Aviso de Receção"],
}

const TARGET_DUCHESS_LOW_PRESSURE := {
	"id": "duchess_low_pressure", "planet_id": "aeropolis_penhora", "name": "Duquesa Baixa Pressão",
	"title": "Pirata aristocrática dos corredores de vento", "description": "Cobra pedágio de toda brisa e chama furacões de transporte executivo.", "emoji": "♨",
	"power": 148, "loot_power": 139, "defense": 66, "health": 1080, "duration": 59, "credits": 1550, "xp": 1270, "rank": 3, "chapter_tier": 1,
	"attacks": ["Rajada Aristocrática", "Monção de Etiqueta", "Pedágio Barométrico"],
}

const TARGET_ENGINEER_THUNDER := {
	"id": "engineer_thunder", "planet_id": "aeropolis_penhora", "name": "Engenheiro Trovão",
	"title": "Locador de tempestades industriais", "description": "Aluga relâmpagos por minuto e desliga o para-raios de quem atrasa uma prestação.", "emoji": "ϟ",
	"power": 160, "loot_power": 151, "defense": 72, "health": 1190, "duration": 63, "credits": 1740, "xp": 1400, "rank": 3, "chapter_tier": 2,
	"attacks": ["Fatura Voltaica", "Curto de Cobrança", "Sobretensão Contratual"],
}

const TARGET_STORM_BANK := {
	"id": "storm_bank", "planet_id": "aeropolis_penhora", "name": "Banco da Tempestade",
	"title": "Instituição atmosférica senciente", "description": "Hipotecou o horizonte, penhorou o clima e capitaliza juros sempre que alguém suspira.", "emoji": "☇",
	"power": 175, "loot_power": 165, "defense": 79, "health": 1330, "duration": 68, "credits": 2040, "xp": 1580, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Juros Cumulonimbus", "Execução Atmosférica", "Falência do Horizonte"],
}

const TARGETS := [TARGET_COURIER_CUMULUS, TARGET_DUCHESS_LOW_PRESSURE, TARGET_ENGINEER_THUNDER, TARGET_STORM_BANK]

const EVENT_PRESSURE_TOLL := {
	"id": "pressure_toll", "planet_id": "aeropolis_penhora", "symbol": "980hPa", "title": "Pedágio de Pressão",
	"description": "Uma cabine flutuante cobra pela diferença de pressão entre a sua nave e o céu público.", "color": "#8fd3ff",
	"choices": [
		{"id": "pay_pressure", "name": "PAGAR 26 CRÉDITOS", "effect_text": "A cabine despressuriza a cobertura: -20% defesa do alvo.", "credit_cost": 26, "defense_mult": 0.80, "result": "O recibo veio selado a vácuo. A armadura do alvo também."},
		{"id": "ride_updraft", "name": "APANHAR A CORRENTE", "effect_text": "+60s de caça e +20% XP em navegação barométrica.", "duration_add": 60.0, "xp_mult": 1.20, "result": "A corrente subiu, virou à esquerda e pediu uma avaliação de cinco estrelas."},
		{"id": "burst_gate", "name": "ROMPER A COMPORTA", "effect_text": "+12% poder inimigo, mas +22% créditos por risco atmosférico.", "power_mult": 1.12, "credits_mult": 1.22, "result": "A comporta abriu. O processo administrativo chegou pelo vento."},
	],
}

const EVENT_LIGHTNING_STRIKE := {
	"id": "lightning_strike", "planet_id": "aeropolis_penhora", "symbol": "SEM RAIO", "title": "Greve de Para-Raios",
	"description": "Os para-raios cruzaram os braços. As nuvens exigem negociação coletiva imediata.", "color": "#ffe66d",
	"choices": [
		{"id": "hire_cloud", "name": "CONTRATAR UMA NUVEM · 28 CR", "effect_text": "A nuvem denuncia o esconderijo: -14% poder do alvo.", "credit_cost": 28, "power_mult": 0.86, "result": "A nuvem assinou por descarga e apontou o alvo com um relâmpago discreto."},
		{"id": "negotiate_rods", "name": "NEGOCIAR COM OS PARA-RAIOS", "effect_text": "+45s de caça e +18% XP em relações atmosféricas.", "duration_add": 45.0, "xp_mult": 1.18, "result": "O acordo inclui pausas, seguro e uma tempestade pessoal por trimestre."},
		{"id": "cross_storm", "name": "ATRAVESSAR A TEMPESTADE", "effect_text": "+10% vida inimiga, mas +20% créditos de periculosidade.", "health_mult": 1.10, "credits_mult": 1.20, "result": "A nave saiu fumegando. O contratante classificou o fumo como experiência premium."},
	],
}

const EVENTS := [EVENT_PRESSURE_TOLL, EVENT_LIGHTNING_STRIKE]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Ar Comprimido Premium", "description": "Dispara atmosfera engarrafada e cobra pela tampa."},
		{"name": "Lança-Raios de Prestação", "description": "Cada descarga vence no fim do mês e no início do alvo."},
		{"name": "Mosquete Barométrico", "description": "Prevê chuva, vento e a direção provável da fuga."},
		{"name": "Canhão Cumulonimbus Portátil", "description": "Cabe na mão, mas exige espaço aéreo próprio."},
	],
	"armor": [
		{"name": "Casaco de Pressão Variável", "description": "Aperta em combate e nas cláusulas de cancelamento."},
		{"name": "Colete de Balão Blindado", "description": "Leve, resistente e proibido perto de alfinetes jurídicos."},
		{"name": "Manto de Corrente Ascendente", "description": "Mantém os ombros erguidos e as balas em trânsito."},
		{"name": "Armadura de Cabine Pressurizada", "description": "Inclui oxigénio, apoio lombar e uma pequena taxa por impacto."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Arnês de Ancoragem Cumulus", "description": "Prende o caçador ao chão quando o chão está de serviço."},
		{"name": "Mochila de Lastro Executivo", "description": "Cheia de chumbo, recibos e decisões com peso legal."},
		{"name": "Colete de Para-Raios Sindicalizado", "description": "Desvia descargas apenas dentro do horário contratual."},
		{"name": "Suspensório Barométrico", "description": "Ajusta postura, pressão e expectativas meteorológicas."},
	],
}

const PACK := {
	"id": "aeropolis_penhora",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
