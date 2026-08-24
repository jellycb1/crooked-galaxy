# Crooked Galaxy

Mobile-first comedic sci-fi idle RPG built with Godot 4 and GDScript.

## Current playable slice

The prototype implements the product's central test:

`BOUNTY → APPROACH → HUNT / INCIDENT → AUTOMATIC COMBAT → REWARD → LOOT → EQUIP → STRONGER BOUNTY`

It currently includes five complete four-target chapters: Dustball Prime, the frozen corporate world Congelária S.A., the fungal network planet Micélia 404, the mechanical scrapyard Ferro-Velho Ômega, and the neon probability trap Cassino Quasar. Each destination has an original visual theme, escalating targets, boss, hunt incidents, and equipment family. Finishing chapters unlocks persistent galaxy-map travel, while three captures of each active warrant reveal the next target sequentially. A capped eight-hour AFK patrol grants credits and scrap on return, while consecutive captures build a capped credit-paying streak that is lost on defeat or abandonment. Repeated captures also build three target-mastery tiers that improve future rare and epic loot odds. A career screen summarizes planets, lifetime patrol earnings, claimable milestones, and a persistent twenty-target wanted archive; it also recommends the closest unfinished mastery tier and links back to that warrant. Rare equipment can carry power, integrity, opening-shot, or incoming-damage-reduction modifications. Every new item also records its planet of origin; matching weapon and armor activates a visible planetary kit bonus that participates in combat odds and complete-build comparison. The workshop filters, sorts, protects valuable pieces, manages two persistent loadouts, safely bulk-recycles, and spends scrap on either power calibration or capped integrity reinforcement. The slice also includes three risk/reward approaches per contract; the dangerous corporate warrant explicitly trades lower odds for credits and a small workshop-scrap reward without inflating loot tier. AFK-safe hunt resolution, scalable procedural portraits, runtime-synthesized sound effects, planet-themed automatic combat, XP and level progression, simulation-backed risk estimates, content validation, versioned save migration, and local persistence complete the slice.

Level progression awards two persistent attribute points per level across Strength, Vitality, Dexterity, Intelligence, and Cunning. The portrait hub keeps taps in a reversible draft until explicit confirmation, and legacy hunters receive the points earned by their existing level. Each attribute contributes a restrained universal bonus.

Three prototype bounty-hunter classes currently exercise that foundation: Quebra-Mandados specializes in Strength, Pistoleiro Orbital in Dexterity, and Hacker de Contratos in Intelligence. Their names, themes, copy, and final identities are explicitly replaceable placeholders; only their tested mechanical roles are current design scaffolding. Class effects are declared as data rather than ID-specific combat branches, so the roster can be replaced or expanded without rewriting combat. Every current class adds one Power for every two points invested in its primary attribute; Hacker additionally converts each invested Intelligence point into two opening damage, compensating for its one-turn tactical window. Each selector card previews the exact bonus produced by the hunter's current committed attributes without selecting or mutating the class. Vitality, Cunning, equipment, and every universal attribute effect remain active. Selection uses a separate mobile scroller and explicit confirmation; reclassification is free during early access so unfinished balance cannot trap an existing save.

The workshop paginates filtered and sorted inventory into twelve-card windows. Only the active page is instantiated, keeping touch navigation and rendering bounded even when a long-running hunter retains hundreds of pieces; page choice remains transient and never expands the save schema.

The bounty board now links to a deterministic three-offer planet market. Credits buy weapons or armor, with upgrades equipped automatically and alternatives stored; paid stock renewal creates a repeatable credit sink. Stock deliberately trails the active warrant tier, preventing the market from selling the next target's reward before the fight. Offer-cycle and purchase records persist through save schema 9 and are bounded during load sanitization.

The bounty board keeps its next contract visually dominant through a compact 3×2 hunter-hub grid. Arsenal, market, hangar, galaxy, career, and class/attribute destinations retain 48-unit touch targets without consuming a full six-button column; pending class choice, attribute points, career claims, and funded build testing remain visible through concise labels and color.

The `HANGAR DUVIDOSO` adds four permanent transports unlocked across chapter completion. Bought models can be equipped freely and reduce only the approach's base hunt time by 10–40%; incident delays remain fully additive, while combat odds, rewards, loot power, and AFK patrols remain unchanged. Prices compete directly with market spending, turning the fastest models into campaign and post-campaign credit goals rather than compulsory combat upgrades. Ownership and the active model persist atomically through save schema 9, while malformed or prematurely unlocked records are repaired safely.

