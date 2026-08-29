class_name ChallengeRules
extends RefCounted

const MonetizationRulesScript = preload("res://scripts/monetization_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")

const UNLOCK_PLANET_ID := "dustball_prime"
const UNLOCK_LEVEL := 8
const FLOORS_PER_SECTOR := 3
const REWARD_SECTORS := ["rig", "implant", "gadget", "relic"]

const ANOMALY_PROFILES := {
	"volatile_opening": {
		"name": "CÂMARA VOLÁTIL",
		"description": "A primeira troca sobrecarrega emboscadas, mas a turbulência atravessa quase todos os amortecedores.",
		"opening_damage_multiplier": 2.5,
		"damage_reduction_piercing": 0.85,
		"attack_roll_bonus_multiplier": 3.0,
		"defense_bypass_multiplier": 0.0,
		"counter_damage_multiplier": 1.0,
		"favored_axis": "ABERTURA",
	},
	"armor_rupture": {
		"name": "FALHA DE CONTENÇÃO",
		"description": "A ruptura dissipa ataques de abertura e desvia sistemas de mira; poder sustentado e casco reforçado ganham valor.",
		"opening_damage_multiplier": 0.5,
		"damage_reduction_piercing": 0.75,
		"attack_roll_bonus_multiplier": 0.30,
		"defense_bypass_multiplier": 0.5,
		"counter_damage_multiplier": 1.0,
		"favored_axis": "PODER SUSTENTADO",
	},
	"inertial_anchor": {
		"name": "ÂNCORA INERCIAL",
		"description": "Metade da mitigação funciona e sistemas de mira permanecem estáveis; builds mistas atravessam o combate longo.",
		"opening_damage_multiplier": 1.0,
		"damage_reduction_piercing": 0.5,
		"attack_roll_bonus_multiplier": 30.0,
		"defense_bypass_multiplier": 0.5,
		"counter_damage_multiplier": 0.0,
		"favored_axis": "BUILD MISTA",
	},
	"calibrated_opening": {
		"name": "RESSONÂNCIA CALIBRADA",
		"description": "A Fenda amplifica aberturas sem deixar que um único disparo resolva todo o andar; casco e precisão continuam relevantes.",
		"opening_damage_multiplier": 1.35,
		"damage_reduction_piercing": 0.65,
		"attack_roll_bonus_multiplier": 1.5,
		"defense_bypass_multiplier": 0.5,
		"counter_damage_multiplier": 1.0,
		"favored_axis": "ABERTURA CONTROLADA",
	},
	"reinforced_rupture": {
		"name": "RUPTURA REFORÇADA",
		"description": "A pressão reduz aberturas e precisão sem apagar defesas maduras; poder contínuo ganha espaço sem monopolizar a luta.",
		"opening_damage_multiplier": 0.8,
		"damage_reduction_piercing": 0.55,
		"attack_roll_bonus_multiplier": 0.6,
		"defense_bypass_multiplier": 0.7,
		"counter_damage_multiplier": 1.0,
		"favored_axis": "PRESSÃO SUSTENTADA",
	},
	"stabilized_anchor": {
		"name": "ÂNCORA ESTABILIZADA",
		"description": "Precisão, mitigação e contra-ataque funcionam parcialmente; a vantagem pertence a builds coerentes, não a imunidades.",
		"opening_damage_multiplier": 1.0,
		"damage_reduction_piercing": 0.52,
		"attack_roll_bonus_multiplier": 3.0,
		"defense_bypass_multiplier": 0.7,
		"counter_damage_multiplier": 0.5,
		"favored_axis": "CONTROLE MISTO",
	},
}

