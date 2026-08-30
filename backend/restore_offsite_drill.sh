#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ "$#" -ne 1 || ! "$1" =~ ^staging-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z$ ]]; then
  echo "Usage: $0 staging-YYYY-MM-DDTHH-MM-SSZ" >&2
  exit 2
fi

archive_name="$1"
backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_path="${BORG_CONFIG_PATH:-/home/cgdeploy/.config/crooked-galaxy/offsite-backup.env}"

if [[ ! -r "${config_path}" ]]; then
  echo "Offsite backup configuration is missing or unreadable: ${config_path}" >&2
  exit 1
fi
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

recovery_root="$(mktemp -d -t cg-offsite-restore-XXXXXXXX)"
recovered_dump=""
recovered_checksum=""
drill_dump=""
drill_checksum=""
cleanup() {
  if [[ -n "${drill_dump}" ]]; then rm -f -- "${drill_dump}"; fi
  if [[ -n "${drill_checksum}" ]]; then rm -f -- "${drill_checksum}"; fi
  rm -rf -- "${recovery_root}"
}
trap cleanup EXIT

(
  cd "${recovery_root}"
  borg extract "::${archive_name}"
)

mapfile -t dump_candidates < <(find "${recovery_root}" -type f -name 'nakama-staging-????????T??????Z.dump')
if [[ "${#dump_candidates[@]}" -ne 1 ]]; then
  echo "Expected exactly one PostgreSQL dump in the recovered archive." >&2
  exit 1
fi
recovered_dump="${dump_candidates[0]}"
recovered_checksum="${recovered_dump}.sha256"
if [[ ! -f "${recovered_checksum}" ]]; then
  echo "Recovered checksum companion is missing." >&2
  exit 1
fi
(cd "$(dirname "${recovered_dump}")" && sha256sum --check --strict "$(basename "${recovered_checksum}")")

run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
drill_dump="${backend_root}/backups/offsite-recovery-${run_id}.dump"
drill_checksum="${drill_dump}.sha256"
install -m 0600 "${recovered_dump}" "${drill_dump}"
digest="$(sha256sum "${drill_dump}" | cut -d' ' -f1)"
printf '%s  %s\n' "${digest}" "$(basename "${drill_dump}")" > "${drill_checksum}"

pwsh -NoLogo -NoProfile -File "${backend_root}/restore_drill.ps1" -BackupPath "${drill_dump}"
echo "PASS: offsite archive downloaded, checksummed and restored in isolation: ${archive_name}"
