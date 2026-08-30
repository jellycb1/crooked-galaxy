# Staging offsite backup evidence — 2026-08-30

Status: operational for disposable staging. Encryption, first archive, repository verification, isolated recovery and daily scheduling all passed.

## Boundary and topology

- Source: Crooked Galaxy disposable staging CX33 in Helsinki.
- Destination: dedicated Hetzner Storage Box BX11 `crooked-galaxy-backups` in Falkenstein, 1 TB.
- Transport: dedicated Ed25519 key, Storage Box SSH port 23; the ordinary operator key is not authorized for this target.
- Content: PostgreSQL custom-format dump plus SHA-256 companion only. No live PostgreSQL data directory is mounted or copied.
- Confidentiality: Borg authenticated repository encryption; passphrase and exported recovery key are never committed or logged.
- Retention: 14 daily, 8 weekly and 12 monthly archives after a successful new archive.

## Observed evidence

- PASS — the VPS reached the Storage Box with the dedicated key and returned its restricted home directory.
- PASS — local Borg 1.2.8 and Storage Box Borg 1.2.9 are protocol-compatible.
- PASS — authenticated `repokey-blake2` repository initialized; recovery key and passphrase copied to an ACL-restricted directory outside the project repository on the operator PC without displaying either secret. The exported key copy was hash-compared and its redundant VPS export then removed; the passphrase remains mode `0600` on the VPS because unattended backups require it.
- PASS — fresh dump `nakama-staging-20260830T064323Z.dump` passed structural validation and SHA-256 before archive `staging-2026-08-30T06-43-23Z` was created.
- PASS — `borg check --verify-data` completed successfully against the independent repository.
- PASS — the archive was downloaded, its SHA-256 matched and it restored completely into a disposable PostgreSQL instance with 20 public tables; the drill removed its exact temporary container, volume and recovered files.
- PASS — the hardened systemd service created and verified a second archive; the enabled persistent timer is active and scheduled daily at 03:20 UTC with up to 45 minutes of jitter.

This evidence applies only to disposable staging. It does not activate the Android online client, production accounts, Agency, Arena, rankings or billing.
