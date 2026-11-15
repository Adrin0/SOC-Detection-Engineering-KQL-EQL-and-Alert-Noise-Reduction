# DET-004 — PowerShell Execution Followed by External Network Activity

| | |
|---|---|
| **Type** | EQL sequence rule |
| **Rule file** | [det-004-powershell-then-network.eql](../../detection-rules/eql/det-004-powershell-then-network.eql) |
| **Validation status** | Untested. Syntax not yet checked against Elasticsearch |
| **Last validated** | Never |

## 1. Description

Detects a PowerShell process that makes a connection to a non-private address within two
minutes of starting.

## 2. Threat hypothesis

Download cradles and command-and-control stagers start PowerShell and immediately reach out
to the internet. Most administrative PowerShell does not.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Execution | T1059.001 PowerShell | The process is PowerShell |
| Command and Control | T1105 Ingress Tool Transfer | An outbound connection from the same process instance is consistent with fetching content |

The rule sees a connection, not what was transferred. T1105 is a hypothesis for the analyst
to confirm from the destination and what the process did next.

## 4. Data sources

Sysmon Event ID 1 (process creation) and Event ID 3 (network connection) in `winlogbeat-*`.

## 5. Required ECS fields

`event.category`, `event.type`, `process.name`, `process.entity_id`, `destination.ip`
(mapped as `ip`), `host.name`.

## 6. Logic

```
sequence by host.name, process.entity_id with maxspan=2m
  [process where event.type == "start" and process.name : ("powershell.exe", "pwsh.exe")]
  [network where process.name : ("powershell.exe", "pwsh.exe") and
    not cidrMatch(destination.ip, "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8", "169.254.0.0/16", "::1/128", "fe80::/10")]
```

## 7. Expected benign behavior

Module installation from the PowerShell Gallery, cloud management modules, update checks,
and scripts that call web APIs.

## 8. Expected suspicious behavior

Connections to raw IP addresses, uncommon ports, or newly seen domains, especially when the
PowerShell process has a hidden window or an encoded command line.

## 9. False-positive considerations

Developer and administrator workstations generate this constantly. Expect this rule to be
the noisiest of the EQL set and a good second tuning experiment.

## 10. Tuning strategy

Exclude verified destinations or signed management scripts by command line; add a condition
on the first event's command line; lower the risk score rather than exclude when unsure.

## 11. Test procedure

See [06-purple-team-validation.md](../06-purple-team-validation.md).

## 12. Validation status

Untested. Depends on the Sysmon configuration logging network connections for PowerShell
and on `destination.ip` being mapped as `ip`; confirm both first.

## 13. Screenshots

Pending: `07-eql-rule.png`, `08-eql-alert.png`.

## 14. Results

None.

## 15. Change history

| Date | Change |
|---|---|
| 2026-11-15 | Draft created |
