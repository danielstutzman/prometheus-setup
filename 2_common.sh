#!/bin/bash -ex

# use port 22 for ssh since haven't changed to port 2222 yet
tugboat ssh -p 22 -n prometheus <<EOF

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

if [ ! -e /etc/ssh/sshd_config.bak ]; then
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
fi
cat /etc/ssh/sshd_config.bak | sed "s/Port 22$/Port 2222/" | sudo tee /etc/ssh/sshd_config
sudo ufw allow 2222
sudo service ssh restart
sudo ufw deny ssh

EOF
