#!/usr/bin/env bash
# Run on the Proxmox host after elk/setup-filebeat-templates.sh. Pushes the CA and Filebeat
# config to VM 103 and starts Filebeat shipping to Logstash (192.168.1.60:5044).
set -euo pipefail
cd "$(dirname "$0")"
EP=soc@192.168.1.61

qm guest exec 102 --timeout 30 -- cat /opt/elastic/ca.crt \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["out-data"],end="")' \
  | ssh "$EP" 'sudo tee /etc/filebeat/ca.crt >/dev/null'
ssh "$EP" 'sudo tee /etc/filebeat/filebeat.yml >/dev/null; sudo chmod 600 /etc/filebeat/filebeat.yml' < filebeat.yml
ssh "$EP" 'sudo filebeat modules enable system >/dev/null; sudo tee /etc/filebeat/modules.d/system.yml >/dev/null' < system.yml
ssh "$EP" 'sudo filebeat test config && sudo systemctl enable --now filebeat && sudo systemctl restart filebeat'
ssh "$EP" 'sudo filebeat test output' || echo "Logstash not reachable from the endpoint (check soc_guard on VM 102)"
