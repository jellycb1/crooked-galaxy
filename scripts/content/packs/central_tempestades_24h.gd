class_name CentralTempestades24hContent
extends RefCounted

const PLANET := {
	"id": "central_tempestades_24h",
	"name": "Central de Tempestades 24h",
	"unlock_level": 90,
	"travel_duration": 2880.0,
	"subtitle": "A sua trovoada é importante para nós.",
	"description": "Um gigante gasoso coberto por plataformas de atendimento onde nuvens aguardam em linha, relâmpagos são transferidos entre departamentos e cada furacão termina com um inquérito de satisfação.",
	"accent": "#65d7ff",
	"unlock_after": "necropole_solar_umbral",
	"completion_text": "O Diretor da Tempestade Eterna foi desligado da chamada. Pela primeira vez em séculos, os trovões chegaram diretamente ao assunto.",
	"visual_delivery": "pending_user_asset",
}

const TARGET_QUEUE_CLOUD_OPERATOR := {
	"id": "queue_cloud_operator", "planet_id": "central_tempestades_24h", "name": "Operador da Nuvem de Espera",
	"title": "Especialista em deixar raios em linha", "description": "Mantém tempestades a ouvir a mesma música durante séculos e reinicia a fila sempre que alguém pergunta pelo supervisor.", "emoji": "☁",
	"power": 457, "loot_power": 430, "defense": 204, "health": 4530, "duration": 220, "credits": 18340, "xp": 12520, "rank": 3, "chapter_tier": 0,
	"attacks": ["Música de Espera Ionizada", "Fila Cumulonimbus", "Reinício da Chamada"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_LIGHTNING_RETENTION_AGENT := {
	"id": "lightning_retention_agent", "planet_id": "central_tempestades_24h", "name": "Agente de Retenção Elétrica",
	"title": "Impede descargas de mudar de fornecedor", "description": "Promete mais voltagem, oferece seis meses de fidelização e persegue qualquer raio que tente cair noutro planeta.", "emoji": "ϟ",
	"power": 472, "loot_power": 444, "defense": 211, "health": 4690, "duration": 229, "credits": 20190, "xp": 13740, "rank": 3, "chapter_tier": 1,
	"attacks": ["Oferta de Voltagem", "Contrato de Fidelização", "Descarga Retida"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_THUNDER_QUALITY_AUDITOR := {
	"id": "thunder_quality_auditor", "planet_id": "central_tempestades_24h", "name": "Auditora de Qualidade do Trovão",
	"title": "Certificadora de estrondos regulamentares", "description": "Rejeita trovões sem dicção, mede ecos com uma prancheta isolante e aplica multas por dramatismo atmosférico insuficiente.", "emoji": "≋",
	"power": 487, "loot_power": 458, "defense": 218, "health": 4860, "duration": 239, "credits": 22220, "xp": 15120, "rank": 3, "chapter_tier": 2,
	"attacks": ["Teste de Eco", "Prancheta Isolante", "Não Conformidade Sónica"],
	"visual_delivery": "pending_user_asset",
}

const TARGET_ETERNAL_STORM_DIRECTOR := {
	"id": "eternal_storm_director", "planet_id": "central_tempestades_24h", "name": "Diretor da Tempestade Eterna",
	"title": "Responsável máximo por todo o mau tempo", "description": "Gere ciclones por comissão, assina relâmpagos em triplicado e nunca encerra uma tempestade enquanto houver alguém em espera.", "emoji": "⛈",
	"power": 516, "loot_power": 486, "defense": 232, "health": 5350, "duration": 251, "credits": 24600, "xp": 16700, "rank": 3, "chapter_tier": 3, "boss": true,
	"attacks": ["Ciclone Executivo", "Relâmpago em Triplicado", "Escalada ao Supervisor"],
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [TARGET_QUEUE_CLOUD_OPERATOR, TARGET_LIGHTNING_RETENTION_AGENT, TARGET_THUNDER_QUALITY_AUDITOR, TARGET_ETERNAL_STORM_DIRECTOR]

const EVENT_ATMOSPHERIC_SUPPORT_CALL := {
	"id": "atmospheric_support_call", "planet_id": "central_tempestades_24h", "symbol": "LINHA 24H", "title": "Chamada de Apoio Atmosférico",
	"description": "A nave entra por engano numa chamada coletiva onde setecentas nuvens tentam comunicar a mesma falha de precipitação.", "color": "#65d7ff",
	"choices": [
		{"id": "buy_priority_support", "name": "COMPRAR APOIO PRIORITÁRIO · 51 CR", "effect_text": "O operador desliga a blindagem do alvo: -22% defesa inimiga.", "credit_cost": 51, "defense_mult": 0.78, "result": "A prioridade colocou a nave à frente de seis séculos de garoa."},
		{"id": "listen_full_menu", "name": "OUVIR O MENU COMPLETO", "effect_text": "+80s de caça e +22% XP em suporte meteorológico.", "duration_add": 80.0, "xp_mult": 1.22, "result": "A opção certa não existia, mas a música ganhou um segundo refrão."},
		{"id": "demand_cloud_supervisor", "name": "EXIGIR O SUPERVISOR", "effect_text": "+13% poder inimigo, mas +25% créditos por escalada atmosférica.", "power_mult": 1.13, "credits_mult": 1.25, "result": "O supervisor atendeu pessoalmente sob a forma de uma frente fria hostil."},
	],
}

const EVENT_TRANSFERRED_LIGHTNING := {
	"id": "transferred_lightning", "planet_id": "central_tempestades_24h", "symbol": "TRANSF. 99+", "title": "Relâmpago Transferido",
	"description": "Uma descarga perdida salta entre antenas de departamento em departamento e pede à nave que confirme novamente todos os dados.", "color": "#ffe66d",
	"choices": [
		{"id": "buy_grounding_extension", "name": "COMPRAR EXTENSÃO DE TERRA · 52 CR", "effect_text": "A extensão drena os sistemas do alvo: -15% poder inimigo.", "credit_cost": 52, "power_mult": 0.85, "result": "A descarga encontrou terra firme e abriu imediatamente uma reclamação."},
		{"id": "follow_every_transfer", "name": "SEGUIR CADA TRANSFERÊNCIA", "effect_text": "+70s de caça e +20% XP em navegação departamental.", "duration_add": 70.0, "xp_mult": 1.20, "result": "Dezanove departamentos depois, o primeiro operador voltou a atender."},
		{"id": "intercept_lightning", "name": "INTERCETAR O RELÂMPAGO", "effect_text": "+12% vida inimiga, mas +23% créditos de energia recuperada.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A nave guardou a descarga. A central guardou o direito de ligar de volta."},
	],
}

const EVENTS := [EVENT_ATMOSPHERIC_SUPPORT_CALL, EVENT_TRANSFERRED_LIGHTNING]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Música de Espera", "description": "Repete o mesmo disparo até o alvo desistir por vontade própria."},
		{"name": "Lança-Raios de Fidelização", "description": "Cada descarga renova automaticamente o contrato por mais uma tempestade."},
		{"name": "Canhão de Eco Certificado", "description": "O impacto regressa com carimbo, parecer técnico e volume aprovado."},
		{"name": "Emissor da Tempestade Eterna", "description": "Garante mau tempo permanente ou até alguém encontrar a opção de cancelamento."},
	],
	"armor": [
		{"name": "Casaco de Atendimento Atmosférico", "description": "Resiste a chuva, reclamações e supervisores em igual proporção."},
		{"name": "Traje de Isolamento de Retenção", "description": "Mantém a eletricidade dentro e qualquer pedido de cancelamento fora."},
		{"name": "Colete de Qualidade Cumulonimbus", "description": "Cada camada de nuvem foi auditada por um departamento diferente."},
		{"name": "Armadura da Direção Meteorológica", "description": "Inclui proteção executiva e autoridade para declarar trovoada em qualquer reunião."},
	],
}

const SECONDARY_ITEMS := {
	"implant": [
		{"name": "Auricular de Espera Infinita", "description": "Filtra ameaças, trovões e qualquer frase que comece por sua chamada."},
		{"name": "Nervo de Retenção Galvânica", "description": "Convence impulsos elétricos a permanecer no corpo por mais um ciclo."},
		{"name": "Processador de Eco Regulamentar", "description": "Repete decisões até receber a resposta estatisticamente mais conveniente."},
		{"name": "Ligação Direta ao Supervisor", "description": "Ignora dezanove menus e descarrega autoridade diretamente no córtex."},
	],
}

const PACK := {
	"id": "central_tempestades_24h",
	"planet": PLANET,
	"targets": TARGETS,
	"events": EVENTS,
	"items": ITEMS,
	"secondary_items": SECONDARY_ITEMS,
}
