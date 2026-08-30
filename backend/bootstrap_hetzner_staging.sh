#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this bootstrap as root." >&2
  exit 1
fi

source /etc/os-release
if [[ "${ID}" != "ubuntu" || "${VERSION_ID}" != "24.04" || "$(uname -m)" != "x86_64" ]]; then
  echo "Expected Ubuntu 24.04 x86_64." >&2
  exit 1
fi
if [[ ! -s /root/.ssh/authorized_keys ]]; then
  echo "Root authorized_keys is required before creating the deployment user." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get full-upgrade -y
apt-get install -y ca-certificates curl git gnupg jq unattended-upgrades sudo
timedatectl set-timezone UTC

if ! id -u cgdeploy >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash cgdeploy
fi
install -d -m 0700 -o cgdeploy -g cgdeploy /home/cgdeploy/.ssh
install -m 0600 -o cgdeploy -g cgdeploy /root/.ssh/authorized_keys /home/cgdeploy/.ssh/authorized_keys
printf 'cgdeploy ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/90-cgdeploy
chmod 0440 /etc/sudoers.d/90-cgdeploy
visudo -cf /etc/sudoers.d/90-cgdeploy >/dev/null

cat > /etc/ssh/sshd_config.d/90-crooked-galaxy.conf <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
X11Forwarding no
AllowUsers root cgdeploy
EOF
sshd -t
systemctl reload ssh

install -m 0755 -d /etc/apt/keyrings
curl --fail --silent --show-error --location https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' "$(dpkg --print-architecture)" "${VERSION_CODENAME}" > /etc/apt/sources.list.d/docker.list

ms_deb="$(mktemp --suffix=.deb)"
trap 'rm -f "${ms_deb}"' EXIT
curl --fail --silent --show-error --location "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o "${ms_deb}"
dpkg -i "${ms_deb}"

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin powershell
usermod -aG docker cgdeploy
install -d -m 0755 /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "20m",
    "max-file": "5"
  }
}
EOF
systemctl enable --now docker
systemctl restart docker
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "PASS: Ubuntu staging host bootstrapped. Verify cgdeploy SSH before disabling root login."
