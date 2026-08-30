#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this finalizer through sudo after validating cgdeploy SSH." >&2
  exit 1
fi
if [[ -z "${SUDO_USER:-}" || "${SUDO_USER}" != "cgdeploy" ]]; then
  echo "Root lock may only be finalized from a verified cgdeploy sudo session." >&2
  exit 1
fi

cat > /etc/ssh/sshd_config.d/90-crooked-galaxy.conf <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
X11Forwarding no
AllowUsers cgdeploy
EOF
sshd -t
systemctl reload ssh
echo "PASS: direct root SSH disabled; cgdeploy public-key access is the administrative path."
