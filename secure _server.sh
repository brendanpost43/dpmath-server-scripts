#!/bin/bash

# === CONFIG ===
SSH_PORT=22   # Change if you're using a custom SSH port
# ==============

echo "Starting server hardening process..."

# Step 1: Update package lists
echo "Updating packages..."
sudo apt update -y

# Step 2: Install UFW and Fail2Ban
echo "Installing UFW and Fail2Ban..."
sudo apt install ufw fail2ban -y

# Step 3: Enable UFW with basic rules
echo "Configuring UFW rules..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ${SSH_PORT}/tcp

echo "Enabling UFW..."
sudo ufw --force enable


# Step 4: Enable and start Fail2Ban
echo "Starting Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Optional: Print current UFW rules
echo "UFW status:"
sudo ufw status verbose

echo "Server hardening complete."
