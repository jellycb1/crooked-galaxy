class_name CaldeiraGarantiaContent
extends RefCounted

const PLANET := {
	"id": "caldeira_garantia",
	"name": "Caldeira de Garantia",
	"unlock_level": 60,
	"travel_duration": 2160.0,
	"subtitle": "A garantia cobre calor. Lava é considerada uso indevido.",
	"description": "Um mundo vulcânico industrial onde erupções batem ponto, rios de magma são concessionados e cada placa de obsidiana vence noventa dias depois da compra.",
	"accent": "#ff7043",
	"unlock_after": "verdantia_patenteada",
	"completion_text": "O Monte Hipoteca foi executado por dívida geológica. A lava continua a correr, agora sem taxa de administração.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_ASH_INSPECTOR := {
	"id": "ash_inspector", "planet_id": "caldeira_garantia", "name": "Fiscal de Cinzas",
	"title": "Auditor das emissões não faturadas", "description": "Pesa cada nuvem vulcânica e multa pulmões que retêm partículas sem declarar.", "emoji": "▧",
	"power": 290, "loot_power": 274, "defense": 130, "health": 2400, "duration": 119, "credits": 5260, "xp": 3790, "rank": 3, "chapter_tier": 0,
	"attacks": ["Auto de Fuligem", "Penhora Respiratória", "Nuvem Tributável"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_FOUNDRY_SALAMANDER := {
	"id": "foundry_salamander", "planet_id": "caldeira_garantia", "name": "Salamandra de Fundição",
	"title": "Capataz dos altos-fornos migratórios", "description": "Transporta metal líquido nas costas e desconta do salário qualquer queimadura de terceiros.", "emoji": "≋",
	"power": 300, "loot_power": 283, "defense": 134, "health": 2500, "duration": 126, "credits": 5830, "xp": 4140, "rank": 3, "chapter_tier": 1,
	"attacks": ["Cauda de Escória", "Turno Incandescente", "Fundição Imediata"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_OBSIDIAN_MAGNATE := {
	"id": "obsidian_magnate", "planet_id": "caldeira_garantia", "name": "Magnata Obsidiana",
	"title": "Monopolista do vidro vulcânico", "description": "Vende reflexos premium, compra crateras falidas e parte concorrentes com arestas contratuais.", "emoji": "◆",
	"power": 302, "loot_power": 285, "defense": 132, "health": 2460, "duration": 133, "credits": 6480, "xp": 4540, "rank": 3, "chapter_tier": 2,
	"attacks": ["Estilhaço de Mercado", "Reflexo Hostil", "Aquisição Cortante"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_MORTGAGE_VOLCANO := {
	"id": "mortgage_volcano", "planet_id": "caldeira_garantia", "name": "Monte Hipoteca",
	"title": "Vulcão senciente de capital fechado", "description": "Transformou pressão tectónica em juros compostos e ameaça executar o próprio horizonte.", "emoji": "▲",
	"power": 324, "loot_power": 306, "defense": 144, "health": 2780, "duration": 141, "credits": 7260, "xp": 5010, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Erupção Executiva", "Juros Piroclásticos", "Falência da Crosta"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_ASH_INSPECTOR, TARGET_FOUNDRY_SALAMANDER, TARGET_OBSIDIAN_MAGNATE, TARGET_MORTGAGE_VOLCANO]

const EVENT_ERUPTION_TIMECLOCK := {
	"id": "eruption_timeclock", "planet_id": "caldeira_garantia", "symbol": "TURNO 06", "title": "Ponto de Erupção",
	"description": "Uma sirene exige que toda atividade vulcânica registe entrada antes de lançar cinzas no espaço aéreo.", "color": "#ff7043",
	"choices": [
		{"id": "bribe_shift_foreman", "name": "SUBORNAR O CAPATAZ · 39 CR", "effect_text": "O turno abre a blindagem térmica: -22% defesa inimiga.", "credit_cost": 39, "defense_mult": 0.78, "result": "O capataz carimbou a lava como intervalo regulamentar."},
		{"id": "audit_lava_hours", "name": "AUDITAR HORAS DE LAVA", "effect_text": "+65s de caça e +22% XP em contabilidade tectónica.", "duration_add": 65.0, "xp_mult": 1.22, "result": "O vulcão tinha horas extra suficientes para reformar uma lua pequena."},
		{"id": "trigger_early_shift", "name": "ACIONAR O TURNO CEDO", "effect_text": "+13% poder inimigo, mas +25% créditos de produção urgente.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A erupção chegou cedo. O prémio de pontualidade chegou derretido."},
	],
}

const EVENT_MAGMA_CONCESSION := {
	"id": "magma_concession", "planet_id": "caldeira_garantia", "symbol": "KM 666", "title": "Concessão de Magma",
	"description": "Uma portagem flutuante cobra por quilómetro de lava, eixo da nave e nível de pânico declarado.", "color": "#ffc857",
	"choices": [
		{"id": "buy_heat_waiver", "name": "COMPRAR ISENÇÃO TÉRMICA · 40 CR", "effect_text": "A licença desliga os fornos de apoio: -15% poder do alvo.", "credit_cost": 40, "power_mult": 0.85, "result": "A isenção permite calor ilimitado em letras muito pequenas."},
		{"id": "follow_cooling_lane", "name": "SEGUIR A FAIXA DE ARREFECIMENTO", "effect_text": "+55s de caça e +20% XP em logística ígnea.", "duration_add": 55.0, "xp_mult": 1.20, "result": "A faixa arrefeceu. A papelada solidificou numa ponte útil."},
		{"id": "surf_magma_current", "name": "SURFAR A CORRENTE DE MAGMA", "effect_text": "+12% vida inimiga, mas +23% créditos de risco vulcânico.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A nave ganhou velocidade, fuligem e uma garantia imediatamente anulada."},
	],
}

const EVENTS := [EVENT_ERUPTION_TIMECLOCK, EVENT_MAGMA_CONCESSION]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Escória Comprimida", "description": "Dispara resíduos industriais antes que alguém descubra onde os depositar."},
		{"name": "Lança-Lava de Responsabilidade Zero", "description": "Aquece o alvo e arrefece qualquer tentativa de reembolso."},
		{"name": "Martelo Sísmico de Cobrança", "description": "Cada impacto abre uma falha e fecha uma conta vencida."},
		{"name": "Canhão de Obsidiana Fracionada", "description": "Divide vidro vulcânico em prestações afiadas e não reembolsáveis."},
	],
	"armor": [
		{"name": "Casaco de Amianto Certificado", "description": "O certificado garante segurança desde que nunca seja lido de perto."},
		{"name": "Traje de Basalto Flexível", "description": "Dobra sob pressão, ao contrário do departamento de garantias."},
		{"name": "Colete de Escória Reativa", "description": "Endurece com impactos e amolece perante inspeções surpresa."},
		{"name": "Armadura de Alto-Forno Executivo", "description": "Inclui refrigeração, porta-copos e saída de emergência opcional."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Pinça Magmática", "description": "Seguram metal líquido, contratos quentes e decisões piores."},
		{"name": "Manoplas de Obsidiana Laminada", "description": "Têm arestas suficientes para cortar custos e dedos."},
		{"name": "Punhos de Arrefecimento Sindical", "description": "Pausam o calor dentro do horário previsto no acordo coletivo."},
		{"name": "Garras de Basalto Tectónico", "description": "Agarram a crosta quando o planeta tenta fugir à prestação."},
	],
}

const PACK := {
	"id": "caldeira_garantia",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
