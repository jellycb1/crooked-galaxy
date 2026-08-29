class_name CartorioUltimoHorizonteContent
extends RefCounted

const PLANET := {
	"id": "cartorio_ultimo_horizonte", "name": "Cartório do Último Horizonte", "unlock_level": 240, "travel_duration": 6480.0,
	"subtitle": "O fim de tudo exige três cópias autenticadas.",
	"description": "Uma repartição suspensa no limite observável do universo regista extinções, mede fronteiras cósmicas e concede extensões provisórias à existência.",
	"accent": "#9d8cff", "unlock_after": "canil_asteroides_domesticos",
	"completion_text": "O Registador do Horizonte Final carimbou a própria ordem de captura. O universo recebeu uma extensão provisória, sujeita a renovação.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "extinction_certificate_clerk", "planet_id": "cartorio_ultimo_horizonte", "name": "Escrivão de Certificados de Extinção", "title": "Só declara espécies extintas com firma reconhecida", "description": "Confere fósseis, rejeita apocalipses sem testemunhas e cobra uma segunda via por cada civilização desaparecida.", "emoji": "▤", "power": 2890, "loot_power": 2717, "defense": 1317, "health": 48100, "duration": 1225, "credits": 2470000, "xp": 1730000, "rank": 3, "chapter_tier": 0, "attacks": ["Certidão de Extinção", "Firma Cósmica", "Segunda Via Final"], "visual_delivery": "pending_user_asset"},
	{"id": "cosmic_boundary_surveyor", "planet_id": "cartorio_ultimo_horizonte", "name": "Topógrafa da Fronteira Cósmica", "title": "Mede o infinito com uma fita regulamentar", "description": "Crava marcos no vazio, multa galáxias que ultrapassam a planta e redesenha o horizonte sempre que alguém chega perto.", "emoji": "⌖", "power": 2948, "loot_power": 2772, "defense": 1343, "health": 49100, "duration": 1248, "credits": 2630000, "xp": 1840000, "rank": 3, "chapter_tier": 1, "attacks": ["Marco no Vazio", "Fita do Infinito", "Horizonte Redesenhado"], "visual_delivery": "pending_user_asset"},
	{"id": "existence_extension_broker", "planet_id": "cartorio_ultimo_horizonte", "name": "Corretor de Extensões de Existência", "title": "Vende mais tempo com juros retroativos", "description": "Prorroga estrelas moribundas, parcela eternidades e recupera anos não pagos diretamente da memória dos clientes.", "emoji": "⌛", "power": 3007, "loot_power": 2828, "defense": 1370, "health": 50120, "duration": 1271, "credits": 2800000, "xp": 1960000, "rank": 3, "chapter_tier": 2, "attacks": ["Prazo Cósmico", "Eternidade Parcelada", "Juro Retroativo"], "visual_delivery": "pending_user_asset"},
	{"id": "final_horizon_registrar", "planet_id": "cartorio_ultimo_horizonte", "name": "Registador do Horizonte Final", "title": "Decide oficialmente onde tudo termina", "description": "Carimba limites universais, arquiva futuros não autorizados e ameaça cancelar a existência de quem perdeu a senha.", "emoji": "◉", "power": 3126, "loot_power": 2940, "defense": 1424, "health": 52900, "duration": 1301, "credits": 2980000, "xp": 2090000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Carimbo Terminal", "Futuro Arquivado", "Existência Cancelada"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "universe_end_date_typo", "planet_id": "cartorio_ultimo_horizonte", "symbol": "DATA INCORRETA", "title": "Erro na Data do Fim do Universo", "description": "Um zero em falta antecipa o fim de tudo para esta tarde e milhões de planetas tentam apresentar recurso ao mesmo tempo.", "color": "#9d8cff", "choices": [
		{"id": "buy_corrected_calendar", "name": "COMPRAR CALENDÁRIO · 106 CR", "effect_text": "O calendário reduz a defesa inimiga em 22%.", "credit_cost": 106, "defense_mult": 0.78, "result": "A nova data concedeu ao universo mais tempo e ao cartório outra taxa."},
		{"id": "verify_every_epoch", "name": "VERIFICAR CADA ÉPOCA", "effect_text": "+155s de caça e +22% XP.", "duration_add": 155.0, "xp_mult": 1.22, "result": "Todas as épocas estavam corretas, exceto uma terça-feira suspeita."},
		{"id": "sell_priority_appeals", "name": "VENDER RECURSOS PRIORITÁRIOS", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O fim foi adiado primeiro para quem pagou por ordem de chegada."},
	]},
	{"id": "infinity_queue_overflow", "planet_id": "cartorio_ultimo_horizonte", "symbol": "SENHA ∞+1", "title": "A Fila do Infinito Transbordou", "description": "A fila atravessa o último horizonte, volta pelo outro lado e entrega duas senhas diferentes a cada visitante.", "color": "#55e5ff", "choices": [
		{"id": "buy_finite_queue_number", "name": "COMPRAR SENHA FINITA · 107 CR", "effect_text": "A senha reduz o poder inimigo em 15%.", "credit_cost": 107, "power_mult": 0.85, "result": "A senha tinha apenas infinitas pessoas menos uma à frente."},
		{"id": "audit_the_entire_line", "name": "AUDITAR TODA A FILA", "effect_text": "+145s de caça e +20% XP.", "duration_add": 145.0, "xp_mult": 1.20, "result": "A auditoria encontrou o início da fila, mas não havia balcão."},
		{"id": "rent_premium_waiting_space", "name": "ALUGAR ESPERA PREMIUM", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O espaço premium incluía uma cadeira e a mesma eternidade."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Certidão Terminal", "description": "Declara o alvo oficialmente atingido em três vias."},
		{"name": "Projetor de Marcos do Vazio", "description": "Delimita uma zona onde o impacto passa a ser obrigatório."},
		{"name": "Lançador de Eternidade Parcelada", "description": "Entrega o dano agora e cobra o resto para sempre."},
		{"name": "Canhão de Carimbo Final", "description": "Autentica o fim de qualquer discussão à distância."},
	],
	"armor": [
		{"name": "Colete de Firma Cósmica", "description": "Só reconhece golpes acompanhados por duas testemunhas."},
		{"name": "Traje de Fronteira Regulamentar", "description": "Mantém o perigo fora da planta aprovada."},
		{"name": "Armadura de Prazo Prorrogado", "description": "Adia cada ferimento até ao próximo período fiscal."},
		{"name": "Uniforme do Horizonte Final", "description": "Arquiva impactos que chegam depois do encerramento."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Implante de Certificação Terminal", "description": "Autentica decisões antes de o cérebro as contestar."},
		{"name": "Nódulo de Medição Infinita", "description": "Encontra limites mesmo quando eles continuam a fugir."},
		{"name": "Implante de Extensão Existencial", "description": "Renova funções vitais em períodos administrativos."},
		{"name": "Nódulo do Carimbo Final", "description": "Declara cada pensamento definitivo por autoridade própria."},
	],
}

const PACK := {"id": "cartorio_ultimo_horizonte", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
