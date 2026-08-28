class_name ResortHorizonteEventosContent
extends RefCounted

const PLANET := {
	"id": "resort_horizonte_eventos",
	"name": "Resort do Horizonte de Eventos",
	"unlock_level": 120,
	"travel_duration": 3600.0,
	"subtitle": "Relaxe. O tempo não tem para onde fugir.",
	"description": "Um arquipélago de hotéis orbitando um buraco negro, onde hóspedes reservam espreguiçadeiras por séculos, o pequeno-almoço nunca termina e cada atraso é vendido como dilatação temporal premium.",
	"accent": "#ff9f68",
	"unlock_after": "biblioteca_silencio_taxado",
	"completion_text": "O Proprietário do Último Pôr do Sol perdeu o controlo do resort. O horizonte continua sem saída, mas pelo menos o minibar deixou de cobrar juros relativísticos.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_TOWEL_RESERVATION_DRONE := {
	"id": "towel_reservation_drone", "planet_id": "resort_horizonte_eventos", "name": "Drone de Reserva de Toalhas",
	"title": "Ocupa espreguiçadeiras antes da criação do universo", "description": "Marca cadeiras vazias com toalhas gravitacionais e vaporiza qualquer hóspede que questione uma reserva feita no século anterior.", "emoji": "▱",
	"power": 712, "loot_power": 670, "defense": 320, "health": 8370, "duration": 355, "credits": 59000, "xp": 40100, "rank": 3, "chapter_tier": 0,
	"attacks": ["Toalha Gravitacional", "Reserva Retroativa", "Espreguiçadeira Balística"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_SINGULARITY_LIFEGUARD := {
	"id": "singularity_lifeguard", "planet_id": "resort_horizonte_eventos", "name": "Salva-Vidas da Singularidade",
	"title": "Proíbe mergulhos depois do ponto sem retorno", "description": "Apita para ondas de luz, resgata turistas de órbitas instáveis e cobra suplemento a quem precisar de voltar do futuro.", "emoji": "◉",
	"power": 734, "loot_power": 691, "defense": 330, "health": 8670, "duration": 367, "credits": 64950, "xp": 44150, "rank": 3, "chapter_tier": 1,
	"attacks": ["Apito Relativístico", "Boia de Singularidade", "Resgate com Suplemento"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_TIME_DILATION_CONCIERGE := {
	"id": "time_dilation_concierge", "planet_id": "resort_horizonte_eventos", "name": "Concierge da Dilatação Temporal",
	"title": "Transforma cada espera em serviço de luxo", "description": "Atrasa check-ins até parecerem exclusivos, envelhece reclamações numa gaveta e entrega chaves de quartos que ainda não foram construídos.", "emoji": "⌚",
	"power": 756, "loot_power": 712, "defense": 340, "health": 8980, "duration": 380, "credits": 71440, "xp": 48630, "rank": 3, "chapter_tier": 2,
	"attacks": ["Check-In Assintótico", "Reclamação Envelhecida", "Chave do Quarto Futuro"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_LAST_SUNSET_OWNER := {
	"id": "last_sunset_owner", "planet_id": "resort_horizonte_eventos", "name": "Proprietário do Último Pôr do Sol",
	"title": "Detentor vitalício da vista para o fim", "description": "Privatizou o horizonte de eventos, aluga pores do sol por minuto local e ameaça despejar qualquer planeta que bloqueie a vista.", "emoji": "●",
	"power": 801, "loot_power": 754, "defense": 361, "health": 9930, "duration": 395, "credits": 79050, "xp": 53700, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Pôr do Sol Privatizado", "Despejo Planetário", "Última Chamada do Horizonte"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_TOWEL_RESERVATION_DRONE, TARGET_SINGULARITY_LIFEGUARD, TARGET_TIME_DILATION_CONCIERGE, TARGET_LAST_SUNSET_OWNER]

const EVENT_INFINITE_BREAKFAST_BUFFET := {
	"id": "infinite_breakfast_buffet", "planet_id": "resort_horizonte_eventos", "symbol": "BUFFET ∞", "title": "Buffet de Pequeno-Almoço Infinito",
	"description": "A rota atravessa um buffet que repõe cada prato antes de ser servido e mantém milhares de turistas presos na mesma primeira refeição.", "color": "#ffbd66",
	"choices": [
		{"id": "buy_priority_table", "name": "COMPRAR MESA PRIORITÁRIA · 63 CR", "effect_text": "A reserva expõe a entrada de serviço: -22% defesa inimiga.", "credit_cost": 63, "defense_mult": 0.78, "result": "A mesa tinha vista para o vazio e uma taxa separada para olhar."},
		{"id": "finish_every_course", "name": "PROVAR TODOS OS PRATOS", "effect_text": "+95s de caça e +22% XP em gastronomia infinita.", "duration_add": 95.0, "xp_mult": 1.22, "result": "A sobremesa chegou antes da entrada, mas vários anos depois da fome."},
		{"id": "raid_premium_buffet", "name": "ASSALTAR O BUFFET PREMIUM", "effect_text": "+13% poder inimigo, mas +25% créditos de minibar recuperado.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O buffet perdeu três bandejas. A segurança ganhou uma motivação sem fundo."},
	],
}

const EVENT_LUGGAGE_FROM_YESTERDAY := {
	"id": "luggage_from_yesterday", "planet_id": "resort_horizonte_eventos", "symbol": "BAGAGEM D-1", "title": "Bagagem Perdida de Ontem",
	"description": "Uma mala chega pela passadeira temporal um dia antes do dono e contém uma reclamação escrita depois de desaparecer.", "color": "#8f7cff",
	"choices": [
		{"id": "buy_temporal_claim_tag", "name": "COMPRAR ETIQUETA TEMPORAL · 64 CR", "effect_text": "A etiqueta desvia energia do alvo: -15% poder inimigo.", "credit_cost": 64, "power_mult": 0.85, "result": "A mala foi declarada encontrada antes de o formulário admitir que estava perdida."},
		{"id": "trace_luggage_timeline", "name": "RASTREAR A LINHA DA BAGAGEM", "effect_text": "+85s de caça e +20% XP em logística relativística.", "duration_add": 85.0, "xp_mult": 1.20, "result": "O rastreio passou por amanhã, voltou por engano e pediu nova palavra-passe."},
		{"id": "auction_future_contents", "name": "LEILOAR O CONTEÚDO FUTURO", "effect_text": "+12% vida inimiga, mas +23% créditos de antecipação turística.", "health_mult": 1.12, "credits_mult": 1.23, "result": "Os objetos foram vendidos antes de serem comprados. O hóspede enviará a queixa ontem."},
	],
}

const EVENTS := [EVENT_INFINITE_BREAKFAST_BUFFET, EVENT_LUGGAGE_FROM_YESTERDAY]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Reserva Retroativa", "description": "Declara cada impacto ocupado desde muito antes de o alvo chegar."},
		{"name": "Lança-Boias de Singularidade", "description": "Salva ou afunda conforme o suplemento incluído no pacote."},
		{"name": "Rifle de Check-In Assintótico", "description": "Aproxima o disparo do alvo para sempre sem admitir qualquer atraso."},
		{"name": "Canhão do Último Pôr do Sol", "description": "Dispara a última luz disponível e cobra pela vista depois do impacto."},
	],
	"armor": [
		{"name": "Casaco de Reserva Gravitacional", "description": "Mantém o lugar do caçador mesmo quando o corpo está noutra órbita."},
		{"name": "Traje de Salva-Vidas Relativístico", "description": "Inclui apito, boia e exclusão contratual para pontos sem retorno."},
		{"name": "Colete de Concierge Temporal", "description": "Atrasa danos até depois do check-out e chama isso de cortesia."},
		{"name": "Armadura da Suíte do Horizonte", "description": "Oferece proteção cinco estrelas e janelas diretamente para o nada."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Viseira de Reserva Solar", "description": "Projeta uma toalha sobre qualquer lugar que o caçador pretenda ocupar."},
		{"name": "Capacete de Resgate Assintótico", "description": "Mantém a cabeça fora do horizonte, mesmo quando o resto já fez check-in."},
		{"name": "Monóculo de Concierge Temporal", "description": "Vê reclamações futuras a tempo de as guardar numa gaveta passada."},
		{"name": "Coroa do Último Pôr do Sol", "description": "Enquadra o fim do universo como uma comodidade exclusiva da suíte."},
	],
}

const PACK := {
	"id": "resort_horizonte_eventos",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
