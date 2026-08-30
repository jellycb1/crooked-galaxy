# Remote economy vertical-slice contract

Status: vertical slice implemented, compiled and proven against live loopback plus public-TLS Hetzner staging Nakama/PostgreSQL. Windows normal-boot lifecycle evidence passes; a fail-closed normal-client gate now prevents staging evidence alone from activating gameplay. Physical Android evidence, real-save archival cutover and deliberate activation remain disabled or pending.

The reusable Godot session coordinator now owns the lifecycle around this adapter: explicit non-production connection, server clock and ownership, archival-only local cutover, bounded read-only cache and conflict-safe reconnect. Normal `GameState` does not instantiate it and all release gates remain false.

The explicit staging path also owns one reusable command dispatcher. It keeps character, economy, build and the presented hunt board as one revision-locked authority unit, blocks concurrent mutations while an outcome is uncertain and permits a retry only with the byte-equivalent command identity already held in memory. Profile commits and economic commands therefore share the same sequencing boundary. Every known receipt is followed by a full character/economy/build/board refetch; conflict and rejection are never resolved through local field merge or automatic intent replay. A profile or board cannot be presented when it belongs to another revision. Pending mutations are not written into the offline cache.

Disconnect is a coordinated state change rather than loss of transport. The coordinator first adopts a canonical character/economy/build unit whose owner, revision, wallet and inventory counts agree. The dispatcher must then close, clearing its owned account, revision, character, board, economy and build views; it cannot close over an uncertain command. Only after that boundary is inert may the coordinator atomically persist and reopen the bounded read-only unit. Expiring hunt offers and pending commands never enter that cache.

One explicit-test-only runtime boundary now enforces that order for callers. It adopts every known post-command refetch into the coordinator, refuses cache or reset while transport outcome is unknown, and refuses to cache a stale unit even after explicit diagnostic abandonment. The public-TLS probe no longer orchestrates coordinator and dispatcher state independently.

## Product truth

The current game remains device-authoritative. `economy_backend` is false, normal APK boot has no endpoint, and the existing local progression continues unchanged. The Nakama runtime now proves the server-owned transaction in isolation without presenting local values as server-owned.

The local environment shortens each authored approach-specific hunt to two seconds solely for repeatable smoke tests. Staging and production retain the authored duration. The resolver now uses the snapshotted target pressure, enemy profile, class, attributes and equipped build in a deterministic alternating combat simulation; victory is never supplied by the client or hard-coded by RPC.

`backend/src/generated_content.ts` is generated from the canonical Godot registry. Its hash binds all 35 planets, 140 target identities, three mission roles, three approaches, three classes, enemy modifiers and pacing constants. Accepted hunts snapshot their complete authored/scaled encounter, so a later catalog update cannot silently change an in-flight result.

## Authority unit

A remote economy snapshot belongs to one authenticated account, one owned character and `international_1`. It carries one server revision and one server UTC timestamp. Level, XP, Credits, Warp Chips, Scrap, Fuel, inventory revision, active hunt and pending reward are accepted or rejected as one unit; they are never merged field by field with a local save. A separate build snapshot binds the same revision to base power, five attributes, unspent points, all nine equipment slots and the exact owned-item list. Every non-starter equipped item must still exist in that ownership list.

The server calculates costs, deadlines, odds, combat outcome and rewards. Client commands may select only stable authored or server-issued identities. A client never sends balance deltas, fuel cost, reward amounts, victory, damage, odds or timestamps as authority.

## First mutation sequence

1. `hunt_accept` selects `board_id`, `offer_id`, `target_id` and `approach_id` against an expected economy revision.
2. The server validates the current board, unlocks, fuel, target, approach and absence of another active transaction; it then creates the hunt and its authoritative deadline.
3. `hunt_resolve` identifies only the accepted `hunt_id`. The server verifies UTC readiness, resolves combat once and seals one reward.
4. `reward_claim` identifies the server-issued hunt and reward plus one disposition: `store`, `equip` or `recycle`.
5. Every accepted step advances the server revision and returns an idempotent receipt. Duplicate commands replay the same receipt; conflicts require a fresh complete snapshot.

## Build mutations

- `attribute_allocate` sends only a non-empty map of positive amounts for the five canonical attributes. The server verifies and spends the available point balance.
- `inventory_equip` sends only one owned `item_id`. Equipment is a view over ownership: equipping never deletes the item from inventory.
- `inventory_recycle` sends only one owned `item_id`. The server refuses equipped items, calculates salvage, removes exactly one item and advances the inventory revision.
- Hunt acceptance freezes the class, level, attributes and complete equipped build used by that hunt. Later workshop changes cannot alter an already accepted combat result.

## Activation evidence

Remote economy may become independently available only after all of these pass end to end:

- authoritative economy snapshot ownership and integrity;
- accepted hunt with server-calculated fuel and deadline;
- retry of the exact command identity without duplicate spend or hunt;
- UTC-gated resolution with server-calculated combat and reward;
- reward claim without duplicate currency, inventory or collection effects;
- exact build fetch plus idempotent attribute, equip and recycle mutations;
- conflict recovery by complete refetch rather than field merge;
- restart and reconnect with an acknowledged read-only cache;
- Android lifecycle validation against public TLS staging.

Agency activity depends on verified normal hunts and therefore cannot activate before economy authority. Billing additionally depends on a server wallet, but remains a separate receipt-validation and refund gate.
