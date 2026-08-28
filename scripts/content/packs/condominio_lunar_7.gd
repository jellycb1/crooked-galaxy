class_name CondominioLunar7Content
extends RefCounted

const PLANET := {
	"id": "condominio_lunar_7",
	"name": "Condomínio Lunar 7",
	"unlock_level": 70,
	"travel_duration": 2400.0,
	"subtitle": "O espaço é infinito. A vaga de estacionamento não.",
	"description": "Uma lua residencial de cúpulas impecáveis onde crateras têm escritura, jardins de poeira obedecem ao regulamento e o eclipse precisa de autorização do condomínio.",
	"accent": "#c9c3ff",
	"unlock_after": "caldeira_garantia",
	"completion_text": "O Síndico do Eclipse perdeu o voto de qualidade. Pela primeira vez, a lua girou sem ata, multa ou autorização prévia.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_LAWN_INSPECTOR := {
	"id": "lunar_lawn_inspector", "planet_id": "condominio_lunar_7", "name": "Fiscal de Gramados Lunares",
	"title": "Medidor oficial de relva no vácuo", "description": "Multa jardins de poeira demasiado altos e confisca qualquer erva que cresça sem atmosfera licenciada.", "emoji": "⌑",
	"power": 336, "loot_power": 317, "defense": 150, "health": 2920, "duration": 148, "credits": 8170, "xp": 5540, "rank": 3, "chapter_tier": 0,
	"attacks": ["Régua Orbital", "Auto de Jardinagem", "Poda Despressurizada"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_DARKSIDE_NEIGHBOR := {
	"id": "darkside_neighbor", "planet_id": "condominio_lunar_7", "name": "Vizinho do Lado Escuro",
	"title": "Colecionador de ruído interplanetário", "description": "Liga o aspirador gravitacional de madrugada e responde a toda reclamação com mais uma antena clandestina.", "emoji": "◐",
	"power": 347, "loot_power": 327, "defense": 155, "health": 3040, "duration": 155, "credits": 8970, "xp": 6130, "rank": 3, "chapter_tier": 1,
	"attacks": ["Aspirador Gravitacional", "Antena Clandestina", "Festa Sem Atmosfera"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_CRATER_BROKER := {
	"id": "crater_broker", "planet_id": "condominio_lunar_7", "name": "Corretora de Crateras",
	"title": "Especialista em imóveis de impacto", "description": "Vende buracos com vista para a Terra, cobra entrada de meteoros e chama radiação de luz natural premium.", "emoji": "◉",
	"power": 358, "loot_power": 337, "defense": 160, "health": 3170, "duration": 163, "credits": 9860, "xp": 6790, "rank": 3, "chapter_tier": 2,
	"attacks": ["Escritura de Impacto", "Entrada Meteórica", "Comissão Balística"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ECLIPSE_MANAGER := {
	"id": "eclipse_manager", "planet_id": "condominio_lunar_7", "name": "Síndico do Eclipse",
	"title": "Presidente vitalício da órbita residencial", "description": "Controla sombras, marés e assembleias com uma procuração assinada pelo lado oculto da lua.", "emoji": "●",
	"power": 380, "loot_power": 358, "defense": 170, "health": 3510, "duration": 172, "credits": 11020, "xp": 7570, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Taxa de Eclipse", "Maré Condominial", "Voto do Lado Oculto"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_LAWN_INSPECTOR, TARGET_DARKSIDE_NEIGHBOR, TARGET_CRATER_BROKER, TARGET_ECLIPSE_MANAGER]

const EVENT_ORBITAL_ASSEMBLY := {
	"id": "orbital_assembly", "planet_id": "condominio_lunar_7", "symbol": "QUÓRUM 51%", "title": "Assembleia de Órbita",
	"description": "Uma fila de satélites bloqueia a rota enquanto discute se a lua pode continuar a girar depois das vinte e duas horas.", "color": "#c9c3ff",
	"choices": [
		{"id": "buy_proxy_vote", "name": "COMPRAR PROCURAÇÃO · 43 CR", "effect_text": "O voto abre a cúpula de segurança: -22% defesa inimiga.", "credit_cost": 43, "defense_mult": 0.78, "result": "A procuração representou você, a nave e dois asteroides indecisos."},
		{"id": "read_orbital_minutes", "name": "LER A ATA ORBITAL", "effect_text": "+70s de caça e +22% XP em legislação rotacional.", "duration_add": 70.0, "xp_mult": 1.22, "result": "A ata tinha mil órbitas de anexos e nenhuma decisão com gravidade."},
		{"id": "break_quorum", "name": "QUEBRAR O QUÓRUM", "effect_text": "+13% poder inimigo, mas +25% créditos por sessão extraordinária.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A assembleia terminou. As multas continuaram por movimento próprio."},
	],
}

const EVENT_VACUUM_NOISE_PATROL := {
	"id": "vacuum_noise_patrol", "planet_id": "condominio_lunar_7", "symbol": "0 dB", "title": "Fiscalização de Ruído no Vácuo",
	"description": "Uma patrulha acústica mede reclamações que ninguém consegue ouvir e reboca naves com escape visualmente barulhento.", "color": "#82f6e8",
	"choices": [
		{"id": "rent_silence_permit", "name": "ALUGAR LICENÇA DE SILÊNCIO · 44 CR", "effect_text": "A licença desliga os amplificadores do alvo: -15% poder inimigo.", "credit_cost": 44, "power_mult": 0.85, "result": "O silêncio foi aprovado, plastificado e cobrado por decibel inexistente."},
		{"id": "contest_noise_fine", "name": "CONTESTAR A MULTA", "effect_text": "+60s de caça e +20% XP em acústica administrativa.", "duration_add": 60.0, "xp_mult": 1.20, "result": "A contestação provou que o vácuo estava inocente. A nave recebeu advertência."},
		{"id": "boost_visual_exhaust", "name": "ACELERAR O ESCAPE VISUAL", "effect_text": "+12% vida inimiga, mas +23% créditos de perturbação orbital.", "health_mult": 1.12, "credits_mult": 1.23, "result": "Ninguém ouviu a fuga, mas três crateras apresentaram queixa por escrito."},
	],
}

const EVENTS := [EVENT_ORBITAL_ASSEMBLY, EVENT_VACUUM_NOISE_PATROL]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Regulamento Orbital", "description": "Dispara artigos, alíneas e projéteis com igual força executiva."},
		{"name": "Lança-Meteoros de Condomínio", "description": "Cada impacto inclui aviso prévio e uma taxa de limpeza da cratera."},
		{"name": "Aspirador Gravitacional Tático", "description": "Remove poeira, cobertura e objetos sem lugar de estacionamento."},
		{"name": "Canhão de Maré Privativa", "description": "Puxa oceanos, inimigos e mensalidades em atraso para a mesma direção."},
	],
	"armor": [
		{"name": "Casaco de Poeira Regulamentar", "description": "A tonalidade foi aprovada por unanimidade depois de nove assembleias."},
		{"name": "Traje de Cúpula Portátil", "description": "Cria atmosfera própria e cobra condomínio aos órgãos internos."},
		{"name": "Colete de Escritura Lunar", "description": "Declara propriedade sobre toda bala que tente ocupar o mesmo espaço."},
		{"name": "Armadura do Conselho Orbital", "description": "Inclui blindagem, procuração e direito a uma vaga perto da eclusa."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Viseira Condominial", "description": "Escurece automaticamente quando um vizinho tenta iniciar conversa."},
		{"name": "Elmo de Cratera Panorâmica", "description": "Oferece vista privilegiada para impactos futuros e despesas presentes."},
		{"name": "Capacete Antirruído de Vácuo", "description": "Bloqueia sons inexistentes com eficiência certificada por ninguém."},
		{"name": "Cúpula do Eclipse Executivo", "description": "Mantém a cabeça na sombra mesmo durante reuniões excessivamente luminosas."},
	],
}

const PACK := {
	"id": "condominio_lunar_7",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
