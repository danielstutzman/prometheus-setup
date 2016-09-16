#!/bin/bash -ex

tugboat ssh -n basicruby <<EOF

if [ ! -e node_exporter-0.12.0.linux-386 ]; then
  curl -L https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-386.tar.gz  > node_exporter-0.12.0.linux-386.tar.gz
  tar xvzf node_exporter-0.12.0.linux-386.tar.gz
fi

tee /etc/init/node_exporter.conf <<EOF2
start on startup
script
  /root/node_exporter-0.12.0.linux-386/node_exporter
end script
EOF2

sudo ufw allow from \$(dig +short monitoring.danstutzman.com) to any port 9100

sudo service node_exporter restart

EOF
