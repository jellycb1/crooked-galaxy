# Crooked Galaxy — cronologia da Fenda no primeiro ano

Estado: modelo executável implementado em 29 de agosto de 2026.

## Regras incluídas

`tools/rift_year_one_chronology_model.gd` combina a curva real de XP, os quadros de três mandados, 100/160 combustível diário, níveis 8/100/160, conclusão sequencial, proteção de chave de 5/7 dias, uma tentativa gratuita da Fenda e até três repetições 1/5/20 após derrota. A Fenda nunca consome combustível e uma vitória termina o dia.

O modelo usa 55% por tentativa como baseline comparável dentro do envelope auditado das três classes. Não afirma que todos os inimigos ou builds terão essa chance. A ferramenta também imprime o limite perfeito e o limite em que a chave só surge no pity.

## Resultado

| Perfil | Nível D365 | Chance diária de vencer | Realidade 1 | Realidade 2 | Realidade 3 | Fichas esperadas de repetição |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Gratuito, mandado padrão | 120 | 55,0% | D23 | D254 | nível não alcançado | 0 |
| Gratuito, rota barata | 162 | 55,0% | D23 | D134 | D371 | 0 |
| 160 combustível, rota barata, 3 repetições | 200 | 95,9% | D13 | D82 | D224 | 123 |

Os 95,9% do terceiro perfil significam `1 − (1 − 0,55)^4`: quatro tentativas possíveis no mesmo inimigo, mas ainda apenas uma vitória e uma recompensa no dia. O gasto esperado pondera 1/5/20 somente quando todas as tentativas anteriores falham.

## Decisão de produto

As chaves e gates já transformam 36 inimigos em mais do que 36 dias de calendário. Para o gratuito padrão, a Fenda atual dura grande parte do primeiro ano; para a rota gratuita mais eficiente, a terceira realidade ainda está em curso no dia 365. O perfil máximo, porém, termina o conteúdo atual aproximadamente no dia 224. Restam cerca de 141 dias sem novo inimigo da Fenda.

Uma quarta realidade é justificável para retenção do perfil máximo, mas não deve abrir imediatamente após a terceira. O próximo desenho recomendado é uma realidade de doze inimigos com gate acima do nível 200 ou com uma condição transversal igualmente lenta, chave obtida apenas por gameplay e envelope calibrado depois de existirem checkpoints reais desse nível. Até isso ser autorado e testado, o jogo deve mostrar conclusão honesta, não repetir drops nem inventar inimigos procedurais.

## Limite visual

A obtenção da chave agora tem uma sequência funcional de estabilização do portal. Ela é um fallback code-native não produtivo. A entrega externa ainda necessária inclui chave de cada realidade, anéis/estrutura do portal, núcleo, distorção e estados fechado/aberto. Codex não criará nem modificará esses assets; um ficheiro fornecido só pode substituir o fallback depois do gate de assets e de pedido explícito de integração.
