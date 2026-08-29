# Crooked Galaxy — inventário completo de assets para UI

Estado: inventário mestre para planeamento e produção visual.

Data da auditoria: 28 de agosto de 2026.

Objetivo: identificar tudo o que a interface precisa para deixar de depender de símbolos provisórios, sem transformar milhares de combinações de personagem e equipamento em milhares de ficheiros desenhados manualmente.

Este documento cobre:

- toda a UI atualmente navegável;
- estados de sistema necessários para lançamento;
- criação de personagem, classes e raças;
- caçadas, combate, recompensas e Fenda;
- equipamento procedural e coleção;
- monetização sem anúncios e sem passe de temporada;
- escala de conteúdo para 365 dias;
- especificações, reutilização e ordem de produção.

---

## 1. Legenda de estado

| Código | Significado |
| --- | --- |
| `PROD` | Asset original já integrado e utilizável em produção. |
| `CODE` | Desenhado atualmente por Godot; funcional e escalável, mas pode receber revisão artística. |
| `TEMP` | Solução provisória que comunica a função mas não representa arte final. |
| `FALTA` | Asset ainda não existe. |
| `GATE` | Asset fornecido pelo utilizador/artista; precisa passar por `Notes/ASSET_GENERATION_RULES.md` e por pedido explícito de integração. |
| `REUSO` | Não deve ganhar um ficheiro exclusivo; reutiliza outro asset ou um sistema modular. |

## 2. Regras de produção para toda a UI

1. Nenhuma imagem deve conter texto. Todo texto permanece nativo no Godot para suportar tradução, tamanho de fonte e acessibilidade.
2. O alvo de validação é Android a 450×800. Assets devem ser julgados no tamanho real em que aparecem, não apenas abertos em resolução total.
3. A UI usa uma única identidade: navy profundo, aço azul, latão envelhecido, cyan tecnológico, dourado para identidade/recompensa, lime para confirmação e coral para perigo.
4. Ilustrações são desenhadas à mão, caricaturais, assimétricas e legíveis. Evitar concept art militar, acabamento 3D, microtextura e brilho genérico.
5. Um ecrã tem um único sujeito visual dominante. Listas e informação repetida continuam simples.
6. Fundos, retratos, equipamento, molduras e efeitos são camadas separadas. Isto permite reutilização, tradução, animação e atualização sem redesenhar o ecrã inteiro.
7. Personagens, alvos e itens importantes usam fundo transparente.
8. O projeto não deve pré-renderizar todas as combinações cosméticas. Raças, aparência e equipamento precisam de composição modular.
9. O código continua responsável por barras, texto, números, scroll, foco, botões, seleção, estados desativados e disposição responsiva.
10. Todo raster novo é rascunho rejeitado por padrão até aprovação visual explícita.

---

## 3. Assets de produção que já existem

| Asset | Função atual | Estado | Decisão |
| --- | --- | --- | --- |
| `assets/ui/panel_frame_space.png` | Moldura 9-slice para dossier focal | `PROD` | Manter. É a principal âncora material da UI. |
| `assets/backgrounds/bounty_office.png` | Quadro, briefing, viagem e recompensa | `PROD` | Manter como fundo genérico de contratos; não deve substituir habitats planetários. |
| `assets/backgrounds/frontier_spaceport.png` | Galáxia, carreira e criação | `PROD` | Manter como hub e fallback. |
| `assets/backgrounds/arsenal_workshop.png` | Arsenal, mercado e hangar | `PROD` | Manter como oficina genérica. |
| `assets/backgrounds/frontier_arena.png` | Combate, vitória e Fenda | `PROD` | Manter como arena genérica/fallback. |
| `assets/boot_splash.png` | Splash de arranque | `PROD` | Manter até existir uma ilustração de marca final aprovada. |
| `assets/icon.svg` | Ícone base da aplicação | `CODE/TEMP` | Precisa de revisão final para loja e dispositivos. |

Os antigos retratos de classe foram rejeitados e não fazem parte deste inventário como assets válidos. O respetivo rascunho local foi removido; a decisão permanece documentada no histórico Git e em `ORIGINAL_VISUAL_ASSETS.md`.

---

## 4. Kit universal da interface

Este kit deve ser concluído antes de desenhar ecrãs isolados. Ele evita que cada área pareça pertencer a um jogo diferente.

### 4.1 Superfícies e molduras

