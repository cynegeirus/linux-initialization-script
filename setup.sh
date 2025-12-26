#!/bin/bash
set -e

# -----------------------------
# General Settings
# -----------------------------
TIMEZONE="Europe/Istanbul"
LOCALE="en_US.UTF-8"
DOCKER_COMPOSE_DEST="/usr/bin/docker-compose"
SYSCTL_CUSTOM_FILE="/etc/sysctl.d/99-custom.conf"
JAIL_FILE="/etc/fail2ban/jail.local"
ULIMIT_CONFIG='/etc/security/limits.conf'

# -----------------------------
# Update System
# -----------------------------
echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

# -----------------------------
# Install Essential Packages
# -----------------------------
echo "[+] Installing base packages..."
sudo apt-get update
DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE sudo apt-get install -y tzdata
sudo apt-get install -y \
  vim nano wget net-tools locales bzip2 wmctrl \
  software-properties-common jq curl apt-transport-https \
  ca-certificates ufw fail2ban

sudo locale-gen $LOCALE

# -----------------------------
# Install Docker
# -----------------------------
echo "[+] Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable --now docker

# -----------------------------
# Install Docker Compose
# -----------------------------
echo "[+] Installing Docker Compose..."
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_COMPOSE_DEST
sudo chmod 755 $DOCKER_COMPOSE_DEST

# -----------------------------
# Ulimit Configuration
# -----------------------------
echo "[+] Configuring ulimit..."
sudo tee -a $ULIMIT_CONFIG > /dev/null <<EOF
* soft nofile 65535
* hard nofile 65535
EOF

# -----------------------------
# Sysctl Performance Tuning
# -----------------------------
echo "[+] Applying sysctl performance settings..."
sudo tee $SYSCTL_CUSTOM_FILE > /dev/null <<EOF
fs.file-max = 2097152
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 0
EOF
sudo sysctl --system

# -----------------------------
# Disable IPv6 (Optional)
# -----------------------------
echo "[+] Disabling IPv6..."
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sudo sysctl -p

# -----------------------------
# Configure Fail2Ban (SSH)
# -----------------------------
echo "[+] Configuring Fail2Ban for SSH..."
sudo tee $JAIL_FILE > /dev/null <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 2
bantime = -1
findtime = 600
ignoreip = 127.0.0.1/8
EOF
sudo systemctl enable --now fail2ban

# -----------------------------
# Upgrade Kernel (Optional)
# -----------------------------
echo "[+] Installing latest generic Linux kernel..."
sudo apt install -y linux-generic

# -----------------------------
# Final Step
# -----------------------------
echo "[✓] Setup complete. Rebooting in 5 seconds..."
sleep 5
sudo reboot
