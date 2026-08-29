class_name FabricaCoincidenciasIndustriaisContent
extends RefCounted

const PLANET := {
	"id": "fabrica_coincidencias_industriais", "name": "Fábrica de Coincidências Industriais", "unlock_level": 310, "travel_duration": 8160.0,
	"subtitle": "Nada acontece por acaso sem número de série.",
	"description": "Uma fábrica orbital produz sorte, encontros improváveis e reviravoltas convenientes para civilizações sem tempo de esperar pelo destino natural.",
	"accent": "#72e0d1", "unlock_after": "leilao_imperios_falidos",
	"completion_text": "O Industrial das Coincidências foi apanhado por um acidente estranhamente apropriado. A fábrica continua ativa porque, por puro acaso, todos os botões de emergência falharam.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "fortunate_accident_foreman", "planet_id": "fabrica_coincidencias_industriais", "name": "Capataz de Acidentes Afortunados", "title": "Organiza desastres que beneficiam exatamente a pessoa certa", "description": "Solta cargas no momento oportuno, agenda colisões úteis e arquiva cada sobrevivente improvável como produto aprovado.", "emoji": "✣", "power": 5389, "loot_power": 5068, "defense": 2455, "health": 106600, "duration": 1828, "credits": 13050000, "xp": 9410000, "rank": 3, "chapter_tier": 0, "attacks": ["Carga Oportuna", "Colisão Útil", "Sobrevivente Aprovado"], "visual_delivery": "pending_user_asset"},
	{"id": "destiny_quality_inspector", "planet_id": "fabrica_coincidencias_industriais", "name": "Inspetora de Qualidade do Destino", "title": "Rejeita futuros que parecem demasiado plausíveis", "description": "Testa profecias em laboratório, mede ironia dramática e devolve destinos que não surpreendam o cliente no pior momento.", "emoji": "⌬", "power": 5494, "loot_power": 5167, "defense": 2503, "health": 108600, "duration": 1858, "credits": 13830000, "xp": 9980000, "rank": 3, "chapter_tier": 1, "attacks": ["Profecia Testada", "Ironia Medida", "Futuro Rejeitado"], "visual_delivery": "pending_user_asset"},
	{"id": "plot_twist_wholesaler", "planet_id": "fabrica_coincidencias_industriais", "name": "Grossista de Reviravoltas", "title": "Vende traições e parentes secretos à tonelada", "description": "Empilha identidades ocultas, desconta revelações vencidas e entrega finais inesperados antes de a história começar.", "emoji": "⤨", "power": 5601, "loot_power": 5268, "defense": 2552, "health": 110650, "duration": 1888, "credits": 14650000, "xp": 10580000, "rank": 3, "chapter_tier": 2, "attacks": ["Parente Secreto", "Traição por Atacado", "Final Antecipado"], "visual_delivery": "pending_user_asset"},
	{"id": "coincidence_industrialist", "planet_id": "fabrica_coincidencias_industriais", "name": "Industrial das Coincidências", "title": "Controla o acaso através de metas trimestrais", "description": "Patenteia boa sorte, sabota probabilidades concorrentes e garante que todo acidente impossível favorece os acionistas da fábrica.", "emoji": "✺", "power": 5822, "loot_power": 5476, "defense": 2653, "health": 116200, "duration": 1928, "credits": 15530000, "xp": 11240000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Sorte Patenteada", "Probabilidade Sabotada", "Acaso Industrial"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "defective_coincidence_batch", "planet_id": "fabrica_coincidencias_industriais", "symbol": "LOTE IMPROVÁVEL", "title": "Lote de Coincidências Defeituoso", "description": "Milhares de encontros destinados aconteceram na mesma cantina, bloqueando portas, destinos e a fila do almoço.", "color": "#72e0d1", "choices": [
		{"id": "buy_probability_filters", "name": "COMPRAR FILTROS · 120 CR", "effect_text": "Os filtros reduzem a defesa inimiga em 22%.", "credit_cost": 120, "defense_mult": 0.78, "result": "Os filtros separaram os destinos e juntaram acidentalmente três casamentos."},
		{"id": "sort_every_coincidence", "name": "SEPARAR CADA COINCIDÊNCIA", "effect_text": "+190s de caça e +22% XP.", "duration_add": 190.0, "xp_mult": 1.22, "result": "A última coincidência era a equipa encontrar exatamente o formulário necessário."},
		{"id": "sell_priority_destiny", "name": "VENDER DESTINO PRIORITÁRIO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os clientes premium coincidiram primeiro e reclamaram da falta de surpresa."},
	]},
	{"id": "fate_conveyor_jam", "planet_id": "fabrica_coincidencias_industriais", "symbol": "DESTINO PRESO", "title": "Tapete Rolante do Destino Bloqueou", "description": "Uma profecia de tamanho imperial ficou presa na linha e começou a cumprir-se em todos os operários próximos.", "color": "#ff8770", "choices": [
		{"id": "buy_emergency_shears", "name": "COMPRAR TESOURAS · 121 CR", "effect_text": "As tesouras reduzem o poder inimigo em 15%.", "credit_cost": 121, "power_mult": 0.85, "result": "As tesouras cortaram o destino em finais menores com garantia limitada."},
		{"id": "unroll_the_full_prophecy", "name": "DESENROLAR A PROFECIA", "effect_text": "+180s de caça e +20% XP.", "duration_add": 180.0, "xp_mult": 1.20, "result": "O último verso previa exatamente o tempo perdido a desenrolá-lo."},
		{"id": "sell_prophetic_offcuts", "name": "VENDER SOBRAS PROFÉTICAS", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "As sobras foram vendidas como destinos artesanais de edição limitada."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Carga Oportuna", "description": "Dispara exatamente quando o alvo olha para o lado."},
		{"name": "Projetor de Ironia Medida", "description": "Entrega a consequência mais adequada à confiança do inimigo."},
		{"name": "Lançador de Traições por Atacado", "description": "Distribui deslealdade suficiente para toda a equipa adversária."},
		{"name": "Canhão de Acaso Industrial", "description": "Produz acidentes impossíveis à escala de uma linha de montagem."},
	],
	"armor": [
		{"name": "Colete de Sobrevivente Aprovado", "description": "Certifica a sobrevivência antes de o perigo terminar."},
		{"name": "Traje de Futuro Rejeitado", "description": "Devolve impactos demasiado previsíveis ao remetente."},
		{"name": "Armadura de Parente Secreto", "description": "Revela outra camada defensiva no momento mais dramático."},
		{"name": "Uniforme de Sorte Patenteada", "description": "Reserva todos os resultados favoráveis ao utilizador registado."},
	],
}

const SECONDARY_ITEMS := {
	"gloves": [
		{"name": "Luvas de Colisão Útil", "description": "Guiam cada contacto para uma consequência oportunamente vantajosa."},
		{"name": "Manoplas de Profecia Testada", "description": "Aprovam destinos apenas depois de falharem de forma interessante."},
		{"name": "Luvas de Final Antecipado", "description": "Agarram a conclusão antes de o conflito conseguir desenvolvê-la."},
		{"name": "Manoplas de Probabilidade Sabotada", "description": "Desmontam a sorte concorrente com precisão industrial."},
	],
}

const PACK := {"id": "fabrica_coincidencias_industriais", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
