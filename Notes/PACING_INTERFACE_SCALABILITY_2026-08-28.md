# Crooked Galaxy — ritmo anual e escalabilidade de interfaces 0.47.0

Estado: implementação validada, 28 de agosto de 2026.

> Nota de continuidade: os números lineares de progressão abaixo documentam a decisão da versão 0.47.0. A curva quadrática ativa e o catálogo revisto estão em `XP_PACING_SIMULATION_2026-08-28.md` e `YEAR_ONE_CONTENT_CONTRACT.md`.

## Decisão de ritmo suportada por dados

Cinco caçadas por dia continuam a ser o perfil de referência, mas não são um limite mecânico. A nova auditoria executável simula 5, 10, 20 e 40 caçadas diárias usando ofertas padrão e nenhum transporte. O nível 30 exige 137 contratos e o nível 300 exige 1 813. Assim, o catálogo contratado de 33 planetas dura aproximadamente 363 dias para 5 caçadas/dia, 182 para 10, 91 para 20 e 46 para 40.

Isto transforma uma suposição numa decisão de produto explícita: antes de produzir a maioria dos 27 habitats ainda em falta, será necessário escolher entre reserva diária, retornos decrescentes, progressão aberta ou outro limite transparente. Este pacote não ativa combustível, não cria bloqueios artificiais e não liga ritmo a monetização.

## Interfaces preparadas para crescimento

- Mercado: as três ofertas continuam comparáveis numa faixa compacta, mas apenas o dossiê selecionado é materializado. A vista passou de 99 para 83 nós e mantém compra, confirmação e atualização no mesmo fluxo.
- Carreira: planetas e marcos deixaram de criar listas verticais ilimitadas. Cada secção apresenta uma página de cada vez, com navegação anterior/seguinte. A amostra atual passou de 193 para 106 nós; adicionar os 27 planetas contratados deixa de aumentar linearmente a árvore visível.
- Hangar: os quatro transportes aparecem como seletores compactos e apenas o transporte selecionado mostra o cartão detalhado e a ação contextual. A vista passou de 98 para 81 nós e abre diretamente no transporte equipado.

As medições foram feitas em arranques limpos a 450 × 800. O Mercado ficou na faixa aproximada de 29–33 ms a frio e 11–14 ms a quente; a Carreira, 26–30 ms; o Hangar, cerca de 13 ms. Os números servem para comparação interna, não como garantia de tempo por dispositivo.

## Limites preservados

O pacote não altera schema de save, atributos, classes, equipamento, combate, preços, refresh premium, tempos de missão nem conteúdo visual. Nenhum novo raster foi gerado ou integrado. A auditoria mantém as referências como instrumento de decisão, sem as exportar como arte de produção.

O gate completo passou em 53 suítes, incluindo traduções PT/EN, expansão de texto, touch, scroll, lifecycle, boot limpo e as 1 659 combinações da matriz de persistência. O tempo total foi 142,88 segundos; o aviso do armazenamento de certificados raiz do Windows permaneceu não fatal e externo ao projeto.

O APK ARM64 0.47.0/code 105 tem 32,12 MB e passou os gates de API 24+, assinatura estável de testes internos, sincronização de versão, conteúdo obrigatório e fronteira de referências. O artefacto publicado em `latest` tem SHA-256 `f1573671d05c4d4990aa582683913fd71b74f4c958106b8d41ccee6c231f5daa`.
