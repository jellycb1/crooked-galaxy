# Staging offsite backup evidence — 2026-08-30

Status: implementation in progress. Update each pending item only from observed command evidence.

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
- PENDING — encrypted repository initialization and independently held recovery material.
- PENDING — first fresh dump, checksum validation and encrypted archive.
- PENDING — repository consistency check.
- PENDING — download, SHA-256 validation and complete isolated PostgreSQL restore.
- PENDING — daily systemd timer installation and one successful service invocation.

This evidence applies only to disposable staging. It does not activate the Android online client, production accounts, Agency, Arena, rankings or billing.
