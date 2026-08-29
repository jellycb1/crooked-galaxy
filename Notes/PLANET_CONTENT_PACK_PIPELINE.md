# Crooked Galaxy — pipeline modular de conteúdo planetário

Estado: migração concluída e pipeline continuado com vinte e nove planetas até ao nível 260.

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

`content_pack_registry.gd` garante unicidade entre pacotes e é a fonte única da composição determinística de planetas, alvos, incidentes e catálogos de equipamento.

`content_db.gd` continua a expor `PLANET`, `PLANETS`, `TARGETS`, `HUNT_EVENTS`, `ITEM_CATALOG`, `PLANET_ITEM_CATALOGS` e `SECONDARY_ITEM_CATALOGS` como constantes públicas. Agora essas constantes são aliases diretos da composição do registry; consumidores, ordem, resultados e saves não mudaram.

## Regras para migrar um planeta existente

1. Copiar os valores exatos para `scripts/content/packs/<planet_id>.gd`.
2. Não renomear IDs, chaves, ataques, itens ou textos.
3. Registar o pack no registry.
4. Substituir no `ContentDB` apenas os blocos equivalentes por constantes do pack.
5. Adicionar teste de igualdade e âncoras de economia/combate.
6. Executar testes de pack, conteúdo, missões, progressão, fluxo, tradução e persistência.
7. Executar a suite completa antes de concluir qualquer migração ou novo pack.

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
| Aerópolis de Penhora | `aeropolis_penhora.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e rig | Migrado |
| Arquivo Abissal N-9 | `arquivo_abissal_n9.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e implant | Migrado |
| Verdântia Patenteada | `verdantia_patenteada.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e botas | Novo · nível 50 |
| Caldeira de Garantia | `caldeira_garantia.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e luvas | Novo · nível 60 |
| Condomínio Lunar 7 | `condominio_lunar_7.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e capacete | Novo · nível 70 |
| Necrópole Solar Umbral | `necropole_solar_umbral.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e rig | Novo · nível 80 |
| Central de Tempestades 24h | `central_tempestades_24h.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e implante | Novo · nível 90 |
| Museu do Amanhã Obsoleto | `museu_amanha_obsoleto.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e botas | Novo · nível 100 |
| Biblioteca do Silêncio Taxado | `biblioteca_silencio_taxado.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e luvas | Novo · nível 110 |
| Resort do Horizonte de Eventos | `resort_horizonte_eventos.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e capacetes | Novo · nível 120 |
| Tribunal de Clones Não Autorizados | `tribunal_clones_nao_autorizados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e rigs | Novo · nível 130 |
| Mosteiro da Gravidade Reversa | `mosteiro_gravidade_reversa.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e implantes | Novo · nível 140 |
| Mercado de Memórias Usadas | `mercado_memorias_usadas.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e botas | Novo · nível 150 |
| Estaleiro de Naufrágios Temporais | `estaleiro_naufragios_temporais.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e luvas | Novo · nível 160 |
| Bolsa de Luas Fracionadas | `bolsa_luas_fracionadas.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e capacetes | Novo · nível 170 |
| Fábrica de Sóis Recondicionados | `fabrica_sois_recondicionados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e rigs | Novo · nível 180 |
| Clínica de Planetas Descontinuados | `clinica_planetas_descontinuados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e implantes | Novo · nível 190 |
| Correio de Buracos de Minhoca | `correio_buracos_minhoca.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e botas | Novo · nível 200 |
| Aquário de Oceanos Confiscados | `aquario_oceanos_confiscados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e luvas | Novo · nível 210 |
| Central de Sonhos Penhorados | `central_sonhos_penhorados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e capacetes | Novo · nível 220 |
| Canil de Asteroides Domésticos | `canil_asteroides_domesticos.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e rigs | Novo · nível 230 |
| Cartório do Último Horizonte | `cartorio_ultimo_horizonte.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e implantes | Novo · nível 240 |
| Universidade de Vilania por Correspondência | `universidade_vilania_correspondencia.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e botas | Novo · nível 250 |
| Agência de Deuses Reformados | `agencia_deuses_reformados.gd` | planeta, 4 alvos, 2 incidentes, arma, traje e luvas | Novo · nível 260 |

O catálogo atual está totalmente modular e a composição manual duplicada foi removida de `ContentDB`. O registry valida tanto o contrato de cada pack como a ordem e integridade dos arrays e catálogos compostos. Os vinte e dois packs novos entre os níveis 50 e 260 provam que planetas entram por um único ponto de registo, mantendo a fachada pública e a compatibilidade de saves. Os seus 88 retratos e 66 ambientes/ícones estão catalogados como entregas pendentes do utilizador; o código conserva fallbacks e não cria assets substitutos.
