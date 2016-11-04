#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF

set -ex

sudo apt-get update

sudo apt-get install -y ntp
sudo service ntp restart

cp /usr/share/zoneinfo/America/Denver /etc/localtime
echo 'America/Denver' | tee /etc/timezone
/usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata

sudo apt-get install -y mosh

sudo ufw disable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 60000:61000/udp # mosh
yes | sudo ufw enable

EOF
