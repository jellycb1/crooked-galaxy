# Crooked Galaxy — polimento, desempenho e qualidade de vida 0.46.0

Estado: implementação validada localmente, 28 de agosto de 2026.

## Diagnóstico medido

Antes deste batch, o primeiro render do Arquivo de Procurados construía os 24 alvos implementados simultaneamente: 262 nós e aproximadamente 21,5 ms no benchmark desktop headless. Esse modelo cresceria para centenas de nós com os 132 alvos exigidos pelo contrato do primeiro ano. O Mercado recriava o mesmo stock determinístico em todos os renders, e o fluxo de descoberta podia abrir a Galáxia no topo, deixando um planeta tardio fora do enquadramento Android.

## Alterações

- O Arquivo mantém todos os registos, mas materializa apenas os quatro alvos do planeta selecionado. O planeta atual continua a ser a primeira página e controlos de 48 unidades permitem navegar pelas restantes.
- O render do Arquivo passou para 109 nós e aproximadamente 8,1 ms: menos 58% de nós e cerca de 62% de tempo síncrono na medição comparável.
- O stock do Mercado recebe uma cache por planeta, nível, dia, ciclo e compras. Cada consumidor recebe uma cópia profunda, impedindo que UI ou testes contaminem o stock canónico.
- Destinos não confirmados produzem badge e rótulo `NOVO`/`NEW` no dock principal.
- A recompensa e o botão do Quadro abrem a Galáxia diretamente no cartão recém-descoberto. O scroll é restaurado após confirmar o destino e ao regressar à tela durante a mesma sessão.
- O reset de desenvolvimento limpa também página do Arquivo, posição e foco da Galáxia, evitando estado transitório entre perfis.

## Limites preservados

O batch não altera combate, economia, probabilidades, duração de missões, disponibilidade de planetas, conteúdo, monetização ou arte. Nenhum raster foi criado ou integrado. `seen_planet_ids` continua sendo apenas estado de apresentação; o nível permanece a única autoridade de desbloqueio.

## Validação

As 50 suítes completas, incluindo a matriz de 1.659 combinações de persistência, PT/EN, expansão de texto, foco, touch, scroll, lifecycle e boot limpo, passaram em 141,78 segundos. O APK ARM64 0.46.0/code 104 passou os gates de API 24+, assinatura de teste estável, conteúdo obrigatório e fronteira de referências.