const STAGES := [
	{
		"id": "rift_customs_drone",
		"name": "Drone da Alfândega Morta",
		"title": "ANDAR 1 · TRIAGEM ILEGAL",
		"description": "Ainda fiscaliza uma fronteira apagada dos mapas e cobra juros desde o colapso.",
		"anomaly_id": "volatile_opening",
		"power": 36, "defense": 13, "health": 321, "credits": 118, "xp": 145,
		"attacks": ["Carimbo Cinético", "Taxa Retroativa", "Scanner de Contrabando"],
		"reward": {"name": "Cinto de Lacres Rompidos", "description": "Redistribui peso, munição e responsabilidade jurídica.", "slot": "rig", "power": 1, "rarity": "Comum", "trait_id": "smuggler_harness"},
	},
	{
		"id": "rift_echo_collector",
		"name": "Cobrador de Ecos",
		"title": "ANDAR 2 · ARQUIVO SONORO",
		"description": "Confisca últimas palavras, revende ameaças e nunca emite recibo em voz baixa.",
		"anomaly_id": "armor_rupture",
		"power": 60, "defense": 17, "health": 450, "credits": 146, "xp": 172,
		"attacks": ["Cobrança Ressonante", "Protesto Sônico", "Juro em Repetição"],
		"reward": {"name": "Arnês de Frequência Torta", "description": "Transforma ruído de combate em decisões marginalmente úteis.", "slot": "rig", "power": 1, "rarity": "Raro", "trait_id": "counterweight_servos"},
	},
	{
		"id": "rift_quartermaster",
		"name": "Intendente Sem Regimento",
		"title": "ANDAR 3 · DEPÓSITO FANTASMA",
		"description": "Administra munição para um exército inexistente e considera você atraso de inventário.",
		"anomaly_id": "inertial_anchor",
		"power": 81, "defense": 32, "health": 630, "credits": 178, "xp": 205,
		"attacks": ["Baixa de Estoque", "Rajada Patrimonial", "Inventário Hostil"],
		"reward": {"name": "Plataforma do Intendente", "description": "Tem bolsos para tudo, inclusive para uma desculpa de emergência.", "slot": "rig", "power": 2, "rarity": "Épico", "trait_id": "quickdraw_bus"},
	},
	{
		"id": "rift_memory_leech",
		"name": "Sanguessuga de Memória",
		"title": "ANDAR 4 · CLÍNICA REVOGADA",
		"description": "Remove lembranças embaraçosas e deixa apenas a fatura do procedimento.",
		"anomaly_id": "volatile_opening",
		"power": 84, "defense": 34, "health": 665, "credits": 216, "xp": 244,
		"attacks": ["Débito Craniano", "Amnésia Parcelada", "Sinapse Predatória"],
		"reward": {"name": "Nódulo de Memória Contrabandeada", "description": "Lembra os erros do inimigo antes que ele consiga repeti-los.", "slot": "implant", "power": 1, "rarity": "Comum", "trait_id": "reflex_archive"},
	},
	{
		"id": "rift_probability_clerk",
		"name": "Escrivão de Probabilidades",
		"title": "ANDAR 5 · CARTÓRIO CAUSAL",
		"description": "Registra futuros possíveis e multa qualquer realidade que saia sem autenticação.",
		"anomaly_id": "armor_rupture",
		"power": 122, "defense": 37, "health": 825, "credits": 258, "xp": 292,
		"attacks": ["Firma Reconhecida", "Cláusula Improvável", "Penhora do Futuro"],
		"reward": {"name": "Córtex de Cálculo Clandestino", "description": "Prevê três resultados e escolhe o menos documentado.", "slot": "implant", "power": 1, "rarity": "Raro", "trait_id": "illegal_adrenaline"},
	},
	{
		"id": "rift_null_warden",
		"name": "Carcereiro do Setor Nulo",
		"title": "ANDAR 6 · CELA SEM UNIVERSO",
		"description": "Guarda uma prisão vazia com dedicação suficiente para prender novas leis da física.",
		"anomaly_id": "inertial_anchor",
		"power": 190, "defense": 60, "health": 865, "credits": 310, "xp": 348,
		"attacks": ["Sentença de Antimatéria", "Confinamento Vetorial", "Apelo Negado"],
		"reward": {"name": "Interface do Setor Nulo", "description": "Liga o caçador a uma rede que oficialmente nunca existiu.", "slot": "implant", "power": 2, "rarity": "Épico", "trait_id": "null_synapse"},
	},
	{
		"id": "rift_signal_poacher",
		"name": "Caçador de Sinais",
		"title": "ANDAR 7 · ESTAÇÃO SEM FREQUÊNCIA",
		"description": "Coleciona pedidos de socorro raros e vende silêncio certificado em lotes industriais.",
		"anomaly_id": "calibrated_opening",
		"power": 195, "defense": 68, "health": 980, "credits": 372, "xp": 418,
		"attacks": ["Farol Predatório", "Ruído de Captura", "Silêncio Revendido"],
		"reward": {"name": "Facho de Jurisdição Duvidosa", "description": "Marca o alvo, o contrato e ocasionalmente o proprietário errado.", "slot": "gadget", "power": 1, "rarity": "Comum", "trait_id": "warrant_flare"},
	},
	{
		"id": "rift_counterfeit_future",
		"name": "Futuro Contrafeito",
		"title": "ANDAR 8 · AMANHÃ APREENDIDO",
		"description": "Chegou antes de existir e exige indemnização por todos os acontecimentos que não sofreu.",
		"anomaly_id": "reinforced_rupture",
		"power": 215, "defense": 75, "health": 1150, "credits": 446, "xp": 502,
		"attacks": ["Previsão Fraudulenta", "Atraso Retroativo", "Possibilidade Penhorada"],
		"reward": {"name": "Isca de Amanhã Improvável", "description": "Convence disparos de que acertaram numa versão menos atual do caçador.", "slot": "gadget", "power": 1, "rarity": "Raro", "trait_id": "probability_decoy"},
	},
	{
		"id": "rift_breach_bailiff",
		"name": "Oficial de Rupturas",
		"title": "ANDAR 9 · PORTA SEM PAREDE",
		"description": "Arromba realidades, entrega intimações e cobra deslocação entre dimensões.",
		"anomaly_id": "stabilized_anchor",
		"power": 250, "defense": 84, "health": 1380, "credits": 532, "xp": 598,
		"attacks": ["Mandado de Entrada", "Dobradiça Balística", "Despejo Dimensional"],
		"reward": {"name": "Drone de Entrada Sem Convite", "description": "Encontra a abertura técnica entre uma fechadura e a definição de propriedade.", "slot": "gadget", "power": 2, "rarity": "Épico", "trait_id": "breach_assistant"},
	},
	{
		"id": "rift_gravity_notary",
		"name": "Notário da Gravidade",
		"title": "ANDAR 10 · PESO AUTENTICADO",
		"description": "Reconhece firmas em órbitas, hipotecas em luas e quedas em triplicado.",
		"anomaly_id": "calibrated_opening",
		"power": 295, "defense": 100, "health": 1700, "credits": 636, "xp": 714,
		"attacks": ["Carimbo de Massa", "Órbita Compulsória", "Firma em Queda Livre"],
		"reward": {"name": "Nó de Gravidade Portátil", "description": "Mantém o caçador no lugar mesmo quando o lugar pede demissão.", "slot": "relic", "power": 1, "rarity": "Comum", "trait_id": "gravity_knot"},
	},
	{
		"id": "rift_loop_auditor",
		"name": "Auditor de Repetições",
		"title": "ANDAR 11 · SEGUNDO EM ATRASO",
		"description": "Revê o mesmo instante até encontrar uma versão fiscalmente mais ofensiva.",
		"anomaly_id": "reinforced_rupture",
		"power": 363, "defense": 125, "health": 2200, "credits": 762, "xp": 852,
		"attacks": ["Reincidência Temporal", "Minuto Sob Protesto", "Juro Recursivo"],
		"reward": {"name": "Segundo Que Recusa Acabar", "description": "Devolve uma fração do conflito quando a contabilidade do tempo fecha.", "slot": "relic", "power": 1, "rarity": "Raro", "trait_id": "recurring_second"},
	},
	{
		"id": "rift_last_claim",
		"name": "Última Reivindicação",
		"title": "ANDAR 12 · BALCÃO DO FIM",
		"description": "Alega propriedade sobre tudo o que resta depois do universo, incluindo as taxas de encerramento.",
		"anomaly_id": "stabilized_anchor",
		"power": 465, "defense": 160, "health": 2900, "credits": 918, "xp": 1024,
		"attacks": ["Cláusula Terminal", "Inventário do Vazio", "Assinatura Final"],
		"reward": {"name": "Prisma da Última Cláusula", "description": "Divide uma certeza em várias infrações úteis e igualmente brilhantes.", "slot": "relic", "power": 2, "rarity": "Épico", "trait_id": "null_prism"},
	},
]

