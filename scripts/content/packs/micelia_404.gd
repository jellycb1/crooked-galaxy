class_name Micelia404Content
extends RefCounted

const PLANET := {
	"id": "micelia_404",
	"name": "Micélia 404",
	"unlock_level": 8,
	"travel_duration": 720.0,
	"subtitle": "Tudo cresce. Principalmente as taxas.",
	"description": "Uma rede fúngica planetária onde prédios brotam, calçadas respiram e todo esporo tem cadastro.",
	"accent": "#c7f464",
	"unlock_after": "congelaria_sa",
	"completion_text": "A rede micelial trocou de administração. Os cogumelos exigem eleições úmidas.",
}

const TARGET_LANDLORD_SPORE := {
	"id": "landlord_spore", "planet_id": "micelia_404", "name": "Síndico Esporão",
	"title": "Administrador do condomínio micelial", "description": "Cobrou aluguel de cada raiz e instalou catracas nas trilhas de formigas.", "emoji": "♣",
	"power": 47, "loot_power": 44, "defense": 20, "health": 340, "duration": 22, "credits": 304, "xp": 282, "rank": 3, "chapter_tier": 0,
	"attacks": ["Boleto de Esporos", "Assembleia Venenosa", "Taxa de Umidade"],
}

const TARGET_COUNTESS_TRUFFLE := {
	"id": "countess_truffle", "planet_id": "micelia_404", "name": "Condessa Trufa",
	"title": "Banqueira de raízes offshore", "description": "Escondeu fortunas em paraísos fiscais subterrâneos e declarou tudo como adubo.", "emoji": "●",
	"power": 58, "loot_power": 50, "defense": 24, "health": 445, "duration": 24, "credits": 346, "xp": 320, "rank": 3, "chapter_tier": 1,
	"attacks": ["Juros Compostáveis", "Hipoteca de Raízes", "Perfume Tóxico Premium"],
}

const TARGET_CAPTAIN_CHLOROPHYLL := {
	"id": "captain_chlorophyll", "planet_id": "micelia_404", "name": "Capitão Clorofila",
	"title": "Pirata de fotossíntese patenteada", "description": "Desviou três sóis portáteis e vende luz solar em pacotes com anúncios.", "emoji": "☀",
	"power": 62, "loot_power": 56, "defense": 27, "health": 450, "duration": 26, "credits": 394, "xp": 360, "rank": 3, "chapter_tier": 2,
	"attacks": ["Sabre Fotônico Verde", "Canhão de Seiva", "Motim Fotossintético"],
}

const TARGET_MOTHER_MYCELIA := {
	"id": "mother_mycelia", "planet_id": "micelia_404", "name": "Mãe Micélia",
	"title": "Rede neural proprietária do planeta", "description": "Cobra assinatura por pensamento e vende seus sonhos para anunciantes de fertilizante.", "emoji": "◎",
	"power": 69, "loot_power": 64, "defense": 30, "health": 470, "duration": 30, "credits": 488, "xp": 438, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Consenso Micelial", "Pensamento Patrocinado", "Raiz do Sistema"],
}

const TARGETS := [TARGET_LANDLORD_SPORE, TARGET_COUNTESS_TRUFFLE, TARGET_CAPTAIN_CHLOROPHYLL, TARGET_MOTHER_MYCELIA]

const EVENT_SPORE_CUSTOMS := {
	"id": "spore_customs", "planet_id": "micelia_404", "symbol": "ACHOO", "title": "Alfândega de Esporos",
	"description": "Uma nuvem carimba cada molécula que entra. Seu pulmão está com documentação vencida.", "color": "#c7f464",
	"choices": [
		{"id": "buy_mask", "name": "COMPRAR MÁSCARA · 14 CR", "effect_text": "Filtros revelam o alvo entre a névoa: -20% defesa.", "credit_cost": 14, "defense_mult": 0.80, "result": "A máscara filtra esporos, desculpas e noventa por cento dos anúncios."},
		{"id": "declare_lungs", "name": "DECLARAR OS PULMÕES", "effect_text": "+60s de caça e +20% XP por preencher anatomia em triplicado.", "duration_add": 60.0, "xp_mult": 1.20, "result": "Seus pulmões agora constam como bagagem de mão regulamentar."},
		{"id": "sneeze_through", "name": "ESPIRRAR E ACELERAR", "effect_text": "+12% poder inimigo, mas +22% créditos por contaminação.", "power_mult": 1.12, "credits_mult": 1.22, "result": "O espirro abriu um túnel e fechou três restaurantes orgânicos."},
	],
}

