# Crooked Galaxy — auditoria do estado atual

Estado: snapshot histórico. Os Batches A–C recomendados neste relatório já foram executados; consultar `Notes/README.md`, os contratos ativos e o código para o estado vigente.

Data: 28 de agosto de 2026.

Escopo: produto, código, conteúdo, UI, Android, desempenho, monetização, conta/servidor e capacidade de expansão. Esta auditoria não cria nem altera assets visuais.

## Diagnóstico executivo

Crooked Galaxy já é um RPG idle local coerente e jogável, não apenas um protótipo de ecrãs. O ciclo `mandado → abordagem → espera em segundo plano → incidente → combate automático → recompensa → equipamento → novo mandado` está fechado, persiste corretamente e já alimenta progressão, coleção, mercado, transportes, objetivos e Fenda.

O projeto não está pronto para lançamento por quatro razões principais:

1. apenas 20% do catálogo planetário anual está autorado;
2. conta, servidor e carteira premium continuam locais e simulados;
3. faltam as entregas visuais que agora pertencem ao utilizador/artista;
4. a arquitetura atual de conteúdo não deve receber mais 28 planetas dentro do mesmo ficheiro monolítico.

O próximo passo recomendado não é criar outro sistema grande nem outro ecrã. É transformar o conteúdo atual num pipeline modular, validado e repetível. Depois devemos provar esse pipeline com o planeta de nível 50. Só então faz sentido aumentar a produção ou iniciar a implementação real do backend.

## Estado mensurável

| Área | Estado atual |
| --- | --- |
| Scripts de runtime | 62 |
| Linhas de GDScript de runtime | 17.233 |
| Ficheiros de teste | 57 |
| Capturas automatizadas Android | 102 estados a 450×800 |
| Classes iniciais | 3/3 mecanicamente implementadas |
| Raças iniciais | 8/8, cosméticas e sem bónus |
| Slots universais | 9/9 |
| Planetas autorados | 7/35 — 20% |
| Alvos autorados | 28/140 — 20% |
| Incidentes autorados | 14/70 recomendados — 20% |
| Transportes | 4 |
| Realidades da Fenda | 2 |
| Inimigos da Fenda | 24 |
| Séries de equipamento atuais | 500 combinações catalogáveis |
| Idiomas completos atuais | Português e Inglês |
| Assets no novo catálogo | 6/220 entregas; 214 em falta, com fallback |
| Autoridade de progresso | Dispositivo local |
| Backend real | Não existe |
| Faturação real | Não existe; simulação local apenas |

## O que está forte

### 1. Ciclo central

- O quadro oferece três mandados comparáveis e expande apenas o selecionado.
- Planetas desbloqueados continuam na rotação em vez de formarem uma campanha descartável.
- A força de um contrato aceite fica congelada; melhorar equipamento torna esse alvo realmente mais fácil.
- Viagem e perseguição são separadas, dando valor duradouro aos transportes.
- A missão continua em segundo plano e sobrevive a fecho, reload e retorno AFK.
- Incidentes não pausam silenciosamente o relógio.
- Combate, derrota, recompensa, reciclagem e repetição mantêm transações explícitas.

Esta é a parte mais importante do produto e já está tecnicamente provada.

### 2. Profundidade de RPG

- Três classes têm identidades mecânicas diferentes sem inventários incompatíveis.
- Cinco atributos permanecem universais.
- Nove slots servem todas as classes e raças atuais ou futuras.
- Equipamento tem poder, integridade, origem, raridade, traits, pacotes de atributo, kit planetário e coleção.
- Dois loadouts, proteção, filtros, ordenação, paginação e reciclagem já suportam inventários longos.
- Perfis de inimigo e anomalias criam perguntas de build sem verificar a classe do jogador.

O jogo já consegue suportar escolhas de build. Falta sobretudo conteúdo suficiente para que essas escolhas se renovem durante meses.

### 3. Retenção sem pressão excessiva

