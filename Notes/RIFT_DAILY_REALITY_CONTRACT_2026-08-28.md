# Fenda Clandestina — contrato de realidades diárias

Estado: fundação e três realidades implementadas. Os envelopes determinísticos estão protegidos; apresentação e sensação física tardias continuam pendentes de um save Android nos níveis correspondentes.

## Loop ativo

1. Nível 8 revela a Fenda e entrega permanentemente a chave da **Alfândega do Universo Morto**.
2. Cada realidade tem doze inimigos fixos, progressão própria e uma chave própria.
3. O jogador escolhe entre as realidades cujas chaves já possui; realidades futuras e os seus inimigos não são antecipados.
4. Existe uma tentativa gratuita global por dia UTC. Iniciar a luta regista-a de forma atómica; fechar a aplicação ou mudar de ecrã não cancela o confronto.
5. A vitória revela então Créditos, XP e o artefacto selado, e só receber esse artefacto avança um inimigo.
6. A vitória encerra novas tentativas até ao próximo reset, impedindo uma segunda recompensa no mesmo dia mesmo que o recibo ainda esteja pendente.
7. Derrota mantém o mesmo inimigo, todo o progresso e o embalo dos mandados. Até três repetições nesse dia podem ser confirmadas por 1/5/20 Fichas de Dobra; a quarta é sempre bloqueada.

## Chaves e expansão

- Uma chave abre o conjunto inteiro e nunca é consumida.
- A realidade seguinte só pode entregar a chave quando a anterior está completa e o nível mínimo foi alcançado.
- A chave surge em caçadas normais, não dentro da própria Fenda. Isto devolve o jogador ao loop principal e evita que um sistema diário fechado se alimente sozinho.
- A segunda chave exige nível 100 e tem proteção de azar de cinco **dias elegíveis**. Somente a primeira caçada normal elegível de cada dia faz o roll. A aquisição seleciona a realidade nova, mas ambas continuam acessíveis por separadores.
- A terceira chave exige a conclusão do Veredito Congelado e nível 160. Surge em no máximo sete dias elegíveis, seleciona a Cidade dos Futuros Recusados e preserva acesso às duas realidades anteriores.
- Obter uma chave pendente abre a interface numa cerimónia de estabilização do portal. Até existirem os assets externos aprovados, o cliente usa somente um fallback procedural explicitamente não produtivo; o jogador pode saltar a animação e o inimigo permanece oculto até a chave ser reconhecida.
- O save schema 22 migra o antigo `challenge_floor` para a primeira realidade, preserva progresso e inicializa os novos campos sem inventar uma chave avançada.

## Informação e surpresa

Antes da entrada são visíveis somente a realidade atual, progresso por setor, inimigo atual, poder, vida, probabilidade com a build presente e regra completa da anomalia. Não são mostrados inimigos futuros nem conteúdo do drop. A mensagem “Recompensa selada” promete equipamento e recursos superiores sem expor item, raridade, espaço, Créditos ou XP.

Após a vitória, o recibo revela o conteúdo completo e permite equipar, guardar ou reciclar. O drop é canónico por inimigo e persistido no fluxo normal de recompensa; reiniciar a aplicação não rerrola o resultado.

## Progressão e monetização

- A Fenda não consome combustível, não avança objetivos diários e não interfere com reputação, domínio ou sequência dos mandados.
- A primeira tentativa é gratuita. Somente após derrota podem ser compradas até três repetições do mesmo confronto por 1/5/20 Fichas, com preço e saldo mostrados antes da confirmação.
- Vitória fecha o dia; não se vendem vitórias adicionais, recompensa repetida, chaves, saltos, alteração de inimigo, chance de vitória ou revelação do drop.
- Mercado e combustível mantêm contadores 1/5/20 independentes. Combustível nunca é usado pela Fenda.
- Esta separação permite recuperar de azar sem vender poder: a build e a probabilidade não mudam, e o teto continua uma vitória por dia.

## Conteúdo inicial e envelope

A primeira realidade conserva os doze inimigos e seis anomalias já auditados. A segunda, **Veredito do Tempo Congelado**, possui doze inimigos, 36 ataques e doze artefactos narrativamente próprios, do Oficial do Segundo Congelado ao Veredito que Nunca Degela. Os IDs compostos e a linhagem mecânica dos artefactos preservam saves interrompidos e recompensas já possuídas; o envelope das três classes nos níveis 100–155 fica entre 47% e 82%.

A terceira, **Cidade dos Futuros Recusados**, acrescenta doze identidades, 36 ataques e doze artefactos próprios, do Fiscal de Vistos Temporais ao Futuro que Despediu o Presente. Ela ocupa os checkpoints 160–215, entrega +2 poder sobre a linhagem base sem trocar espaços ou traços universais e paga recursos dentro da economia normal. A auditoria das três classes mede 47–88% de chance, com cada encontro entre 40% e 90% e spread máximo de 30 pontos percentuais. Assim, aumenta pressão e identidade sem criar uma classe obrigatória nem equipamento premium.

As duas realidades avançadas pagam em cada primeira vitória 1,25× os Créditos e XP de um mandado padrão do respetivo checkpoint. O Veredito totaliza 335 703 Créditos/13 929 XP; a Cidade totaliza 718 428 Créditos/20 229 XP ao longo de doze dias mínimos. O artefacto persiste esse checkpoint como nível económico e pode ser servido em qualquer um dos nove espaços da Oficina. Cada pagamento avançado cobre 1,69 primeiros serviços da peça correspondente; schema 25 repõe o nível correto em artefactos antigos sem o campo. O recurso permanece limitado a uma primeira vitória por inimigo e uma vitória global por dia; as repetições pagas só existem depois de derrota e nunca geram conteúdo adicional depois de a realidade terminar.

A simulação integrada de 36 primeiras vitórias combina Fenda, caçadas reais, loot, reciclagem, objetivos diários/semanais, Circuito, Mandado Negro, transportes e Oficina. Perfis gratuitos concluem 168–228 caçadas e retêm a Fenda em 22,9–23,9% da renda bruta; o perfil de 160 combustível conclui 370 e reduz essa parcela a 15,1%, mas recebe os mesmos 1 059 023 Créditos da Fenda. Assim, premium compra atividade normal adicional, nunca repete nem multiplica a recompensa diária selada.

O sistema atual prova 36 vitórias e 36 identidades de inimigo de primeira conclusão, distribuídas por no mínimo 36 dias bem-sucedidos. A cronologia real é muito mais longa porque cada andar foi calibrado num checkpoint: 8–90, 100–155 e 160–215. No baseline de 55% por tentativa, o gratuito padrão termina o ano com cinco inimigos da segunda realidade acessíveis; o gratuito eficiente conclui a segunda perto do dia 323 e alcança o primeiro inimigo da terceira; o perfil máximo com 160 combustível e repetições chega a nove inimigos da terceira, pois nível 200 só ocorre no dia 364. A Fenda atual ultrapassa assim o primeiro ano; uma quarta realidade fica congelada até existir uma projeção de segundo ano e builds pós-215. Eventos, Arena e coleção continuam necessários para variedade transversal, não para tapar uma falsa ausência de andares. O fallback visual permanece até cada substituto, independentemente da autoria, passar o gate visual obrigatório.
