# Online backend decision — 29 August 2026

Status: active architecture decision. Nakama is selected; no remote environment, credential, client add-on or online product claim exists yet.

## Decision

Crooked Galaxy will build its first online vertical slice on **open-source Nakama with PostgreSQL**, using its official Godot 4 client and TypeScript server runtime. The reviewed baseline pins Nakama `3.40.0`, Nakama runtime types `1.47.0` and the Godot client `3.4.0`. Pins are upgraded only through a deliberate compatibility review.

This is the best fit for an Android-first idle RPG that later needs accounts, server-owned progression, Bounty Agencies, asynchronous Arena, rankings and verified purchases. Nakama already supplies the game-specific primitives; our server runtime remains responsible for Crooked Galaxy economy and progression rules.

## Evidence and alternatives

| Candidate | Strength | Decisive limitation for this project |
| --- | --- | --- |
| Nakama | Official Godot 4 client; authentication; conditional storage; groups; leaderboards; server runtime; Google Play purchase validation. | Self-hosting requires real database/operations ownership; managed Heroic Cloud pricing is infrastructure-based and must be quoted/measured before launch. |
| Supabase | Predictable low entry cost, PostgreSQL, Auth, RLS and Edge Functions. | Godot library is community-maintained and Agencies, rankings, economy receipts and game-authoritative commands would be mostly custom. |
| Firebase | Strong Android tooling, Google authentication, App Check and generous initial quotas. | No official Godot client, document-oriented persistence is a poorer match for revisioned character/Agency transactions, and game social systems remain custom. |
| PlayFab | Mature game accounts, economy and LiveOps. | No official Godot integration in the supported-platform matrix and consumption is spread across many profile, event, economy and function meters. |

Nakama does not make client writes trustworthy automatically. Character progression, wallets, daily limits, Fenda, Agency contribution and rewards must be server-only runtime operations. Storage objects containing authority use server-write permission and conditional versions.

## Authentication product

- Primary Android identity: Google Play Games Services v2 server auth code, exchanged and verified by Nakama.
- Recovery/cross-platform identity: e-mail and password linked to the same Nakama account.
- Internal local testing may use a random app-private device UUID, never `OS.get_unique_id()` and never as the only recoverable production identity.
- The game account is created before its first character. Class, species and name remain mandatory character creation steps.
- Social authorization codes are single-use and never stored. Session and refresh tokens remain memory/private-storage concerns and never enter the player profile.

## Authority and offline policy

The first production model is server-authoritative. A previously synchronized character may open in a clearly marked cached state, but economic mutations remain pending until server confirmation. Agency, ranking and billing require connectivity. No field-wise merge of currencies, inventory, claims, timers or social state is allowed.

For the first migration from the current local test build, the player chooses one side when local and remote profiles both contain progress. The server records a one-time import receipt and never accepts the same local profile twice.

## Deployment phases

1. Local loopback: health, development authentication, server UTC and protocol v1 receipts.
2. Staging over TLS: Google tester accounts, character create/snapshot/commit, reconnect and conflict recovery.
3. Economy authority: missions, loot, currencies, inventory, daily limits and Fenda transactions.
4. Agency authority: groups mapped to the approved 25-character Agency contract plus weekly warrant records.
5. Billing sandbox: Google Play receipt validation, replay prevention, restoration and refund handling.
6. Production readiness: backups, restore drill, metrics, alerting, abuse limits, privacy/export/delete flow and load test.

Capabilities are activated separately. A configured URL never enables a feature by itself.

## Cost posture

Begin with local open-source development. Compare a small managed deployment against a single-node self-hosted staging environment only after request volume can be measured. Production must budget backups, monitoring, TLS, database maintenance, incident response and regional latency; the cheapest virtual machine is not the real operational cost.

Current published reference points are volatile and must be rechecked before spending: Supabase advertises Free and USD 25/month Pro tiers with included MAU/function quotas; Firebase offers free quotas with pay-as-you-go Google Cloud services; PlayFab uses multiple consumption meters; Heroic Cloud charges active deployment capacity and add-ons.

## Immediate gate

The repository may prepare provider-neutral and Nakama-specific contracts, but must not download the client, add Android plugins or enable `account_backend`, `clock_backend`, `profile_backend`, `agency_backend` or billing until a reproducible local server and integration test exist. Docker Desktop/Compose is currently absent from the development host, so local deployment is the next external prerequisite rather than something the APK should conceal.

## Official references consulted

- Nakama Godot 4 client: <https://heroiclabs.com/docs/nakama/client-libraries/godot/> and <https://github.com/heroiclabs/nakama-godot/releases>.
- Nakama authentication and Google Play Games v2: <https://heroiclabs.com/docs/nakama/concepts/authentication/>.
- Nakama conditional storage, groups and purchase validation: <https://heroiclabs.com/docs/nakama/concepts/storage/collections/>, <https://heroiclabs.com/docs/nakama/concepts/groups/> and <https://heroiclabs.com/docs/nakama/concepts/iap-validation/>.
- Nakama server/runtime releases: <https://github.com/heroiclabs/nakama/releases> and <https://heroiclabs.com/docs/nakama/server-framework/typescript-runtime/>.
- Supabase pricing, Auth and client support: <https://supabase.com/pricing>, <https://supabase.com/docs/guides/auth> and <https://supabase.com/docs/guides/api/rest/client-libs>.
- Firebase pricing and Android attestation: <https://firebase.google.com/pricing> and <https://firebase.google.com/docs/app-check/android/play-integrity-provider>.
- PlayFab platform and consumption model: <https://learn.microsoft.com/gaming/playfab/sdks/platforms/> and <https://learn.microsoft.com/gaming/playfab/pricing/meters/meters>.
