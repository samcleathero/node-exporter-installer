#!/bin/sh -e
VERSION=0.16.0

if [ -x "$(command -v apt-get)" ]; then
    apt-get update
    apt-get -y install wget
elif [ -x "$(command -v yum)" ]; then
    yum -y install wget
else
    echo "No known package manager found" >&2;
    exit 1;
fi

cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${VERSION}.linux-amd64.tar.gz
mkdir -p /opt/node_exporter
mv node_exporter-${VERSION}.linux-amd64/node_exporter /opt/node_exporter/
rm -rf /tmp/node_exporter-${VERSION}.linux-amd64

if [ -x "$(command -v systemctl)" ]; then
    cat << EOF > /lib/systemd/system/node-exporter.service
[Unit]
Description=Prometheus agent
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable node-exporter
    systemctl start node-exporter
elif [ -x "$(command -v initctl)" ]; then
    cat << EOF > /etc/init/node-exporter.conf
start on runlevel [23456]
stop on runlevel [016]
exec /opt/node_exporter/node_exporter
respawn
EOF

    initctl reload-configuration
    initctl start node-exporter
else
    echo "No known service management found" >&2;
    exit 1;
fi