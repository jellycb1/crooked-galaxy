# Nakama TLS staging runbook

Status: active operations contract. The Hetzner CX33 exists at `2.29.2.190`, and `staging-api.crookedgalaxy.com` resolves to it. Ubuntu 24.04, the key-only `cgdeploy` administration path, Docker/Compose, PowerShell, automatic updates, bounded container logs, the Cloud Firewall, the complete application stack and public TLS are validated. The dedicated Falkenstein Storage Box now holds encrypted, checksummed archives; repository verification, a complete isolated restore and the daily systemd execution passed. Exact evidence is recorded in `STAGING_OFFSITE_BACKUP_EVIDENCE_2026-08-30.md`.

## Purpose and boundary

Staging exists to exercise the exact server and Godot protocol across a real public TLS boundary using disposable accounts. It is never a production database and never validates real purchases. Local, staging and production must use different databases, encryption keys, client keys, console credentials, certificate state and backups.

The checked-in topology pins PostgreSQL 16.8, Nakama 3.40.0, runtime types 1.47.0, the official Godot client 3.4.0 and Caddy 2.11.4-alpine. Caddy is additionally pinned to the reviewed multi-platform image digest. PostgreSQL has no host port. Nakama port 7350 is internal; console 7351 is loopback-only and must be reached through an authenticated SSH tunnel. Caddy alone owns public 80/tcp, 443/tcp and 443/udp.

## Host prerequisites

- One disposable Hetzner Cloud CX33 x86 server in Helsinki, running Ubuntu 24.04 LTS, current Docker Engine, Compose and PowerShell 7 (`pwsh`) for the checked-in operational scripts. Helsinki is the selected currently available CX33 location; do not silently substitute a smaller host merely to obtain another region.
- An A record for `staging-api.crookedgalaxy.com` pointing at `2.29.2.190`. Add IPv6 only after its exact host address is configured and tested; the assigned `/64` prefix alone is not an AAAA value.
- Inbound 80/tcp and 443/tcp; 443/udp is optional HTTP/3. Never expose 5432, 7350 or 7351 publicly.
- A stateful Hetzner Cloud Firewall: SSH restricted to the operator source whenever practical; 80/tcp, 443/tcp and optional 443/udp public; all other inbound traffic denied.
- Restricted SSH key access, automatic security updates and adequate disk monitoring.
- A separate Hetzner Storage Box in Falkenstein with SSH-key access for encrypted Borg archives. It is off-host and cross-region recovery, not a mounted PostgreSQL data volume. Hetzner server snapshots/backups supplement this copy but never replace database dumps and restore drills.
- A real operator e-mail for ACME expiry/problem notices.

## Validated host bootstrap

Run `backend/bootstrap_hetzner_staging.sh` only from the initial root key session. It updates Ubuntu, creates `cgdeploy`, installs the official Docker and Microsoft packages, disables password authentication and retains root key access only for the validation window. Open a separate `cgdeploy` session and prove key login, non-interactive sudo, Docker and `sshd -t` before running `backend/finalize_hetzner_ssh.sh` through `cgdeploy` sudo. The finalizer refuses a direct root invocation and leaves `AllowUsers cgdeploy` plus `PermitRootLogin no`. Keep the Hetzner Rescue path available for break-glass recovery; do not weaken the checked-in policy to recover an operator workstation.

Caddy automatic HTTPS requires correct DNS, externally reachable ports 80/443 and persistent writable certificate storage. Do not start staging with a production hostname, reuse the local `.env`, disable TLS verification, or put credentials in shell history, tickets or chat.

The validated Cloud Firewall named `crooked-galaxy-staging` is applied to the CX33. Its inbound rules are TCP 22, TCP 80, TCP 443 and UDP 443 for both IP families; all unspecified inbound traffic is dropped and outbound traffic remains allowed. SSH is key-only with direct root login disabled. Restrict port 22 to a stable operator CIDR later if one becomes available, but never apply an unverified transient address that could remove the only normal administration path.

## First deployment

1. Clone the reviewed commit on the staging host.
2. Run `pwsh backend/prepare_staging_env.ps1` with the dedicated DNS hostname and operator e-mail. The ignored file is created once with independent 256-bit values and none are printed.
3. Run `pwsh backend/validate_staging.ps1`. Inspect `docker compose ... config --services` if the service set differs from `postgres`, `nakama`, `caddy`.
4. Confirm the host firewall and cloud security group expose only SSH plus 80/443.
5. Start the staging compose project and wait for PostgreSQL and Nakama health checks.
6. Verify Caddy obtained a publicly trusted certificate, then run `backend/test_staging.ps1` from outside the host/network.
7. Inspect startup logs for one Crooked Galaxy runtime registration, migration success, certificate success and no default-key warnings.

