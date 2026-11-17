#!/usr/bin/env bash
# One-time, on VM 102 from /opt/elastic: load the Filebeat index template and the system
# module ingest pipelines from a throwaway Filebeat container on the stack's Docker network.
# Endpoints then only need to reach Logstash on 5044, never Elasticsearch.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a
docker run --rm --network "${COMPOSE_PROJECT_NAME}_default" -v "${COMPOSE_PROJECT_NAME}_certs:/certs:ro" \
  -e ESPW="$ELASTIC_PASSWORD" "docker.elastic.co/beats/filebeat:${STACK_VERSION}" bash -c '
  filebeat setup --index-management --pipelines --modules system \
    -M system.auth.enabled=true -M system.syslog.enabled=true \
    -E setup.template.settings.index.number_of_replicas=0 \
    -E setup.template.settings.index.number_of_shards=1 \
    -E output.logstash.enabled=false \
    -E output.elasticsearch.hosts=[https://es01:9200] \
    -E output.elasticsearch.ssl.certificate_authorities=/certs/ca/ca.crt \
    -E output.elasticsearch.username=elastic -E "output.elasticsearch.password=$ESPW"'