- reserva diária de combustível;
- objetivos diários limitados;
- Operações semanais 8/20/35;
- Mandado Negro rotativo;
- uma entrada diária global na Fenda;
- chaves permanentes com proteção contra azar;
- domínio de alvos;
- coleção vitalícia;
- carreira, arquivo e desbloqueios planetários;
- retorno AFK limitado.

Os sistemas não dependem de anúncios, passe de temporada ou checklist obrigatório. A direção comercial continua coerente.

### 4. Segurança de estado

- saves versionados e migrados;
- substituição atómica e backup;
- recuperação de corrupção;
- reparação de identificadores e equipamento;
- fases interrompidas retomadas de forma determinística;
- revisões locais que só avançam depois de gravação concluída;
- nenhuma fusão heurística de inventário, moedas ou recompensas.

Esta fundação reduz muito o risco de migrar para servidor no futuro.

### 5. Qualidade e automação

- 57 testes cobrem regras, UI, mobile, persistência, traduções, economia, performance e conteúdo.
- 102 capturas protegem PT/EN, layouts densos e estados raros.
- A suite rápida completa, incluindo boot, passou em 60,49 segundos nesta auditoria.
- O catálogo visual agora define caminhos, limites Android, fallbacks e entregas sem obrigar a existência dos assets.
- Referências permanecem isoladas do runtime e dos exports normais.

## Riscos principais

### P0 — arquitetura de conteúdo não escala para 35 planetas

`scripts/content_db.gd` já possui 1.593 linhas com:

- sete planetas;
- 28 alvos;
- 14 incidentes e 56 escolhas;
- abordagens;
- traits;
- catálogos de equipamento;
- funções de consulta e geração.

Ainda faltam 28 planetas, 112 alvos e 56 incidentes. Acrescentar tudo ao mesmo ficheiro pode levá-lo a várias milhares de linhas, aumentar conflitos, tornar revisões difíceis e permitir que um erro de conteúdo afete o catálogo inteiro.

Recomendação: dividir conteúdo por pacote planetário mantendo a API pública de `ContentDB` e os IDs atuais. Cada pacote deve declarar planeta, quatro alvos, incidentes, famílias de item e chaves de tradução. Um registry compõe os arrays atuais, e um validador rejeita pacotes incompletos ou duplicados.

### P0 — produto online ainda é apenas uma fronteira local

O schema já separa provider, conta, sessão, shard, personagem, autoridade e revisões. Isso é correto, mas ainda não existe:

- autenticação;
- refresh de sessão;
- API remota;
- relógio autoritativo;
- upload/download transacional;
- carteira premium;
- recibos idempotentes;
- recuperação de compra;
- telemetria;
- moderação de nomes;
- arena, ranking ou sindicatos.

Não devemos integrar dinheiro real, PvP ou guildas sobre saves autoritativos no dispositivo.

Isto é bloqueador de lançamento, mas não precisa ser o próximo batch imediato. Primeiro devemos estabilizar a produção modular de conteúdo, porque backend não resolve a falta de jogo para consumir.

### P0 — dívida de conteúdo anual

Os sete mundos atuais representam apenas 20% da meta. O catálogo anual ainda deve produzir:

- 28 habitats;
- 112 identidades de alvo;
- 56 incidentes;
- famílias de equipamento e traduções correspondentes;
- balanceamento por distância e nível;
- diversidade suficiente para não parecer apenas reskin.

O número de planetas sozinho não cria 365 dias. Fenda, Operações, coleção e equipamento ajudam, mas cada novo pacote deve acrescentar ao menos uma nova combinação de habitat, comportamento de inimigo, incidente e família de loot.

### P1 — monólitos de estado e apresentação

Os maiores ficheiros são:

- `scripts/game_state.gd`: 2.831 linhas;
- `scripts/main.gd`: 2.703 linhas;
- `scripts/content_db.gd`: 1.593 linhas;
- `scripts/arsenal_view.gd`: 1.003 linhas.