| Unidade | Quantidade | Estado | Formato recomendado |
| --- | ---: | --- | --- |
| Moldura de dossier focal | 1 | `PROD` | PNG RGBA 9-slice; já existe. |
| Painel de suporte simples | 1 sistema | `CODE` | `StyleBoxFlat`; não rasterizar. |
| Painel de alerta/perigo | 1 sistema | `CODE` | Variação semanticamente coral. |
| Painel de sucesso/recibo | 1 sistema | `CODE` | Variação semanticamente lime/cyan. |
| Moldura de item por raridade | 4 estados | `TEMP` | Preferir 9-slice/vector ou shader: comum, raro, épico e futuro especial. |
| Moldura de retrato | 4 estados | `CODE/TEMP` | Normal, selecionado, bloqueado e chefe. |
| Separador material | 3 variantes | `CODE` | Curto, médio e ornamental focal. |
| Tooltip/sheet secundária | 1 sistema | `CODE` | Sem raster obrigatório. |
| Modal de confirmação | 1 sistema | `CODE` | Reutiliza painel de suporte e scrim. |
| Scrim de legibilidade | 3 intensidades | `CODE` | Fundo, modal e combate. |

### 4.2 Botões e controlos

Continuar code-native para garantir tradução, toque e estados. Precisamos definir visualmente:

- ação primária;
- ação secundária;
- ação destrutiva;
- botão premium;
- selecionado;
- bloqueado;
- desativado;
- pressionado;
- foco de teclado/comando;
- checkbox;
- seletor anterior/seguinte;
- slider;
- dropdown;
- tabs;
- scrollbar e indicador de arrasto;
- botão voltar;
- fechar modal;
- informação/detalhes.

Estado atual: `CODE`. Nenhum deles precisa de uma imagem raster exclusiva.

### 4.3 Ícones globais de recursos e estado

| Ícone | Quantidade | Estado | Uso |
| --- | ---: | --- | --- |
| Créditos | 1 | `TEMP` | Cabeçalho, mercado, recompensa e recibos. |
| Fichas de Dobra | 1 | `TEMP` | Moeda premium (`Warp Chips` em inglês) e confirmações. |
| Combustível | 1 | `TEMP` | Quadro, briefing, recarga e retorno diário. |
| Sucata | 1 | `TEMP` | Arsenal, reciclagem e melhorias. |
| XP | 1 | `TEMP` | Recompensas, nível e progressão. |
| Nível | 1 | `TEMP` | Perfil e desbloqueios. |
| Poder | 1 | `TEMP` | Comparação de personagem, item e alvo. |
| Saúde | 1 | `TEMP` | Combate, Vitalidade e comparação. |
| Chave da Fenda | 1 | `TEMP` | Realidades, desbloqueio e recompensa. |
| Tempo/relógio | 1 | `TEMP` | Viagem, missão ativa e reinício diário. |
| Cadeado | 1 | `TEMP` | Conteúdo bloqueado. |
| Novo/notificação | 1 | `CODE/TEMP` | Badges de navegação. |
| Compra concluída | 1 | `FALTA` | Recibos e restauração de compra. |
| Erro/indisponível | 1 | `FALTA` | Rede, compra, save e manutenção. |
| Ligação/servidor | 1 | `FALTA` | Login e estado de servidor. |
| Globo/idioma | 1 | `FALTA` | Seleção de idioma; não usar bandeiras. |

Entrega recomendada: uma folha vetorial única com 16 símbolos e regras consistentes de linha. Estes ícones não devem ser pinturas raster individuais.

### 4.4 Navegação principal

Cinco destinos persistentes:

1. Mandados;
2. Arsenal;
3. Caçador;
4. Galáxia;
5. Menu.

Estado atual: `CODE`, através de `hub_destination_icon.gd`.

Necessidades:

- 5 ícones finais coerentes;
- estado normal;
- ativo;
- pressionado;
- bloqueado quando aplicável;
- badge de novidade/contagem;
- fundo estrutural do dock, já resolvido por código e latão/aço.

Não criar 25 bitmaps. Um ícone vetorial por destino deve receber cor e estados pelo Godot.

---

## 5. Entrada, conta e criação de personagem

### 5.1 Ecrãs obrigatórios

