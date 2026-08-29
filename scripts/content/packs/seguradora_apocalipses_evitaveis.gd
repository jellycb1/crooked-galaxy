class_name SeguradoraApocalipsesEvitaveisContent
extends RefCounted

const PLANET := {
	"id": "seguradora_apocalipses_evitaveis", "name": "Seguradora de Apocalipses Evitáveis", "unlock_level": 290, "travel_duration": 7680.0,
	"subtitle": "O fim do mundo exige participação em triplicado.",
	"description": "Uma central orbital assegura civilizações contra invasões, estrelas explosivas e profecias vencidas, desde que a catástrofe não esteja mencionada nas letras pequenas.",
	"accent": "#ffb454", "unlock_after": "oficina_realidades_defeituosas",
	"completion_text": "O Diretor de Sinistros Finais foi declarado risco não coberto. Os sobreviventes receberam um cupão, uma franquia nova e instruções para reconstruir fora do horário comercial.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "doomsday_claim_adjuster", "planet_id": "seguradora_apocalipses_evitaveis", "name": "Perito de Sinistros do Juízo Final", "title": "Avalia planetas destruídos pelo valor anterior ao desastre", "description": "Mede crateras, deprecia continentes e reduz cada extinção a desgaste normal provocado por utilização civilizacional.", "emoji": "▣", "power": 4538, "loot_power": 4268, "defense": 2067, "health": 85100, "duration": 1648, "credits": 8230000, "xp": 5870000, "rank": 3, "chapter_tier": 0, "attacks": ["Cratera Avaliada", "Continente Depreciado", "Desgaste Civilizacional"], "visual_delivery": "pending_user_asset"},
	{"id": "prophecy_exclusion_broker", "planet_id": "seguradora_apocalipses_evitaveis", "name": "Corretora de Exclusões Proféticas", "title": "Esconde o destino inevitável nas letras pequenas", "description": "Revende presságios, altera datas sagradas e prova que qualquer herói anunciado constitui conhecimento prévio do segurado.", "emoji": "⌘", "power": 4626, "loot_power": 4351, "defense": 2107, "health": 86700, "duration": 1676, "credits": 8720000, "xp": 6220000, "rank": 3, "chapter_tier": 1, "attacks": ["Presságio Revendido", "Data Sagrada Alterada", "Herói Excluído"], "visual_delivery": "pending_user_asset"},
	{"id": "extinction_deductible_collector", "planet_id": "seguradora_apocalipses_evitaveis", "name": "Cobrador de Franquias de Extinção", "title": "Fatura os últimos sobreviventes antes do resgate", "description": "Confisca cápsulas de fuga, penhora reservas de oxigénio e acrescenta juros sempre que a população segurada diminui.", "emoji": "¤", "power": 4716, "loot_power": 4436, "defense": 2148, "health": 88320, "duration": 1704, "credits": 9240000, "xp": 6600000, "rank": 3, "chapter_tier": 2, "attacks": ["Cápsula Penhorada", "Oxigénio com Juros", "Franquia Terminal"], "visual_delivery": "pending_user_asset"},
	{"id": "final_claims_director", "planet_id": "seguradora_apocalipses_evitaveis", "name": "Diretor de Sinistros Finais", "title": "Recusa indemnizações porque ninguém sobreviveu para assinar", "description": "Autoriza catástrofes rentáveis, cancela resgates dispendiosos e mantém uma coleção de mundos destruídos classificados como processos incompletos.", "emoji": "◆", "power": 4902, "loot_power": 4610, "defense": 2233, "health": 92800, "duration": 1742, "credits": 9790000, "xp": 7010000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Catástrofe Rentável", "Resgate Cancelado", "Processo Incompleto"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "planetary_claim_denied", "planet_id": "seguradora_apocalipses_evitaveis", "symbol": "PEDIDO RECUSADO", "title": "Sinistro Planetário Recusado", "description": "Um planeta partido ao meio recebeu uma carta explicando que a apólice cobre apenas dois hemisférios ainda ligados.", "color": "#ffb454", "choices": [
		{"id": "buy_appeal_stamps", "name": "COMPRAR SELOS · 116 CR", "effect_text": "Os selos reduzem a defesa inimiga em 22%.", "credit_cost": 116, "defense_mult": 0.78, "result": "O recurso foi aceite, carimbado e enviado para o departamento que já não existe."},
		{"id": "document_every_fragment", "name": "DOCUMENTAR CADA FRAGMENTO", "effect_text": "+180s de caça e +22% XP.", "duration_add": 180.0, "xp_mult": 1.22, "result": "O último fragmento continha o formulário original em perfeito estado."},
		{"id": "sell_salvage_rights", "name": "VENDER DIREITOS DE SALVADO", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os compradores adquiriram metade do planeta e discutiram sobre qual metade."},
	]},
	{"id": "apocalypse_premium_overdue", "planet_id": "seguradora_apocalipses_evitaveis", "symbol": "PRÉMIO EM ATRASO", "title": "Prémio do Apocalipse em Atraso", "description": "A lua segurada deixou de pagar minutos antes da invasão, anulando cobertura para todos os habitantes ainda a gritar.", "color": "#ff6f79", "choices": [
		{"id": "buy_emergency_coverage", "name": "COMPRAR COBERTURA · 117 CR", "effect_text": "A cobertura reduz o poder inimigo em 15%.", "credit_cost": 117, "power_mult": 0.85, "result": "A cobertura começou imediatamente após o fim oficial da emergência."},
		{"id": "audit_every_survivor", "name": "AUDITAR CADA SOBREVIVENTE", "effect_text": "+170s de caça e +20% XP.", "duration_add": 170.0, "xp_mult": 1.20, "result": "A auditoria encontrou um sobrevivente e cobrou-lhe a totalidade do prémio."},
		{"id": "auction_the_rescue_slots", "name": "LEILOAR LUGARES DE RESGATE", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "O último lugar foi vendido a alguém que já possuía a nave de resgate."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Cratera Avaliada", "description": "Calcula o impacto antes de reduzir o valor do alvo."},
		{"name": "Projetor de Presságios Revendidos", "description": "Entrega ao inimigo um futuro inevitável com proprietário anterior."},
		{"name": "Lançador de Franquias Terminais", "description": "Cobra uma parte do dano diretamente ao alvo."},
		{"name": "Canhão de Catástrofe Rentável", "description": "Transforma destruição em resultados trimestrais positivos."},
	],
	"armor": [
		{"name": "Colete de Desgaste Civilizacional", "description": "Classifica ferimentos como envelhecimento normal da espécie."},
		{"name": "Traje de Herói Excluído", "description": "Recusa ataques previamente anunciados por qualquer profecia."},
		{"name": "Armadura de Oxigénio com Juros", "description": "Respira agora e acrescenta a dívida à próxima batalha."},
		{"name": "Uniforme de Processo Incompleto", "description": "Adia cada dano até chegar a assinatura em falta."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Implante de Avaliação Terminal", "description": "Estima perdas irreversíveis antes de permitir qualquer emoção."},
		{"name": "Nódulo de Exclusão Profética", "description": "Apaga destinos que possam aumentar o prémio mensal."},
		{"name": "Implante de Franquia Vital", "description": "Reserva uma parte de cada função orgânica para pagamento futuro."},
		{"name": "Nódulo de Sinistros Finais", "description": "Recusa o fim enquanto o processo permanecer administrativamente aberto."},
	],
}

const PACK := {"id": "seguradora_apocalipses_evitaveis", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
