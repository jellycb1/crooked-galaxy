# Crooked Galaxy backend workspace

Status: reproducible local development service implemented and smoke-tested; no remote service is deployed or connected to the game.

The selected foundation is open-source Nakama. Version pins live in `stack-lock.json`. This directory is intentionally excluded from Godot exports.

## Environment order

1. `local`: loopback-only Nakama and PostgreSQL for protocol development.
2. `staging`: TLS test deployment with disposable accounts and no real purchases.
3. `production`: separate database, keys, OAuth application and store credentials.

Never reuse databases, encryption keys, Google credentials, purchase-validation keys or console credentials between these environments. `.env`, generated runtime output, database volumes and backups remain untracked.

## Local prerequisites

- Docker Desktop with Docker Compose;
- no host Node.js installation is required; the pinned builder runs inside Docker;
- the pinned Nakama Godot client only after the local server passes health, authentication and protocol smoke tests.

Docker Desktop/Compose is available. The local stack builds the pinned TypeScript runtime, starts PostgreSQL and Nakama on loopback, and exposes only the game API (`7350`) and local console (`7351`). Generate or complete ignored credentials with `prepare_local_env.ps1`, start with `docker compose up --build -d`, then run `test_local.ps1` and `test_godot_client.ps1`. Stop the services without deleting their database with `docker compose stop`. Both tests cover authentication, sanitized session identity, server UTC, mandatory character creation, ownership, snapshots, cosmetic commits, idempotent retries and stale-revision conflicts. The direct test also proves that a client-authored credit mutation is rejected and races two identical creates/commits to verify one atomic result plus one idempotent replay.

The Nakama base image is pulled from the official Heroic Labs Docker Hub repository. Heroic Labs documents this as the supported fallback for its rate-limited `registry.heroiclabs.com` gateway; the immutable version tag remains pinned by `stack-lock.json`. `.dockerignore` also prevents local secrets and generated state from entering the Docker build context.

The exported game remains `offline`, `local_only` and device-authoritative: the SDK is present but receives no endpoint at normal boot. Local character authority and the inactive read-only cache/reconnect/cutover policy pass, but public staging and normal-boot remote exercise remain intentionally incomplete. Existing device-authored saves will be archived rather than imported into the online economy. See `Notes/ONLINE_BACKEND_DECISION_2026-08-29.md` and `Notes/BACKEND_VERTICAL_SLICE_CONTRACT.md`.

## TLS staging package

The repository now contains a deployable-but-unactivated staging topology in `docker-compose.staging.yml`. PostgreSQL is isolated on an internal network, Nakama's game API is reachable only through Caddy, the Nakama console binds to loopback for an SSH tunnel, and only ports 80/443 are public. Caddy `2.11.4-alpine` is pinned by tag and image digest, validates the 128 KiB request ceiling, health-checks Nakama, supplies HSTS/security headers and manages public certificates. DNS must already point to the host and ports 80/443 must reach Caddy before startup.

The staging operator environment requires PowerShell 7 in addition to Docker Engine/Compose. On Linux invoke scripts with `pwsh`.

1. On the protected staging host, run `pwsh ./prepare_staging_env.ps1 -Domain <host> -AcmeEmail <operator>` once. It refuses placeholder domains and existing credentials.
2. Run `validate_staging.ps1`; this renders Compose without starting services and rejects missing secrets, an exposed Nakama API, or a non-loopback console.
3. Start with `docker compose --env-file .env.staging -f docker-compose.staging.yml up --build -d`.
4. Run `test_staging.ps1` from a host that reaches the public DNS name. It proves valid TLS/HSTS, authentication, UTC, ownership, creation, commits, idempotency and conflicts.
5. Run `backup_staging.ps1` before deployments and schema/runtime changes. It writes an ignored custom-format PostgreSQL dump, validates it with `pg_restore --list`, finalizes atomically and records SHA-256. Run `restore_drill.ps1 -BackupPath <dump>` regularly; it verifies the checksum and restores into an isolated disposable PostgreSQL volume without touching staging.

No staging host, domain or credential is committed or provisioned automatically. A successful deployment test is evidence for staging only; it does not change the APK capability flags or authorize production.

The selected external target is the disposable Hetzner CX33 x86 instance at `2.29.2.190` in Helsinki, using `staging-api.crookedgalaxy.com`, with a separate Falkenstein Storage Box planned for encrypted cross-region archives. DNS and the hardened `cgdeploy` SSH path are validated. The application deployment, public TLS proof, Cloud Firewall and Storage Box remain pending. Cloud-server snapshots are supplemental recovery only; the checked-in PostgreSQL dump and isolated restore proof remain mandatory.

`bootstrap_hetzner_staging.sh` is the reviewed Ubuntu 24.04 host bootstrap. It creates the key-only `cgdeploy` administrator, installs official Docker/Compose and PowerShell repositories, enables unattended upgrades and bounded Docker logs, but deliberately retains root key access for the validation window. Only after a separate `cgdeploy` login passes may `finalize_hetzner_ssh.sh` disable direct root access; that script refuses execution outside a real `cgdeploy` sudo session.