| Ecrã/estado | Assets dominantes | Estado atual |
| --- | --- | --- |
| Splash e carregamento | Marca, fundo, indicador | Parcial `PROD` |
| Login | Fundo/hub, símbolo de conta/servidor | UI existe; arte específica `FALTA` |
| Seleção de servidor | Emblema do servidor, população, estado | Contrato existe; arte `FALTA` |
| Internacional 1 | Emblema neutro internacional | `FALTA` |
| Seleção de idioma | Globo + nomes nativos dos idiomas | UI parcial; ícone `FALTA` |
| Escolha obrigatória de classe | 3 ilustrações promocionais | UI existe; arte `GATE` |
| Escolha de raça | 8 bustos modulares | UI existe; arte `GATE` |
| Aparência | Preview modular e controlos | UI existe; arte `GATE` |
| Nome | Preview final do caçador | UI existe; arte `GATE` |
| Confirmação de personagem | Retrato final e resumo | `FALTA` |
| Reconexão | Símbolo de ligação e spinner | `FALTA` |
| Manutenção | Ilustração pequena/prop cómico | `FALTA` |
| Versão incompatível | Ícone de atualização | `FALTA` |
| Recuperação de conta/save | Ícone seguro e estados | UI de save parcial; arte `FALTA` |
| Termos e privacidade | Sem arte especial | `CODE` |

### 5.2 Classes

Precisamos de exatamente três ilustrações promocionais iniciais:

- Quebra-Mandados;
- Pistoleiro Orbital;
- Hacker de Contratos.

Cada ilustração:

- personagem inteira, vertical, RGBA;
- representante de uma raça, sem limitar a classe a essa raça;
- rosto expressivo;
- silhueta e ferramenta principal legíveis a 120 px;
- máximo recomendado de 1024 px no maior lado importado;
- uma pose neutra de seleção; não criar várias emoções nesta fase.

Estado: `GATE`, 0/3 aprovadas.

Os três emblemas procedurais atuais continuam como fallback até aprovação.

### 5.3 Raças e personalização modular

As oito raças são:

1. Terrano;
2. Sintético;
3. Astrerrante;
4. Fungoide;
5. Abissal;
6. Mothari;
7. Raiz-de-Sucata;
8. Luz-Defeituosa.

O sistema possui quatro categorias, cada uma com três opções: paleta, olhos, característica e marcação. Isso produz 81 combinações por raça e 648 combinações totais antes do equipamento.

Não criar 648 retratos acabados. Criar por raça:

| Camada por raça | Quantidade |
| --- | ---: |
| Base anatómica/linha principal | 1 |
| Máscara de cor/material | 1 |
| Olhos | 3 |
| Característica principal | 3 |
| Marcação | 3 |
| Máscara de oclusão para equipamento | 1 |
| Silhueta/miniatura de seleção | 1 derivada |

Total recomendado: 12 unidades de autoria por raça, sendo algumas exportações derivadas; aproximadamente 96 unidades para as oito raças, em vez de 648 retratos completos.

As três paletas devem ser aplicadas por shader ou máscaras de cor, não por três pinturas completas.

Estado: renderer procedural funcional, arte final `GATE`, 0/8 bases aprovadas.

---

## 6. Quadro de Mandados e ciclo de caçada

### 6.1 Quadro de três ofertas

Assets necessários:

- retrato do alvo selecionado;
- miniatura dos outros dois alvos;
- ícone/medalhão do planeta;
- fundo do habitat do planeta selecionado;
- três níveis visuais de pressão: segura, padrão e perigosa;
- combustível;
- tempo de viagem;
- créditos;
- XP;
- poder relativo;
- indicador de chefe;
- indicador de novo planeta;
- indicador de alvo já arquivado;
- botão de detalhes;
- dossier selecionado.

Reutilização: o mesmo retrato de alvo aparece no quadro, briefing, combate, vitória, recompensa, Mandados Procurados e operações semanais.

### 6.2 Briefing e três abordagens

Três ícones de abordagem:

- pressão corporativa/premium;
- entrada rápida;
- rede silenciosa.

Necessidades adicionais:

- rota selecionada;
- modificador positivo;
- modificador negativo;
- afinidade de classe;
- custo de combustível;
- duração com e sem transporte;
- confirmação de partida;
- insuficiência de combustível;
- recarga premium de combustível;
- missão já ativa.

Estado: funcional por código; ícones finais `FALTA`.

### 6.3 Missão ativa em segundo plano

O jogador pode navegar ou fechar o jogo durante uma caçada. Portanto precisamos de:

- chip compacto de missão ativa no cabeçalho;
- miniatura do alvo;
- contador regressivo;
- destino;
- estado viajando;
- estado incidente disponível;
- estado combate pronto;
- estado resultado pronto;
- notificação local do Android;
- resumo de retorno AFK.

Todos são componentes pequenos e reutilizam o retrato do alvo e ícones globais.

### 6.4 Incidentes de viagem

Conteúdo atual: 42 incidentes, dois por cada um dos vinte e um planetas de gameplay. Cada incidente contém três opções/ícones de escolha no código.

Produção recomendada por incidente:

- 1 ilustração focal simples de prop/criatura/situação;
- 3 pictogramas de escolha podem reutilizar uma biblioteca comum;
- 1 variação visual para resultado positivo/negativo feita por cor e efeitos, não por nova pintura.

