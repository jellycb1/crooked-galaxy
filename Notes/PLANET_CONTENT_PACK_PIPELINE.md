# Crooked Galaxy — pipeline modular de conteúdo planetário

Estado: fundação ativa; Dustball Prime migrado sem alteração de comportamento.

## Objetivo

Evitar que os 35 planetas, 140 alvos e aproximadamente 70 incidentes do catálogo anual transformem `scripts/content_db.gd` num único ficheiro impossível de rever.

Cada planeta passa a ter um pacote canónico que reúne:

- definição e ordem de desbloqueio;
- quatro alvos, exatamente um por tier;
- um boss;
- dois incidentes com três decisões cada;
- quatro famílias de arma;
- quatro famílias de traje;
- famílias secundárias opcionais;
- IDs estáveis que continuam compatíveis com saves e traduções.

## Estrutura

```text
scripts/content/
  planet_content_pack.gd
  content_pack_registry.gd
  packs/
    dustball_prime.gd
```

`planet_content_pack.gd` rejeita IDs inseguros, campos ausentes, alvos de outro planeta, tiers duplicados, boss ausente, incidentes incompletos, escolhas duplicadas e catálogos fora do contrato universal.

`content_pack_registry.gd` garante unicidade entre pacotes e oferece uma fronteira única para composição futura.

`content_db.gd` continua a expor `PLANET`, `PLANETS`, `TARGETS`, `HUNT_EVENTS` e `ITEM_CATALOG`. O primeiro passo apenas mudou a origem dos dados de Dustball; consumidores, resultados e saves não mudaram.

## Regras para migrar um planeta existente

1. Copiar os valores exatos para `scripts/content/packs/<planet_id>.gd`.
2. Não renomear IDs, chaves, ataques, itens ou textos.
3. Registar o pack no registry.
4. Substituir no `ContentDB` apenas os blocos equivalentes por constantes do pack.
5. Adicionar teste de igualdade e âncoras de economia/combate.
6. Executar testes de pack, conteúdo, missões, progressão, fluxo, tradução e persistência.
7. Executar a suite completa antes de concluir a migração dos sete planetas atuais.

## Regras para um planeta novo

Um pacote novo só entra no registry quando:

- passa integralmente pelo contrato;
- o nível e `unlock_after` mantêm a ordem anual;
- possui quatro identidades de alvo e exatamente um boss;
- inclui dois incidentes;
- fornece arma e traje;
- define apenas slots secundários universais válidos;
- possui PT/EN completos;
- passa simulações de missão, economia e conteúdo anual;
- os caminhos visuais aparecem no catálogo, mesmo que continuem em fallback até o utilizador fornecer os assets.

## Estado da migração

| Planeta | Pack | Conteúdo preservado | Estado |
| --- | --- | --- | --- |
| Dustball Prime | `dustball_prime.gd` | planeta, 4 alvos, 2 incidentes, arma e traje | Migrado |
| Congelária S.A. | — | permanece no monólito | Pendente |
| Micélia 404 | — | permanece no monólito | Pendente |
| Ferro-Velho Ômega | — | permanece no monólito | Pendente |
| Cassino Quasar | — | permanece no monólito | Pendente |
| Aerópolis de Penhora | — | permanece no monólito | Pendente |
| Arquivo Abissal N-9 | — | permanece no monólito | Pendente |

O próximo batch deve migrar Congelária e Micélia, comparar a progressão secundária de capacete/luvas e só depois avançar para os quatro mundos tardios.
