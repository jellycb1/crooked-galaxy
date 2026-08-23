class_name ContentDB
extends RefCounted


const PLANET := {
	"id": "dustball_prime",
	"name": "Dustball Prime",
	"subtitle": "A poeira entra em tudo. Inclusive nos contratos.",
	"accent": "#ffc857",
	"completion_text": "O prefeito foi afastado do cargo, da delegacia e do próprio cartório. A papelada continua foragida.",
}

const PLANETS := [
	PLANET,
	{
		"id": "congelaria_sa",
		"name": "Congelária S.A.",
		"subtitle": "Tudo abaixo de zero. Inclusive o atendimento.",
		"description": "Um frigorífico planetário privatizado, com geleiras, cubículos e multas por aquecimento.",
		"accent": "#72f1dd",
		"unlock_after": "dustball_prime",
		"completion_text": "A diretoria foi descongelada de suas funções. O termostato agora aceita votos e moedas.",
	},
	{
		"id": "micelia_404",
		"name": "Micélia 404",
		"subtitle": "Tudo cresce. Principalmente as taxas.",
		"description": "Uma rede fúngica planetária onde prédios brotam, calçadas respiram e todo esporo tem cadastro.",
		"accent": "#c7f464",
		"unlock_after": "congelaria_sa",
		"completion_text": "A rede micelial trocou de administração. Os cogumelos exigem eleições úmidas.",
	},
	{
		"id": "ferro_velho_omega",
		"name": "Ferro-Velho Ômega",
		"subtitle": "Tudo tem dono. Principalmente o lixo.",
		"description": "Um planeta-oficina montado com luas usadas, garantias vencidas e robôs que cobram estacionamento por eixo.",
		"accent": "#ff9f43",
		"unlock_after": "micelia_404",
		"completion_text": "O aterro deixou de colecionar civilizações. Agora aceita apenas recicláveis e opiniões com nota fiscal.",
	},
]

