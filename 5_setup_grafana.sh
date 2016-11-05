#!/bin/bash -ex
DOMAINS_AND_TLS=~/dev/domains_and_tls

$DOMAINS_AND_TLS/renew_certificate.sh monitoring.danstutzman.com

fwknop -s -n monitoring.danstutzman.com
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
  $DOMAINS_AND_TLS/tls/certs/monitoring.danstutzman.com/cert.pem \
  $DOMAINS_AND_TLS/tls/certs/monitoring.danstutzman.com/privkey.pem \
  root@monitoring.danstutzman.com:/etc/grafana

tugboat ssh -n monitoring <<EOF
set -ex

wget https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.1-1470047149_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_3.1.1-1470047149_amd64.deb

if [ ! -e /etc/grafana/grafana.ini.bak ]; then
  sudo cp /etc/grafana/grafana.ini /etc/grafana/grafana.ini.bak
fi

chown root:grafana /etc/grafana/*.pem
chmod g+r /etc/grafana/*.pem

cat /etc/grafana/grafana.ini.bak \
  | sed 's/^;\?allow_sign_up =\\(.*\\)/allow_sign_up = false/' \
  | sed 's/^;\?protocol =\\(.*\\)/protocol = https/' \
  | sed 's/^;\?cert_file =\\(.*\\)/cert_file = \/etc\/grafana\/cert.pem/' \
  | sed 's/^;\?cert_key =\\(.*\\)/cert_key = \/etc\/grafana\/privkey.pem/' \
  | sudo tee /etc/grafana/grafana.ini

sudo service grafana-server restart
sudo update-rc.d grafana-server defaults 95 10

sudo ufw allow 3000

EOF

echo "Please login to Grafana at https://monitoring.danstutzman.com:3000 with admin/admin and set the admin's password"
