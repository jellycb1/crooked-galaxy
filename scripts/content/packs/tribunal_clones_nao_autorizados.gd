class_name TribunalClonesNaoAutorizadosContent
extends RefCounted

const PLANET := {
	"id": "tribunal_clones_nao_autorizados",
	"name": "Tribunal de Clones Não Autorizados",
	"unlock_level": 130,
	"travel_duration": 3840.0,
	"subtitle": "Todo indivíduo é inocente até aparecer a cópia.",
	"description": "Um planeta-tribunal coberto por laboratórios de duplicação e salas de audiência espelhadas, onde cada testemunha tem sete versões e ninguém consegue provar quem chegou primeiro.",
	"accent": "#73e6b8",
	"unlock_after": "resort_horizonte_eventos",
	"completion_text": "O Juiz da Originalidade Obrigatória foi declarado cópia de si próprio. Milhares de réus idênticos saíram em liberdade, embora nenhum tenha certeza de ser o correto.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_DUPLICATE_BAILIFF := {
	"id": "duplicate_bailiff", "planet_id": "tribunal_clones_nao_autorizados", "name": "Oficial de Justiça Duplicado",
	"title": "Entrega duas intimações por pessoa", "description": "Cerca suspeitos com cópias de si mesmo, cobra deslocação por cada corpo e prende qualquer um que apresente uma assinatura original.", "emoji": "Ⅱ",
	"power": 823, "loot_power": 775, "defense": 371, "health": 10260, "duration": 410, "credits": 87100, "xp": 59150, "rank": 3, "chapter_tier": 0,
	"attacks": ["Intimação em Duplicado", "Cerco de Cópias", "Algemas Gémeas"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_WITNESS_VERSION_SEVEN := {
	"id": "witness_version_seven", "planet_id": "tribunal_clones_nao_autorizados", "name": "Testemunha Versão Sete",
	"title": "Recorda seis crimes que não presenciou", "description": "Contradiz as versões anteriores, atualiza o próprio álibi durante o depoimento e exige proteção para todos os backups.", "emoji": "Ⅶ",
	"power": 848, "loot_power": 799, "defense": 383, "health": 10630, "duration": 423, "credits": 95880, "xp": 65120, "rank": 3, "chapter_tier": 1,
	"attacks": ["Depoimento Reescrito", "Álibi Atualizado", "Memória de Backup"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_GENETIC_PATENT_PROSECUTOR := {
	"id": "genetic_patent_prosecutor", "planet_id": "tribunal_clones_nao_autorizados", "name": "Promotora de Patentes Genéticas",
	"title": "Cobra royalties por semelhança biológica", "description": "Regista sequências de ADN durante o interrogatório e processa qualquer ser vivo que reproduza células sem licença comercial.", "emoji": "§",
	"power": 873, "loot_power": 823, "defense": 395, "health": 11010, "duration": 437, "credits": 105470, "xp": 71700, "rank": 3, "chapter_tier": 2,
	"attacks": ["Royalties Celulares", "Patente de ADN", "Embargo Genético"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_MANDATORY_ORIGINALITY_JUDGE := {
	"id": "mandatory_originality_judge", "planet_id": "tribunal_clones_nao_autorizados", "name": "Juiz da Originalidade Obrigatória",
	"title": "Único original segundo todas as suas cópias", "description": "Condena duplicados ao esquecimento, mantém substitutos em cada gabinete e assina sentenças com vinte impressões digitais iguais.", "emoji": "≡",
	"power": 925, "loot_power": 872, "defense": 419, "health": 12180, "duration": 454, "credits": 116700, "xp": 79150, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Sentença Idêntica", "Júri de Substitutos", "Apagamento do Original"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_DUPLICATE_BAILIFF, TARGET_WITNESS_VERSION_SEVEN, TARGET_GENETIC_PATENT_PROSECUTOR, TARGET_MANDATORY_ORIGINALITY_JUDGE]

const EVENT_DUPLICATE_DEFENDANT_QUEUE := {
	"id": "duplicate_defendant_queue", "planet_id": "tribunal_clones_nao_autorizados", "symbol": "RÉU × 2048", "title": "Fila de Réus Duplicados",
	"description": "Duas mil cópias do mesmo suspeito bloqueiam a rota e todas afirmam ter chegado primeiro à audiência.", "color": "#73e6b8",
	"choices": [
		{"id": "buy_originality_stamp", "name": "COMPRAR SELO ORIGINAL · 67 CR", "effect_text": "O selo abre o arquivo de segurança: -22% defesa inimiga.", "credit_cost": 67, "defense_mult": 0.78, "result": "O selo era autêntico, exceto pelos outros dois mil selos igualmente autênticos."},
		{"id": "interview_every_copy", "name": "INTERROGAR CADA CÓPIA", "effect_text": "+100s de caça e +22% XP em jurisprudência duplicada.", "duration_add": 100.0, "xp_mult": 1.22, "result": "Todos deram a mesma resposta em tons juridicamente diferentes."},
		{"id": "declare_all_guilty", "name": "DECLARAR TODOS CULPADOS", "effect_text": "+13% poder inimigo, mas +25% créditos em custas multiplicadas.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A sentença poupou tempo. A perseguição ganhou dois mil participantes."},
	],
}

const EVENT_IDENTITY_APPEAL := {
	"id": "identity_appeal", "planet_id": "tribunal_clones_nao_autorizados", "symbol": "RECURSO: EU?", "title": "Recurso de Identidade",
	"description": "O computador do tribunal acusa a nave de ser uma cópia não licenciada de outra que ainda não chegou.", "color": "#7aa8ff",
	"choices": [
		{"id": "buy_genetic_certificate", "name": "COMPRAR CERTIFICADO GENÉTICO · 68 CR", "effect_text": "O certificado bloqueia a autorização ofensiva: -15% poder inimigo.", "credit_cost": 68, "power_mult": 0.85, "result": "O certificado confirmou que a nave é única dentro de uma margem de erro de nove cópias."},
		{"id": "audit_identity_chain", "name": "AUDITAR A CADEIA DE IDENTIDADE", "effect_text": "+90s de caça e +20% XP em genealogia forense.", "duration_add": 90.0, "xp_mult": 1.20, "result": "A cadeia terminou na própria auditoria, que alegou ser filha do relatório."},
		{"id": "sell_clone_rights", "name": "VENDER DIREITOS DE CÓPIA", "effect_text": "+12% vida inimiga, mas +23% créditos de licenciamento genético.", "health_mult": 1.12, "credits_mult": 1.23, "result": "Os direitos foram vendidos. Uma frota idêntica enviará a fatura."},
	],
}

const EVENTS := [EVENT_DUPLICATE_DEFENDANT_QUEUE, EVENT_IDENTITY_APPEAL]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Intimação Duplicada", "description": "Entrega o primeiro disparo e uma cópia certificada antes do impacto."},
		{"name": "Rifle de Depoimento Reescrito", "description": "Altera a trajetória até os factos concordarem com o projétil."},
		{"name": "Canhão de Royalties Genéticos", "description": "Cobra ao alvo por cada célula atingida sem licença."},
		{"name": "Emissor da Originalidade Obrigatória", "description": "Apaga qualquer coisa parecida demais com o proprietário."},
	],
	"armor": [
		{"name": "Casaco de Oficial Duplicado", "description": "Inclui uma segunda camada que insiste ser a primeira."},
		{"name": "Traje da Testemunha Sete", "description": "Muda de versão sempre que a proteção anterior deixa de funcionar."},
		{"name": "Colete de Patente Celular", "description": "Regista cada impacto recebido e envia uma cobrança ao atacante."},
		{"name": "Armadura do Juiz Original", "description": "Vinte placas idênticas certificam que nenhuma é uma cópia."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Arnês de Intimações Gémeas", "description": "Transporta documentos, algemas e respetivos duplicados autenticados."},
		{"name": "Suporte de Memória Versão Sete", "description": "Guarda seis depoimentos incompatíveis e escolhe o mais conveniente."},
		{"name": "Barramento de Patente Genética", "description": "Compara cada movimento com milhões de gestos já registados."},
		{"name": "Rig do Original Certificado", "description": "Replica o equipamento inteiro enquanto proíbe formalmente qualquer duplicação."},
	],
}

const PACK := {
	"id": "tribunal_clones_nao_autorizados",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