const TARGETS := [
	{
		"id": "gloop",
		"planet_id": "dustball_prime",
		"name": "Gloop, o Inconveniente",
		"title": "Ladrão de estacionamento orbital",
		"description": "Roubou 43 naves. Nenhuma era a nave certa.",
		"emoji": "👽",
		"power": 11,
		"defense": 4,
		"health": 70,
		"duration": 5,
		"credits": 38,
		"xp": 42,
		"rank": 0,
		"chapter_tier": 0,
		"attacks": ["Tapa Tentacular", "Cuspe de Formulário", "Raio Mal Estacionado"],
	},
	{
		"id": "baron_boom",
		"planet_id": "dustball_prime",
		"name": "Barão Boom",
		"title": "Nobreza autoproclamada e explosiva",
		"description": "Assina todos os documentos com dinamite. Até recibos.",
		"emoji": "💥",
		"power": 16,
		"defense": 6,
		"health": 96,
		"duration": 7,
		"credits": 58,
		"xp": 62,
		"rank": 1,
		"chapter_tier": 1,
		"attacks": ["Decreto Explosivo", "Imposto de Impacto", "Brasão-Bomba"],
	},
	{
		"id": "madame_vacuum",
		"planet_id": "dustball_prime",
		"name": "Madame Vácuo",
		"title": "Contrabandista de oxigênio premium",
		"description": "Vende ar engarrafado e cobra pela tampa separadamente.",
		"emoji": "🪐",
		"power": 23,
		"defense": 9,
		"health": 128,
		"duration": 9,
		"credits": 88,
		"xp": 90,
		"rank": 2,
		"chapter_tier": 2,
		"attacks": ["Vácuo Executivo", "Taxa de Respiração", "Sucção Premium"],
	},
	{
		"id": "mayor_gold_dust",
		"planet_id": "dustball_prime",
		"name": "Prefeito Pó-de-Ouro",
		"title": "Prefeito, xerife e dono do cartório",
		"description": "Emitiu o próprio mandado, carimbou como inocente e cobrou a taxa de leitura.",
		"emoji": "⭐",
		"power": 28,
		"defense": 11,
		"health": 160,
		"duration": 12,
		"credits": 138,
		"xp": 132,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Veto de Plasma", "Carimbo de Emergência", "Imposto sobre Esquiva"],
	},
	{
		"id": "auditor_frost",
		"planet_id": "congelaria_sa",
		"name": "Auditor Geada",
		"title": "Fiscal de aquecedores clandestinos",
		"description": "Confiscou o último cobertor do hemisfério sul por excesso de conforto.",
		"emoji": "❄",
		"power": 28,
		"defense": 11,
		"health": 165,
		"duration": 13,
		"credits": 146,
		"xp": 140,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Auto de Infração Glacial", "Caneta Criogênica", "Juros Congelantes"],
	},
	{
		"id": "chef_coldflame",
		"planet_id": "congelaria_sa",
		"name": "Chef Brasa Fria",
		"title": "Contrabandista de sopa acima de zero",
		"description": "Serviu caldo morno sem licença térmica. Três executivos descongelaram sentimentos.",
		"emoji": "♨",
		"power": 32,
		"defense": 13,
		"health": 190,
		"duration": 15,
		"credits": 174,
		"xp": 166,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Concha de Lava", "Caldo Clandestino", "Pimenta de Reentrada"],
	},
	{
		"id": "executive_penguin",
		"planet_id": "congelaria_sa",
		"name": "Pinguim Executivo",
		"title": "Diretor de demissões em massa polar",
		"description": "Terceirizou o próprio bando e vendeu os peixes da confraternização.",
		"emoji": "▰",
		"power": 37,
		"defense": 15,
		"health": 220,
		"duration": 17,
		"credits": 208,
		"xp": 196,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Gravata Torpedo", "Reunião Sem Pauta", "Bicada de Desligamento"],
	},
	{
		"id": "director_kelvin",
		"planet_id": "congelaria_sa",
		"name": "Diretora Kelvin",
		"title": "CEO vitalícia do frio corporativo",
		"description": "Patenteou o zero absoluto e agora cobra royalties de todo termômetro.",
		"emoji": "◆",
		"power": 43,
		"defense": 18,
		"health": 260,
		"duration": 20,
		"credits": 268,
		"xp": 248,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Fusão Hostil", "Zero Absoluto Fiscal", "Sinergia Criogênica"],
	},
	{
		"id": "landlord_spore",
		"planet_id": "micelia_404",
		"name": "Síndico Esporão",
		"title": "Administrador do condomínio micelial",
		"description": "Cobrou aluguel de cada raiz e instalou catracas nas trilhas de formigas.",
		"emoji": "♣",
		"power": 44,
		"defense": 19,
		"health": 275,
		"duration": 22,
		"credits": 304,
		"xp": 282,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Boleto de Esporos", "Assembleia Venenosa", "Taxa de Umidade"],
	},
	{
		"id": "countess_truffle",
		"planet_id": "micelia_404",
		"name": "Condessa Trufa",
		"title": "Banqueira de raízes offshore",
		"description": "Escondeu fortunas em paraísos fiscais subterrâneos e declarou tudo como adubo.",
		"emoji": "●",
		"power": 50,
		"defense": 21,
		"health": 315,
		"duration": 24,
		"credits": 346,
		"xp": 320,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Juros Compostáveis", "Hipoteca de Raízes", "Perfume Tóxico Premium"],
	},
	{
		"id": "captain_chlorophyll",
		"planet_id": "micelia_404",
		"name": "Capitão Clorofila",
		"title": "Pirata de fotossíntese patenteada",
		"description": "Desviou três sóis portáteis e vende luz solar em pacotes com anúncios.",
		"emoji": "☀",
		"power": 56,
		"defense": 24,
		"health": 360,
		"duration": 26,
		"credits": 394,
		"xp": 360,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Sabre Fotônico Verde", "Canhão de Seiva", "Motim Fotossintético"],
	},
	{
		"id": "mother_mycelia",
		"planet_id": "micelia_404",
		"name": "Mãe Micélia",
		"title": "Rede neural proprietária do planeta",
		"description": "Cobra assinatura por pensamento e vende seus sonhos para anunciantes de fertilizante.",
		"emoji": "◎",
		"power": 64,
		"defense": 28,
		"health": 430,
		"duration": 30,
		"credits": 488,
		"xp": 438,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Consenso Micelial", "Pensamento Patrocinado", "Raiz do Sistema"],
	},
	{
		"id": "bolt_collector",
		"planet_id": "ferro_velho_omega",
		"name": "Cobrador Rebite",
		"title": "Agente de penhora magnética",
		"description": "Confiscou todos os parafusos de um bairro por atraso de três arruelas.",
		"emoji": "◆",
		"power": 69,
		"defense": 30,
		"health": 470,
		"duration": 32,
		"credits": 540,
		"xp": 480,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Cobrança Magnética", "Multa de Rebite", "Penhora de Parafusos"],
	},
	{
		"id": "doctor_patchwork",
		"planet_id": "ferro_velho_omega",
		"name": "Doutora Gambiarra",
		"title": "Cirurgiã de naves sem licença",
		"description": "Transplantou um motor de ônibus numa fragata e cobrou pelo segundo coração.",
		"emoji": "+",
		"power": 75,
		"defense": 33,
		"health": 520,
		"duration": 34,
		"credits": 604,
		"xp": 532,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Bisturi de Solda", "Anestesia de Bateria", "Alta Contraindicação"],
	},
	{
		"id": "crane_king",
		"planet_id": "ferro_velho_omega",
		"name": "Rei Guindaste",
		"title": "Monarca da sucata prensada",
		"description": "Coroou a si mesmo com uma calota e anexou seis depósitos por decreto hidráulico.",
		"emoji": "♜",
		"power": 82,
		"defense": 36,
		"health": 580,
		"duration": 36,
		"credits": 676,
		"xp": 594,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Decreto Hidráulico", "Coroa de Calota", "Prensa Real"],
	},
	{
		"id": "omega_junkyard",
		"planet_id": "ferro_velho_omega",
		"name": "Ômega, o Ferro-Velho",
		"title": "Aterro senciente de civilizações",
		"description": "Arquiva planetas inteiros na categoria “peças talvez úteis” e perdeu o formulário de devolução.",
		"emoji": "Ω",
		"power": 90,
		"defense": 40,
		"health": 680,
		"duration": 40,
		"credits": 792,
		"xp": 690,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Compactação Planetária", "Inventário Infinito", "Garantia do Fim"],
	},
]

