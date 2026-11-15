# Project Status

Last updated: 2026-11-15

## Summary

Repository initialized. Documentation, draft queries, draft detections, templates, and
tooling exist. No exercise has been run, no rule has been validated, no screenshot has been
captured, and no result has been measured.

## Completed exercises

None.

## Active exercises

None. Work is blocked on restoring connectivity to the ELK stack (known issue 1).

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

Found by read-only inspection on 2026-11-15. Items marked "to confirm" are expected from the
configuration but have not been observed on the running stack.

1. **ELK stack unreachable; Winlogbeat not delivering.** Requests to Elasticsearch and Kibana timed out, and the Winlogbeat log shows repeated connection failures to Logstash. Either the container is down or its DHCP address changed. Get the current address on the Proxmox host (`pct exec 104 -- hostname -I`) and compare it with `winlogbeat.yml`.
2. **Logstash may have no Winlogbeat branch (to confirm).** The local checkout of the lab repository had output branches for Filebeat, Metricbeat, and Packetbeat only. Without a Winlogbeat branch, events are dropped silently.
3. **Winlogbeat module processors are not configured (to confirm impact).** Without them, `event.category`, `process.*`, `user.name`, and `source.ip` are probably absent, which breaks every EQL rule and the ECS form of the KQL queries. Fix proposed in [docs/02](docs/02-telemetry-configuration.md).
4. **Index template may not apply (to confirm).** If the Logstash index name does not match the Winlogbeat template pattern, IP fields are text and CIDR matching fails.
5. **Detection engine prerequisites not met.** Elastic Security rules in 7.17 need Elasticsearch security enabled and a Kibana encryption key. The lab runs without either. Enabling security also means adding credentials to every Beat and to Logstash.
6. **PowerShell script block logging is not collected.**
7. **Failed-logon auditing state unknown.** Checking `auditpol` needs an elevated prompt.
8. **Linux authentication telemetry not verified.** Filebeat system module, ingest pipeline through Logstash, and the presence of an auth log in the container all need checking.
9. **Lab is not network-isolated.** Guests share the home LAN bridge.
10. **No license selected.**
11. **Repository name differs from the planned `soc-detection-engineering`.** The existing repository and its configured remote were reused rather than creating a duplicate.

## Next actions

1. Restore connectivity (issue 1) and confirm `GET winlogbeat-*/_count` is increasing.
2. Inspect one Sysmon Event ID 1 document in Discover and record which fields exist. This decides whether issue 3 is real.
3. Apply and test the Winlogbeat module processor change if needed.
4. Run KQL-01 (failed Windows logins): enable failure auditing, generate a failed logon, capture `05-kql-failed-logins.png`.
5. Decide how to meet the detection engine prerequisites (issue 5).
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
