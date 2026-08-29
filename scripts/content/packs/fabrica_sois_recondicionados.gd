class_name FabricaSoisRecondicionadosContent
extends RefCounted

const PLANET := {
	"id": "fabrica_sois_recondicionados",
	"name": "Fábrica de Sóis Recondicionados",
	"unlock_level": 180,
	"travel_duration": 5040.0,
	"subtitle": "Pouco uso. Uma explosão anterior.",
	"description": "Uma fundição do tamanho de um sistema solar desmonta estrelas expiradas, repinta o brilho e revende cada núcleo com uma garantia de três amanheceres.",
	"accent": "#ff8a47",
	"unlock_after": "bolsa_luas_fracionadas",
	"completion_text": "O Diretor da Segunda Aurora foi capturado e todos os sóis vendidos esta semana entraram em revisão. A fábrica garante que a escuridão temporária é uma característica premium.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{
		"id": "counterfeit_glow_inspector", "planet_id": "fabrica_sois_recondicionados", "name": "Inspetora de Brilho Adulterado",
		"title": "Certifica luz diluída como quase nova", "description": "Mistura claridade usada com néon barato, carimba cada raio e apreende sombras que façam perguntas.", "emoji": "☼",
		"power": 1557, "loot_power": 1465, "defense": 708, "health": 23920, "duration": 732, "credits": 510000, "xp": 349000, "rank": 3, "chapter_tier": 0,
		"attacks": ["Carimbo Luminoso", "Claridade Diluída", "Apreensão de Sombra"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "stellar_core_smuggler", "planet_id": "fabrica_sois_recondicionados", "name": "Contrabandista de Núcleos Estelares",
		"title": "Transporta milhões de graus sem declarar", "description": "Esconde pequenos sóis em caixas térmicas, falsifica temperaturas e vende fusão nuclear por peso.", "emoji": "⊙",
		"power": 1592, "loot_power": 1498, "defense": 724, "health": 24450, "duration": 749, "credits": 545000, "xp": 373000, "rank": 3, "chapter_tier": 1,
		"attacks": ["Núcleo Não Declarado", "Fusão por Quilo", "Temperatura Falsa"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "solar_warranty_technician", "planet_id": "fabrica_sois_recondicionados", "name": "Técnico de Garantia Solar",
		"title": "Declara cada supernova desgaste normal", "description": "Chega depois da explosão, encontra uma cláusula microscópica e cobra deslocação a todos os planetas atingidos.", "emoji": "✹",
		"power": 1628, "loot_power": 1532, "defense": 740, "health": 24990, "duration": 766, "credits": 583000, "xp": 399000, "rank": 3, "chapter_tier": 2,
		"attacks": ["Cláusula de Supernova", "Desgaste Normal", "Taxa de Deslocação"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "second_dawn_director", "planet_id": "fabrica_sois_recondicionados", "name": "Diretor da Segunda Aurora",
		"title": "Vende o mesmo amanhecer duas vezes", "description": "Comanda linhas de montagem de estrelas, desliga constelações concorrentes e assina garantias com tinta fotossensível.", "emoji": "✺",
		"power": 1702, "loot_power": 1601, "defense": 774, "health": 26770, "duration": 789, "credits": 625000, "xp": 429000, "rank": 3, "chapter_tier": 3, "boss": true,
		"attacks": ["Segunda Aurora", "Apagão da Concorrência", "Garantia Fotossensível"], "visual_delivery": "pending_user_asset",
	},
]

const EVENTS := [
	{
		"id": "star_recall_notice", "planet_id": "fabrica_sois_recondicionados", "symbol": "RECALL ☼", "title": "Recolha Urgente de Estrela",
		"description": "Um sol recondicionado começa a piscar um código de avaria e a fábrica exige devolução na embalagem original.", "color": "#ff8a47",
		"choices": [
			{"id": "buy_heatproof_receipt", "name": "COMPRAR RECIBO TÉRMICO · 87 CR", "effect_text": "O recibo reduz a defesa inimiga em 22%.", "credit_cost": 87, "defense_mult": 0.78, "result": "O recibo sobreviveu ao sol; a garantia não."},
			{"id": "find_original_star_box", "name": "PROCURAR A CAIXA ORIGINAL", "effect_text": "+125s de caça e +22% XP.", "duration_add": 125.0, "xp_mult": 1.22, "result": "A caixa dizia guardar longe da luz direta."},
			{"id": "keep_the_defective_sun", "name": "FICAR COM O SOL DEFEITUOSO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O defeito produziu três pores do sol por dia e uma conta enorme."},
		],
	},
	{
		"id": "industrial_light_leak", "planet_id": "fabrica_sois_recondicionados", "symbol": "LUZ 400%", "title": "Fuga de Luz Industrial",
		"description": "Um contentor rachado inunda o corredor com quatro amanheceres e revela todas as etiquetas de preço escondidas.", "color": "#ffd166",
		"choices": [
			{"id": "buy_eclipse_screen", "name": "COMPRAR ECRÃ DE ECLIPSE · 88 CR", "effect_text": "O eclipse reduz o poder inimigo em 15%.", "credit_cost": 88, "power_mult": 0.85, "result": "O ecrã bloqueou a luz e acrescentou uma taxa de noite artificial."},
			{"id": "catalog_every_ray", "name": "CATALOGAR CADA RAIO", "effect_text": "+115s de caça e +20% XP.", "duration_add": 115.0, "xp_mult": 1.20, "result": "O último raio recusou preencher o formulário de saída."},
			{"id": "sell_the_extra_sunrise", "name": "VENDER A AURORA EXTRA", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A aurora foi vendida a um planeta onde ainda era ontem."},
		],
	},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Brilho Adulterado", "description": "Dispara luz certificada como suficientemente letal."},
		{"name": "Rifle de Núcleo Não Declarado", "description": "Transporta uma pequena infração estelar em cada câmara."},
		{"name": "Lançador de Cláusulas de Supernova", "description": "Explode apenas fora da cobertura contratual."},
		{"name": "Canhão da Segunda Aurora", "description": "Acerta novamente antes de o primeiro disparo anoitecer."},
	],
	"armor": [
		{"name": "Colete de Claridade Diluída", "description": "Reflete uma percentagem não especificada do impacto."},
		{"name": "Traje de Contrabando Térmico", "description": "Esconde temperaturas proibidas nos bolsos interiores."},
		{"name": "Armadura de Garantia Solar", "description": "Exclui danos, explosões e utilização sob qualquer estrela."},
		{"name": "Uniforme da Segunda Aurora", "description": "Permanece impecável até ao próximo amanhecer faturado."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Rig de Certificação Luminosa", "description": "Mede o brilho e arredonda sempre a favor da fábrica."},
		{"name": "Arnês de Núcleo Contrabandeado", "description": "Distribui calor ilegal por compartimentos falsos."},
		{"name": "Rig de Garantia de Supernova", "description": "Imprime exclusões antes de cada explosão."},
		{"name": "Arnês da Segunda Aurora", "description": "Recarrega ao nascer do sol, incluindo repetições pagas."},
	],
}

const PACK := {"id": "fabrica_sois_recondicionados", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
