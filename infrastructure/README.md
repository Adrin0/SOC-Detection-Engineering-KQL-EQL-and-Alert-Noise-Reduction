# Infrastructure

Everything that runs the lab, as deployed on the Proxmox host `hadron` (2026-11-15; Windows VM 104 added 2026-11-17).
No secrets are stored here: real values live only in `/opt/elastic/.env` (mode 600) on VM 102.

| Guest | Role | Address | Resources |
|---|---|---|---|
| VM 102 `soc-elastic` | Elasticsearch, Kibana, Fleet Server, Logstash 9.5.6 (Docker Compose, `/opt/elastic`) | 192.168.1.60 (static) | 4 vCPU, 10 GB RAM, 150 GB |
| VM 103 `soc-linux-ep` | Linux endpoint: Ubuntu 24.04, rsyslog, Filebeat 9.5.6 (system module) | 192.168.1.61 (static) | 1 vCPU, 2 GB RAM, 20 GB |
| VM 104 `soc-win-ep` | Windows endpoint: Windows 11 Pro, Sysmon, Winlogbeat 9.5.6. On demand, snapshot `clean-baseline` | 192.168.1.62 (static) | 2 vCPU, 4 GB RAM, 64 GB |

| Port on VM 102 | Service | Allowed sources (`soc_guard`) |
|---|---|---|
| 9200 | Elasticsearch, HTTPS | `admin` set (hadron, mgmt VM), 10.10.0.0/16 |
| 5601 | Kibana, HTTPS | `admin`, `kibana_users` |
| 8220 | Fleet Server | `admin`, 10.10.0.0/16 |
| 5044 | Logstash Beats input, plaintext | `beats` set: 192.168.1.61 (VM 103), 192.168.1.62 (VM 104) |

## Layout

| Path | Deployed to | Purpose |
|---|---|---|
| `elk/docker-compose.yml`, `kibana.yml`, `instances.yml`, `bootstrap.sh` | `/opt/elastic/` | Stack from 2026-11-02 (ES, Kibana, Fleet Server, TLS, security), copied unchanged |
| `elk/docker-compose.override.yml` | `/opt/elastic/` | Adds Logstash; Compose merges it automatically |
| `elk/logstash/` | `/opt/elastic/logstash/` | Logstash settings and the Beats pipeline |
| `elk/setup-logstash.sh` | `/opt/elastic/` | Creates `logstash_writer` (role and user) and `soc_analyst`, starts Logstash |
| `elk/setup-filebeat-templates.sh` | `/opt/elastic/` | Loads the Filebeat template and system ingest pipelines from a throwaway container |
| `elk/.env.example` | `/opt/elastic/.env` | Variable names only |
| `linux-endpoint/` | VM 103 `/etc/filebeat/` | Filebeat config; `setup-endpoint.sh` runs from hadron |
| `windows-endpoint/` | VM 104 | Unattended build (answer file, first-logon bootstrap, ISO builder) and Winlogbeat config |

## Data path

Beats → Logstash `:5044` → Elasticsearch, into `<beat>-<version>` data streams
(`filebeat-9.5.6`, `winlogbeat-9.5.6`). Logstash picks the ingest pipeline:

- Filebeat modules: the pipeline named in `[@metadata][pipeline]` (system auth and syslog parsing).
- Winlogbeat: `winlogbeat-9.5.6-routing`, which produces the ECS fields (`event.category`,
  `process.*`, `user.name`, `source.ip`) that the KQL and EQL exercises need.

The index templates come from the Beats themselves (`setup --index-management`), so IP
fields are mapped as `ip`.

## Deploy from scratch

1. VM 102: copy `elk/` to `/opt/elastic`, create `.env` from `.env.example` and fill in the
   passwords and keys, run `./bootstrap.sh`, then `./setup-logstash.sh`, then
   `./setup-filebeat-templates.sh`.
2. VM 103: create it from the Ubuntu 24.04 cloud image with cloud-init (user `soc`, the host's
   SSH key, static IP), install `qemu-guest-agent`, `rsyslog` and `filebeat=9.5.6` from the
   Elastic 9.x apt repo, then run `linux-endpoint/setup-endpoint.sh` from hadron.
3. VM 104: follow [windows-endpoint/README.md](windows-endpoint/README.md).

## Operations

| Task | Command (on VM 102, in `/opt/elastic`) |
|---|---|
| Status | `docker compose ps` |
| Logstash logs | `docker compose logs -f logstash` |
| Restart the stack | `docker compose restart` |
| Stop without losing data | `docker compose down` (keeps volumes) |
| Remove only Logstash | `docker compose rm -sf logstash` and delete `docker-compose.override.yml` |

Credentials: log in to Kibana (`https://192.168.1.60:5601`) as `soc_analyst`. Its password
is `SOC_ANALYST_PASSWORD` in `/opt/elastic/.env`.

## Open items

- Beats → Logstash traffic is plaintext on the LAN.
- The lab is not network-isolated (the move to vmbr20 / 10.10.20.10 is planned; certificates
  already carry that address).