const EVENT_SENTIENT_SHORTCUT := {
	"id": "sentient_shortcut", "planet_id": "micelia_404", "symbol": "OI?", "title": "Atalho Senciente",
	"description": "A trilha acordou, pediu seu nome e quer comissão sobre a recompensa.", "color": "#ff75c8",
	"choices": [
		{"id": "pay_path", "name": "PAGAR 16 CRÉDITOS", "effect_text": "A trilha entrega o alvo: -16% vida inimiga.", "credit_cost": 16, "health_mult": 0.84, "result": "O atalho aceitou pagamento, gorjeta e uma avaliação de cinco estrelas."},
		{"id": "tell_story", "name": "CONTAR UMA HISTÓRIA", "effect_text": "+45s de caça e +18% XP pela terapia vegetal.", "duration_add": 45.0, "xp_mult": 1.18, "result": "A trilha chorou seiva e indicou uma rota emocionalmente mais curta."},
		{"id": "step_on_it", "name": "PISAR FUNDO", "effect_text": "+10% poder inimigo, mas +20% créditos por danos botânicos.", "power_mult": 1.10, "credits_mult": 1.20, "result": "A trilha abriu um processo. O contratante cobriu os honorários."},
	],
}

const EVENTS := [EVENT_SPORE_CUSTOMS, EVENT_SENTIENT_SHORTCUT]

const ITEMS := {
	"weapon": [
		{"name": "Escopeta de Pólen Comprimido", "description": "Dispersa alergias, suspeitos e evidências."},
		{"name": "Lâmina de Micélio Nervoso", "description": "Treme perto do perigo e de saladas."},
		{"name": "Pistola Fotossintética", "description": "Recarrega ao sol e reclama em ambientes fechados."},
		{"name": "Canhão de Compostagem Rápida", "description": "Transforma cobertura em adubo antes do impacto."},
	],
	"armor": [
		{"name": "Casaco Antimofo Ofensivo", "description": "O mofo não entra. Ele manda representantes."},
		{"name": "Colete de Casca Reforçada", "description": "Orgânico, balístico e ligeiramente crocante."},
		{"name": "Poncho de Folha Carnívora", "description": "Protege o dono e belisca estranhos sem autorização."},
		{"name": "Armadura de Cortiça Orbital", "description": "Leve, renovável e péssima perto de saca-rolhas."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Elmo de Casca Micelial", "description": "Cresce uma camada nova sempre que a garantia expira."},
		{"name": "Viseira de Esporos Contábeis", "description": "Classifica pólen por risco fiscal e nível de alergia."},
		{"name": "Capuz Antifungo Ofensivo", "description": "Impede colônias e conversas úmidas de se instalarem."},
		{"name": "Coroa de Cogumelo Nervoso", "description": "Treme diante de emboscadas e molhos cremosos."},
	],
	"gloves": [
		{"name": "Luvas de Raiz Prensora", "description": "Agarram criminosos, paredes e recibos biodegradáveis."},
		{"name": "Manoplas de Casca Crocante", "description": "Orgânicas por fora, argumentos contundentes por dentro."},
		{"name": "Dedos de Micélio Assistido", "description": "Digitam contratos antes que a mão perceba o risco."},
		{"name": "Luvas de Pólen Aderente", "description": "Nada escapa. A limpeza também não."},
	],
}

const PACK := {
	"id": "micelia_404",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
