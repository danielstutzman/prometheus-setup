#!/bin/bash -ex

tugboat ssh -n monitoring <<EOF
set -ex

if [ ! -e prometheus-1.1.2.linux-amd64 ]; then
  curl -L https://github.com/prometheus/prometheus/releases/download/v1.1.2/prometheus-1.1.2.linux-amd64.tar.gz > prometheus-1.1.2.linux-amd64.tar.gz
  tar xvfz prometheus-1.1.2.linux-amd64.tar.gz
fi

grep -v ' (basicruby|monitoring).internal ' /etc/hosts > /etc/hosts.new
echo '192.81.208.111 basicruby.internal' >> /etc/hosts.new
echo '127.0.0.1 monitoring.internal' >> /etc/hosts.new
mv /etc/hosts.new /etc/hosts

tee prometheus.yml <<EOF2
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label job=<job_name> to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['monitoring.internal:9100', 'basicruby.internal:9100']

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
