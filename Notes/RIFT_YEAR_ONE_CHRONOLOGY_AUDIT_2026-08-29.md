# Crooked Galaxy — cronologia da Fenda no primeiro ano

Estado: modelo executável implementado em 29 de agosto de 2026.

## Regras incluídas

`tools/rift_year_one_chronology_model.gd` combina a curva real de XP, os quadros de três mandados, 100/160 combustível diário, conclusão sequencial, proteção de chave de 5/7 dias, uma tentativa gratuita da Fenda e até três repetições 1/5/20 após derrota. A Fenda nunca consome combustível e uma vitória termina o dia.

Cada inimigo respeita também o checkpoint para o qual o seu envelope foi calibrado: 8–90 na primeira realidade, 100–155 na segunda e 160–215 na terceira, em passos de cinco nas duas escadas avançadas. O nível não é uma segunda chave rígida no runtime; é o ponto em que a projeção pode aplicar honestamente a chance baseline. Antes dele, a chance real mostrada pela build pode ser muito inferior.

O modelo usa 55% por tentativa como baseline comparável dentro do envelope auditado das três classes. Não afirma que todos os inimigos ou builds terão essa chance. A ferramenta também imprime o limite perfeito e o limite em que a chave só surge no pity.

## Resultado

| Perfil | Nível D365 | Chance diária de vencer | Realidade 1 | Realidade 2 | Realidade 3 | Fichas esperadas de repetição |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Gratuito, mandado padrão | 120 | 55,0% | D182 | 5/12 acessíveis | nível 160 não alcançado | 0 |
| Gratuito, rota barata | 162 | 55,0% | D90 | D323 | 1/12 acessível | 0 |
| 160 combustível, rota barata, 3 repetições | 200 | 95,9% | D55 | D194 | 9/12 acessíveis | 113 |

Os 95,9% do terceiro perfil significam `1 − (1 − 0,55)^4`: quatro tentativas possíveis no mesmo inimigo, mas ainda apenas uma vitória e uma recompensa no dia. O gasto esperado pondera 1/5/20 somente quando todas as tentativas anteriores falham.

## Decisão de produto

As chaves, gates e checkpoints já transformam 36 inimigos em mais do que 36 dias de calendário. O gratuito padrão entra no segundo conjunto mas termina o ano por volta do quinto inimigo. A rota gratuita eficiente conclui a segunda perto do dia 323 e abre somente o primeiro inimigo da terceira. O perfil máximo chega ao nível 200 no dia 364 e deixa intactos os inimigos calibrados para 205, 210 e 215.

Conclusão corrigida: não existe a lacuna de 141 dias indicada pela primeira versão do modelo, que aplicava 55% desde a abertura de cada chave e ignorava os checkpoints internos. Uma quarta realidade não é necessária para cumprir o primeiro ano na curva atual. Deve permanecer congelada até existir uma projeção de segundo ano e builds reais acima do nível 215. O jogo mostra agora o nível recomendado do inimigo atual junto da chance calculada, sem antecipar inimigos ou drops futuros.

## Limite visual

A obtenção da chave agora tem uma sequência funcional de estabilização do portal. Ela é um fallback code-native não produtivo. A entrega externa ainda necessária inclui chave de cada realidade, anéis/estrutura do portal, núcleo, distorção e estados fechado/aberto. Codex não criará nem modificará esses assets; um ficheiro fornecido só pode substituir o fallback depois do gate de assets e de pedido explícito de integração.