Do not place the staging endpoint in `server_rules.gd` or the normal Android configuration. Desktop normal-boot validation uses process-only environment values. Physical Android validation uses `backend/test_android_staging_boot.ps1`: it installs the debug APK in place, obtains the client key over SSH, streams a five-minute configuration through `run-as` into the app-private `user://` mailbox, and launches the ordinary main scene. The game deletes that mailbox before parsing or networking, disables all real-save persistence for the probe, and exits after sanitized evidence. The physical execution itself remains a gate until a USB-authorized device is attached.

## Deploy and rollback discipline

Before every runtime or database change, create a verified dump with `backup_staging.ps1`, run `restore_drill.ps1` against that dump, and copy the dump plus SHA-256 to protected off-host storage. The drill creates a random isolated PostgreSQL container/volume, performs a complete error-stopping restore, verifies the public schema and removes only those exact disposable resources. Record commit, image digests, UTC deployment time and smoke-test result. Deploy one reviewed commit, rebuild, wait for health, then rerun the public test.

For the selected all-Hetzner arrangement, “off-host” means the independent Storage Box, not another directory or attached volume on the CX33. Borg uses repository encryption and an explicit remote version over Storage Box SSH port 23. The automated transfer, archive verification, download and isolated restore gate have passed; keep rerunning the drill after relevant operational changes. The recovery key must remain protected outside both services.

The checked-in `backup_offsite_borg.sh` runs the local dump transaction, validates its checksum, creates one encrypted Borg archive, applies retention only after success, compacts the repository and confirms the new archive. Retention is 14 daily, 8 weekly and 12 monthly recovery points. `restore_offsite_drill.sh <archive>` downloads one archive into a unique temporary directory, verifies its checksum and invokes the existing isolated PostgreSQL restore drill. Neither script accepts a live database as a restore destination.

The operator-owned `/home/cgdeploy/.config/crooked-galaxy/offsite-backup.env` and passphrase file are mode `0600`, outside Git and readable only by `cgdeploy`. The private SSH key is dedicated to this Storage Box. The Borg recovery key export and passphrase require an independently protected copy outside both the CX33 and the Storage Box; losing both makes encrypted archives unrecoverable. The systemd timer runs daily at 03:20 UTC with up to 45 minutes of jitter and persistent catch-up after downtime. Inspect `systemctl status crooked-galaxy-offsite-backup.service` and the journal after failures; never suppress failed runs.

A rollback means restoring the previous reviewed commit and compatible runtime image. Database rollback is never inferred from a code rollback. If a migration changed stored data, stop writes and use the rehearsed isolated-restore evidence before planning restoration of the actual service. Never run `pg_restore` over the active staging or production database.

## Evidence required before APK activation

- Public certificate chain and hostname pass on the Android 15 Pixel 9 AVD without installing a private CA; repeat on unmanaged physical Android when one becomes available.
- Authentication, session refresh/expiry, character creation and snapshot ownership pass across app restart.
- Read-only cache opens only after a previously acknowledged snapshot; economy, Agency and billing remain unavailable offline.
- Same-command retry after simulated timeout produces one mutation; stale revision produces visible conflict recovery.
- Database backup is copied off-host and restored into an isolated disposable database.
- Logs contain request correlation without credentials or full player payloads.
- Existing internal local-save treatment is explicitly decided and tested; no automatic field merge exists.

Only after all evidence is recorded may account, clock and profile flags be considered independently. Agency, Arena, rankings and billing remain separate later gates.

## Physical Android staging command

Prerequisites are PowerShell 7, the existing protected SSH operator identity, Android SDK Platform-Tools, and exactly one physical device with USB debugging authorized. From the repository root run:

```powershell
pwsh ./backend/test_android_staging_boot.ps1
```

The default path first runs the complete Android export gate, then performs `adb install -r`; it never uninstalls the package or clears application data. Use `-SkipBuild` only when the current local APK has already passed that exact gate. `-Serial` selects one device when several are attached, and emulators are rejected unless `-AllowEmulator` is explicit. A timeout or any probe failure leaves sanitized `logcat.txt`, package metadata and device metadata under the ignored evidence directory. The cleanup block removes the exact mailbox on both success and failure and clears the key and payload variables.

## Official operating references

- Heroic Labs Docker deployment and server configuration: <https://heroiclabs.com/docs/nakama/getting-started/configuration/docker-configuration/> and <https://heroiclabs.com/docs/nakama/getting-started/configuration/>.
- Caddy reverse proxy and automatic HTTPS: <https://caddyserver.com/docs/caddyfile/directives/reverse_proxy> and <https://caddyserver.com/docs/automatic-https>.
- Official Caddy container image: <https://hub.docker.com/_/caddy/>.
- Hetzner Storage Box SSH/rsync/Borg access and cloud backup semantics: <https://docs.hetzner.com/storage/storage-box/access/access-ssh-rsync-borg/> and <https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/>.
- Hetzner Cloud Firewall behavior: <https://docs.hetzner.com/cloud/firewalls/faq/>.
