class_name ContentDB
extends RefCounted

const CoreRulesScript = preload("res://scripts/core_rules.gd")
const EquipmentGenerationRulesScript = preload("res://scripts/equipment_generation_rules.gd")
const AttributePackageRulesScript = preload("res://scripts/attribute_package_rules.gd")
const DustballPrimeContent = preload("res://scripts/content/packs/dustball_prime.gd")

static var procedural_collection_ids_cache: Array[String] = []
static var procedural_collection_entries_cache: Array[Dictionary] = []


const PLANET := DustballPrimeContent.PLANET

const PLANETS := [
	PLANET,
	{
		"id": "congelaria_sa",
		"name": "Congelária S.A.",
		"unlock_level": 4,
		"travel_duration": 480.0,
		"subtitle": "Tudo abaixo de zero. Inclusive o atendimento.",
		"description": "Um frigorífico planetário privatizado, com geleiras, cubículos e multas por aquecimento.",
		"accent": "#72f1dd",
		"unlock_after": "dustball_prime",
		"completion_text": "A diretoria foi descongelada de suas funções. O termostato agora aceita votos e moedas.",
	},
	{
		"id": "micelia_404",
		"name": "Micélia 404",
		"unlock_level": 8,
		"travel_duration": 720.0,
		"subtitle": "Tudo cresce. Principalmente as taxas.",
		"description": "Uma rede fúngica planetária onde prédios brotam, calçadas respiram e todo esporo tem cadastro.",
		"accent": "#c7f464",
		"unlock_after": "congelaria_sa",
		"completion_text": "A rede micelial trocou de administração. Os cogumelos exigem eleições úmidas.",
	},
	{
		"id": "ferro_velho_omega",
		"name": "Ferro-Velho Ômega",
		"unlock_level": 13,
		"travel_duration": 960.0,
		"subtitle": "Tudo tem dono. Principalmente o lixo.",
		"description": "Um planeta-oficina montado com luas usadas, garantias vencidas e robôs que cobram estacionamento por eixo.",
		"accent": "#ff9f43",
		"unlock_after": "micelia_404",
		"completion_text": "O aterro deixou de colecionar civilizações. Agora aceita apenas recicláveis e opiniões com nota fiscal.",
	},
	{
		"id": "cassino_quasar",
		"name": "Cassino Quasar",
		"unlock_level": 19,
		"travel_duration": 1200.0,
		"subtitle": "A casa sempre ganha. E cobra estacionamento.",
		"description": "Um resort orbital construído em torno de uma estrela viciada, com roletas gravitacionais e probabilidades sob licença.",
		"accent": "#ff75d8",
		"unlock_after": "ferro_velho_omega",
		"completion_text": "A Casa finalmente perdeu. O prêmio foi parcelado em eras geológicas e a saída continua passando pela loja de lembranças.",
	},
	{
		"id": "aeropolis_penhora",
		"name": "Aerópolis de Penhora",
		"unlock_level": 30,
		"travel_duration": 1440.0,
		"subtitle": "O céu é o limite. A dívida também.",
		"description": "Cidades-balão navegam um gigante gasoso onde bancos privatizaram o vento, tempestades trabalham por turno e até respirar exige fiador.",
		"accent": "#8fd3ff",
		"unlock_after": "cassino_quasar",
		"completion_text": "O Banco da Tempestade entrou em liquidação. Choveu moedas por onze minutos e formulários por três dias.",
	},
	{
		"id": "arquivo_abissal_n9",
		"name": "Arquivo Abissal N-9",
		"unlock_level": 40,
		"travel_duration": 1680.0,
		"subtitle": "A pressão aumenta. O prazo também.",
		"description": "Uma repartição oceânica afundada num mundo sem continentes, onde recifes arquivam processos, submarinos fazem fila e toda bolha precisa de protocolo.",
		"accent": "#39d7c5",
		"unlock_after": "aeropolis_penhora",
		"completion_text": "O Leviatã do Protocolo foi carimbado, catalogado e devolvido ao abismo. A fila avançou dois lugares.",
	},
]

