class_name BolsaLuasFracionadasContent
extends RefCounted

const PLANET := {
	"id": "bolsa_luas_fracionadas",
	"name": "Bolsa de Luas Fracionadas",
	"unlock_level": 170,
	"travel_duration": 4800.0,
	"subtitle": "Compre uma cratera. Assuma a dívida orbital.",
	"description": "Uma bolsa orbital divide luas em milhões de participações, negocia futuros de gravidade e cobra manutenção por crateras que ninguém consegue localizar.",
	"accent": "#b4ff65",
	"unlock_after": "estaleiro_naufragios_temporais",
	"completion_text": "O Acionista Lunar Maioritário perdeu o controlo da lua por uma participação decimal. A bolsa suspendeu a gravidade durante três minutos de silêncio financeiro.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{
		"id": "crater_share_broker", "planet_id": "bolsa_luas_fracionadas", "name": "Corretora de Frações de Cratera",
		"title": "Vende o mesmo impacto por metro quadrado", "description": "Recorta crateras em participações microscópicas, promete vista para o vácuo e omite que a lua está hipotecada.", "emoji": "◔",
		"power": 1388, "loot_power": 1306, "defense": 632, "health": 20730, "duration": 660, "credits": 383000, "xp": 260000, "rank": 3, "chapter_tier": 0,
		"attacks": ["Oferta de Cratera", "Hipoteca de Impacto", "Comissão Orbital"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "gravity_dividend_collector", "planet_id": "bolsa_luas_fracionadas", "name": "Cobrador de Dividendos Gravitacionais",
		"title": "Taxa cada objeto que volta ao chão", "description": "Instala contadores de queda livre, cobra juros por cada aterragem e confisca tudo o que saltar sem licença.", "emoji": "⇣",
		"power": 1420, "loot_power": 1336, "defense": 646, "health": 21220, "duration": 676, "credits": 410000, "xp": 279000, "rank": 3, "chapter_tier": 1,
		"attacks": ["Dividendo de Queda", "Juro Gravitacional", "Confisco de Salto"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "orbital_insider_trader", "planet_id": "bolsa_luas_fracionadas", "name": "Negociante de Órbita Privilegiada",
		"title": "Compra eclipses antes de serem anunciados", "description": "Move satélites com informação reservada, vende noites artificiais e desaparece sempre um segundo antes da fiscalização.", "emoji": "◒",
		"power": 1453, "loot_power": 1367, "defense": 661, "health": 21720, "duration": 692, "credits": 440000, "xp": 300000, "rank": 3, "chapter_tier": 2,
		"attacks": ["Eclipse Privilegiado", "Venda a Descoberto", "Órbita Reservada"], "visual_delivery": "pending_user_asset",
	},
	{
		"id": "majority_moon_owner", "planet_id": "bolsa_luas_fracionadas", "name": "Acionista Lunar Maioritário",
		"title": "Possui cinquenta por cento e mais uma pedra", "description": "Controla assembleias por maré, lança crateras hostis e ameaça deslocar a lua para um paraíso fiscal interplanetário.", "emoji": "●",
		"power": 1522, "loot_power": 1432, "defense": 692, "health": 23380, "duration": 714, "credits": 474000, "xp": 324000, "rank": 3, "chapter_tier": 3, "boss": true,
		"attacks": ["Maioria Absoluta", "Cratera Hostil", "Deslocalização Lunar"], "visual_delivery": "pending_user_asset",
	},
]

const EVENTS := [
	{
		"id": "gravity_market_crash", "planet_id": "bolsa_luas_fracionadas", "symbol": "G ↓ 99%", "title": "Quebra do Mercado Gravitacional",
		"description": "O valor da gravidade cai a pique. Corpos, carteiras e previsões começam a flutuar pelo pregão.", "color": "#b4ff65",
		"choices": [
			{"id": "buy_fall_insurance", "name": "COMPRAR SEGURO DE QUEDA · 83 CR", "effect_text": "A apólice reduz a defesa inimiga em 22%.", "credit_cost": 83, "defense_mult": 0.78, "result": "A seguradora pagou assim que encontrou um chão elegível."},
			{"id": "audit_floating_accounts", "name": "AUDITAR CONTAS FLUTUANTES", "effect_text": "+120s de caça e +22% XP.", "duration_add": 120.0, "xp_mult": 1.22, "result": "Os números fecharam depois de serem presos à secretária."},
			{"id": "short_the_floor", "name": "VENDER O CHÃO A DESCOBERTO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O chão recuperou logo depois de todos venderem os sapatos."},
		],
	},
	{
		"id": "hostile_moon_takeover", "planet_id": "bolsa_luas_fracionadas", "symbol": "LUA 51%", "title": "Aquisição Lunar Hostil",
		"description": "Uma lua menor compra silenciosamente a maioria das ações da lua que orbita e exige trocar de lugar.", "color": "#ffbf55",
		"choices": [
			{"id": "buy_voting_proxy", "name": "COMPRAR PROCURAÇÃO · 84 CR", "effect_text": "Os votos reduzem o poder inimigo em 15%.", "credit_cost": 84, "power_mult": 0.85, "result": "A procuração representava três crateras e um rochedo indeciso."},
			{"id": "recount_every_rock", "name": "RECONTAR CADA ROCHA", "effect_text": "+110s de caça e +20% XP.", "duration_add": 110.0, "xp_mult": 1.20, "result": "A última rocha pediu para se abster."},
			{"id": "back_the_smaller_moon", "name": "APOIAR A LUA MENOR", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A lua menor venceu e aumentou imediatamente a renda orbital."},
		],
	},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Frações de Cratera", "description": "Divide cada impacto por acionista responsável."},
		{"name": "Rifle de Dividendos Gravitacionais", "description": "Devolve cada projétil ao chão com juros."},
		{"name": "Lançador de Eclipses Privilegiados", "description": "Apaga a luz antes de anunciar a venda."},
		{"name": "Canhão da Maioria Absoluta", "description": "Aprova o próprio disparo por cinquenta por cento mais um voto."},
	],
	"armor": [
		{"name": "Colete de Hipoteca Lunar", "description": "Pertence ao banco, mas os impactos ficam com o utilizador."},
		{"name": "Traje de Queda Dividendária", "description": "Capitaliza cada aterragem antes de amortecer o corpo."},
		{"name": "Armadura de Órbita Reservada", "description": "Desvia golpes segundo informação ainda confidencial."},
		{"name": "Fato do Acionista Maioritário", "description": "Transforma qualquer dano numa despesa minoritária."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Cratera Fracionada", "description": "Oferece vista parcial para todos os impactos."},
		{"name": "Elmo de Gravidade Cotada", "description": "Mantém a cabeça em alta quando o mercado cai."},
		{"name": "Viseira de Eclipse Privilegiado", "description": "Escurece um instante antes de toda a concorrência."},
		{"name": "Coroa Lunar Maioritária", "description": "Inclui voto decisivo em cada pancada recebida."},
	],
}

const PACK := {"id": "bolsa_luas_fracionadas", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
