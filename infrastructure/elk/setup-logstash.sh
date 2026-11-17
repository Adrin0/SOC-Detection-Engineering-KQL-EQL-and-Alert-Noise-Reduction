#!/usr/bin/env bash
# One-time: generate the logstash_writer password (if absent), create the writer role/user
# and a soc_analyst login, then start Logstash. Safe to re-run. Run from /opt/elastic.
set -euo pipefail
cd "$(dirname "$0")"

grep -q '^LOGSTASH_WRITER_PASSWORD=.' .env || {
  sed -i '/^LOGSTASH_WRITER_PASSWORD=/d' .env
  echo "LOGSTASH_WRITER_PASSWORD=$(openssl rand -hex 24)" >> .env
}
grep -q '^SOC_ANALYST_PASSWORD=.' .env || {
  sed -i '/^SOC_ANALYST_PASSWORD=/d' .env
  echo "SOC_ANALYST_PASSWORD=$(openssl rand -hex 16)" >> .env
}
set -a; . ./.env; set +a

es() { curl -fsS --cacert ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H 'Content-Type: application/json' "$@"; echo; }

es -X PUT https://localhost:9200/_security/role/logstash_writer -d '{
  "cluster": ["monitor", "read_ilm", "read_pipeline"],
  "indices": [{
    "names": ["winlogbeat-*", "filebeat-*"],
    "privileges": ["create_doc", "create_index", "view_index_metadata", "auto_configure"]
  }]
}'
es -X PUT https://localhost:9200/_security/user/logstash_writer -d "{
  \"password\": \"${LOGSTASH_WRITER_PASSWORD}\",
  \"roles\": [\"logstash_writer\"],
  \"full_name\": \"Logstash Beats writer\"
}"
es -X PUT https://localhost:9200/_security/user/soc_analyst -d "{
  \"password\": \"${SOC_ANALYST_PASSWORD}\",
  \"roles\": [\"superuser\"],
  \"full_name\": \"SOC lab analyst\"
}"

docker compose up -d logstash
