# Backend vertical slice contract

Status: active protocol boundary. Version 1 now has a local authenticated server plus official Godot-client clock and character-authority implementation; no remote provider or endpoint is configured in the current APK.

## Product truth

Crooked Galaxy remains device-authoritative and `local_only`. `International 1` is the sole canonical shard, but its account, clock, profile and Agency service flags remain disabled. The client must not display online login, cloud synchronization, Agency membership or server rewards until a real service implements and passes this contract.

This slice deliberately does not persist credentials, contact a server, alter the player-save schema or move progress authority away from the device. It creates the stable seam required before those changes can be made safely.

The separate `backend/` development stack proves Nakama health, development device authentication and authenticated clock/character RPCs on loopback. The pinned SDK independently proves the same path through Godot, but normal boot supplies it no endpoint or credential. Inactive read-only cache and reconnect rules now pass without field merging. A pinned, unactivated TLS staging package is ready for a dedicated host and DNS name; all online capability flags remain disabled. The remaining implementation boundary is the one-time trusted migration from current local saves, while public staging must separately prove normal-boot reconnect behavior.

## Session boundary

An authenticated response must declare API version 1, server authority, `international_1`, a bounded provider/account/session identity and an active character that occurs exactly once in the owned-character list. Issuance and expiry are validated against the caller's current time; sessions may last at most 30 days.

The canonical session summary is safe to persist and never contains access or refresh credentials. A bearer token can only be extracted through the separate memory-only transport function. Passwords, authorization values, client secrets, API keys and bearer/refresh/access tokens are forbidden in profile and command payloads at every nesting depth.

## Server clock

Daily attempts, weekly resets, Agency contribution limits and future commerce require server UTC. A clock sample records the midpoint offset, round-trip duration and uncertainty. Reversed timestamps, non-server authority, unsupported API versions, impossible Unix values and round trips above 30 seconds are rejected. Device time remains the current gameplay clock while `clock_backend` is false.

## Character snapshots

A remote profile is acceptable only when account, character and shard match the requested ownership tuple. The server supplies its revision and UTC timestamp; the embedded profile must repeat the same character ID and contain no credentials. A foreign or malformed snapshot is rejected as a unit. Currencies, inventory, claims and social state are never field-merged.

The local implementation gives each authenticated account exactly one launch character. Class, species, name and all four appearance choices are mandatory. The server itself supplies level 1, zero XP, 25 credits and zero premium/scrap balances. Class and species are immutable after creation; the current profile commit permits only name and appearance. Storage is server-write-only and the account ID is also the owned character ID for this first-character slice.

## Commands and receipts

Every mutation carries API version, command ID, idempotency key, operation, session, shard, character, expected revision and payload. Version 1 reserves these operations:

- profile commit;
- Agency application and departure;
- Agency Intel contribution and capture attempt;
- Agency reward claim.

Accepted and duplicate receipts must bind the exact command identity and advance beyond its expected revision. Both complete the original operation without replaying it. A revision conflict requires a fresh authoritative snapshot. Domain rejection stops. Timeout, rate limit and server failure retry the same command and idempotency key; authentication failure refreshes the session before retrying that same identity. A retry must never manufacture a new command to disguise uncertainty.

## Activation order

1. Deploy provider authentication and server UTC against a test environment.
2. Make character snapshots and profile commits pass ownership, revision, idempotency and conflict tests. **Complete on local loopback; staging remains pending.**
3. Exercise offline cache and reconnect without automatic field merging. **Rules and crash-safe read-only cache complete; normal-boot/staging exercise remains pending.**
4. Implement server-owned Agency roster and warrant records using the same command receipts.
5. Enable each capability flag independently only after end-to-end evidence exists.

Agency UI, ranking and rewards remain prohibited before steps 1–4. Billing is a separate server-verified boundary and is not implied by this protocol.
