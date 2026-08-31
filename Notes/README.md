# Crooked Galaxy — mapa documental

Estado: índice normativo. Atualizado após a auditoria geral de 31 de agosto de 2026.

Este ficheiro define a autoridade dos documentos. Relatórios datados preservam decisões e medições históricas, mas nunca substituem o código, os testes ou os contratos ativos.

## Ordem de autoridade

1. `AGENTS.md` — limites operacionais e autorização de Codex para criar, corrigir e integrar assets visuais através do gate obrigatório.
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
| `PROJECT_STATUS.md` | Handoff conciso do estado atual, validação e próximas prioridades. |
| `Vision.txt` | Fantasia central, tom, ciclo e princípios do produto. |
| `ACCOUNT_SERVER_CONTRACT.md` | Conta, personagem, International 1 e futura autoridade remota. |
| `BACKEND_VERTICAL_SLICE_CONTRACT.md` | Protocolo v1 de sessão, UTC, snapshots, comandos idempotentes e recibos remotos. |
| `REMOTE_ECONOMY_CONTRACT.md` | Autoridade remota de caçadas, economia, recompensas e ordem de ativação anterior a Agências/faturação. |
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
| `REQUIRED_ASSET_INVENTORY_EN.txt` | Checklist em inglês contendo apenas nomes e quantidades das entregas visuais. |
| `MODULAR_CHARACTER_IMAGE_RULES.md` | Regra artística única para produzir as oito raças a partir das 50 referências selecionadas e das descrições aprovadas. |
| `ASSET_GENERATION_RULES.md` | Gate obrigatório para criar, corrigir, receber e integrar material visual. |
| `ORIGINAL_VISUAL_ASSETS.md` | Proveniência dos assets de produção existentes e experiências rejeitadas. |

## Evidência operacional mantida

`STAGING_OFFSITE_BACKUP_EVIDENCE_2026-08-30.md` continua no repositório porque prova o estado operacional atual do backup e restauro de staging. Auditorias de desenvolvimento concluídas e blueprints implementados foram removidos da árvore de trabalho; o histórico Git é o arquivo canónico dessas versões, medições e decisões superadas.

## Artefactos locais

`builds/`, `.godot/`, `.test_appdata/` e `artifacts/` são regeneráveis e não são documentação. `References/` é a biblioteca local de estudo, permanece fora do Git e dos exports, mas não deve ser apagada durante limpezas rotineiras. Não se devem conservar APKs, logs ou capturas de QA dentro de `Notes/`.
