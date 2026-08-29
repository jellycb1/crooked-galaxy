class_name ClinicaPlanetasDescontinuadosContent
extends RefCounted

const PLANET := {
	"id": "clinica_planetas_descontinuados",
	"name": "Clínica de Planetas Descontinuados",
	"unlock_level": 190,
	"travel_duration": 5280.0,
	"subtitle": "Aceitamos mundos fora de garantia.",
	"description": "Uma clínica orbital reboca planetas avariados, sutura continentes e substitui oceanos enquanto seguradoras discutem se a extinção era uma condição preexistente.",
	"accent": "#69e0c1",
	"unlock_after": "fabrica_sois_recondicionados",
	"completion_text": "A Diretora de Alta Planetária recebeu alta contra a própria vontade. A clínica reabriu a lista de espera e recomendou repouso absoluto a três sistemas solares.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{
		"id": "tectonic_triage_nurse", "planet_id": "clinica_planetas_descontinuados", "name": "Enfermeira de Triagem Tectónica",
		"title": "Classifica terramotos por ordem de chegada", "description": "Mede febres vulcânicas, distribui placas tectónicas numeradas e manda continentes partidos aguardar sentados.", "emoji": "✚",
		"power": 1740, "loot_power": 1637, "defense": 792, "health": 27340, "duration": 808, "credits": 668000, "xp": 459000, "rank": 3, "chapter_tier": 0,
		"attacks": ["Triagem Tectónica", "Placa Numerada", "Febre Vulcânica"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "continental_transplant_surgeon", "planet_id": "clinica_planetas_descontinuados", "name": "Cirurgião de Transplante Continental",
		"title": "Instala massas terrestres sem verificar compatibilidade", "description": "Costura continentes usados, troca polos magnéticos e deixa arquipélagos inteiros dentro do paciente.", "emoji": "⌁",
		"power": 1778, "loot_power": 1673, "defense": 809, "health": 27920, "duration": 826, "credits": 714000, "xp": 489000, "rank": 3, "chapter_tier": 1,
		"attacks": ["Sutura Continental", "Troca de Polo", "Arquipélago Esquecido"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "extinction_claim_adjuster", "planet_id": "clinica_planetas_descontinuados", "name": "Perito de Sinistros de Extinção",
		"title": "Declara cada apocalipse parcialmente coberto", "description": "Inspeciona fósseis, desvaloriza civilizações perdidas e encontra sempre um meteorito excluído na apólice.", "emoji": "▧",
		"power": 1817, "loot_power": 1710, "defense": 827, "health": 28520, "duration": 844, "credits": 764000, "xp": 522000, "rank": 3, "chapter_tier": 2,
		"attacks": ["Franquia de Extinção", "Meteorito Excluído", "Perda Desvalorizada"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "planetary_discharge_director", "planet_id": "clinica_planetas_descontinuados", "name": "Diretora de Alta Planetária",
		"title": "Devolve mundos ainda ligados às máquinas", "description": "Assina altas prematuras, cobra cada órbita ocupada e remove atmosferas para libertar camas depressa.", "emoji": "◎",
		"power": 1896, "loot_power": 1784, "defense": 863, "health": 30430, "duration": 868, "credits": 819000, "xp": 559000, "rank": 3, "chapter_tier": 3, "boss": true,
		"attacks": ["Alta Prematura", "Cobrança por Órbita", "Remoção de Atmosfera"], "visual_delivery": "pending_user_asset",
	},
]

const EVENTS := [
	{
		"id": "continental_rejection", "planet_id": "clinica_planetas_descontinuados", "symbol": "TIPO PANGEIA", "title": "Rejeição de Transplante Continental",
		"description": "Um planeta recém-operado rejeita o novo continente e começa a empurrá-lo para fora da própria gravidade.", "color": "#69e0c1",
		"choices": [
			{"id": "buy_compatibility_scan", "name": "COMPRAR EXAME · 91 CR", "effect_text": "O exame reduz a defesa inimiga em 22%.", "credit_cost": 91, "defense_mult": 0.78, "result": "O continente era compatível com outro hemisfério."},
			{"id": "stitch_every_coast", "name": "SUTURAR CADA COSTA", "effect_text": "+130s de caça e +22% XP.", "duration_add": 130.0, "xp_mult": 1.22, "result": "A última ilha pediu anestesia quando já estava cosida."},
			{"id": "sell_the_rejected_land", "name": "VENDER A TERRA REJEITADA", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A massa terrestre foi vendida como lote com vista para dois oceanos."},
		],
	},
	{
		"id": "moon_waiting_room_overflow", "planet_id": "clinica_planetas_descontinuados", "symbol": "SENHA 4 002", "title": "Lotação na Sala de Espera Lunar",
		"description": "Quarenta luas aguardam consulta, trocam de órbita por impaciência e confundem todas as marés da clínica.", "color": "#c8d6e5",
		"choices": [
			{"id": "buy_priority_orbit", "name": "COMPRAR ÓRBITA PRIORITÁRIA · 92 CR", "effect_text": "A prioridade reduz o poder inimigo em 15%.", "credit_cost": 92, "power_mult": 0.85, "result": "A órbita prioritária tinha apenas vinte e nove luas à frente."},
			{"id": "reissue_every_ticket", "name": "REEMITIR CADA SENHA", "effect_text": "+120s de caça e +20% XP.", "duration_add": 120.0, "xp_mult": 1.20, "result": "A lua número um já tinha completado outra volta."},
			{"id": "charge_for_extra_orbits", "name": "COBRAR ÓRBITAS EXTRA", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "As luas pagaram e adicionaram a clínica à própria gravidade."},
		],
	},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Triagem Tectónica", "description": "Classifica o impacto antes de abrir a cratera."},
		{"name": "Rifle de Sutura Continental", "description": "Fecha fronteiras com pontos de alta pressão."},
		{"name": "Lançador de Meteoritos Excluídos", "description": "Entrega impactos que nenhuma apólice reconhece."},
		{"name": "Canhão de Alta Planetária", "description": "Remove o alvo da lista de pacientes ativos."},
	],
	"armor": [
		{"name": "Colete de Placas Numeradas", "description": "Distribui cada golpe pela fila tectónica."},
		{"name": "Traje de Transplante Continental", "description": "Aceita quase qualquer massa terrestre doadora."},
		{"name": "Armadura de Franquia de Extinção", "description": "Só começa a proteger depois do primeiro apocalipse."},
		{"name": "Uniforme de Alta Prematura", "description": "Parece saudável o suficiente para libertar uma cama."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Implante de Triagem Tectónica", "description": "Prioriza ameaças segundo uma escala que muda a cada tremor."},
		{"name": "Nódulo de Compatibilidade Continental", "description": "Convence o corpo de que qualquer território sempre esteve ali."},
		{"name": "Implante de Cobertura de Extinção", "description": "Recorda apenas os desastres incluídos na apólice."},
		{"name": "Nódulo de Alta Planetária", "description": "Declara estabilidade clínica antes de terminar o diagnóstico."},
	],
}

const PACK := {"id": "clinica_planetas_descontinuados", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
