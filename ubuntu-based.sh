#!/bin/bash

set -e

#############################################################
# Configuration Variables
#############################################################
TIMEZONE="Europe/Istanbul"
LOCALE="en_US.UTF-8"
DOCKER_COMPOSE_DEST="/usr/local/bin/docker-compose"
SYSCTL_CUSTOM_FILE="/etc/sysctl.d/99-champion.conf"
JAIL_FILE="/etc/fail2ban/jail.local"
ULIMIT_CONFIG="/etc/security/limits.conf"
DNS1="1.1.1.3"
DNS2="1.0.0.3"

#############################################################
# Color Codes for Output
#############################################################
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

#############################################################
# Check for root privileges
#############################################################
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Root privileges are required.${NC}"
  exit 1
fi

#############################################################
# Display Banner
#############################################################
clear
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}       CHAMPION EDITION v8 (REAL LOW-LATENCY + RPS)         ${NC}"
echo -e "${GREEN}============================================================${NC}"
sleep 3

#############################################################
# Update and Upgrade System
#############################################################
echo -e "${BLUE}Updating and upgrading system packages...${NC}"
apt update && apt full-upgrade --auto-remove --purge -y

#############################################################
# Install Base Packages
#############################################################
echo -e "${BLUE}Installing base packages...${NC}"
DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE apt-get install -y tzdata
apt-get install -y vim nano wget net-tools locales bzip2 wmctrl software-properties-common \
    jq curl apt-transport-https ca-certificates ufw fail2ban ethtool cpufrequtils \
    iproute2 htop iotop iftop conntrack build-essential docker.io linux-lowlatency fastfetch

#############################################################
# Configure Locale
#############################################################
echo -e "${BLUE}Configuring system locale to ${LOCALE}...${NC}"
locale-gen $LOCALE
systemctl enable --now docker

#############################################################
# Set Timezone
#############################################################
echo -e "${BLUE}Setting timezone to ${TIMEZONE}...${NC}"
timedatectl set-timezone $TIMEZONE
timedatectl set-ntp true
timedatectl status

#############################################################
# Configure DNS
#############################################################
echo -e "${BLUE}Configuring DNS settings...${NC}"
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
apt-get purge -y systemd-resolved 2>/dev/null || true

if [ -f /etc/resolv.conf ]; then
  lsattr /etc/resolv.conf 2>/dev/null | grep -q '\-i\-' && chattr -i /etc/resolv.conf
fi

rm -f /etc/resolv.conf
echo -e "nameserver $DNS1\nnameserver $DNS2" > /etc/resolv.conf
chattr +i /etc/resolv.conf

#############################################################
# Disable Swap
#############################################################
echo -e "${BLUE}Disabling swap...${NC}"
swapoff -a
sed -i '/swap/d' /etc/fstab

#############################################################
# Download Docker Compose
#############################################################
echo -e "${BLUE}Downloading Docker Compose...${NC}"
VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_COMPOSE_DEST
chmod +x $DOCKER_COMPOSE_DEST

#############################################################
# Configure security limit parameters
#############################################################
echo -e "${BLUE}Configuring security limit parameters...${NC}"
cat > $ULIMIT_CONFIG <<EOF
root soft nofile 100000000
root hard nofile 100000000
* soft nofile 100000000
* hard nofile 100000000
EOF
mkdir -p /etc/systemd/system.conf.d
echo -e "[Manager]\nDefaultLimitNOFILE=100000000\nDefaultLimitNPROC=infinity" > /etc/systemd/system.conf.d/limits.conf
systemctl daemon-reexec

#############################################################
# Configure sysctl parameters
#############################################################
echo -e "${BLUE}Configuring sysctl parameters...${NC}"
cat > $SYSCTL_CUSTOM_FILE <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
kernel.pid_max = 4194304
fs.file-max = 100000000
fs.nr_open = 100000000
vm.swappiness = 0
vm.dirty_ratio = 80
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 300000
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.optmem_max = 67108864
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 87380 67108864
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_mtu_probing = 1
net.netfilter.nf_conntrack_max = 2000000
EOF
sysctl --system

#############################################################
# Configure GRUB for low latency
#############################################################
echo -e "${BLUE}Configuring GRUB for low latency...${NC}"
if [ -f /etc/default/grub ]; then
  cp /etc/default/grub /etc/default/grub.bak
  EXTRA_ARGS="audit=0 mitigations=off nohz=on skew_tick=1 idle=poll apparmor=0"
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
  sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\"/GRUB_CMDLINE_LINUX_DEFAULT=\"${EXTRA_ARGS}\"/" /etc/default/grub
  update-grub || true
fi

#############################################################
# Set CPU Governor to Performance
#############################################################
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl restart cpufrequtils || true

#############################################################
# Configure Network Wait Online Timeout
#############################################################
mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
echo -e "[Service]\nExecStart=\nExecStart=/lib/systemd/systemd-networkd-wait-online --timeout=5" > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
systemctl daemon-reload

#############################################################
# Configure Network Interface for Low Latency and RPS
#############################################################
echo -e "${BLUE}Configuring network interface for low latency and RPS...${NC}"
systemctl disable --now irqbalance 2>/dev/null || true
IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

if [ -n "$IFACE" ]; then
  RX_MAX=$(ethtool -g "$IFACE" 2>/dev/null | awk '/RX:/ {print $2; exit}')
  TX_MAX=$(ethtool -g "$IFACE" 2>/dev/null | awk '/TX:/ {print $2; exit}')
  [ -n "$RX_MAX" ] && [ -n "$TX_MAX" ] && ethtool -G "$IFACE" rx "$RX_MAX" tx "$TX_MAX" || true

  ethtool -K "$IFACE" tso on gso on gro on sg on rx on tx on || true
  ip link set dev "$IFACE" txqueuelen 10000

  if [ -f /sys/class/net/$IFACE/queues/rx-0/rps_cpus ]; then
    echo "f" > /sys/class/net/$IFACE/queues/rx-0/rps_cpus || true
  fi
  if [ -f /sys/class/net/$IFACE/queues/rx-0/rps_flow_cnt ]; then
    echo 4096 > /sys/class/net/$IFACE/queues/rx-0/rps_flow_cnt || true
  fi

  sysctl -w net.core.rps_sock_flow_entries=32768 || true
fi

#############################################################
# Configure Fail2Ban
#############################################################
echo -e "${BLUE}Configuring Fail2Ban...${NC}"
cat > $JAIL_FILE <<EOF
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
systemctl enable --now fail2ban

#############################################################
# Cleanup Unnecessary Services
#############################################################
systemctl stop snapd 2>/dev/null || true
apt-get purge -y snapd 2>/dev/null || true
rm -rf /snap /var/cache/snapd
systemctl disable --now avahi-daemon 2>/dev/null || true
systemctl disable --now bluetooth 2>/dev/null || true
apt-get autoremove --purge -y
apt-get clean -y
history -c
rm -f .bash_history

#############################################################
# Final Message and Reboot
#############################################################
echo -e "${GREEN}Setup completed successfully! Please reboot the system to apply all changes.${NC}"
echo -e "${YELLOW}Rebooting in 10 seconds... Press Ctrl+C to cancel.${NC}"
sleep 10
reboot
