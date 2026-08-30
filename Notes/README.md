# Crooked Galaxy — mapa documental

Estado: índice normativo. Atualizado após a auditoria de organização de 28 de agosto de 2026.

Este ficheiro define a autoridade dos documentos. Relatórios datados preservam decisões e medições históricas, mas nunca substituem o código, os testes ou os contratos ativos.

## Ordem de autoridade

1. `AGENTS.md` — limites operacionais do repositório, incluindo a proibição de Codex criar assets visuais.
2. Código e testes — comportamento executável atual.
3. Contratos ativos abaixo — intenção de produto e limites que o código deve preservar.
4. `README.md` — visão técnica e instruções de execução.
5. Auditorias e registos datados — contexto histórico, não instruções vigentes.

Quando dois documentos discordarem, aplica-se o documento de maior autoridade. Valores mensuráveis devem ser confirmados nos testes e simuladores atuais.

## Vocabulário canónico

- **Raça** é o termo de produto em português; `species` permanece o nome técnico estável nos saves e no código.
- **Fichas de Dobra** é o nome português da moeda premium; **Warp Chips** é o nome inglês e `warp_chips` o ID técnico.
- **Mandado** é a oferta/contrato de caça. **Caçada** é a execução assíncrona aceite.
- **Fenda Clandestina** é o nome do sistema; **realidade** é cada conjunto de doze inimigos aberto por uma chave.
- Contagens acompanhadas de uma versão ou data são históricas. Contagens sem qualificação devem coincidir com código e testes atuais.

## Produto e contratos ativos

| Documento | Responsabilidade |
| --- | --- |
| `Vision.txt` | Fantasia central, tom, ciclo e princípios do produto. |
| `ACCOUNT_SERVER_CONTRACT.md` | Conta, personagem, International 1 e futura autoridade remota. |
| `BACKEND_VERTICAL_SLICE_CONTRACT.md` | Protocolo v1 de sessão, UTC, snapshots, comandos idempotentes e recibos remotos. |
| `ONLINE_BACKEND_DECISION_2026-08-29.md` | Seleção de Nakama, alternativas, autenticação, offline, custos e fases de ativação. |
| `STAGING_RUNBOOK.md` | Topologia TLS, preparação, deploy, backup, rollback e evidência operacional de staging. |
| `BOUNTY_AGENCY_CONTRACT.md` | Agências de Caçadores, Mandado coletivo, cargos, justiça e autoridade social. |
| `MONETIZATION_CONTRACT.md` | Limites comerciais, moedas e ausência de anúncios/passe. |
| `EQUIPMENT_SYSTEM_CONTRACT.md` | Inventário universal, geração, raridade e proteção. |
| `YEAR_ONE_CONTENT_CONTRACT.md` | Escala de 365 dias, curva e teto de produção. |
| `RIFT_DAILY_REALITY_CONTRACT_2026-08-28.md` | Fenda diária, chaves, sigilo e monetização. |
| `WEEKLY_OPERATIONS_CONTRACT_2026-08-28.md` | Objetivos e operações semanais. |
| `NETWORK_CIRCUIT_CONTRACT_2026-08-29.md` | Rotação semanal repetível dos mundos e alvos já desbloqueados. |
| `PLANET_CONTENT_PACK_PIPELINE.md` | Contrato modular para planetas, alvos, incidentes e loot. |
| `XP_PACING_SIMULATION_2026-08-28.md` | Curva de XP ativa e resultados reproduzíveis. |

## Direção visual e entregas do utilizador

| Documento | Responsabilidade |
| --- | --- |
| `VISUAL_DIRECTION.md` | Identidade visual vigente e hierarquia da UI. |
| `UI_ASSET_INVENTORY_PT.md` | Inventário mestre de assets ainda necessários. |
| `CHARACTER_ASSET_BRIEF_PT.txt` | Especificação visual das classes e raças para o artista. |
| `CHARACTER_AND_UI_ASSET_BRIEF_EN.txt` | Brief visual consolidado em inglês para personagens e todos os assets reutilizáveis da UI. |
| `ASSET_GENERATION_RULES.md` | Gate de receção para material visual fornecido externamente; subordinado à proibição de autoria em `AGENTS.md`. |
| `ORIGINAL_VISUAL_ASSETS.md` | Proveniência dos assets de produção existentes e experiências rejeitadas. |
| `REFERENCE_PLACEHOLDERS.md` | Registro arquivado da remoção das antigas referências em runtime. |

## Registo vivo

`AUDIT_2026-08-23.md` é o changelog técnico acumulado. Apenas a entrada mais recente e a seção `Current priorities` descrevem a situação presente; entradas numeradas anteriores são históricas.

## Relatórios arquivados

Estes ficheiros são evidência datada. Podem explicar uma decisão, mas as suas contagens, versões, capturas e próximas etapas podem ter sido superadas:

- `ECONOMY_EQUIPMENT_AUDIT_2026-08-27.md`;
- `HUNT_FUEL_IMPLEMENTATION_2026-08-28.md`;
- `PACING_INTERFACE_SCALABILITY_2026-08-28.md`;
- `POLISH_PERFORMANCE_QOL_2026-08-28.md`;
- `PROJECT_STATE_AUDIT_2026-08-28.md`;
- `PROJECT_AUDIT_2026-08-29.md`;
- `LAUNCH_CONTENT_COVERAGE_AUDIT_2026-08-29.md`;
- `UI_IDENTITY_AUDIT_2026-08-26.md`;
- `UI_REBUILD_BLUEPRINT_2026-08-27.md`;
- `WORKSHOP_CREDIT_SERVICE_AUDIT_2026-08-29.md`.
- `RIFT_36_DAY_ECONOMY_AUDIT_2026-08-29.md`.
- `RIFT_YEAR_ONE_CHRONOLOGY_AUDIT_2026-08-29.md`.

## Artefactos locais

`builds/`, `.godot/`, `.test_appdata/` e `artifacts/` são regeneráveis e não são documentação. `References/` é a biblioteca local de estudo, permanece fora do Git e dos exports, mas não deve ser apagada durante limpezas rotineiras. Não se devem conservar APKs, logs ou capturas de QA dentro de `Notes/`.
