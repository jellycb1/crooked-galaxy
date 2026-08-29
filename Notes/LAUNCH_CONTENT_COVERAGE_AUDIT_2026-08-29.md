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
| Retenção semanal | três metas, um Circuito da Rede e um Mandado Negro | Volume, variedade planetária e alvo especial são decisões distintas sem criar outra energia ou campanha linear. |
| Fenda | três realidades, 36 primeiras vitórias | Teste diário de build coerente nos checkpoints 8–215; a cronologia corrigida ultrapassa o primeiro ano mesmo no perfil máximo. |
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

`test_launch_content_coverage.gd` fixa num único gate as contagens dos cinco eixos, os 36 primeiros clears atuais da Fenda, as 2 180 séries e os dezenove marcos até 3 000 caçadas/35 mundos. Testes de regras, persistência, UI, texto e mobile protegem derivação, resgate único, tradução PT/EN, paginação leve e apresentação do progresso.

## Continuação implementada

A Oficina passou a cobrar um serviço em Créditos além da Sucata, conforme `WORKSHOP_CREDIT_SERVICE_AUDIT_2026-08-29.md`. A simulação preserva os quatro transportes e absorve medianamente 17,4% do saldo que seria retido após 200 contratos. A continuação seguinte acrescenta a terceira realidade da Fenda, com doze inimigos, chave gameplay-only, 36 dias totais de primeira conclusão e envelope de recompensas compatível com esta economia.

O Circuito da Rede fecha a lacuna repetível seguinte sem expandir o catálogo: até três mundos por semana, duas capturas em cada, um cartão garantido no quadro e 250 Créditos/18 Sucata resgatáveis uma vez. Doze semanas cobrem os 35 mundos; o sistema reutiliza os 140 alvos através das regras normais de rotação e não altera combustível, tempo, pressão ou pagamento dos mandados.

A auditoria conjunta posterior fecha a lacuna de evidência da Fenda: 36 primeiras vitórias representam 15,1–23,9% da renda bruta dos três perfis, financiam os quatro transportes e 202–405 intervenções sem saldo negativo. Artefactos avançados guardam o seu nível económico e os nove espaços recebem serviço; viagens tardias mantêm até 140 minutos mas uma missão normal nunca excede a reserva gratuita de 100 combustível. Resultados completos estão em `RIFT_36_DAY_ECONOMY_AUDIT_2026-08-29.md`.

## Correção cronológica e continuidade

A primeira leitura dos 36 clears confundia “uma vitória possível por dia” com “um inimigo equilibrado por dia”. A cronologia checkpoint-aware posterior prova que os inimigos foram balanceados para níveis 8–90, 100–155 e 160–215. O perfil máximo chega apenas ao nono inimigo da terceira realidade no primeiro ano; a quarta realidade deixa de ser uma lacuna de lançamento.

Essa correção revelou um problema de navegação mais imediato: Carreira e Menu tratavam a realidade selecionada em 12/12 como conclusão de toda a Fenda. Agora ambos procuram uma realidade possuída ainda incompleta, mostram o seu nome, próximo inimigo e nível recomendado, e selecionam-na antes de abrir. Quando a realidade atual termina sem nova chave, apresentam o nível da próxima chave ou os dias elegíveis já realizados; somente 36/36 com todas as três chaves usa “Fenda concluída”. Isto preserva a escada anual existente sem criar outra checklist diária ou conteúdo vertical prematuro.
