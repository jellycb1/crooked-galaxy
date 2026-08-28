class_name CongelariaContent
extends RefCounted

const PLANET := {
	"id": "congelaria_sa",
	"name": "Congelária S.A.",
	"unlock_level": 4,
	"travel_duration": 480.0,
	"subtitle": "Tudo abaixo de zero. Inclusive o atendimento.",
	"description": "Um frigorífico planetário privatizado, com geleiras, cubículos e multas por aquecimento.",
	"accent": "#72f1dd",
	"unlock_after": "dustball_prime",
	"completion_text": "A diretoria foi descongelada de suas funções. O termostato agora aceita votos e moedas.",
}

const TARGET_AUDITOR_FROST := {
	"id": "auditor_frost", "planet_id": "congelaria_sa", "name": "Auditor Geada",
	"title": "Fiscal de aquecedores clandestinos", "description": "Confiscou o último cobertor do hemisfério sul por excesso de conforto.", "emoji": "❄",
	"power": 31, "loot_power": 28, "defense": 12, "health": 245, "duration": 13, "credits": 146, "xp": 140, "rank": 3, "chapter_tier": 0,
	"attacks": ["Auto de Infração Glacial", "Caneta Criogênica", "Juros Congelantes"],
}

const TARGET_CHEF_COLDFLAME := {
	"id": "chef_coldflame", "planet_id": "congelaria_sa", "name": "Chef Brasa Fria",
	"title": "Contrabandista de sopa acima de zero", "description": "Serviu caldo morno sem licença térmica. Três executivos descongelaram sentimentos.", "emoji": "♨",
	"power": 35, "loot_power": 32, "defense": 14, "health": 270, "duration": 15, "credits": 174, "xp": 166, "rank": 3, "chapter_tier": 1,
	"attacks": ["Concha de Lava", "Caldo Clandestino", "Pimenta de Reentrada"],
}

const TARGET_EXECUTIVE_PENGUIN := {
	"id": "executive_penguin", "planet_id": "congelaria_sa", "name": "Pinguim Executivo",
	"title": "Diretor de demissões em massa polar", "description": "Terceirizou o próprio bando e vendeu os peixes da confraternização.", "emoji": "▰",
	"power": 40, "loot_power": 37, "defense": 17, "health": 315, "duration": 17, "credits": 208, "xp": 196, "rank": 3, "chapter_tier": 2,
	"attacks": ["Gravata Torpedo", "Reunião Sem Pauta", "Bicada de Desligamento"],
}

const TARGET_DIRECTOR_KELVIN := {
	"id": "director_kelvin", "planet_id": "congelaria_sa", "name": "Diretora Kelvin",
	"title": "CEO vitalícia do frio corporativo", "description": "Patenteou o zero absoluto e agora cobra royalties de todo termômetro.", "emoji": "◆",
	"power": 45, "loot_power": 43, "defense": 20, "health": 335, "duration": 20, "credits": 268, "xp": 248, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Fusão Hostil", "Zero Absoluto Fiscal", "Sinergia Criogênica"],
}

const TARGETS := [TARGET_AUDITOR_FROST, TARGET_CHEF_COLDFLAME, TARGET_EXECUTIVE_PENGUIN, TARGET_DIRECTOR_KELVIN]

const EVENT_HEAT_INSPECTOR := {
	"id": "heat_inspector", "planet_id": "congelaria_sa", "symbol": "-40°", "title": "Fiscal de Calor",
	"description": "Um termômetro de terno detectou intenções acima da temperatura permitida.", "color": "#72f1dd",
	"choices": [
		{"id": "pay_cooling_fee", "name": "PAGAR 12 CRÉDITOS", "effect_text": "O fiscal congela juntas expostas: -20% defesa do alvo.", "credit_cost": 12, "defense_mult": 0.80, "result": "A taxa de resfriamento foi paga. Até os parafusos do alvo bateram os dentes."},
		{"id": "fake_badge", "name": "FALSIFICAR UM CRACHÁ", "effect_text": "+45s de caça e +18% XP pela experiência corporativa.", "duration_add": 45.0, "xp_mult": 1.18, "result": "Seu novo cargo é Vice-Caçador Sênior. Ninguém pediu referências."},
		{"id": "overclock_heater", "name": "LIGAR O AQUECEDOR", "effect_text": "+10% poder inimigo, mas +20% créditos por insalubridade.", "power_mult": 1.10, "credits_mult": 1.20, "result": "O aquecedor disparou alarmes, bônus de risco e uma torrada esquecida."},
	],
}

const EVENT_CORPORATE_AVALANCHE := {
	"id": "corporate_avalanche", "planet_id": "congelaria_sa", "symbol": "RACHOU", "title": "Avalanche Corporativa",
	"description": "A geleira foi reestruturada sem aviso prévio e metade da rota foi demitida.", "color": "#a97cff",
	"choices": [
		{"id": "melt_route", "name": "DERRETER A ROTA · 10 CR", "effect_text": "Atalho térmico: o alvo perde 15% de vida.", "credit_cost": 10, "health_mult": 0.85, "result": "A rota derreteu. O departamento jurídico também, mas só um pouco."},
		{"id": "climb_shelf", "name": "ESCALAR A GELEIRA", "effect_text": "+60s de caça e +20% XP por treinamento não solicitado.", "duration_add": 60.0, "xp_mult": 1.20, "result": "Você escalou a nova hierarquia glacial sem uma única reunião."},
		{"id": "surf_collapse", "name": "SURFAR O COLAPSO", "effect_text": "+12% poder inimigo, mas +22% créditos pelo espetáculo.", "power_mult": 1.12, "credits_mult": 1.22, "result": "A manobra recebeu nota dez e uma advertência de segurança."},
	],
}

const EVENTS := [EVENT_HEAT_INSPECTOR, EVENT_CORPORATE_AVALANCHE]

const ITEMS := {
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
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Ponto de Congelamento", "description": "Mantém ideias acima de zero e multas do lado de fora."},
		{"name": "Viseira Antineblina Executiva", "description": "Revela alvos, planilhas e demissões através da geada."},
		{"name": "Touca Balística Homologada", "description": "Parece lã. O setor jurídico insiste que é blindagem."},
		{"name": "Cúpula Criogênica Reversa", "description": "Congela projéteis e descongela decisões ruins."},
	],
}

const PACK := {
	"id": "congelaria_sa",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