# Authored identity layer for the second reality. Combat values, traits and
# reward slots continue to inherit the audited twelve-floor envelope above;
# only fiction and collectible identity change. Composite runtime IDs remain
# unchanged, preserving interrupted schema-22/23 saves.
const FROZEN_VERDICT_IDENTITIES := [
	{
		"name": "Oficial do Segundo Congelado", "title": "ANDAR 1 · INTIMAÇÃO IMÓVEL",
		"description": "Entrega mandados num instante que nunca termina e cobra estacionamento desde antes do tempo parar.",
		"attacks": ["Carimbo de Geada", "Prazo Suspenso", "Citação Imóvel"],
		"reward": {"name": "Arnês do Prazo Suspenso", "description": "Mantém munição e desculpas legais preservadas fora do fluxo temporal."},
	},
	{
		"name": "Júri dos Recursos Mudos", "title": "ANDAR 2 · SALA SEM DELIBERAÇÃO",
		"description": "Doze vozes congeladas votam em silêncio e apresentam a fatura em coro.",
		"attacks": ["Veredito Ressonante", "Objeção em Coro", "Silêncio Culpado"],
		"reward": {"name": "Colete de Deliberação Térmica", "description": "Converte hesitação coletiva em estabilidade quase profissional."},
	},
	{
		"name": "Carrasco do Cronómetro", "title": "ANDAR 3 · EXECUÇÃO ADIADA",
		"description": "Afia o mesmo segundo há séculos e considera pontualidade uma circunstância agravante.",
		"attacks": ["Lâmina de Ponteiro", "Contagem Condenatória", "Último Tique"],
		"reward": {"name": "Plataforma do Último Tique", "description": "Distribui ferramentas pelo intervalo exato entre agora e tarde demais."},
	},
	{
		"name": "Testemunha em Estase", "title": "ANDAR 4 · DEPOIMENTO PRESERVADO",
		"description": "Recorda tudo perfeitamente porque nada novo acontece desde o início do interrogatório.",
		"attacks": ["Memória Pericial", "Relato Imutável", "Contradição Criogénica"],
		"reward": {"name": "Nódulo da Testemunha Fria", "description": "Arquiva detalhes comprometedores antes que a realidade possa alterá-los."},
	},
	{
		"name": "Promotor de Ontem", "title": "ANDAR 5 · ACUSAÇÃO RETROATIVA",
		"description": "Processa crimes que ainda não aconteceram usando precedentes que já foram apagados.",
		"attacks": ["Culpa Anterior", "Precedente Congelado", "Alegação Retroativa"],
		"reward": {"name": "Córtex de Precedentes Mortos", "description": "Prevê a acusação seguinte consultando decisões que o tempo recusou publicar."},
	},
	{
		"name": "Glaciar de Sentenças", "title": "ANDAR 6 · ARQUIVO SOB ZERO",
		"description": "Uma montanha de decisões acumuladas avança à velocidade judicial e com o mesmo peso.",
		"attacks": ["Desabamento Jurídico", "Pena Perpétua", "Recurso Soterrado"],
		"reward": {"name": "Interface da Pena Glacial", "description": "Liga o pensamento a jurisprudência suficientemente fria para não discutir."},
	},
	{
		"name": "Relojoeiro da Condicional", "title": "ANDAR 7 · OFICINA DE PENAS",
		"description": "Repara relógios de sentença e acrescenta meses sempre que sobra uma engrenagem.",
		"attacks": ["Mola de Reincidência", "Liberdade Atrasada", "Pêndulo Penal"],
		"reward": {"name": "Sinalizador de Hora Condicional", "description": "Marca a única janela em que fugir é tecnicamente uma questão de agenda."},
	},
	{
		"name": "Fiança do Inverno Eterno", "title": "ANDAR 8 · CAUÇÃO CRIOGÉNICA",
		"description": "Uma garantia viva que congela bens, contas e qualquer pessoa com aspeto de fiador.",
		"attacks": ["Penhora Térmica", "Caução Predatória", "Avalista Congelado"],
		"reward": {"name": "Isca de Fiador Improvável", "description": "Convence cobranças de que outra versão sua assinou toda a documentação."},
	},
	{
		"name": "Magistrado do Zero Absoluto", "title": "ANDAR 9 · TRIBUNAL SEM MOVIMENTO",
		"description": "Proibiu vibrações moleculares durante a audiência para evitar protestos excessivamente animados.",
		"attacks": ["Martelo Entrópico", "Ordem de Imobilidade", "Desacato Molecular"],
		"reward": {"name": "Assistente de Audiência Isotérmica", "description": "Encontra brechas legais onde até os átomos foram intimados a ficar quietos."},
	},
	{
		"name": "Avalanche de Recursos", "title": "ANDAR 10 · INSTÂNCIA SUPERIOR",
		"description": "Milhões de apelos rejeitados ganharam massa, inclinação e representação própria.",
		"attacks": ["Recurso em Massa", "Precedente Descendente", "Soterramento Final"],
		"reward": {"name": "Nó de Jurisdição Portátil", "description": "Mantém o caçador dentro da instância correta quando a lei começa a deslizar."},
	},
	{
		"name": "Capataz do Último Minuto", "title": "ANDAR 11 · TURNO INTERMINÁVEL",
		"description": "Obriga o último minuto do universo a fazer horas extra sem intervalo nem sindicato.",
		"attacks": ["Hora Extra Eterna", "Ponto Recursivo", "Intervalo Negado"],
		"reward": {"name": "Minuto que Recusa Descongelar", "description": "Devolve uma fração do turno sempre que o relógio tenta encerrar o expediente."},
	},
	{
		"name": "Veredito que Nunca Degela", "title": "ANDAR 12 · SENTENÇA DO FIM",
		"description": "A decisão final tornou-se consciente, declarou-se irrevogável e penhorou o futuro do universo.",
		"attacks": ["Cláusula Criogénica", "Execução do Amanhã", "Trânsito em Julgado"],
		"reward": {"name": "Prisma da Sentença Irrevogável", "description": "Divide uma decisão final em várias exceções úteis e legalmente luminosas."},
	},
]

