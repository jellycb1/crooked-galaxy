# Crooked Galaxy backend workspace

Status: provider selected and deployment boundary prepared; no service is deployed or connected to the game.

The selected foundation is open-source Nakama. Version pins live in `stack-lock.json`. This directory is intentionally excluded from Godot exports.

## Environment order

1. `local`: loopback-only Nakama and PostgreSQL for protocol development.
2. `staging`: TLS test deployment with disposable accounts and no real purchases.
3. `production`: separate database, keys, OAuth application and store credentials.

Never reuse databases, encryption keys, Google credentials, purchase-validation keys or console credentials between these environments. `.env`, generated runtime output, database volumes and backups remain untracked.

## Local prerequisites

- Docker Desktop with Docker Compose;
- Node.js only when the TypeScript authoritative runtime is introduced;
- the pinned Nakama Godot client only after the local server passes health, authentication and protocol smoke tests.

Docker/Compose is not currently available on the development host, so no unverified compose stack or downloaded client add-on is committed in this batch. The next infrastructure action is to install Docker Desktop, reproduce the official PostgreSQL quickstart with the pinned versions, then add the minimal clock and character RPC runtime with integration tests.

The game remains `offline`, `local_only` and device-authoritative until those integration tests pass. See `Notes/ONLINE_BACKEND_DECISION_2026-08-29.md` and `Notes/BACKEND_VERTICAL_SLICE_CONTRACT.md`.
