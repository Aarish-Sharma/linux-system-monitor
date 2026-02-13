# 🖥️ Linux System Resource Monitor

A lightweight, production-ready Bash script that continuously monitors **CPU load**, **RAM usage**, and **root disk space** on Linux systems — with persistent logging and real-time email alerts when thresholds are exceeded.

---

## ✨ Features

- **CPU monitoring** — 1-minute load average, dynamically scaled to available cores
- **RAM monitoring** — usage as a percentage of total memory
- **Disk monitoring** — root filesystem (`/`) usage percentage
- **Smart alerting** — Gmail alerts via `msmtp`, sent only when thresholds are crossed (no noise on normal operation)
- **Persistent logging** — all results written to `/var/log/system-monitor.log`
- **Fully automated** — runs every 15 minutes via a systemd timer, no cron needed
- **Minimal footprint** — depends only on standard Ubuntu tools + `msmtp`

---

## 🧰 Prerequisites

- Ubuntu 24.04 (or similar Debian-based distro)
- A Gmail account with an [App Password](https://support.google.com/accounts/answer/185833) configured
- `sudo` access

---

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install msmtp msmtp-mta mailutils ca-certificates -y
```

---

### 2. Configure Gmail (msmtp)

Create `~/.msmtprc` with the following content, substituting your own Gmail address and app password:

```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           yourgmail@gmail.com
user           yourgmail@gmail.com
password       your_app_password_here

account default : gmail
```

Then secure the file:

```bash
chmod 600 ~/.msmtprc
```

> **Note:** A standard Gmail password will not work here. You must generate an [App Password](https://support.google.com/accounts/answer/185833) in your Google account security settings.

---

### 3. Copy & Prepare the Script

```bash
mkdir -p ~/scripts
cp monitor.sh ~/scripts/
cd ~/scripts
chmod +x monitor.sh
```

---

### 4. Deploy the systemd Units

```bash
sudo cp systemd/system-monitor.service /etc/systemd/system/
sudo cp systemd/system-monitor.timer   /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now system-monitor.timer
```

---

### 5. Verify It's Running

```bash
# Check the timer status
systemctl status system-monitor.timer

# List all active timers
systemctl list-timers --all

# Tail the live log
tail -f /var/log/system-monitor.log
```

---

## 📁 Project Structure

```
.
├── monitor.sh                        # Main monitoring script
├── systemd/
│   ├── system-monitor.service        # systemd service unit
│   └── system-monitor.timer          # systemd timer unit (15-min interval)
└── README.md
```

---

## ⚙️ Configuration

Thresholds and alert recipients can be customized at the top of `monitor.sh`:

| Variable         | Default | Description                        |
|------------------|---------|------------------------------------|
| `CPU_THRESHOLD`  | `80`    | CPU load % that triggers an alert  |
| `RAM_THRESHOLD`  | `85`    | RAM usage % that triggers an alert |
| `DISK_THRESHOLD` | `90`    | Disk usage % that triggers an alert|
| `ALERT_EMAIL`    | —       | Recipient email for alerts         |

---

## 📋 Log Format

Entries are appended to `/var/log/system-monitor.log` on every run:

```
[2025-06-01 14:15:02] CPU: 23% | RAM: 61% | Disk: 45%
[2025-06-01 14:30:01] CPU: 91% | RAM: 62% | Disk: 45% ⚠️ ALERT SENT
```

---

## 🔒 Security Notes

- Store your msmtp credentials in `~/.msmtprc` with `chmod 600` — never commit this file to version control
- Add `.msmtprc` and `*.log` to your `.gitignore`
- Consider using a dedicated Gmail account for sending alerts

---
