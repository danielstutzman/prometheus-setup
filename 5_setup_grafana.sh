#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF

set -ex
wget https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.1-1470047149_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_3.1.1-1470047149_amd64.deb

if [ ! -e /etc/grafana/grafana.ini.bak ]; then
  sudo cp /etc/grafana/grafana.ini /etc/grafana/grafana.ini.bak
fi

cat /etc/grafana/grafana.ini.bak | sed 's/;\?allow_sign_up = \\(.*\\)/allow_sign_up = false/' | sudo tee /etc/grafana/grafana.ini

sudo service grafana-server restart
sudo update-rc.d grafana-server defaults 95 10

sudo ufw allow 3000

EOF

echo "Please login with admin/admin and set the admin's password"