Meta de lançamento: 70 incidentes se mantivermos dois por cada um dos 35 planetas. Faltam 36 identidades de incidente para o catálogo anual.

Para controlar custo, criar primeiro 12 pictogramas universais de decisão: atacar, negociar, hackear, fugir, investigar, reparar, arriscar, pagar, ajudar, roubar, esperar e improvisar.

---

## 7. Planetas, habitats e galáxia

### 7.1 Escala definida

| Conteúdo | Atual | Meta de lançamento | Falta |
| --- | ---: | ---: | ---: |
| Planetas | 17 | 35 | 18 |
| Alvos | 68 | 140 | 72 |
| Alvos por planeta | 4 | 4 | — |
| Incidentes | 34 | 70 recomendados | 36 |

Planetas atuais:

- Dustball Prime;
- Congelária S.A.;
- Micélia 404;
- Ferro-Velho Ômega;
- Cassino Quasar;
- Aerópolis de Penhora;
- Arquivo Abissal N-9;
- Verdântia Patenteada (assets pendentes do utilizador);
- Caldeira de Garantia (assets pendentes do utilizador);
- Condomínio Lunar 7 (assets pendentes do utilizador);
- Necrópole Solar Umbral (assets pendentes do utilizador);
- Central de Tempestades 24h (assets pendentes do utilizador).
- Museu do Amanhã Obsoleto (assets pendentes do utilizador).
- Biblioteca do Silêncio Taxado (assets pendentes do utilizador).
- Resort do Horizonte de Eventos (assets pendentes do utilizador).
- Tribunal de Clones Não Autorizados (assets pendentes do utilizador).
- Mosteiro da Gravidade Reversa (assets pendentes do utilizador).

### 7.2 Pacote visual mínimo por planeta

Cada planeta precisa de:

1. fundo/habitat principal 9:16;
2. medalhão/ícone de planeta;
3. paleta semântica;
4. silhueta no mapa;
5. camada de arena/solo de combate ou variante do habitat;
6. quatro retratos de alvo;
7. pelo menos dois elementos de incidente;
8. linguagem material para equipamento;
9. selo de desbloqueio;
10. estado bloqueado e estado novo, produzidos por código.

Recomendação: uma pintura principal por planeta deve servir no quadro, briefing e carreira por recorte e scrim. O combate usa uma camada de chão/arena transparente combinada com o mesmo habitat. Assim evitamos desenhar dois fundos completos por planeta.

Produção anual mínima:

- 35 fundos de habitat;
- 35 camadas de arena;
- 35 medalhões;
- 140 retratos de alvo;
- 70 ilustrações simples de incidente.

Os quatro fundos atuais são ambientes genéricos e não contam como substituição das 35 identidades planetárias; permanecem como hubs e fallbacks.

### 7.3 Mapa galáctico

Necessidades:

- fundo estrelado discreto, já procedural;
- 35 nós planetários reutilizando medalhões;
- rota normal;
- rota selecionada;
- planeta bloqueado;
- planeta novo;
- planeta atual;
- planeta completo;
- recompensa pendente;
- marcador de missão ativa;
- efeito de desbloqueio.

Não desenhar um mapa raster fechado. As rotas e posições devem continuar em código para suportar a expansão.

---

## 8. Alvos, combate e resultados

### 8.1 Retratos de alvo

Formato recomendado:

- busto ou três quartos com fundo transparente;
- rosto/expressão dominante;
- uma prop que comunique a piada e profissão;
- leitura a 96–160 px;
- máximo importado de 1024 px;
- sem moldura embutida;
- uma única pose canónica reutilizada em todas as interfaces.

Quantidade:

- atual: 40 identidades precisam de arte;
- lançamento anual: 140;
- estado aprovado atual: 0/140 arte final; símbolos/emoji são `TEMP`.

Não criar versões separadas para quadro, combate e arquivo. Variantes de dano, chefe, selecionado e derrotado devem ser overlays de UI.

### 8.2 Combate automático

Assets necessários:

- composição do caçador modular;
- retrato/figura do alvo;
- arena do planeta;
- barras de vida;
- marcador de turno;
- impacto normal;
- impacto crítico;
- esquiva;
- bloqueio/redução;
- disparo;
- ataque pesado;
- hack/abertura;
- contra-ataque;
- derrota;
- vitória;
- efeitos de estado e anomalia;
- opção de movimento reduzido.

Recomendação: efeitos em shader, partículas e spritesheets pequenos. Não criar uma animação completa exclusiva por alvo no primeiro lançamento.

