#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF

if [ ! -e node_exporter-0.12.0.linux-amd64 ]; then
  curl -L https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-amd64.tar.gz > node_exporter-0.12.0.linux-amd64.tar.gz
  tar xvzf node_exporter-0.12.0.linux-amd64.tar.gz
fi

tee /etc/init/node_exporter.conf <<EOF2
start on startup
script
  /root/node_exporter-0.12.0.linux-amd64/node_exporter
end script
EOF2

sudo service node_exporter restart

EOF
