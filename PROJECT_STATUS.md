# Project Status

Last updated: 2026-11-15

## Summary

Infrastructure deployed on 2026-11-15: Elastic 9.5.6 (Elasticsearch, Kibana, Fleet Server,
Logstash) on VM 102 and a Linux endpoint on VM 103, files in [infrastructure/](infrastructure/README.md).
No endpoint is delivering events yet. No exercise has been run, no rule has been validated,
no screenshot has been captured, and no result has been measured.

## Completed exercises

None.

## Active exercises

None. Work is blocked on endpoint delivery (known issues 1 and 12).

## Pending screenshots

All 12. See [docs/screenshot-checklist.md](docs/screenshot-checklist.md).

## Validated detection rules

None.

| Rule | Syntax checked | Fires on simulation | Benign baseline checked |
|---|---|---|---|
| DET-001 | No | No | No |
| DET-002 | No | No | No |
| DET-003 | No | No | No |
| DET-004 | No | No | No |
| DET-005 | No | No | No |
| DET-006 | No | No | No |

## Outstanding tuning experiments

| Experiment | Stage | State |
|---|---|---|
| DET-001 | E1 Baseline | Not started |
| DET-001 | E2 Threshold adjustment | Not started |
| DET-001 | E3 Narrow exception | Not started |
| DET-001 | E4 Alert suppression | Not started |
| DET-001 | E5 Regression test | Not started |

## Known issues

Items 1–11 were found by read-only inspection on 2026-11-15, before deployment. Their state
was updated the same day after the deployment; each change names its evidence.

1. **Winlogbeat not delivering.** The Windows endpoint runs Winlogbeat 7.17.26 pointed at the old ELK address. *Update 2026-11-15:* the old LXC stack no longer exists; the new target is Logstash on `192.168.1.60:5044`, which needs Winlogbeat 9.5.6 ([steps](infrastructure/windows-endpoint/README.md)). Open.
2. ~~**Logstash may have no Winlogbeat branch.**~~ Resolved 2026-11-15: the new pipeline has one default output for every Beat plus a Winlogbeat branch for its routing pipeline (`infrastructure/elk/logstash/pipeline/beats.conf`, running and reloaded on VM 102).
3. **Winlogbeat ECS parsing.** In 9.x this is the `winlogbeat-9.5.6-routing` ingest pipeline, selected by Logstash. Open until `winlogbeat setup --pipelines` has run from the upgraded Windows endpoint.
4. **Index template may not apply.** Resolved for Filebeat (`source.ip` simulates as `ip` on `filebeat-9.5.6`, 2026-11-15). Open for Winlogbeat until its template is loaded.
5. ~~**Detection engine prerequisites not met.**~~ Resolved 2026-11-15: Elastic 9.5.6 runs with security, TLS and Kibana encryption keys; `POST /api/detection_engine/index` acknowledged and the privileges API reports `has_encryption_key: true`.
6. **PowerShell script block logging is not collected.** The new Winlogbeat config collects the channel; the Windows policy still has to be enabled. Open.
7. **Failed-logon auditing state unknown.** Checking `auditpol` needs an elevated prompt. Open.
8. **Linux authentication telemetry.** VM 103 has `/var/log/auth.log` (rsyslog), the Filebeat system module is configured, and its ingest pipelines are loaded. Delivery is blocked by issue 12. Open.
9. **Lab is not network-isolated.** Guests share the home LAN bridge. Open.
10. **No license selected.**
11. **Repository name differs from the planned `soc-detection-engineering`.** The existing repository and its configured remote were reused rather than creating a duplicate.
12. **VM 102 host firewall drops Logstash traffic.** The nftables allowlist `soc_guard` (`/etc/soc-guard.nft`) accepts 9200, 5601 and 8220 from listed admin hosts only, so `filebeat test output` from VM 103 times out on 5044. Proposed fix: a `beats` set (192.168.1.61, later the Windows endpoint) with `tcp dport 5044 ip saddr @beats accept`. Needs owner approval. Open.

## Next actions

1. Approve and apply the `soc_guard` change for 5044 (issue 12), then confirm `filebeat test output` passes on VM 103.
2. Generate a failed SSH login on VM 103 and confirm a parsed `system.auth` event in `filebeat-*` (KQL-07).
3. Upgrade the Windows endpoint to Winlogbeat 9.5.6 and run `setup --index-management --pipelines` (issues 1, 3, 4).
4. Inspect one Sysmon Event ID 1 document in Discover and record which fields exist.
5. Run KQL-01 (failed Windows logins): enable failure auditing, generate a failed logon, capture `05-kql-failed-logins.png`.
6. Choose a license.
7. Decide whether to push to the GitHub remote.

## Evidence log

When new evidence arrives it is recorded here with its date, linked to its exercise, and the
related documents are updated. Earlier entries are not rewritten.

| Date | Evidence | Associated with | Recorded in |
|---|---|---|---|
| 2026-11-15 | `Get-Service` output: Sysmon64 and winlogbeat running | Lab setup steps 4, 5 | docs/01 |
| 2026-11-15 | Local `winlogbeat.yml` contents (sanitized) | Telemetry configuration | docs/02 |
| 2026-11-15 | Winlogbeat log: connection failures to Logstash | Known issue 1 | docs/01, docs/07 |
| 2026-11-15 | VM 102: existing Elastic 9.5.6 stack found and reused; Logstash added; `docker compose ps` all healthy; cluster green | Lab setup step 3 | docs/01, infrastructure/ |
| 2026-11-15 | Detection engine index created; privileges API `has_encryption_key: true` | Known issue 5 | docs/01 |
| 2026-11-15 | VM 103 created; Filebeat 9.5.6 `test config` OK; Filebeat template and system pipelines loaded | Lab setup steps 1, 4; known issues 4, 8 | docs/01, docs/02 |
| 2026-11-15 | `filebeat test output` from VM 103: dial timeout to 192.168.1.60:5044 (`soc_guard`) | Known issue 12 | docs/01, docs/02 |