Kit VFX mínimo: 12 efeitos reutilizáveis, com cor e intensidade parametrizadas.

### 8.3 Vitória, derrota e recompensa

Reutilizar retrato de alvo, caçador, fundo e ícones. Assets exclusivos necessários:

- selo de captura/vitória;
- selo de derrota;
- caixa/revelação de loot;
- brilho comum, raro e épico;
- novo item;
- melhoria;
- item inferior;
- nova série de coleção;
- reciclagem;
- subida de nível;
- novo planeta;
- nova classe/sistema quando aplicável;
- retorno ao quadro;
- recuperação na oficina.

Uma folha com 10 selos/efeitos pequenos é suficiente; não criar dez ilustrações completas.

---

## 9. Caçador, atributos e classes

### 9.1 Ficha do caçador

O ecrã deve mostrar:

- retrato modular grande;
- nome;
- nível e XP;
- raça;
- classe;
- poder;
- nove espaços de equipamento;
- cinco atributos;
- pontos disponíveis;
- moeda e recursos relevantes;
- acesso a inventário e classes.

Assets:

- moldura de retrato;
- base modular das oito raças;
- cinco ícones de atributo;
- nove ícones de slot;
- três emblemas de classe;
- indicadores equipar, comparar, melhorar e remover;
- silhueta vazia por slot.

### 9.2 Cinco atributos

1. Força;
2. Vitalidade;
3. Destreza;
4. Inteligência;
5. Astúcia.

Estado atual: desenhados por `attribute_icon.gd`, `CODE/TEMP`.

Entrega artística: cinco símbolos vetoriais simples, reconhecíveis sem texto e compatíveis com as cores da UI.

### 9.3 Classes dentro do jogo

Reutilizar:

- 3 ilustrações promocionais da criação;
- 3 emblemas;
- 5 ícones de atributo;
- retrato modular do jogador.

Estados adicionais feitos por código:

- classe atual;
- troca gratuita inicial;
- troca paga futura, se aprovada;
- sinergia de rota;
- poder/especialização;
- comparação.

---

## 10. Equipamento, inventário e coleção

### 10.1 Nove slots universais

1. Arma;
2. Capacete;
3. Traje;
4. Luvas;
5. Botas;
6. Cinto técnico;
7. Implante;
8. Gadget;
9. Relíquia.

Os slots são iguais para todas as classes e raças presentes e futuras.

### 10.2 O que não fazer

Não desenhar um PNG acabado para cada item. O sistema pretende milhares de combinações com pequenas mudanças de nível, origem, raridade e modificador. Um catálogo totalmente plano multiplicaria custo, memória e tamanho do APK.

### 10.3 Kit modular recomendado de itens

| Unidade | Quantidade de autoria inicial |
| --- | ---: |
| Silhuetas base, 4 por cada um dos 9 slots | 36 |
| Componentes/attachments, 5 por slot | 45 |
| Máscaras de material/cor, 1 por slot | 9 |
| Packs de identidade planetária, 3 detalhes por planeta | 105 para 35 planetas |
| Símbolos de atributo | 5 reutilizados |
| Símbolos de modificador/trait | 9–18 |
| Molduras de raridade | 4 |
| Estado bloqueado, equipado, favorito, novo e melhoria | overlays `CODE` |

Uma composição pode combinar:

`silhueta do slot + detalhe do planeta + attachment + paleta + raridade + trait + nível`.

Isto produz milhares de itens visualmente relacionados sem milhares de pinturas únicas.

### 10.4 Equipamento visível no retrato

Slots visualmente prioritários:

- arma;
- capacete;
- traje;
- luvas;
- botas.

Cinto, gadget e relíquia podem aparecer como pequenos pontos de ancoragem. Implante pode alterar o rosto/efeito sem redesenhar a anatomia.

Para evitar multiplicar cada item por oito raças:

- normalizar pontos de ancoragem;
- usar máscaras de oclusão por raça;
- permitir pequena transformação de posição/escala por espécie;
- desenhar primeiro bustos, não personagem inteira modular;
- usar uma versão reduzida/ícone do item quando o encaixe corporal não for relevante.

### 10.5 Arsenal e oficina

Assets adicionais:

- bancada/oficina já coberta pelo fundo `arsenal_workshop.png`;
- martelo/calibração de poder;
- integridade/reforço;
- reciclagem;
- favorito/protegido;
- equipar;
- remover;
- comparar;
- loadout A/B;
- filtros dos nove slots;
- ordenação;
- paginação;
- recibo de custo;
- sucesso e erro de melhoria.

Todos são ícones ou estados compactos. Não precisam de ilustração grande.

