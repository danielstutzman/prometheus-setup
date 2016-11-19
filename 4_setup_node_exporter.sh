#!/bin/bash -ex

for INSTANCE in basicruby monitoring vocabincontext; do
  fwknop -s -n $INSTANCE.danstutzman.com
  ssh root@$INSTANCE.danstutzman.com <<"EOF"
  set -ex

  id -u node_exporter &>/dev/null || sudo useradd node_exporter
  sudo mkdir -p /home/node_exporter
  sudo chown node_exporter:node_exporter /home/node_exporter
  cd /home/node_exporter

  if [ `uname -p` == i686 ];     then ARCH=386
  elif [ `uname -p` == x86_64 ]; then ARCH=amd64; fi

  if [ ! -e node_exporter-0.12.0.linux-$ARCH ]; then
    curl -L https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-$ARCH.tar.gz > node_exporter-0.12.0.linux-$ARCH.tar.gz
    chown node_exporter:node_exporter node_exporter-0.12.0.linux-$ARCH.tar.gz
    sudo -u node_exporter tar xvzf node_exporter-0.12.0.linux-$ARCH.tar.gz
  fi

  tee /etc/init/node_exporter.conf <<EOF2
  start on filesystem
  setuid node_exporter
  setgid node_exporter
  script
    /home/node_exporter/node_exporter-0.12.0.linux-$ARCH/node_exporter
  end script
EOF2

  sudo ufw allow from $(dig +short monitoring.danstutzman.com) to any port 9100

  sudo service node_exporter restart

EOF
done
