class_name CorreioBuracosMinhocaContent
extends RefCounted

const PLANET := {
	"id": "correio_buracos_minhoca", "name": "Correio de Buracos de Minhoca", "unlock_level": 200, "travel_duration": 5520.0,
	"subtitle": "Entregamos ontem. Talvez noutro universo.",
	"description": "Um centro postal construído entre buracos de minhoca separa encomendas por século, dimensão e probabilidade de alguma vez chegarem ao destinatário correto.",
	"accent": "#9b87ff", "unlock_after": "clinica_planetas_descontinuados",
	"completion_text": "O Diretor das Encomendas Impossíveis foi finalmente entregue às autoridades. O recibo confirma que chegou três dias antes de ser capturado.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "paradox_parcel_sorter", "planet_id": "correio_buracos_minhoca", "name": "Separador de Encomendas Paradoxais", "title": "Ordena pacotes antes de serem enviados", "description": "Empilha presentes de futuros cancelados, devolve causas sem efeito e cobra portes a ambos os lados do paradoxo.", "emoji": "▣", "power": 1936, "loot_power": 1821, "defense": 881, "health": 31080, "duration": 887, "credits": 878000, "xp": 599000, "rank": 3, "chapter_tier": 0, "attacks": ["Pacote Paradoxal", "Porte Duplicado", "Devolução sem Causa"], "visual_delivery": "pending_user_asset"},
	{"id": "yesterday_express_courier", "planet_id": "correio_buracos_minhoca", "name": "Estafeta Expresso de Ontem", "title": "Entrega sempre antes de levantar a encomenda", "description": "Conduz uma mota através de atalhos temporais, falsifica horas de receção e exige gorjeta retroativa.", "emoji": "↯", "power": 1977, "loot_power": 1860, "defense": 900, "health": 31730, "duration": 906, "credits": 940000, "xp": 642000, "rank": 3, "chapter_tier": 1, "attacks": ["Entrega de Ontem", "Atalho Temporal", "Gorjeta Retroativa"], "visual_delivery": "pending_user_asset"},
	{"id": "lost_dimension_customs_officer", "planet_id": "correio_buracos_minhoca", "name": "Fiscal de Dimensões Perdidas", "title": "Confisca universos sem código postal", "description": "Abre realidades mal embaladas, taxa dimensões extra e envia civilizações inteiras para o depósito de perdidos.", "emoji": "⌑", "power": 2019, "loot_power": 1900, "defense": 919, "health": 32400, "duration": 925, "credits": 1007000, "xp": 688000, "rank": 3, "chapter_tier": 2, "attacks": ["Dimensão Confiscada", "Taxa de Realidade", "Depósito de Perdidos"], "visual_delivery": "pending_user_asset"},
	{"id": "impossible_mail_postmaster", "planet_id": "correio_buracos_minhoca", "name": "Diretor das Encomendas Impossíveis", "title": "Assina por destinatários que nunca existiram", "description": "Comanda milhões de carteiros alternativos, carimba universos como morada insuficiente e nunca aceita uma reclamação no presente.", "emoji": "✉", "power": 2104, "loot_power": 1979, "defense": 958, "health": 34450, "duration": 950, "credits": 1080000, "xp": 738000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Morada Insuficiente", "Assinatura Impossível", "Devolução ao Universo"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "infinite_return_loop", "planet_id": "correio_buracos_minhoca", "symbol": "DEVOLVER ∞", "title": "Ciclo de Devolução Infinito", "description": "Uma encomenda regressa ao remetente antes de sair, acumulando um novo selo em cada passagem.", "color": "#9b87ff", "choices": [
		{"id": "buy_final_delivery_stamp", "name": "COMPRAR SELO FINAL · 95 CR", "effect_text": "O selo reduz a defesa inimiga em 22%.", "credit_cost": 95, "defense_mult": 0.78, "result": "O selo dizia FINAL em oito alfabetos provisórios."},
		{"id": "trace_every_return", "name": "SEGUIR CADA DEVOLUÇÃO", "effect_text": "+135s de caça e +22% XP.", "duration_add": 135.0, "xp_mult": 1.22, "result": "A rota terminou exatamente onde ainda não tinha começado."},
		{"id": "auction_the_stamp_layer", "name": "LEILOAR OS SELOS", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Um colecionador comprou a camada exterior e ficou preso no ciclo."},
	]},
	{"id": "parcel_contains_destination", "planet_id": "correio_buracos_minhoca", "symbol": "FRÁGIL: MUNDO", "title": "Encomenda Contém o Destino", "description": "Ao abrir uma caixa, a equipa encontra o planeta de entrega dobrado no interior junto da fatura.", "color": "#ffd166", "choices": [
		{"id": "buy_spacetime_padding", "name": "COMPRAR PROTEÇÃO · 96 CR", "effect_text": "A proteção reduz o poder inimigo em 15%.", "credit_cost": 96, "power_mult": 0.85, "result": "A espuma protegeu o espaço, mas colou-se ao tempo."},
		{"id": "unfold_the_planet", "name": "DESDOBRAR O PLANETA", "effect_text": "+125s de caça e +20% XP.", "duration_add": 125.0, "xp_mult": 1.20, "result": "Sobrou uma montanha no fundo da caixa."},
		{"id": "charge_oversized_postage", "name": "COBRAR POR EXCESSO", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O planeta pagou em continentes e pediu troco em ilhas."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Pacotes Paradoxais", "description": "Entrega o impacto antes de puxar o gatilho."},
		{"name": "Rifle Expresso de Ontem", "description": "Regista cada acerto com data retroativa."},
		{"name": "Lançador de Dimensões Confiscadas", "description": "Dispara espaço adicional sem o declarar."},
		{"name": "Canhão de Morada Insuficiente", "description": "Devolve o alvo à origem sem portes pagos."},
	],
	"armor": [
		{"name": "Colete de Porte Duplicado", "description": "Encaminha cada golpe por duas rotas incompatíveis."},
		{"name": "Traje de Entrega Retroativa", "description": "Chega intacto antes de receber o dano."},
		{"name": "Armadura de Código Dimensional", "description": "Esconde a morada numa realidade alternativa."},
		{"name": "Uniforme das Encomendas Impossíveis", "description": "Nunca está disponível para receber impactos."	},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Rota Paradoxal", "description": "Começam o percurso pelo comprovativo de entrega."},
		{"name": "Botas Expresso de Ontem", "description": "Chegam antes de os pés decidirem partir."},
		{"name": "Grevas de Alfândega Dimensional", "description": "Atravessam fronteiras que ainda não existem."},
		{"name": "Botas do Diretor Impossível", "description": "Recusam qualquer destino com morada verificável."},
	],
}

const PACK := {"id": "correio_buracos_minhoca", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
