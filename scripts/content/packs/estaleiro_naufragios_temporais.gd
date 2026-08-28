class_name EstaleiroNaufragiosTemporaisContent
extends RefCounted

const PLANET := {
	"id": "estaleiro_naufragios_temporais",
	"name": "Estaleiro de Naufrágios Temporais",
	"unlock_level": 160,
	"travel_duration": 4560.0,
	"subtitle": "Reparamos ontem. Faturamos amanhã.",
	"description": "Um estaleiro orbital recolhe naves destruídas antes do acidente, desmonta futuros usados e cobra armazenamento por cada linha temporal ocupada.",
	"accent": "#66e6ff",
	"unlock_after": "mercado_memorias_usadas",
	"completion_text": "O Almirante do Último Acidente foi capturado antes de provocar o primeiro. O estaleiro continua a enviar faturas por reparações que agora nunca serão necessárias.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{
		"id": "retroactive_welder", "planet_id": "estaleiro_naufragios_temporais", "name": "Soldador Retroativo",
		"title": "Conserta a nave antes de a partir", "description": "Solda danos futuros, apaga garantias passadas e deixa cicatrizes metálicas em acidentes que ainda estão a caminho.", "emoji": "⌁",
		"power": 1230, "loot_power": 1157, "defense": 559, "health": 17770, "duration": 594, "credits": 275900, "xp": 187300, "rank": 3, "chapter_tier": 0,
		"attacks": ["Solda Retroativa", "Garantia Paradoxal", "Faísca de Amanhã"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "future_scrap_diver", "planet_id": "estaleiro_naufragios_temporais", "name": "Mergulhadora de Sucata Futura",
		"title": "Recicla peças que ainda estão instaladas", "description": "Salta para destroços de amanhã, remove componentes valiosos e regressa antes de os proprietários perceberem por que falharam.", "emoji": "◇",
		"power": 1260, "loot_power": 1185, "defense": 573, "health": 18220, "duration": 609, "credits": 298600, "xp": 202700, "rank": 3, "chapter_tier": 1,
		"attacks": ["Mergulho no Amanhã", "Peça Ainda Instalada", "Reciclagem Prematura"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "paradox_tug_captain", "planet_id": "estaleiro_naufragios_temporais", "name": "Capitão do Rebocador Paradoxal",
		"title": "Reboca duas versões do mesmo desastre", "description": "Arrasta naufrágios por atalhos temporais e cobra a cada versão sobrevivente da tripulação.", "emoji": "↺",
		"power": 1291, "loot_power": 1214, "defense": 587, "health": 18680, "duration": 624, "credits": 323100, "xp": 219300, "rank": 3, "chapter_tier": 2,
		"attacks": ["Cabo de Paradoxo", "Reboque Duplicado", "Taxa de Sobrevivente"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "last_accident_admiral", "planet_id": "estaleiro_naufragios_temporais", "name": "Almirante do Último Acidente",
		"title": "Planeia o desastre que encerra todos os outros", "description": "Comanda uma frota de navios já destruídos e dispara ordens de batalha a partir do relatório final do acidente.", "emoji": "⌛",
		"power": 1357, "loot_power": 1277, "defense": 617, "health": 20240, "duration": 645, "credits": 351900, "xp": 238900, "rank": 3, "chapter_tier": 3, "boss": true,
		"attacks": ["Relatório Final", "Frota Já Destruída", "Último Acidente"], "visual_delivery": "pending_user_asset",
	},
]

const EVENTS := [
	{
		"id": "premature_salvage_claim", "planet_id": "estaleiro_naufragios_temporais", "symbol": "SALVADO T-1", "title": "Reclamação de Salvado Prematura",
		"description": "Um perito declara a nave como destroço valioso enquanto ela ainda atravessa o corredor em perfeito estado.", "color": "#66e6ff",
		"choices": [
			{"id": "buy_future_damage_report", "name": "COMPRAR RELATÓRIO FUTURO · 79 CR", "effect_text": "O relatório revela pontos fracos: -22% defesa inimiga.", "credit_cost": 79, "defense_mult": 0.78, "result": "O relatório estava correto, sobretudo depois de ser lido."},
			{"id": "inventory_every_timeline", "name": "INVENTARIAR CADA LINHA", "effect_text": "+115s de caça e +22% XP.", "duration_add": 115.0, "xp_mult": 1.22, "result": "A última linha temporal continha o inventário da primeira."},
			{"id": "claim_salvage_first", "name": "RECLAMAR O SALVADO PRIMEIRO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A tripulação vendeu a própria nave e teve de alugar o regresso."},
		],
	},
	{
		"id": "duplicate_distress_signal", "planet_id": "estaleiro_naufragios_temporais", "symbol": "SOS × 2", "title": "Sinal de Socorro Duplicado",
		"description": "Duas versões da mesma nave pedem resgate, cada uma acusando a outra de ser o acidente falso.", "color": "#ffbf55",
		"choices": [
			{"id": "buy_chronology_certificate", "name": "COMPRAR CERTIFICADO · 80 CR", "effect_text": "A cronologia reduz o poder inimigo em 15%.", "credit_cost": 80, "power_mult": 0.85, "result": "O certificado era autêntico numa das duas quintas-feiras."},
			{"id": "interview_both_wrecks", "name": "ENTREVISTAR AMBOS", "effect_text": "+105s de caça e +20% XP.", "duration_add": 105.0, "xp_mult": 1.20, "result": "As versões concordaram apenas sobre a culpa da tripulação."},
			{"id": "tow_the_louder_version", "name": "REBOCAR A MAIS RUIDOSA", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A versão silenciosa chegou primeiro e apresentou a fatura."},
		],
	},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Solda Retroativa", "description": "Fecha a perfuração um segundo antes de a abrir."},
		{"name": "Rifle de Salvado Futuro", "description": "Dispara componentes removidos da próxima versão do alvo."},
		{"name": "Lançador de Cabos Paradoxais", "description": "Prende o inimigo ao lugar onde deixou de estar."},
		{"name": "Canhão do Último Acidente", "description": "Usa o relatório final como coordenada de impacto."},
	],
	"armor": [
		{"name": "Colete de Garantia Retroativa", "description": "Cobre danos ocorridos antes da exclusão contratual."},
		{"name": "Traje de Mergulho Futuro", "description": "Mantém o utilizador seco em destroços que ainda flutuam."},
		{"name": "Armadura de Reboque Duplicado", "description": "Distribui cada impacto por duas linhas temporais."},
		{"name": "Uniforme do Almirante Final", "description": "Já inclui todas as medalhas concedidas depois da batalha."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Solda de Ontem", "description": "Protegem as mãos de faíscas que já arderam."},
		{"name": "Manoplas de Sucata Futura", "description": "Agarram peças antes de se soltarem."},
		{"name": "Luvas de Cabo Paradoxal", "description": "Seguram ambas as pontas da mesma causa."},
		{"name": "Manoplas do Último Acidente", "description": "Assinam o relatório antes de começar a batalha."},
	],
}

const PACK := {"id": "estaleiro_naufragios_temporais", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
