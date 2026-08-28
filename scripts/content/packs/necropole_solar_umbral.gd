class_name NecropoleSolarUmbralContent
extends RefCounted

const PLANET := {
	"id": "necropole_solar_umbral",
	"name": "Necrópole Solar Umbral",
	"unlock_level": 80,
	"travel_duration": 2640.0,
	"subtitle": "A luz acaba. A taxa de sepultamento não.",
	"description": "Um cemitério orbital de sóis extintos onde estações funerárias engarrafam os últimos fótons, vendem coroas de plasma e antecipam o funeral de estrelas ainda acesas.",
	"accent": "#ffb45e",
	"unlock_after": "condominio_lunar_7",
	"completion_text": "O Coveiro da Última Luz perdeu a concessão do horizonte. Os sóis mortos continuam quietos e os vivos recuperaram o direito de escolher quando apagar.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_PHOTON_PALLBEARER := {
	"id": "photon_pallbearer", "planet_id": "necropole_solar_umbral", "name": "Carregador de Fótons",
	"title": "Condutor do cortejo luminoso", "description": "Transporta caixões de luz entre órbitas e cobra excesso de brilho a qualquer nave que tente ultrapassar.", "emoji": "✦",
	"power": 392, "loot_power": 369, "defense": 175, "health": 3670, "duration": 180, "credits": 12280, "xp": 8400, "rank": 3, "chapter_tier": 0,
	"attacks": ["Caixão Fotónico", "Marcha de Penumbra", "Portagem de Brilho"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_SUNSPOT_WIDOW := {
	"id": "sunspot_widow", "planet_id": "necropole_solar_umbral", "name": "Viúva da Mancha Solar",
	"title": "Herdeira de uma estrela suspeitamente extinta", "description": "Coleciona pensões de fusão, usa um véu de plasma e transforma condolências em procurações irreversíveis.", "emoji": "◒",
	"power": 405, "loot_power": 381, "defense": 181, "health": 3810, "duration": 188, "credits": 13550, "xp": 9280, "rank": 3, "chapter_tier": 1,
	"attacks": ["Véu de Plasma", "Pensão de Fusão", "Luto Coronal"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_FLARE_TAXIDERMIST := {
	"id": "flare_taxidermist", "planet_id": "necropole_solar_umbral", "name": "Taxidermista de Fulgurações",
	"title": "Conservador de explosões já falecidas", "description": "Empalha tempestades solares no auge do clarão e vende cada radiação residual como peça de sala certificada.", "emoji": "⌁",
	"power": 418, "loot_power": 393, "defense": 186, "health": 3960, "duration": 197, "credits": 14940, "xp": 10250, "rank": 3, "chapter_tier": 2,
	"attacks": ["Fulguração Empalhada", "Agulha Magnética", "Exposição Radioativa"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_LAST_LIGHT_UNDERTAKER := {
	"id": "last_light_undertaker", "planet_id": "necropole_solar_umbral", "name": "Coveiro da Última Luz",
	"title": "Concessionário do crepúsculo universal", "description": "Apaga estrelas antes do prazo, enterra os últimos raios e cobra ao universo uma taxa por cada sombra produzida.", "emoji": "✹",
	"power": 444, "loot_power": 417, "defense": 198, "health": 4380, "duration": 208, "credits": 16620, "xp": 11380, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Pá do Crepúsculo", "Funeral Antecipado", "Extinção com Recibo"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_PHOTON_PALLBEARER, TARGET_SUNSPOT_WIDOW, TARGET_FLARE_TAXIDERMIST, TARGET_LAST_LIGHT_UNDERTAKER]

const EVENT_DEAD_STAR_PROCESSION := {
	"id": "dead_star_procession", "planet_id": "necropole_solar_umbral", "symbol": "CORTEJO 0 LUX", "title": "Cortejo de Estrelas Mortas",
	"description": "Rebocadores funerários ocupam todas as órbitas enquanto escoltam um sol extinto para uma parcela de vazio com vista eterna.", "color": "#ffb45e",
	"choices": [
		{"id": "pay_funeral_toll", "name": "PAGAR PORTAGEM FÚNEBRE · 47 CR", "effect_text": "O cortejo abre a mortalha defensiva: -22% defesa inimiga.", "credit_cost": 47, "defense_mult": 0.78, "result": "A portagem incluiu flores, recibo e dois minutos de silêncio gravitacional."},
		{"id": "catalog_eulogies", "name": "CATALOGAR OS ELOGIOS", "effect_text": "+75s de caça e +22% XP em protocolo de extinção.", "duration_add": 75.0, "xp_mult": 1.22, "result": "O elogio tinha mais anexos do que a estrela teve planetas."},
		{"id": "overtake_hearse", "name": "ULTRAPASSAR O CARRO FÚNEBRE", "effect_text": "+13% poder inimigo, mas +25% créditos por urgência orbital.", "power_mult": 1.13, "credits_mult": 1.25, "result": "A ultrapassagem foi rápida. A perseguição ganhou sirenes de luto."},
	],
}

const EVENT_LAST_RAY_AUCTION := {
	"id": "last_ray_auction", "planet_id": "necropole_solar_umbral", "symbol": "LOTE 1 FÓTON", "title": "Leilão dos Últimos Raios",
	"description": "Um pregão sem janelas vende os últimos fótons de uma estrela em lotes numerados, cada um com procedência emocional duvidosa.", "color": "#9b7cff",
	"choices": [
		{"id": "buy_dimness_certificate", "name": "COMPRAR CERTIFICADO DE SOMBRA · 48 CR", "effect_text": "O certificado reduz a alimentação do alvo: -15% poder inimigo.", "credit_cost": 48, "power_mult": 0.85, "result": "A sombra veio autenticada, numerada e estranhamente quente."},
		{"id": "verify_photon_origin", "name": "VERIFICAR A PROCEDÊNCIA", "effect_text": "+65s de caça e +20% XP em arqueologia fotónica.", "duration_add": 65.0, "xp_mult": 1.20, "result": "Metade dos fótons era contrabando. A outra metade recusou testemunhar."},
		{"id": "steal_final_lot", "name": "ROUBAR O LOTE FINAL", "effect_text": "+12% vida inimiga, mas +23% créditos de revenda luminosa.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O último raio coube no porta-luvas e iluminou imediatamente o mandado."},
	],
}

const EVENTS := [EVENT_DEAD_STAR_PROCESSION, EVENT_LAST_RAY_AUCTION]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Elogio Fotónico", "description": "Cada disparo dedica algumas palavras ao alvo antes de o interromper."},
		{"name": "Lança-Fulgurações de Cortejo", "description": "Transforma uma despedida solene num problema magnético de grande alcance."},
		{"name": "Foice de Coroa Enlutada", "description": "Colhe plasma maduro e deixa condolências gravadas na órbita."},
		{"name": "Canhão da Última Luz", "description": "Dispara o clarão final agora para não ter de esperar milhares de milhões de anos."},
	],
	"armor": [
		{"name": "Casaco de Cinza Estelar", "description": "Ainda guarda calor suficiente para negar qualquer pedido de reembolso."},
		{"name": "Traje de Mortalha Magnética", "description": "Enrola projéteis em tecido de campo e envia-os para o velório errado."},
		{"name": "Colete de Luto Coronal", "description": "Absorve radiação e expressa pesar apenas dentro do horário laboral."},
		{"name": "Armadura do Funeral Solar", "description": "Inclui blindagem cerimonial, ombreiras de plasma e lugar reservado no cortejo."},
	],
}

const SECONDARY_ITEMS := {
	"rig": [
		{"name": "Arnês de Carregador Fotónico", "description": "Distribui o peso da luz morta por ombros que já viram coisas piores."},
		{"name": "Contrapeso de Coroa Negra", "description": "Mantém o caçador estável quando o horizonte decide colapsar."},
		{"name": "Urna de Fótons de Saque Rápido", "description": "Guarda um último clarão para emergências e reuniões excessivamente sombrias."},
		{"name": "Suporte do Coveiro Umbral", "description": "Prende ferramentas, recibos e uma pá dobrável para estrelas de pequeno porte."},
	],
}

const PACK := {
	"id": "necropole_solar_umbral",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
