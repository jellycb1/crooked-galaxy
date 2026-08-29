# Crooked Galaxy — contrato de monetização

Estado: direção aprovada e combustível implementado na simulação local. Os princípios e limites são fixos; valores numéricos continuam sujeitos a testes e telemetria.

## Princípios inegociáveis

- Free-to-play, sem anúncios, sem passe de temporada e sem subscrição obrigatória.
- Monetização vende tempo, escolhas adicionais e conveniência; nunca vende vitória direta.
- Não vender níveis, pontos de atributo, probabilidades de combate, classes superiores, espécies com bónus, equipamento exclusivo objetivamente superior ou rerolls após conhecer o resultado de um combate.
- Não usar loot boxes. Toda compra mostra exatamente o que entrega.
- Cosméticos podem ser complementares no futuro, mas não sustentam o modelo antes de existirem personagens modulares e locais onde outros jogadores os vejam.
- Compras reais, saldos premium e limites diários serão autoritativos no servidor. A implementação local atual é apenas uma simulação de produto para testes internos.

## Moedas

- **Créditos:** moeda normal de jogo. Compra equipamento apresentado no mercado, transportes permanentes e outros sistemas de progressão normal.
- **Sucata:** recurso de oficina, obtido sobretudo ao reciclar equipamento e dominar alvos.
- **Fichas de Dobra / Warp Chips:** moeda premium. Pode ser comprada e também obtida em quantidades controladas ao jogar.

O mercado nunca vende o item por Fichas de Dobra: a ficha compra uma nova seleção; o item continua a custar Créditos. Assim, a compra premium aumenta oportunidades sem prometer uma melhoria.

## Fontes gratuitas de Fichas de Dobra

- A primeira missão concluída em cada dia UTC concede 1 Ficha de Dobra.
- Marcos vitalícios da coleção de equipamento concedem quantidades pequenas e predeterminadas. No catálogo atual de 1 940 séries, a escada completa concede 37 Fichas no total; não reinicia e não depende de sorte paga.
- Os objetivos semanais atuais concedem apenas Créditos e Sucata. Eventos e compensações poderão conceder fichas mais tarde, sempre com fonte e limite explícitos.
- O jogo deve mostrar claramente a fonte, o limite e o momento do próximo reset.
- Objetivos diários normais não concedem Fichas: o turno inicial paga no máximo 85 Créditos e 8 Sucata por 1/3/5 caçadas normais, sem contar Fenda ou qualquer ação premium.
- Operações semanais não concedem Fichas: as metas 8/20/35 pagam no máximo 550 Créditos e 40 Sucata. O Mandado Negro usa combustível normal, não aceita renovação premium e só pode ser pago uma vez por semana.

## Escada de custos e limites

Dentro de cada sistema e dia UTC, os três usos premium custam **1, 5 e 20** Fichas de Dobra. O quarto uso é bloqueado. A escalada é sempre mostrada antes da confirmação e reinicia no próximo dia UTC.

Estado das aplicações:

1. **ATIVO — Mercado:** até três renovações por dia. A terceira seleção contém pelo menos um item Raro compatível, mas não garante que seja melhoria.
2. **ATIVO — Combustível de caça:** reserva diária de 100 unidades; missões normais consomem o equivalente aos minutos da rota-base. Cada recarga concede 20 e segue a escada diária 1/5/20. Faturação e autoridade continuam locais e não representam uma loja real.
3. **PLANEADO — Reduções de tempo:** Células de Salto poderão reduzir cinco minutos e deverão existir também como recompensa jogável, com limite diário. Ainda não fazem parte do cliente atual.
4. **FUTURO — Arena:** saltos de cooldown poderão usar a mesma escada, sempre limitados a três por dia e sem alterar probabilidades de vitória.

## Fenda: limite de integridade comercial

- A Fenda concede exatamente uma entrada global por dia UTC, partilhada por todas as realidades abertas. A entrada é consumida ao iniciar o combate, inclusive quando existe derrota.
- Não se vende entrada adicional, repetição após derrota, salto de inimigo, alteração do inimigo, chave, probabilidade de vitória nem revelação antecipada da recompensa.
- Cada realidade contém doze inimigos sequenciais e exige uma chave permanente. A primeira chave é descoberta ao atingir o nível 8; chaves seguintes entram apenas por caçadas normais depois de completar a realidade anterior e alcançar o nível exigido.
- O contador oculto de uma chave tem proteção contra azar e não aceita Fichas de Dobra. Na segunda realidade, a chave surge no máximo após cinco caçadas elegíveis.
- Antes da luta, o jogador vê somente o inimigo atual, as regras da anomalia e a promessa genérica de recompensa superior. Item, raridade, espaço, Créditos e XP permanecem selados até à vitória.
- A Fenda não consome combustível e não avança Turno Diário, reputação, domínio de alvos ou embalo dos mandados. Assim, funciona como compromisso diário de build e não como multiplicador pago da progressão normal.

## Transportes e conveniência

- Transportes de 10%, 20% e 30% continuam compráveis permanentemente com Créditos.
- Transportes reduzem apenas a espera da viagem. O custo de combustível permanece ligado à rota-base, por isso transporte não compra caçadas diárias adicionais.
- O transporte permanente de 50% já existe por Créditos no nível 13. Uma licença temporária premium de 14 dias só poderá existir como antecipação, nunca como exclusividade ou melhoria acima desse teto.
- Espaços adicionais de personagem, loadout ou inventário podem ser vendidos apenas quando o espaço gratuito for confortável e não criar dor artificial.
- Alterações de nome, aparência, espécie, classe ou respec podem ter custos normais/premium definidos quando esses fluxos forem finais.

## Produtos futuros permitidos

- Pacotes transparentes de Fichas de Dobra.
- Um pacote inicial único, claramente descrito.
- Pacotes ocasionais de evento com conteúdo direto conhecido.
- Conveniências limitadas que respeitem os princípios acima.

Não integrar faturação real antes de conta remota, recibos idempotentes, carteira e relógio de servidor, recuperação de compra e proteção contra repetição estarem implementados.
