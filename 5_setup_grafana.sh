#!/bin/bash -ex

tugboat ssh -n prometheus <<EOF

set -ex
wget https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.1-1470047149_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_3.1.1-1470047149_amd64.deb

sudo service grafana-server restart
sudo update-rc.d grafana-server defaults 95 10

EOF
