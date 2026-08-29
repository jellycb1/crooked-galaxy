# Crooked Galaxy — auditoria económica dos 36 dias da Fenda

Estado: diagnóstico implementado e protegido por teste, 29 de agosto de 2026.

Nota histórica: esta auditoria mede a economia de 36 **dias de primeira vitória** e foi escrita antes da decisão de permitir repetições 1/5/20 após derrota. Continua válida para pagamentos e custos de Oficina, mas não representa a cronologia real. Níveis, chaves, derrotas e Fichas de repetição são medidos em `RIFT_YEAR_ONE_CHRONOLOGY_AUDIT_2026-08-29.md`.

## Escopo

`tools/rift_calendar_economy_model.gd` simula as 36 primeiras vitórias das três realidades juntamente com o quadro real de três mandados, loot e reciclagem, Turno Diário, Operações, Circuito da Rede, Mandado Negro, quatro transportes e intervenções racionais da Oficina. Os perfis gratuito equilibrado, gratuito eficiente e 160-combustível usam as mesmas regras de runtime; apenas combustível e seleção de rota diferem.

## Resultados

| Perfil | Caçadas | Créditos brutos | Parcela da Fenda | Oficina | Circuitos | Fichas gastas / em falta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Gratuito equilibrado | 168 | 4 438 596 | 23,9% | 106 783 / 202 ações | 5 | 0 / 0 |
| Gratuito eficiente | 228 | 4 625 654 | 22,9% | 185 077 / 257 ações | 4 | 0 / 0 |
| 160 combustível | 370 | 7 006 269 | 15,1% | 391 457 / 405 ações | 5 | 936 / 900 |

Todos recebem exatamente 1 059 023 Créditos da Fenda, compram os quatro transportes e terminam com saldo positivo. Os 24 artefactos avançados geram uma responsabilidade inicial de 624 580 Créditos; cada pagamento de primeira vitória cobre 1,69 serviços da peça entregue. O perfil premium ganha mais caçadas normais, não entradas ou pagamentos adicionais da Fenda. As 36 fichas gratuitas reduzem a procura de recargas do perfil mais ativo de 936 para 900 fichas adquiridas.

## Correções decorrentes

- Artefactos avançados passam a guardar o `item_level` do checkpoint; schema 25 repara equipamento, inventário e loot pendente antigos.
- A Oficina passa de duas fichas simultâneas para um seletor dos nove espaços e um único dossier móvel. Projeções e recomendações consideram todos os equipamentos.
- Uma missão normal custa no máximo 100 combustível, embora a viagem mantenha os 124–140 minutos autorados. Isso garante uma caçada gratuita em qualquer planeta e preserva utilidade dos transportes.

Este relatório, isoladamente, não decide a quarta realidade: demonstra apenas que os pagamentos atuais são sustentáveis. A decisão de calendário pertence à auditoria cronológica posterior.
