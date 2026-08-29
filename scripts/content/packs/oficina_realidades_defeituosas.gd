class_name OficinaRealidadesDefeituosasContent
extends RefCounted

const PLANET := {
	"id": "oficina_realidades_defeituosas", "name": "Oficina de Realidades Defeituosas", "unlock_level": 280, "travel_duration": 7440.0,
	"subtitle": "A garantia não cobre paradoxos causados pelo cliente.",
	"description": "Uma oficina orbital remenda universos rachados, substitui leis físicas fora de prazo e devolve dimensões defeituosas com peças de realidades incompatíveis.",
	"accent": "#65c7ff", "unlock_after": "reserva_especies_impossiveis",
	"completion_text": "O Mestre das Realidades Defeituosas foi selado numa dimensão de substituição. A oficina reabriu sob nova gerência e anulou imediatamente todas as garantias antigas.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "continuity_patch_smuggler", "planet_id": "oficina_realidades_defeituosas", "name": "Contrabandista de Remendos de Continuidade", "title": "Tapa buracos narrativos com futuros roubados", "description": "Recorta acontecimentos de universos vizinhos, cola causas depois dos efeitos e vende finais usados sem revelar a linha temporal original.", "emoji": "⌁", "power": 4164, "loot_power": 3916, "defense": 1897, "health": 76000, "duration": 1560, "credits": 6530000, "xp": 4630000, "rank": 3, "chapter_tier": 0, "attacks": ["Remendo de Continuidade", "Causa Tardia", "Final Usado"], "visual_delivery": "pending_user_asset"},
	{"id": "counterfeit_law_physicist", "planet_id": "oficina_realidades_defeituosas", "name": "Físico de Leis Contrafeitas", "title": "Instala gravidade sem licença de fabricante", "description": "Duplica constantes universais, falsifica certificados de causalidade e deixa cada realidade funcional até terminar o período de devolução.", "emoji": "∿", "power": 4245, "loot_power": 3992, "defense": 1934, "health": 77450, "duration": 1587, "credits": 6920000, "xp": 4910000, "rank": 3, "chapter_tier": 1, "attacks": ["Gravidade Contrafeita", "Constante Duplicada", "Causalidade sem Licença"], "visual_delivery": "pending_user_asset"},
	{"id": "universe_recall_mechanic", "planet_id": "oficina_realidades_defeituosas", "name": "Mecânica de Recolhas Universais", "title": "Recolhe cosmos inteiros por defeitos menores", "description": "Reboca dimensões habitadas, desmonta horizontes e classifica apocalipses completos como simples ruído no motor cósmico.", "emoji": "⚙", "power": 4328, "loot_power": 4070, "defense": 1972, "health": 78920, "duration": 1614, "credits": 7330000, "xp": 5210000, "rank": 3, "chapter_tier": 2, "attacks": ["Reboque Dimensional", "Horizonte Desmontado", "Apocalipse de Oficina"], "visual_delivery": "pending_user_asset"},
	{"id": "defective_reality_foreman", "planet_id": "oficina_realidades_defeituosas", "name": "Mestre das Realidades Defeituosas", "title": "Aprova universos que falham em todas as inspeções", "description": "Manda polir singularidades, substitui estrelas por peças genéricas e assina a garantia de mundos que já começaram a desfazer-se.", "emoji": "⬢", "power": 4499, "loot_power": 4231, "defense": 2050, "health": 82900, "duration": 1650, "credits": 7770000, "xp": 5540000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Singularidade Polida", "Estrela Genérica", "Garantia Anulada"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "reality_seam_split", "planet_id": "oficina_realidades_defeituosas", "symbol": "COSTURA ABERTA", "title": "A Costura da Realidade Abriu", "description": "Uma reparação barata soltou-se e agora três versões incompatíveis da oficina ocupam o mesmo lugar.", "color": "#65c7ff", "choices": [
		{"id": "buy_causality_staples", "name": "COMPRAR AGRAFOS · 114 CR", "effect_text": "Os agrafos reduzem a defesa inimiga em 22%.", "credit_cost": 114, "defense_mult": 0.78, "result": "Os agrafos seguraram duas realidades; a terceira apresentou reclamação."},
		{"id": "stitch_every_timeline", "name": "COSER CADA LINHA TEMPORAL", "effect_text": "+175s de caça e +22% XP.", "duration_add": 175.0, "xp_mult": 1.22, "result": "A última costura ligou a oficina a uma lavandaria do fim dos tempos."},
		{"id": "rent_the_extra_dimensions", "name": "ALUGAR AS DIMENSÕES EXTRA", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Cada dimensão foi anunciada como estúdio compacto com causalidade partilhada."},
	]},
	{"id": "physical_law_recall", "planet_id": "oficina_realidades_defeituosas", "symbol": "LEI RECOLHIDA", "title": "Lei Física Chamada à Oficina", "description": "A gravidade deste setor pertence a um lote defeituoso e o fabricante exige a devolução imediata de tudo o que está no chão.", "color": "#ff9f68", "choices": [
		{"id": "buy_emergency_magnetism", "name": "COMPRAR MAGNETISMO · 115 CR", "effect_text": "O magnetismo reduz o poder inimigo em 15%.", "credit_cost": 115, "power_mult": 0.85, "result": "O magnetismo segurou a equipa e todo o mobiliário metálico à mesma parede."},
		{"id": "inventory_every_falling_object", "name": "INVENTARIAR CADA OBJETO", "effect_text": "+165s de caça e +20% XP.", "duration_add": 165.0, "xp_mult": 1.20, "result": "O inventário terminou quando deixaram de concordar sobre a direção de baixo."},
		{"id": "sell_zero_gravity_repairs", "name": "VENDER REPARAÇÕES SEM GRAVIDADE", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "Os clientes pagaram extra para ver os mecânicos perderem as ferramentas."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Continuidade Remendada", "description": "Faz o impacto parecer inevitável depois de acontecer."},
		{"name": "Projetor de Gravidade Contrafeita", "description": "Atrai alvos sem apresentar certificado de autenticidade."},
		{"name": "Lançador de Reboque Dimensional", "description": "Puxa o campo de batalha para uma realidade mais conveniente."},
		{"name": "Canhão de Singularidade Polida", "description": "Engole imperfeições e devolve apenas a fatura."},
	],
	"armor": [
		{"name": "Colete de Causa Tardia", "description": "Inventa uma explicação defensiva depois de receber o golpe."},
		{"name": "Traje de Constante Duplicada", "description": "Mantém uma segunda lei física disponível como peça suplente."},
		{"name": "Armadura de Horizonte Desmontado", "description": "Remove a fronteira antes de o ataque conseguir atravessá-la."},
		{"name": "Uniforme de Garantia Anulada", "description": "Declara todos os danos consequência de utilização indevida."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Arnês de Agrafos Causais", "description": "Mantém acontecimentos incompatíveis presos na ordem certa."},
		{"name": "Módulo de Causalidade sem Licença", "description": "Produz consequências sem esperar pela autorização da causa."},
		{"name": "Estrutura de Reboque Universal", "description": "Transporta dimensões avariadas sem perguntar quem vive nelas."},
		{"name": "Arnês de Peças Genéricas", "description": "Substitui componentes cósmicos por equivalentes quase compatíveis."},
	],
}

const PACK := {"id": "oficina_realidades_defeituosas", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
