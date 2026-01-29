#!/bin/bash
set -e

#############################################################
# Configuration Variables
#############################################################
TIMEZONE="Europe/Istanbul"
LOCALE="en_US.UTF-8"
SYSCTL_CUSTOM_FILE="/etc/sysctl.d/99-champion.conf"
JAIL_FILE="/etc/fail2ban/jail.local"
ULIMIT_CONFIG="/etc/security/limits.d/99-champion.conf"
DNS1="1.1.1.3"
DNS2="1.0.0.3"

#############################################################
# Color Codes
#############################################################
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

#############################################################
# Root Check
#############################################################
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Run as root.${NC}"
  exit 1
fi

clear
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   CHAMPION EDITION – DEBIAN 13 (TRIXIE)           ${NC}"
echo -e "${GREEN}==================================================${NC}"
sleep 2

#############################################################
# Update System
#############################################################
echo -e "${BLUE}System update...${NC}"
apt update
apt full-upgrade -y
apt autoremove --purge -y

#############################################################
# Base Packages
#############################################################
echo -e "${BLUE}Installing base packages...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y \
  vim nano curl wget jq ca-certificates \
  locales tzdata net-tools iproute2 ethtool \
  htop iotop iftop conntrack \
  ufw fail2ban \
  build-essential \
  docker.io

systemctl enable --now docker

#############################################################
# Locale & Timezone
#############################################################
echo -e "${BLUE}Configuring locale & timezone...${NC}"
sed -i "s/^# $LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
update-locale LANG=$LOCALE

timedatectl set-timezone $TIMEZONE
timedatectl set-ntp true

#############################################################
# DNS (Debian Safe)
#############################################################
echo -e "${BLUE}Configuring DNS...${NC}"
cat > /etc/resolv.conf <<EOF
nameserver $DNS1
nameserver $DNS2
EOF

#############################################################
# Disable Swap
#############################################################
echo -e "${BLUE}Disabling swap...${NC}"
swapoff -a
sed -i '/swap/d' /etc/fstab

#############################################################
# Limits (SAFE VALUES)
#############################################################
echo -e "${BLUE}Configuring limits...${NC}"
cat > $ULIMIT_CONFIG <<EOF
* soft nofile 1048576
* hard nofile 1048576
EOF

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/limits.conf <<EOF
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitNPROC=infinity
EOF

systemctl daemon-reexec

#############################################################
# Sysctl (BBR + Low Latency)
#############################################################
echo -e "${BLUE}Applying sysctl tuning...${NC}"
cat > $SYSCTL_CUSTOM_FILE <<EOF
net.ipv4.ip_forward=1
vm.swappiness=0
fs.file-max=2097152
net.core.somaxconn=65535
net.core.netdev_max_backlog=250000
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.netfilter.nf_conntrack_max=1048576
EOF

sysctl --system

#############################################################
# GRUB – Debian Friendly
#############################################################
echo -e "${BLUE}Configuring GRUB...${NC}"
cp /etc/default/grub /etc/default/grub.bak

sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet mitigations=off"/' \
  /etc/default/grub

update-grub

#############################################################
# Network Tuning
#############################################################
echo -e "${BLUE}Network tuning...${NC}"

IFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -n "$IFACE" ]; then
  ip link set "$IFACE" txqueuelen 10000
fi

#############################################################
# Fail2Ban
#############################################################
echo -e "${BLUE}Configuring Fail2Ban...${NC}"
cat > $JAIL_FILE <<EOF
[sshd]
enabled = true
maxretry = 3
bantime = 1d
findtime = 10m
EOF

systemctl enable --now fail2ban

#############################################################
# Cleanup
#############################################################
echo -e "${BLUE}Cleaning system...${NC}"
apt clean
history -c || true

#############################################################
# Finish
#############################################################
echo -e "${GREEN}DONE. Reboot required.${NC}"
echo -e "${YELLOW}Rebooting in 10 seconds...${NC}"
sleep 10
reboot