Não há evidência de falha causada apenas pelo tamanho: os testes são fortes e muitas views já foram extraídas. Portanto não se recomenda uma reescrita geral.

Recomendação localizada:

1. extrair primeiro dados planetários de `content_db.gd`;
2. qualquer novo sistema deve ter rules/view próprios;
3. mover de `game_state.gd` apenas fronteiras transacionais completas, nunca helpers isolados;
4. manter `main.gd` como orquestrador e continuar a extrair ecrãs inteiros quando forem alterados.

### P1 — densidade visual ainda depende de texto e código

As capturas atuais são organizadas e funcionais, mas ainda mostram três limitações:

- muitos ecrãs comunicam identidade através de texto e símbolos procedurais;
- Caçador e Arsenal apresentam muita informação acima da dobra;
- o mesmo material de painel e os mesmos fundos genéricos repetem-se em várias áreas.

Isto não deve ser corrigido com mais cartões. A melhoria deverá vir dos assets fornecidos pelo utilizador, substituindo progressivamente retratos, habitats, transportes e ícones nos pontos já inventariados.

Até esses assets existirem, o código deve preservar os fallbacks atuais. Codex não criará substitutos visuais.

### P1 — desempenho frio ainda pode ser percebido no Android

Benchmarks de desktop nesta auditoria:

| Superfície | Cold | Warm |
| --- | ---: | ---: |
| Quadro | 13,24 ms | — |
| Arsenal | 50,65 ms | 10,00 ms |
| Séries | 45,77 ms | 10,54 ms |
| Mercado | 29,83 ms | 13,91 ms |
| Carreira | 30,39 ms | Arquivo 8,68 ms |
| Fenda | 23,56 ms | — |
| Quadro interplanetário | 24,51 ms | 15,37 ms |

O prefetch real reduz a primeira entrada típica no Arsenal para aproximadamente 12,25 ms, o que mostra que a estratégia atual funciona. Porém 45–50 ms frios no desktop podem ser claramente perceptíveis num Android modesto.

Próximas medidas:

- conservar prefetch e caches;
- evitar preload global de futuros rasters;
- carregar assets do catálogo apenas quando o ecrã os usa;
- repetir Arsenal, Séries, Mercado, Carreira e Fenda no dispositivo físico;
- não otimizar cegamente sem perfil real Android.

### P1 — alterações atuais ainda não estão consolidadas no Git

O branch está em `a646ddc`, mas os últimos documentos e infraestrutura visual estão não commitados:

- regra de autoria de assets;
- briefing de classes/raças;
- inventário de UI;
- catálogo visual;
- teste e ferramenta de auditoria;
- documentação do README;
- rascunho visual rejeitado fora do runtime.

Antes de iniciar uma migração estrutural de conteúdo, este trabalho deve ser revisto e consolidado num commit separado. O rascunho rejeitado não deve entrar em produção nem tornar-se referência artística.

### P2 — monetização real não pode avançar ainda

A simulação comercial é coerente:

- Fichas Warp jogáveis;
- renovação de mercado 1/5/20;
- combustível 1/5/20;
- limites diários explícitos;
- nenhuma venda de poder, classes, espécies ou vitória;
- Fenda protegida de monetização.

Falta o produto comercial real:

- ecrã de compra;
- produtos e preços da plataforma;
- carteira de servidor;
- validação de recibo;
- idempotência;
- restauração;
- suporte e histórico;
- regras legais por região.

Não implementar faturação antes do backend. Podemos continuar a testar a economia local sem fingir que existe uma loja real.

### P2 — PvP, ranking e sindicatos continuam corretamente adiados

Esses sistemas precisam de:

- snapshots autoritativos;
- matchmaking;
- defesa persistente;
- anti-cheat;
- temporadas/ranking sem passe comercial;
- moderação;
- comparação de builds que já seja interessante.

A sua ausência não é dívida imediata. Implementá-los agora desviaria trabalho do conteúdo e do backend fundamental.