const PLAYER_ATTACKS := [
	"Ricochete de Plasma",
	"Cobrança à Queima-Roupa",
	"Disparo Quase Calculado",
	"Cláusula de Perfuração",
]

const CONTRACT_APPROACHES := [
	{
		"id": "quiet_net",
		"name": "Rede Silenciosa",
		"tag": "SEGURO · +XP",
		"description": "Cerque o alvo, desligue as saídas e finja que tudo estava planejado.",
		"duration_mult": 1.35,
		"power_mult": 0.92,
		"defense_mult": 0.85,
		"health_mult": 1.0,
		"credits_mult": 0.90,
		"xp_mult": 1.25,
		"color": "#55e5ff",
	},
	{
		"id": "hot_hatch",
		"name": "Entrada pela Escotilha",
		"tag": "RÁPIDO · +CRÉDITOS",
		"description": "Chegue antes do plano, chute a porta errada e cobre taxa de urgência.",
		"duration_mult": 0.55,
		"power_mult": 1.12,
		"defense_mult": 1.0,
		"health_mult": 1.08,
		"credits_mult": 1.35,
		"xp_mult": 1.0,
		"color": "#ff6f7d",
	},
	{
		"id": "premium_warrant",
		"name": "Mandado Corporativo",
		"tag": "LUCRO · ALTO RISCO",
		"description": "A corporação paga muito mais, desde que o alvo possa revidar muito mais.",
		"duration_mult": 1.0,
		"power_mult": 1.18,
		"defense_mult": 1.12,
		"health_mult": 1.12,
		"credits_mult": 1.65,
		"xp_mult": 0.85,
		"color": "#ffc857",
	},
]

