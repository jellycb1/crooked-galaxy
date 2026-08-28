class_name VerdantiaPatenteadaContent
extends RefCounted

const PLANET := {
	"id": "verdantia_patenteada",
	"name": "Verdântia Patenteada",
	"unlock_level": 50,
	"travel_duration": 1920.0,
	"subtitle": "A natureza encontra um caminho. A licença chega primeiro.",
	"description": "Uma selva bioluminescente onde corporações patentearam genes, raízes cobram portagem e toda migração precisa de autorização por escrito.",
	"accent": "#9be15d",
	"unlock_after": "arquivo_abissal_n9",
	"completion_text": "O Conselho-Raiz perdeu a patente da fotossíntese. A selva respirou sem subscrição pela primeira vez em três séculos.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_FRANCHISE_BEE := {
	"id": "franchise_bee", "planet_id": "verdantia_patenteada", "name": "Abelha de Franquia",
	"title": "Polinizadora com território exclusivo", "description": "Cobra royalties por flor visitada e confisca pólen sem selo de origem.", "emoji": "✿",
	"power": 250, "loot_power": 236, "defense": 112, "health": 1980, "duration": 94, "credits": 3410, "xp": 2550, "rank": 3, "chapter_tier": 0,
	"attacks": ["Ferroada de Royalties", "Pólen Sob Licença", "Cláusula da Colmeia"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_VINE_BROKER := {
	"id": "vine_broker", "planet_id": "verdantia_patenteada", "name": "Corretor Cipó",
	"title": "Intermediário do mercado de raízes", "description": "Vende atalhos pela copa, recompra o chão e executa garantias com trepadeiras carnívoras.", "emoji": "⌇",
	"power": 260, "loot_power": 245, "defense": 116, "health": 2070, "duration": 100, "credits": 3790, "xp": 2800, "rank": 3, "chapter_tier": 1,
	"attacks": ["Laço de Liquidação", "Juros Trepadores", "Execução da Raiz"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_PATENT_CHAMELEON := {
	"id": "patent_chameleon", "planet_id": "verdantia_patenteada", "name": "Camaleão de Patentes",
	"title": "Advogado de camuflagem proprietária", "description": "Registou todas as cores da selva e processa quem muda de tom sem consentimento.", "emoji": "◈",
	"power": 270, "loot_power": 255, "defense": 120, "health": 2180, "duration": 106, "credits": 4230, "xp": 3080, "rank": 3, "chapter_tier": 2,
	"attacks": ["Camuflagem Litigiosa", "Cessação Cromática", "Embargo Prismático"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ROOT_COUNCIL := {
	"id": "root_council", "planet_id": "verdantia_patenteada", "name": "Conselho-Raiz",
	"title": "Diretoria subterrânea da evolução", "description": "Uma assembleia vegetal milenar que vota por esporos e considera toda vida propriedade intelectual.", "emoji": "Ψ",
	"power": 282, "loot_power": 266, "defense": 126, "health": 2320, "duration": 113, "credits": 4770, "xp": 3420, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Decreto da Clorofila", "Aquisição Hostil do Solo", "Patente da Evolução"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_FRANCHISE_BEE, TARGET_VINE_BROKER, TARGET_PATENT_CHAMELEON, TARGET_ROOT_COUNCIL]

const EVENT_PHOTOSYNTHESIS_METER := {
	"id": "photosynthesis_meter", "planet_id": "verdantia_patenteada", "symbol": "LUZ/m²", "title": "Contador de Fotossíntese",
	"description": "Um girassol fiscal mede cada raio absorvido e ameaça cortar a luz por consumo não declarado.", "color": "#9be15d",
	"choices": [
		{"id": "rent_grow_light", "name": "ALUGAR LUZ DE CULTIVO · 35 CR", "effect_text": "A luz revela as placas orgânicas: -22% defesa inimiga.", "credit_cost": 35, "defense_mult": 0.78, "result": "A lâmpada veio com contador, contrato e uma sombra de cortesia."},
		{"id": "audit_canopy", "name": "AUDITAR A COPA", "effect_text": "+60s de caça e +22% XP em contabilidade solar.", "duration_add": 60.0, "xp_mult": 1.22, "result": "Cada folha apresentou recibo. Uma samambaia pediu revisão fiscal."},
		{"id": "cut_meter_vine", "name": "CORTAR O CIPÓ DO CONTADOR", "effect_text": "+12% poder inimigo, mas +24% créditos por energia recuperada.", "power_mult": 1.12, "credits_mult": 1.24, "result": "A selva ficou mais clara. O departamento jurídico germinou imediatamente."},
	],
}

const EVENT_MIGRATION_LICENSE := {
	"id": "migration_license", "planet_id": "verdantia_patenteada", "symbol": "ROTA B-17", "title": "Licença de Migração",
	"description": "Uma manada de herbívoros aguarda autorização para atravessar uma estrada que cresceu durante a noite.", "color": "#ffd166",
	"choices": [
		{"id": "forge_pollen_stamp", "name": "FORJAR SELO DE PÓLEN · 36 CR", "effect_text": "O selo desvia a patrulha genética: -15% poder do alvo.", "credit_cost": 36, "power_mult": 0.85, "result": "O selo cheirava a flores e fraude administrativa convincente."},
		{"id": "follow_herd", "name": "SEGUIR A MANADA", "effect_text": "+50s de caça e +20% XP em navegação migratória.", "duration_add": 50.0, "xp_mult": 1.20, "result": "A manada conhecia o caminho. Também conhecia sete atalhos e um sindicato."},
		{"id": "cross_carnivore_garden", "name": "ATRAVESSAR O JARDIM CARNÍVORO", "effect_text": "+12% vida inimiga, mas +22% créditos de perigo botânico.", "health_mult": 1.12, "credits_mult": 1.22, "result": "O jardim ficou alimentado. A nave ficou com menos duas antenas."},
	],
}

const EVENTS := [EVENT_PHOTOSYNTHESIS_METER, EVENT_MIGRATION_LICENSE]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Sementes Balísticas", "description": "Planta o projétil primeiro e faz a explosão germinar depois."},
		{"name": "Lança-Esporos de Cessação", "description": "Espalha alergias, liminares e uma névoa legalmente irritante."},
		{"name": "Arco de Fibra Clorofílica", "description": "Converte luz em tensão e tensão em correspondência hostil."},
		{"name": "Canhão de Néctar Pressurizado", "description": "Doce na entrada, devastador na saída e pegajoso em auditorias."},
	],
	"armor": [
		{"name": "Casaco de Casca Reforçada", "description": "Ganha um novo anel de proteção a cada processo sobrevivido."},
		{"name": "Traje de Folha Antibalística", "description": "Respira, regenera e exige rega depois de combate intenso."},
		{"name": "Colete de Quitina Franqueada", "description": "Resiste a impactos desde que as prestações da colmeia estejam pagas."},
		{"name": "Armadura do Sub-Bosque Executivo", "description": "Inclui camuflagem, irrigação e direito preferencial sobre a sombra."},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Raiz Contratual", "description": "Fixam-se ao solo até todas as cláusulas deixarem de tremer."},
		{"name": "Polainas de Salto Gafanhoto", "description": "Saltam muros, filas e pequenas restrições de zoneamento."},
		{"name": "Solas de Musgo Silencioso", "description": "Abafam passos e qualquer objeção que cresça pelo caminho."},
		{"name": "Grevas de Quitina Migratória", "description": "Percorrem continentes inteiros sem perder o recibo de origem."},
	],
}

const PACK := {
	"id": "verdantia_patenteada",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
