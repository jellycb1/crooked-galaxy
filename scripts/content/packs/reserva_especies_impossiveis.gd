class_name ReservaEspeciesImpossiveisContent
extends RefCounted

const PLANET := {
	"id": "reserva_especies_impossiveis", "name": "Reserva de Espécies Impossíveis", "unlock_level": 270, "travel_duration": 7200.0,
	"subtitle": "Não observe os animais que ainda não existem.",
	"description": "Um zoológico orbital preserva criaturas apagadas pela lógica, futuros já extintos e predadores que só aparecem quando ninguém olha diretamente.",
	"accent": "#7df2b8", "unlock_after": "agencia_deuses_reformados",
	"completion_text": "A Diretora da Fauna Impossível foi colocada na própria jaula probabilística. Metade dos animais fugiu; a outra metade provou nunca ter estado ali.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "paradox_egg_poacher", "planet_id": "reserva_especies_impossiveis", "name": "Caçador de Ovos Paradoxais", "title": "Rouba crias antes dos próprios progenitores existirem", "description": "Contrabandeia ninhos temporais, falsifica datas de eclosão e vende cada ovo duas vezes em linhas históricas diferentes.", "emoji": "◉", "power": 3820, "loot_power": 3593, "defense": 1740, "health": 67900, "duration": 1475, "credits": 5180000, "xp": 3650000, "rank": 3, "chapter_tier": 0, "attacks": ["Ovo Paradoxal", "Ninho Temporal", "Eclosão Antecipada"], "visual_delivery": "pending_user_asset"},
	{"id": "extinct_future_breeder", "planet_id": "reserva_especies_impossiveis", "name": "Criadora de Futuros Extintos", "title": "Reproduz espécies que desaparecerão amanhã", "description": "Cruza fósseis prematuros, seleciona catástrofes hereditárias e garante pedigree para animais sem passado verificável.", "emoji": "◇", "power": 3895, "loot_power": 3663, "defense": 1774, "health": 69200, "duration": 1501, "credits": 5490000, "xp": 3880000, "rank": 3, "chapter_tier": 1, "attacks": ["Fóssil Prematuro", "Catástrofe Hereditária", "Pedigree sem Passado"], "visual_delivery": "pending_user_asset"},
	{"id": "probability_cage_engineer", "planet_id": "reserva_especies_impossiveis", "name": "Engenheiro de Jaulas Probabilísticas", "title": "Prende monstros apenas na maioria dos universos", "description": "Solda hipóteses, eletrifica possibilidades e considera qualquer fuga uma medição estatisticamente aceitável.", "emoji": "▦", "power": 3972, "loot_power": 3735, "defense": 1809, "health": 70520, "duration": 1527, "credits": 5820000, "xp": 4120000, "rank": 3, "chapter_tier": 2, "attacks": ["Grade Hipotética", "Choque Possível", "Fuga Estatística"], "visual_delivery": "pending_user_asset"},
	{"id": "impossible_fauna_warden", "planet_id": "reserva_especies_impossiveis", "name": "Diretora da Fauna Impossível", "title": "Cataloga predadores que devoram as próprias definições", "description": "Comanda habitats contraditórios, alimenta feras com leis físicas e apaga visitantes que questionam a contagem oficial.", "emoji": "⬡", "power": 4129, "loot_power": 3883, "defense": 1881, "health": 74100, "duration": 1562, "credits": 6170000, "xp": 4380000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Habitat Contraditório", "Lei Física Servida", "Visitante Apagado"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "unobserved_predator_escape", "planet_id": "reserva_especies_impossiveis", "symbol": "NÃO OLHAR", "title": "Predador Não Observado Fugiu", "description": "Uma criatura invisível quando observada abriu a jaula durante uma piscadela coletiva e agora deixa pegadas em todas as direções.", "color": "#7df2b8", "choices": [
		{"id": "buy_indirect_viewing_mirrors", "name": "COMPRAR ESPELHOS · 112 CR", "effect_text": "Os espelhos reduzem a defesa inimiga em 22%.", "credit_cost": 112, "defense_mult": 0.78, "result": "Os espelhos encontraram a criatura e várias versões envergonhadas da equipa."},
		{"id": "track_every_footprint", "name": "SEGUIR CADA PEGADA", "effect_text": "+170s de caça e +22% XP.", "duration_add": 170.0, "xp_mult": 1.22, "result": "Todas as pegadas terminaram no ponto onde ainda não tinham começado."},
		{"id": "sell_invisible_safari", "name": "VENDER SAFÁRI INVISÍVEL", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os visitantes pagaram para não ver nada e exigiram fotografias."},
	]},
	{"id": "future_extinction_arrived_early", "planet_id": "reserva_especies_impossiveis", "symbol": "EXTINÇÃO ADIANTADA", "title": "Extinção Futura Chegou Cedo", "description": "Uma catástrofe marcada para o próximo século entrou pela porta errada e começou a apagar a ala infantil.", "color": "#ff8f70", "choices": [
		{"id": "buy_temporal_quarantine", "name": "COMPRAR QUARENTENA · 113 CR", "effect_text": "A quarentena reduz o poder inimigo em 15%.", "credit_cost": 113, "power_mult": 0.85, "result": "A catástrofe ficou isolada até uma data mutuamente inconveniente."},
		{"id": "evacuate_every_timeline", "name": "EVACUAR CADA LINHA TEMPORAL", "effect_text": "+160s de caça e +20% XP.", "duration_add": 160.0, "xp_mult": 1.20, "result": "A última linha temporal continha apenas o plano de evacuação."},
		{"id": "sell_last_chance_tours", "name": "VENDER ÚLTIMAS VISITAS", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "Os bilhetes esgotaram assim que a extinção ganhou iluminação temática."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Ovo Paradoxal", "description": "Dispara antes de a munição ter sido produzida."},
		{"name": "Projetor de Fósseis Prematuros", "description": "Enterra o impacto no passado do alvo."},
		{"name": "Lançador de Grades Hipotéticas", "description": "Prende o alvo em todas as possibilidades convenientes."},
		{"name": "Canhão de Habitat Contraditório", "description": "Cria um ambiente onde acertar e falhar são obrigatórios."},
	],
	"armor": [
		{"name": "Colete de Eclosão Antecipada", "description": "Abre uma nova camada antes de a anterior partir."},
		{"name": "Traje de Catástrofe Hereditária", "description": "Transmite cada dano para uma geração improvável."},
		{"name": "Armadura de Fuga Estatística", "description": "Considera nove em dez impactos tecnicamente ausentes."},
		{"name": "Uniforme da Fauna Impossível", "description": "Cataloga golpes até deixarem de corresponder à definição."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Observação Indireta", "description": "Mostra ameaças apenas quando o utilizador olha para outro lado."},
		{"name": "Elmo de Pedigree sem Passado", "description": "Recorda ancestrais que ainda não foram inventados."},
		{"name": "Viseira de Probabilidade Enjaulada", "description": "Mantém possibilidades perigosas atrás de uma grade mental."},
		{"name": "Capacete da Fauna Impossível", "description": "Reconhece criaturas que a lógica se recusa a nomear."},
	],
}

const PACK := {"id": "reserva_especies_impossiveis", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
