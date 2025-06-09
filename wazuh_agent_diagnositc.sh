#!/bin/bash

echo "=== [1/5] Checking if agent is running..."
sudo systemctl is-active wazuh-agent

echo -e "\n=== [2/5] Checking if auth.log contains recent login events..."
sudo grep 'session opened' /var/log/auth.log | tail -n 5

echo -e "\n=== [3/5] Checking if /var/log/auth.log is included in ossec.conf..."
sudo grep -A2 '<location>/var/log/auth.log</location>' /var/ossec/etc/ossec.conf || echo "auth.log not configured"

echo -e "\n=== [4/5] Tailing agent logs (last 10 lines)..."
sudo tail -n 10 /var/ossec/logs/ossec.log

echo -e "\n=== [5/5] Check this on the Wazuh manager to confirm alert flow:"
echo "    sudo tail -n 10 /var/ossec/logs/alerts/alerts.json"
echo "    If nothing appears there, check that Filebeat is working and that Wazuh rules are enabled."