# Authored identity layer for the third reality. It deliberately reuses the
# universal slot/trait ladder while giving every sealed reward and opponent a
# distinct collectible identity. Visual delivery remains external; runtime
# portraits continue through the documented procedural fallback.
const REJECTED_FUTURES_IDENTITIES := [
	{
		"name": "Fiscal de Vistos Temporais", "title": "ANDAR 1 · FRONTEIRA DO AMANHÃ",
		"description": "Recusa futuros sem fotografia recente e deporta viajantes para o ontem de onde supostamente vieram.",
		"attacks": ["Visto Cronológico", "Deportação Retroativa", "Fila do Amanhã"],
		"reward": {"name": "Arnês de Fronteira Temporal", "description": "Transporta documentos válidos em linhas temporais que ainda não reconheceram o caçador."},
	},
	{
		"name": "Prefeita que Ainda Não Nasceu", "title": "ANDAR 2 · CÂMARA PREMATURA",
		"description": "Governa por procuração fetal, inaugura ruínas futuras e culpa o presente pela baixa execução do orçamento.",
		"attacks": ["Decreto Pré-Natal", "Obra Ainda Demolida", "Orçamento do Futuro"],
		"reward": {"name": "Colete da Administração Prematura", "description": "Organiza recursos municipais antes de a cidade cometer o erro de existir."},
	},
	{
		"name": "Sindicato dos Eus Alternativos", "title": "ANDAR 3 · ASSEMBLEIA PARALELA",
		"description": "Mil versões da mesma pessoa exigem salários distintos, férias simultâneas e uma única cadeira na direção.",
		"attacks": ["Greve Multiversal", "Piquete Duplicado", "Negociação Infinita"],
		"reward": {"name": "Plataforma dos Mil Turnos", "description": "Distribui tarefas por versões alternativas que nunca assinaram o contrato original."},
	},
	{
		"name": "Contrabandista de Amanhãs", "title": "ANDAR 4 · CAIS NÃO OCORRIDO",
		"description": "Importa manhãs ensolaradas, exporta segundas-feiras e esconde décadas inteiras em contentores diplomáticos.",
		"attacks": ["Década Contrabandeada", "Segunda-Feira Exportada", "Alvorada Clandestina"],
		"reward": {"name": "Nódulo de Alfândega Prospectiva", "description": "Reconhece acontecimentos proibidos antes de eles chegarem ao controlo fronteiriço."},
	},
	{
		"name": "Carreira que Nunca Aconteceu", "title": "ANDAR 5 · RECURSOS HUMANOS HIPOTÉTICOS",
		"description": "Foi promovida do nada, gere funcionários imaginários e exige indemnização por décadas que ninguém trabalhou.",
		"attacks": ["Promoção Inexistente", "Avaliação Hipotética", "Despedimento Preventivo"],
		"reward": {"name": "Córtex do Currículo Impossível", "description": "Recorda competências adquiridas em empregos que a realidade se recusou a financiar."},
	},
	{
		"name": "Demolidor de Previsões", "title": "ANDAR 6 · ESTALEIRO CONTRAFACTUAL",
		"description": "Derruba edifícios antes da licença, recicla destinos cancelados e deixa a fatura para o universo aprovado.",
		"attacks": ["Martelo de Probabilidade", "Destino Demolido", "Entulho Causal"],
		"reward": {"name": "Interface de Demolição Causal", "description": "Marca estruturas condenadas mesmo quando só existem como uma possibilidade inconveniente."},
	},
	{
		"name": "Cobrador Contrafactual", "title": "ANDAR 7 · FINANÇAS DO IMPOSSÍVEL",
		"description": "Tributa rendimentos que poderia ter recebido e aplica juros a decisões financeiramente responsáveis.",
		"attacks": ["Imposto Hipotético", "Juro do Talvez", "Penhora Contrafactual"],
		"reward": {"name": "Sinalizador de Dívida Improvável", "description": "Aponta para a versão da conta onde outra pessoa ainda parece ser responsável."},
	},
	{
		"name": "Nostalgia da Próxima Semana", "title": "ANDAR 8 · MEMÓRIA ANTECIPADA",
		"description": "Sente falta de acontecimentos futuros, coleciona recordações por estrear e considera o presente demasiado moderno.",
		"attacks": ["Saudade Antecipada", "Memória por Estrear", "Passado da Próxima Terça"],
		"reward": {"name": "Isca de Recordação Futura", "description": "Convence ameaças de que já falharam o caçador numa lembrança particularmente convincente."},
	},
	{
		"name": "Ministro dos Resultados Impossíveis", "title": "ANDAR 9 · GOVERNO DO TALVEZ",
		"description": "Anuncia metas incompatíveis, celebra estatísticas inexistentes e demite a matemática quando os números discordam.",
		"attacks": ["Meta Incompatível", "Estatística Inventada", "Matemática Demitida"],
		"reward": {"name": "Assistente Ministerial do Talvez", "description": "Encontra uma interpretação favorável sempre que os factos insistem em aparecer."},
	},
	{
		"name": "Reformado de Outra Linha Temporal", "title": "ANDAR 10 · PENSÃO PARALELA",
		"description": "Cobra reformas de sete futuros, trabalha em todos eles e protesta contra a idade atual do universo.",
		"attacks": ["Pensão Séptupla", "Antiguidade Paralela", "Greve de Reformados Futuros"],
		"reward": {"name": "Nó de Antiguidade Paralela", "description": "Mantém benefícios acumulados em carreiras que nunca ocorreram nesta linha temporal."},
	},
	{
		"name": "Último Sobrevivente Homologado", "title": "ANDAR 11 · ABRIGO CERTIFICADO",
		"description": "Sobreviveu oficialmente a apocalipses cancelados e recusa dividir o título com vítimas não credenciadas.",
		"attacks": ["Apocalipse Certificado", "Abrigo Exclusivo", "Sobrevivência por Decreto"],
		"reward": {"name": "Segundo Certificado de Sobrevivência", "description": "Repete o instante exato em que o desastre percebe que preencheu o formulário errado."},
	},
	{
		"name": "Futuro que Despediu o Presente", "title": "ANDAR 12 · RESCISÃO DA REALIDADE",
		"description": "Declarou o agora obsoleto, assumiu o cargo com efeitos retroativos e terceirizou o fim do tempo.",
		"attacks": ["Rescisão do Agora", "Obsolescência Imediata", "Futuro Terceirizado"],
		"reward": {"name": "Prisma do Presente Obsoleto", "description": "Divide o agora em alternativas negociáveis antes que o futuro consiga cancelá-las."},
	},
]

