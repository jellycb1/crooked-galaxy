# Backend vertical slice contract

Status: active protocol boundary. Version 1 now has a local authenticated server plus an official Godot-client public-TLS staging proof; no remote endpoint or client key is configured in the current APK.

## Product truth

Crooked Galaxy remains device-authoritative and `local_only`. `International 1` is the sole canonical shard, but its account, clock, profile, economy and Agency service flags remain disabled. The client must not display online login, cloud synchronization, Agency membership or server rewards until a real service implements and passes this contract.

This slice deliberately does not persist credentials, contact a server, alter the player-save schema or move progress authority away from the device. It creates the stable seam required before those changes can be made safely.

The separate `backend/` development stack proves Nakama health, development device authentication and authenticated clock/character RPCs on loopback. The pinned SDK now also proves the same ownership, commit, idempotency, conflict, read-only cache and reconnect path through the normal main-scene boot against public TLS staging. A new disposable account additionally binds a pristine revision-zero remote baseline to an exact three-member local-save archive whose manifest forbids seeding server progress; source files remain intact throughout the proof. The probe requires explicit command-line activation plus process-only host and client-key injection; the exported APK contains neither value and ordinary boot remains offline. Physical Android certificate, lifecycle and real-save confirmation remain separate.

## Session boundary

An authenticated response must declare API version 1, server authority, `international_1`, a bounded provider/account/session identity and an active character that occurs exactly once in the owned-character list. Issuance and expiry are validated against the caller's current time; sessions may last at most 30 days.

The canonical session summary is safe to persist and never contains access or refresh credentials. A bearer token can only be extracted through the separate memory-only transport function. Passwords, authorization values, client secrets, API keys and bearer/refresh/access tokens are forbidden in profile and command payloads at every nesting depth.

## Server clock

Daily attempts, weekly resets, Agency contribution limits and future commerce require server UTC. A clock sample records the midpoint offset, round-trip duration and uncertainty. Reversed timestamps, non-server authority, unsupported API versions, impossible Unix values and round trips above 30 seconds are rejected. Device time remains the current gameplay clock while `clock_backend` is false.

## Character snapshots

A remote profile is acceptable only when account, character and shard match the requested ownership tuple. The server supplies its revision and UTC timestamp; the embedded profile must repeat the same character ID and contain no credentials. A foreign or malformed snapshot is rejected as a unit. Currencies, inventory, claims and social state are never field-merged.

The online cutover never treats the current local save as trusted input. When established local progress meets a pristine revision-zero remote character, the only accepted transition archives the local file and starts the remote baseline. No client RPC accepts local level, XP, currencies, equipment, rewards, timers or completion claims. A future tester recognition, if any, requires an independent server-side entitlement and audit trail.

The local implementation gives each authenticated account exactly one launch character. Class, species, name and all four appearance choices are mandatory. The server itself supplies level 1, zero XP, 25 credits and zero premium/scrap balances. Class and species are immutable after creation; the current profile commit permits only name and appearance. Storage is server-write-only and the account ID is also the owned character ID for this first-character slice.

## Commands and receipts

Every mutation carries API version, command ID, idempotency key, operation, session, shard, character, expected revision and payload. Version 1 reserves these operations:

- profile commit;
- hunt acceptance, resolution and reward claim;
- attribute allocation, inventory equip and inventory recycle;
- Agency application and departure;
- Agency Intel contribution and capture attempt;
- Agency reward claim.

Accepted and duplicate receipts must bind the exact command identity and advance beyond its expected revision. Both complete the original operation without replaying it. A revision conflict requires a fresh authoritative snapshot. Domain rejection stops. Timeout, rate limit and server failure retry the same command and idempotency key; authentication failure refreshes the session before retrying that same identity. A retry must never manufacture a new command to disguise uncertainty.

## Activation order