Market and hangar now expose each other as neutral spending alternatives. The market names the nearest unowned permanent transport and its exact speed/price, while the hangar reports how many current stock offers are genuine complete-build combat upgrades and the cheapest entry price. One-tap cross-navigation keeps the comparison actionable without reserving currency, recommending a compulsory purchase, or changing either economy.

Every transport uses an original, code-drawn vector silhouette rather than a shipped bitmap or reference asset. The boxy shuttle, roof-lit warp taxi, magnetic wedge interceptor, and asymmetric executive yacht scale from compact hangar cards to map and hunt status without additional texture residency. The active silhouette follows the hunter through the galaxy map, contract briefing, and live hunt so the time upgrade remains part of the travel fantasy rather than an isolated shop statistic.

Aggressive contract routes now preserve their identity as equipment grows. The fast route grants 45% more credits but adds substantially more target resistance; the corporate route grants 85% more credits and two workshop scrap at still higher combat pressure. Resistance pressure rises gently by planet while attack pressure remains fixed, avoiding hidden player-scaled enemies and preserving the safe route as recovery. Equipment drops remain anchored to the canonical target, so extra danger cannot inflate the loot tier.

Congelária and Micélia use a smoother mid-campaign combat curve instead of repeating the previous chapter's endpoint. Their explicit loot-power anchors preserve the established equipment economy while stronger combat profiles keep safe, fast, and corporate routes meaningfully distinct. Campaign reports include per-planet saturation and viable-choice metrics so future content cannot hide a local plateau behind a healthy global average.

Four original portrait environment paintings now ground the primary mobile contexts: bounty office, frontier spaceport, arsenal workshop, and encounter arena. They are production assets included in desktop and Android exports; proprietary study references have no active runtime mapping and remain export-excluded.

Every primary screen also exposes a visible keyboard/controller focus ring. Rebuilt layouts restore the equivalent focused action when possible and otherwise select the first enabled action, including automatic combat redraws.

The arsenal includes a persistent reduced-motion preference. It removes the decorative loot fade while preserving automatic combat, its deliberate 1× default, the readable victory receipt pause, and the explicit skip action.

Dense decision layouts are regression-tested with 125% expanded typography. Shared actions and long loot names wrap by words so briefing, incident, threshold reward, career, and arsenal controls remain reachable at the mobile viewport.

Window focus and mobile suspension explicitly freeze automatic combat and preserve the unread portion of the victory receipt. Overlapping lifecycle notifications are idempotent; idle hunts still reconcile wall-clock progress on the final resume, and mobile suspension saves immediately.

Local write failures no longer fail silently. A phase-independent warning explains that progress remains only in memory and offers a retry; it clears only after the complete current payload is flushed successfully, without hiding the mobile victory action.

Save replacement is crash-resilient: a fully flushed staging payload is promoted before a latest-state backup is refreshed. Loading prefers a valid interrupted staging write, then primary, then backup; copy recovery is visible and rewrites the primary without rolling reward or incident transactions backward.

If primary, staging, and backup are all unreadable, normal gameplay and writes remain blocked instead of silently replacing evidence with defaults. `INICIAR NOVO SAVE` is an explicit recovery decision that first preserves every damaged artifact under a `.corrupt` suffix, then creates a canonical primary/backup pair.

Corrupt-artifact retention is bounded to the two newest generations for each member of the save family. Cleanup runs only after a replacement save succeeds, retaining the most useful recent evidence without unbounded storage growth.

Threshold captures explicitly preview and reveal the next warrant, keeping early progression visible without a modal tutorial.

Reward screens also count the pending capture toward target mastery and preview its rare/epic loot bonus plus one-time workshop scrap funding before the player commits the loot decision.

The first reward in any sequence explicitly marks embalo ×1 and explains that its credit bonus begins on the next consecutive capture; later rewards show the exact active bonus. On the return board, that ×1 lesson is embedded in the exact contract/equipment receipt instead of repeated as a second tutorial banner. Established streaks retain their forward-looking reminder.

Reward decisions use three distinct visual layers: loot identity, a `NOVO / EQUIPADO / RESULTADO` comparison, and grouped contract/progression evidence. Repeat remains the solid primary action for ordinary captures; when a new warrant opens, the named warrant destination becomes solid while workshop preparation stays secondary. Recycling remains explicit and destructive-looking without competing with a genuine upgrade.

