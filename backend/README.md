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

The exported game remains `offline`, `local_only` and device-authoritative: the SDK is present but receives no endpoint at normal boot. The local character authority gate now passes, but staging, reconnect/cache policy and migration from existing local saves remain intentionally incomplete. See `Notes/ONLINE_BACKEND_DECISION_2026-08-29.md` and `Notes/BACKEND_VERTICAL_SLICE_CONTRACT.md`.