## Inconsistências documentais encontradas

1. Resolvido na auditoria de organização: o antigo `CROOKED_GALAXY_CODEX_MAX_AUTONOMY.txt`, que permitia placeholders procedurais e conflitava com `AGENTS.md`, foi removido. `AGENTS.md` permanece a única autoridade operacional do repositório.
2. Registos antigos em `Notes/AUDIT_2026-08-23.md` descrevem fases em que referências eram incluídas no APK interno. O estado atual exclui-as. Esses trechos são históricos e não devem ser lidos como instrução vigente.
3. Algumas capturas preservadas mostram versões anteriores como `v0.50.0`, enquanto o projeto está em `0.53.1`. As capturas continuam úteis para regressão, mas uma futura baseline visual deve ser regenerada antes da revisão final Android.

## Sequência recomendada

### Batch A — consolidar a baseline atual

- rever o diff atual;
- remover qualquer ficheiro que não deva ser preservado;
- manter o rascunho rejeitado fora de runtime ou arquivá-lo separadamente;
- executar suite completa, não apenas rápida;
- criar um commit exclusivamente de documentação e infraestrutura visual;
- não publicar APK se o conteúdo jogável não mudou.

### Batch B — modularizar conteúdo planetário

Criar:

- `scripts/content/planet_content_pack.gd` com contrato/validação;
- `scripts/content/content_pack_registry.gd`;
- um ficheiro de pacote por planeta;
- composição compatível com as APIs atuais de `ContentDB`;
- testes de unicidade, quatro alvos, dois incidentes, loot, tradução e ordem de unlock;
- migração sem alterar IDs, saves, economia ou resultados.

Fazer a migração em pequenos passos e comparar todas as simulações antes/depois.

### Batch C — provar o pipeline com o planeta de nível 50

O primeiro novo planeta pós-Arquivo deve incluir:

- identidade e habitat definidos em texto/dados;
- quatro alvos;
- dois incidentes;
- um boss;
- famílias de equipamento;
- perfil de inimigo;
- PT/EN completos;
- distância coerente;
- testes, simulação e capturas com fallback visual.

Não precisa de asset final para validar a mecânica. O catálogo apontará os caminhos que o utilizador deverá preencher depois.

### Batch D — segunda passagem de desempenho e Android

- perfil físico de primeiro acesso e retornos quentes;
- medir input-to-feedback em Arsenal, Séries, Mercado, Carreira e Fenda;
- medir memória com assets fornecidos progressivamente;
- validar scroll e texto longo;
- só então ajustar caches ou densidade.

### Batch E — backend vertical slice

Depois de o pipeline de conteúdo estar estável:

1. servidor de desenvolvimento local;
2. criação/login de conta real de teste;
3. sessão e refresh;
4. `International 1` remoto;
5. relógio de servidor;
6. upload/download atómico de um personagem;
7. conflito de revisões explícito;
8. carteira premium simulada no servidor;
9. nenhuma faturação nem PvP nesta primeira fatia.

### Batch F — loja real e social

Somente depois da autoridade remota:

- validação de compras;
- restauração e suporte;
- Arena assíncrona;
- ranking;
- Sindicatos.

## Recomendação final

Prosseguir agora com os Batches A e B.

O projeto já tem sistemas suficientes para justificar uma pausa na expansão horizontal. A prioridade é transformar o conteúdo existente num formato repetível e seguro. Isso permitirá adicionar os 28 planetas restantes sem degradar `content_db.gd`, manter testes por pacote, ligar os assets fornecidos pelo utilizador através de caminhos estáveis e preparar o mesmo conteúdo para autoridade de servidor mais tarde.

Não se recomenda neste momento:

- criar mais um grande sistema de retenção;
- implementar PvP;
- integrar faturação real;
- reescrever todo o estado ou UI;
- produzir assets por Codex;
- adicionar planetas diretamente ao monólito atual.
