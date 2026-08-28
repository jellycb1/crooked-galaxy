class_name MuseuAmanhaObsoletoContent
extends RefCounted

const PLANET := {
	"id": "museu_amanha_obsoleto",
	"name": "Museu do Amanhã Obsoleto",
	"unlock_level": 100,
	"travel_duration": 3120.0,
	"subtitle": "O futuro já não é o que prometia ser.",
	"description": "Um asteroide oco transformado em museu para futuros que nunca aconteceram, onde robôs retro, cidades engarrafadas e profecias fora de prazo continuam em exposição contra a própria vontade.",
	"accent": "#ff7ac8",
	"unlock_after": "central_tempestades_24h",
	"completion_text": "O Curador do Futuro Cancelado foi arquivado na secção de previsões falhadas. As exposições continuam impossíveis, mas finalmente deixaram de cobrar entrada ao amanhã.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_RETRO_ROBOT_GUIDE := {
	"id": "retro_robot_guide", "planet_id": "museu_amanha_obsoleto", "name": "Guia Robô Retrofuturista",
	"title": "Explica botões que ninguém chegou a inventar", "description": "Conduz visitas com uma cassete de voz presa em 1987 e expulsa quem perguntar por que razão o futuro tem tantas válvulas.", "emoji": "◈",
	"power": 530, "loot_power": 499, "defense": 237, "health": 5540, "duration": 260, "credits": 27100, "xp": 18450, "rank": 3, "chapter_tier": 0,
	"attacks": ["Visita Guiada Balística", "Cassete de Boas-Vindas", "Ponteiro Laser Analógico"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_BOTTLED_CITY_CARETAKER := {
	"id": "bottled_city_caretaker", "planet_id": "museu_amanha_obsoleto", "name": "Zeladora da Cidade Engarrafada",
	"title": "Administradora de uma metrópole em miniatura", "description": "Agita arranha-céus para limpar o pó, cobra renda a cidadãos microscópicos e guarda a única rolha com saída para o exterior.", "emoji": "▥",
	"power": 547, "loot_power": 515, "defense": 245, "health": 5750, "duration": 270, "credits": 29850, "xp": 20320, "rank": 3, "chapter_tier": 1,
	"attacks": ["Sismo de Limpeza", "Rolha Metropolitana", "Renda em Miniatura"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_EXPIRED_ORACLE := {
	"id": "expired_oracle", "planet_id": "museu_amanha_obsoleto", "name": "Oráculo Fora de Prazo",
	"title": "Previu ontem com uma precisão extraordinária", "description": "Vende profecias depois de acontecerem, altera datas com tinta cósmica e culpa o cliente por qualquer apocalipse entregue tarde.", "emoji": "⌛",
	"power": 564, "loot_power": 531, "defense": 252, "health": 5960, "duration": 281, "credits": 32840, "xp": 22400, "rank": 3, "chapter_tier": 2,
	"attacks": ["Profecia Retroativa", "Apocalipse Adiado", "Correção da Linha Temporal"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_CANCELLED_FUTURE_CURATOR := {
	"id": "cancelled_future_curator", "planet_id": "museu_amanha_obsoleto", "name": "Curador do Futuro Cancelado",
	"title": "Proprietário de todos os amanhãs que falharam", "description": "Cataloga utopias defeituosas, restaura catástrofes para exposição e declara qualquer presente uma falsificação sem valor histórico.", "emoji": "⌁",
	"power": 598, "loot_power": 563, "defense": 268, "health": 6580, "duration": 294, "credits": 36350, "xp": 24750, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Utopia Defeituosa", "Catástrofe Restaurada", "Cancelamento do Amanhã"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_RETRO_ROBOT_GUIDE, TARGET_BOTTLED_CITY_CARETAKER, TARGET_EXPIRED_ORACLE, TARGET_CANCELLED_FUTURE_CURATOR]

const EVENT_GRAND_OPENING_YESTERDAY := {
	"id": "grand_opening_yesterday", "planet_id": "museu_amanha_obsoleto", "symbol": "ABERTO ONTEM", "title": "Grande Inauguração de Ontem",
	"description": "Uma fita cerimonial atravessa a rota da nave para inaugurar uma exposição que foi encerrada três séculos antes de abrir.", "color": "#ff7ac8",
	"choices": [
		{"id": "buy_vip_ticket", "name": "COMPRAR BILHETE VIP · 55 CR", "effect_text": "A visita revela a manutenção da exposição: -22% defesa inimiga.", "credit_cost": 55, "defense_mult": 0.78, "result": "O bilhete incluía acesso prioritário e uma lembrança de algo que nunca existiu."},
		{"id": "attend_full_tour", "name": "SEGUIR A VISITA COMPLETA", "effect_text": "+85s de caça e +22% XP em história especulativa.", "duration_add": 85.0, "xp_mult": 1.22, "result": "A visita terminou amanhã, precisamente onde o folheto dizia que tinha começado."},
		{"id": "cut_opening_ribbon", "name": "CORTAR A FITA À FORÇA", "effect_text": "+13% poder inimigo, mas +25% créditos de direitos de inauguração.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A exposição abriu passagem e apresentou imediatamente uma queixa histórica."},
	],
}

const EVENT_MISSING_FUTURE_EXHIBIT := {
	"id": "missing_future_exhibit", "planet_id": "museu_amanha_obsoleto", "symbol": "LOTE: AMANHÃ", "title": "Exposição do Futuro Desaparecida",
	"description": "Uma vitrina vazia afirma conter o amanhã definitivo, mas o sistema de segurança insiste que a nave acabou de o roubar.", "color": "#78e6c8",
	"choices": [
		{"id": "buy_replica_future", "name": "COMPRAR FUTURO RÉPLICA · 56 CR", "effect_text": "A réplica confunde os sensores do alvo: -15% poder inimigo.", "credit_cost": 56, "power_mult": 0.85, "result": "A cópia veio com certificado de autenticidade previsto para a próxima semana."},
		{"id": "search_archive_storage", "name": "REVISTAR O ARQUIVO", "effect_text": "+75s de caça e +20% XP em arqueologia do amanhã.", "duration_add": 75.0, "xp_mult": 1.20, "result": "O futuro estava na arrecadação, entre uma utopia dobrável e três fins do mundo suplentes."},
		{"id": "claim_exhibit_insurance", "name": "RECLAMAR O SEGURO", "effect_text": "+12% vida inimiga, mas +23% créditos de indemnização temporal.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A seguradora pagou ontem e enviou os cobradores para depois de amanhã."},
	],
}

const EVENTS := [EVENT_GRAND_OPENING_YESTERDAY, EVENT_MISSING_FUTURE_EXHIBIT]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Visita Retrofutura", "description": "Dispara comentários pré-gravados e munições que pareciam modernas há duzentos anos."},
		{"name": "Agitador de Metrópoles", "description": "Transforma qualquer cidade engarrafada num terramoto portátil."},
		{"name": "Rifle de Profecia Retroativa", "description": "Acerta sempre, desde que o disparo seja anunciado depois do impacto."},
		{"name": "Canhão do Amanhã Cancelado", "description": "Lança um futuro inteiro contra o alvo e arquiva os destroços por ordem cronológica."},
	],
	"armor": [
		{"name": "Casaco de Guia do Futuro", "description": "Tem bolsos para bilhetes, válvulas e respostas a perguntas que ainda não existem."},
		{"name": "Traje de Vitrine Metropolitana", "description": "Protege como vidro de museu e inclui uma placa a pedir para não tocar."},
		{"name": "Colete de Profecia Expirada", "description": "Prevê cada golpe imediatamente depois de o absorver."},
		{"name": "Armadura da Coleção Impossível", "description": "Feita de utopias descontinuadas e garantida até ao fim de ontem."},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Visita Cronológica", "description": "Mantêm o grupo unido mesmo quando cada pé entra numa década diferente."},
		{"name": "Solas de Cidade Engarrafada", "description": "Carregam uma rede viária completa sob cada passo de tamanho normal."},
		{"name": "Calçado do Oráculo Atrasado", "description": "Chega exatamente onde previa, geralmente um dia depois do necessário."},
		{"name": "Botas do Curador do Amanhã", "description": "Deixam pegadas com número de inventário e data futura de aquisição."},
	],
}

const PACK := {
	"id": "museu_amanha_obsoleto",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
