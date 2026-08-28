class_name ArquivoAbissalN9Content
extends RefCounted

const PLANET := {
	"id": "arquivo_abissal_n9",
	"name": "Arquivo Abissal N-9",
	"unlock_level": 40,
	"travel_duration": 1680.0,
	"subtitle": "A pressão aumenta. O prazo também.",
	"description": "Uma repartição oceânica afundada num mundo sem continentes, onde recifes arquivam processos, submarinos fazem fila e toda bolha precisa de protocolo.",
	"accent": "#39d7c5",
	"unlock_after": "aeropolis_penhora",
	"completion_text": "O Leviatã do Protocolo foi carimbado, catalogado e devolvido ao abismo. A fila avançou dois lugares.",
}

const TARGET_EEL_COURIER := {
	"id": "eel_courier", "planet_id": "arquivo_abissal_n9", "name": "Estafeta Enguia",
	"title": "Contrabandista dos tubos pneumáticos", "description": "Entrega processos por atalhos elétricos e cobra sobretaxa a quem sobrevive à assinatura.", "emoji": "≈",
	"power": 190, "loot_power": 179, "defense": 85, "health": 1460, "duration": 72, "credits": 2260, "xp": 1750, "rank": 3, "chapter_tier": 0,
	"attacks": ["Despacho Elétrico", "Atalho Condutor", "Recibo de Alta Voltagem"],
}

const TARGET_CORAL_LANDLADY := {
	"id": "coral_landlady", "planet_id": "arquivo_abissal_n9", "name": "Senhoria Coralina",
	"title": "Proprietária de recifes hipotecados", "description": "Aluga cavernas por maré, penhora pérolas e aumenta a renda sempre que o oceano sobe.", "emoji": "♒",
	"power": 207, "loot_power": 195, "defense": 92, "health": 1600, "duration": 77, "credits": 2470, "xp": 1910, "rank": 3, "chapter_tier": 1,
	"attacks": ["Renda de Maré Alta", "Penhora de Pérola", "Despejo do Recife"],
}

const TARGET_NOTARY_OCTOPUS := {
	"id": "notary_octopus", "planet_id": "arquivo_abissal_n9", "name": "Tabelião Tentáculo",
	"title": "Notário de oito assinaturas simultâneas", "description": "Autentica provas, falsifica testemunhas e mantém seis braços livres para cobrar emolumentos.", "emoji": "§",
	"power": 225, "loot_power": 212, "defense": 100, "health": 1760, "duration": 82, "credits": 2720, "xp": 2090, "rank": 3, "chapter_tier": 2,
	"attacks": ["Carimbo Octogonal", "Firma Reconhecida", "Cláusula de Tinta"],
}

const TARGET_PROTOCOL_LEVIATHAN := {
	"id": "protocol_leviathan", "planet_id": "arquivo_abissal_n9", "name": "Leviatã do Protocolo",
	"title": "Arquivo vivo de processos afogados", "description": "Engole recursos, regurgita formulários e só desperta quando alguém escolhe a fila errada.", "emoji": "⌁",
	"power": 245, "loot_power": 231, "defense": 109, "health": 1950, "duration": 88, "credits": 3060, "xp": 2310, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Decreto Hadal", "Engolir Recurso", "Protocolo do Fim"],
}

const TARGETS := [TARGET_EEL_COURIER, TARGET_CORAL_LANDLADY, TARGET_NOTARY_OCTOPUS, TARGET_PROTOCOL_LEVIATHAN]

