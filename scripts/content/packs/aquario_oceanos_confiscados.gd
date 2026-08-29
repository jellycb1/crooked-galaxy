class_name AquarioOceanosConfiscadosContent
extends RefCounted

const PLANET := {
	"id": "aquario_oceanos_confiscados", "name": "Aquário de Oceanos Confiscados", "unlock_level": 210, "travel_duration": 5760.0,
	"subtitle": "Cada mar tem dono. Os peixes ainda não sabem.",
	"description": "Uma estação transparente guarda oceanos apreendidos dentro de tanques orbitais, com recifes inteiros etiquetados como prova e leviatãs à espera do fim do processo.",
	"accent": "#42d9e8", "unlock_after": "correio_buracos_minhoca",
	"completion_text": "O Curador do Oceano Engarrafado perdeu a custódia das marés. Os tanques foram abertos, embora três oceanos tenham pedido para continuar em exposição.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "confiscated_reef_auctioneer", "planet_id": "aquario_oceanos_confiscados", "name": "Leiloeiro de Recifes Confiscados", "title": "Vende corais ainda ligados ao planeta", "description": "Divide recifes em lotes, acrescenta taxas de maré e aceita pérolas obtidas de forma suficientemente vaga.", "emoji": "⌁", "power": 2145, "loot_power": 2018, "defense": 977, "health": 35200, "duration": 970, "credits": 1160000, "xp": 791000, "rank": 3, "chapter_tier": 0, "attacks": ["Lote de Coral", "Taxa de Maré", "Martelo de Pérola"], "visual_delivery": "pending_user_asset"},
	{"id": "pocket_leviathan_biologist", "planet_id": "aquario_oceanos_confiscados", "name": "Bióloga de Leviatãs de Bolso", "title": "Miniaturiza monstros que recusam adoção", "description": "Cria criaturas abissais em frascos portáteis, ignora limites de crescimento e chama cada fuga de enriquecimento ambiental.", "emoji": "≋", "power": 2189, "loot_power": 2059, "defense": 997, "health": 35920, "duration": 990, "credits": 1235000, "xp": 846000, "rank": 3, "chapter_tier": 1, "attacks": ["Leviatã de Bolso", "Crescimento Súbito", "Fuga Educativa"], "visual_delivery": "pending_user_asset"},
	{"id": "orbital_submarine_privateer", "planet_id": "aquario_oceanos_confiscados", "name": "Corsário de Submarino Orbital", "title": "Navega águas que já não têm planeta", "description": "Pilota um submarino entre tanques, aborda aquários rivais e dispara torpedos que insistem em nadar no vácuo.", "emoji": "◒", "power": 2234, "loot_power": 2101, "defense": 1017, "health": 36650, "duration": 1010, "credits": 1315000, "xp": 905000, "rank": 3, "chapter_tier": 2, "attacks": ["Abordagem Submersa", "Torpedo de Vácuo", "Mergulho Orbital"], "visual_delivery": "pending_user_asset"},
	{"id": "bottled_ocean_curator", "planet_id": "aquario_oceanos_confiscados", "name": "Curador do Oceano Engarrafado", "title": "Cataloga marés como propriedade privada", "description": "Controla comportas planetárias, cobra entrada à chuva e mantém um oceano inteiro fechado para inventário anual.", "emoji": "◉", "power": 2323, "loot_power": 2185, "defense": 1058, "health": 38800, "duration": 1035, "credits": 1405000, "xp": 968000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Comporta Planetária", "Chuva com Bilhete", "Inventário das Marés"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "leviathan_song_noise_fine", "planet_id": "aquario_oceanos_confiscados", "symbol": "CANTO: 180 DB", "title": "Multa de Ruído do Leviatã", "description": "Um leviatã canta através de sete tanques e o segurança tenta multar qualquer pessoa com ouvidos.", "color": "#42d9e8", "choices": [
		{"id": "buy_acoustic_bubbles", "name": "COMPRAR BOLHAS · 98 CR", "effect_text": "As bolhas reduzem a defesa inimiga em 22%.", "credit_cost": 98, "defense_mult": 0.78, "result": "O canto ficou preso nas bolhas e exigiu uma audiência própria."},
		{"id": "record_the_full_song", "name": "GRAVAR O CANTO INTEIRO", "effect_text": "+140s de caça e +22% XP.", "duration_add": 140.0, "xp_mult": 1.22, "result": "A última nota chegou acompanhada por uma baleia muito menor."},
		{"id": "sell_concert_tickets", "name": "VENDER BILHETES", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O público pediu bis. O leviatã pediu advogado."},
	]},
	{"id": "cracked_ocean_tank", "planet_id": "aquario_oceanos_confiscados", "symbol": "FUGA: OCEANO", "title": "Tanque Oceânico Rachado", "description": "Uma fissura começa a despejar um oceano inteiro para o corredor de lembranças antes que alguém encontre a torneira.", "color": "#ffd166", "choices": [
		{"id": "buy_emergency_coral", "name": "COMPRAR CORAL · 99 CR", "effect_text": "O remendo reduz o poder inimigo em 15%.", "credit_cost": 99, "power_mult": 0.85, "result": "O coral tapou a fissura e apresentou uma fatura de crescimento."},
		{"id": "rescue_every_current", "name": "SALVAR CADA CORRENTE", "effect_text": "+130s de caça e +20% XP.", "duration_add": 130.0, "xp_mult": 1.20, "result": "Todas as correntes regressaram, exceto uma que pediu asilo."},
		{"id": "charge_for_indoor_beach", "name": "COBRAR PELA PRAIA", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A evacuação esgotou quando alguém anunciou espreguiçadeiras premium."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Lote de Coral", "description": "Leiloa cada disparo antes do impacto."},
		{"name": "Projetor de Leviatã de Bolso", "description": "Liberta algo demasiado grande para o carregador."},
		{"name": "Lançador de Torpedos de Vácuo", "description": "Convence munições de que o espaço é água muito seca."},
		{"name": "Canhão de Comporta Planetária", "description": "Abre uma maré onde não devia existir nenhuma."},
	],
	"armor": [
		{"name": "Colete de Recifes Confiscados", "description": "Protege com provas que ninguém pode legalmente remover."},
		{"name": "Traje de Crescimento Abissal", "description": "Expande sempre que o perigo deixa de caber."},
		{"name": "Armadura de Submarino Orbital", "description": "Mantém pressão interna mesmo sem oceano exterior."},
		{"name": "Uniforme do Curador das Marés", "description": "Classifica cada golpe como exposição temporária."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Leilão de Coral", "description": "Fecham negócios antes de alguém verificar o lote."},
		{"name": "Manoplas de Leviatã Portátil", "description": "Seguram monstros que ainda não sabem o seu tamanho."},
		{"name": "Luvas de Abordagem Submersa", "description": "Aderem a cascos no mar, no espaço e em tribunal."},
		{"name": "Manoplas do Oceano Engarrafado", "description": "Contêm pressão suficiente para negociar com uma maré."},
	],
}

const PACK := {"id": "aquario_oceanos_confiscados", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