const FIRST_REALITY_ID := "dead_customs"
const REALITIES := [
	{
		"id": FIRST_REALITY_ID,
		"key_id": "dead_customs_key",
		"name": "Alfândega do Universo Morto",
		"description": "Uma repartição presa entre o último segundo do universo e uma cobrança que se recusa a prescrever.",
		"unlock_level": UNLOCK_LEVEL,
		"stat_multiplier": 1.0,
		"reward_power_bonus": 0,
		"stages": STAGES,
	},
	{
		"id": "frozen_verdict",
		"key_id": "frozen_verdict_key",
		"name": "Veredito do Tempo Congelado",
		"description": "Uma realidade onde o último julgamento parou o relógio, mas não interrompeu a execução da sentença.",
		"unlock_level": 100,
		"previous_reality_id": FIRST_REALITY_ID,
		"stat_multiplier": 1.35,
		"power_bonus": 430,
		"defense_bonus": 145,
		"health_bonus": 2500,
		"credits_multiplier": 1.65,
		"xp_multiplier": 1.55,
		"reward_level_start": 100,
		"reward_level_step": 5,
		"credit_reward_ratio": 1.25,
		"xp_reward_ratio": 1.25,
		# Calibrated against representative level 100–155 builds in five-level
		# steps. This preserves a readable dungeon wall without four trivial
		# opening enemies or an impossible final spike.
		"difficulty_multipliers": [1.23, 1.22, 1.21, 1.24, 1.19, 1.12, 1.13, 1.12, 1.09, 1.04, 0.97, 0.87],
		"reward_power_bonus": 1,
		"key_pity_days": 5,
		"identity_stages": FROZEN_VERDICT_IDENTITIES,
		"stages": STAGES,
	},
	{
		"id": "rejected_futures",
		"key_id": "rejected_futures_key",
		"name": "Cidade dos Futuros Recusados",
		"description": "Uma metrópole construída com linhas temporais sem licença, futuros indeferidos e amanhãs que se recusaram a desaparecer.",
		"unlock_level": 160,
		"previous_reality_id": "frozen_verdict",
		"stat_multiplier": 1.80,
		"power_bonus": 900,
		"defense_bonus": 400,
		"health_bonus": 7000,
		"credits_multiplier": 2.45,
		"xp_multiplier": 2.30,
		"reward_level_start": 160,
		"reward_level_step": 5,
		"credit_reward_ratio": 1.25,
		"xp_reward_ratio": 1.25,
		# Calibrated across the three class policies at levels 160–215. The
		# descending factors counter the steeper inherited base ladder while the
		# additive mature-reality pressure keeps every encounter above reality two.
		"difficulty_multipliers": [0.85, 0.83, 0.82, 0.85, 0.83, 0.83, 0.83, 0.83, 0.81, 0.78, 0.73, 0.68],
		"reward_power_bonus": 2,
		"key_pity_days": 7,
		"identity_stages": REJECTED_FUTURES_IDENTITIES,
		"stages": STAGES,
	},
]


