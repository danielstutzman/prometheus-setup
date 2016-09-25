#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF
set -e

id -u blackbox_exporter &>/dev/null || sudo useradd blackbox_exporter
sudo mkdir -p /home/blackbox_exporter
sudo chown blackbox_exporter:blackbox_exporter /home/blackbox_exporter
cd /home/blackbox_exporter
sudo sudo -u blackbox_exporter -s <<EOF2
if [ ! -e blackbox_exporter-0.2.0.linux-amd64.tar.gz ]; then
  curl -L https://github.com/prometheus/blackbox_exporter/releases/download/v0.2.0/blackbox_exporter-0.2.0.linux-amd64.tar.gz > blackbox_exporter-0.2.0.linux-amd64.tar.gz
fi
tar xvzf blackbox_exporter-0.2.0.linux-amd64.tar.gz
EOF2

sudo tee /etc/init/blackbox_exporter.conf <<EOF2
start on startup
setuid blackbox_exporter
setgid blackbox_exporter
chdir /home/blackbox_exporter/blackbox_exporter-0.2.0.linux-amd64
script
  ./blackbox_exporter -config.file ./blackbox.yml
end script
EOF2

sudo service blackbox_exporter restart

EOF
