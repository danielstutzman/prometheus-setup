#!/bin/bash -ex

fwknop -s -n monitoring.danstutzman.com
ssh root@monitoring.danstutzman.com <<EOF

sudo debconf-set-selections <<< "postfix postfix/mailname string monitoring.danstutzman.com"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo apt-get install -y mailutils
sudo postconf -e 'myhostname = monitoring.danstutzman.com'
echo monitoring.danstutzman.com | sudo tee /etc/hostname
sudo hostname monitoring.danstutzman.com

id -u alertmanager &>/dev/null || sudo useradd alertmanager
sudo mkdir -p /home/alertmanager
sudo chown alertmanager:alertmanager /home/alertmanager
cd /home/alertmanager

if [ ! -e alertmanager-0.5.0.linux-amd64 ]; then
  curl -L https://github.com/prometheus/alertmanager/releases/download/v0.5.0/alertmanager-0.5.0.linux-amd64.tar.gz > alertmanager-0.5.0.linux-amd64.tar.gz
  chown alertmanager:alertmanager alertmanager-0.5.0.linux-amd64.tar.gz
  sudo -u alertmanager tar xvzf alertmanager-0.5.0.linux-amd64.tar.gz
fi

tee /etc/init/alertmanager.conf <<EOF2
start on startup
setuid alertmanager
setgid alertmanager
script
  /home/alertmanager/alertmanager-0.5.0.linux-amd64/alertmanager -config.file /home/alertmanager/alertmanager.yml -storage.path /home/alertmanager/alertmanager-data
end script
EOF2

sudo -u alertmanager tee /home/alertmanager/alertmanager.yml <<EOF2
global:
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@monitoring.danstutzman.com'

route:
  # The labels by which incoming alerts are grouped together. For example,
  # multiple alerts coming in for cluster=A and alertname=LatencyHigh would
  # be batched into a single group.
  group_by: ['alertname', 'cluster', 'service']

  # When a new group of alerts is created by an incoming alert, wait at
  # least 'group_wait' to send the initial notification.
  # This way ensures that you get multiple alerts for the same group that start
  # firing shortly after another are batched together on the first
  # notification.
  group_wait: 30s

  # When the first notification was sent, wait 'group_interval' to send a batch
  # of new alerts that started firing for that group.
  #group_interval: 5m

  # If an alert has successfully been sent, wait 'repeat_interval' to
  # resend them.
  #repeat_interval: 3h

  # A default receiver
  receiver: email-dan

  routes:
  - receiver: fake-alert-emails
    repeat_interval: 1h
    match:
      alertname: 'FakeAlertToVerifyEndToEnd'

# Inhibition rules allow to mute a set of alerts given that another alert is
# firing.
# We use this to mute any warning-level notifications if the same alert is
# already critical.
inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  # Apply inhibition if the alertname is the same.
  equal: ['alertname', 'cluster', 'service']

receivers:
- name: 'email-dan'
  email_configs:
  - to: 'dtstutz@gmail.com'
    require_tls: false
- name: 'fake-alert-emails'
  email_configs:
  - to: 'fake.alert.emails@gmail.com'
    require_tls: false
EOF2

sudo service alertmanager restart

EOF