1. Deploy provider authentication and server UTC against a test environment.
2. Make character snapshots and profile commits pass ownership, revision, idempotency and conflict tests. **Complete on local loopback and public TLS staging through the official Godot client.**
3. Exercise offline cache and reconnect without automatic field merging. **Crash-safe rules and a normal main-scene staging reconnect pass on Windows; physical Android lifecycle evidence remains pending.**
4. Implement server-owned normal hunts, economy/build snapshots, reward claims, attribute allocation and inventory mutations using the same command receipts. **Implemented and proven against live loopback plus public-TLS staging Nakama/PostgreSQL with a generated 35-world catalog, frozen accepted-hunt builds and deterministic class/build combat; physical Android evidence and client activation remain pending.**
5. Implement server-owned Agency roster and warrant records using verified normal-hunt evidence.
6. Enable each capability flag independently only after end-to-end evidence exists. Technical staging evidence is not sufficient: the normal-client gate additionally requires physical Android TLS/lifecycle, a real-save archival cutover, the normal login flow and explicit activation approval. Economy then requires physical authoritative-hunt and build-mutation evidence; Agency and billing retain separate product-flow approvals.

The Godot client owns one reusable `RemoteSessionCoordinator` boundary for explicit local/staging authentication, authoritative character adoption, archival cutover, read-only cache and reconnect decisions. Before disconnect it requires character, economy and build to canonicalize under the same owner and revision; the cache persists those three views atomically, rejects cross-view wallet/inventory contradictions and deliberately excludes the expiring hunt board and every pending command. The staging probe uses this same boundary. It is not an autoload, is not referenced by `GameState`, accepts no production environment and exposes no endpoint or credential through its safe summary; its existence does not activate normal gameplay.

Remote profile and economy mutations pass through a separate `RemoteCommandDispatcher` in the explicit staging probe. It owns the current shared character/economy/build/hunt-board revision and permits only one in-memory command with an uncertain outcome. Transport failure can retry only that exact command ID, idempotency key, operation, expected revision and payload; another mutation cannot overtake it. Accepted, duplicate, conflict and domain-rejected receipts all trigger a complete character-plus-economy-plus-build-plus-board refetch at the receipt revision. A split or foreign snapshot, stale board or character, forged receipt identity or failed refetch makes the dispatcher stale instead of merging fields or guessing success. The dispatcher is likewise absent from `GameState`, exports no endpoint and provides no offline mutation queue.

Before the coordinator writes the read-only disconnect cache, the staging lifecycle must explicitly close the dispatcher. Closing erases its account, revision and all online presentation snapshots and makes mutations unavailable. It refuses to close while a command outcome is uncertain; that command must be retried or explicitly abandoned with its identity returned for diagnostics, never silently discarded.

The explicit staging path composes both objects through one `RemoteRuntimeBoundary`. It owns connection, complete-unit bootstrap, mutation refresh, ordered dispatcher closure, composite cache creation and reconnect comparison. Unknown outcomes block cache and reset; explicit diagnostic abandonment permits zeroization but the resulting stale unit can never be cached. This boundary remains explicit-test-only, is not an autoload and is absent from normal `GameState` startup.

Agency membership deliberately has its own `RemoteAgencyDispatcher` instead of entering the shared character/economy revision or disconnect cache. The inert client seam canonicalizes `none`, pending-application and full member snapshots under the authenticated owner and `International 1`; a member role must match exactly one canonical roster entry. Creation, application and departure intents use an independent expected social revision, preserve exact command identity across unknown transport outcomes and require a complete membership refetch after a known receipt. Closing zeroizes the adapter, owner, revision and social presentation. Nakama now uses authoritative Groups for real Agency identity/membership and exposes authenticated membership, directory and creation RPCs. Local HTTP and official-Godot integration prove creation, exact replay, sole-Director ownership and roster-free discovery. Application, departure and role-management endpoints do not exist yet, the boundary is absent from `GameState`, and `agency_backend` remains false.

The Agency directory is roster-free and bounded to 25 canonical summaries per cursor page. It reveals only Agency identity/name, social revision, member count, recruitment mode, preferred locale and computed capacity; duplicate IDs, invalid cursors and unsupported enum values fail closed. `agency_create` contains exactly the trimmed display name, recruitment mode and locale. Nakama generates the identity and creates the initial sole-Director membership with a recovery marker in Group metadata; roster and Prestige remain server outputs. This path is local-only evidence until a separate staging deploy, and no normal game flow can invoke it.

Agency UI, ranking and rewards remain prohibited before steps 1–4. Billing is a separate server-verified boundary and is not implied by this protocol.
