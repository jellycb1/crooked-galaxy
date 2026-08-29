# Crooked Galaxy — auditoria do serviço de Créditos da Oficina

Estado: decisão implementada e simulada, 29 de agosto de 2026.

## Problema medido

Uma carreira determinística de 200 contratos comprava os quatro transportes até à vitória 88 e terminava no nível 33 com 136 391 Créditos. O Mercado continuava útil para procurar peças, mas o saldo permitia comprar stock tardio sem uma escolha real. Acrescentar outra renovação por Créditos foi rejeitado porque concorreria diretamente com a identidade das Fichas de Dobra; desgaste obrigatório, reparações e taxas de missão foram rejeitados por criarem dor artificial.

## Solução

Calibrar poder ou reforçar integridade continua a exigir Sucata e passa também a pagar um serviço em Créditos. A transação só acontece quando os dois saldos cobrem o custo completo e deduz ambos atomicamente.

- Sucata continua a ser o recurso escasso que limita quantas melhorias existem.
- Créditos pagam a mão de obra recorrente e não substituem Sucata.
- O serviço deriva do nível persistido da peça, não do seu poder bruto; equipamento lateral e builds diferentes recebem tratamento coerente.
- A primeira intervenção segue aproximadamente o quadrado do nível do item, acompanhando a curva da renda.
- Repetir calibração ou reforço na mesma peça aumenta progressivamente o serviço.
- Peças antigas sem `item_level` usam uma aproximação segura e os starters conservam pisos de 60/75 Créditos.
- A UI mostra Créditos e Sucata no saldo, no botão, na recomendação e no recibo antes/depois da transação.

Nos checkpoints 1, 4, 8, 13, 19, 30, 50, 75 e 100, uma primeira calibração custa entre meia e duas recompensas de um mandado padrão. Assim, o serviço é uma decisão visível desde o início sem tornar uma única melhoria num bloqueio de vários dias.

## Simulação

`tools/audit_workshop_credit_sink.gd` executa 40 carreiras determinísticas de 200 contratos, gera e decide loot real, recicla peças inferiores, compra cada transporte assim que possível e aplica no máximo uma intervenção racional da Oficina por contrato.

Resultado mediano:

- nível final 33;
- quatro transportes adquiridos;
- 55 intervenções de Oficina;
- 23 707 Créditos pagos em serviços;
- saldo final 112 808, contra 136 391 sem o serviço;
- 17,4% do saldo que seria retido foi absorvido.

O objetivo não é esvaziar a carteira. Créditos continuam a financiar Mercado, incidentes e futuras despesas; a mudança apenas devolve custo de oportunidade ao investimento repetido sem vender poder premium nem atrasar a escada de transportes.

## Limites comerciais

O serviço não usa Fichas de Dobra, não oferece melhoria garantida, não altera o roll do item e não cria compras reais. Renovações premium continuam limitadas a três novas seleções por 1/5/20 Fichas; a peça revelada continua a custar Créditos. A próxima expansão recomendada volta a ser conteúdo de build: uma terceira realidade da Fenda com doze inimigos, chave gameplay-only e recompensa simulada dentro desta economia.
