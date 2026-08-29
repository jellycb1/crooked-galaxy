class_name CanilAsteroidesDomesticosContent
extends RefCounted

const PLANET := {
	"id": "canil_asteroides_domesticos", "name": "Canil de Asteroides Domésticos", "unlock_level": 230, "travel_duration": 6240.0,
	"subtitle": "Não alimente os cometas depois da meia-noite.",
	"description": "Um arquipélago orbital prende asteroides com campos gravitacionais, ensina cometas a não colidir com visitas e aluga pequenas luas como animais de companhia.",
	"accent": "#ff9d57", "unlock_after": "central_sonhos_penhorados",
	"completion_text": "O Diretor de Controlo Orbital perdeu a trela mestra. Os asteroides foram libertados, embora muitos tenham regressado à hora da refeição.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "unruly_comet_trainer", "planet_id": "canil_asteroides_domesticos", "name": "Treinador de Cometas Indisciplinados", "title": "Ensina gelo em chamas a ficar quieto", "description": "Assobia para órbitas erradas, recompensa caudas brilhantes e chama cada cratera inesperada de progresso comportamental.", "emoji": "☄", "power": 2620, "loot_power": 2464, "defense": 1194, "health": 44500, "duration": 1145, "credits": 1930000, "xp": 1345000, "rank": 3, "chapter_tier": 0, "attacks": ["Cometa Solto", "Assobio Gravitacional", "Cratera Educativa"], "visual_delivery": "pending_user_asset"},
	{"id": "pocket_meteor_breeder", "planet_id": "canil_asteroides_domesticos", "name": "Criadora de Meteoros de Bolso", "title": "Seleciona rochas pela queda mais elegante", "description": "Cruza meteoritos raros, vende cascalho com pedigree e garante que cada impacto demonstra uma personalidade única.", "emoji": "◆", "power": 2673, "loot_power": 2514, "defense": 1218, "health": 45400, "duration": 1167, "credits": 2050000, "xp": 1435000, "rank": 3, "chapter_tier": 1, "attacks": ["Pedigree Mineral", "Queda Elegante", "Ninhada de Cascalho"], "visual_delivery": "pending_user_asset"},
	{"id": "runaway_moon_tracker", "planet_id": "canil_asteroides_domesticos", "name": "Rastreador de Luas Fugitivas", "title": "Segue marés deixadas como pegadas", "description": "Persegue satélites assustados, marca órbitas com cheiro magnético e devolve luas ao planeta errado por uma taxa menor.", "emoji": "◔", "power": 2727, "loot_power": 2565, "defense": 1242, "health": 46320, "duration": 1189, "credits": 2180000, "xp": 1530000, "rank": 3, "chapter_tier": 2, "attacks": ["Pegada de Maré", "Laço Magnético", "Lua Devolvida"], "visual_delivery": "pending_user_asset"},
	{"id": "orbital_control_director", "planet_id": "canil_asteroides_domesticos", "name": "Diretor de Controlo Orbital", "title": "Mantém sistemas solares inteiros pela trela", "description": "Comanda coleiras gravitacionais, licencia luas de guarda e ameaça mandar qualquer planeta desobediente para a casota.", "emoji": "◎", "power": 2834, "loot_power": 2665, "defense": 1291, "health": 48900, "duration": 1217, "credits": 2320000, "xp": 1630000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Coleira Gravitacional", "Lua de Guarda", "Órbita Castigada"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "escaped_meteor_litter", "planet_id": "canil_asteroides_domesticos", "symbol": "NINHADA SOLTA", "title": "Ninhada de Meteoros Fugiu", "description": "Dezenas de meteoros juvenis correm pelo corredor, derrubando sinais e tentando adotar a nave.", "color": "#ff9d57", "choices": [
		{"id": "buy_gravity_treats", "name": "COMPRAR PETISCOS · 104 CR", "effect_text": "Os petiscos reduzem a defesa inimiga em 22%.", "credit_cost": 104, "defense_mult": 0.78, "result": "Os meteoros sentaram-se. O corredor continuou a cair."},
		{"id": "round_up_every_meteor", "name": "RECOLHER A NINHADA", "effect_text": "+150s de caça e +22% XP.", "duration_add": 150.0, "xp_mult": 1.22, "result": "A contagem terminou com um meteoro extra e menos uma lanterna."},
		{"id": "sell_adoption_slots", "name": "VENDER ADOÇÕES", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Todas as vagas foram ocupadas por planetas com jardins frágeis."},
	]},
	{"id": "asteroid_refuses_to_sit", "planet_id": "canil_asteroides_domesticos", "symbol": "ORDEM: SENTA", "title": "Asteroide Recusa Sentar", "description": "Uma rocha de quatro quilómetros ignora o treinador e arrasta metade do canil pela própria órbita.", "color": "#ffd166", "choices": [
		{"id": "buy_reinforced_leash", "name": "COMPRAR TRELA · 105 CR", "effect_text": "A trela reduz o poder inimigo em 15%.", "credit_cost": 105, "power_mult": 0.85, "result": "A trela segurou a rocha e puxou o planeta ligeiramente para a esquerda."},
		{"id": "follow_the_full_orbit", "name": "SEGUIR A ÓRBITA", "effect_text": "+140s de caça e +20% XP.", "duration_add": 140.0, "xp_mult": 1.20, "result": "A volta terminou onde começou, mas com muito mais formulários."},
		{"id": "charge_spectator_seats", "name": "COBRAR BANCADAS", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O público aplaudiu cada colisão e pediu uma temporada completa."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Cometa Solto", "description": "Dispara numa órbita que não aceita comandos."},
		{"name": "Projetor de Pedigree Mineral", "description": "Lança rochas acompanhadas por documentação excessiva."},
		{"name": "Lançador de Luas Fugitivas", "description": "Devolve satélites com velocidade pouco diplomática."},
		{"name": "Canhão de Coleira Gravitacional", "description": "Puxa o alvo para a pior posição possível."},
	],
	"armor": [
		{"name": "Colete de Cratera Educativa", "description": "Regista cada impacto como parte do treino."},
		{"name": "Traje de Cascalho com Pedigree", "description": "Substitui placas partidas por descendentes certificados."},
		{"name": "Armadura de Rastreador Lunar", "description": "Segue danos antes que encontrem o utilizador."},
		{"name": "Uniforme de Controlo Orbital", "description": "Mantém cada golpe a uma distância regulamentar."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Arnês de Treino de Cometas", "description": "Distribui impulsos por uma cauda que não está incluída."},
		{"name": "Rig de Meteoros de Bolso", "description": "Guarda uma ninhada mineral em compartimentos reforçados."},
		{"name": "Arnês de Laço Magnético", "description": "Prende satélites antes que mudem de planeta."},
		{"name": "Rig da Trela Mestra", "description": "Controla órbitas com uma autoridade quase convincente."},
	],
}

const PACK := {"id": "canil_asteroides_domesticos", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
