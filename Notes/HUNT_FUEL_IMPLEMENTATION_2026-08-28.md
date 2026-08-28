# Crooked Galaxy — implementação do combustível de caça 0.48.0

Estado: sistema local completo para testes internos, 28 de agosto de 2026.

## Contrato executável

- Cada dia UTC começa com 100 unidades gratuitas de combustível.
- Uma missão normal consome os minutos inteiros da rota-base do planeta: Dustball custa 5, Congelária 8, Micélia 12, Ferro-Velho 16 e Cassino 20.
- O custo é mostrado no Quadro e na decisão do Briefing antes de comprometer a rota.
- O combustível é debitado uma única vez ao iniciar a viagem. Cancelar o Briefing não cobra; abandonar uma rota iniciada não devolve.
- Transportes reduzem apenas o tempo de viagem. Não reduzem combustível e, portanto, não compram progressão diária adicional.
- Fenda e futuros modos independentes permanecem fora da reserva de caçadas normais.
- Três recargas diárias concedem exatamente 20 unidades e custam 1, 5 e 20 Fichas de Dobra. Uma quarta recarga é bloqueada e cada compra exige confirmação explícita.
- No próximo dia UTC, combustível e contador de recargas regressam a 100 e zero. Combustível de um dia não acumula.

O schema 21 adiciona `hunt_fuel` e `hunt_fuel_refill_count`. Saves anteriores recebem a reserva integral, enquanto valores impossíveis são limitados a 0–160 e 0–3. Início de missão, gasto premium e persistência usam transações únicas; sinais duplicados não podem cobrar a mesma rota duas vezes.

## Resultado da auditoria de ritmo

A simulação de 365 dias com os seis planetas atuais e sem recargas pagas produz:

| Estratégia | Caçadas/ano | Média diária | Nível final | Combustível usado/dia |
| --- | ---: | ---: | ---: | ---: |
| Oferta padrão | 2 383 | 6,5 | 389 | 91,0 |
| Rota disponível mais barata | 4 705 | 12,9 | 766 | 96,4 |

Isto não invalida os 100 pontos: confirma que a reserva limita o jogo e que os destinos criam escolhas reais. Porém, também demonstra que o catálogo até nível 300 não basta para quem esgota a reserva escolhendo rotas curtas. A cadência dos 27 planetas futuros deve aumentar custos de rota de forma controlada e a promessa anual deve ser reavaliada contra o jogador eficiente, não apenas contra cinco caçadas fixas.

## Limites

Não existe faturação real, anúncio, passe, energia da Fenda nem relógio autoritativo de servidor. Fichas e reset UTC continuam a ser uma simulação local transparente para validar UX, saves e balanceamento antes da infraestrutura online.

O gate completo passou em 54 suítes e 143,95 segundos, incluindo as 1 659 combinações da matriz de persistência, migrações, PT/EN, expansão de texto, touch, lifecycle e boot limpo. Capturas a 450 × 800 confirmam as três ofertas e as três abordagens no primeiro ecrã com custo legível.