const HUNT_EVENTS := [
	{
		"id": "toll_drone",
		"planet_id": "dustball_prime",
		"symbol": "D-7",
		"title": "Pedágio de Drone D-7",
		"description": "Um drone municipal bloqueia a rota. O adesivo diz: “totalmente oficial”.",
		"color": "#55e5ff",
		"choices": [
			{
				"id": "bribe",
				"name": "PAGAR 8 CRÉDITOS",
				"effect_text": "O drone entrega os pontos fracos: -18% defesa do alvo.",
				"credit_cost": 8,
				"defense_mult": 0.82,
				"result": "D-7 aceitou a taxa administrativa e marcou a armadura defeituosa.",
			},
			{
				"id": "detour",
				"name": "PEGAR O DESVIO",
				"effect_text": "+2s de caça, mas o alvo perde 12% de vida.",
				"duration_add": 2.0,
				"health_mult": 0.88,
				"result": "O desvio terminou atrás do alvo. Pela primeira vez, uma placa ajudou.",
			},
			{
				"id": "ram",
				"name": "FURAR O BLOQUEIO",
				"effect_text": "+12% poder inimigo, mas +18% créditos.",
				"power_mult": 1.12,
				"credits_mult": 1.18,
				"result": "O drone enviou a placa da nave ao alvo e uma multa ao contratante.",
			},
		],
	},
	{
		"id": "bounty_streamer",
		"planet_id": "dustball_prime",
		"symbol": "LIVE",
		"title": "Influencer de Caçada",
		"description": "Uma repórter transmite sua perseguição ao vivo para onze espectadores e um bot.",
		"color": "#d789ff",
		"choices": [
			{
				"id": "interview",
				"name": "DAR ENTREVISTA",
				"effect_text": "+22% XP, mas o alvo ganha 8% de poder.",
				"xp_mult": 1.22,
				"power_mult": 1.08,
				"result": "A entrevista viralizou entre os onze espectadores. O alvo também assistiu.",
			},
			{
				"id": "jam_signal",
				"name": "CORTAR O SINAL · 6 CR",
				"effect_text": "Emboscada preservada: -8% poder do alvo.",
				"credit_cost": 6,
				"power_mult": 0.92,
				"result": "A transmissão caiu no melhor momento. Sua emboscada não.",
			},
			{
				"id": "wave",
				"name": "MANDAR UM JOINHA",
				"effect_text": "+1s de caça e +8% créditos pela publicidade.",
				"duration_add": 1.0,
				"credits_mult": 1.08,
				"result": "O joinha virou patrocínio. Ninguém sabe por quê.",
			},
		],
	},
	{
		"id": "heat_inspector",
		"planet_id": "congelaria_sa",
		"symbol": "-40°",
		"title": "Fiscal de Calor",
		"description": "Um termômetro de terno detectou intenções acima da temperatura permitida.",
		"color": "#72f1dd",
		"choices": [
			{
				"id": "pay_cooling_fee", "name": "PAGAR 12 CRÉDITOS",
				"effect_text": "O fiscal congela juntas expostas: -20% defesa do alvo.",
				"credit_cost": 12, "defense_mult": 0.80,
				"result": "A taxa de resfriamento foi paga. Até os parafusos do alvo bateram os dentes.",
			},
			{
				"id": "fake_badge", "name": "FALSIFICAR UM CRACHÁ",
				"effect_text": "+2s de caça e +18% XP pela experiência corporativa.",
				"duration_add": 2.0, "xp_mult": 1.18,
				"result": "Seu novo cargo é Vice-Caçador Sênior. Ninguém pediu referências.",
			},
			{
				"id": "overclock_heater", "name": "LIGAR O AQUECEDOR",
				"effect_text": "+10% poder inimigo, mas +20% créditos por insalubridade.",
				"power_mult": 1.10, "credits_mult": 1.20,
				"result": "O aquecedor disparou alarmes, bônus de risco e uma torrada esquecida.",
			},
		],
	},
	{
		"id": "corporate_avalanche",
		"planet_id": "congelaria_sa",
		"symbol": "RACHOU",
		"title": "Avalanche Corporativa",
		"description": "A geleira foi reestruturada sem aviso prévio e metade da rota foi demitida.",
		"color": "#a97cff",
		"choices": [
			{
				"id": "melt_route", "name": "DERRETER A ROTA · 10 CR",
				"effect_text": "Atalho térmico: o alvo perde 15% de vida.",
				"credit_cost": 10, "health_mult": 0.85,
				"result": "A rota derreteu. O departamento jurídico também, mas só um pouco.",
			},
			{
				"id": "climb_shelf", "name": "ESCALAR A GELEIRA",
				"effect_text": "+3s de caça e +20% XP por treinamento não solicitado.",
				"duration_add": 3.0, "xp_mult": 1.20,
				"result": "Você escalou a nova hierarquia glacial sem uma única reunião.",
			},
			{
				"id": "surf_collapse", "name": "SURFAR O COLAPSO",
				"effect_text": "+12% poder inimigo, mas +22% créditos pelo espetáculo.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "A manobra recebeu nota dez e uma advertência de segurança.",
			},
		],
	},
	{
		"id": "spore_customs",
		"planet_id": "micelia_404",
		"symbol": "ACHOO",
		"title": "Alfândega de Esporos",
		"description": "Uma nuvem carimba cada molécula que entra. Seu pulmão está com documentação vencida.",
		"color": "#c7f464",
		"choices": [
			{
				"id": "buy_mask", "name": "COMPRAR MÁSCARA · 14 CR",
				"effect_text": "Filtros revelam o alvo entre a névoa: -20% defesa.",
				"credit_cost": 14, "defense_mult": 0.80,
				"result": "A máscara filtra esporos, desculpas e noventa por cento dos anúncios.",
			},
			{
				"id": "declare_lungs", "name": "DECLARAR OS PULMÕES",
				"effect_text": "+3s de caça e +20% XP por preencher anatomia em triplicado.",
				"duration_add": 3.0, "xp_mult": 1.20,
				"result": "Seus pulmões agora constam como bagagem de mão regulamentar.",
			},
			{
				"id": "sneeze_through", "name": "ESPIRRAR E ACELERAR",
				"effect_text": "+12% poder inimigo, mas +22% créditos por contaminação.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "O espirro abriu um túnel e fechou três restaurantes orgânicos.",
			},
		],
	},
	{
		"id": "sentient_shortcut",
		"planet_id": "micelia_404",
		"symbol": "OI?",
		"title": "Atalho Senciente",
		"description": "A trilha acordou, pediu seu nome e quer comissão sobre a recompensa.",
		"color": "#ff75c8",
		"choices": [
			{
				"id": "pay_path", "name": "PAGAR 16 CRÉDITOS",
				"effect_text": "A trilha entrega o alvo: -16% vida inimiga.",
				"credit_cost": 16, "health_mult": 0.84,
				"result": "O atalho aceitou pagamento, gorjeta e uma avaliação de cinco estrelas.",
			},
			{
				"id": "tell_story", "name": "CONTAR UMA HISTÓRIA",
				"effect_text": "+2s de caça e +18% XP pela terapia vegetal.",
				"duration_add": 2.0, "xp_mult": 1.18,
				"result": "A trilha chorou seiva e indicou uma rota emocionalmente mais curta.",
			},
			{
				"id": "step_on_it", "name": "PISAR FUNDO",
				"effect_text": "+10% poder inimigo, mas +20% créditos por danos botânicos.",
				"power_mult": 1.10, "credits_mult": 1.20,
				"result": "A trilha abriu um processo. O contratante cobriu os honorários.",
			},
		],
	},
	{
		"id": "magnetic_storm",
		"planet_id": "ferro_velho_omega",
		"symbol": "CLANG",
		"title": "Tempestade de Ímãs",
		"description": "Uma frente magnética arrancou placas, talheres e três luas decorativas da rota.",
		"color": "#ff9f43",
		"choices": [
			{
				"id": "rent_demagnetizer", "name": "ALUGAR DESMAGNETIZADOR · 18 CR",
				"effect_text": "O campo expõe juntas metálicas: -20% defesa do alvo.",
				"credit_cost": 18, "defense_mult": 0.80,
				"result": "O aparelho desmagnetizou a rota e apagou duas fitas muito importantes.",
			},
			{
				"id": "follow_debris", "name": "SEGUIR OS DESTROÇOS",
				"effect_text": "+3s de caça e +20% XP em arqueologia automotiva.",
				"duration_add": 3.0, "xp_mult": 1.20,
				"result": "Os destroços formaram uma seta, um imposto e depois outra seta.",
			},
			{
				"id": "ride_magnetism", "name": "SURFAR O CAMPO",
				"effect_text": "+12% poder inimigo, mas +22% créditos pelo risco metálico.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "A manobra atraiu o alvo, a recompensa e todo o conteúdo de uma oficina.",
			},
		],
	},
	{
		"id": "warranty_ghost",
		"planet_id": "ferro_velho_omega",
		"symbol": "VENCEU",
		"title": "Fantasma da Garantia",
		"description": "Um holograma insiste que a perseguição deixou de ter cobertura há quatro quilômetros.",
		"color": "#ffd166",
		"choices": [
			{
				"id": "extend_warranty", "name": "ESTENDER GARANTIA · 20 CR",
				"effect_text": "Assistência autorizada reduz 12% do poder inimigo.",
				"credit_cost": 20, "power_mult": 0.88,
				"result": "A garantia cobre impactos, lasers e uma quantidade juridicamente vaga de explosões.",
			},
			{
				"id": "read_fine_print", "name": "LER AS LETRAS MIÚDAS",
				"effect_text": "+2s de caça e +18% XP em direito de oficina.",
				"duration_add": 2.0, "xp_mult": 1.18,
				"result": "Na cláusula 9001, o alvo aparece listado como defeito de fabricação.",
			},
			{
				"id": "void_it", "name": "VIOLAR O LACRE",
				"effect_text": "+10% vida inimiga, mas +20% créditos sem cobertura.",
				"health_mult": 1.10, "credits_mult": 1.20,
				"result": "A garantia evaporou. O contratante chamou isso de bônus de autonomia.",
			},
		],
	},
]

