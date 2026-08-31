# Crooked Galaxy — contrato de Operações semanais

Estado: primeira fundação executável, 28 de agosto de 2026.

O Circuito da Rede complementa este sistema sem alterar as três metas nem o Mandado Negro; o seu contrato ativo está em `NETWORK_CIRCUIT_CONTRACT_2026-08-29.md`.

## Ciclo

- A semana começa segunda-feira às 00:00 UTC.
- O APK atual usa o relógio local e declara essa limitação; o identificador do ciclo já é determinístico para futura autoridade de servidor.
- Uma virada de semana reinicia em conjunto progresso, pagamentos e Mandado Negro. Um contrato aceite preserva o seu snapshot; se terminar depois da virada, não consome o Mandado Negro da nova semana.

## Quadro semanal

- 8 contratos: 150 Créditos.
- 20 contratos: 15 Sucata.
- 35 contratos: 400 Créditos e 25 Sucata.
- Somente caçadas normais concluídas contam. Fenda, mercado, compras e outras ações premium não contam.
- Cada pagamento é explícito, resgatável uma vez e sanitizado no carregamento.

O perfil gratuito padrão atual completa aproximadamente 27 caçadas por semana (`3,9/dia` na auditoria anual); portanto, a meta final de 35 é deliberadamente um objetivo estratégico. Continua possível sem recarga premium quando o jogador escolhe rotas mais baratas durante a semana, mas não deve ser apresentada como automática nem como promessa do perfil que escolhe sempre o mandado padrão.

## Mandado Negro

- Um criminoso de elite é selecionado deterministicamente entre os planetas desbloqueados quando o ciclo é inicializado.
- O alvo permanece estável durante a semana, mesmo se o caçador subir de nível e desbloquear outro planeta.
- O contrato usa o briefing, abordagens, viagem, transporte, incidente, combate, loot e recompensa normais; não cria outro ciclo de combate.
- Consome o custo normal da rota-base, é ligeiramente mais resistente e paga Créditos, XP e 8 Sucata reforçados.
- Pode ser concluído e pago somente uma vez por ciclo. A ação de repetir contrato é ignorada neste tipo de mandado.
- Não usa Fichas de Dobra, não pode ser renovado e não revela antecipadamente o loot.

Os elites dos antigos capítulos fornecem a identidade inicial, mas o sistema não reativa a campanha linear nem os antigos bloqueios de planeta. Novos bosses e apresentações próprias podem ampliar a rotação depois, sem alterar o contrato de progressão.
