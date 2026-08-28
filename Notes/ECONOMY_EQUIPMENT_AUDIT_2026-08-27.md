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

## Pacotes de atributos — quinto batch

Os pacotes de atributos entram como alternativa a uma modificação normal, nunca como uma segunda camada acumulada na mesma peça. O primeiro corte abrange somente capacete, luvas, botas, rig e implante; arma e traje preservam a sua curva vertical, enquanto gadget e relíquia continuam reservados para sistemas posteriores. Cada pacote permanece universal entre classes: +2 Força, +3 Vitalidade, +3 Destreza, +2 Inteligência ou +3 Astúcia. Os valores diferentes atravessam os limiares mecânicos próprios de cada atributo sem converter todos os resultados em poder bruto.

A simulação cruzou as três classes nos níveis 8, 19 e 35. O atributo principal produziu em média a maior alteração de probabilidade, enquanto todos os cinco pacotes registaram valor mensurável no comparador completo. Picos elevados continuam possíveis junto a limiares de turnos do combate determinístico, tal como nas modificações existentes; por isso, a frequência total de modificadores não aumentou. Apenas 35% dos drops secundários que já teriam uma modificação recebem um pacote de atributos.

Combate, estimativa de campo, comparação de builds, Mercado, Arsenal, recompensas, reciclagem e saneamento de saves usam a mesma definição canónica. Astúcia passou a integrar explicitamente a pontuação comparativa através da precisão, fechando o caso em que um ganho real podia parecer neutro. Um save adulterado não pode inventar IDs, aplicar um pacote numa posição inválida nem acumular pacote e trait.

A nova auditoria de 80 carreiras × 120 contratos manteve a escada saudável: upgrades caem de 55,3% nos contratos 1–20 para 20,9% nos contratos 101–120, com intervalo mediano tardio de quatro contratos. A raridade permanece em 63,6% Comum, 26,3% Raro e 10,2% Épico; os pacotes representam 1,7% de todos os drops. A versão é `0.41.0` código 97 e mantém o schema 19, pois o novo campo opcional de item é saneado sem alterar a forma obrigatória do jogador.

## Stock lateral — sexto batch

O Mercado mantém exatamente três ofertas. As duas primeiras continuam sempre arma e traje; a terceira passa a rodar entre as famílias secundárias que o planeta ativo já pode conceder. Dustball preserva a alternância arma/traje por não possuir uma fonte lateral, Congelaria introduz capacetes, Micelia acrescenta luvas e Ferro-Velho/Cassino acrescentam botas. Rig e implante permanecem exclusivos da Fenda, sem diluir a identidade da escada clandestina.

Uma auditoria de 30 dias × quatro ciclos por planeta confirmou rotação equilibrada. Entre as ofertas laterais, a incidência de modificadores ficou entre 34,2% e 45,8%, e os pacotes de atributos entre 7,5% e 16,7% consoante a perícia local. O refresh premium continua a vender apenas uma nova seleção: não garante pacote nem melhoria.

Como o poder-base das secundárias é deliberadamente plano, a primeira regressão revelou preços demasiado baixos relativamente a uma missão nos níveis 75 e 100. Uma componente quadrática limitada, ativa somente depois do nível 50 e somente para secundárias, restaurou a relação protegida pelo teste de economia. Aos níveis 75/100, a oferta lateral representativa custa 4.048/7.421 Créditos perante missões de 7.626/13.532 Créditos. Progressão inicial, preços de arma/traje, transportes, moedas premium e schema de save permanecem inalterados. A correção corresponde à versão `0.41.1` código 98.

## Gadget, relíquia e Fenda madura — sétimo batch

A Fenda Clandestina cresce de seis para doze pisos sem criar outra moeda, menu ou fonte de grind. Os três primeiros pisos continuam a entregar rigs, os três seguintes implantes, os pisos 7–9 ativam gadgets e os pisos 10–12 ativam relíquias. Cada recompensa é fixa, universal entre classes e lateral: abertura, integridade, esquiva, ruptura de defesa, mitigação, contra-ataque ou rajada curta substituem saltos grandes de poder bruto.

Três anomalias maduras reutilizam os eixos já ensinados com pressões menos absolutas. A simulação acumulativa cruza as três classes em doze checkpoints dos níveis 8–90; todos os protótipos equilibrados preservam pelo menos 40% de probabilidade, nenhum ultrapassa 90%, o maior spread fica dentro de 30 pontos percentuais e as seis identidades introdutórias continuam intactas. O maior efeito da escada numa rota normal de campanha permanece 22 pontos; na rota segura, zero.

No Android, doze chips individuais seriam ilegíveis. O progresso agora resume quatro setores num grid 2×2, cada um com avanço `0/3` a `3/3`, preservando o dossier, a anomalia, a recompensa e a ação fixa. Os limites antigos de seis pisos na recompensa e no texto de conclusão foram removidos. PT/EN, touch/scroll 450×800 e a matriz exaustiva de persistência passaram sem alteração de schema. A versão é `0.42.0` código 99.