const TARGETS := [
	DustballPrimeContent.TARGET_GLOOP,
	DustballPrimeContent.TARGET_BARON_BOOM,
	DustballPrimeContent.TARGET_MADAME_VACUUM,
	DustballPrimeContent.TARGET_MAYOR_GOLD_DUST,
	{
		"id": "auditor_frost",
		"planet_id": "congelaria_sa",
		"name": "Auditor Geada",
		"title": "Fiscal de aquecedores clandestinos",
		"description": "Confiscou o último cobertor do hemisfério sul por excesso de conforto.",
		"emoji": "❄",
		"power": 31,
		"loot_power": 28,
		"defense": 12,
		"health": 245,
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
		"power": 35,
		"loot_power": 32,
		"defense": 14,
		"health": 270,
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
		"power": 40,
		"loot_power": 37,
		"defense": 17,
		"health": 315,
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
		"power": 45,
		"loot_power": 43,
		"defense": 20,
		"health": 335,
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
		"power": 47,
		"loot_power": 44,
		"defense": 20,
		"health": 340,
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
		"power": 58,
		"loot_power": 50,
		"defense": 24,
		"health": 445,
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
		"power": 62,
		"loot_power": 56,
		"defense": 27,
		"health": 450,
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
		"power": 69,
		"loot_power": 64,
		"defense": 30,
		"health": 470,
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
	{
		"id": "dealer_comet",
		"planet_id": "cassino_quasar",
		"name": "Crupiê Cometa",
		"title": "Distribuidor de órbitas marcadas",
		"description": "Embaralhou sete luas e jura que o eclipse na manga veio de fábrica.",
		"emoji": "♠",
		"power": 96,
		"defense": 43,
		"health": 700,
		"duration": 42,
		"credits": 870,
		"xp": 750,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Baralho Balístico", "Corte de Órbita", "Aposta Cega"],
	},
	{
		"id": "duchess_jackpot",
		"planet_id": "cassino_quasar",
		"name": "Duquesa Jackpot",
		"title": "Herdeira das máquinas caça-luas",
		"description": "Transformou a gravidade em assinatura premium e o chão em conteúdo patrocinado.",
		"emoji": "♦",
		"power": 104,
		"defense": 47,
		"health": 770,
		"duration": 44,
		"credits": 955,
		"xp": 820,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Jackpot de Plasma", "Salto Alto Gravitacional", "Dividendos Marcados"],
	},
	{
		"id": "misfortune_auditor",
		"planet_id": "cassino_quasar",
		"name": "Auditor do Azar",
		"title": "Fiscal de probabilidades não declaradas",
		"description": "Multa coincidências, confisca trevos e exige recibo de todo golpe de sorte.",
		"emoji": "%",
		"power": 113,
		"defense": 51,
		"health": 830,
		"duration": 47,
		"credits": 1055,
		"xp": 900,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Juros do Destino", "Auto de Má Fortuna", "Probabilidade Reversa"],
	},
	{
		"id": "house_eternal",
		"planet_id": "cassino_quasar",
		"name": "A Casa Eterna",
		"title": "Cassino senciente de saldo infinito",
		"description": "Calcula todas as escolhas possíveis e oferece bebida grátis apenas na pior delas.",
		"emoji": "♛",
		"power": 124,
		"defense": 56,
		"health": 900,
		"duration": 51,
		"credits": 1230,
		"xp": 1040,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Vantagem da Casa", "Roleta de Singularidade", "Última Ficha"],
	},
	{
		"id": "courier_cumulus",
		"planet_id": "aeropolis_penhora",
		"name": "Carteiro Cumulus",
		"title": "Contrabandista de encomendas atmosféricas",
		"description": "Entrega cobranças antes do vencimento e destinatários depois da tempestade.",
		"emoji": "☁",
		"power": 136,
		"loot_power": 128,
		"defense": 61,
		"health": 980,
		"duration": 55,
		"credits": 1390,
		"xp": 1160,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Entrega Expressa", "Selo de Turbulência", "Aviso de Receção"],
	},
	{
		"id": "duchess_low_pressure",
		"planet_id": "aeropolis_penhora",
		"name": "Duquesa Baixa Pressão",
		"title": "Pirata aristocrática dos corredores de vento",
		"description": "Cobra pedágio de toda brisa e chama furacões de transporte executivo.",
		"emoji": "♨",
		"power": 148,
		"loot_power": 139,
		"defense": 66,
		"health": 1080,
		"duration": 59,
		"credits": 1550,
		"xp": 1270,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Rajada Aristocrática", "Monção de Etiqueta", "Pedágio Barométrico"],
	},
	{
		"id": "engineer_thunder",
		"planet_id": "aeropolis_penhora",
		"name": "Engenheiro Trovão",
		"title": "Locador de tempestades industriais",
		"description": "Aluga relâmpagos por minuto e desliga o para-raios de quem atrasa uma prestação.",
		"emoji": "ϟ",
		"power": 160,
		"loot_power": 151,
		"defense": 72,
		"health": 1190,
		"duration": 63,
		"credits": 1740,
		"xp": 1400,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Fatura Voltaica", "Curto de Cobrança", "Sobretensão Contratual"],
	},
	{
		"id": "storm_bank",
		"planet_id": "aeropolis_penhora",
		"name": "Banco da Tempestade",
		"title": "Instituição atmosférica senciente",
		"description": "Hipotecou o horizonte, penhorou o clima e capitaliza juros sempre que alguém suspira.",
		"emoji": "☇",
		"power": 175,
		"loot_power": 165,
		"defense": 79,
		"health": 1330,
		"duration": 68,
		"credits": 2040,
		"xp": 1580,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Juros Cumulonimbus", "Execução Atmosférica", "Falência do Horizonte"],
	},
	{
		"id": "eel_courier",
		"planet_id": "arquivo_abissal_n9",
		"name": "Estafeta Enguia",
		"title": "Contrabandista dos tubos pneumáticos",
		"description": "Entrega processos por atalhos elétricos e cobra sobretaxa a quem sobrevive à assinatura.",
		"emoji": "≈",
		"power": 190,
		"loot_power": 179,
		"defense": 85,
		"health": 1460,
		"duration": 72,
		"credits": 2260,
		"xp": 1750,
		"rank": 3,
		"chapter_tier": 0,
		"attacks": ["Despacho Elétrico", "Atalho Condutor", "Recibo de Alta Voltagem"],
	},
	{
		"id": "coral_landlady",
		"planet_id": "arquivo_abissal_n9",
		"name": "Senhoria Coralina",
		"title": "Proprietária de recifes hipotecados",
		"description": "Aluga cavernas por maré, penhora pérolas e aumenta a renda sempre que o oceano sobe.",
		"emoji": "♒",
		"power": 207,
		"loot_power": 195,
		"defense": 92,
		"health": 1600,
		"duration": 77,
		"credits": 2470,
		"xp": 1910,
		"rank": 3,
		"chapter_tier": 1,
		"attacks": ["Renda de Maré Alta", "Penhora de Pérola", "Despejo do Recife"],
	},
	{
		"id": "notary_octopus",
		"planet_id": "arquivo_abissal_n9",
		"name": "Tabelião Tentáculo",
		"title": "Notário de oito assinaturas simultâneas",
		"description": "Autentica provas, falsifica testemunhas e mantém seis braços livres para cobrar emolumentos.",
		"emoji": "§",
		"power": 225,
		"loot_power": 212,
		"defense": 100,
		"health": 1760,
		"duration": 82,
		"credits": 2720,
		"xp": 2090,
		"rank": 3,
		"chapter_tier": 2,
		"attacks": ["Carimbo Octogonal", "Firma Reconhecida", "Cláusula de Tinta"],
	},
	{
		"id": "protocol_leviathan",
		"planet_id": "arquivo_abissal_n9",
		"name": "Leviatã do Protocolo",
		"title": "Arquivo vivo de processos afogados",
		"description": "Engole recursos, regurgita formulários e só desperta quando alguém escolhe a fila errada.",
		"emoji": "⌁",
		"power": 245,
		"loot_power": 231,
		"defense": 109,
		"health": 1950,
		"duration": 88,
		"credits": 3060,
		"xp": 2310,
		"rank": 3,
		"chapter_tier": 3,
		"boss": true,
		"attacks": ["Decreto Hadal", "Engolir Recurso", "Protocolo do Fim"],
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
		"tag": "RÁPIDO · +35% CRÉDITOS",
		"description": "Chegue antes do plano, chute a porta errada e cobre taxa de urgência.",
		"duration_mult": 0.65,
		"power_mult": 1.18,
		"defense_mult": 1.08,
		"health_mult": 1.28,
		"frontier_health_bonus": 0.22,
		"planet_health_step": 0.03,
		"credits_mult": 1.35,
		"xp_mult": 1.0,
		"color": "#ff6f7d",
	},
	{
		"id": "premium_warrant",
		"name": "Mandado Corporativo",
		"tag": "LUCRO · +100% CR · +3 SUCATA",
		"description": "A corporação paga muito mais e libera peças da oficina, desde que o alvo possa revidar muito mais.",
		"duration_mult": 1.0,
		"power_mult": 1.22,
		"defense_mult": 1.14,
		"health_mult": 1.32,
		"frontier_health_bonus": 0.32,
		"planet_health_step": 0.02,
		"credits_mult": 2.0,
		"xp_mult": 0.90,
		"scrap_reward": 3,
		"color": "#ffc857",
	},
]

const HUNT_EVENTS := [
	DustballPrimeContent.EVENT_TOLL_DRONE,
	DustballPrimeContent.EVENT_BOUNTY_STREAMER,
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
				"effect_text": "+45s de caça e +18% XP pela experiência corporativa.",
				"duration_add": 45.0, "xp_mult": 1.18,
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
				"effect_text": "+60s de caça e +20% XP por treinamento não solicitado.",
				"duration_add": 60.0, "xp_mult": 1.20,
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
				"effect_text": "+60s de caça e +20% XP por preencher anatomia em triplicado.",
				"duration_add": 60.0, "xp_mult": 1.20,
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
				"effect_text": "+45s de caça e +18% XP pela terapia vegetal.",
				"duration_add": 45.0, "xp_mult": 1.18,
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
				"effect_text": "+60s de caça e +20% XP em arqueologia automotiva.",
				"duration_add": 60.0, "xp_mult": 1.20,
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
				"effect_text": "+45s de caça e +18% XP em direito de oficina.",
				"duration_add": 45.0, "xp_mult": 1.18,
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
	{
		"id": "gravity_roulette",
		"planet_id": "cassino_quasar",
		"symbol": "17?",
		"title": "Roleta Gravitacional",
		"description": "A avenida gira, a nave flutua e uma voz anuncia que cair também conta como aposta.",
		"color": "#ff75d8",
		"choices": [
			{
				"id": "buy_anchor", "name": "ALUGAR ÂNCORA · 22 CR",
				"effect_text": "A rota estabiliza e expõe o alvo: -20% defesa.",
				"credit_cost": 22, "defense_mult": 0.80,
				"result": "A âncora veio com recibo, corrente e uma taxa por conceito de baixo.",
			},
			{
				"id": "ride_spin", "name": "SEGUIR O GIRO",
				"effect_text": "+60s de caça e +20% XP em física recreativa.",
				"duration_add": 60.0, "xp_mult": 1.20,
				"result": "Três voltas depois, você entende gravidade e desaprova a gerência.",
			},
			{
				"id": "bet_on_red", "name": "APOSTAR NO VERMELHO",
				"effect_text": "+12% poder inimigo, mas +22% créditos se a nave parar inteira.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "Deu vermelho. O alvo também ficou sabendo e trouxe munição temática.",
			},
		],
	},
	{
		"id": "luck_inspector",
		"planet_id": "cassino_quasar",
		"symbol": "1:∞",
		"title": "Fiscal de Sorte",
		"description": "Um dado de gravata exige licença para coincidências favoráveis na via pública.",
		"color": "#9c7cff",
		"choices": [
			{
				"id": "license_luck", "name": "LICENCIAR A SORTE · 24 CR",
				"effect_text": "O fiscal recalcula o alvo: -14% poder inimigo.",
				"credit_cost": 24, "power_mult": 0.86,
				"result": "Sua sorte agora tem carimbo, validade e direito a uma coincidência útil.",
			},
			{
				"id": "audit_odds", "name": "AUDITAR AS ODDS",
				"effect_text": "+45s de caça e +18% XP por matemática hostil.",
				"duration_add": 45.0, "xp_mult": 1.18,
				"result": "As contas fecham. O cassino abre outra planilha para contestar.",
			},
			{
				"id": "roll_anyway", "name": "ROLAR ASSIM MESMO",
				"effect_text": "+10% vida inimiga, mas +20% créditos sem cobertura atuarial.",
				"health_mult": 1.10, "credits_mult": 1.20,
				"result": "O dado caiu de pé. O contratante chamou isso de cláusula de espetáculo.",
			},
		],
	},
	{
		"id": "pressure_toll",
		"planet_id": "aeropolis_penhora",
		"symbol": "980hPa",
		"title": "Pedágio de Pressão",
		"description": "Uma cabine flutuante cobra pela diferença de pressão entre a sua nave e o céu público.",
		"color": "#8fd3ff",
		"choices": [
			{
				"id": "pay_pressure", "name": "PAGAR 26 CRÉDITOS",
				"effect_text": "A cabine despressuriza a cobertura: -20% defesa do alvo.",
				"credit_cost": 26, "defense_mult": 0.80,
				"result": "O recibo veio selado a vácuo. A armadura do alvo também.",
			},
			{
				"id": "ride_updraft", "name": "APANHAR A CORRENTE",
				"effect_text": "+60s de caça e +20% XP em navegação barométrica.",
				"duration_add": 60.0, "xp_mult": 1.20,
				"result": "A corrente subiu, virou à esquerda e pediu uma avaliação de cinco estrelas.",
			},
			{
				"id": "burst_gate", "name": "ROMPER A COMPORTA",
				"effect_text": "+12% poder inimigo, mas +22% créditos por risco atmosférico.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "A comporta abriu. O processo administrativo chegou pelo vento.",
			},
		],
	},
	{
		"id": "lightning_strike",
		"planet_id": "aeropolis_penhora",
		"symbol": "SEM RAIO",
		"title": "Greve de Para-Raios",
		"description": "Os para-raios cruzaram os braços. As nuvens exigem negociação coletiva imediata.",
		"color": "#ffe66d",
		"choices": [
			{
				"id": "hire_cloud", "name": "CONTRATAR UMA NUVEM · 28 CR",
				"effect_text": "A nuvem denuncia o esconderijo: -14% poder do alvo.",
				"credit_cost": 28, "power_mult": 0.86,
				"result": "A nuvem assinou por descarga e apontou o alvo com um relâmpago discreto.",
			},
			{
				"id": "negotiate_rods", "name": "NEGOCIAR COM OS PARA-RAIOS",
				"effect_text": "+45s de caça e +18% XP em relações atmosféricas.",
				"duration_add": 45.0, "xp_mult": 1.18,
				"result": "O acordo inclui pausas, seguro e uma tempestade pessoal por trimestre.",
			},
			{
				"id": "cross_storm", "name": "ATRAVESSAR A TEMPESTADE",
				"effect_text": "+10% vida inimiga, mas +20% créditos de periculosidade.",
				"health_mult": 1.10, "credits_mult": 1.20,
				"result": "A nave saiu fumegando. O contratante classificou o fumo como experiência premium.",
			},
		],
	},
	{
		"id": "bathyal_customs",
		"planet_id": "arquivo_abissal_n9",
		"symbol": "9.000m",
		"title": "Alfândega Batial",
		"description": "Uma cancela submarina exige declarar cada litro de ar e qualquer pensamento acima da pressão permitida.",
		"color": "#39d7c5",
		"choices": [
			{
				"id": "stamp_oxygen", "name": "CARIMBAR O OXIGÉNIO · 30 CR",
				"effect_text": "O fiscal abre a escotilha do alvo: -20% defesa inimiga.",
				"credit_cost": 30, "defense_mult": 0.80,
				"result": "O oxigénio recebeu visto temporário. A cobertura do alvo perdeu o selo.",
			},
			{
				"id": "inspect_manifest", "name": "INSPECIONAR O MANIFESTO",
				"effect_text": "+60s de caça e +20% XP em burocracia hidrostática.",
				"duration_add": 60.0, "xp_mult": 1.20,
				"result": "O manifesto tinha quarenta páginas e uma pequena lula sem declaração.",
			},
			{
				"id": "dive_under_gate", "name": "MERGULHAR SOB A CANCELA",
				"effect_text": "+12% poder inimigo, mas +22% créditos por risco batial.",
				"power_mult": 1.12, "credits_mult": 1.22,
				"result": "A cancela ficou para trás. A multa aprendeu a nadar.",
			},
		],
	},
	{
		"id": "decompression_queue",
		"planet_id": "arquivo_abissal_n9",
		"symbol": "SENHA 404",
		"title": "Fila de Descompressão",
		"description": "Quatrocentos submarinos aguardam uma cabine com um único botão e intervalo para almoço.",
		"color": "#8de8ff",
		"choices": [
			{
				"id": "buy_priority", "name": "COMPRAR PRIORIDADE · 32 CR",
				"effect_text": "A cabine revela a rota interna: -14% poder do alvo.",
				"credit_cost": 32, "power_mult": 0.86,
				"result": "A prioridade veio numa senha dourada e numa culpa laminada.",
			},
			{
				"id": "wait_pressure", "name": "AGUARDAR A PRESSÃO",
				"effect_text": "+45s de caça e +18% XP em paciência submarina.",
				"duration_add": 45.0, "xp_mult": 1.18,
				"result": "A pressão normalizou. A fila desenvolveu uma sociedade própria.",
			},
			{
				"id": "open_emergency_hatch", "name": "ABRIR A ESCOTILHA DE EMERGÊNCIA",
				"effect_text": "+10% vida inimiga, mas +20% créditos de profundidade.",
				"health_mult": 1.10, "credits_mult": 1.20,
				"result": "A água entrou primeiro. O procedimento disciplinar veio logo atrás.",
			},
		],
	},
]

const ITEM_TRAITS := {
	"weapon": [
		{"id": "crooked_coil", "name": "BOBINA TORTA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0},
		{"id": "argument_amplifier", "name": "AMPLIFICADOR DE ARGUMENTO", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6},
		{"id": "ambush_capacitor", "name": "CAPACITOR DE EMBOSCADA", "description": "+5 dano no primeiro disparo.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 5},
	],
	"armor": [
		{"id": "reactive_lining", "name": "FORRO REATIVO", "description": "+14 de integridade máxima.", "power_bonus": 0, "health_bonus": 14},
		{"id": "illegal_servos", "name": "SERVOS NÃO DECLARADOS", "description": "+1 poder e +8 integridade.", "power_bonus": 1, "health_bonus": 8},
		{"id": "bureaucratic_dampener", "name": "AMORTECEDOR BUROCRÁTICO", "description": "-2 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 2},
	],
	"helmet": [
		{"id": "contraband_visor", "name": "VISEIRA DE CONTRABANDO", "description": "+3 dano de abertura.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3},
		{"id": "cranial_warranty", "name": "GARANTIA CRANIANA", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "neural_calculator", "name": "CALCULADORA NEURAL", "description": "+1 poder e +1 dano de abertura.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 1},
	],
	"gloves": [
		{"id": "unlicensed_servos", "name": "SERVOS SEM LICENÇA", "description": "+2 poder de combate.", "power_bonus": 2, "health_bonus": 0},
		{"id": "reactive_grip", "name": "PEGA REATIVA", "description": "+1 poder e +6 integridade.", "power_bonus": 1, "health_bonus": 6},
		{"id": "parry_mesh", "name": "MALHA DE APARO", "description": "-1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1},
	],
	"boots": [
		{"id": "inertial_soles", "name": "SOLAS INERCIAIS", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "evasion_gyros", "name": "GIROSCÓPIOS DE FUGA", "description": "-1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1},
		{"id": "argument_thrusters", "name": "PROPULSORES DE ARGUMENTO", "description": "+1 poder e +2 dano de abertura.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2},
	],
	"rig": [
		{"id": "smuggler_harness", "name": "ARNÊS DE CONTRABANDO", "description": "+10 de integridade máxima.", "power_bonus": 0, "health_bonus": 10},
		{"id": "counterweight_servos", "name": "SERVOS DE CONTRAPESO", "description": "-1 dano por golpe e +1 contra-ataque a cada 4 turnos.", "power_bonus": 0, "health_bonus": 0, "damage_reduction": 1, "counter_damage_bonus": 1, "counter_every_rounds": 4},
		{"id": "quickdraw_bus", "name": "BARRAMENTO DE SAQUE", "description": "+1 poder, +2 abertura e rajada de 5% em tiro perfeito.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2, "follow_up_roll_threshold": 0.99, "follow_up_damage_ratio": 0.05},
	],
	"implant": [
		{"id": "reflex_archive", "name": "ARQUIVO DE REFLEXOS", "description": "+3 dano de abertura.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3},
		{"id": "illegal_adrenaline", "name": "ADRENALINA ILEGAL", "description": "+1 poder, +6 integridade e +1% esquiva.", "power_bonus": 1, "health_bonus": 6, "evasion_chance_bonus": 0.01},
		{"id": "null_synapse", "name": "SINAPSE NULA", "description": "+2 poder e ignora 1 defesa.", "power_bonus": 2, "health_bonus": 0, "defense_bypass_bonus": 1},
	],
	"gadget": [
		{"id": "warrant_flare", "name": "SINALIZADOR DE MANDADO", "description": "+4 dano de abertura e +4 integridade.", "power_bonus": 0, "health_bonus": 4, "opening_damage_bonus": 4},
		{"id": "probability_decoy", "name": "ISCO DE PROBABILIDADE", "description": "+8 integridade e +1,5% esquiva.", "power_bonus": 0, "health_bonus": 8, "evasion_chance_bonus": 0.015},
		{"id": "breach_assistant", "name": "ASSISTENTE DE RUPTURA", "description": "+1 poder, +2 abertura e ignora 2 defesa.", "power_bonus": 1, "health_bonus": 0, "opening_damage_bonus": 2, "defense_bypass_bonus": 2},
	],
	"relic": [
		{"id": "gravity_knot", "name": "NÓ DE GRAVIDADE", "description": "+16 integridade e -1 dano recebido por golpe.", "power_bonus": 0, "health_bonus": 16, "damage_reduction": 1},
		{"id": "recurring_second", "name": "SEGUNDO RECORRENTE", "description": "+3 abertura e +2 contra-ataque a cada 4 turnos.", "power_bonus": 0, "health_bonus": 0, "opening_damage_bonus": 3, "counter_damage_bonus": 2, "counter_every_rounds": 4},
		{"id": "null_prism", "name": "PRISMA DO NULO", "description": "+2 poder, +8 integridade, ignora 2 defesa e rajada de 5% em tiro perfeito.", "power_bonus": 2, "health_bonus": 8, "defense_bypass_bonus": 2, "follow_up_roll_threshold": 0.99, "follow_up_damage_ratio": 0.05},
	],
}


const ITEM_CATALOG := DustballPrimeContent.ITEMS

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
	"cassino_quasar": {
		"weapon": [
			{"name": "Carabina de Fichas Marcadas", "description": "Cada disparo vale uma entrada e três suspeitas."},
			{"name": "Revólver de Roleta Orbital", "description": "O tambor gira. A estação inteira também."},
			{"name": "Canhão Jackpot Portátil", "description": "Acerta três símbolos iguais e uma parede diferente."},
			{"name": "Lâmina de Crédito Infinito", "description": "Corta armadura, saldo e relações com o gerente."},
		],
		"armor": [
			{"name": "Smoking Antiazar", "description": "Elegante contra lasers e estatisticamente inconclusivo."},
			{"name": "Colete de Fichas Laminadas", "description": "Tilinta ao impacto e exige gorjeta do projétil."},
			{"name": "Manto de Probabilidade Duvidosa", "description": "Talvez proteja. A etiqueta garante cinquenta por cento disso."},
			{"name": "Armadura da Casa", "description": "Absorve dano e devolve apenas os termos de uso."},
		],
	},
	"aeropolis_penhora": {
		"weapon": [
			{"name": "Carabina de Ar Comprimido Premium", "description": "Dispara atmosfera engarrafada e cobra pela tampa."},
			{"name": "Lança-Raios de Prestação", "description": "Cada descarga vence no fim do mês e no início do alvo."},
			{"name": "Mosquete Barométrico", "description": "Prevê chuva, vento e a direção provável da fuga."},
			{"name": "Canhão Cumulonimbus Portátil", "description": "Cabe na mão, mas exige espaço aéreo próprio."},
		],
		"armor": [
			{"name": "Casaco de Pressão Variável", "description": "Aperta em combate e nas cláusulas de cancelamento."},
			{"name": "Colete de Balão Blindado", "description": "Leve, resistente e proibido perto de alfinetes jurídicos."},
			{"name": "Manto de Corrente Ascendente", "description": "Mantém os ombros erguidos e as balas em trânsito."},
			{"name": "Armadura de Cabine Pressurizada", "description": "Inclui oxigénio, apoio lombar e uma pequena taxa por impacto."},
		],
	},
	"arquivo_abissal_n9": {
		"weapon": [
			{"name": "Arpão de Firma Reconhecida", "description": "Perfura casco, cláusulas e qualquer assinatura sem três testemunhas."},
			{"name": "Carabina de Bolhas Comprimidas", "description": "Cada bolha explode com pressão e uma pequena taxa de serviço."},
			{"name": "Lança-Torpedos de Cartório", "description": "O projétil chega autenticado, numerado e ligeiramente atrasado."},
			{"name": "Tridente de Cobrança Hadal", "description": "Tem três pontas para capital, juros e despesas administrativas."},
		],
		"armor": [
			{"name": "Escafandro de Responsabilidade Limitada", "description": "Suporta o abismo, mas não responde por danos emocionais."},
			{"name": "Colete de Coral Notarial", "description": "Cresce uma nova placa sempre que alguém contesta a garantia."},
			{"name": "Manto de Alga Balística", "description": "Flexível, biodegradável e hostil a qualquer arpão não registado."},
			{"name": "Armadura de Submarino Executivo", "description": "Inclui sonar, minibar e uma escotilha exclusiva para recursos."},
		],
	},
}

const SECONDARY_ITEM_CATALOGS := {
	"congelaria_sa": {
		"helmet": [
			{"name": "Capacete de Ponto de Congelamento", "description": "Mantém ideias acima de zero e multas do lado de fora."},
			{"name": "Viseira Antineblina Executiva", "description": "Revela alvos, planilhas e demissões através da geada."},
			{"name": "Touca Balística Homologada", "description": "Parece lã. O setor jurídico insiste que é blindagem."},
			{"name": "Cúpula Criogênica Reversa", "description": "Congela projéteis e descongela decisões ruins."},
		],
	},
	"micelia_404": {
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
	},
	"ferro_velho_omega": {
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
	},
	"cassino_quasar": {
		"helmet": [
			{"name": "Cartola de Probabilidade Blindada", "description": "Protege a cabeça em aproximadamente cem por cento das versões pagas."},
			{"name": "Viseira de Contagem de Cartas", "description": "Marca alvos, fichas e seguranças olhando na direção errada."},
			{"name": "Capacete Jackpot", "description": "Três impactos iguais liberam uma luz piscante sem prêmio."},
			{"name": "Máscara da Casa", "description": "A casa sempre vê primeiro e cobra pela gravação."},
		],
		"gloves": [
			{"name": "Luvas de Crupiê Balístico", "description": "Distribuem cartas, golpes e responsabilidade limitada."},
			{"name": "Manoplas de Fichas Marcadas", "description": "Cada dedo vale uma aposta e duas suspeitas."},
			{"name": "Pegadores de Roleta Orbital", "description": "Seguram o mundo enquanto a mesa continua girando."},
			{"name": "Luvas de Crédito Infinito", "description": "O limite é infinito. A fatura também."},
		],
		"boots": [
			{"name": "Sapatos de Fuga Estatística", "description": "Reduzem a chance de tropeço segundo o próprio fabricante."},
			{"name": "Botas de Roleta Gravitacional", "description": "Mantêm os pés no chão quando o chão perde a aposta."},
			{"name": "Coturnos de Saída VIP", "description": "Atravessam filas e algumas definições locais de parede."},
			{"name": "Propulsores Tudo ou Nada", "description": "Ou pousam perfeitamente ou geram uma história excelente."},
		],
	},
	"aeropolis_penhora": {
		"rig": [
			{"name": "Arnês de Ancoragem Cumulus", "description": "Prende o caçador ao chão quando o chão está de serviço."},
			{"name": "Mochila de Lastro Executivo", "description": "Cheia de chumbo, recibos e decisões com peso legal."},
			{"name": "Colete de Para-Raios Sindicalizado", "description": "Desvia descargas apenas dentro do horário contratual."},
			{"name": "Suspensório Barométrico", "description": "Ajusta postura, pressão e expectativas meteorológicas."},
		],
	},
	"arquivo_abissal_n9": {
		"implant": [
			{"name": "Brânquia de Atendimento Prioritário", "description": "Filtra água, oxigénio e pedidos sem a documentação correta."},
			{"name": "Sonar de Firma Digital", "description": "Reconhece ecos, assinaturas e mentiras a seis mil metros."},
			{"name": "Regulador Neural de Pressão", "description": "Mantém o pensamento estável quando o oceano e os prazos apertam."},
			{"name": "Memória Coralina Auditável", "description": "Arquiva lembranças em recifes e cobra por cada recuperação."},
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


static func board_bounties(reputation: int, planet_id: String, chapter_tier: int, captures_by_target: Dictionary, limit := 3) -> Array[Dictionary]:
	var unlocked := available_bounties(reputation, planet_id, chapter_tier)
	if unlocked.is_empty() or limit <= 0:
		return []
	var primary_index := 0
	for index in unlocked.size():
		if int(unlocked[index].get("chapter_tier", 0)) > int(unlocked[primary_index].get("chapter_tier", 0)):
			primary_index = index
	var primary: Dictionary = unlocked[primary_index]
	var primary_captures := int(captures_by_target.get(str(primary.id), 0))
	var chapter_complete := bool(primary.get("boss", false)) and primary_captures > 0
	var repeats: Array[Dictionary] = []
	for index in unlocked.size():
		if index == primary_index and not chapter_complete:
			continue
		var candidate: Dictionary = unlocked[index].duplicate(true)
		var captures := int(captures_by_target.get(str(candidate.id), 0))
		var mastery_level := CoreRulesScript.target_mastery_level(captures)
		var next_requirement := CoreRulesScript.target_mastery_next_requirement(mastery_level)
		candidate["board_mastery_remaining"] = 999 if next_requirement < 0 else next_requirement - captures
		repeats.append(candidate)
	repeats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var remaining_a := int(a.get("board_mastery_remaining", 999))
		var remaining_b := int(b.get("board_mastery_remaining", 999))
		if remaining_a != remaining_b:
			return remaining_a < remaining_b
		return int(a.get("chapter_tier", 0)) > int(b.get("chapter_tier", 0))
	)
	var result: Array[Dictionary] = []
	if not chapter_complete:
		primary = primary.duplicate(true)
		primary["board_role"] = "primary"
		primary["board_reason"] = "MANDADO FINAL" if bool(primary.get("boss", false)) else "MANDADO PRINCIPAL"
		result.append(primary)
	for candidate in repeats:
		if result.size() >= limit:
			break
		var captures := int(captures_by_target.get(str(candidate.id), 0))
		var mastery_level := CoreRulesScript.target_mastery_level(captures)
		var next_requirement := CoreRulesScript.target_mastery_next_requirement(mastery_level)
		candidate["board_role"] = "repeat"
		candidate["board_reason"] = "CONTRATO RECORRENTE · PERÍCIA MÁX." if next_requirement < 0 else "ROTA DE PERÍCIA · FALTAM %d" % (next_requirement - captures)
		candidate.erase("board_mastery_remaining")
		result.append(candidate)
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


static func target_for_planet_tier(planet_id: String, tier: int) -> Dictionary:
	for target in TARGETS:
		if str(target.get("planet_id", "")) == planet_id and int(target.get("chapter_tier", -1)) == tier:
			return target.duplicate(true)
	return {}


static func planet_tier_from_target_captures(planet_id: String, captures_by_target: Dictionary) -> int:
	var tier := 0
	for prerequisite_tier in 3:
		var prerequisite := target_for_planet_tier(planet_id, prerequisite_tier)
		if prerequisite.is_empty() or int(captures_by_target.get(str(prerequisite.id), 0)) < 3:
			break
		tier = prerequisite_tier + 1
	return tier


static func warrant_progress(planet_id: String, captures_by_target: Dictionary) -> Dictionary:
	var tier := planet_tier_from_target_captures(planet_id, captures_by_target)
	var next_target := target_for_planet_tier(planet_id, tier + 1)
	if next_target.is_empty():
		return {"tier": tier, "next_target": {}, "progress": 0, "requirement": 0}
	var prerequisite := target_for_planet_tier(planet_id, tier)
	return {
		"tier": tier,
		"next_target": next_target,
		"progress": mini(3, int(captures_by_target.get(str(prerequisite.id), 0))),
		"requirement": 3,
		"prerequisite": prerequisite,
	}


static func apply_approach(bounty: Dictionary, approach: Dictionary) -> Dictionary:
	var result := bounty.duplicate(true)
	result["approach"] = approach.duplicate(true)
	# Contract danger affects the encounter, not the equipment tier that drops.
	# Otherwise the fastest recommended route compounds its own power advantage.
	result["loot_power"] = int(bounty.get("loot_power", bounty.power))
	var planet_index := planet_index_for(str(bounty.get("planet_id", PLANET.id)))
	# Small first-chapter targets under-round route multipliers and saturate after
	# the first loot drops. The correction is intentionally isolated to Dustball
	# so established planet balance and endpoint guard rails remain unchanged.
	var frontier_pressure := float(approach.get("frontier_health_bonus", 0.0)) if planet_index == 0 else 0.0
	var health_mult := float(approach.health_mult) + float(approach.get("planet_health_step", 0.0)) * planet_index + frontier_pressure
	if bool(bounty.get("mission_offer", false)):
		result["pursuit_duration"] = maxf(1.0, float(bounty.get("pursuit_duration", 1.0)) * float(approach.duration_mult))
		result["duration"] = maxi(1, ceili(float(bounty.get("travel_duration", 0.0)) + float(result.pursuit_duration)))
	else:
		result["duration"] = maxi(1, ceili(float(bounty.duration) * float(approach.duration_mult)))
	result["power"] = maxi(1, roundi(float(bounty.power) * float(approach.power_mult)))
	result["defense"] = maxi(0, roundi(float(bounty.defense) * float(approach.defense_mult)))
	result["health"] = maxi(1, roundi(float(bounty.health) * health_mult))
	result["credits"] = maxi(1, roundi(float(bounty.credits) * float(approach.credits_mult)))
	result["xp"] = maxi(1, roundi(float(bounty.xp) * float(approach.xp_mult)))
	result["scrap_reward"] = maxi(0, int(approach.get("scrap_reward", 0)))
	return result


static func planet_index_for(planet_id: String) -> int:
	for index in PLANETS.size():
		if str(PLANETS[index].id) == planet_id:
			return index
	return 0


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
	result["hunt_event_choice_id"] = str(choice.get("id", ""))
	result["hunt_event_credit_cost"] = maxi(0, int(choice.get("credit_cost", 0)))
	return result


static func generate_loot(target: Dictionary, rng: RandomNumberGenerator, mastery_level := 0, forced_slot := "") -> Dictionary:
	var planet_id := str(target.get("planet_id", "dustball_prime"))
	var available_slots := loot_slots_for_planet(planet_id)
	var slot := forced_slot if available_slots.has(forced_slot) else choose_loot_slot(available_slots, rng.randf())
	var catalog := item_catalog_for(planet_id, slot)
	var catalog_index := rng.randi_range(0, catalog.size() - 1)
	var definition: Dictionary = catalog[catalog_index]
	var secondary_slot := slot != "weapon" and slot != "armor"
	var quality_roll := rng.randf()
	var base_power := 1 if secondary_slot else int(int(target.get("loot_power", target.power)) * lerpf(0.36, 0.68, quality_roll))
	# Secondary equipment creates lateral build choices instead of three extra
	# weapon curves. Its progression lives in rare modifications, not target tier.
	var rarity_roll := rng.randf()
	var rarity_thresholds := CoreRulesScript.loot_rarity_thresholds(mastery_level)
	var rarity := "Comum"
	var rarity_color := "#b9c2d9"
	var bonus := 0
	if rarity_roll > float(rarity_thresholds.epic):
		rarity = "Épico"
		rarity_color = "#d789ff"
		bonus = 1 if secondary_slot else 5
	elif rarity_roll > float(rarity_thresholds.rare):
		rarity = "Raro"
		rarity_color = "#58d9ff"
		bonus = 0 if secondary_slot else 2
	var generation_seed := rng.randi()
	var item := {
		"id": "%s_%s_%d" % [target.id, slot, generation_seed],
		"name": definition.name,
		"description": definition.description,
		"slot": slot,
		"origin_planet_id": planet_id,
		"template_id": EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index),
		"item_level": EquipmentGenerationRulesScript.item_level(target),
		"quality": EquipmentGenerationRulesScript.quality_for_roll(quality_roll),
		"variant_id": EquipmentGenerationRulesScript.variant_for_roll(generation_seed),
		"generation_seed": generation_seed,
		"power": maxi(1, base_power + bonus),
		"rarity": rarity,
		"color": rarity_color,
	}
	var rare_trait_chance := 0.85 if planet_id == "ferro_velho_omega" or planet_id == "cassino_quasar" else 0.65
	if rarity == "Épico" or (rarity == "Raro" and rng.randf() < rare_trait_chance):
		# Attribute packages replace an ordinary modification; they never stack
		# with one on the same drop. Only secondary gear enters this first slice.
		if AttributePackageRulesScript.is_eligible_slot(slot) and rng.randf() < 0.35:
			item.attribute_package_id = str(AttributePackageRulesScript.package_for_index(rng.randi()).id)
		else:
			var traits: Array = ITEM_TRAITS[slot]
			item.trait = traits[rng.randi_range(0, traits.size() - 1)].duplicate(true)
	return item


static func loot_slots_for_planet(planet_id: String) -> Array[String]:
	match planet_id:
		"congelaria_sa":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet"]
		"micelia_404":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves"]
		"ferro_velho_omega", "cassino_quasar":
			return ["weapon", "weapon", "weapon", "armor", "armor", "helmet", "gloves", "boots"]
		"aeropolis_penhora":
			return ["weapon", "weapon", "weapon", "armor", "armor", "rig", "rig"]
		"arquivo_abissal_n9":
			return ["weapon", "weapon", "weapon", "armor", "armor", "implant", "implant"]
		_:
			return ["weapon", "weapon", "weapon", "armor", "armor"]


static func choose_loot_slot(weighted_slots: Array[String], roll: float) -> String:
	if weighted_slots.is_empty():
		return "weapon"
	var index := mini(weighted_slots.size() - 1, floori(clampf(roll, 0.0, 0.999999) * float(weighted_slots.size())))
	return weighted_slots[index]


static func item_catalog_for(planet_id: String, slot: String) -> Array:
	if slot == "weapon" or slot == "armor":
		var core_family: Dictionary = PLANET_ITEM_CATALOGS.get(planet_id, ITEM_CATALOG)
		return core_family.get(slot, ITEM_CATALOG[slot])
	var secondary_family: Dictionary = SECONDARY_ITEM_CATALOGS.get(planet_id, {})
	return secondary_family.get(slot, [])


static func procedural_collection_ids() -> Array[String]:
	if not procedural_collection_ids_cache.is_empty():
		return procedural_collection_ids_cache.duplicate()
	var ids: Array[String] = []
	for planet in PLANETS:
		var planet_id := str(planet.id)
		for slot in CoreRulesScript.EQUIPMENT_SLOTS:
			var catalog := item_catalog_for(planet_id, slot)
			for catalog_index in catalog.size():
				var template := EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index)
				for variant_id in EquipmentGenerationRulesScript.VARIANT_IDS:
					var collection_id := "%s::%s" % [template, str(variant_id)]
					if not ids.has(collection_id):
						ids.append(collection_id)
	procedural_collection_ids_cache = ids
	return ids.duplicate()


static func procedural_collection_total() -> int:
	if procedural_collection_ids_cache.is_empty():
		procedural_collection_ids()
	return procedural_collection_ids_cache.size()


static func procedural_collection_entries() -> Array[Dictionary]:
	if not procedural_collection_entries_cache.is_empty():
		return procedural_collection_entries_cache.duplicate(true)
	var entries: Array[Dictionary] = []
	for planet in PLANETS:
		var planet_id := str(planet.id)
		for slot in CoreRulesScript.EQUIPMENT_SLOTS:
			var catalog := item_catalog_for(planet_id, slot)
			for catalog_index in catalog.size():
				entries.append({
					"template_id": EquipmentGenerationRulesScript.template_id(planet_id, slot, catalog_index),
					"planet_id": planet_id,
					"slot": slot,
					"name": str(catalog[catalog_index].get("name", "")),
					"description": str(catalog[catalog_index].get("description", "")),
				})
	procedural_collection_entries_cache = entries
	return entries.duplicate(true)


static func player_attack(rng: RandomNumberGenerator) -> String:
	return PLAYER_ATTACKS[rng.randi_range(0, PLAYER_ATTACKS.size() - 1)]


static func target_attack(target: Dictionary, rng: RandomNumberGenerator) -> String:
	var attacks: Array = target.get("attacks", ["Golpe Suspeito"])
	return attacks[rng.randi_range(0, attacks.size() - 1)]
