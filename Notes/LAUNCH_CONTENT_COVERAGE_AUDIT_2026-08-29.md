# Crooked Galaxy — auditoria transversal de conteúdo de lançamento

Estado: diagnóstico executável e primeira correção implementada, 29 de agosto de 2026.

## Pergunta

Com o eixo planetário fechado em 35 mundos, esta auditoria mede se missões, equipamento, retenção, Fenda e economia formam um RPG idle de longo prazo. A contagem de planetas deixou de ser a medida principal; a prioridade passa a ser a quantidade de decisões, objetivos e despesas relevantes que esses planetas sustentam.

## Cobertura confirmada

| Eixo | Estado executável | Leitura |
| --- | --- | --- |
| Rede de mandados | 35 planetas, 140 alvos e 70 incidentes até ao nível 320 | Catálogo lógico de lançamento completo; expansão congelada. |
| Equipamento | nove espaços universais e 2 180 séries normais | Variedade e cauda de coleção suficientes; nenhuma de 100 carreiras completou o catálogo após 5 000 contratos. |
| Retenção curta | três objetivos diários | Ciclo limitado e honesto de 1/3/5 caçadas, sem obrigação premium. |
| Retenção semanal | três metas e um Mandado Negro | Um motivo semanal funcional, reutilizando bosses desbloqueados sem reativar campanha linear. |
| Fenda | duas realidades, 24 primeiras vitórias | Teste diário de build coerente, mas apenas 24 dias únicos e final mecânico no nível 155. |
| Economia | Mercado, Oficina, quatro transportes e incidentes pagos | Créditos perdem pressão após os transportes; uma carreira padrão conserva 136 391 créditos ao fim de 200 vitórias. |
| Carreira antes deste batch | oito marcos | Terminava no quinto mundo, cinco capturas de embalo e 25 de sucata reciclada, muito antes do horizonte anual. |

## Correção escolhida

A escada permanente de Carreira era a quebra mais direta entre o conteúdo já produzido e a perceção de progresso. Ela passa de oito para dezenove marcos estáveis:

- caçadas normais em 100, 500, 1 000, 2 000 e 3 000 vitórias;
- descoberta em 10, 15, 20, 25, 30 e 35 mundos;
- os oito marcos iniciais permanecem compatíveis e na mesma ordem;
- cada dossier mostra progresso numérico e barra visual;
- todos os pagamentos são únicos, explícitos e somam 46 230 Créditos e 482 Sucata ao longo de toda a escada.

Esses pagamentos são reconhecimento, não uma nova curva de poder. O total de Créditos é pequeno perante a renda tardia e a Sucata chega em passos espaçados. Nenhum marco concede Fichas de Dobra, combustível, nível, atributos, entrada de Fenda ou equipamento exclusivo.

## Proteção executável

`test_launch_content_coverage.gd` fixa num único gate as contagens dos cinco eixos, os 24 primeiros clears atuais da Fenda, as 2 180 séries e os dezenove marcos até 3 000 caçadas/35 mundos. Testes de regras, persistência, UI, texto e mobile protegem derivação, resgate único, tradução PT/EN, paginação leve e apresentação do progresso.

## Próxima prioridade

O próximo problema de maior impacto é a utilidade dos Créditos depois da compra dos quatro transportes. A solução deve ser uma despesa recorrente, voluntária e transparente que preserve o Mercado premium como venda de novas escolhas, não uma melhoria garantida. Só depois dessa decisão económica se deve produzir uma terceira realidade da Fenda; acrescentar doze inimigos antes de estabilizar a recompensa de longo prazo aumentaria conteúdo sem resolver o excedente que ele próprio paga.
