# Crooked Galaxy — contrato do sistema de equipamento

Estado: direção aprovada para implementação. A estrutura é estável; curvas, pesos e cadência permanecem ajustáveis.

## Estrutura universal

Todas as classes atuais e futuras usam o mesmo inventário e os mesmos nove espaços:

`weapon`, `helmet`, `armor`, `gloves`, `boots`, `rig`, `implant`, `gadget` e `relic`.

As classes tornam peças mais ou menos úteis através de atributos, efeitos e builds. Restrições rígidas por classe devem ser exceção, não a regra.

## Modelo de geração

O jogo combina um conjunto finito de famílias visuais e templates com instâncias procedurais praticamente ilimitadas. Cada item gerado deve poder registar:

- template/família base e espaço;
- nível do item e origem planetária;
- raridade e qualidade do roll;
- variante visual/material;
- pacote futuro de atributos;
- modificador opcional;
- estado de melhoria da oficina;
- semente estável da instância.

Itens épicos e lendários podem ter mais autoria visual e narrativa. A grande variedade normal deve vir de combinações controladas, não de milhares de imagens isoladas.

## Progressão e raridade

- A maioria das melhorias deve ser pequena. Sidegrades e trade-offs são parte deliberada da progressão.
- O nível do item sobe com o jogador e a dificuldade; diferenças pequenas de poder mantêm valor sem acelerar excessivamente a campanha.
- O cliente atual usa três raridades: Comum, Raro e Épico. A estrutura futura poderá acrescentar Melhorado/Incomum e Lendário limitado apenas com nova simulação, localização e apresentação; os nomes finais ainda podem mudar.
- O mercado fornece mais rolls, nunca uma melhoria garantida. O preço do item continua em Créditos.
- Investimentos da oficina devem ser visíveis e recuperáveis em parte ao substituir ou reciclar uma peça.

Cadência inicial para balanceamento:

- início: uma melhoria aproximadamente a cada 1–2 contratos;
- meio: a cada 3–5 contratos;
- jogador estabelecido: a cada 6–10 contratos;
- longo prazo: raridades, sidegrades, coleção e otimização tornam-se os objetivos principais.

## Proteções de qualidade de vida

Comparação automática, filtros por espaço/raridade, proteção contra reciclagem, reciclagem em lote e loadouts devem acompanhar o crescimento do catálogo. O jogador nunca deve precisar memorizar qual peça é melhor nem perder um item investido por um toque acidental.

## Sequência de implementação

1. Persistir identidade procedural sem alterar o combate atual.
2. Medir distribuição de qualidade, raridade, upgrades e sidegrades.
3. Dar valor permanente aos sidegrades através da coleção de famílias/variantes sem aumentar poder.
4. Introduzir pacotes de atributos e sinergias de classe apenas se novas simulações preservarem a cadência.
5. Expandir gadgets/relics, raridades e famílias visuais somente após a navegação e comparação suportarem o volume.

Estado atual: as etapas 1–4 estão implementadas e simuladas. A etapa 5 começou de forma controlada: o Arquivo Abissal N-9 introduz implantes no catálogo normal ao nível 40; os packs seguintes aprofundam ciclicamente espaços universais, chegando à Universidade de Vilania por Correspondência com botas no nível 250 e à Agência de Deuses Reformados com luvas no nível 260. Gadget e relíquia permanecem nos dois setores maduros da Fenda Clandestina, com três recompensas únicas e universais por espaço. O catálogo normal mantém 1 820 combinações família/variante; novas séries são identificadas antes da decisão e consultadas por planeta sem construir o catálogo inteiro no mesmo frame. Drops normais para gadget/relíquia continuam bloqueados até navegação, comparação e identidade visual suportarem esse volume.
