#!/bin/bash

# Script to fix volume permissions for monitoring stack
# This script should be run as root or with sudo

echo "Fixing volume permissions for monitoring stack..."

# Create directories if they don't exist
sudo mkdir -p /data/db/prometheus
sudo mkdir -p /data/db/loki
sudo mkdir -p /data/db/grafana
sudo mkdir -p /data/db/alertmanager
sudo mkdir -p /data/db/promtail

# Set ownership to UID 999 (what the containers expect)
sudo chown -R 999:999 /data/db/prometheus
sudo chown -R 999:999 /data/db/loki
sudo chown -R 999:999 /data/db/grafana
sudo chown -R 999:999 /data/db/alertmanager
sudo chown -R 999:999 /data/db/promtail

# Set proper permissions
sudo chmod -R 755 /data/db/prometheus
sudo chmod -R 755 /data/db/loki
sudo chmod -R 755 /data/db/grafana
sudo chmod -R 755 /data/db/alertmanager
sudo chmod -R 755 /data/db/promtail

echo "Permissions fixed. You can now restart the containers."
echo "Run: docker-compose down && docker-compose up -d"