const ITEM_TRAITS := {
	"weapon": [
		{"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0},
		{"id": "argument_amplifier", "name": "AMPLIFICADOR DE ARGUMENTO", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6},
	],
	"armor": [
		{"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "power_bonus": 0, "health_bonus": 14},
		{"id": "illegal_servos", "name": "SERVOS NÃO DECLARADOS", "description": "+1 poder e +8 integridade.", "power_bonus": 1, "health_bonus": 8},
	],
}


const ITEM_CATALOG := {
	"weapon": [
		{"name": "Desatomizador de Bolso", "description": "Desmonta átomos, garantias e conversas constrangedoras."},
		{"name": "Canhão de Recibos", "description": "A prova de compra chega antes do projétil."},
		{"name": "Pistola Quase Legal", "description": "Legal em pelo menos duas luas e meia."},
		{"name": "Zapper de Plasma Torto", "description": "O tiro faz curva. Às vezes até na direção certa."},
	],
	"armor": [
		{"name": "Casaco Antilaser Usado", "description": "As marcas de queimadura comprovam que já funcionou."},
		{"name": "Colete de Espuma Cósmica", "description": "Confortável, protetor e estranhamente efervescente."},
		{"name": "Armadura Fiscal", "description": "Deduz parte do dano no próximo ano galáctico."},
		{"name": "Poncho de Titânio", "description": "Elegância de fronteira com nove quilos por ombro."},
	],
}

const PLANET_ITEM_CATALOGS := {
	"congelaria_sa": {
		"weapon": [
			{"name": "Lança-Chamas de Escritório", "description": "Aquece café, contratos e negociações hostis."},
			{"name": "Carabina Criogênica Reversa", "description": "Congela a culpa e descongela o gatilho."},
			{"name": "Grampeador Térmico", "description": "Prende folhas a três metros e criminosos a dois."},
			{"name": "Canhão de Sopa Pressurizada", "description": "O caldo é ilegal. Os croutons são perfurantes."},
		],
		"armor": [
			{"name": "Parka de Reunião Infinita", "description": "Mantém o corpo aquecido enquanto a pauta congela a alma."},
			{"name": "Colete Antitermostato", "description": "Certificado para sobreviver a três auditorias e meia."},
			{"name": "Terno de Fibra Glacial", "description": "Elegante, blindado e impossível de passar a ferro."},
			{"name": "Manta Executiva de Emergência", "description": "Dourada por fora, formulário de despesas por dentro."},
		],
	},
	"micelia_404": {
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
	},
	"ferro_velho_omega": {
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
	},
}


static func get_planet(planet_id: String) -> Dictionary:
	for planet in PLANETS:
		if str(planet.id) == planet_id:
			return planet.duplicate(true)
	return PLANET.duplicate(true)


static func is_planet_unlocked(planet_id: String, completed_planets: Array) -> bool:
	var planet := get_planet(planet_id)
	var requirement := str(planet.get("unlock_after", ""))
	return requirement.is_empty() or completed_planets.has(requirement)


static func available_bounties(reputation: int, planet_id := "dustball_prime", chapter_tier := -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unlocked_tier: int = reputation if chapter_tier < 0 else chapter_tier
	for target in TARGETS:
		if str(target.get("planet_id", "dustball_prime")) == planet_id and int(target.rank) <= reputation and int(target.get("chapter_tier", target.rank)) <= unlocked_tier:
			result.append(target.duplicate(true))
	return result


static func contract_approaches() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for approach in CONTRACT_APPROACHES:
		result.append(approach.duplicate(true))
	return result


static func get_target(target_id: String) -> Dictionary:
	for target in TARGETS:
		if str(target.get("id", "")) == target_id:
			return target.duplicate(true)
	return {}


static func apply_approach(bounty: Dictionary, approach: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	result["approach"] = approach.duplicate(true)
	result["duration"] = maxi(1, ceili(float(bounty.duration) * float(approach.duration_mult)))
	result["power"] = maxi(1, roundi(float(bounty.power) * float(approach.power_mult)))
	result["defense"] = maxi(0, roundi(float(bounty.defense) * float(approach.defense_mult)))
	result["health"] = maxi(1, roundi(float(bounty.health) * float(approach.health_mult)))
	result["credits"] = maxi(1, roundi(float(bounty.credits) * float(approach.credits_mult)))
	result["xp"] = maxi(1, roundi(float(bounty.xp) * float(approach.xp_mult)))
	return result


static func random_hunt_event(rng: RandomNumberGenerator, planet_id := "dustball_prime") -> Dictionary:
	var candidates: Array[Dictionary] = []
	for event in HUNT_EVENTS:
		if str(event.get("planet_id", "dustball_prime")) == planet_id:
			candidates.append(event)
	if candidates.is_empty():
		candidates.append(HUNT_EVENTS[0])
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)


static func apply_hunt_choice(bounty: Dictionary, choice: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	for stat in ["power", "defense", "health", "credits", "xp"]:
		var multiplier_key := "%s_mult" % stat
		if choice.has(multiplier_key):
			result[stat] = maxi(1 if stat != "defense" else 0, roundi(float(result[stat]) * float(choice[multiplier_key])))
	result["hunt_event_result"] = str(choice.get("result", "A perseguição ficou ligeiramente mais estranha."))
	return result


static func generate_loot(target: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var slot := "weapon" if rng.randf() < 0.58 else "armor"
	var planet_id := str(target.get("planet_id", "dustball_prime"))
	var item_family: Dictionary = PLANET_ITEM_CATALOGS.get(planet_id, ITEM_CATALOG)
	var catalog: Array = item_family[slot]
	var definition: Dictionary = catalog[rng.randi_range(0, catalog.size() - 1)]
	var base_power := int(target.power * rng.randf_range(0.36, 0.68))
	var rarity_roll := rng.randf()
	var rarity := "Comum"
	var rarity_color := "#b9c2d9"
	var bonus := 0
	if rarity_roll > 0.92:
		rarity = "Épico"
		rarity_color = "#d789ff"
		bonus = 5
	elif rarity_roll > 0.68:
		rarity = "Raro"
		rarity_color = "#58d9ff"
		bonus = 2
	var item := {
		"id": "%s_%s_%d" % [target.id, slot, rng.randi()],
		"name": definition.name,
		"description": definition.description,
		"slot": slot,
		"power": maxi(1, base_power + bonus),
		"rarity": rarity,
		"color": rarity_color,
	}
	var rare_trait_chance := 0.85 if planet_id == "ferro_velho_omega" else 0.65
	if rarity == "Épico" or (rarity == "Raro" and rng.randf() < rare_trait_chance):
		var traits: Array = ITEM_TRAITS[slot]
		item.trait = traits[rng.randi_range(0, traits.size() - 1)].duplicate(true)
	return item


static func player_attack(rng: RandomNumberGenerator) -> String:
	return PLAYER_ATTACKS[rng.randi_range(0, PLAYER_ATTACKS.size() - 1)]


static func target_attack(target: Dictionary, rng: RandomNumberGenerator) -> String:
	var attacks: Array = target.get("attacks", ["Golpe Suspeito"])
	return attacks[rng.randi_range(0, attacks.size() - 1)]
