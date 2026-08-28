# Crooked Galaxy — pipeline modular de conteúdo planetário

Estado: fundação ativa; os cinco primeiros planetas foram migrados sem alteração de comportamento.

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

`content_db.gd` continua a expor `PLANET`, `PLANETS`, `TARGETS`, `HUNT_EVENTS`, `ITEM_CATALOG`, `PLANET_ITEM_CATALOGS` e `SECONDARY_ITEM_CATALOGS`. Os cinco primeiros pacotes apenas mudaram a origem dos dados; consumidores, resultados e saves não mudaram.

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
| Congelária S.A. | `congelaria_sa.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e capacete | Migrado |
| Micélia 404 | `micelia_404.gd` | planeta, 4 alvos, 2 incidentes, arma, traje, capacete e luvas | Migrado |
| Ferro-Velho Ômega | `ferro_velho_omega.gd` | planeta, 4 alvos, 2 incidentes e 5 slots de equipamento | Migrado |
| Cassino Quasar | `cassino_quasar.gd` | planeta, 4 alvos, 2 incidentes e 5 slots de equipamento | Migrado |
| Aerópolis de Penhora | — | permanece no monólito | Pendente |
| Arquivo Abissal N-9 | — | permanece no monólito | Pendente |

O próximo batch deve concluir a migração dos sete mundos atuais com Aerópolis e Arquivo Abissal. Esses pacotes devem manter deliberadamente ramificações tardias distintas: `rig` em Aerópolis e `implant` no Arquivo, sem herdar automaticamente `helmet`, `gloves` ou `boots` na tabela de drops desses planetas.
