  # Linux System Resource Monitoring Script

A simple, production-ready Bash script that continuously monitors CPU load, RAM usage, and root disk space on Linux systems, logs results, and sends real-time email alerts when thresholds are exceeded.

## Features
- Monitors:
  - CPU load average (1-min, dynamic percentage of available cores)
  - RAM usage (%)
  - Root filesystem usage (%)
- Sends Gmail email alerts via msmtp only when thresholds crossed (no spam on normal operation)
- Persistent logging to `/var/log/system-monitor.log` for historical review
- Fully automated background execution via systemd timer (every 15 minutes)
- Minimal dependencies (standard Ubuntu tools + msmtp)


## Quick Setup (I used Ubuntu 24.04)

1. **Install dependencies**
   ```bash
   sudo apt update
   sudo apt install msmtp msmtp-mta mailutils ca-certificates -y
2. **Configure Gmail (app password required – see msmtp docs)**
    Create ~/.msmtprc:
    defaults
    auth on
    tls on
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile ~/.msmtp.log
    
    account gmail
    host smtp.gmail.com
    port 587
    from yourgmail@gmail.com
    user yourgmail@gmail.com
    password your_app_password_here
    
    account default : gmail
  Secure it:
    chmod 600 ~/.msmtprc
   
3.  **Copy & prepare script**
    mkdir -p ~/scripts
    # Copy monitor.sh here (from repo)
    cd ~/scripts
    chmod +x monitor.sh
4.  **Deploy systemd units**
    sudo cp systemd/system-monitor.service /etc/systemd/system/
    sudo cp systemd/system-monitor.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now system-monitor.timer
5.  **verify**
    systemctl status system-monitor.timer
    systemctl list-timers --all
    tail -f /var/log/system-monitor.log    
    
       
