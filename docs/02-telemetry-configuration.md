# 02 — Telemetry Configuration

How events get from the endpoints into fields that KQL and EQL can query. The stack side was
deployed on 2026-11-15 (Elastic 9.5.6); the deployed files are in
[infrastructure/](../infrastructure/README.md). No endpoint is delivering events yet.

## Pipeline

```
Winlogbeat 9.5.6 (Windows) ─┐
                            ├─► Logstash :5044 ─► Elasticsearch ─► winlogbeat-9.5.6 / filebeat-9.5.6
Filebeat 9.5.6 (VM 103) ────┘                     (ingest pipeline does ECS parsing)
```

Logstash writes every Beat to `<beat>-<version>` with `action => "create"`, which matches the
data streams the Beats index templates define. It also selects the ingest pipeline that does
the parsing:

| Source | Ingest pipeline | Selected by |
|---|---|---|
| Winlogbeat | `winlogbeat-9.5.6-routing` (dispatches to sysmon, security, powershell) | A dedicated `winlogbeat` branch in [beats.conf](../infrastructure/elk/logstash/pipeline/beats.conf) |
| Filebeat modules | The module pipeline, e.g. `filebeat-9.5.6-system-auth-entrypoint` | `[@metadata][pipeline]`, set by Filebeat |

## Windows collection

The endpoint currently runs Winlogbeat 7.17.26 with this config (sanitized, verified
2026-11-15). It has to be replaced:

```yaml
winlogbeat.event_logs:
  - name: Microsoft-Windows-Sysmon/Operational
  - name: Security
  - name: System
  - name: Application
output.logstash:
  hosts: ["<old ELK address>:5045"]
processors:
  - add_host_metadata: ~
```

The replacement is [infrastructure/windows-endpoint/winlogbeat.yml](../infrastructure/windows-endpoint/winlogbeat.yml)
for Winlogbeat 9.5.6. It adds the PowerShell Operational channel (4103–4106) and the Windows
PowerShell channel, and ships to `192.168.1.60:5044`. Upgrade steps are in
[infrastructure/windows-endpoint/README.md](../infrastructure/windows-endpoint/README.md).

Sysmon is installed with the SwiftOnSecurity `sysmonconfig.xml`.

## Gaps and how they were handled

### 1. ECS fields (`event.category`, `process.*`, `user.name`, `source.ip`)

In Winlogbeat 7.17 these came from JavaScript processors that the old config did not load.
In 8.x and later the same parsing runs in Elasticsearch ingest pipelines. Two things make it
work through Logstash:

- The pipelines exist only after `winlogbeat setup --pipelines` has run once against
  Elasticsearch. **Pending**: this needs Winlogbeat 9.5.6 on the Windows host.
- Winlogbeat does not pass its pipeline name to Logstash, so Logstash names it explicitly.
  **Done** (2026-11-15).

EQL selects events by `event.category`, so the EQL exercises match nothing until both are in
place. The KQL exercises each list a raw `winlog.event_data.*` fallback.

### 2. PowerShell script block logging

The new config collects the PowerShell Operational channel. Script block logging (Event ID
4104) also has to be enabled in Windows policy; the command is in the Windows README.

### 3. Index template and field types

If the index name doesn't match a Beats template, Elasticsearch maps fields dynamically and IP
addresses become text, which breaks CIDR matching in KQL and `cidrMatch()` in EQL. Logstash
now writes to `<beat>-<version>`, which matches the templates.

- Filebeat: template `filebeat-9.5.6` loaded; `source.ip` simulates as type `ip`. **Verified**
  2026-11-15.
- Winlogbeat: template is loaded by the same `setup` run as the pipelines. **Pending**.

Check after events arrive:

```http
GET winlogbeat-*/_mapping/field/destination.ip
```

### 4. Logstash branches

The old lab Logstash had output branches for some Beats only, and a Beat with no branch was
dropped without an error. The new pipeline has one default output that every Beat reaches.
**Done.**

### 5. Failed-logon auditing is off by default on Windows client editions

Event ID 4625 is only written when failure auditing is enabled for the Logon subcategory.
Check and enable from an elevated prompt:

```cmd
auditpol /get /subcategory:"Logon"
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

### 6. Linux authentication events

- VM 103 runs rsyslog, so `/var/log/auth.log` exists. **Verified**.
- Filebeat `system` module is enabled for `auth` and `syslog`. **Verified** (`filebeat test config`).
- The module's ingest pipelines are loaded in Elasticsearch (from a temporary Filebeat
  container on VM 102, so the endpoint never needs access to 9200). **Verified**.
- Filebeat → Logstash 5044 is dropped by the VM 102 host firewall. **Blocking.**

## Validation checklist

| Check | Command | Result |
|---|---|---|
| Logstash reaches Elasticsearch | Logstash log: "Elasticsearch version determined (9.5.6)" | Pass (2026-11-15) |
| Filebeat can reach Logstash | `filebeat test output` on VM 103 | Fail: firewall (2026-11-15) |
| Winlogbeat can reach Logstash | `winlogbeat.exe test output` | Pending |
| Windows documents are arriving | `GET winlogbeat-*/_count` | Pending |
| Sysmon Event ID 1 has `process.name` | Discover: `event.code: "1"` and inspect a document | Pending |
| Security Event ID 4625 is produced | Deliberate failed logon, then `event.code: "4625"` | Pending |
| `destination.ip` is mapped as `ip` | `GET winlogbeat-*/_mapping/field/destination.ip` | Pending |
| Linux auth events are parsed | Discover on `filebeat-*`: `event.dataset: "system.auth"` | Pending |

Screenshots pending: `03-agent-enrollment.png` (for this lab: Beats shipping status) and
`04-windows-logs.png`. See the [screenshot checklist](screenshot-checklist.md).
