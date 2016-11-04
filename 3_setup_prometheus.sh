#!/bin/bash -ex

tugboat ssh -n monitoring <<"EOF"
set -ex

if [ ! -e prometheus-1.1.2.linux-amd64 ]; then
  curl -L https://github.com/prometheus/prometheus/releases/download/v1.1.2/prometheus-1.1.2.linux-amd64.tar.gz > prometheus-1.1.2.linux-amd64.tar.gz
  tar xvfz prometheus-1.1.2.linux-amd64.tar.gz
fi

mkdir -p /root/prometheus_configs

echo "- targets: [ 'vocabincontext.danstutzman.com:9100' ]" \
  >/root/prometheus_configs/vocabincontext.yml

tee prometheus.yml <<"EOF2"
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
- job_name: prometheus-custom-metrics
  static_configs:
  - targets:
    - vocabincontext.danstutzman.com:9102
    - monitoring.danstutzman.com:9102
    - basicruby.danstutzman.com:9102
  scrape_interval: 15m
- job_name: postgres_exporter
  static_configs:
  - targets:
    - vocabincontext.danstutzman.com:9113
- job_name: blackbox_exporter
  metrics_path: /probe
  params:
    module: [http_2xx]
  static_configs:
  - targets:
    - basicruby.com
    - danstutzman.com
    - monitoring.danstutzman.com
    - vocabincontext.com
  relabel_configs:
  - source_labels: [__address__]
    regex: (.*?)(:80)?
    target_label: __param_target
    replacement: https://${1}
  - source_labels: [__param_target]
    regex: (.*)
    target_label: instance
    replacement: ${1}
  - source_labels: []
    regex: .*
    target_label: __address__
    replacement: 127.0.0.1:9115
rule_files:
- '/root/alert.rules'
EOF2

tee /root/alert.rules <<EOF2
ALERT DiskWillFillIn24Hours
  IF predict_linear(node_filesystem_free{job='node'}[1h], 24*3600) < 0
  FOR 1m
  LABELS {
    severity="page"
  }

ALERT CloudFrontLogsStopped
  IF absent(cloudfront_visits)
  FOR 30m
  LABELS {
    severity="page"
  }

ALERT SSLCertExpiringIn30Days
  IF probe_ssl_earliest_cert_expiry - time() < 86400 * 30
  FOR 10m

ALERT UnappliedUbuntuSecurityUpdates
  IF ubuntu_security_updates > 0
  FOR 24h

ALERT UbuntuNeedsReboot
  IF is_reboot_required > 0
  FOR 1m
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
