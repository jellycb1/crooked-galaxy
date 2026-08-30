# Account and International 1 contract

Status: active boundary. The current build is device-authoritative. Local loopback character authority plus inactive cache/reconnect rules are implemented, but the normal APK still makes no online claim.

## Current product truth

Crooked Galaxy remains a local test build. `International 1` is the stable shard identity reserved for the first global multilingual world, but no account backend is contacted. The device is the only authority for progress, the session is `local_ready`, and synchronization is `local_only`.

The UI must never call this state authenticated, online, cloud-saved, or synchronized. Login creates a local account boundary without requesting credentials. Portuguese and English are account preferences; class, species, name, equipment, and progression belong to the active character.

## Ownership model

```text
provider: local_device
  account: local_account_primary
    session: local_primary / local_ready
    shard: international_1
    active character: local_character_primary
      player profile and all progression
```

The account owns an explicit list of character IDs and selects one active character. A loaded account may not claim a different character, change its authority to `server`, or claim a synchronized state. Schema 14 adds this ownership without inventing an account or character for an interrupted fresh login.

## Transaction and revision policy

`local_revision` advances only after a complete atomic save transaction. Failed writes do not advance the committed in-memory revision. `last_server_revision` remains zero until a real backend acknowledges a revision. Backups continue to mirror the latest committed transaction.

Future conflict resolution is deterministic:

| Condition | Required decision |
| --- | --- |
| Backend unavailable | Keep device authority; continue `local_only` |
| Remote character ID differs | Reject the foreign profile |
| Remote advanced after the last acknowledged revision while local changes are pending | Stop and request explicit conflict resolution |
| Remote is newer and local is uncontested | Download remote profile |
| Local is newer | Upload local profile |
| Revisions match | Mark synchronized |

No automatic merge of currencies, inventory, claimed rewards, combat phases, or progression is allowed.

## Future online adapter boundary

A real provider may later supply credentials, authenticated session refresh, server revision fetch, and atomic profile upload/download. It must preserve the same stable account, character, server, and locale fields. Expired authentication may fall back to `offline_cached` only after a previously acknowledged server snapshot exists. The inactive cache implementation now validates ownership/revision, writes atomically, expires after seven days, and opens only as read-only `cached_server`: economy, social actions and billing are prohibited. Normal boot does not configure or use it yet.

On reconnect, an uncontested server snapshot replaces the cache as a unit. Exact pending commands retain their original idempotency keys and may retry only while the server revision is unchanged. A server advance with pending work requires conflict review; a foreign owner, malformed queue or revision regression is rejected. No path uploads or merges fields automatically.

An established local-test character and a pristine revision-zero remote character produce one explicit archival cutover: preserve the old local save as a non-authoritative archive, then start from the remote baseline. Device-authored level, currencies, equipment, claims, timers and progression are never imported or merged into the online economy. The offer disappears after a recorded decision and is never shown over progressed remote state. Any later recognition for internal testers must be granted as a separately audited server-side entitlement, never inferred from the old save.

The inactive archive primitive copies the primary, staging and backup members into a unique app-private directory, verifies every copy by SHA-256 and writes its non-authoritative manifest last. It leaves all active files untouched. Normal-boot integration may remove or replace those active files only after the pristine remote snapshot and archive manifest are both durable; the current offline build never calls this transition.

The provider-neutral wire validation, server-clock sampling, secret separation, revisioned command envelope, idempotent receipt, cache and reconnect policies are executable in `backend_protocol_rules.gd` and `profile_sync_rules.gd`, and normative in `BACKEND_VERTICAL_SLICE_CONTRACT.md`. This is protocol preparation, not a deployed backend: all remote capability flags remain false and the local save remains unchanged.

Arena, rankings, Bounty Agencies and future Consortiums must depend on server-authoritative character snapshots and cannot be built on the current device-authoritative save. Agency membership belongs to one character on one shard, is revisioned independently from the player save, and must never be reconstructed from local claims. The active social design is defined in `BOUNTY_AGENCY_CONTRACT.md`.
