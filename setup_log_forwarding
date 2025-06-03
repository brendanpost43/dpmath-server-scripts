#!/bin/bash

# ========= CONFIG =========
LOG_SERVER_HOST="129.123.40.35"   # Change to your actual log server hostname or IP
LOG_SERVER_PORT="514"
USE_TCP=true  # Set to false to use UDP
# ==========================

echo "[+] Installing rsyslog if not already installed..."
sudo apt update
sudo apt install -y rsyslog

# Choose protocol prefix
if [ "$USE_TCP" = true ]; then
    FORWARD_DIRECTIVE="*.* @@$LOG_SERVER_HOST:$LOG_SERVER_PORT"
else
    FORWARD_DIRECTIVE="*.* @$LOG_SERVER_HOST:$LOG_SERVER_PORT"
fi

echo "[+] Updating rsyslog config to forward logs to $LOG_SERVER_HOST..."

# Add forwarding rule to rsyslog.conf (if not already present)
if ! grep -q "$LOG_SERVER_HOST" /etc/rsyslog.conf; then
    echo -e "\n# Remote logging to central log server\n$FORWARD_DIRECTIVE" | sudo tee -a /etc/rsyslog.conf
else
    echo "[=] Log forwarding rule already exists. Skipping append."
fi

echo "[+] Restarting rsyslog service..."
sudo systemctl restart rsyslog
sudo systemctl enable rsyslog

echo "[✔] Log forwarding configured. Test with: logger 'Test message from $(hostname)'"
