# Online backend decision — 29 August 2026

Status: active architecture decision. Nakama is selected; the local loopback authentication, clock and authoritative character path pass end to end through both HTTP and the official Godot client. No remote environment, production credential or online product claim exists yet.

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

For the first transition from the current local test build, the app preserves the old save as a non-authoritative local archive and begins from the pristine server character. Device-authored progression is never imported into the online economy. Any internal-tester recognition is a separate server-side entitlement, not evidence extracted from a local save.

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

The staging provider is now fixed as Hetzner: one disposable CX33 x86 cloud server in Helsinki at `2.29.2.190`, the currently available location shown by the operator console, plus a separate Falkenstein Storage Box for encrypted cross-region database archives. The owned domain is `crookedgalaxy.com` and its reserved staging API hostname is `staging-api.crookedgalaxy.com`. This is a staging choice, not a production-topology decision. A single CX33 provides no high availability and must never be represented as launch-ready production infrastructure.

Current published reference points are volatile and must be rechecked before spending: Supabase advertises Free and USD 25/month Pro tiers with included MAU/function quotas; Firebase offers free quotas with pay-as-you-go Google Cloud services; PlayFab uses multiple consumption meters; Heroic Cloud charges active deployment capacity and add-ons.

## Local foundation evidence

Docker Desktop now runs the pinned Nakama `3.40.0` image and PostgreSQL `16.8` on a private Docker network. Only loopback ports `7350` and `7351` are exposed. The TypeScript runtime compiles inside a multi-stage image and registers protocol-v1 `cg_clock`; a repeatable smoke test verifies container health, rejects anonymous RPC access, creates a development device session, and validates authoritative UTC plus the `international_1` shard envelope. Local secrets are random, ignored by Git, absent from game exports and never printed by the test.

The official Heroic Labs Docker Hub repository is used as its documented fallback because the Heroic Labs Scarf gateway returned HTTP 429 during the first pinned pull. Both sources resolve the same Heroic Labs image/tag; no version was relaxed.

The official Nakama Godot `3.4.0` release is vendored with its Apache-2.0 license, source tag, commit, archive size, SHA-256 and guarded core-file hashes. It is registered as the documented `Nakama` autoload. A Crooked Galaxy adapter starts inert, canonicalizes only reviewed endpoints, keeps the Nakama session in memory, returns no bearer tokens and uses error-level logging. Its local integration test injects the generated client key only into the Godot child process, authenticates a stable test-only app-private device identity, invokes `cg_clock`, validates protocol version, shard, authority and latency, then discards the session.

## Immediate gate

The local server, Godot transport and first character-authority gate are complete. The public Hetzner staging service, trusted TLS edge, encrypted off-host backup and isolated recovery drill are operational. An explicitly injected normal main-scene probe now proves the official Godot client can authenticate a fresh disposable account, bind its pristine remote baseline to a non-importing local archive, verify ownership and clock, commit/replay/conflict, persist a read-only cache and reconnect cleanly over public TLS without embedding the endpoint or client key in the APK. Physical Android certificate/lifecycle and real-save cutover confirmation remain before client activation. `account_backend`, `clock_backend`, `profile_backend`, `agency_backend` and billing remain false until their individual product gates pass; prepared infrastructure and test-only evidence alone enable none of them.

## Official references consulted

- Nakama Godot 4 client: <https://heroiclabs.com/docs/nakama/client-libraries/godot/> and <https://github.com/heroiclabs/nakama-godot/releases>.
- Nakama authentication and Google Play Games v2: <https://heroiclabs.com/docs/nakama/concepts/authentication/>.
- Nakama conditional storage, groups and purchase validation: <https://heroiclabs.com/docs/nakama/concepts/storage/collections/>, <https://heroiclabs.com/docs/nakama/concepts/groups/> and <https://heroiclabs.com/docs/nakama/concepts/iap-validation/>.
- Nakama server/runtime releases: <https://github.com/heroiclabs/nakama/releases> and <https://heroiclabs.com/docs/nakama/server-framework/typescript-runtime/>.
- Supabase pricing, Auth and client support: <https://supabase.com/pricing>, <https://supabase.com/docs/guides/auth> and <https://supabase.com/docs/guides/api/rest/client-libs>.
- Firebase pricing and Android attestation: <https://firebase.google.com/pricing> and <https://firebase.google.com/docs/app-check/android/play-integrity-provider>.
- PlayFab platform and consumption model: <https://learn.microsoft.com/gaming/playfab/sdks/platforms/> and <https://learn.microsoft.com/gaming/playfab/pricing/meters/meters>.