The initial reward prioritizes the equipment upgrade and next-warrant `1/3` progress. Target-mastery vocabulary begins on the second capture at `2/3`, immediately before its first tangible loot-quality and workshop reward, avoiding two unrelated `1/3` counters on the first decision screen.

On that second capture, the two systems converge into one explicit promise: the next repeat grants mastery 1/3 and opens the named warrant. The duplicate warrant-progress/odds line is omitted for this one handoff, keeping `EQUIPAR E REPETIR` as the dominant decision.

The combined third-capture reward keeps two intentional destinations—spend the new mastery scrap before hunting, or inspect the newly opened warrant immediately. Mobile guards verify both that threshold choice and the first reward's repeat/board actions remain fully inside the viewport.

On ordinary rewards, the repeat route previews the next streak multiplier and approach-invariant percentage. Exact credits remain attached to the selected approach and incident outcome. Threshold rewards suppress the repeat prompt and prioritize the newly opened warrant.

Contract briefings present all three routes and their actions inside the initial 450×800 decision viewport. Every compact card follows the same scan order: strategy and explicit risk, short route fiction, included streak/scrap bonuses, time, current-build win chance, credits, XP, and the exact named action. A bordered `MELHOR EQUILÍBRIO` state explains that the dynamic recommendation balances risk, return, and time without hiding the alternatives.

Repeated-contract briefings mark each route's displayed payment as already streak-adjusted and show its exact included bonus, preventing the same percentage from being counted twice.

Hunt incidents recompute and display the final victory payment for every choice, including any streak amount already embedded after that consequence.

Their interruption panel also names the exact paused hunt percentage and remaining seconds, making it clear that the idle timer resumes after the choice rather than having stalled.

Paid incident options additionally show the net contract gain after their immediate credit cost.

If a paid choice is unaffordable, its disabled action states the exact missing credits; zero-cost alternatives remain enabled in the same incident.

Incident resolution is persisted atomically with its cost and applied choice: reloading resumes the mutated hunt, cannot charge the same option twice, and cannot resurrect it after abandonment.

Reward claiming has the same transaction guarantee across credits, XP/captures, contract and mastery scrap, equipment/inventory changes, and pending-loot cleanup; reload cannot execute the receipt twice.

Claiming also consumes the completed victory log before saving. The evidence remains visible through combat, victory, and reward, but cannot be misinterpreted as damaged state after its approach-modified contract has been cleared.

Immediate repeat saves only after replacing the completed modified contract with a canonical target and three fresh approaches, so reload cannot retain the old route or skip the next route decision.

Chapter finales survive reload until acknowledged. Continuing consumes only the finale evidence; completed-planet and active-route progress remain persistent, and later reloads cannot resurrect the completion screen.

AFK rewards immediately persist their updated wallet and `last_seen` timestamp, including after chapter continuation, so a second launch cannot claim the completed-planet patrol multiplier twice.

The AFK settlement watermark is monotonic: a device-clock rollback pays nothing and cannot manufacture a later patrol when the clock catches up. Boundary tests cover the five-minute minimum, exact and exceeded eight-hour cap, pre-capture lock, duplicate launch, and a return that also repairs save data.

The reward receipt retains paid incident cost and reconciles gross payout with the exact net wallet gain from before the choice.

Claim summaries and the persistent board/workshop record name whether the captured item was equipped, stored, or recycled, including the exact item name.

After an equipped claim with enough scrap for at least one calibration, the board's arsenal shortcut becomes a contextual `TESTAR BUILD` action that opens the field-test odds beside the new loadout. Unfunded early loot keeps the ordinary arsenal link, leaving the repeat contract as the clear first-session action.

The workshop presents one explicit `MELHOR INVESTIMENTO` strip between the field test and equipped pieces. It names the affected slot and item, exact scrap cost, projected odds change (or saturated-build impact), and exposes a single 48-unit `APLICAR` action while retaining both manual upgrade paths below. Recommendation, loadouts, filters, recycling, and the bounded 12-item inventory page remain visually distinct in the initial Android viewport.

When that field test focuses an available warrant, its `ESCOLHER ROTA` action opens the briefing and preserves the same recommendation instead of implying that combat begins immediately.