---

## 11. Hangar e transportes

Transportes atuais:

1. Lata Voadora Homologada;
2. Táxi Warp Clonado;
3. Interceptor de Penhora;
4. Iate de Fuga Executiva.

Cada transporte precisa de:

- ilustração lateral ou três quartos, fundo transparente;
- miniatura derivada;
- silhueta bloqueada;
- estado possuído;
- estado ativo;
- rasto/efeito de viagem reutilizável;
- emblema de velocidade;
- leitura a aproximadamente 120–220 px.

Quantidade: 4 ilustrações principais iniciais. Estado atual: símbolos procedurais `TEMP`; arte final `GATE`, 0/4.

Não criar uma imagem diferente para briefing e caça. Reutilizar a mesma nave e aplicar movimento/escala no Godot.

Assets de hangar adicionais:

- mecânico/NPC opcional;
- plataforma/sombra de nave;
- comprar;
- selecionar;
- ativo;
- nível exigido;
- poupança de tempo;
- comparação;
- objetivo de poupança no mercado.

---

## 12. Mercado e monetização

A direção definida não usa anúncios nem passe de temporada. A monetização concentra-se em Fichas de Dobra para conveniência limitada, como renovações escaladas do mercado e combustível adicional.

### 12.1 Mercado de itens

Reutiliza:

- ícones procedurais/modulares de equipamento;
- fundo da oficina;
- créditos;
- Fichas de Dobra;
- raridade;
- comparação;
- coleção;
- transporte seguinte.

Assets específicos:

- 3 slots de oferta;
- renovar ofertas;
- confirmação de custo 1/5/20;
- ofertas esgotadas;
- vendido;
- recibo;
- insuficiência de créditos;
- proteção contra compra acidental.

### 12.2 Loja premium necessária para lançamento

Ainda precisamos inventariar e posteriormente implementar:

- entrada da loja de Fichas de Dobra;
- pacotes de fichas;
- preço local da plataforma;
- destaque de valor sem alegações enganosas;
- confirmação de compra;
- compra em processamento;
- compra concluída;
- compra cancelada;
- compra falhou;
- restaurar compras quando aplicável;
- saldo atualizado;
- histórico/apoio;
- indisponível offline;
- limite etário/consentimento conforme mercado;
- termos e política de privacidade.

Assets visuais:

- ícone final da Ficha Warp;
- 4–6 recipientes/pilhas de fichas, derivados de um único kit modular;
- selo de valor;
- recibo;
- erro de plataforma;
- ligação segura.

Não desenhar banners agressivos, temporizadores falsos ou pop-ups que interrompam o ciclo de jogo.

### 12.3 Combustível premium

Estados necessários:

- reserva diária;
- custo atual de missão;
- primeira ficha diária jogável;
- recarga +20;
- custo escalado 1/5/20;
- limite de três recargas;
- confirmação;
- reserva após compra;
- reinício às 00:00 UTC.

Reutiliza combustível, relógio e Ficha Warp. Não necessita de ilustração própria.

---

## 13. Fenda no espaço-tempo

### 13.1 Ecrãs

- Fenda bloqueada;
- Fenda desbloqueada;
- lista de realidades;
- realidade sem chave;
- chave encontrada;
- entrada diária disponível;
- entrada diária usada;
- inimigo atual;
- combate;
- derrota;
- vitória;
- setor completo;
- recompensa;
- próxima realidade.

### 13.2 Assets estruturais

| Asset | Quantidade atual | Estado |
| --- | ---: | --- |
| Portal/Fenda principal | 1 | `FALTA/GATE` |
| Moldura corrompida da Fenda | 1 | `FALTA` |
| Chave por realidade | 2 atuais | `FALTA` |
| Emblema por realidade | 2 atuais | `FALTA` |
| Fundo por realidade | 2 atuais | `FALTA/GATE` |
| Inimigos/andares | 24 identidades atuais | `TEMP`; arte `FALTA/GATE` |
| Recompensas especiais | 24 ícones/reutilização modular | `TEMP` |
| Perfis de anomalia | conjunto de símbolos | `CODE/TEMP` |

Realidades atuais:

- Alfândega do Universo Morto;
- Veredito do Tempo Congelado.

O jogador vê apenas o inimigo atual, não a tabela completa de drops. Portanto a UI não precisa de ilustrações antecipadas de recompensa por andar; ícones só aparecem quando a recompensa é obtida.

Produção recomendada: 24 retratos de inimigo podem usar o mesmo contrato técnico dos alvos normais, mas precisam de linguagem mais surreal. Não misturar estes 24 com os 140 alvos planetários na contagem.

