class_name CentralReiniciosCosmicosContent
extends RefCounted

const PLANET := {
	"id": "central_reinicios_cosmicos", "name": "Central de Reinícios Cósmicos", "unlock_level": 320, "travel_duration": 8400.0,
	"subtitle": "Guarde o universo antes de o desligar.",
	"description": "Uma sala de controlo no exterior da realidade agenda novos Big Bangs, restaura universos avariados e elimina civilizações inteiras classificadas como dados temporários.",
	"accent": "#8aa8ff", "unlock_after": "fabrica_coincidencias_industriais",
	"completion_text": "O Administrador do Reinício Cósmico foi removido da lista de utilizadores. O universo escapou ao reset, mas continua a receber avisos para reiniciar numa hora mais conveniente.",
	"visual_delivery": "pending_user_asset",
}

const TARGETS := [
	{"id": "big_bang_scheduler", "planet_id": "central_reinicios_cosmicos", "name": "Agendador de Big Bangs", "title": "Marca criações universais sem verificar conflitos de calendário", "description": "Sobrepõe explosões primordiais, reserva espaço-tempo em duplicado e cobra taxa de cancelamento a cosmos que ainda não nasceram.", "emoji": "✷", "power": 5868, "loot_power": 5520, "defense": 2673, "health": 119400, "duration": 1920, "credits": 16460000, "xp": 11910000, "rank": 3, "chapter_tier": 0, "attacks": ["Explosão Agendada", "Espaço-Tempo Duplicado", "Criação Cancelada"], "visual_delivery": "pending_user_asset"},
	{"id": "universal_memory_wipe_engineer", "planet_id": "central_reinicios_cosmicos", "name": "Engenheira de Limpeza de Memória Universal", "title": "Apaga eras históricas para libertar armazenamento", "description": "Comprime impérios, remove espécies sem utilização recente e classifica recordações coletivas como ficheiros temporários.", "emoji": "⌫", "power": 5982, "loot_power": 5627, "defense": 2725, "health": 121650, "duration": 1951, "credits": 17450000, "xp": 12630000, "rank": 3, "chapter_tier": 1, "attacks": ["Era Comprimida", "Espécie Removida", "Memória Temporária"], "visual_delivery": "pending_user_asset"},
	{"id": "universe_backup_smuggler", "planet_id": "central_reinicios_cosmicos", "name": "Contrabandista de Backups Universais", "title": "Vende cópias antigas da realidade sem licença de restauro", "description": "Duplica linhas temporais, esconde civilizações em arquivos e troca finais recentes por versões mais lucrativas do passado.", "emoji": "⧉", "power": 6098, "loot_power": 5736, "defense": 2778, "health": 123930, "duration": 1982, "credits": 18490000, "xp": 13390000, "rank": 3, "chapter_tier": 2, "attacks": ["Linha Duplicada", "Civilização Arquivada", "Passado Restaurado"], "visual_delivery": "pending_user_asset"},
	{"id": "cosmic_reset_administrator", "planet_id": "central_reinicios_cosmicos", "name": "Administrador do Reinício Cósmico", "title": "Desliga a existência para instalar atualizações obrigatórias", "description": "Bloqueia adiamentos, elimina backups independentes e considera cada ser vivo um processo que devia ter sido encerrado há eras.", "emoji": "◉", "power": 6338, "loot_power": 5962, "defense": 2888, "health": 130200, "duration": 2023, "credits": 19600000, "xp": 14230000, "rank": 3, "chapter_tier": 3, "boss": true, "attacks": ["Adiamento Bloqueado", "Backup Eliminado", "Reinício Obrigatório"], "visual_delivery": "pending_user_asset"},
]