Briefings opened through that handoff display the tested route and odds as confirmed context while keeping all three approach choices available; ordinary board and career briefings remain context-free.

The active hunt persists whether the player confirmed that tested route or deliberately replaced it, so the decision remains visible through interruptions and later incident resolution.

That compact tested-versus-chosen record is reused on the paused incident and automatic-combat screens, alongside the selected approach and incident-adjusted payment.

Victory closes that provenance trail beside the capture report; the reward screen then replaces it with loot, receipt, mastery, streak, and next-hunt projection evidence.

On defeat, the combat summary preserves that provenance after the live contract is cleared: overridden tests recommend reconsidering the route, while a failed confirmed route redirects recovery toward build or incident choices. The revenge workshop repeats the same diagnosis beside fresh odds.

Every reward with a next warrant translates the full pending receipt—XP level gains plus the chosen equipment state—into same-route win odds before and after claiming, directly connecting loot to the next hunt and the workshop field test.

Automatic combat retains the selected incident result and adjusted payment above the encounter, preserving economic context through resolution.

The victory beat confirms that same gross payment, embedded streak bonus, and net balance before revealing loot.

It remains on screen for 2.8 seconds so the decisive hit, build contribution, combat totals, and payment can be read; `ABRIR RECOMPENSA` lets players skip that pause immediately.

The 1×/2× combat pace is a session preference: victory stops automatic turns but does not silently reset the selected speed for the next encounter.

Abandoning either an active hunt or a paused incident names the exact active streak that will be lost before the action; the return-board receipt confirms the same number afterward.

When a capture reveals a new warrant, the reward also projects the best approach and win chance after equipping the pending item, so the direct-contract and workshop routes have visible context.

Post-combat reports summarize turns, damage and the contribution of tactical traits or planetary kits; defeats name any lost capture streak, explain its ×1 restart, retain a compact diagnosis on the board, and link directly to a field-test workshop that keeps the failed warrant focused through the next attempt.

Long-career navigation keeps progress legible: galaxy cards distinguish completed chapters and name each open planet's current warrant, while career shortcuts jump directly between planetary progress and the twenty-target archive.

Every revealed and currently available wanted record in that archive has a 48-unit `ABRIR` action that travels across unlocked planets and opens its briefing; revealed-but-sequentially-locked records remain read-only.

The archive keeps all twenty records but orders the active planet's four warrants first, making late-career contract access immediate without erasing chronological history.

Career scroll position is session-persistent: claiming a milestone, rerendering the ledger, or briefly visiting another hub returns to the same section instead of the top.

Milestone claims leave an exact in-career receipt for individual or bulk rewards, including both credits and scrap, while the shared renderer cleanly replaces the previous UI tree before rebuilding transactional views.

Transient notices carry explicit provenance: reward-equipped receipts alone activate `TESTAR BUILD`, career receipts stay in career, and the arsenal distinguishes contract receipts from its own workshop records while ignoring unrelated travel or system messages.

All warrant handoffs that open a briefing now say `ESCOLHER ROTA`; a full development reset also clears hub filters, tested-briefing context, and retained career position along with gameplay progress.

Save loading clears runtime-only receipts before restoration, type-checks interrupted-phase objects, reconstructs missing briefing routes when the contract is valid, and repairs incoherent phases back to the board without discarding valid player progression.

A dedicated current-schema matrix round-trips board, briefing, hunt, incident, combat, victory, reward, and chapter-complete states and rejects any false `SAVE RECUPERADO` notice from data written by the game itself.

Its combat variant also proves optional active-kit and confirmed tested-route evidence survives when present, while empty optional fields remain omitted.

The same matrix applies and reloads all thirty canonical hunt-event choices across the five unlocked planet chains, covering paid/free costs, added duration, and combat/economic multipliers.

Representative early, mid-campaign, and final-boss targets also round-trip all three approaches, including corporate scrap metadata while proving loot power remains anchored to the canonical target.

Equipment round-trips cover every canonical modification, rarity, planetary origin, and legal reinforcement level, crossed with no, early, and mature calibration histories. Equipped and reserve copies retain their complete payloads, protection flags, and loadout references without false recovery.

Career claims are transaction-tested individually for every milestone and in bulk for early, mid-campaign, and completed profiles. Reloads retain each wallet and lifetime total exactly once, consume only eligible stable IDs, and reject duplicate claims without side effects.

