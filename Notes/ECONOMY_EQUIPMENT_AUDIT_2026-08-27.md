# Auditoria de economia e equipamento — 2026-08-27

## Diagnóstico

O projeto já possui três economias funcionais (Créditos, Sucata e tempo), mercado determinístico, nove espaços universais, reciclagem, proteção, loadouts, oficina e loot com raridade/modificadores. Essa base permite evoluir sem reescrever o ciclo central.

As lacunas encontradas são:

- não existe carteira premium nem limite/reset diário;
- renovar o mercado consome Créditos sem limite, contrariando a direção comercial escolhida;
- o stock não possui rotação diária explícita;
- os itens não persistem template, nível, qualidade, variante e semente, limitando análise e variedade futura;
- `gadget` e `relic` estão reservados, mas ainda não entram no loop normal;
- faturação e autoridade continuam locais, portanto qualquer saldo premium atual só pode ser dado de teste, nunca dinheiro real.

## Decisão de implementação

O primeiro corte vertical altera apenas a renovação do mercado e a identidade dos novos itens. Não ativa combustível nem faturação. Isso valida a UX e a persistência da monetização com risco reduzido para o ritmo já testável.

Critérios:

- três renovações diárias por 1/5/20 Fichas;
- reset por dia UTC, preparado para trocar relógio local por servidor;
- primeira missão do dia concede uma Ficha;
- terceira renovação garante no mínimo um Raro, não uma melhoria;
- compras de itens permanecem em Créditos;
- novos itens recebem metadados procedurais sem alterar os seus atributos de combate.

## Resultado do primeiro batch de implementação

- O schema de save 16 persiste o saldo local de teste de Fichas de Dobra, dia UTC da economia, contagem diária de renovações e último prémio diário de missão.
- O mercado roda por dia UTC, cobra a escada 1/5/20 de forma atómica, bloqueia uma quarta renovação e preserva os Créditos exclusivamente para comprar os itens revelados.
- A primeira missão normal resgatada em cada dia UTC concede uma Ficha e inclui-a no recibo localizado da recompensa.
- O terceiro stock renovado promove pelo menos uma oferta para Raro quando necessário. A compatibilidade continua universal e o item não é comparado nem forçado a ser melhoria.
- Loot novo regista ID do template, nível, qualidade de 1–100, variante e semente de geração. Os campos são saneados ao carregar e ainda não alteram o combate.
- A UI portuguesa e inglesa mostra os dois saldos, próximo custo/uso e a garantia/limite diário.

## Deliberadamente adiado

- Combustível/energia não está ativo. Precisa de testes de ritmo contra o modelo atual de rotas de 5–20 minutos antes de limitar jogo.
- Células de Salto, licenças temporárias do transporte de 50% e futuros saltos de cooldown continuam opções contratuais, não botões inacabados.
- Produtos com dinheiro real e faturação ficam bloqueados até existir carteira autoritativa de backend e recibos idempotentes.
- Pacotes de atributos, raridades Incomum/Lendário e drops de `gadget`/`relic` exigem uma simulação dedicada antes de alterar combate ou cadência de loot.

## Verificação

- Gate Godot completo: todas as 49 suites e a matriz exaustiva de persistência passaram.
- Primeiro gate Android-first: APK ARM64, API 24+, pacote `com.crookedgalaxy.game`, versão `0.37.0` código 92 e assinatura estável de teste interno.
- A inspeção do export confirmou os assets de produção necessários e nenhuma referência bruta no APK.

## Auditoria de progressão procedural — segundo batch

Uma simulação determinística de 80 carreiras com 120 contratos cada analisou 9.600 drops:

- 63,3% Comuns, 26,5% Raros e 10,2% Épicos, já incluindo o efeito gradual da perícia com alvos;
- qualidade p10/mediana/p90 de 11/51/91, confirmando uma distribuição uniforme e compreensível;
- 8.773 combinações únicas de template, raridade, qualidade, variante e modificador;
- upgrades em 55,4% dos primeiros 20 drops, caindo para 20,3% entre os contratos 101–120.

O sistema já produz variedade suficiente, mas a fase estabelecida ainda recebe aproximadamente uma melhoria a cada cinco drops. Novos bónus de atributos aumentariam essa frequência e foram, por isso, rejeitados para ativação neste batch. A qualidade foi ligada ao roll real dentro da faixa de poder e passou a ser visível. As cinco variantes ganharam nomes de coleção e marcas vetoriais distintas nos ícones, aumentando reconhecimento sem alterar combate, memória de texturas ou probabilidade de vitória.

O schema 17 adiciona um catálogo permanente e saneado de combinações template/variante. A descoberta acontece mesmo quando a peça é reciclada imediatamente, de modo que sidegrades e drops fracos podem avançar coleção sem obrigar o jogador a ocupar o inventário. A Mochila apresenta o total descoberto sobre o catálogo procedural finito atual. Uma quarta aba do Arsenal, Séries, torna o catálogo consultável por planeta e família, diferencia variantes descobertas e em falta e mantém oculto o nome de famílias ainda totalmente desconhecidas. As Fichas de Dobra passaram também a integrar o cabeçalho persistente de recursos, evitando que o jogador só descubra o saldo ao abrir o Mercado.

