#!/bin/bash

# ========== CONFIGURATION ==========
SOC_SERVER="log.math.usu.edu"  # Replace with IP if DNS fails
AGENT_VERSION="4.7.0-1"
DEB_PACKAGE="wazuh-agent_${AGENT_VERSION}_amd64.deb"
DOWNLOAD_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${DEB_PACKAGE}"
# ===================================

echo ">> Installing Wazuh agent..."

# Clean up previous installs if any
sudo systemctl stop wazuh-agent 2>/dev/null
sudo apt remove wazuh-agent -y 2>/dev/null
sudo rm -rf /var/ossec

# Download the .deb package
echo ">> Downloading Wazuh agent..."
wget -q "$DOWNLOAD_URL" -O "$DEB_PACKAGE"

# Check if download was successful
if file "$DEB_PACKAGE" | grep -q "Debian binary package"; then
    echo ">> Download verified. Installing..."
else
    echo "!! ERROR: Downloaded file is not a valid .deb package."
    exit 1
fi

# Install the agent
sudo dpkg -i "$DEB_PACKAGE"
sudo apt-get install -f -y  # Fix dependencies if needed

# Configure the agent to point to your SOC server
echo ">> Configuring agent to report to $SOC_SERVER..."
sudo sed -i "s|<address>.*</address>|<address>$SOC_SERVER</address>|" /var/ossec/etc/ossec.conf

# Enable and start the agent
echo ">> Enabling and starting wazuh-agent..."
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Final check
echo ">> Status of wazuh-agent:"
sudo systemctl status wazuh-agent --no-pager

echo "✅ Installation complete."