static func is_unlocked(player: Dictionary) -> bool:
	return int(player.get("level", 1)) >= UNLOCK_LEVEL


static func reality_definition(reality_id: String) -> Dictionary:
	for reality in REALITIES:
		if str(reality.id) == reality_id:
			return reality.duplicate(true)
	return {}


static func reality_ids() -> Array[String]:
	var ids: Array[String] = []
	for reality in REALITIES:
		ids.append(str(reality.id))
	return ids


static func initial_key_ids(player: Dictionary) -> Array[String]:
	return [str(REALITIES[0].key_id)] if is_unlocked(player) else []


static func has_reality_key(player: Dictionary, reality_id: String) -> bool:
	var definition := reality_definition(reality_id)
	return not definition.is_empty() and player.get("rift_reality_keys", []).has(str(definition.key_id))


static func progress(player: Dictionary, reality_id := FIRST_REALITY_ID) -> int:
	var definition := reality_definition(reality_id)
	if definition.is_empty():
		return 0
	var legacy_progress := int(player.get("challenge_floor", 0)) if reality_id == FIRST_REALITY_ID else 0
	var progress_by_reality: Dictionary = player.get("rift_reality_progress", {})
	return clampi(int(progress_by_reality.get(reality_id, legacy_progress)), 0, definition.stages.size())


static func selected_reality_id(player: Dictionary) -> String:
	var selected := str(player.get("selected_rift_reality_id", FIRST_REALITY_ID))
	return selected if has_reality_key(player, selected) else FIRST_REALITY_ID