Loaded player data is shape-checked against canonical defaults: scalar progress is preserved when compatible, invalid equipment falls back safely, malformed inventory entries are discarded, and loadouts always normalize to two usable slots before any renderer sees them.

When loading performs a migration or repair, the next board visit receives a concise session-only `SAVE ATUALIZADO` or `SAVE RECUPERADO` notice that emphasizes preserved progress without exposing storage internals.

When shown by itself, that system notice has an explicit acknowledgement. Gameplay receipts instead remain available for review until the player commits to the next contract, at which point target selection clears the stale transaction context.

If that recovery coincides with an AFK patrol return, both outcomes share one compact return card and one acknowledgement. This avoids competing board banners while preserving the exact patrol payout and recovery explanation.

Defeat uses the same one-outcome hierarchy: the escaped target, combat evidence, lost streak, route diagnosis, and workshop recovery action live in one persistent panel. Claimable career rewards remain counted in the header instead of inserting another competing board card.

Numerical repair enforces only canonical lower bounds and existing reinforcement caps: currencies and counters cannot be negative, level/base power stay at least one, and best streak cannot trail the active streak, while legitimately high long-career power and level remain untouched.

Identifier repair accepts only canonical targets, planets, and milestones, removes duplicates, routes an invalid current planet to the furthest legitimately unlocked chapter, and clears protection/loadout references to items the player no longer owns.

Equipment repair canonicalizes rarity colors and known modification payloads, removes unknown planetary origins or traits, and applies the same rules to pending reward loot so an interrupted decision survives whenever the base item remains usable.

Interrupted contracts are rebuilt from canonical target, approach, and incident-choice IDs; forged nested multipliers or payouts are discarded while the selected route, incident outcome, tested-route evidence, and pending reward phase remain intact.

Restored combat and chapter evidence also validates canonical target/planet identity, known kit and route context, nonnegative metrics, bounded remaining health, and a real boss-to-planet pairing before defeat recovery or finale UI can consume it.

Combat-event rows accept only catalog attacks and known quality labels; impossible hunt clocks restart with canonical duration, expired hunts still resolve normally, and resumed combat clamps HP and round counters to the active build/contract.

Automatic combat exposes a concise mobile readout above the arena: both relative-health percentages and an explicitly health-based pressure state. Fighter cards retain raw HP, add percentages, and identify the active weapon/armor build, while the latest event pair and turn report separate damage caused, damage received, quality, tactical effects, and the existing narrative. This presentation derives only from authoritative combat state and does not predict or alter the result.

## Run

Open `project.godot` in Godot 4, or run from a console where Godot is available:

```powershell
godot --path . --editor
godot --path .
```

Create and smoke-boot the local Windows release without touching the player's real save:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check_windows_export.ps1
```

The tracked `Windows Desktop` preset emits `builds/windows/CrookedGalaxy.exe` plus its PCK. Export filters exclude tests, tools, captures, notes, references, and prior builds; `builds/.gdignore` also prevents generated review images and binaries from entering Godot's resource scan.

Create the installable Android test APK locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check_android_export.ps1
```

Publish a newly verified APK to the permanent public download address without exposing this source repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\publish_android_latest.ps1
```

The command exports an ARM64 debug-signed APK and replaces only the asset on the public `latest` release. The dedicated ignored local test key keeps successive APKs update-compatible; it must never be reused for store distribution. The stable download address is:

```text
https://github.com/jellycb1/crooked-galaxy/releases/download/latest/CrookedGalaxy.apk
```

The matching checksum is always available at `https://github.com/jellycb1/crooked-galaxy/releases/download/latest/CrookedGalaxy.apk.sha256`. Publishing requires a clean tracked worktree, uploads both assets, records the SHA-256 in the release notes, and verifies the remote APK size and digest when GitHub exposes it.

This channel is intended for direct testing. The public repository contains the release/download page rather than the game's source. Preserve the ignored local test key to keep direct installs update-compatible; its non-secret public certificate fingerprint is tracked and verified on every export. A store release must use a separate private release keystore and signing workflow.

Run deterministic core tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check_project.ps1
```

For the normal edit loop, run the same functional, UI, lifecycle, migration, and phase-round-trip coverage without the 1,659-case exhaustive persistence matrix:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check_fast.ps1
```

