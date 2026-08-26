# Account and International 1 contract

## Current product truth

Crooked Galaxy 0.26 remains a local test build. `International 1` is the stable shard identity reserved for the first global multilingual world, but no account backend is contacted. The device is the only authority for progress, the session is `local_ready`, and synchronization is `local_only`.

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

A real provider may later supply credentials, authenticated session refresh, server revision fetch, and atomic profile upload/download. It must preserve the same stable account, character, server, and locale fields. Expired authentication may fall back to `offline_cached` only after a previously acknowledged server snapshot exists; this local test build cannot manufacture that state.

Arena, rankings, and syndicates must depend on server-authoritative character snapshots and cannot be built on the current device-authoritative save.