---

## 14. Retenção, carreira e coleção

### 14.1 Objetivos diários

Assets:

- ícone diário;
- progresso;
- concluído;
- recompensa disponível;
- recompensa recolhida;
- reinício UTC;
- três famílias de objetivo reutilizáveis.

Estado: UI funcional; símbolos `CODE/TEMP`.

### 14.2 Operações semanais

Assets:

- emblema semanal;
- três patamares 8/20/35;
- Mandado Negro;
- alvo especial, reutilizado do catálogo;
- progresso;
- recompensa;
- semana concluída;
- rotação seguinte.

Estado: UI funcional; arte final `FALTA`.

### 14.3 Carreira e Mandados Procurados

Reutiliza planetas e retratos de alvo. Precisa de:

- linha de progressão;
- alvo normal/eliminei/chefe;
- planeta completo;
- recompensa de capítulo;
- arquivo bloqueado;
- série registada;
- percentagem de coleção;
- filtros por planeta, slot e raridade;
- selo de domínio/mastery.

Não criar miniaturas novas; usar os retratos e ícones de item existentes.

### 14.4 Retorno AFK

Assets:

- relógio/tempo ausente;
- missão que continuou;
- XP/créditos recebidos;
- resultado pendente;
- desbloqueios ocorridos;
- botão continuar.

Estado: ecrã existe; pode ser resolvido apenas com ícones globais.

---

## 15. Menu, definições e suporte

Ecrãs/ações necessários:

- perfil/conta;
- servidor Internacional 1;
- idioma;
- áudio;
- música;
- vibração;
- movimento reduzido;
- notificações;
- tamanho do texto quando suportado;
- acessibilidade/contraste;
- ajuda/tutorial;
- créditos;
- termos;
- privacidade;
- apoio;
- copiar ID de jogador;
- terminar sessão;
- eliminar conta com confirmação forte;
- versão do jogo;
- diagnóstico de ligação.

Ícones finais necessários: 14–18 símbolos vetoriais simples. Não usar ilustrações grandes ou molduras focais nesta área.

---

## 16. Estados de erro, segurança e recuperação

Estes assets são pequenos, mas obrigatórios para um jogo real:

- sem internet;
- servidor indisponível;
- manutenção;
- timeout;
- sessão expirada;
- autenticação falhou;
- nome inválido;
- nome ocupado;
- save corrompido recuperado;
- backup restaurado;
- espaço de armazenamento insuficiente;
- compra falhou;
- compra pendente;
- compra restaurada;
- versão desatualizada;
- conteúdo ainda a descarregar;
- ação não guardada;
- limite diário atingido;
- combustível insuficiente;
- inventário cheio;
- recurso insuficiente;
- confirmação destrutiva;
- servidor cheio/fechado quando existirem vários servidores.

Recomendação: uma biblioteca de 8 pictogramas semânticos — ligação, servidor, alerta, erro, segurança, armazenamento, compra e atualização — combinada com texto nativo. Não criar 23 ilustrações.

---

## 17. NPCs que dão identidade às interfaces

Para a UI parecer um mundo habitado, e não apenas um dashboard, recomendamos cinco personagens de serviço reutilizáveis:

1. escrivão/escrivã do Quadro de Mandados;
2. armeiro/mecânico do Arsenal;
3. comerciante do Mercado Torto;
4. mecânico/piloto do Hangar;
5. arquivista/guia da Fenda.

Cada NPC precisa inicialmente de apenas um busto canónico transparente. Emoções adicionais não são prioridade; expressões podem ser criadas depois com variantes faciais simples.

Estado: `FALTA/GATE`, 0/5.

---

## 18. Som e feedback não visual associados à UI

Embora este seja um inventário visual, cada família precisa de feedback correspondente:

- toque normal;
- seleção;
- confirmação;
- erro;
- moeda;
- compra;
- equipar;
- melhorar;
- reciclar;
- loot comum/raro/épico;
- nível;
- novo planeta;
- missão pronta;
- Fenda/chave;
- vitória;
- derrota.

Estado: gerador de som existe. A identidade sonora final deverá ser auditada juntamente com a arte para evitar uma UI visualmente artesanal com feedback eletrónico genérico.

---

## 19. Estados capturados e cobertura atual

O projeto gera mais de 100 capturas automatizadas a 450×800. Elas cobrem, entre outras:

