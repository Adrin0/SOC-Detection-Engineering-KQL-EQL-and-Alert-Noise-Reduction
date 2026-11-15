# 02 — Telemetry Configuration

How events get from the endpoints into fields that KQL and EQL can query. Nothing in this
document has been applied to the lab; the proposed changes need approval and a test.

## Current Windows collection (verified from the local config, 2026-11-15)

Sanitized `winlogbeat.yml`:

```yaml
winlogbeat.event_logs:
  - name: Microsoft-Windows-Sysmon/Operational
  - name: Security
    ignore_older: 72h
  - name: System
    ignore_older: 72h
  - name: Application
    ignore_older: 72h

output.logstash:
  hosts: ["<ELK_LXC_IP>:5045"]

processors:
  - add_host_metadata: ~
```

Sysmon is installed with the SwiftOnSecurity `sysmonconfig.xml`.

## Gaps that affect the exercises

### 1. No module processors, so most ECS fields are missing

In Winlogbeat 7.17 the ECS mapping for Sysmon and Security events is done by JavaScript
processors that ship in the install directory under `module/`. The current config does not
load them. Expected consequence, to be confirmed against the index mapping:

| Present without the processors | Missing without the processors |
|---|---|
| `event.code`, `event.provider`, `event.kind`, `host.name` | `event.category`, `event.type`, `event.outcome`, `event.action` |
| `winlog.channel`, `winlog.event_id`, `winlog.event_data.*` | `process.*`, `user.name`, `source.ip`, `destination.ip` |

EQL selects events by `event.category` (`process where ...`), so the EQL exercises cannot
match anything until these processors are enabled. The KQL exercises each list a raw
`winlog.event_data.*` fallback.

Proposed replacement for the `winlogbeat.event_logs` block (the `module` directory with
`sysmon`, `security`, and `powershell` exists in the local install):

```yaml
winlogbeat.event_logs:
  - name: Microsoft-Windows-Sysmon/Operational
    processors:
      - script:
          lang: javascript
          id: sysmon
          file: ${path.home}/module/sysmon/config/winlogbeat-sysmon.js
  - name: Security
    ignore_older: 72h
    processors:
      - script:
          lang: javascript
          id: security
          file: ${path.home}/module/security/config/winlogbeat-security.js
  - name: Microsoft-Windows-PowerShell/Operational
    event_id: 4103, 4104, 4105, 4106
    ignore_older: 72h
    processors:
      - script:
          lang: javascript
          id: powershell
          file: ${path.home}/module/powershell/config/winlogbeat-powershell.js
  - name: System
    ignore_older: 72h
  - name: Application
    ignore_older: 72h
```

Check the config before restarting the service: `winlogbeat.exe test config`.

### 2. PowerShell script block logging is not collected

The `Microsoft-Windows-PowerShell/Operational` channel is not in the current config, so the
PowerShell exercises rely on Sysmon process creation (Event ID 1) only. Command-line arguments
are visible; script content is not. The block above adds the channel. Script block logging
(Event ID 4104) also has to be enabled in Windows policy before it produces events.

### 3. Index template may not match the Logstash index name

Field types come from the Winlogbeat index template, whose pattern in 7.17 is
`winlogbeat-<version>-*`. If Logstash writes to `winlogbeat-<date>` the template does not
apply and Elasticsearch falls back to dynamic mapping, where IP addresses become text. That
breaks CIDR matching in KQL and `cidrMatch()` in EQL. To check:

```http
GET winlogbeat-*/_mapping/field/destination.ip
```

The result should show `"type": "ip"`. If it does not, load the template once and include the
Beat version in the Logstash index name:

```powershell
.\winlogbeat.exe setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["<ELK_LXC_IP>:9201"]'
```

```conf
} else if [@metadata][beat] == "winlogbeat" {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
```

### 4. Logstash must have a `winlogbeat` branch

The Logstash output is an if / else-if chain on `[@metadata][beat]`. Events from a Beat with no
branch are dropped without an error. The local checkout of the lab repository reviewed on
2026-11-15 contained branches for Filebeat, Metricbeat, and Packetbeat only. Confirm the
deployed `logstash.conf` on LXC 104 has the Winlogbeat branch.

### 5. Failed-logon auditing is off by default on Windows client editions

Event ID 4625 is only written when failure auditing is enabled for the Logon subcategory.
Check and enable from an elevated prompt:

```cmd
auditpol /get /subcategory:"Logon"
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

### 6. Linux authentication events

KQL-07 needs the Filebeat `system` module on the Linux endpoint (`filebeat modules enable
system`). Two things to check:

- Filebeat modules parse in Elasticsearch ingest pipelines. When shipping through Logstash the
  pipelines are only applied if they were loaded (`filebeat setup --pipelines`) and the Logstash
  Elasticsearch output passes `pipeline => "%{[@metadata][pipeline]}"`. Without that the events
  arrive unparsed, with the raw line in `message`.
- A minimal container image may log authentication to journald only, with no
  `/var/log/auth.log` for Filebeat to read.

## Validation checklist

| Check | Command | Result |
|---|---|---|
| Winlogbeat can reach Logstash | `winlogbeat.exe test output` | Pending |
| Windows documents are arriving | `GET winlogbeat-*/_count` | Pending |
| Sysmon Event ID 1 has `process.name` | Discover: `event.code: "1"` and inspect a document | Pending |
| Security Event ID 4625 is produced | Deliberate failed logon, then `event.code: "4625"` | Pending |
| `destination.ip` is mapped as `ip` | `GET winlogbeat-*/_mapping/field/destination.ip` | Pending |
| Linux auth events are parsed | Discover on `filebeat-*`: `event.dataset: "system.auth"` | Pending |

Screenshots pending: `03-agent-enrollment.png` (for this lab: Beats shipping status) and
`04-windows-logs.png`. See the [screenshot checklist](screenshot-checklist.md).