static func entry_available(player: Dictionary, unix_time := -1.0) -> bool:
	var status := attempt_status(player, unix_time)
	return bool(status.can_attempt)


static func attempt_status(player: Dictionary, unix_time := -1.0) -> Dictionary:
	var day := MonetizationRulesScript.utc_day_id(unix_time)
	var attempted_today := int(player.get("rift_entry_day", -1)) == day
	var won_today := int(player.get("rift_victory_day", -1)) == day
	var retry_count := MonetizationRulesScript.rift_retry_count(player) if attempted_today else 0
	var retries_remaining := maxi(0, MonetizationRulesScript.MAX_RIFT_RETRIES_PER_DAY - retry_count)
	var retry_cost := MonetizationRulesScript.rift_retry_cost(player) if attempted_today and not won_today else 0
	var retry_stage_id := str(player.get("rift_attempt_stage_id", "")) if attempted_today else ""
	var can_pay := retry_cost > 0 and int(player.get("warp_chips", 0)) >= retry_cost
	return {
		"day": day,
		"free_attempt": not attempted_today,
		"attempted_today": attempted_today,
		"won_today": won_today,
		"retry_count": retry_count,
		"retries_remaining": retries_remaining,
		"retry_cost": retry_cost,
		"retry_stage_id": retry_stage_id,
		"can_attempt": not won_today and (not attempted_today or (retries_remaining > 0 and can_pay)),
		"retry_available": attempted_today and not won_today and retries_remaining > 0,
		"can_afford_retry": can_pay,
	}


static func next_key_reality(player: Dictionary) -> Dictionary:
	for index in range(1, REALITIES.size()):
		var reality: Dictionary = REALITIES[index]
		if has_reality_key(player, str(reality.id)) or int(player.get("level", 1)) < int(reality.unlock_level):
			continue
		var previous := reality_definition(str(reality.previous_reality_id))
		if previous.is_empty() or progress(player, str(previous.id)) < previous.stages.size():
			continue
		return reality.duplicate(true)
	return {}


static func record_eligible_hunt_for_key(player: Dictionary, unix_time := -1.0) -> Dictionary:
	var reality := next_key_reality(player)
	if reality.is_empty():
		return {}
	var day := MonetizationRulesScript.utc_day_id(unix_time)
	if int(player.get("rift_key_roll_day", -1)) == day:
		return {}
	player.rift_key_roll_day = day
	var counters: Dictionary = player.get("rift_key_hunt_progress", {}).duplicate(true)
	var reality_id := str(reality.id)
	var attempts := int(counters.get(reality_id, 0)) + 1
	counters[reality_id] = attempts
	player.rift_key_hunt_progress = counters
	var pity := maxi(1, int(reality.get("key_pity_days", reality.get("key_pity_hunts", 5))))
	var deterministic_roll := posmod(int(player.get("wins", 0)) * 31 + int(player.get("level", 1)) * 17 + reality_id.hash(), pity)
	if attempts < pity and deterministic_roll != 0:
		return {}
	var keys: Array = player.get("rift_reality_keys", []).duplicate()
	keys.append(str(reality.key_id))
	player.rift_reality_keys = keys
	var progress_by_reality: Dictionary = player.get("rift_reality_progress", {}).duplicate(true)
	progress_by_reality[reality_id] = 0
	player.rift_reality_progress = progress_by_reality
	player.selected_rift_reality_id = reality_id
	return reality


static func unseen_key_reality(player: Dictionary) -> Dictionary:
	var seen: Array = player.get("rift_seen_key_ids", [])
	for reality in REALITIES:
		var key_id := str(reality.key_id)
		if player.get("rift_reality_keys", []).has(key_id) and not seen.has(key_id):
			return reality.duplicate(true)
	return {}


static func sector_slot_for_floor(floor: int) -> String:
	if REWARD_SECTORS.is_empty():
		return ""
	var sector_index := clampi(floor / FLOORS_PER_SECTOR, 0, REWARD_SECTORS.size() - 1)
	return str(REWARD_SECTORS[sector_index])


static func sector_progress(floor: int, sector_index: int) -> int:
	if sector_index < 0 or sector_index >= REWARD_SECTORS.size():
		return 0
	return clampi(floor - sector_index * FLOORS_PER_SECTOR, 0, FLOORS_PER_SECTOR)


static func current_stage(player: Dictionary, reality_id := "") -> Dictionary:
	var resolved_reality := selected_reality_id(player) if reality_id.is_empty() else reality_id
	var definition := reality_definition(resolved_reality)
	if definition.is_empty() or not has_reality_key(player, resolved_reality):
		return {}
	var floor := progress(player, resolved_reality)
	return {} if floor >= definition.stages.size() else stage_at(floor, resolved_reality)


