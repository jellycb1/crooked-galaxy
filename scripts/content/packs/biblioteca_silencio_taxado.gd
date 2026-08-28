class_name BibliotecaSilencioTaxadoContent
extends RefCounted

const PLANET := {
	"id": "biblioteca_silencio_taxado",
	"name": "Biblioteca do Silêncio Taxado",
	"unlock_level": 110,
	"travel_duration": 3360.0,
	"subtitle": "Falar é permitido. Pagar é obrigatório.",
	"description": "Uma lua de cristal escavada em estantes quilométricas, onde sons proibidos são engarrafados, ecos precisam de licença e cada sussurro atrasado acumula juros acústicos.",
	"accent": "#9f8cff",
	"unlock_after": "museu_amanha_obsoleto",
	"completion_text": "A Grã-Bibliotecária do Silêncio Absoluto perdeu a licença para calar a galáxia. Os ecos voltaram às prateleiras e, pela primeira vez, ninguém cobrou pela pausa dramática.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_SHUSHING_DRONE := {
	"id": "shushing_drone", "planet_id": "biblioteca_silencio_taxado", "name": "Drone de Psiu Automático",
	"title": "Fiscal de decibéis não autorizados", "description": "Patrulha corredores com um medidor de ruído, multa respirações entusiásticas e silencia motores que não têm cartão de leitor.", "emoji": "⌁",
	"power": 615, "loot_power": 579, "defense": 275, "health": 6820, "duration": 305, "credits": 40000, "xp": 27200, "rank": 3, "chapter_tier": 0,
	"attacks": ["Psiu Supersónico", "Multa de Decibéis", "Carimbo Abafador"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ECHO_SMUGGLER := {
	"id": "echo_smuggler", "planet_id": "biblioteca_silencio_taxado", "name": "Contrabandista de Ecos",
	"title": "Transporta segundas vozes sem declaração", "description": "Esconde gargalhadas em capas falsas, vende trovões de bolso e atravessa a alfândega acústica repetindo sempre a versão errada.", "emoji": "≈",
	"power": 634, "loot_power": 597, "defense": 284, "health": 7070, "duration": 316, "credits": 44050, "xp": 29950, "rank": 3, "chapter_tier": 1,
	"attacks": ["Gargalhada Clandestina", "Trovão de Bolso", "Eco com Identidade Falsa"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_OVERDUE_BALLAD_COLLECTOR := {
	"id": "overdue_ballad_collector", "planet_id": "biblioteca_silencio_taxado", "name": "Cobradora de Baladas Atrasadas",
	"title": "Recupera refrões com juros", "description": "Confisca melodias vencidas, transforma canções de embalar em avisos de cobrança e nunca aceita silêncio como prova de pagamento.", "emoji": "♫",
	"power": 653, "loot_power": 615, "defense": 293, "health": 7330, "duration": 328, "credits": 48460, "xp": 33020, "rank": 3, "chapter_tier": 2,
	"attacks": ["Refrão em Dívida", "Penhora Harmónica", "Juro Crescendo"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ABSOLUTE_SILENCE_LIBRARIAN := {
	"id": "absolute_silence_librarian", "planet_id": "biblioteca_silencio_taxado", "name": "Grã-Bibliotecária do Silêncio Absoluto",
	"title": "Detentora dos direitos sobre toda pausa", "description": "Arquiva explosões por ordem alfabética, cobra royalties ao vazio e pretende transformar o universo inteiro numa sala de leitura sem saída.", "emoji": "∅",
	"power": 692, "loot_power": 652, "defense": 311, "health": 8100, "duration": 342, "credits": 53650, "xp": 36500, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Silêncio Absoluto", "Explosão Arquivada", "Encerramento da Sala de Leitura"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_SHUSHING_DRONE, TARGET_ECHO_SMUGGLER, TARGET_OVERDUE_BALLAD_COLLECTOR, TARGET_ABSOLUTE_SILENCE_LIBRARIAN]

const EVENT_FORBIDDEN_SOUND_RETURN := {
	"id": "forbidden_sound_return", "planet_id": "biblioteca_silencio_taxado", "symbol": "DEVOLUÇÃO: 99 dB", "title": "Devolução de Som Proibido",
	"description": "Um frasco de trovão vencido rola para a rota da nave e exige assinatura antes de regressar à secção de ruídos perigosos.", "color": "#9f8cff",
	"choices": [
		{"id": "pay_late_sound_fee", "name": "PAGAR MULTA SONORA · 59 CR", "effect_text": "O recibo revela a frequência da blindagem: -22% defesa inimiga.", "credit_cost": 59, "defense_mult": 0.78, "result": "A multa cobriu três segundos de trovão e uma eternidade de custos administrativos."},
		{"id": "catalog_full_thunder", "name": "CATALOGAR TODO O TROVÃO", "effect_text": "+90s de caça e +22% XP em biblioteconomia acústica.", "duration_add": 90.0, "xp_mult": 1.22, "result": "O trovão ocupou sete volumes e recusou falar baixo durante a indexação."},
		{"id": "uncork_forbidden_sound", "name": "DESTAPAR O FRASCO", "effect_text": "+13% poder inimigo, mas +25% créditos de direitos sonoros.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O som escapou, pediu silêncio e deixou a conta para a nave."},
	],
}

const EVENT_ECHO_READING_ROOM := {
	"id": "echo_reading_room", "planet_id": "biblioteca_silencio_taxado", "symbol": "SALA ECO B", "title": "Sala de Leitura com Eco",
	"description": "Cada movimento da nave regressa como uma reclamação sussurrada, carimbada e ligeiramente mais alta do que o original.", "color": "#66d9d0",
	"choices": [
		{"id": "buy_acoustic_membership", "name": "COMPRAR CARTÃO ACÚSTICO · 60 CR", "effect_text": "O cartão cancela a ressonância ofensiva: -15% poder inimigo.", "credit_cost": 60, "power_mult": 0.85, "result": "A adesão ofereceu cancelamento de ruído e renovação automática para sempre."},
		{"id": "follow_echo_catalog", "name": "SEGUIR O CATÁLOGO DE ECOS", "effect_text": "+80s de caça e +20% XP em rastreio de reverberações.", "duration_add": 80.0, "xp_mult": 1.20, "result": "O último eco apontou para o primeiro, que alegou não se lembrar de nada."},
		{"id": "record_illegal_echo", "name": "GRAVAR O ECO ILEGAL", "effect_text": "+12% vida inimiga, mas +23% créditos de revenda acústica.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A gravação vendeu depressa. A ordem de silêncio chegou ainda mais depressa."},
	],
}

const EVENTS := [EVENT_FORBIDDEN_SOUND_RETURN, EVENT_ECHO_READING_ROOM]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Psiu Supersónico", "description": "Dispara uma ordem de silêncio tão rápida que chega antes do próprio tiro."},
		{"name": "Lança-Ecos Clandestinos", "description": "Repete cada impacto sem declarar nenhuma das cópias à alfândega."},
		{"name": "Canhão de Refrão Penhorado", "description": "Cobra a mesma rajada em prestações cada vez mais barulhentas."},
		{"name": "Emissor do Silêncio Absoluto", "description": "Remove o som, a discussão e ocasionalmente a parede que os separava."},
	],
	"armor": [
		{"name": "Casaco de Fiscal Acústico", "description": "Inclui bolsos para multas e isolamento contra desculpas em volume elevado."},
		{"name": "Traje de Contrabando Reverberante", "description": "Esconde ecos entre camadas que juram nunca ter ouvido nada."},
		{"name": "Colete de Cobrança Harmónica", "description": "Absorve impactos e devolve cada um com juros compostos."},
		{"name": "Armadura da Sala Sem Som", "description": "Torna qualquer batalha tão silenciosa quanto uma cláusula importante."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Carimbo Abafador", "description": "Aprovam silêncio e rejeitam ruído com o mesmo movimento burocrático."},
		{"name": "Manoplas de Eco Falso", "description": "Cada golpe deixa uma segunda assinatura que ninguém consegue autenticar."},
		{"name": "Punhos de Cobrança Crescendo", "description": "Apertam progressivamente até a dívida ou o alvo deixar de responder."},
		{"name": "Luvas da Grã-Bibliotecária", "description": "Viraram páginas, fecharam arquivos e silenciaram civilizações inteiras."},
	],
}

const PACK := {
	"id": "biblioteca_silencio_taxado",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
