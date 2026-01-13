# 🛡️ Public Server Bootstrap Script

A **production-grade initialization script** for Ubuntu-based public servers such as **VPS, VDS, and cloud instances**.
Designed for engineers who want a **clean, fast, and secure system** from the very first minute.

This project focuses on three things only:

> **Security. Performance. Reliability.**

No bloat. No magic. Just solid engineering.

---

## 🎯 Purpose

This script automates the complete base setup of a freshly installed Ubuntu server by handling:

* System updates and base configuration
* Docker environment preparation
* Kernel and network performance tuning
* SSH protection with Fail2Ban
* Optional IPv6 deactivation
* Automatic reboot after completion

Perfect for:

* Public-facing servers
* Production VMs
* Cloud instances
* Edge and gateway systems

---

## ✨ Key Features

* One-command full system bootstrap
* Clean and deterministic configuration
* Modern TCP stack tuning with **BBR**
* High file descriptor limits for heavy workloads
* Hardened SSH access with Fail2Ban
* Docker + Docker Compose ready out of the box
* Zero-interaction installation (fully automated)

---

## 📦 What Gets Installed

### Core Utilities

* `vim`, `nano`, `wget`, `curl`, `jq`
* `net-tools`, `bzip2`, `locales`

### Security

* `ufw`
* `fail2ban`

### Container Stack

* `docker.io`
* Latest **Docker Compose** (fetched from GitHub releases)

### Performance Tools

* `ethtool`
* `cpufrequtils`
* `iproute2`

---

## ⚡ Quick Start

```bash
chmod +x setup.sh
sudo ./setup.sh
```

That’s it.
The system will reboot automatically when everything is ready.

---

## ⚙️ Default System Configuration

### Time & Locale

* **Timezone:** `Europe/Istanbul`
* **Locale:** `en_US.UTF-8`

### File Limits

```
* soft nofile 65535
* hard nofile 65535
```

### Network & Kernel Tuning

The script applies a balanced performance profile:

* Increased socket buffers
* Higher backlog limits
* Optimized TCP memory settings
* **BBR congestion control enabled**
* Optional IPv6 deactivation

Result:
Lower latency, higher throughput, better stability under load.

---

## 🔐 Security Model

### SSH Protection with Fail2Ban

* Monitors `/var/log/auth.log`
* Tracks failed SSH login attempts
* **2 failures within 10 minutes → permanent ban**
* Zero tolerance for brute-force attacks

This setup is intentionally strict and designed for **public servers**.

---

## 🧩 Customization

The script is intentionally simple to modify.
You can safely adapt:

* DNS servers
* Sysctl tuning values
* Fail2Ban thresholds
* IPv6 enable/disable logic
* Package list

Everything is transparent. No hidden logic.

---

## 🧾 Requirements

* Ubuntu **22.04 LTS** or newer
* Root or sudo privileges
* Active internet connection during installation

---

## 🏗️ Design Philosophy

This project follows a few clear principles:

* **Deterministic over dynamic**
* **Explicit over implicit**
* **Minimal over bloated**
* **Battle-tested over trendy**

It is not a “do everything” script.
It is a **do the important things right** script.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
You are free to use, modify, and distribute it in personal or commercial projects.

---

## 🤝 Support & Contributions

Found a bug? Have an idea? Want to improve it?

You can:

* Open an **Issue**
* Send a **Pull Request**
* Or contact directly

📧 **[akin.bicer@outlook.com.tr](mailto:akin.bicer@outlook.com.tr)**
