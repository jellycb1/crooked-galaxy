#!/usr/bin/env bash
set -euo pipefail
umask 077

backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_path="${BORG_CONFIG_PATH:-/home/cgdeploy/.config/crooked-galaxy/offsite-backup.env}"
lock_path="${CG_BACKUP_LOCK_PATH:-/home/cgdeploy/.local/state/crooked-galaxy/offsite-backup.lock}"

if [[ ! -r "${config_path}" ]]; then
  echo "Offsite backup configuration is missing or unreadable: ${config_path}" >&2
  exit 1
fi

# This operator-owned file contains the repository address and the passphrase
# command. It must remain mode 0600 and outside Git.
set -a
# shellcheck disable=SC1090
source "${config_path}"
set +a

for required_name in BORG_REPO BORG_PASSCOMMAND BORG_RSH; do
  if [[ -z "${!required_name:-}" ]]; then
    echo "Required Borg setting is missing: ${required_name}" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "${lock_path}")"
exec 9>"${lock_path}"
if ! flock -n 9; then
  echo "Another Crooked Galaxy offsite backup is already running." >&2
  exit 75
fi

pwsh -NoLogo -NoProfile -File "${backend_root}/backup_staging.ps1"

backup_root="${backend_root}/backups"
newest_dump="$(find "${backup_root}" -maxdepth 1 -type f -name 'nakama-staging-????????T??????Z.dump' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)"
if [[ -z "${newest_dump}" || ! -f "${newest_dump}.sha256" ]]; then
  echo "The new staging dump or its checksum companion is missing." >&2
  exit 1
fi

dump_name="$(basename "${newest_dump}")"
checksum_name="${dump_name}.sha256"
(cd "${backup_root}" && sha256sum --check --strict "${checksum_name}")

archive_name="staging-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
(
  cd "${backup_root}"
  borg create \
    --compression zstd,6 \
    --comment "Crooked Galaxy staging PostgreSQL dump ${dump_name}" \
    "::${archive_name}" \
    "./${dump_name}" \
    "./${checksum_name}"
)

# Retention is applied only after the new, checksummed archive succeeds.
borg prune --list --prefix 'staging-' --keep-daily 14 --keep-weekly 8 --keep-monthly 12
borg compact
borg info "::${archive_name}" >/dev/null

echo "PASS: encrypted offsite archive created and verified: ${archive_name}"