- login, classe, raça, aparência e nome em PT/EN;
- quadro, escolhas, detalhes e destinos;
- briefing, caça, incidente e resultado;
- combate, vitória, derrota e recompensa;
- Caçador, atributos e classes;
- Arsenal equipado, oficina, inventário, filtros e páginas;
- Mercado e confirmações premium;
- Hangar e transporte ativo;
- Galáxia e planetas;
- carreira e Mandados Procurados;
- objetivos diários e semanais;
- Fenda, realidades, conclusão e recompensas;
- conclusão de capítulo;
- retorno AFK;
- recuperação de save;
- definições.

Estas capturas são a matriz de validação. Não representam 102 ilustrações diferentes. Um bom sistema reutiliza aproximadamente 20–30 famílias de componentes para cobrir todos esses estados.

---

## 20. Contagem consolidada de autoria

### 20.1 Primeira fase: identidade e vertical slice atual

| Família | Quantidade recomendada |
| --- | ---: |
| Ilustrações de classe | 3 |
| Bases modulares de raça e camadas | aproximadamente 96 unidades |
| Retratos dos 84 alvos atuais | 84 |
| Habitats dos 21 planetas atuais | 21 |
| Camadas de arena dos 21 planetas | 21 |
| Medalhões dos 21 planetas atuais | 21 |
| Incidentes atuais | 42 |
| Transportes | 4 |
| NPCs de serviço | 5 |
| Inimigos atuais da Fenda | 24 |
| Fundos/emblemas das duas realidades | 6–8 unidades |
| Ícones globais/nav/atributos/slots/ações | aproximadamente 50–65 vetores |
| Kit modular inicial de equipamento | 90 unidades base, antes dos packs planetários |
| Kit de VFX e selos | aproximadamente 22 |

### 20.2 Expansão para o catálogo de um ano

| Família | Meta total | Falta após conteúdo atual |
| --- | ---: | ---: |
| Habitats | 35 | 14 |
| Arenas/camadas de chão | 35 | 14 |
| Medalhões | 35 | 14 |
| Alvos | 140 | 56 |
| Incidentes | 70 | 28 |
| Packs materiais planetários para equipamento | 35 | 14 packs |

Fenda, eventos sazonais e futuros transportes ainda não têm uma meta anual fechada. Devem usar templates escaláveis e receber orçamento separado.

---

## 21. Ordem recomendada de produção

### Lote 0 — bloquear a linguagem visual

1. folha de ícones globais;
2. cinco ícones da navegação;
3. cinco atributos;
4. nove slots de equipamento;
5. um alvo atual como teste;
6. um planeta atual com habitat, medalhão e arena;
7. uma raça modular como teste;
8. uma classe promocional como teste.

Nada se expande antes de estes testes funcionarem juntos numa captura 450×800.

### Lote 1 — criação e Caçador

1. três classes;
2. oito bases raciais e sistema modular;
3. retrato equipado;
4. cinco atributos;
5. nove slots;
6. estados de seleção, bloqueio e confirmação.

### Lote 2 — ciclo central atual

1. vinte e um habitats e medalhões;
2. 84 alvos;
3. 42 incidentes;
4. vinte e uma arenas;
5. VFX de combate;
6. vitória, derrota e recompensa.

### Lote 3 — equipamento, economia e mobilidade

1. kit modular de itens;
2. packs visuais dos vinte e um planetas;
3. quatro transportes;
4. mercado e ícones premium;
5. recibos e estados de compra.

### Lote 4 — Fenda e retenção

1. portal;
2. duas realidades;
3. 24 inimigos;
4. chaves e recompensas;
5. objetivos, operações e arquivo.

### Lote 5 — lançamento e expansão anual

1. login/servidor/loja final;
2. estados de rede, compra e recuperação;
3. app icon e imagens de loja;
4. mais 26 planetas;
5. mais 104 alvos;
6. mais 52 incidentes;
7. packs materiais restantes.

---

## 22. Definição de “UI visualmente completa”

A interface só deve ser considerada completa quando:

- nenhum ecrã principal depende de emoji ou símbolo tipográfico como arte final;
- classes, raças, alvos, planetas, equipamento e transportes têm uma linguagem comum;
- toda a matriz automatizada permanece legível a 450×800;
- todas as imagens continuam funcionais em PT, EN e idiomas futuros;
- missão ativa, retorno AFK, rede, compra e recuperação têm estados claros;
- a loja premium parece parte do mundo, mas não domina a navegação;
- o inventário suporta milhares de combinações sem milhares de texturas residentes;
- novos planetas e alvos podem ser adicionados sem reconstruir a UI;
- todos os assets raster passaram pelo gate visual e pela validação Android;
- referências externas permanecem fora do APK e não são confundidas com produção original.

Este inventário deve ser atualizado sempre que um novo sistema, moeda, slot, realidade, tipo de missão ou família de ecrã for aprovado.