The full checker remains the release/commit authority and reports per-suite timing. The exhaustive matrix can also run independently with `res://tests/test_persistence_matrix.gd`.

Successful checker runs retain only the three newest `.godot/test-logs` directories. Failed runs exit before pruning, so their diagnostics survive until later successful runs age them out; `-RetainedLogRuns` can raise the bounded retention when needed.

Or run an individual suite:

```powershell
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_attributes.gd
godot --headless --path . --script res://tests/test_balance_guards.gd
godot --headless --path . --script res://tests/test_flow.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_ui_factory.gd
godot --headless --path . --script res://tests/test_arsenal_view.gd
godot --headless --path . --script res://tests/test_transport.gd
godot --headless --path . --script res://tests/test_reward_view.gd
godot --headless --path . --script res://tests/test_career_view.gd
godot --headless --path . --script res://tests/test_persistence.gd
godot --headless --path . --script res://tests/test_clean_roundtrip.gd
godot --headless --path . --script res://tests/test_persistence_matrix.gd
godot --headless --path . --script res://tests/test_save_migrations.gd
godot --headless --path . --script res://tests/test_equipment_presentation.gd
godot --headless --path . --script res://tests/test_career_rules.gd
godot --headless --path . --script res://tests/test_contract_rules.gd
godot --headless --path . --script res://tests/test_audio.gd
godot --headless --path . --script res://tests/test_content.gd
godot --headless --path . --script res://tests/test_mobile.gd
```

Capture the bounty boards, market, transport hangar, defeat recovery and post-upgrade workshop, AFK return, career, galaxy map, unlocked boss, contract briefing, hunt incident, combat, victory, reward decisions, arsenal filters, and chapter-completion states for visual review:

```powershell
godot --path . --script res://tools/capture_ui.gd
```

The proprietary study art in `References/` remains local, Git-ignored, and documented. Public builds use independently generated original production environments and reject leaked reference files. A separate `Android Internal References` profile can stage exactly four registered images into a watermarked APK for composition testing on our own device; every use and intended replacement is tracked in `Notes/REFERENCE_PLACEHOLDERS.md`.

The internal adapter decodes only the visible 2000×1400 placeholder and releases it on context changes. It also unloads the corresponding production backdrop, bounding reference-image residency near 10.7 MB instead of accumulating roughly 42.7 MB across a complete navigation session.

Build and inspect that internal-only APK:

```powershell
.\tools\check_android_internal_export.ps1
```

Capture the procedural character lineup:

```powershell
godot --path . --script res://tools/capture_portraits.gd
```

Regenerate the tracked PNG boot splash from its SVG illustration and Godot-composed title:

```powershell
godot --path . --script res://tools/generate_boot_splash.gd
```

Run the deterministic combat balance simulation:

```powershell
godot --headless --path . --script res://tools/simulate_balance.gd
```

Audit the failure-aware first-chapter repeat path across 100 deterministic careers, plus alternate target-choice samples:

```powershell
godot --headless --path . --script res://tools/simulate_first_chapter.gd
```

Run a continuous five-planet, failure-aware campaign sample with real loot, mastery, XP, and workshop spending:

```powershell
godot --headless --path . --script res://tools/simulate_campaign.gd
```

The campaign simulator now selects each prototype class and automatically spends earned attribute points through comparable 50/25/25 primary-attribute, Vitality, and Cunning policies. It reports final attributes and currency plus route/odds saturation, market and hangar spend, purchases, active transport, and seconds saved. `CG_CAMPAIGN_MARKET=active|off` and `CG_CAMPAIGN_TRANSPORT=active|off` compare the optional sinks; `CG_CAMPAIGN_BUILD` can isolate `breaker_balanced`, `gunslinger_balanced`, `hacker_balanced`, or the intentionally obsolete `unassigned_control`; `CG_CAMPAIGN_STRATEGY` and `CG_CAMPAIGN_CAREERS` narrow route policy and sample count.

## Project layout

- `scenes/` — Godot scenes.
- `scripts/` — gameplay state, deterministic rules, content, and interface.
- `tests/` — headless deterministic tests.
- `Notes/` — product vision and development rules.
- `References/` — external study material, excluded from Godot imports by `.gdignore`; four registered placeholders can be staged only by the internal Android checker.

Content in `References/` is temporary internal test material, not Crooked Galaxy production content. Code, names, formulas, UI, and public distributable assets remain independently created.
