#!/bin/bash -ex

tugboat ssh -n prometheus <<EOF

set -ex
sudo apt-get update
sudo apt-get install -y git ruby bundler libsqlite3-dev sqlite3 zlib1g-dev

mkdir -p /home/promdash
id -u promdash &>/dev/null || useradd promdash --home /home/promdash
chown promdash:promdash /home/promdash

sudo sudo -u promdash bash -ex <<EOF2
if [ ! -e /home/promdash/promdash ]; then
  git clone https://github.com/prometheus/promdash.git /home/promdash/promdash
fi
cd /home/promdash/promdash
bundle install --without mysql postgresql
mkdir -p /home/promdash/promdash/databases
DATABASE_URL=sqlite3:/home/promdash/promdash/databases/mydb.sqlite3 bundle exec rake db:migrate
RAILS_ENV=production DATABASE_URL=sqlite3:/home/promdash/promdash/databases/mydb.sqlite3 bundle exec rake assets:precompile
EOF2

tee /etc/init/promdash.conf <<EOF2
start on startup
chdir /home/promdash/promdash
setgid promdash
setuid promdash
script
  DATABASE_URL=sqlite3:/home/promdash/promdash/databases/mydb.sqlite3 bundle exec thin start -e production -p 3000
end script
EOF2

sudo service promdash restart

EOF
