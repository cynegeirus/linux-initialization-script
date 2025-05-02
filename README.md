# 🛡️ Public Server Setup Script

This script provides a comprehensive and automated setup process for initializing Ubuntu-based public servers (e.g., VDS/VPS). It focuses on system updates, essential utilities, Docker installation, security hardening, and performance tuning.

## 🚀 Features

- Updates the system packages.
- Configures timezone and locale.
- Installs Docker and Docker Compose.
- Applies kernel and network optimizations (`sysctl`, `ulimit`).
- Disables IPv6 (optional).
- Installs and configures Fail2Ban for SSH brute-force protection.
- Installs the latest generic Linux kernel.
- Reboots the system automatically after setup.

## 🧰 Installed Packages

- `vim`, `nano`, `wget`, `curl`, `jq`, `net-tools`, `bzip2`, `locales`, `ufw`, `fail2ban`, etc.
- `docker.io`
- Latest Docker Compose release (fetched from GitHub)

## ⚙️ Usage

Make the script executable and run it:

```bash
chmod +x setup.sh
./setup.sh
````

> **Note:** The system will reboot automatically at the end of the process.

## 📌 Configuration Details

* **Timezone:** `Europe/Istanbul`
* **Locale:** `en_US.UTF-8`
* **File Descriptor Limits:**

  ```
  * soft nofile 65535
  * hard nofile 65535
  ```
* **Sysctl Settings:**

    * Increases buffer sizes, backlog limits, and enables BBR congestion control.
    * Disables IPv6 (can be removed or edited if required).
* **Fail2Ban:**

    * Monitors SSH login attempts.
    * Blocks IPs permanently after 2 failed attempts within 10 minutes.

## 🔐 Security Tips

* Adjust `fail2ban` ban time and retry limits according to your environment.
* Consider adding UFW firewall rules for further hardening.
* If IPv6 is required, comment or remove the related lines in the script.

## 🧾 Requirements

* Ubuntu 22.04 or later
* Sudo privileges

---

## License

This project is licensed under the [MIT License](LICENSE). See the license file for details.

---

## Issues, Feature Requests or Support

Please use the Issue > New Issue button to submit issues, feature requests or support issues directly to me. You can also send an e-mail to akin.bicer@outlook.com.tr.
