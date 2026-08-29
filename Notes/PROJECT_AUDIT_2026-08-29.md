# Crooked Galaxy — auditoria detalhada do estado atual

Estado: snapshot técnico de 29 de agosto de 2026, após completar o catálogo de lançamento e corrigir a cronologia anual da Fenda. Este relatório é evidência datada; código, testes e contratos ativos permanecem autoritativos.

## Diagnóstico executivo

Crooked Galaxy já possui um RPG idle local completo o suficiente para testar retenção: criação obrigatória de personagem, três classes, oito raças cosméticas, três mandados simultâneos, caçadas assíncronas, combate automático, equipamento universal, Mercado, Oficina, transportes, progressão diária/semanal, Carreira e três realidades da Fenda.

O projeto deixou de ter uma lacuna quantitativa de primeiro ano. Os 35 mundos, 140 alvos, 70 incidentes, 2.180 séries colecionáveis e 36 inimigos da Fenda ultrapassam a progressão alcançável dos perfis anuais aprovados. Acrescentar outro planeta, checklist ou realidade agora aumentaria complexidade sem resolver um problema medido.

O jogo ainda não está pronto para lançamento comercial. Conta, relógio, progresso, carteira premium e recibos continuam locais; faltam 422 entregas visuais externas; e vários comportamentos só podem ser validados honestamente num Android físico. Estes são os bloqueadores reais.

## Estado mensurável

| Área | Estado em 0.85.2 |
| --- | --- |
| Scripts de runtime | 100 ficheiros / 20.597 linhas |
| Testes | 63 ficheiros / 8.986 linhas |
| Classes / raças | 3 classes mecânicas / 8 raças cosméticas |
| Inventário universal | 9 slots, 2 loadouts e 2.180 séries |
| Rede de missões | 35 mundos, 140 alvos e 70 incidentes |
| Fenda | 3 realidades, 36 inimigos e 36 primeiras recompensas |
| Idiomas | Português e Inglês completos e simétricos |
| Autoridade | Dispositivo local; `International 1` é identidade reservada, não servidor real |
| Assets visuais | 6/428 disponíveis; 422 entregas externas em falta |
| APK validado anterior | 0.85.2/code 151, API 24+, ARM64, assinatura estável |

## Produto e progressão

O ciclo central está fechado e persiste em segundo plano: `mandado → abordagem → viagem → perseguição → incidente → combate → recompensa → equipamento → novo mandado`. Uma missão ativa não bloqueia navegação nem depende de o jogo permanecer aberto.

A progressão anual continua lenta e limitada pelo combustível:

- 100 combustível, oferta padrão: 1.427 caçadas e nível 120 ao fim de 365 dias;
- 100 combustível, rota mais barata: 2.304 caçadas e nível 162;
- 160 combustível, oferta padrão: 2.008 caçadas e nível 148;
- 160 combustível, rota mais barata: 3.263 caçadas e nível 200.

O nível 320 e os mundos 210–320 são margem de produção, não progressão paga obrigatória. A cronologia checkpoint-aware da Fenda mantém ainda os inimigos de níveis 205, 210 e 215 além do perfil anual mecanicamente mais rápido. Uma quarta realidade permanece injustificada.

## RPG, combate e equipamento

As três classes têm atributos e respostas táticas distintas sem fragmentar o inventário. Todos os nove slots aceitam qualquer classe e raça, e equipamento preserva nível, raridade, origem, integridade, calibração, traits, pacotes de atributos e coleção.

As sondas atuais da Fenda mantêm envelopes representativos de 44–90%, 47–82% e 47–88% entre classes. Os cohorts tardios continuam a exigir pelo menos duas abordagens viáveis acima de 55%. Não existe evidência para recalibrar combate, inimigos ou recompensas neste batch.

## Retenção e monetização