Verificação final do segundo batch: todas as 49 suites, matriz exaustiva de persistência e gate Android passaram. O APK resultante é `0.38.1` código 94, ARM64/API 24+, com a assinatura interna estável e sem referências brutas exportadas.

## Retenção, segurança premium e desempenho — terceiro batch

Uma auditoria inicial de 100 carreiras com 1.200 contratos cada, totalizando 120.000 drops, mediu o catálogo atual de 380 séries. Uma segunda passagem estendeu cada carreira a 5.000 contratos, totalizando 500.000 drops. As medianas para descobrir 1/10/25/50/100/200/300/350 séries foram 1/11/29/62/133/337/781/1.422 contratos. Apenas 86 das 100 carreiras completaram todas as 380 dentro de 5.000 contratos, com mediana de 4.217 entre as concluídas. Por isso, o salto anterior de 100 diretamente para a conclusão foi rejeitado e recebeu marcos intermediários em 200, 300 e 350; a conclusão permanece uma meta genuinamente longa, não uma obrigação diária. A escada vitalícia completa concede 37 Fichas de Dobra, quantidade suficiente para escolhas ocasionais sem sustentar renovações premium ilimitadas.

O schema 18 persiste os marcos resgatados e rejeita IDs desconhecidos ou duplicados. O loot e as ofertas de mercado indicam `nova série` antes da decisão; receber, guardar ou reciclar continua a registar a descoberta. Recompensas disponíveis criam um badge no Arsenal e um atalho direto para Séries, enquanto o painel mostra somente o próximo marco relevante em vez de empurrar o catálogo para baixo com oito linhas.

O catálogo passou a construir um planeta de cada vez, com navegação de 48 px e posição de scroll preservada. O benchmark local mediu 99 nós e aproximadamente 9,3 ms na abertura quente, contra uma árvore única de todas as famílias. A confirmação de renovação do mercado usa 105 nós e aproximadamente 15 ms quente. Nenhuma nova textura foi adicionada.

Toda renovação premium agora exige um segundo passo explícito de confirmar ou cancelar, mostra o custo exato e avisa que as três ofertas serão substituídas. A primeira interação não gasta moeda. O Mercado também expõe a fonte jogável diária e o reinício às 00:00 UTC.

Verificação final do terceiro batch: todas as 50 suites, a matriz exaustiva de persistência e o gate Android passaram duas vezes após as decisões de cauda longa. O APK final é `0.39.0` código 95, ARM64/API 24+, com assinatura interna estável, 32,07 MB e sem referências brutas exportadas.

## Turno diário e descoberta — quarto batch

O primeiro sistema de retenção diária foi limitado ao ciclo que o jogo já prova: concluir caçadas normais. Três pagamentos opcionais abrem com 1, 3 e 5 contratos; em conjunto concedem no máximo 85 Créditos e 8 Sucata por dia. Compras, renovações premium e Fenda não avançam o contador, e nenhum objetivo diário concede Fichas de Dobra. Assim, o sistema dá uma razão curta para regressar sem transformar moeda premium em obrigação diária nem substituir loot, transportes ou contratos como fontes de progresso.

O Turno ocupa um dos seis lugares equilibrados do Menu da Fronteira, mostra progresso e pagamentos disponíveis, suporta scroll vertical e regressa corretamente pelo botão Android. A decisão de recompensa antecipa o progresso que será aplicado ao receber o loot. O badge do Menu agrega pagamentos diários e de Carreira, mas o jogador pode aceitar outra caçada sem abrir ou resgatar o Turno.

O schema 19 persiste progresso e resgates, rejeita IDs desconhecidos/duplicados e usa o mesmo reset UTC atómico do stock. O benchmark local mediu 73 nós e cerca de 9,2 ms para construir o Turno. A soma diária é explicitamente testada e permanece inferior ao preço de uma oferta de mercado no horizonte tardio analisado.

A revisão gráfica em 450×800 confirmou que Turno, Menu e recompensa mantêm margens, scroll por arrasto, ações fixas e textos PT/EN legíveis. “Pagamentos” no resumo foi tornado explicitamente “resgatados/claimed” para não confundir recompensas prontas com recompensas já recolhidas.

Na auditoria final de primeira visita, o Arsenal real abriu em 11,6 ms graças aos sete cálculos previamente aquecidos. As pinturas de Mundo e Combate ainda custavam aproximadamente 13,6 e 14,1 ms na primeira transição. O quadro passou a iniciar as três descodificações em worker requests escalonados depois do aquecimento de odds; após 200 ms de inatividade normal, as transições medidas caíram para 0,032 e 0,015 ms sem transferir trabalho para o frame do toque.

Verificação final do quarto batch: todas as 51 suites registradas, incluindo a matriz exaustiva de persistência, passaram depois da otimização. O APK `0.40.0` código 96 passou novamente o gate Android ARM64/API 24+, assinatura interna estável, orçamento de 32,08 MB e inspeção sem referências brutas.
