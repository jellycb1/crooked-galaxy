class_name CassinoQuasarContent
extends RefCounted

const PLANET := {
	"id": "cassino_quasar",
	"name": "Cassino Quasar",
	"unlock_level": 19,
	"travel_duration": 1200.0,
	"subtitle": "A casa sempre ganha. E cobra estacionamento.",
	"description": "Um resort orbital construído em torno de uma estrela viciada, com roletas gravitacionais e probabilidades sob licença.",
	"accent": "#ff75d8",
	"unlock_after": "ferro_velho_omega",
	"completion_text": "A Casa finalmente perdeu. O prêmio foi parcelado em eras geológicas e a saída continua passando pela loja de lembranças.",
}

const TARGET_DEALER_COMET := {
	"id": "dealer_comet", "planet_id": "cassino_quasar", "name": "Crupiê Cometa",
	"title": "Distribuidor de órbitas marcadas", "description": "Embaralhou sete luas e jura que o eclipse na manga veio de fábrica.", "emoji": "♠",
	"power": 96, "defense": 43, "health": 700, "duration": 42, "credits": 870, "xp": 750, "rank": 3, "chapter_tier": 0,
	"attacks": ["Baralho Balístico", "Corte de Órbita", "Aposta Cega"],
}

const TARGET_DUCHESS_JACKPOT := {
	"id": "duchess_jackpot", "planet_id": "cassino_quasar", "name": "Duquesa Jackpot",
	"title": "Herdeira das máquinas caça-luas", "description": "Transformou a gravidade em assinatura premium e o chão em conteúdo patrocinado.", "emoji": "♦",
	"power": 104, "defense": 47, "health": 770, "duration": 44, "credits": 955, "xp": 820, "rank": 3, "chapter_tier": 1,
	"attacks": ["Jackpot de Plasma", "Salto Alto Gravitacional", "Dividendos Marcados"],
}

const TARGET_MISFORTUNE_AUDITOR := {
	"id": "misfortune_auditor", "planet_id": "cassino_quasar", "name": "Auditor do Azar",
	"title": "Fiscal de probabilidades não declaradas", "description": "Multa coincidências, confisca trevos e exige recibo de todo golpe de sorte.", "emoji": "%",
	"power": 113, "defense": 51, "health": 830, "duration": 47, "credits": 1055, "xp": 900, "rank": 3, "chapter_tier": 2,
	"attacks": ["Juros do Destino", "Auto de Má Fortuna", "Probabilidade Reversa"],
}

const TARGET_HOUSE_ETERNAL := {
	"id": "house_eternal", "planet_id": "cassino_quasar", "name": "A Casa Eterna",
	"title": "Cassino senciente de saldo infinito", "description": "Calcula todas as escolhas possíveis e oferece bebida grátis apenas na pior delas.", "emoji": "♛",
	"power": 124, "defense": 56, "health": 900, "duration": 51, "credits": 1230, "xp": 1040, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Vantagem da Casa", "Roleta de Singularidade", "Última Ficha"],
}

const TARGETS := [TARGET_DEALER_COMET, TARGET_DUCHESS_JACKPOT, TARGET_MISFORTUNE_AUDITOR, TARGET_HOUSE_ETERNAL]

const EVENT_GRAVITY_ROULETTE := {
	"id": "gravity_roulette", "planet_id": "cassino_quasar", "symbol": "17?", "title": "Roleta Gravitacional",
	"description": "A avenida gira, a nave flutua e uma voz anuncia que cair também conta como aposta.", "color": "#ff75d8",
	"choices": [
		{"id": "buy_anchor", "name": "ALUGAR ÂNCORA · 22 CR", "effect_text": "A rota estabiliza e expõe o alvo: -20% defesa.", "credit_cost": 22, "defense_mult": 0.80, "result": "A âncora veio com recibo, corrente e uma taxa por conceito de baixo."},
		{"id": "ride_spin", "name": "SEGUIR O GIRO", "effect_text": "+60s de caça e +20% XP em física recreativa.", "duration_add": 60.0, "xp_mult": 1.20, "result": "Três voltas depois, você entende gravidade e desaprova a gerência."},
		{"id": "bet_on_red", "name": "APOSTAR NO VERMELHO", "effect_text": "+12% poder inimigo, mas +22% créditos se a nave parar inteira.", "power_mult": 1.12, "credits_mult": 1.22, "result": "Deu vermelho. O alvo também ficou sabendo e trouxe munição temática."},
	],
}

const EVENT_LUCK_INSPECTOR := {
	"id": "luck_inspector", "planet_id": "cassino_quasar", "symbol": "1:∞", "title": "Fiscal de Sorte",
	"description": "Um dado de gravata exige licença para coincidências favoráveis na via pública.", "color": "#9c7cff",
	"choices": [
		{"id": "license_luck", "name": "LICENCIAR A SORTE · 24 CR", "effect_text": "O fiscal recalcula o alvo: -14% poder inimigo.", "credit_cost": 24, "power_mult": 0.86, "result": "Sua sorte agora tem carimbo, validade e direito a uma coincidência útil."},
		{"id": "audit_odds", "name": "AUDITAR AS ODDS", "effect_text": "+45s de caça e +18% XP por matemática hostil.", "duration_add": 45.0, "xp_mult": 1.18, "result": "As contas fecham. O cassino abre outra planilha para contestar."},
		{"id": "roll_anyway", "name": "ROLAR ASSIM MESMO", "effect_text": "+10% vida inimiga, mas +20% créditos sem cobertura atuarial.", "health_mult": 1.10, "credits_mult": 1.20, "result": "O dado caiu de pé. O contratante chamou isso de cláusula de espetáculo."},
	],
}

const EVENTS := [EVENT_GRAVITY_ROULETTE, EVENT_LUCK_INSPECTOR]

const ITEMS := {
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
}

const SECONDARY_ITEMS := {
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
}

const PACK := {
	"id": "cassino_quasar",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
