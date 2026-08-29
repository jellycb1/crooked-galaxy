class_name AgenciaDeusesReformadosContent
extends RefCounted

const PLANET := {
	"id": "agencia_deuses_reformados", "name": "Agência de Deuses Reformados", "unlock_level": 260, "travel_duration": 6960.0,
	"subtitle": "Milagres anteriores contam como experiência.",
	"description": "Um templo-centro de emprego orbital recicla divindades esquecidas, converte profecias em currículos e encontra carreiras civis para entidades habituadas a governar mundos.",
	"accent": "#ffd166", "unlock_after": "universidade_vilania_correspondencia",
	"completion_text": "A Diretora da Redundância Divina foi dispensada por intervenção superior. Os antigos deuses fundaram um sindicato e exigiram fins de semana sem sacrifícios.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "retired_thunder_retrainer", "planet_id": "agencia_deuses_reformados", "name": "Formador de Trovões Reformados", "title": "Ensina tempestades a trabalhar em escritórios", "description": "Reduz relâmpagos a notificações, converte ira divina em motivação e reprova trovões que continuam a exigir sacrifícios.", "emoji": "ϟ", "power": 3500, "loot_power": 3292, "defense": 1594, "health": 60600, "duration": 1390, "credits": 4070000, "xp": 2860000, "rank": 3, "chapter_tier": 0, "attacks": ["Trovão Requalificado", "Ira Motivacional", "Relâmpago de Escritório"], "visual_delivery": "pending_user_asset"},
	{"id": "minor_miracle_auditor", "planet_id": "agencia_deuses_reformados", "name": "Auditora de Milagres Menores", "title": "Exige recibos por cada intervenção divina", "description": "Conta pães multiplicados, taxa mares abertos e classifica ressurreições tardias como despesas não autorizadas.", "emoji": "✧", "power": 3569, "loot_power": 3357, "defense": 1626, "health": 61800, "duration": 1415, "credits": 4320000, "xp": 3040000, "rank": 3, "chapter_tier": 1, "attacks": ["Milagre Menor", "Mar Tributado", "Ressurreição Rejeitada"], "visual_delivery": "pending_user_asset"},
	{"id": "worship_subscription_broker", "planet_id": "agencia_deuses_reformados", "name": "Corretor de Subscrições de Culto", "title": "Vende fiéis em planos mensais renováveis", "description": "Agrupa orações, limita bênçãos gratuitas e transfere devotos entre panteões sem avisar as divindades envolvidas.", "emoji": "⌁", "power": 3640, "loot_power": 3423, "defense": 1658, "health": 63020, "duration": 1440, "credits": 4580000, "xp": 3230000, "rank": 3, "chapter_tier": 2, "attacks": ["Oração Agrupada", "Bênção Limitada", "Devoto Transferido"], "visual_delivery": "pending_user_asset"},
	{"id": "divine_redundancy_director", "planet_id": "agencia_deuses_reformados", "name": "Diretora da Redundância Divina", "title": "Declara panteões inteiros economicamente desnecessários", "description": "Cancela domínios sagrados, terceiriza destinos e substitui deuses antigos por respostas automáticas com halo.", "emoji": "☼", "power": 3784, "loot_power": 3559, "defense": 1724, "health": 66300, "duration": 1473, "credits": 4870000, "xp": 3440000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Domínio Cancelado", "Destino Terceirizado", "Halo Automático"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "unclaimed_prayer_backlog", "planet_id": "agencia_deuses_reformados", "symbol": "ORAÇÕES EM ATRASO", "title": "Acumulação de Orações Não Reclamadas", "description": "Milhões de pedidos antigos transbordam do arquivo, invocando chuva, riqueza e estacionamento na mesma coordenada.", "color": "#ffd166", "choices": [
		{"id": "buy_divine_sorting_seals", "name": "COMPRAR SELOS · 110 CR", "effect_text": "Os selos reduzem a defesa inimiga em 22%.", "credit_cost": 110, "defense_mult": 0.78, "result": "As orações foram separadas entre urgente, impossível e estacionamento."},
		{"id": "answer_every_prayer", "name": "RESPONDER A TODAS", "effect_text": "+165s de caça e +22% XP.", "duration_add": 165.0, "xp_mult": 1.22, "result": "A última resposta criou outra religião por engano."},
		{"id": "sell_priority_blessings", "name": "VENDER BÊNÇÃOS PRIORITÁRIAS", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os fiéis premium receberam chuva primeiro e guarda-chuvas depois."},
	]},
	{"id": "retired_god_refuses_mortality", "planet_id": "agencia_deuses_reformados", "symbol": "REFORMA RECUSADA", "title": "Deus Reformado Recusa Mortalidade", "description": "Uma antiga divindade solar rejeita o crachá temporário e transforma a sala de entrevistas num novo amanhecer.", "color": "#ff8f70", "choices": [
		{"id": "buy_mortal_orientation_manual", "name": "COMPRAR MANUAL · 111 CR", "effect_text": "O manual reduz o poder inimigo em 15%.", "credit_cost": 111, "power_mult": 0.85, "result": "O manual explicou mortalidade em vinte volumes não reembolsáveis."},
		{"id": "complete_the_exit_interview", "name": "CONCLUIR A ENTREVISTA", "effect_text": "+155s de caça e +20% XP.", "duration_add": 155.0, "xp_mult": 1.20, "result": "A entrevista terminou quando o sol assinou com uma mancha de plasma."},
		{"id": "charge_for_new_sunrise", "name": "COBRAR O NOVO AMANHECER", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "As janelas premium venderam toda a vista antes do meio-dia."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Trovão Requalificado", "description": "Entrega ira divina num formato adequado ao escritório."},
		{"name": "Projetor de Milagres Menores", "description": "Faz o impossível desde que caiba no orçamento."},
		{"name": "Lançador de Orações Agrupadas", "description": "Combina pedidos incompatíveis numa única resposta urgente."},
		{"name": "Canhão de Domínio Cancelado", "description": "Remove a autoridade sagrada antes do impacto."},
	],
	"armor": [
		{"name": "Colete de Ira Motivacional", "description": "Transforma ameaças celestes em objetivos trimestrais."},
		{"name": "Traje de Ressurreição Rejeitada", "description": "Recusa permanecer derrotado sem o formulário correto."},
		{"name": "Armadura de Bênção Limitada", "description": "Protege até ao limite mensal do plano gratuito."},
		{"name": "Uniforme da Redundância Divina", "description": "Declara cada golpe uma função sagrada duplicada."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Relâmpago de Escritório", "description": "Aterraram trovões diretamente na caixa de entrada."},
		{"name": "Manoplas de Auditoria Milagrosa", "description": "Contam intervenções divinas antes de permitir outra."},
		{"name": "Luvas de Transferência de Devotos", "description": "Movem fiéis entre panteões com um aperto administrativo."},
		{"name": "Manoplas de Halo Automático", "description": "Imitam autoridade celestial durante o horário laboral."},
	],
}

const PACK := {"id": "agencia_deuses_reformados", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
