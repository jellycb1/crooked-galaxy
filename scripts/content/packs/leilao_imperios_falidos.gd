class_name LeilaoImperiosFalidosContent
extends RefCounted

const PLANET := {
	"id": "leilao_imperios_falidos", "name": "Leilão de Impérios Falidos", "unlock_level": 300, "travel_duration": 7920.0,
	"subtitle": "Tronos usados, conquistas vendidas separadamente.",
	"description": "Uma praça orbital liquida civilizações insolventes, vende frotas por lote e transforma séculos de conquista em oportunidades de investimento sem garantia.",
	"accent": "#d9a7ff", "unlock_after": "seguradora_apocalipses_evitaveis",
	"completion_text": "O Leiloeiro da Falência Galáctica foi vendido juntamente com o próprio martelo. Os impérios libertados descobriram que a liberdade inclui todas as dívidas anteriores.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "royal_debt_appraiser", "planet_id": "leilao_imperios_falidos", "name": "Avaliador de Dívidas Reais", "title": "Calcula o valor de cada coroa pelo peso das promessas quebradas", "description": "Penhora joias dinásticas, taxa linhagens antigas e considera revoluções populares simples danos à propriedade.", "emoji": "♜", "power": 4946, "loot_power": 4652, "defense": 2253, "health": 95200, "duration": 1738, "credits": 10360000, "xp": 7430000, "rank": 3, "chapter_tier": 0, "attacks": ["Coroa Penhorada", "Linhagem Taxada", "Revolução Avaliada"], "visual_delivery": "pending_user_asset"},
	{"id": "conquered_throne_flipper", "planet_id": "leilao_imperios_falidos", "name": "Revendedora de Tronos Conquistados", "title": "Renova monarquias derrotadas para compradores sem experiência", "description": "Pinta brasões antigos, esconde passagens de golpe de estado e promete vistas soberanas sobre populações incluídas no preço.", "emoji": "♛", "power": 5042, "loot_power": 4742, "defense": 2297, "health": 97000, "duration": 1767, "credits": 10980000, "xp": 7880000, "rank": 3, "chapter_tier": 1, "attacks": ["Brasão Repintado", "Golpe Escondido", "Soberania Renovada"], "visual_delivery": "pending_user_asset"},
	{"id": "army_liquidation_broker", "planet_id": "leilao_imperios_falidos", "name": "Corretor de Liquidação de Exércitos", "title": "Vende legiões ao lote sem verificar lealdade", "description": "Agrupa generais incompatíveis, remove garantias das naves e cobra transporte por cada soldado ainda em retirada.", "emoji": "⚑", "power": 5140, "loot_power": 4834, "defense": 2342, "health": 98820, "duration": 1796, "credits": 11630000, "xp": 8360000, "rank": 3, "chapter_tier": 2, "attacks": ["Legião em Lote", "General Incompatível", "Retirada Faturada"], "visual_delivery": "pending_user_asset"},
	{"id": "galactic_bankruptcy_auctioneer", "planet_id": "leilao_imperios_falidos", "name": "Leiloeiro da Falência Galáctica", "title": "Baixa o martelo sobre civilizações inteiras", "description": "Aceita estrelas como entrada, divide povos em lotes e prolonga guerras apenas para aumentar a comissão final da venda.", "emoji": "⬙", "power": 5343, "loot_power": 5025, "defense": 2435, "health": 103800, "duration": 1835, "credits": 12320000, "xp": 8880000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Estrela como Entrada", "Povo em Lotes", "Martelo Galáctico"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "throne_bid_war", "planet_id": "leilao_imperios_falidos", "symbol": "LICITAÇÃO REAL", "title": "Guerra de Licitações pelo Trono", "description": "Três ex-imperadores licitam a mesma cadeira e começaram a usar frotas militares como sinais de mão.", "color": "#d9a7ff", "choices": [
		{"id": "buy_priority_paddle", "name": "COMPRAR PLACA · 118 CR", "effect_text": "A placa reduz a defesa inimiga em 22%.", "credit_cost": 118, "defense_mult": 0.78, "result": "A placa venceu a licitação e tornou-se monarca provisória."},
		{"id": "verify_every_royal_bid", "name": "VERIFICAR CADA LICITAÇÃO", "effect_text": "+185s de caça e +22% XP.", "duration_add": 185.0, "xp_mult": 1.22, "result": "A última oferta era garantida por um reino vendido no lote anterior."},
		{"id": "sell_coronation_seats", "name": "VENDER LUGARES NA COROAÇÃO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A cerimónia esgotou antes de decidirem quem seria coroado."},
	]},
	{"id": "liquidated_army_mutiny", "planet_id": "leilao_imperios_falidos", "symbol": "LOTE AMOTINADO", "title": "Exército Liquidado Amotinou-se", "description": "Um lote de soldados descobriu que foi vendido sem salários, planeta de destino ou cláusula de devolução.", "color": "#ff786f", "choices": [
		{"id": "buy_back_pay_vouchers", "name": "COMPRAR VALES · 119 CR", "effect_text": "Os vales reduzem o poder inimigo em 15%.", "credit_cost": 119, "power_mult": 0.85, "result": "Os vales pagavam em crédito válido apenas na cantina destruída."},
		{"id": "inventory_every_soldier", "name": "INVENTARIAR CADA SOLDADO", "effect_text": "+175s de caça e +20% XP.", "duration_add": 175.0, "xp_mult": 1.20, "result": "O inventário terminou com mais generais do que soldados."},
		{"id": "auction_the_command", "name": "LEILOAR O COMANDO", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O comando foi comprado pelo motim e pago com armas do próprio lote."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Coroa Penhorada", "description": "Dispara autoridade real sem verificar o proprietário atual."},
		{"name": "Projetor de Golpes Escondidos", "description": "Instala uma mudança de regime atrás do alvo."},
		{"name": "Lançador de Legiões em Lote", "description": "Entrega forças incompatíveis numa única descarga militar."},
		{"name": "Canhão de Martelo Galáctico", "description": "Encerra a licitação e qualquer resistência restante."},
	],
	"armor": [
		{"name": "Colete de Linhagem Taxada", "description": "Transfere cada impacto para um antepassado insolvente."},
		{"name": "Traje de Soberania Renovada", "description": "Parece legítimo desde que ninguém examine o brasão."},
		{"name": "Armadura de General Incompatível", "description": "Emite ordens contraditórias até os ataques desistirem."},
		{"name": "Uniforme de Povo em Lotes", "description": "Divide cada golpe por uma população vendida separadamente."},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Revolução Avaliada", "description": "Marcham sobre mudanças de regime sem perder valor contabilístico."},
		{"name": "Botas de Passagem de Golpe", "description": "Encontram a saída secreta incluída em cada trono renovado."},
		{"name": "Botas de Retirada Faturada", "description": "Cobram por quilómetro enquanto recuam estrategicamente."},
		{"name": "Botas do Leiloeiro Galáctico", "description": "Permanecem firmes enquanto mundos inteiros mudam de dono."},
	],
}

const PACK := {"id": "leilao_imperios_falidos", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
