class_name MercadoMemoriasUsadasContent
extends RefCounted

const PLANET := {
	"id": "mercado_memorias_usadas",
	"name": "Mercado de Memórias Usadas",
	"unlock_level": 150,
	"travel_duration": 4320.0,
	"subtitle": "Recordações autênticas. Proprietários opcionais.",
	"description": "Uma megacidade-bazar onde memórias são engarrafadas, infâncias recebem descontos de fim de estação e turistas alugam personalidades para parecer interessantes ao jantar.",
	"accent": "#ff70c8",
	"unlock_after": "mosteiro_gravidade_reversa",
	"completion_text": "A Curadora das Vidas Nunca Vividas perdeu o arquivo central. Milhões de cidadãos recuperaram recordações, embora muitos tenham regressado com aniversários alheios.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_MEMORY_APPRAISER_DRONE := {
	"id": "memory_appraiser_drone", "planet_id": "mercado_memorias_usadas", "name": "Drone Avaliador de Memórias",
	"title": "Baixa o preço de qualquer infância feliz", "description": "Digitaliza recordações sem consentimento, encontra defeitos emocionais microscópicos e oferece crédito de loja por traumas em bom estado.", "emoji": "◫",
	"power": 1081, "loot_power": 1018, "defense": 491, "health": 15020, "duration": 530, "credits": 189200, "xp": 128450, "rank": 3, "chapter_tier": 0,
	"attacks": ["Avaliação Emocional", "Desconto Nostálgico", "Scanner de Infância"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_CHILDHOOD_BROKER := {
	"id": "childhood_broker", "planet_id": "mercado_memorias_usadas", "name": "Corretor de Infâncias",
	"title": "Vende verões que nunca aconteceram", "description": "Leiloa primeiras palavras, combina férias incompatíveis e cobra comissão por cada amigo imaginário transferido.", "emoji": "☀",
	"power": 1110, "loot_power": 1045, "defense": 504, "health": 15450, "duration": 545, "credits": 208100, "xp": 141300, "rank": 3, "chapter_tier": 1,
	"attacks": ["Verão Falsificado", "Amigo Imaginário Hostil", "Comissão Retroativa"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_IDENTITY_COUNTERFEITER := {
	"id": "identity_counterfeiter", "planet_id": "mercado_memorias_usadas", "name": "Falsificadora de Identidades",
	"title": "Entrega uma personalidade enquanto espera", "description": "Costura hábitos roubados, imprime passados profissionais e substitui testemunhas por clientes com memórias promocionais.", "emoji": "⌁",
	"power": 1139, "loot_power": 1072, "defense": 517, "health": 15890, "duration": 561, "credits": 228900, "xp": 155400, "rank": 3, "chapter_tier": 2,
	"attacks": ["Passado Impresso", "Personalidade de Substituição", "Hábito Roubado"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_UNLIVED_LIVES_CURATOR := {
	"id": "unlived_lives_curator", "planet_id": "mercado_memorias_usadas", "name": "Curadora das Vidas Nunca Vividas",
	"title": "Coleciona futuros cancelados", "description": "Administra um arquivo de carreiras abandonadas, romances improváveis e versões heroicas de clientes que nunca pagaram a mensalidade.", "emoji": "∞?",
	"power": 1202, "loot_power": 1131, "defense": 546, "health": 17320, "duration": 581, "credits": 253200, "xp": 171900, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Futuro Cancelado", "Biografia Impossível", "Arquivo da Vida Alheia"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_MEMORY_APPRAISER_DRONE, TARGET_CHILDHOOD_BROKER, TARGET_IDENTITY_COUNTERFEITER, TARGET_UNLIVED_LIVES_CURATOR]

const EVENT_RECALL_BOOTH_MALFUNCTION := {
	"id": "recall_booth_malfunction", "planet_id": "mercado_memorias_usadas", "symbol": "RECORDE JÁ", "title": "Cabine de Recordação Avariada",
	"description": "Uma cabine promocional projeta memórias de centenas de clientes sobre a rota e insiste que a tripulação reconheça todas como próprias.", "color": "#ff70c8",
	"choices": [
		{"id": "buy_original_memory_receipt", "name": "COMPRAR RECIBO ORIGINAL · 75 CR", "effect_text": "O recibo abre o arquivo técnico: -22% defesa inimiga.", "credit_cost": 75, "defense_mult": 0.78, "result": "O recibo provou que a memória era original, mas não de quem a comprou."},
		{"id": "sort_every_recollection", "name": "ORGANIZAR CADA RECORDAÇÃO", "effect_text": "+110s de caça e +22% XP em catalogação emocional.", "duration_add": 110.0, "xp_mult": 1.22, "result": "A última memória lembrava-se de ter organizado a primeira."},
		{"id": "overload_recall_projector", "name": "SOBRECARREGAR O PROJETOR", "effect_text": "+13% poder inimigo, mas +25% créditos em dados recuperados.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A cabine explodiu em nostalgia. A segurança recordou imediatamente o culpado."},
	],
}

const EVENT_IDENTITY_AUCTION := {
	"id": "identity_auction", "planet_id": "mercado_memorias_usadas", "symbol": "EU · LOTE 9", "title": "Leilão de Identidades",
	"description": "O trânsito parou para um leilão onde três versões da mesma personalidade disputam quem possui o passado mais convincente.", "color": "#73dfff",
	"choices": [
		{"id": "buy_witnessed_past", "name": "COMPRAR PASSADO TESTEMUNHADO · 76 CR", "effect_text": "O novo álibi reduz o poder inimigo em 15%.", "credit_cost": 76, "power_mult": 0.85, "result": "Doze testemunhas confirmaram uma infância que terminou ontem."},
		{"id": "verify_every_identity", "name": "VERIFICAR CADA IDENTIDADE", "effect_text": "+100s de caça e +20% XP em biografia forense.", "duration_add": 100.0, "xp_mult": 1.20, "result": "Todas eram falsas, incluindo a identidade do verificador."},
		{"id": "resell_unused_personas", "name": "REVENDER PERSONALIDADES", "effect_text": "+12% vida inimiga, mas +23% créditos de corretagem.", "health_mult": 1.12, "credits_mult": 1.23, "result": "As personalidades foram vendidas. Duas regressaram para reclamar comissão."},
	],
}

const EVENTS := [EVENT_RECALL_BOOTH_MALFUNCTION, EVENT_IDENTITY_AUCTION]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Avaliação Emocional", "description": "Reduz a autoestima do alvo antes de avaliar o impacto."},
		{"name": "Rifle de Verão Falsificado", "description": "Dispara tardes ensolaradas com munição surpreendentemente real."},
		{"name": "Impressor de Passados Balísticos", "description": "Instala no alvo a recordação detalhada de já ter sido atingido."},
		{"name": "Canhão de Futuros Cancelados", "description": "Remove todas as versões da batalha em que o inimigo venceu."},
	],
	"armor": [
		{"name": "Colete do Avaliador Nostálgico", "description": "Declara cada dano um defeito emocional pré-existente."},
		{"name": "Casaco de Infância Premium", "description": "Inclui joelhos esfolados, bolsos com areia e proteção contratual."},
		{"name": "Traje de Identidade Instantânea", "description": "Muda de profissão sempre que a armadura falha uma inspeção."},
		{"name": "Armadura das Vidas Não Vividas", "description": "Sobrepõe todas as versões do utilizador que aprenderam a defender-se."},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Memória Muscular", "description": "Recordam fugas que as pernas nunca praticaram."},
		{"name": "Sapatos do Verão Emprestado", "description": "Trazem areia de uma praia onde o utilizador nunca esteve."},
		{"name": "Passos de Identidade Substituta", "description": "Imitam a passada de qualquer pessoa com melhor álibi."},
		{"name": "Botas do Futuro Cancelado", "description": "Pisam apenas caminhos que deixaram de acontecer."},
	],
}

const PACK := {
	"id": "mercado_memorias_usadas",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