const EVENTS := [
	{"id": "cosmic_reboot_countdown", "planet_id": "central_reinicios_cosmicos", "symbol": "REINÍCIO EM CURSO", "title": "Contagem para Reinício Cósmico", "description": "O temporizador universal começou nos dez segundos e todas as civilizações receberam a opção de adiar durante cinco minutos.", "color": "#8aa8ff", "choices": [
		{"id": "buy_admin_override", "name": "COMPRAR ACESSO · 122 CR", "effect_text": "O acesso reduz a defesa inimiga em 22%.", "credit_cost": 122, "defense_mult": 0.78, "result": "O acesso suspendeu o temporizador e iniciou uma atualização diferente."},
		{"id": "notify_every_civilization", "name": "AVISAR CADA CIVILIZAÇÃO", "effect_text": "+195s de caça e +22% XP.", "duration_add": 195.0, "xp_mult": 1.22, "result": "A última civilização respondeu que nunca tinha subscrito estes avisos."},
		{"id": "sell_priority_restarts", "name": "VENDER REINÍCIOS PRIORITÁRIOS", "effect_text": "+13% poder inimigo, mas +25% créditos.", "power_mult": 1.13, "credits_mult": 1.25, "result": "Os clientes premium foram apagados primeiro e chamaram-lhe serviço exclusivo."},
	]},
	{"id": "universe_backup_corrupted", "planet_id": "central_reinicios_cosmicos", "symbol": "BACKUP CORROMPIDO", "title": "Backup do Universo Corrompido", "description": "A cópia mais recente mistura três eras, duas leis físicas e uma pasta inteira de dinossauros administrativos.", "color": "#ff728f", "choices": [
		{"id": "buy_recovery_keys", "name": "COMPRAR CHAVES · 123 CR", "effect_text": "As chaves reduzem o poder inimigo em 15%.", "credit_cost": 123, "power_mult": 0.85, "result": "As chaves recuperaram tudo exceto a definição atual de gravidade."},
		{"id": "restore_every_archive", "name": "RESTAURAR CADA ARQUIVO", "effect_text": "+185s de caça e +20% XP.", "duration_add": 185.0, "xp_mult": 1.20, "result": "O último arquivo continha apenas instruções para restaurar o primeiro."},
		{"id": "sell_the_mixed_timeline", "name": "VENDER A LINHA MISTURADA", "effect_text": "+12% vida inimiga, mas +23% créditos.", "health_mult": 1.12, "credits_mult": 1.23, "result": "A linha temporal foi vendida como universo experimental com história aberta."},
	]},
]

const ITEMS := {
	"weapon": [
		{"name": "Carabina de Explosão Agendada", "description": "Cria o impacto no primeiro instante disponível."},
		{"name": "Projetor de Eras Comprimidas", "description": "Entrega milhões de anos de pressão num único segundo."},
		{"name": "Lançador de Linhas Duplicadas", "description": "Ataca a partir de duas histórias simultaneamente."},
		{"name": "Canhão de Reinício Obrigatório", "description": "Encerra todos os processos hostis sem guardar alterações."},
	],
	"armor": [
		{"name": "Colete de Criação Cancelada", "description": "Impede que o impacto chegue a existir oficialmente."},
		{"name": "Traje de Memória Temporária", "description": "Esquece cada golpe assim que deixa de ser necessário."},
		{"name": "Armadura de Civilização Arquivada", "description": "Guarda uma cópia defensiva fora da linha temporal ativa."},
		{"name": "Uniforme de Backup Eliminado", "description": "Sobrevive sem deixar uma versão anterior vulnerável."},
	],
}

const SECONDARY_ITEMS := {
	"helmet": [
		{"name": "Capacete de Espaço-Tempo Duplicado", "description": "Mantém uma segunda mente reservada no calendário cósmico."},
		{"name": "Viseira de Espécie Removida", "description": "Oculta o utilizador de qualquer limpeza automática de existência."},
		{"name": "Elmo de Passado Restaurado", "description": "Recupera pensamentos a partir de versões historicamente convenientes."},
		{"name": "Capacete de Adiamento Bloqueado", "description": "Termina cada dúvida antes de a confirmação aparecer."},
	],
}

const PACK := {"id": "central_reinicios_cosmicos", "planet": PLANET, "targets": TARGETS, "events": EVENTS, "items": ITEMS, "secondary_items": SECONDARY_ITEMS}
