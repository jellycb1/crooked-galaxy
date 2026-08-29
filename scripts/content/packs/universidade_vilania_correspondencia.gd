class_name UniversidadeVilaniaCorrespondenciaContent
extends RefCounted

const PLANET := {
	"id": "universidade_vilania_correspondencia", "name": "Universidade de Vilania por Correspondência", "unlock_level": 250, "travel_duration": 6720.0,
	"subtitle": "O diploma chega antes da primeira aula.",
	"description": "Um campus orbital desmontável ensina monólogos, armadilhas excessivas e gestão de capangas através de aulas enviadas para qualquer planeta com caixa de correio.",
	"accent": "#e76fff", "unlock_after": "cartorio_ultimo_horizonte",
	"completion_text": "O Reitor Magnífico foi reprovado na defesa final. Os estudantes ocuparam o campus e exigiram créditos académicos por cada crime praticado.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "dramatic_monologue_tutor", "planet_id": "universidade_vilania_correspondencia", "name": "Tutora de Monólogos Dramáticos", "title": "Explica todos os planos antes de os executar", "description": "Corrige pausas ameaçadoras, avalia gargalhadas ao vivo e reprova qualquer discurso que permita ao herói fugir cedo demais.", "emoji": "❞", "power": 3188, "loot_power": 2998, "defense": 1452, "health": 54000, "duration": 1306, "credits": 3180000, "xp": 2230000, "rank": 3, "chapter_tier": 0, "attacks": ["Pausa Ameaçadora", "Plano Integral", "Gargalhada Avaliada"], "visual_delivery": "pending_user_asset"},
	{"id": "overengineered_trap_lecturer", "planet_id": "universidade_vilania_correspondencia", "name": "Docente de Armadilhas Excessivas", "title": "Transforma qualquer botão numa hora de perigo", "description": "Instala serras redundantes, acrescenta contagens decrescentes e recusa soluções que usem menos de quatro alçapões.", "emoji": "⚙", "power": 3251, "loot_power": 3058, "defense": 1481, "health": 55100, "duration": 1330, "credits": 3380000, "xp": 2370000, "rank": 3, "chapter_tier": 1, "attacks": ["Serra Redundante", "Contagem Dramática", "Quarto Alçapão"], "visual_delivery": "pending_user_asset"},
	{"id": "henchman_management_dean", "planet_id": "universidade_vilania_correspondencia", "name": "Decano de Gestão de Capangas", "title": "Converte motins em trabalho de grupo", "description": "Distribui uniformes numerados, corta benefícios de lacaios e chama cada traição interna de avaliação entre colegas.", "emoji": "♟", "power": 3316, "loot_power": 3119, "defense": 1510, "health": 56220, "duration": 1354, "credits": 3590000, "xp": 2520000, "rank": 3, "chapter_tier": 2, "attacks": ["Capanga Numerado", "Benefício Cortado", "Motim Curricular"], "visual_delivery": "pending_user_asset"},
	{"id": "magnificent_villainy_rector", "planet_id": "universidade_vilania_correspondencia", "name": "Reitor Magnífico de Vilania", "title": "Acredita crimes antes de serem cometidos", "description": "Assina diplomas malignos, patenteia planos finais e expulsa estudantes que derrotam o herói sem preencher o relatório obrigatório.", "emoji": "♛", "power": 3447, "loot_power": 3242, "defense": 1569, "health": 59200, "duration": 1385, "credits": 3820000, "xp": 2690000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Diploma Maligno", "Plano Final Patenteado", "Expulsão Magnífica"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "mandatory_evil_group_project", "planet_id": "universidade_vilania_correspondencia", "symbol": "GRUPO OBRIGATÓRIO", "title": "Trabalho de Grupo Maligno", "description": "Quatro aspirantes a vilão construíram partes incompatíveis da mesma máquina apocalíptica e todos querem assinar primeiro.", "color": "#e76fff", "choices": [
		{"id": "buy_shared_blueprints", "name": "COMPRAR PLANTAS · 108 CR", "effect_text": "As plantas reduzem a defesa inimiga em 22%.", "credit_cost": 108, "defense_mult": 0.78, "result": "A máquina passou a ter um plano e cinco botões de autodestruição."},
		{"id": "assemble_every_component", "name": "MONTAR CADA PEÇA", "effect_text": "+160s de caça e +22% XP.", "duration_add": 160.0, "xp_mult": 1.22, "result": "A última peça encaixou perfeitamente noutra máquina."},
		{"id": "sell_team_leadership", "name": "VENDER A LIDERANÇA", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Todos compraram o cargo e ninguém ficou responsável."},
	]},
	{"id": "final_exam_hero_escaped", "planet_id": "universidade_vilania_correspondencia", "symbol": "EXAME INTERROMPIDO", "title": "O Herói Fugiu do Exame Final", "description": "O herói convidado soltou-se antes do monólogo terminar, invalidando a avaliação prática de toda a turma.", "color": "#ffd166", "choices": [
		{"id": "buy_emergency_restraints", "name": "COMPRAR AMARRAS · 109 CR", "effect_text": "As amarras reduzem o poder inimigo em 15%.", "credit_cost": 109, "power_mult": 0.85, "result": "As amarras prenderam o herói e dois examinadores distraídos."},
		{"id": "repeat_the_full_monologue", "name": "REPETIR O MONÓLOGO", "effect_text": "+150s de caça e +20% XP.", "duration_add": 150.0, "xp_mult": 1.20, "result": "O segundo monólogo explicou por que o primeiro tinha falhado."},
		{"id": "sell_resit_tickets", "name": "VENDER REPETIÇÕES", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A época de recurso esgotou antes de encontrarem outro herói."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Pausa Ameaçadora", "description": "Espera pelo momento mais dramático antes de disparar."},
		{"name": "Projetor de Serras Redundantes", "description": "Acrescenta uma lâmina sempre que o perigo parece suficiente."},
		{"name": "Lançador de Motins Curriculares", "description": "Transforma desacordo interno em avaliação contínua."},
		{"name": "Canhão de Diploma Maligno", "description": "Certifica o impacto como prática profissional supervisionada."},
	],
	"armor": [
		{"name": "Colete de Gargalhada Avaliada", "description": "Converte aplausos ameaçadores em proteção académica."},
		{"name": "Traje do Quarto Alçapão", "description": "Mantém sempre outra saída perigosa por baixo da anterior."},
		{"name": "Armadura de Capanga Numerado", "description": "Redistribui cada golpe pelo organograma dos lacaios."},
		{"name": "Uniforme do Reitor Magnífico", "description": "Reprova ataques que não cumpram os critérios da disciplina."},
	],
}

const SECONDARY_ITEMS := {
	"boots": [
		{"name": "Botas de Entrada Dramática", "description": "Chegam exatamente depois de toda a sala ficar em silêncio."},
		{"name": "Botas de Alçapão Redundante", "description": "Encontram chão firme apenas quando isso complica o plano."},
		{"name": "Botas de Supervisor de Capangas", "description": "Mantêm distância segura de qualquer motim produtivo."},
		{"name": "Botas Magníficas de Formatura", "description": "Marcham como se cada corredor fosse uma cerimónia final."},
	],
}

const PACK := {"id": "universidade_vilania_correspondencia", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