const EVENT_BATHYAL_CUSTOMS := {
	"id": "bathyal_customs", "planet_id": "arquivo_abissal_n9", "symbol": "9.000m", "title": "Alfândega Batial",
	"description": "Uma cancela submarina exige declarar cada litro de ar e qualquer pensamento acima da pressão permitida.", "color": "#39d7c5",
	"choices": [
		{"id": "stamp_oxygen", "name": "CARIMBAR O OXIGÉNIO · 30 CR", "effect_text": "O fiscal abre a escotilha do alvo: -20% defesa inimiga.", "credit_cost": 30, "defense_mult": 0.80, "result": "O oxigénio recebeu visto temporário. A cobertura do alvo perdeu o selo."},
		{"id": "inspect_manifest", "name": "INSPECIONAR O MANIFESTO", "effect_text": "+60s de caça e +20% XP em burocracia hidrostática.", "duration_add": 60.0, "xp_mult": 1.20, "result": "O manifesto tinha quarenta páginas e uma pequena lula sem declaração."},
		{"id": "dive_under_gate", "name": "MERGULHAR SOB A CANCELA", "effect_text": "+12% poder inimigo, mas +22% créditos por risco batial.", "power_mult": 1.12, "credits_mult": 1.22, "result": "A cancela ficou para trás. A multa aprendeu a nadar."},
	],
}

const EVENT_DECOMPRESSION_QUEUE := {
	"id": "decompression_queue", "planet_id": "arquivo_abissal_n9", "symbol": "SENHA 404", "title": "Fila de Descompressão",
	"description": "Quatrocentos submarinos aguardam uma cabine com um único botão e intervalo para almoço.", "color": "#8de8ff",
	"choices": [
		{"id": "buy_priority", "name": "COMPRAR PRIORIDADE · 32 CR", "effect_text": "A cabine revela a rota interna: -14% poder do alvo.", "credit_cost": 32, "power_mult": 0.86, "result": "A prioridade veio numa senha dourada e numa culpa laminada."},
		{"id": "wait_pressure", "name": "AGUARDAR A PRESSÃO", "effect_text": "+45s de caça e +18% XP em paciência submarina.", "duration_add": 45.0, "xp_mult": 1.18, "result": "A pressão normalizou. A fila desenvolveu uma sociedade própria."},
		{"id": "open_emergency_hatch", "name": "ABRIR A ESCOTILHA DE EMERGÊNCIA", "effect_text": "+10% vida inimiga, mas +20% créditos de profundidade.", "health_mult": 1.10, "credits_mult": 1.20, "result": "A água entrou primeiro. O procedimento disciplinar veio logo atrás."},
	],
}

const EVENTS := [EVENT_BATHYAL_CUSTOMS, EVENT_DECOMPRESSION_QUEUE]

const ITEMS := {
	"weapon": [
		{"name": "Arpão de Firma Reconhecida", "description": "Perfura casco, cláusulas e qualquer assinatura sem três testemunhas."},
		{"name": "Carabina de Bolhas Comprimidas", "description": "Cada bolha explode com pressão e uma pequena taxa de serviço."},
		{"name": "Lança-Torpedos de Cartório", "description": "O projétil chega autenticado, numerado e ligeiramente atrasado."},
		{"name": "Tridente de Cobrança Hadal", "description": "Tem três pontas para capital, juros e despesas administrativas."},
	],
	"armor": [
		{"name": "Escafandro de Responsabilidade Limitada", "description": "Suporta o abismo, mas não responde por danos emocionais."},
		{"name": "Colete de Coral Notarial", "description": "Cresce uma nova placa sempre que alguém contesta a garantia."},
		{"name": "Manto de Alga Balística", "description": "Flexível, biodegradável e hostil a qualquer arpão não registado."},
		{"name": "Armadura de Submarino Executivo", "description": "Inclui sonar, minibar e uma escotilha exclusiva para recursos."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Brânquia de Atendimento Prioritário", "description": "Filtra água, oxigénio e pedidos sem a documentação correta."},
		{"name": "Sonar de Firma Digital", "description": "Reconhece ecos, assinaturas e mentiras a seis mil metros."},
		{"name": "Regulador Neural de Pressão", "description": "Mantém o pensamento estável quando o oceano e os prazos apertam."},
		{"name": "Memória Coralina Auditável", "description": "Arquiva lembranças em recifes e cobra por cada recuperação."},
	],
}

const PACK := {
	"id": "arquivo_abissal_n9",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
