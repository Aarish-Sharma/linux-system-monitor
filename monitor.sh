#!/bin/bash
# monitor.sh - Basic system health check with email alerts
# Monitors CPU load, RAM, disk on Ubuntu 24.04
# Alerts via Gmail/msmtp if thresholds exceeded
# Runs as systemd timer every 15 min
# GitHub: github.com/Aarish-Sharma/system-monitor-script

# ================= CONFIG =================
ADMIN_EMAIL="YOUR@gmail.com"                
ALERT_CPU_PCT=80                            
ALERT_RAM_PCT=90                            
ALERT_DISK_PCT=90                           
LOGFILE="/var/log/system-monitor.log"       

HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log file exists and is writable (run once with sudo if needed)
if [ ! -f "$LOGFILE" ]; then
    sudo touch "$LOGFILE"
    sudo chmod 644 "$LOGFILE"
    sudo chown $USER:$USER "$LOGFILE"   
fi

# ================= COLLECT METRICS =================

# CPU: 1-min load average, compare to % of cores
CORES=$(nproc --all)
LOAD1=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
LOAD_PCT=$(echo "scale=2; ($LOAD1 / $CORES) * 100" | bc)
echo "CPU Load (1-min): $LOAD1 on $CORES cores → ${LOAD_PCT}%"

# RAM: used percentage (free -m style)
RAM_USED=$(free -m | awk '/Mem:/ {printf "%.0f", $3*100/$2}')
echo "RAM Used: $RAM_USED%"

# Disk: root filesystem used %
DISK_USED=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
echo "Disk / Used: $DISK_USED%"

# ================= ALERT LOGIC =================
ALERTS=""

if (( $(echo "$LOAD_PCT > $ALERT_CPU_PCT" | bc -l) )); then
    ALERTS+="HIGH CPU LOAD: ${LOAD_PCT}% (threshold ${ALERT_CPU_PCT}% of cores)\n"
fi

if [ "$RAM_USED" -ge "$ALERT_RAM_PCT" ]; then
    ALERTS+="HIGH RAM USAGE: ${RAM_USED}% (threshold ${ALERT_RAM_PCT}%)\n"
fi

if [ "$DISK_USED" -ge "$ALERT_DISK_PCT" ]; then
    ALERTS+="HIGH DISK USAGE on /: ${DISK_USED}% (threshold ${ALERT_DISK_PCT}%)\n"
fi

# ================= OUTPUT & ALERT =================
{
    echo "=== System Health Check @ $DATE on $HOSTNAME ==="
    echo "CPU Load (1-min): $LOAD1 on $CORES cores → ${LOAD_PCT}%"
    echo "RAM Used: $RAM_USED%"
    echo "Disk / Used: $DISK_USED%"
    if [ -n "$ALERTS" ]; then
        echo -e "\n*** ALERTS TRIGGERED ***"
        echo -e "$ALERTS"
        # Send email alert
        {
            echo "Subject: [ALERT] $HOSTNAME - System Resource Warning"
            echo ""
            echo "Host: $HOSTNAME"
            echo "Time: $DATE"
            echo ""
            echo "Alerts:"
            echo -e "$ALERTS"
            echo ""
            echo "Full metrics:"
            echo "CPU: ${LOAD_PCT}%"
            echo "RAM: ${RAM_USED}%"
            echo "Disk: ${DISK_USED}%"
        } | msmtp -a gmail "$ADMIN_EMAIL"
    else
        echo "All resources within limits."
    fi
    echo "=== End ==="
    echo ""
} >> "$LOGFILE" 2>&1
