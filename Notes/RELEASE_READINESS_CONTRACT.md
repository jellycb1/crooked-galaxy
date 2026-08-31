# Crooked Galaxy — contrato de prontidão e slice de produção

Estado: contrato ativo. Define o significado de “completo” e o próximo marco de produto sem alterar as mecânicas, a economia ou o catálogo anual existentes.

## Estados canónicos

Os estados abaixo são independentes e nunca podem ser usados como sinónimos:

1. **Mecanicamente completo** — regras, conteúdo estruturado, persistência e testes existem, ainda que usem fallbacks visuais ou autoridade local.
2. **Visualmente completo** — todos os assets exigidos pelo âmbito passaram o gate visual e aparecem corretamente no contexto final; fallbacks temporários não contam.
3. **Validado em Android físico** — desempenho, touch, lifecycle, legibilidade, temperatura e armazenamento foram exercitados num dispositivo Android pessoal ou de tester sem restrições empresariais.
4. **Online em staging** — uma capacidade passou pelo ambiente público TLS com contas descartáveis e evidência operacional; isto não a torna disponível no APK normal.
5. **Online ativado** — o APK normal recebeu configuração de produção e a capability flag específica depois dos respetivos gates de segurança e migração.
6. **Pronto para lançamento** — o âmbito é mecanicamente e visualmente completo, validado em dispositivo, localizado, operacionalmente suportado e aprovado por playtest. Nenhum dos estados anteriores implica este automaticamente.

## Verdade atual

- O catálogo planeta–alvo até ao nível 320 e a Fenda de três realidades estão mecanicamente completos.
- O núcleo reutilizável de UI possui assets aprovados, mas a maior parte das personagens, destinos, inimigos, transportes e ícones de produção continua em fallback.
- PT/EN e o fluxo local de `International 1` estão completos; autenticação, economia remota, billing e Agências continuam desativados no APK normal.
- Staging público, TLS, backup off-host, restauro isolado e a transação remota de personagem/caçada estão provados.
- Android Studio fornece evidência de dispositivo virtual. O gate Android físico continua aberto.
- Consequentemente, Crooked Galaxy ainda não está visualmente completo nem pronto para lançamento.

## Primeiro slice de produção: níveis 1–30

Este é o próximo âmbito fechado. Não remove conteúdo posterior; apenas impede que a expansão esconda a qualidade insuficiente do primeiro mês.

O slice inclui:

- onboarding completo: idioma, `International 1`, login local, três classes, oito raças, aparência e nome;
- seis mundos: Dustball Prime, Congelária S.A., Micélia 404, Ferro-Velho Ômega, Cassino Quasar e Aerópolis de Penhora;
- vinte e quatro alvos, doze incidentes e respetivos ambientes de briefing, viagem e combate;
- os quatro transportes permanentes e a economia de combustível disponível nesta faixa;
- mandados, três abordagens, combate, recompensa, equipamento, Oficina, coleção, atributos, diários, Operações, Circuito e Mandado Negro;
- descoberta da Fenda no nível 8, cerimónia da primeira chave e os seis primeiros inimigos cujos checkpoints chegam ao nível 29;
- todas as superfícies necessárias para sair, regressar e continuar uma caçada em segundo plano;
- PT/EN completos e resistentes a expansão de texto no alvo físico 450×800.

## Gate visual do slice

- As três classes e as oito raças devem ter identidade final aprovada; a ficha do caçador mostra a personagem escolhida, equipamento e atributos.
- Os seis mundos, vinte e quatro alvos, quatro transportes e seis inimigos iniciais da Fenda não podem depender de emoji, silhueta genérica ou retrato procedural temporário.
- Controles code-native aprovados continuam válidos; não precisam de raster apenas para aumentar a contagem de assets.
- Cada família visual passa individualmente por `ASSET_GENERATION_RULES.md`, pela matriz de capturas e por inspeção a 450×800.
- A auditoria visual deve distinguir o slice 1–30 do catálogo anual completo para que o progresso imediato seja mensurável.

O gate executável é `tools/audit_release_readiness.gd`. A sua lista fechada contém 151 entregas visuais finais: 3 classes, 96 unidades do kit modular das 8 raças, 24 alvos, 18 entregas planetárias, 4 transportes e 6 inimigos da Fenda. Assets runtime já aprovados e controles code-native não inflam esta contagem nem bloqueiam o slice por ausência de substituto raster.

## Gate de experiência e dispositivo

Antes de expandir o âmbito ou ativar economia online:

- completar o onboarding, uma caçada, um incidente, uma derrota/vitória e uma recompensa num Android físico;
- confirmar scroll por dedo, áreas de toque, Back, suspensão, fecho, reabertura e continuação por timestamp;
- observar tempos de resposta, memória, temperatura, consumo e armazenamento sem bloqueios perceptíveis;
- executar pelo menos um percurso de sete dias com save persistente e relógio real;
- recolher feedback explícito sobre clareza da próxima ação, vontade de aceitar outro mandado, valor do loot e compreensão do combustível;
- registar falhas e evidência sem incluir saves, chaves, tokens ou dados pessoais no Git.

As curvas atuais permanecem hipóteses protegidas por simulação até existir esta evidência. Telemetria de produção não é necessária para o slice interno, mas alterações de XP, preços ou limites não devem ser justificadas apenas por preferência quando a simulação e o playtest podem responder.

## Trabalho congelado até ao gate

- novos planetas acima do nível 320, quarta realidade da Fenda, Arena, ranking, Consórcios e novos sistemas horizontais;
- ativação normal de conta/economia remota, billing ou Agências;
- expansão de raridades ou drops normais de gadget/relíquia;
- produção indiscriminada dos assets tardios antes das identidades necessárias ao slice.

Correções, testes, desempenho, acessibilidade, ferramentas de conteúdo, integração de assets aprovados e trabalho operacional que reduz risco do slice continuam autorizados.

## Ordem depois do slice

1. Corrigir os problemas encontrados no percurso físico de sete dias.
2. Validar conta, perfil e cutover no Android físico contra staging, mantendo economia local no APK normal.
3. Expandir a cobertura visual por faixas de mundo já mecanicamente implementadas.
4. Só então decidir, com evidência, alterações à curva anual, metas semanais, preços e cadência de conteúdo.
5. Ativar economia remota antes de billing; Agências e Arena permanecem fases posteriores.
