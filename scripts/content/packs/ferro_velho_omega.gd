class_name FerroVelhoOmegaContent
extends RefCounted

const PLANET := {
	"id": "ferro_velho_omega",
	"name": "Ferro-Velho Ômega",
	"unlock_level": 13,
	"travel_duration": 960.0,
	"subtitle": "Tudo tem dono. Principalmente o lixo.",
	"description": "Um planeta-oficina montado com luas usadas, garantias vencidas e robôs que cobram estacionamento por eixo.",
	"accent": "#ff9f43",
	"unlock_after": "micelia_404",
	"completion_text": "O aterro deixou de colecionar civilizações. Agora aceita apenas recicláveis e opiniões com nota fiscal.",
}

const TARGET_BOLT_COLLECTOR := {
	"id": "bolt_collector", "planet_id": "ferro_velho_omega", "name": "Cobrador Rebite",
	"title": "Agente de penhora magnética", "description": "Confiscou todos os parafusos de um bairro por atraso de três arruelas.", "emoji": "◆",
	"power": 69, "defense": 30, "health": 470, "duration": 32, "credits": 540, "xp": 480, "rank": 3, "chapter_tier": 0,
	"attacks": ["Cobrança Magnética", "Multa de Rebite", "Penhora de Parafusos"],
}

const TARGET_DOCTOR_PATCHWORK := {
	"id": "doctor_patchwork", "planet_id": "ferro_velho_omega", "name": "Doutora Gambiarra",
	"title": "Cirurgiã de naves sem licença", "description": "Transplantou um motor de ônibus numa fragata e cobrou pelo segundo coração.", "emoji": "+",
	"power": 75, "defense": 33, "health": 520, "duration": 34, "credits": 604, "xp": 532, "rank": 3, "chapter_tier": 1,
	"attacks": ["Bisturi de Solda", "Anestesia de Bateria", "Alta Contraindicação"],
}

const TARGET_CRANE_KING := {
	"id": "crane_king", "planet_id": "ferro_velho_omega", "name": "Rei Guindaste",
	"title": "Monarca da sucata prensada", "description": "Coroou a si mesmo com uma calota e anexou seis depósitos por decreto hidráulico.", "emoji": "♜",
	"power": 82, "defense": 36, "health": 580, "duration": 36, "credits": 676, "xp": 594, "rank": 3, "chapter_tier": 2,
	"attacks": ["Decreto Hidráulico", "Coroa de Calota", "Prensa Real"],
}

const TARGET_OMEGA_JUNKYARD := {
	"id": "omega_junkyard", "planet_id": "ferro_velho_omega", "name": "Ômega, o Ferro-Velho",
	"title": "Aterro senciente de civilizações", "description": "Arquiva planetas inteiros na categoria “peças talvez úteis” e perdeu o formulário de devolução.", "emoji": "Ω",
	"power": 90, "defense": 40, "health": 680, "duration": 40, "credits": 792, "xp": 690, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Compactação Planetária", "Inventário Infinito", "Garantia do Fim"],
}

const TARGETS := [TARGET_BOLT_COLLECTOR, TARGET_DOCTOR_PATCHWORK, TARGET_CRANE_KING, TARGET_OMEGA_JUNKYARD]

const EVENT_MAGNETIC_STORM := {
	"id": "magnetic_storm", "planet_id": "ferro_velho_omega", "symbol": "CLANG", "title": "Tempestade de Ímãs",
	"description": "Uma frente magnética arrancou placas, talheres e três luas decorativas da rota.", "color": "#ff9f43",
	"choices": [
		{"id": "rent_demagnetizer", "name": "ALUGAR DESMAGNETIZADOR · 18 CR", "effect_text": "O campo expõe juntas metálicas: -20% defesa do alvo.", "credit_cost": 18, "defense_mult": 0.80, "result": "O aparelho desmagnetizou a rota e apagou duas fitas muito importantes."},
		{"id": "follow_debris", "name": "SEGUIR OS DESTROÇOS", "effect_text": "+60s de caça e +20% XP em arqueologia automotiva.", "duration_add": 60.0, "xp_mult": 1.20, "result": "Os destroços formaram uma seta, um imposto e depois outra seta."},
		{"id": "ride_magnetism", "name": "SURFAR O CAMPO", "effect_text": "+12% poder inimigo, mas +22% créditos pelo risco metálico.", "power_mult": 1.12, "credits_mult": 1.22, "result": "A manobra atraiu o alvo, a recompensa e todo o conteúdo de uma oficina."},
	],
}

