class_name CentralSonhosPenhoradosContent
extends RefCounted

const PLANET := {
	"id": "central_sonhos_penhorados", "name": "Central de Sonhos Penhorados", "unlock_level": 220, "travel_duration": 6000.0,
	"subtitle": "Durma agora. Pague quando acordar.",
	"description": "Uma lua coberta por torres de sono recolhe sonhos usados como garantia, arquiva pesadelos vencidos e revende fantasias em cápsulas com juros compostos.",
	"accent": "#d78cff", "unlock_after": "aquario_oceanos_confiscados",
	"completion_text": "O Diretor do Repouso Compulsivo finalmente acordou para responder pelos contratos. Milhões de sonhos regressaram aos donos, mas ninguém encontrou os recibos.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "overdue_nightmare_collector", "planet_id": "central_sonhos_penhorados", "name": "Cobrador de Pesadelos em Atraso", "title": "Recupera monstros antes do despertador", "description": "Invade quartos a meio da noite, confisca sustos vencidos e deixa uma taxa por cada grito fora do prazo.", "emoji": "☾", "power": 2370, "loot_power": 2229, "defense": 1080, "health": 39600, "duration": 1055, "credits": 1500000, "xp": 1035000, "rank": 3, "chapter_tier": 0, "attacks": ["Cobrança Noturna", "Susto Vencido", "Taxa de Grito"], "visual_delivery": "pending_user_asset"},
	{"id": "prefabricated_dream_architect", "planet_id": "central_sonhos_penhorados", "name": "Arquiteta de Sonhos Pré-Fabricados", "title": "Constrói destinos com peças repetidas", "description": "Monta paraísos em série, recicla rostos desconhecidos e cobra extra por finais que fazem algum sentido.", "emoji": "◇", "power": 2418, "loot_power": 2274, "defense": 1102, "health": 40400, "duration": 1076, "credits": 1595000, "xp": 1105000, "rank": 3, "chapter_tier": 1, "attacks": ["Paraíso Modular", "Rosto Reciclado", "Final Premium"], "visual_delivery": "pending_user_asset"},
	{"id": "sleep_memory_smuggler", "planet_id": "central_sonhos_penhorados", "name": "Contrabandista de Memórias de Sono", "title": "Transporta noites que ninguém viveu", "description": "Esconde lembranças em almofadas seladas, atravessa alfândegas inconscientes e vende déjà vu sem certificado de origem.", "emoji": "⌁", "power": 2467, "loot_power": 2320, "defense": 1124, "health": 41220, "duration": 1097, "credits": 1695000, "xp": 1180000, "rank": 3, "chapter_tier": 2, "attacks": ["Almofada Selada", "Alfândega Inconsciente", "Déjà Vu Ilegal"], "visual_delivery": "pending_user_asset"},
	{"id": "compulsory_rest_director", "planet_id": "central_sonhos_penhorados", "name": "Diretor do Repouso Compulsivo", "title": "Declara toda a galáxia oficialmente cansada", "description": "Controla o ciclo de sono da lua, encerra revoltas com uma canção de embalar e aplica juros a quem acorda cedo.", "emoji": "◉", "power": 2564, "loot_power": 2411, "defense": 1168, "health": 43550, "duration": 1124, "credits": 1810000, "xp": 1260000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Repouso Obrigatório", "Canção Executiva", "Juro Matinal"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "lucid_dream_tax_audit", "planet_id": "central_sonhos_penhorados", "symbol": "LÚCIDO: TAXADO", "title": "Auditoria ao Sonho Lúcido", "description": "Um inspetor descobre que a equipa sabe que está a sonhar e exige declaração retroativa de imaginação.", "color": "#d78cff", "choices": [
		{"id": "buy_dream_receipts", "name": "COMPRAR RECIBOS · 101 CR", "effect_text": "Os recibos reduzem a defesa inimiga em 22%.", "credit_cost": 101, "defense_mult": 0.78, "result": "Os recibos eram autênticos dentro de três sonhos consecutivos."},
		{"id": "itemize_every_symbol", "name": "DECLARAR CADA SÍMBOLO", "effect_text": "+145s de caça e +22% XP.", "duration_add": 145.0, "xp_mult": 1.22, "result": "A escada sem fim foi aceite como despesa de deslocação."},
		{"id": "sell_lucid_access", "name": "VENDER ACESSO LÚCIDO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os bilhetes esgotaram antes de o público adormecer."},
	]},
	{"id": "nightmare_storage_leak", "planet_id": "central_sonhos_penhorados", "symbol": "FUGA: MEDO", "title": "Fuga no Armazém de Pesadelos", "description": "Uma cápsula rachada liberta medos em bruto pelo corredor, incluindo um exame para uma disciplina inexistente.", "color": "#ff6f9c", "choices": [
		{"id": "buy_comfort_blanket", "name": "COMPRAR MANTA · 102 CR", "effect_text": "A manta reduz o poder inimigo em 15%.", "credit_cost": 102, "power_mult": 0.85, "result": "A manta cobriu todos os medos menos o preço da própria manta."},
		{"id": "catalog_every_fear", "name": "CATALOGAR CADA MEDO", "effect_text": "+135s de caça e +20% XP.", "duration_add": 135.0, "xp_mult": 1.20, "result": "O catálogo ganhou dentes e pediu uma prateleira baixa."},
		{"id": "open_a_haunted_attraction", "name": "ABRIR ATRAÇÃO", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A fila cresceu assim que o perigo recebeu iluminação temática."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Cobrança Noturna", "description": "Acorda o alvo apenas para apresentar a fatura."},
		{"name": "Projetor de Paraíso Modular", "description": "Dispara destinos montados com peças incompatíveis."},
		{"name": "Lançador de Déjà Vu Ilegal", "description": "Acerta como se já tivesse acertado antes."},
		{"name": "Canhão de Repouso Obrigatório", "description": "Coloca qualquer discussão em modo de suspensão."},
	],
	"armor": [
		{"name": "Colete de Susto Vencido", "description": "Devolve impactos apresentados fora do horário de sono."},
		{"name": "Traje de Sonho Pré-Fabricado", "description": "Reconstrói-se com o cenário mais próximo."},
		{"name": "Armadura de Alfândega Inconsciente", "description": "Esconde danos em compartimentos que a memória não alcança."},
		{"name": "Uniforme do Repouso Compulsivo", "description": "Declara cada ataque uma pausa não autorizada."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Cobrança Onírica", "description": "Localiza dívidas mesmo dentro de sonhos sem endereço."},
		{"name": "Elmo de Paraíso Modular", "description": "Troca o horizonte sempre que a realidade se aproxima."},
		{"name": "Viseira de Memórias de Sono", "description": "Mostra lembranças que ainda não decidiram a quem pertencem."},
		{"name": "Capacete do Diretor Adormecido", "description": "Mantém o utilizador acordado apenas durante reuniões obrigatórias."},
	],
}

const PACK := {"id": "central_sonhos_penhorados", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