static func stage_at(index: int, reality_id := FIRST_REALITY_ID) -> Dictionary:
	var definition := reality_definition(reality_id)
	if definition.is_empty() or index < 0 or index >= definition.stages.size():
		return {}
	var stage: Dictionary = definition.stages[index].duplicate(true)
	var base_stage_id := str(stage.id)
	var stat_multiplier := float(definition.get("stat_multiplier", 1.0))
	stage["base_stage_id"] = base_stage_id
	if reality_id != FIRST_REALITY_ID:
		stage["id"] = "%s__%s" % [reality_id, base_stage_id]
		var identities: Array = definition.get("identity_stages", [])
		if index < identities.size():
			var identity: Dictionary = identities[index]
			for field in ["name", "title", "description", "attacks"]:
				if identity.has(field):
					stage[field] = identity[field] if field != "attacks" else identity[field].duplicate()
			var identity_reward: Dictionary = identity.get("reward", {})
			if not identity_reward.is_empty():
				var authored_reward: Dictionary = stage.get("reward", {}).duplicate(true)
				for field in ["name", "description"]:
					if identity_reward.has(field):
						authored_reward[field] = identity_reward[field]
				stage.reward = authored_reward
		for stat_key in ["power", "defense", "health"]:
			stage[stat_key] = maxi(1, roundi(float(stage.get(stat_key, 1)) * stat_multiplier) + int(definition.get("%s_bonus" % stat_key, 0)))
		var difficulty_multipliers: Array = definition.get("difficulty_multipliers", [])
		if index < difficulty_multipliers.size():
			for stat_key in ["power", "defense", "health"]:
				stage[stat_key] = maxi(1, roundi(float(stage[stat_key]) * float(difficulty_multipliers[index])))
		stage.credits = maxi(1, roundi(float(stage.get("credits", 1)) * float(definition.get("credits_multiplier", stat_multiplier))))
		stage.xp = maxi(1, roundi(float(stage.get("xp", 1)) * float(definition.get("xp_multiplier", stat_multiplier))))
		if definition.has("reward_level_start"):
			var reward_level := int(definition.reward_level_start) + index * int(definition.get("reward_level_step", 0))
			stage.credits = maxi(1, roundi(float(MissionRulesScript.standard_credit_reward(reward_level)) * float(definition.get("credit_reward_ratio", 1.0))))
			stage.xp = maxi(1, roundi(float(MissionRulesScript.standard_xp_reward(reward_level)) * float(definition.get("xp_reward_ratio", 1.0))))
			stage["reward_level"] = reward_level
	stage["reward_power_bonus"] = int(definition.get("reward_power_bonus", 0))
	stage["localization_stage_id"] = str(stage.id)
	var anomaly := anomaly_profile(str(stage.get("anomaly_id", "")))
	if anomaly.is_empty():
		return {}
	stage["challenge"] = true
	stage["challenge_index"] = index
	stage["reality_id"] = reality_id
	stage["rift_key_id"] = str(definition.key_id)
	stage["anomaly"] = anomaly
	stage["damage_reduction_piercing"] = float(anomaly.damage_reduction_piercing)
	stage["opening_damage_multiplier"] = float(anomaly.opening_damage_multiplier)
	stage["attack_roll_bonus_multiplier"] = float(anomaly.attack_roll_bonus_multiplier)
	stage["defense_bypass_multiplier"] = float(anomaly.defense_bypass_multiplier)
	stage["counter_damage_multiplier"] = float(anomaly.counter_damage_multiplier)
	stage["duration"] = 0
	stage["planet_id"] = UNLOCK_PLANET_ID
	stage["scrap_reward"] = 0
	return stage


static func anomaly_profile(anomaly_id: String) -> Dictionary:
	return ANOMALY_PROFILES.get(anomaly_id, {}).duplicate(true)


static func get_stage(stage_id: String) -> Dictionary:
	for reality in REALITIES:
		for index in reality.stages.size():
			var candidate := stage_at(index, str(reality.id))
			if str(candidate.id) == stage_id:
				return candidate
	return {}


static func reward_for(stage: Dictionary, traits: Dictionary) -> Dictionary:
	var definition: Dictionary = stage.get("reward", {}).duplicate(true)
	if definition.is_empty():
		return {}
	var rarity := str(definition.get("rarity", "Comum"))
	var colors := {"Comum": "#b9c2d9", "Raro": "#58d9ff", "Épico": "#d789ff"}
	var item := {
		"id": "%s_reward" % str(stage.id),
		"base_reward_id": "%s_reward" % str(stage.get("base_stage_id", stage.id)),
		"localization_reward_id": "%s_reward" % str(stage.get("localization_stage_id", stage.id)),
		"name": str(definition.name),
		"description": str(definition.description),
		"slot": str(definition.slot),
		"power": int(definition.power) + int(stage.get("reward_power_bonus", 0)),
		"rarity": rarity,
		"color": str(colors.get(rarity, colors.Comum)),
		"challenge_origin": "fenda_clandestina",
	}
	if stage.has("reward_level"):
		item["item_level"] = int(stage.reward_level)
	var trait_id := str(definition.get("trait_id", ""))
	for modification in traits.get(str(definition.slot), []):
		if str(modification.id) == trait_id:
			item.trait = modification.duplicate(true)
			break
	return item