const EVENT_WARRANTY_GHOST := {
	"id": "warranty_ghost", "planet_id": "ferro_velho_omega", "symbol": "VENCEU", "title": "Fantasma da Garantia",
	"description": "Um holograma insiste que a perseguição deixou de ter cobertura há quatro quilômetros.", "color": "#ffd166",
	"choices": [
		{"id": "extend_warranty", "name": "ESTENDER GARANTIA · 20 CR", "effect_text": "Assistência autorizada reduz 12% do poder inimigo.", "credit_cost": 20, "power_mult": 0.88, "result": "A garantia cobre impactos, lasers e uma quantidade juridicamente vaga de explosões."},
		{"id": "read_fine_print", "name": "LER AS LETRAS MIÚDAS", "effect_text": "+45s de caça e +18% XP em direito de oficina.", "duration_add": 45.0, "xp_mult": 1.18, "result": "Na cláusula 9001, o alvo aparece listado como defeito de fabricação."},
		{"id": "void_it", "name": "VIOLAR O LACRE", "effect_text": "+10% vida inimiga, mas +20% créditos sem cobertura.", "health_mult": 1.10, "credits_mult": 1.20, "result": "A garantia evaporou. O contratante chamou isso de bônus de autonomia."},
	],
}

const EVENTS := [EVENT_MAGNETIC_STORM, EVENT_WARRANTY_GHOST]

const ITEMS := {
	"weapon": [
		{"name": "Canhão de Peças Soltas", "description": "Cada disparo vem com um parafuso extra e nenhuma explicação."},
		{"name": "Chave de Impacto Diplomática", "description": "Aperta acordos e afrouxa mandíbulas na mesma rotação."},
		{"name": "Carabina de Rebite Quântico", "description": "Fixa o alvo simultaneamente em duas cenas de crime."},
		{"name": "Prensa Portátil de Argumentos", "description": "Compacta objeções até caberem no coldre."},
	],
	"armor": [
		{"name": "Colete de Placas Descombinadas", "description": "Nenhuma placa combina. Todas discordam do projétil."},
		{"name": "Macacão de Mecânico Orbital", "description": "Tem bolsos para ferramentas, lanches e uma lua pequena."},
		{"name": "Armadura de Para-Choques", "description": "Absorve colisões e avaliações negativas de oficina."},
		{"name": "Manto de Garantias Vencidas", "description": "Não cobre dano algum, mas intimida o setor jurídico."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Para-Choque", "description": "Sobreviveu a três naves e a uma inspeção de oficina."},
		{"name": "Máscara de Solda Diplomática", "description": "Escurece clarões e negociações excessivamente honestas."},
		{"name": "Elmo de Peças Descombinadas", "description": "Cada placa discorda do impacto numa frequência diferente."},
		{"name": "Viseira de Garantia Vencida", "description": "Não cobre acidentes, mas registra todos em alta definição."},
	],
	"gloves": [
		{"name": "Manoplas de Chave Pneumática", "description": "Apertam parafusos, acordos e suspeitos na mesma pressão."},
		{"name": "Luvas de Rebite Quântico", "description": "Seguram a peça aqui e numa oficina concorrente."},
		{"name": "Garras de Separação Magnética", "description": "Atraem metal útil e repelem notas fiscais."},
		{"name": "Dedais de Sucata Industrial", "description": "Dez pequenos escudos com procedência criativa."},
	],
	"boots": [
		{"name": "Botas de Pistão Recondicionado", "description": "Cada passo vem com torque e uma peça sobrando."},
		{"name": "Coturnos de Esteira Lunar", "description": "Foram pneus numa vida anterior e ainda sentem saudades."},
		{"name": "Propulsores de Calcanhar Usados", "description": "Decolam sempre. A direção continua opcional."},
		{"name": "Botas de Aterragem Fiscal", "description": "Amortecem quedas e parcelam o impacto em doze vezes."},
	],
}

const PACK := {
	"id": "ferro_velho_omega",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