O stack atual combina combustível diário, objetivos 1/3/5, metas semanais 8/20/35, Mandado Negro, Circuito da Rede, domínio de alvos, coleção vitalícia, Carreira e uma vitória diária global na Fenda.

Monetização continua coerente com o contrato: sem anúncios, passe ou loot boxes; Warp Chips renovam Mercado, combustível e até três derrotas da mesma Fenda por 1/5/20, com confirmação e limite diário. Não compram níveis, atributos, equipamento, odds, chaves ou uma segunda vitória diária.

A simulação atual de 40 carreiras × 200 contratos termina no nível 33 com os quatro transportes e mediana de 57 serviços de Oficina. O serviço absorve 24.883 Créditos, 18,2% do saldo que seria retido, sem criar uma venda premium de poder.

## Persistência, conta e servidor

Saves continuam atómicos, versionados, migráveis, recuperáveis por backup e protegidos contra duplicação de recompensa. O benchmark local mede 11,5 ms de mediana e 13,7 ms de p95 com 120 itens, sem justificar enfraquecer a garantia do backup mais recente.

O limite de conta está correto, mas ainda é apenas um contrato local. Antes de lançamento ou faturação real faltam autenticação, refresh, relógio de servidor, perfil autoritativo, carteira, recibos idempotentes, recuperação de compras, conflitos, telemetria e moderação. Arena, rankings e Sindicatos não podem confiar no save atual do dispositivo.

## UI, Android e desempenho

O shell, menu, navegação persistente, scroll por arrasto, 125% de texto, safe areas e touch targets possuem cobertura automatizada. Ainda exigem validação física: Circuito da Rede, eventos em background, vibração/toast, saves migrados e latência num inventário maduro.

O perfil desta auditoria encontrou uma regressão de escala concreta no Mapa Galáctico. Com todos os mundos abertos, a view construía 368 nós e demorava 31,8 ms no desktop, apesar de um ecrã Android apresentar apenas uma pequena fração. O batch 0.86.0 pagina o catálogo em cinco rotas, mantém as 35 acessíveis, abre descobertas na página correta e preserva o contexto após confirmação. O mesmo cenário passa a 103 nós e 11,7 ms: menos 72% de nós e menos 63% de tempo síncrono.

Arsenal/Séries ainda medem aproximadamente 48 ms no primeiro render e 12–13 ms aquecidos. O prefetch existente permanece justificado; qualquer otimização adicional deve partir de perfil físico, não de remoção especulativa de informação.

## Arquitetura e manutenção

`game_state.gd` e `main.gd` continuam concentrações de aproximadamente 2.972 e 2.800 linhas. Isso é dívida de ownership, mas não uma falha demonstrada: transações, fases, lifecycle, saves e UI possuem cobertura ampla. Uma reescrita geral seria mais arriscada do que extrações oportunistas de views ou fronteiras transacionais completas.

O pipeline modular dos 35 planetas eliminou o antigo risco de `content_db.gd` concentrar todo o conteúdo. O catálogo está indexado, validado e protegido por IDs canónicos. Expansão além do nível 320 deve continuar congelada.

## Bloqueadores e ordem recomendada

1. **Android físico:** validar o mapa paginado, Circuito, scroll/texto, background, feedback e saves migrados.
2. **Assets externos:** receber e integrar candidatos um a um através do gate obrigatório; Codex não cria nem modifica artwork.
3. **Backend de lançamento:** escolher provider/API e implementar uma fatia vertical de autenticação, relógio, revisão e perfil antes de faturação, PvP ou guildas.
4. **Telemetria de teste:** medir retorno, escolhas de rota, combustível, derrotas/retries e latência antes de alterar tempos ou economia.
5. **Performance dirigida:** depois de dados físicos, atacar apenas cold paths que excedam o orçamento real.

Não se recomenda neste momento uma quarta Fenda, novos planetas, passe, anúncios, redução premium de tempos, reescrita de estado ou rebalanceamento por sensação.
