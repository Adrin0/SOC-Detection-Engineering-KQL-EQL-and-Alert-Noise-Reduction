#!/usr/bin/env bash
# First-run bring-up: ES first, then record the CA fingerprint and the Fleet Server
# service token in .env, then the rest of the stack. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a

# Poll until every named service is healthy (one-shot services can't use --wait)
wait_healthy() {
  for svc in "$@"; do
    for _ in $(seq 1 90); do
      state=$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q "$svc")" 2>/dev/null || true)
      [ "$state" = healthy ] && { echo "$svc: healthy"; continue 2; }
      sleep 10
    done
    echo "$svc: not healthy after 15 min" >&2; docker compose logs --tail 50 "$svc" >&2; exit 1
  done
}

docker compose up -d es01
wait_healthy es01
docker compose cp es01:/usr/share/elasticsearch/config/certs/ca/ca.crt ./ca.crt

fp=$(openssl x509 -in ca.crt -noout -fingerprint -sha256 | cut -d= -f2 | tr -d ':' | tr 'A-F' 'a-f')
sed -i "s/^CA_FINGERPRINT=.*/CA_FINGERPRINT=${fp}/" .env

if [ -z "${FLEET_SERVER_SERVICE_TOKEN:-}" ]; then
  token=$(curl -fsS --cacert ca.crt -u "elastic:${ELASTIC_PASSWORD}" -X POST \
    "https://localhost:9200/_security/service/elastic/fleet-server/credential/token/fleet-server-01" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"]["value"])')
  sed -i "s|^FLEET_SERVER_SERVICE_TOKEN=.*|FLEET_SERVER_SERVICE_TOKEN=${token}|" .env
fi

# Single node: no replicas for integration data streams (else the cluster stays yellow)
es() { curl -fsS --cacert ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H 'Content-Type: application/json' "$@"; echo; }
for t in logs metrics traces synthetics; do
  es -X PUT "https://localhost:9200/_component_template/${t}@custom" \
    -d '{"template":{"settings":{"index":{"number_of_replicas":0}}}}'
done

docker compose up -d
wait_healthy es01 kibana fleet-server
es -X PUT "https://localhost:9200/*,.ds-*,.fs-*/_settings?expand_wildcards=all" \
  -d '{"index":{"number_of_replicas":0}}' || true
docker compose ps -a
