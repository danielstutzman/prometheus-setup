#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF
set -ex

if [ ! -e prometheus-1.1.2.linux-amd64 ]; then
  curl -L https://github.com/prometheus/prometheus/releases/download/v1.1.2/prometheus-1.1.2.linux-amd64.tar.gz > prometheus-1.1.2.linux-amd64.tar.gz
  tar xvfz prometheus-1.1.2.linux-amd64.tar.gz
fi

mkdir -p /root/prometheus_configs

echo "- targets: [ 'vocabincontext.danstutzman.com:9100' ]" \
  >/root/prometheus_configs/vocabincontext.yml

tee prometheus.yml <<EOF2
global:
  scrape_interval: 15s
scrape_configs:
- job_name: file_sd_configs
  file_sd_configs:
  - files:
    - /root/prometheus_configs/*.yml
    refresh_interval: 1m
- job_name: node_exporter
  static_configs:
  - targets:
    - monitoring.danstutzman.com:9100
    - basicruby.danstutzman.com:9100
- job_name: prometheus-piwik-exporter
  static_configs:
  - targets:
    - localhost:9101
- job_name: prometheus-cloudfront-logs-exporter
  static_configs:
  - targets:
    - localhost:9102
  scrape_interval: 15m
rule_files:
- '/root/alert.rules'
EOF2

tee /etc/init/prometheus.conf <<EOF2
start on startup
chdir /root/prometheus-1.1.2.linux-amd64
script
  ./prometheus -config.file /root/prometheus.yml -storage.local.memory-chunks=10000 -alertmanager.url http://localhost:9093
end script
EOF2

sudo service prometheus stop || true
sleep 1
sudo service prometheus start

EOF
